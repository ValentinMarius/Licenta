# backend/app/services/llm_client.py
# Wraps the DeepSeek chat completion API for generating Treespora plan summaries.
# Exists so higher-level services do not care about HTTP minutiae or JSON parsing.
# RELEVANT FILES:backend/app/services/plan_summary_service.py,backend/app/core/settings.py,backend/app/schemas/plan_summary.py

from __future__ import annotations

import json
import re
from typing import List, Optional

import httpx
from pydantic import BaseModel, Field, ValidationError

from functools import lru_cache

from ..core.settings import get_settings
from ..schemas.plan_tasks import TaskPlanPrompt, TaskPlanResult


class LlmClientError(Exception):
    """Raised when the LLM request fails or returns invalid content."""

    def __init__(self, message: str, status_code: Optional[int] = None) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code

    def __str__(self) -> str:
        if self.status_code is not None:
            return f"{self.message} (status={self.status_code})"
        return self.message


class PlanPhase(BaseModel):
    name: str
    focus: str
    days_range: Optional[str] = None


class PlanSummaryResult(BaseModel):
    overview: str
    phases: List[PlanPhase] = Field(default_factory=list)
    estimated_duration_days: Optional[int] = None


class PlanSummaryPrompt(BaseModel):
    goal_title: str
    goal_description: str
    user_context: Optional[str] = None
    language: str = "en"

    def to_formatted_string(self) -> str:
        """Creates the user-facing prompt the LLM expects."""
        context = self.user_context.strip() if self.user_context else "Not provided"
        return (
            f"Language: {self.language}\n"
            "You help Treespora summarize user goals.\n"
            f"Goal title: {self.goal_title}\n"
            f"Goal description: {self.goal_description}\n"
            f"User context: {context}\n"
            "Respond ONLY with JSON matching the schema:\n"
            "{"
            '"overview": str, '
            '"estimated_duration_days": int | null, '
            '"phases": ['
            '{"name": str, "days_range": str | null, "focus": str}'
            "]"
            "}"
        )


TASK_PLANNER_SYSTEM_PROMPT = (
    "You are the Treespora Task Planner agent.\n"
    "- The user message will ALWAYS be a JSON payload describing TaskPlanPrompt.\n"
    "- Respond ONLY with JSON following the schema:\n"
    "{goal_id, plan_id, version, summary, time_horizon_days, "
    "daily_time_commitment_minutes, start_date, days:[{day_index,label,focus,"
    "tasks:[{description,estimated_minutes}]}]}.\n"
    "- Cover every calendar day from start_date to target_date inclusively.\n"
    "- Each day must include 1-3 actionable tasks with durations between 5 and 60 minutes.\n"
    "- Ensure total daily effort stays within the provided daily_time_commitment_minutes.\n"
    "- NEVER modify plan_summary; keep it identical in the output summary field.\n"
    "- Always produce short, clear, user-friendly task descriptions."
)


