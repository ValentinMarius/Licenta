# backend/app/main.py
# Creates the FastAPI application and wires routers plus simple diagnostics.
# Exists so uvicorn can import a single ASGI callable when booting the backend.
# RELEVANT FILES:backend/app/api/plans.py,backend/app/core/settings.py,backend/app/db/session.py

from __future__ import annotations

from fastapi import FastAPI

from .api import plans, task_plans
from .core.settings import get_settings

settings = get_settings()
print("=== DB URL USED BY BACKEND ===")
print(settings.database_url)
print("================================")




app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.include_router(plans.router, prefix="/v1")
app.include_router(task_plans.router, prefix="/v1")


@app.get("/health", tags=["health"])
async def healthcheck() -> dict:
    """Lightweight endpoint for uptime checks."""
    return {
        "status": "ok",
        "environment": settings.environment,
        "service": settings.app_name,
    }
