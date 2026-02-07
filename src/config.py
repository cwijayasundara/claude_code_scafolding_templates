"""Configuration management using pydantic-settings."""

import logging
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

VALID_LOG_LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")

DEFAULT_MODEL = "openai:gpt-5-mini"
DEFAULT_MAX_SEARCH_RESULTS = 5
DEFAULT_OUTPUT_DIR = "output"
DEFAULT_LOG_LEVEL = "INFO"
MIN_SEARCH_RESULTS = 1
MAX_SEARCH_RESULTS_LIMIT = 20


class Settings(BaseSettings):  # type: ignore[call-arg]
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", frozen=True)

    openai_api_key: str
    tavily_api_key: str
    model: str = DEFAULT_MODEL
    max_search_results: int = DEFAULT_MAX_SEARCH_RESULTS
    output_dir: str = DEFAULT_OUTPUT_DIR
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = DEFAULT_LOG_LEVEL  # type: ignore[assignment]

    def model_post_init(self, __context: object) -> None:
        """Validate field constraints after initialization."""
        if not (MIN_SEARCH_RESULTS <= self.max_search_results <= MAX_SEARCH_RESULTS_LIMIT):
            msg = (
                f"max_search_results must be between {MIN_SEARCH_RESULTS} "
                f"and {MAX_SEARCH_RESULTS_LIMIT}, got {self.max_search_results}"
            )
            raise ValueError(msg)
        logger.debug(
            "Settings loaded: model=%s, max_results=%d",
            self.model,
            self.max_search_results,
        )
