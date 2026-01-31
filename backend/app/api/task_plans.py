# backend/app/api/task_plans.py
# Exposes HTTP endpoints for generating structured daily task plans.
# Exists so clients can trigger LLM-backed task generation per goal.
# RELEVANT FILES:backend/app/services/plan_tasks_service.py,backend/app/schemas/plan_tasks.py,backend/app/services/llm_client.py

from __future__ import annotations

import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.session import get_db_session
from ..schemas.plan_tasks import TaskPlanResult, TasksForDayResponse
from ..services.llm_client import LlmClient, LlmClientError, get_llm_client
from ..services.plan_tasks_service import (
    ActivePlanNotFoundError,
    GoalTargetDateMissingError,
    PlanTasksService,
    TaskPlanValidationError,
)

router = APIRouter(prefix="/goals", tags=["task_plans"])
logger = logging.getLogger(__name__)


def get_plan_tasks_service(
    db_session: AsyncSession = Depends(get_db_session),
    llm_client: LlmClient = Depends(get_llm_client),
) -> PlanTasksService:
    """FastAPI dependency for injecting PlanTasksService."""
    return PlanTasksService(llm_client=llm_client, db_session=db_session)


@router.post(
    "/{goal_id}/task_plan",
    response_model=TaskPlanResult,
    status_code=status.HTTP_200_OK,
)
async def generate_task_plan(
    goal_id: UUID,
    service: PlanTasksService = Depends(get_plan_tasks_service),
) -> TaskPlanResult:
    """
    Generate (or regenerate) the daily tasks for a goal.

    This endpoint:
    - fetches goal + active summary,
    - constructs TaskPlanPrompt,
    - calls the LLM,
    - updates ai_plans.plan_json,
    - replaces all rows in `tasks`.
    """
    try:
        return await service.generate_task_plan_for_goal(str(goal_id))
    except ActivePlanNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"detail": "plan_not_found", "message": str(error)},
        ) from error
    except GoalTargetDateMissingError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"detail": "missing_target_date", "message": str(error)},
        ) from error
    except TaskPlanValidationError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"detail": "task_plan_invalid", "message": str(error)},
        ) from error
    except LlmClientError as error:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"detail": "llm_error", "message": error.message},
        ) from error
    except HTTPException:
        raise
    except Exception as error:  # pragma: no cover - safety net
        logger.exception("Unexpected failure while generating task plan for goal %s", goal_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"detail": "task_plan_failed", "message": "task plan generation failed"},
        ) from error


@router.get(
    "/{goal_id}/tasks",
    response_model=TasksForDayResponse,
    status_code=status.HTTP_200_OK,
)
async def get_tasks_for_day(
    goal_id: UUID,
    day_index: int = Query(..., ge=0),
    service: PlanTasksService = Depends(get_plan_tasks_service),
) -> TasksForDayResponse:
    """Expose generated tasks for the selected day."""
    try:
        return await service.fetch_tasks_for_day(str(goal_id), day_index)
    except ActivePlanNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"detail": "plan_not_found", "message": str(error)},
        ) from error
    except TaskPlanValidationError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"detail": "task_plan_invalid", "message": str(error)},
        ) from error
    except HTTPException:
        raise
    except Exception as error:  # pragma: no cover - safety net
        logger.exception(
            "Unexpected failure while fetching tasks for goal %s day_index=%s",
            goal_id,
            day_index,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "detail": "tasks_fetch_failed",
                "message": "Could not load tasks for this day",
            },
        ) from error