class LlmClient:
    """Thin wrapper around DeepSeek's OpenAI-compatible chat completions."""

    def __init__(self, base_url: str, api_key: str, model: str) -> None:
        if not api_key:
            raise ValueError("DeepSeek API key is missing.")
        self._base_url = base_url.rstrip("/")
        self._api_key = api_key
        self._model = model
        self._summary_timeout = httpx.Timeout(timeout=30.0, connect=10.0, read=30.0)
        self._task_plan_timeout = httpx.Timeout(timeout=90.0, connect=15.0, read=90.0)

    @property
    def model_name(self) -> str:
        return self._model

    async def generate_plan_summary(
        self,
        prompt: PlanSummaryPrompt,
    ) -> PlanSummaryResult:
        payload = {
            "model": self._model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a planning assistant for Treespora."
                        " Always return structured JSON."
                    ),
                },
                {"role": "user", "content": prompt.to_formatted_string()},
            ],
        }
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }
        try:
            async with httpx.AsyncClient(
                base_url=self._base_url,
                timeout=self._summary_timeout,
            ) as client:
                response = await client.post(
                    "/chat/completions",
                    json=payload,
                    headers=headers,
                )
            response.raise_for_status()
        except httpx.ReadTimeout as error:
            raise LlmClientError("LLM request timed out while summarizing plan.") from error
        except httpx.HTTPStatusError as error:
            raise LlmClientError(
                "LLM responded with an HTTP error.",
                status_code=error.response.status_code,
            ) from error
        except httpx.HTTPError as error:
            raise LlmClientError("LLM request failed.") from error

        data = response.json()
        content = (
            data.get("choices", [{}])[0]
            .get("message", {})
            .get("content", "")
            .strip()
        )
        parsed_payload = self._extract_json_payload(content)
        try:
            return PlanSummaryResult(**parsed_payload)
        except ValidationError as error:
            raise LlmClientError("LLM response payload is invalid.") from error

    async def generate_task_plan(
        self,
        prompt: TaskPlanPrompt,
    ) -> TaskPlanResult:
        """Generates the full plan_json payload (days + tasks)."""
        payload = {
            "model": self._model,
            "messages": [
                {
                    "role": "system",
                    "content": TASK_PLANNER_SYSTEM_PROMPT,
                },
                {"role": "user", "content": prompt.model_dump_json()},
            ],
        }
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }
        try:
            async with httpx.AsyncClient(
                base_url=self._base_url,
                timeout=self._task_plan_timeout,
            ) as client:
                response = await client.post(
                    "/chat/completions",
                    json=payload,
                    headers=headers,
                )
            response.raise_for_status()
        except httpx.ReadTimeout as error:
            raise LlmClientError("LLM request timed out while generating tasks.") from error
        except httpx.HTTPStatusError as error:
            raise LlmClientError(
                "LLM responded with an HTTP error.",
                status_code=error.response.status_code,
            ) from error
        except httpx.HTTPError as error:
            raise LlmClientError("LLM request failed.") from error

        data = response.json()
        content = (
            data.get("choices", [{}])[0]
            .get("message", {})
            .get("content", "")
            .strip()
        )
        parsed_payload = self._extract_json_payload(content)
        normalized_payload = self._normalize_task_plan_payload(parsed_payload)
        try:
            return TaskPlanResult(**normalized_payload)
        except ValidationError as error:
            raise LlmClientError("Task plan payload is invalid.") from error

    def _extract_json_payload(self, raw_content: str) -> dict:
        """Extracts JSON even if the LLM wrapped it with prose."""
        try:
            return json.loads(raw_content)
        except json.JSONDecodeError:
            pass
        match = re.search(r"\{.*\}", raw_content, re.DOTALL)
        if match:
            snippet = match.group(0)
            try:
                return json.loads(snippet)
            except json.JSONDecodeError:
                pass
        raise LlmClientError("LLM response did not contain valid JSON.")

    def _normalize_task_plan_payload(self, payload: dict) -> dict:
        """Clamps task durations so Pydantic validation cannot fail."""
        if not isinstance(payload, dict):
            return payload
        days = payload.get("days")
        if not isinstance(days, list):
            return payload
        normalized_days = []
        for day in days:
            if not isinstance(day, dict):
                continue
            tasks = day.get("tasks")
            if isinstance(tasks, list):
                normalized_tasks = []
                for task in tasks:
                    if not isinstance(task, dict):
                        continue
                    minutes = task.get("estimated_minutes")
                    if isinstance(minutes, bool):
                        coerced_minutes = 5
                    elif isinstance(minutes, (int, float)):
                        coerced_minutes = int(minutes)
                    else:
                        coerced_minutes = 5
                    coerced_minutes = min(60, max(5, coerced_minutes))
                    normalized_tasks.append(
                        {**task, "estimated_minutes": coerced_minutes},
                    )
                day = {**day, "tasks": normalized_tasks}
            normalized_days.append(day)
        return {**payload, "days": normalized_days}


@lru_cache
def _build_llm_client() -> LlmClient:
    settings = get_settings()
    return LlmClient(
        base_url=settings.deepseek_base_url,
        api_key=settings.deepseek_api_key,
        model=settings.deepseek_model,
    )


def get_llm_client() -> LlmClient:
    """FastAPI dependency that reuses a single client instance."""
    return _build_llm_client()
