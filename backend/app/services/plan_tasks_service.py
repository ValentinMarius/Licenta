# backend/app/services/plan_tasks_service.py
# Coordinates prompt creation, LLM invocation, and persistence for daily tasks.
# Exists so FastAPI handlers can turn plan summaries into executable task plans.
# RELEVANT FILES:backend/app/services/llm_client.py,backend/app/schemas/plan_tasks.py,backend/app/api/plans.py

from __future__ import annotations

import json
import logging
from datetime import date, datetime, timedelta
from typing import Any, Dict, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from ..schemas.plan_tasks import (
    TaskPlanPrompt,
    TaskPlanGenerationResult,
    TaskPlanResult,
    TasksForDayResponse,
)
from .llm_client import LlmClient

ALLOWED_LANGUAGES = {"en", "es", "zh", "hi", "ar", "ro"}
DEFAULT_PLAN_DURATION_DAYS = 30
PLAN_WINDOW_DAYS = 14
TASK_GENERATION_MODE = "windowed"
logger = logging.getLogger(__name__)


class ActivePlanNotFoundError(Exception):
    """Raised when no active ai_plan exists for the requested goal."""


class GoalTargetDateMissingError(Exception):
    """Raised when the goal lacks a target_date needed for scheduling."""


class TaskPlanValidationError(Exception):
    """Raised when the task-plan payload is invalid."""


class TaskPlanNotGeneratedError(Exception):
    """Raised when tasks are not yet generated for the requested day."""


