# backend/app/schemas/plan_tasks.py
# Declares the prompt/result contracts for generating daily AI tasks.
# Exists so both LLM services and API layers share one validated schema.
# RELEVANT FILES:backend/app/services/plan_tasks_service.py,backend/app/services/llm_client.py,backend/app/api/plans.py

from __future__ import annotations

from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class TaskPlanTask(BaseModel):
    """Concrete actionable task that lands in Supabase tasks."""

    description: str = Field(
        ...,
        min_length=1,
        description="Short actionable instruction for the user.",
    )
    estimated_minutes: int = Field(
        ...,
        ge=5,
        le=60,
        description="Estimated effort required to finish the task.",
    )


class TaskPlanDay(BaseModel):
    """Represents one calendar day in the generated plan."""

    day_index: int = Field(
        ...,
        ge=0,
        description="Zero-based index relative to start_date.",
    )
    label: str = Field(
        ...,
        min_length=1,
        description="User-facing label such as 'Day 1'.",
    )
    focus: str = Field(
        ...,
        min_length=1,
        description="Short summary describing the intention for the day.",
    )
    tasks: List[TaskPlanTask] = Field(
        ...,
        min_items=1,
        max_items=3,
        description="Between 1 and 3 actionable tasks for the day.",
    )


class TaskPlanResult(BaseModel):
    """Full payload stored into ai_plans.plan_json."""

    goal_id: str = Field(..., description="Supabase goals.id.")
    plan_id: str = Field(..., description="Supabase ai_plans.id.")
    version: int = Field(
        ...,
        ge=1,
        description="Plan version; backend may overwrite this value.",
    )
    summary: str = Field(
        ...,
        description="Read-only plan summary carried from ai_plans.summary.",
    )
    time_horizon_days: int = Field(
        ...,
        ge=1,
        description="Number of days in the generated plan horizon.",
    )
    daily_time_commitment_minutes: int = Field(
        ...,
        ge=5,
        description="Desired daily time budget coming from user preferences.",
    )
    start_date: date = Field(
        ...,
        description="Calendar date corresponding to day_index = 0.",
    )
    days: List[TaskPlanDay] = Field(
        ...,
        min_items=1,
        description="Continuous set of day definitions for the plan.",
    )


class TaskPlanPrompt(BaseModel):
    """
    Input contract shared with the LLM agent that generates daily tasks.

    IMPORTANT:
    - plan_summary is read-only (already saved in ai_plans.summary / plan_json.overview)
    - this prompt must not modify the summary; it only consumes it to craft tasks
    """

    goal_id: str = Field(..., description="Supabase goals.id")
    plan_id: str = Field(..., description="Supabase ai_plans.id (active plan)")
    goal_title: str = Field(..., description="User-facing title of the goal")
    goal_description: Optional[str] = Field(
        None,
        description="Optional longer description for additional context.",
    )
    goal_category: Optional[str] = Field(
        None,
        description="Optional goal category (learning/fitness/career/other/etc.).",
    )
    start_date: date = Field(
        ...,
        description=(
            "Calendar date when daily tasks should start. "
            "Maps directly to day_index = 0."
        ),
    )
    target_date: date = Field(
        ...,
        description="Final calendar date (inclusive) for this plan horizon.",
    )
    plan_summary: str = Field(
        ...,
        description="Existing plan summary text; strictly read-only context.",
    )
    estimated_duration_days: Optional[int] = Field(
        None,
        description=(
            "Optional count of days reported by the plan summary. "
            "Useful for ensuring the daily sequence matches expectations."
        ),
    )
    daily_time_commitment_minutes: int = Field(
        30,
        ge=5,
        le=300,
        description="Desired effort per day; used to constrain task durations.",
    )
    user_language: Optional[str] = Field(
        None,
        description="User language code so tasks can be localized if needed.",
    )
    user_context: Optional[str] = Field(
        None,
        description="Optional lightweight profile context (age_range, language, etc.).",
    )


class DailyTaskPayload(BaseModel):
    """Represents a stored task returned via the daily tasks endpoint."""

    id: str = Field(..., description="tasks.id primary key.")
    description: str = Field(..., description="Human-facing description.")
    estimated_minutes: int = Field(
        ...,
        ge=5,
        description="Estimated effort in minutes.",
    )
    completed_at: Optional[datetime] = Field(
        None,
        description="When the task was completed, if available.",
    )


class TasksForDayResponse(BaseModel):
    """API response for GET /goals/{goal_id}/tasks."""

    goal_id: str = Field(..., description="Supabase goals.id.")
    plan_id: str = Field(..., description="ai_plans.id containing the tasks.")
    day_index: int = Field(..., ge=0, description="Zero-based day index.")
    tasks: List[DailyTaskPayload] = Field(
        default_factory=list,
        description="Ordered list of user-facing tasks.",
    )
