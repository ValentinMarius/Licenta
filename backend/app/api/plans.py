# backend/app/api/plans.py
# Exposes HTTP endpoints for plan/goal related operations.
# Exists so the Flutter app can request LLM-backed plan summaries.
# RELEVANT FILES:backend/app/services/plan_summary_service.py,backend/app/schemas/plan_summary.py,backend/app/services/llm_client.py

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.session import get_db_session
from ..schemas.plan_summary import PlanSummary
from ..services.llm_client import LlmClient, LlmClientError, get_llm_client
from ..services.plan_summary_service import (
    GoalNotFoundError,
    PlanSummaryService,
)

router = APIRouter(prefix="", tags=["plans"])
logger = logging.getLogger(__name__)


@router.get(
    "/goals/{goal_id}/plan/summary",
    response_model=PlanSummary,
    status_code=status.HTTP_200_OK,
)
async def get_plan_summary(
    goal_id: str,
    db_session: AsyncSession = Depends(get_db_session),
    llm_client: LlmClient = Depends(get_llm_client),
) -> PlanSummary:
    service = PlanSummaryService(llm_client=llm_client, db_session=db_session)
    try:
        return await service.get_or_generate_plan_summary(goal_id)
    except GoalNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"detail": "goal_not_found", "message": str(error)},
        ) from error
    except LlmClientError as error:
        logger.warning(
            "Plan summary LLM error for goal %s: %s",
            goal_id,
            error,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"detail": "llm_error", "message": error.message},
        ) from error
    except HTTPException:
        raise
    except Exception as error:
        logger.exception("Plan summary failed for goal %s", goal_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "detail": "internal_error",
                "message": "plan summary failed",
            },
        ) from error