class PlanTasksService:
    """Generates actionable tasks for a goal by leveraging the LLM agent."""

    def __init__(self, llm_client: LlmClient, db_session: AsyncSession) -> None:
        self._llm_client = llm_client
        self._db_session = db_session
        self._tasks_extended_schema: Optional[bool] = None

    async def generate_task_plan_for_goal(
        self,
        goal_id: str,
        start_day_index: Optional[int] = None,
        window_days: Optional[int] = None,
        start_date_override: Optional[date] = None,
    ) -> TaskPlanGenerationResult:
        try:
            goal = await self._fetch_goal(goal_id)
            plan = await self._fetch_active_plan(goal_id)
            if not plan:
                logger.warning("Task plan aborted: no active plan for goal %s", goal_id)
                raise ActivePlanNotFoundError("Goal has no active AI plan.")

            current_plan_payload = plan.get("plan_json") or {}
            plan_summary_text = plan.get("summary") or current_plan_payload.get("overview") or ""
            user_language = await self._fetch_user_language(goal.get("user_id"))
            user_context = await self._fetch_user_context(goal.get("user_id"))
            plan_target_date = self._coerce_date(plan.get("target_date"))
            goal_target_date = self._coerce_date(goal.get("target_date"))
            horizon_from_payload = self._positive_int(
                current_plan_payload.get("time_horizon_days")
            ) or self._positive_int(current_plan_payload.get("estimated_duration_days"))
            start_date_value = (
                start_date_override
                or self._coerce_date(goal.get("start_date"))
                or self._coerce_date(current_plan_payload.get("start_date"))
            )
            target_date = plan_target_date or goal_target_date
            if start_date_value is None and target_date and horizon_from_payload:
                start_date_value = target_date - timedelta(days=horizon_from_payload - 1)
            if start_date_value is None:
                start_date_value = date.today()
            if target_date is None:
                fallback_horizon = horizon_from_payload or DEFAULT_PLAN_DURATION_DAYS
                target_date = start_date_value + timedelta(days=fallback_horizon - 1)
            if not target_date:
                logger.warning("Task plan aborted: missing target_date for goal %s", goal_id)
                raise GoalTargetDateMissingError("Plan target_date is required.")

            goal_id_str = str(goal["id"])
            plan_id_str = str(plan["id"])
            prompt = TaskPlanPrompt(
                goal_id=goal_id_str,
                plan_id=plan_id_str,
                goal_title=goal.get("title") or "Untitled goal",
                goal_description=goal.get("description"),
                goal_category=goal.get("category"),
                start_date=start_date_value,
                target_date=target_date,
                plan_summary=plan_summary_text,
                estimated_duration_days=current_plan_payload.get("estimated_duration_days"),
                daily_time_commitment_minutes=current_plan_payload.get(
                    "daily_time_commitment_minutes",
                    30,
                ),
                user_language=user_language,
                user_context=user_context,
            )

            expected_days = max((target_date - start_date_value).days + 1, 1)
            window_size = max(1, window_days or PLAN_WINDOW_DAYS)
            window_size = min(window_size, expected_days)
            safe_start_index = max(0, start_day_index or 0)
            if safe_start_index >= expected_days:
                safe_start_index = max(expected_days - 1, 0)
            window_end_index = min(
                safe_start_index + window_size - 1,
                expected_days - 1,
            )
            window_size = window_end_index - safe_start_index + 1
            window_start_date = start_date_value + timedelta(days=safe_start_index)
            window_target_date = start_date_value + timedelta(days=window_end_index)

            plan_payload = plan.get("plan_json") or {}
            if not isinstance(plan_payload, dict):
                plan_payload = {}
            is_windowed = plan_payload.get("task_generation_mode") == TASK_GENERATION_MODE
            if not is_windowed and safe_start_index == 0:
                await self._trim_future_tasks(plan_id_str, window_end_index)

            existing_days = await self._fetch_existing_task_days(
                plan_id_str,
                safe_start_index,
                window_end_index,
            )
            if len(existing_days) == window_size:
                return TaskPlanGenerationResult(
                    goal_id=goal_id_str,
                    plan_id=plan_id_str,
                    window_start_day_index=safe_start_index,
                    window_end_day_index=window_end_index,
                    days_generated=0,
                    generated=False,
                )

            window_prompt = prompt.model_copy(
                update={
                    "start_date": window_start_date,
                    "target_date": window_target_date,
                    "estimated_duration_days": window_size,
                },
            )
            task_plan_raw = await self._llm_client.generate_task_plan(window_prompt)
            task_plan = self._normalize_task_plan(
                task_plan_raw,
                expected_days=window_size,
                day_index_offset=safe_start_index,
            )

            days_generated = await self._insert_task_plan_window(
                plan_id_str,
                goal_id_str,
                task_plan,
                start_date_value,
                existing_days,
            )
            await self._update_task_generation_metadata(
                plan_id_str,
                plan_payload,
                window_days=window_size,
                generated_until=window_end_index,
            )
            await self._db_session.commit()
            return TaskPlanGenerationResult(
                goal_id=goal_id_str,
                plan_id=plan_id_str,
                window_start_day_index=safe_start_index,
                window_end_day_index=window_end_index,
                days_generated=days_generated,
                generated=days_generated > 0,
            )
        except (ActivePlanNotFoundError, GoalTargetDateMissingError, TaskPlanValidationError):
            raise
        except Exception:
            logger.exception("Task plan generation crashed for goal %s", goal_id)
            raise

    async def _fetch_goal(self, goal_id: str) -> Dict[str, Any]:
        query = text(
            """
            SELECT id, user_id, title, description, target_date, start_date
            FROM goals
            WHERE id = :goal_id
            LIMIT 1
            """,
        )
        result = await self._db_session.execute(query, {"goal_id": goal_id})
        record = result.mappings().first()
        if not record:
            raise ActivePlanNotFoundError("Goal not found.")
        goal = dict(record)
        goal["target_date"] = self._coerce_date(goal.get("target_date"))
        goal["start_date"] = self._coerce_date(goal.get("start_date"))
        return goal

    async def _fetch_active_plan(self, goal_id: str) -> Optional[Dict[str, Any]]:
        query = text(
            """
            SELECT id, summary, plan_json, target_date
            FROM ai_plans
            WHERE goal_id = :goal_id
            ORDER BY is_active DESC, version DESC, created_at DESC
            LIMIT 1
            """,
        )
        result = await self._db_session.execute(query, {"goal_id": goal_id})
        record = result.mappings().first()
        if not record:
            return None
        row = dict(record)
        payload = row.get("plan_json")
        if isinstance(payload, str) and payload:
            try:
                row["plan_json"] = json.loads(payload)
            except json.JSONDecodeError:
                logger.warning("Malformed plan_json for plan %s; defaulting to {}", row.get("id"))
                row["plan_json"] = {}
        elif not isinstance(payload, dict):
            row["plan_json"] = {}
        row["target_date"] = self._coerce_date(row.get("target_date"))
        return row

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

    async def _insert_task_plan_window(
        self,
        plan_id: str,
        goal_id: str,
        task_plan: TaskPlanResult,
        plan_start_date: date,
        existing_days: set[int],
    ) -> int:
        """Stores generated tasks for missing days without overwriting existing ones."""
        inserted_days = 0
        if await self._supports_extended_task_schema():
            insert_query = text(
                """
                INSERT INTO tasks (
                    id,
                    goal_id,
                    plan_id,
                    day_index,
                    order_in_day,
                    description,
                    estimated_minutes,
                    planned_date,
                    task_type,
                    status,
                    created_at,
                    updated_at
                )
                VALUES (
                    gen_random_uuid(),
                    :goal_id,
                    :plan_id,
                    :day_index,
                    :order_in_day,
                    :description,
                    :estimated_minutes,
                    :planned_date,
                    :task_type,
                    :status,
                    NOW(),
                    NOW()
                )
                """,
            )
            for day in task_plan.days:
                if day.day_index in existing_days:
                    continue
                planned_date = plan_start_date + timedelta(days=day.day_index)
                inserted_days += 1
                for order_in_day, task in enumerate(day.tasks, start=1):
                    await self._db_session.execute(
                        insert_query,
                        {
                            "goal_id": goal_id,
                            "plan_id": plan_id,
                            "day_index": day.day_index,
                            "order_in_day": order_in_day,
                            "description": task.description,
                            "estimated_minutes": task.estimated_minutes,
                            "planned_date": planned_date,
                            "task_type": "core",
                            "status": "pending",
                        },
                    )
        else:
            insert_query = text(
                """
                INSERT INTO tasks (
                    id,
                    plan_id,
                    day_index,
                    order_in_day,
                    description,
                    estimated_minutes,
                    created_at
                )
                VALUES (
                    gen_random_uuid(),
                    :plan_id,
                    :day_index,
                    :order_in_day,
                    :description,
                    :estimated_minutes,
                    NOW()
                )
                """,
            )
            for day in task_plan.days:
                if day.day_index in existing_days:
                    continue
                inserted_days += 1
                for order_in_day, task in enumerate(day.tasks, start=1):
                    await self._db_session.execute(
                        insert_query,
                        {
                            "plan_id": plan_id,
                            "day_index": day.day_index,
                            "order_in_day": order_in_day,
                            "description": task.description,
                            "estimated_minutes": task.estimated_minutes,
                        },
                    )
        return inserted_days

    async def fetch_tasks_for_day(
        self,
        goal_id: str,
        day_index: int,
    ) -> TasksForDayResponse:
        """Returns ordered tasks for the selected day."""
        if day_index < 0:
            raise TaskPlanValidationError("day_index must be >= 0")
        plan = await self._fetch_active_plan(goal_id)
        if not plan:
            raise ActivePlanNotFoundError("No active plan found for goal.")
        plan_payload = plan.get("plan_json") or {}
        if isinstance(plan_payload, dict):
            generated_until = plan_payload.get("tasks_generated_until_day_index")
            if isinstance(generated_until, int) and generated_until >= 0:
                if day_index > generated_until:
                    raise TaskPlanNotGeneratedError(
                        "Tasks are not generated for this day yet."
                    )
        plan_id = str(plan["id"])
        tasks_query = text(
            """
            SELECT id, description, estimated_minutes, completed_at
            FROM tasks
            WHERE plan_id = :plan_id AND day_index = :day_index
            ORDER BY order_in_day ASC
            """,
        )
        result = await self._db_session.execute(
            tasks_query,
            {"plan_id": plan_id, "day_index": day_index},
        )
        rows = result.mappings().all()
        if not rows:
            raise TaskPlanNotGeneratedError("Tasks are not generated for this day yet.")
        return TasksForDayResponse(
            goal_id=goal_id,
            plan_id=plan_id,
            day_index=day_index,
            tasks=[
                {
                    "id": str(row["id"]),
                    "description": row.get("description") or "",
                    "estimated_minutes": row.get("estimated_minutes") or 0,
                    "completed_at": row.get("completed_at"),
                }
                for row in rows
            ],
        )

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

    def _positive_int(self, value: Any) -> Optional[int]:
        if isinstance(value, bool):
            return None
        if isinstance(value, int) and value > 0:
            return value
        if isinstance(value, float) and value > 0:
            return int(value)
        return None

    def _normalize_task_plan(
        self,
        task_plan: TaskPlanResult,
        expected_days: int,
        day_index_offset: int = 0,
    ) -> TaskPlanResult:
        """Ensures day indexes start at 0 and align with the requested horizon."""
        if not task_plan.days:
            return task_plan
        sorted_days = sorted(task_plan.days, key=lambda day: day.day_index)
        normalized_days = [
            day.model_copy(update={"day_index": index})
            for index, day in enumerate(sorted_days)
        ]
        horizon = expected_days if expected_days > 0 else len(normalized_days)
        trimmed_days = normalized_days[:horizon]
        if day_index_offset:
            trimmed_days = [
                day.model_copy(update={"day_index": day.day_index + day_index_offset})
                for day in trimmed_days
            ]
        return task_plan.model_copy(
            update={
                "days": trimmed_days,
                "time_horizon_days": len(trimmed_days),
            },
        )

    async def _trim_future_tasks(self, plan_id: str, max_day_index: int) -> None:
        await self._db_session.execute(
            text(
                """
                DELETE FROM tasks
                WHERE plan_id = :plan_id AND day_index > :max_day_index
                """,
            ),
            {"plan_id": plan_id, "max_day_index": max_day_index},
        )

    async def _update_task_generation_metadata(
        self,
        plan_id: str,
        plan_payload: dict,
        window_days: int,
        generated_until: int,
    ) -> None:
        existing_until = plan_payload.get("tasks_generated_until_day_index")
        if isinstance(existing_until, int):
            generated_until = max(existing_until, generated_until)
        plan_payload = {
            **plan_payload,
            "task_generation_mode": TASK_GENERATION_MODE,
            "tasks_window_days": window_days,
            "tasks_generated_until_day_index": generated_until,
        }
        await self._db_session.execute(
            text(
                """
                UPDATE ai_plans
                SET plan_json = CAST(:plan_json AS jsonb),
                    updated_at = NOW()
                WHERE id = :plan_id
                """,
            ),
            {
                "plan_id": plan_id,
                "plan_json": json.dumps(plan_payload),
            },
        )

    async def _fetch_existing_task_days(
        self,
        plan_id: str,
        start_day_index: int,
        end_day_index: int,
    ) -> set[int]:
        query = text(
            """
            SELECT day_index, COUNT(*) AS task_count
            FROM tasks
            WHERE plan_id = :plan_id
              AND day_index BETWEEN :start_day AND :end_day
            GROUP BY day_index
            """,
        )
        result = await self._db_session.execute(
            query,
            {
                "plan_id": plan_id,
                "start_day": start_day_index,
                "end_day": end_day_index,
            },
        )
        rows = result.mappings().all()
        return {
            int(row["day_index"]) for row in rows if row.get("task_count", 0) > 0
        }

    async def _supports_extended_task_schema(self) -> bool:
        if self._tasks_extended_schema is not None:
            return self._tasks_extended_schema
        query = text(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'tasks'
            """,
        )
        result = await self._db_session.execute(query)
        columns = {row["column_name"] for row in result.mappings()}
        required = {"goal_id", "planned_date", "task_type", "status", "updated_at"}
        self._tasks_extended_schema = required.issubset(columns)
        return self._tasks_extended_schema
