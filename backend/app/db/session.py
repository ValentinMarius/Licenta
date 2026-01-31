# backend/app/db/session.py
# Creates async SQLAlchemy sessions wired through our shared settings object.
# Exists so API endpoints can depend on a consistent DB session provider.
# RELEVANT FILES:backend/app/api/plans.py,backend/app/services/plan_summary_service.py,backend/app/core/settings.py

from __future__ import annotations

from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from ..core.settings import get_settings

_session_factory: async_sessionmaker[AsyncSession] | None = None


def _get_session_factory() -> async_sessionmaker[AsyncSession]:
    global _session_factory
    if _session_factory is None:
        settings = get_settings()
        if not settings.database_url:
            raise RuntimeError(
                "DATABASE_URL must be set to create a database session.",
            )
        connect_args = {
            # Disable prepared statements because PgBouncer (transaction mode) rejects them.
            "statement_cache_size": 0,
        }
        engine = create_async_engine(
            settings.database_url,
            future=True,
            echo=False,
            connect_args=connect_args,
        )
        _session_factory = async_sessionmaker(
            engine,
            expire_on_commit=False,
            class_=AsyncSession,
        )
    return _session_factory


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency that yields an AsyncSession."""
    session_factory = _get_session_factory()
    async with session_factory() as session:
        yield session
