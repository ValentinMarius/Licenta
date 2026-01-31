# backend/app/services/plan_summary_service.py
# Coordinates DB access and LLM generation to build plan summaries per goal.
# Exists to isolate business logic from HTTP layers and raw LLM calls.
# RELEVANT FILES:backend/app/services/llm_client.py,backend/app/schemas/plan_summary.py,backend/app/api/plans.py

from __future__ import annotations

import json
import logging
import re
from datetime import date, datetime, timedelta
from typing import Any, Dict, Optional
from uuid import uuid4

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from ..schemas.plan_summary import PlanPhase, PlanSummary
from .llm_client import LlmClient, LlmClientError, PlanSummaryPrompt
from .plan_tasks_service import PlanTasksService

ALLOWED_LANGUAGES = {"en", "es", "zh", "hi", "ar", "ro"}
DEFAULT_PLAN_DURATION_DAYS = 30
logger = logging.getLogger(__name__)


class GoalNotFoundError(Exception):
    """Raised when the requested goal does not exist."""  # simple marker


class PlanSummaryService:
    def __init__(self, llm_client: LlmClient, db_session: AsyncSession) -> None:
        self._llm_client = llm_client
        self._db_session = db_session

    async def get_or_generate_plan_summary(self, goal_id: str) -> PlanSummary:
        cached_plan = await self._fetch_cached_plan_summary(goal_id)
        if cached_plan:
            return cached_plan

        goal = await self._fetch_goal(goal_id)
        user_context = await self._fetch_user_context(goal.get("user_id"))
        language = await self._fetch_user_language(goal.get("user_id"))
        prompt = PlanSummaryPrompt(
            goal_title=goal.get("title") or "Untitled goal",
            goal_description=goal.get("description") or "",
            user_context=user_context,
            language=language or "en",
        )
        try:
            llm_result = await self._llm_client.generate_plan_summary(prompt)
            summary = PlanSummary(
                goal_id=goal_id,
                overview=llm_result.overview,
                phases=[PlanPhase(**phase.dict()) for phase in llm_result.phases],
                estimated_duration_days=llm_result.estimated_duration_days,
            )
        except LlmClientError as error:
            logger.warning(
                "Plan summary LLM failure for goal %s; falling back: %s",
                goal_id,
                error,
            )
            goal_title = goal.get("title") or "your goal"
            fallback_overview = (
                "AI summary unavailable right now. "
                f"We'll retry soon. Goal: {goal_title}. "
                "You can continue with tasks while the summary regenerates."
            )
            summary = PlanSummary(
                goal_id=goal_id,
                overview=fallback_overview,
                phases=[],
                estimated_duration_days=DEFAULT_PLAN_DURATION_DAYS,
            )
        target_date = self._resolve_target_date(goal, summary)
        if not self._coerce_date(goal.get("target_date")) and target_date:
            await self._update_goal_target_date(goal_id, target_date)
        
        # Parse daily time commitment from goal description
        daily_time_minutes = self._parse_daily_time_from_description(
            goal.get("description") or ""
        )
        
        await self._persist_plan_summary(
            goal_id=goal_id,
            summary=summary,
            model_name=self._llm_client.model_name,
            target_date=target_date,
            daily_time_commitment_minutes=daily_time_minutes,
        )
        await self._generate_task_plan(goal_id)
        return summary

    async def _fetch_goal(self, goal_id: str) -> dict:
        query = text(
            """
            SELECT id, user_id, title, description, target_date
            FROM goals
            WHERE id = :goal_id
            LIMIT 1
            """,
        )
        result = await self._db_session.execute(query, {"goal_id": goal_id})
        record = result.mappings().first()
        if not record:
            raise GoalNotFoundError("Goal not found.")
        return dict(record)

    async def _fetch_user_language(self, user_id: Optional[str]) -> Optional[str]:
        if not user_id:
            return None
        query = text(
            """
            SELECT language_code
            FROM profiles
            WHERE id = :user_id
            LIMIT 1
            """,
        )
        result = await self._db_session.execute(query, {"user_id": user_id})
        record = result.mappings().first()
        language = record.get("language_code") if record else None
        if isinstance(language, str) and language.strip():
            normalized = language.strip().lower()
            if normalized in ALLOWED_LANGUAGES:
                return normalized
        return None

    async def _fetch_user_context(self, user_id: Optional[str]) -> Optional[str]:
        if not user_id:
            return None
        query = text(
            """
            SELECT age, language_code
            FROM profiles
            WHERE id = :user_id
            LIMIT 1
            """,
        )
        result = await self._db_session.execute(query, {"user_id": user_id})
        record = result.mappings().first()
        if not record:
            return None
        parts = []
        age = record.get("age")
        language_code = record.get("language_code")
        if age is not None:
            parts.append(f"age: {age}")
        if isinstance(language_code, str) and language_code.strip():
            parts.append(f"language: {language_code.strip().lower()}")
        if not parts:
            return None
        return ", ".join(parts)

    async def _fetch_cached_plan_summary(self, goal_id: str) -> Optional[PlanSummary]:
        payload = await self._select_plan_payload(goal_id)
        if not payload:
            return None
        return self._build_summary_from_payload(goal_id, payload)

    async def _select_plan_payload(self, goal_id: str) -> Optional[Dict[str, Any]]:
        cached_plan_query = text(
            """
            SELECT ap.plan_json
            FROM goals g
            LEFT JOIN ai_plans ap ON g.current_plan_id = ap.id
            WHERE g.id = :goal_id
            LIMIT 1
            """,
        )
        cached_plan_result = await self._db_session.execute(
            cached_plan_query,
            {"goal_id": goal_id},
        )
        cached_plan_record = cached_plan_result.mappings().first()
        plan_payload = cached_plan_record.get("plan_json") if cached_plan_record else None
        if plan_payload:
            return plan_payload

        fallback_query = text(
            """
            SELECT plan_json
            FROM ai_plans
            WHERE goal_id = :goal_id
            ORDER BY is_active DESC, version DESC, created_at DESC
            LIMIT 1
            """,
        )
        fallback_result = await self._db_session.execute(fallback_query, {"goal_id": goal_id})
        fallback_record = fallback_result.mappings().first()
        if fallback_record:
            return fallback_record.get("plan_json")
        return None

    async def _persist_plan_summary(
        self,
        goal_id: str,
        summary: PlanSummary,
        model_name: str,
        target_date: Optional[date],
        daily_time_commitment_minutes: Optional[int] = None,
    ) -> None:
        plan_payload = self._plan_payload_from_summary(summary, daily_time_commitment_minutes)
        plan_id = str(uuid4())
        version = await self._next_plan_version(goal_id)

        await self._db_session.execute(
            text("UPDATE ai_plans SET is_active = false WHERE goal_id = :goal_id"),
            {"goal_id": goal_id},
        )
        insert_query = text(
            """
            INSERT INTO ai_plans (
                id,
                goal_id,
                version,
                model_name,
                plan_json,
                summary,
                target_date,
                is_active
            )
            VALUES (
                :plan_id,
                :goal_id,
                :version,
                :model_name,
                CAST(:plan_json AS jsonb),
                :plan_summary,
                :target_date,
                true
            )
            """,
        )
        await self._db_session.execute(
            insert_query,
            {
                "plan_id": plan_id,
                "goal_id": goal_id,
                "version": version,
                "model_name": model_name,
                "plan_json": json.dumps(plan_payload),
                "plan_summary": summary.overview,
                "target_date": target_date,
            },
        )
        await self._db_session.execute(
            text(
                """
                UPDATE goals
                SET current_plan_id = :plan_id, updated_at = NOW()
                WHERE id = :goal_id
                """,
            ),
            {"plan_id": plan_id, "goal_id": goal_id},
        )
        await self._db_session.commit()

    async def _next_plan_version(self, goal_id: str) -> int:
        query = text(
            """
            SELECT COALESCE(MAX(version), 0) AS max_version
            FROM ai_plans
            WHERE goal_id = :goal_id
            """,
        )
        result = await self._db_session.execute(query, {"goal_id": goal_id})
        record = result.mappings().first()
        max_version = record.get("max_version") if record else 0
        try:
            version = int(max_version)
        except (TypeError, ValueError):
            version = 0
        return version + 1

    def _plan_payload_from_summary(
        self, 
        summary: PlanSummary,
        daily_time_commitment_minutes: Optional[int] = None,
    ) -> Dict[str, Any]:
        payload = {
            "overview": summary.overview,
            "estimated_duration_days": summary.estimated_duration_days,
            "phases": [phase.dict() for phase in summary.phases],
        }
        if daily_time_commitment_minutes is not None:
            payload["daily_time_commitment_minutes"] = daily_time_commitment_minutes
        return payload

    def _parse_daily_time_from_description(self, description: str) -> Optional[int]:
        """Parses 'Daily time: X' from goal description and converts to minutes.
        
        Returns:
            - 10 for '10 minutes'
            - 30 for '15–30 minutes'  
            - 60 for '30–60 minutes'
            - 90 for '1 hour or more'
            - None if 'Let AI decide' or not found
        """
        # Match pattern like "Daily time: 30–60 minutes" or "Daily time: Let AI decide"
        match = re.search(r"Daily time:\s*(.+?)(?:\n|$)", description, re.IGNORECASE)
        if not match:
            return None
        
        time_str = match.group(1).strip().lower()
        
        if "let ai decide" in time_str:
            return None
        
        if "10 minute" in time_str:
            return 10
        elif "15" in time_str and "30" in time_str:
            return 30
        elif "30" in time_str and "60" in time_str:
            return 60
        elif "hour" in time_str or "60" in time_str:
            return 90
        
        return None

    def _build_summary_from_payload(
        self,
        goal_id: str,
        payload: Dict[str, Any],
    ) -> PlanSummary:
        raw_phases = payload.get("phases") or []
        phases = []
        for raw_phase in raw_phases:
            if isinstance(raw_phase, dict):
                phases.append(
                    PlanPhase(
                        name=str(raw_phase.get("name", "")),
                        focus=str(raw_phase.get("focus", "")),
                        days_range=raw_phase.get("days_range"),
                    ),
                )
        return PlanSummary(
            goal_id=goal_id,
            overview=str(payload.get("overview", "")),
            phases=phases,
            estimated_duration_days=payload.get("estimated_duration_days"),
        )

    async def _generate_task_plan(self, goal_id: str) -> None:
        """Ensures the freshly generated summary also has daily tasks."""
        service = PlanTasksService(llm_client=self._llm_client, db_session=self._db_session)
        try:
            await service.generate_task_plan_for_goal(goal_id)
        except Exception as error:  # pragma: no cover - best-effort logging
            logger.warning("Task plan generation failed for goal %s: %s", goal_id, error)

    def _coerce_date(self, value: Any) -> Optional[date]:
        if value is None:
            return None
        if isinstance(value, date) and not isinstance(value, datetime):
            return value
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, str):
            try:
                return datetime.fromisoformat(value).date()
            except ValueError:
                return None
        return None

    def _resolve_target_date(self, goal: Dict[str, Any], summary: PlanSummary) -> date:
        existing = self._coerce_date(goal.get("target_date"))
        description = str(goal.get("description") or "").lower()
        user_delegated_duration = (
            "preferred completion" in description and "let ai decide" in description
        )
        estimated = summary.estimated_duration_days
        if user_delegated_duration and isinstance(estimated, int) and estimated > 0:
            return date.today() + timedelta(days=estimated - 1)
        if existing:
            return existing
        if isinstance(estimated, int) and estimated > 0:
            # Target date is inclusive, so subtract one day from the duration.
            return date.today() + timedelta(days=estimated - 1)
        return date.today() + timedelta(days=DEFAULT_PLAN_DURATION_DAYS - 1)

    async def _update_goal_target_date(self, goal_id: str, target_date: date) -> None:
        await self._db_session.execute(
            text(
                """
                UPDATE goals
                SET target_date = :target_date, updated_at = NOW()
                WHERE id = :goal_id
                """,
            ),
            {"goal_id": goal_id, "target_date": target_date},
        )
