# backend/app/schemas/plan_summary.py
# Declares the API response models for the plan summary endpoint.
# Exists so FastAPI can validate/serialize summaries consistently.
# RELEVANT FILES:backend/app/api/plans.py,backend/app/services/plan_summary_service.py,backend/app/services/llm_client.py

from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel


class PlanPhase(BaseModel):
    name: str
    focus: str
    days_range: Optional[str] = None


class PlanSummary(BaseModel):
    goal_id: str
    overview: str
    phases: List[PlanPhase]
    estimated_duration_days: Optional[int] = None
