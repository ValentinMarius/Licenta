from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """Holds all runtime configuration for the backend stack."""

    environment: str = "development"
    app_name: str = "Treespora Backend"

    # O facem obligatorie și ne asigurăm că citește fix din DATABASE_URL
    database_url: str = Field(..., alias="DATABASE_URL")

    deepseek_base_url: str = Field(..., alias="DEEPSEEK_BASE_URL")
    deepseek_api_key: str = Field(..., alias="DEEPSEEK_API_KEY")
    deepseek_model: str = Field(..., alias="DEEPSEEK_MODEL")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    """Returns a cached Settings instance so every import shares the same object."""
    return Settings()
