"""Unit tests for src/config.py — Configuration Management."""

import pytest
from pydantic import ValidationError
from src.config import (
    DEFAULT_LOG_LEVEL,
    DEFAULT_MAX_SEARCH_RESULTS,
    DEFAULT_MODEL,
    DEFAULT_OUTPUT_DIR,
    Settings,
)

from tests.conftest import TEST_OPENAI_KEY, TEST_TAVILY_KEY

pytestmark = pytest.mark.unit


class TestSettingsDefaults:
    """Test that Settings loads correct default values."""

    def test_settings_loads_defaults_when_optional_vars_absent(
        self, required_env_vars: None
    ) -> None:
        """Settings applies defaults for optional fields."""
        settings = Settings()  # type: ignore[call-arg]
        assert settings.model == DEFAULT_MODEL
        assert settings.max_search_results == DEFAULT_MAX_SEARCH_RESULTS
        assert settings.log_level == DEFAULT_LOG_LEVEL
        assert settings.output_dir == DEFAULT_OUTPUT_DIR

    def test_settings_loads_required_keys(self, required_env_vars: None) -> None:
        """Settings reads required API keys from env vars."""
        settings = Settings()  # type: ignore[call-arg]
        assert settings.openai_api_key == TEST_OPENAI_KEY
        assert settings.tavily_api_key == TEST_TAVILY_KEY


class TestSettingsFromEnv:
    """Test that Settings reads values from environment variables."""

    def test_settings_loads_values_from_env_vars(
        self, monkeypatch: pytest.MonkeyPatch, required_env_vars: None
    ) -> None:
        """Settings reads all fields from environment variables."""
        monkeypatch.setenv("MODEL", "openai:gpt-4o")
        monkeypatch.setenv("MAX_SEARCH_RESULTS", "10")
        monkeypatch.setenv("LOG_LEVEL", "DEBUG")
        monkeypatch.setenv("OUTPUT_DIR", "reports")

        settings = Settings()  # type: ignore[call-arg]
        assert settings.model == "openai:gpt-4o"
        assert settings.max_search_results == 10
        assert settings.log_level == "DEBUG"
        assert settings.output_dir == "reports"


class TestSettingsValidation:
    """Test that Settings validates input correctly."""

    def test_settings_raises_validation_error_when_tavily_api_key_missing(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Missing TAVILY_API_KEY raises ValidationError."""
        monkeypatch.setenv("OPENAI_API_KEY", TEST_OPENAI_KEY)
        monkeypatch.delenv("TAVILY_API_KEY", raising=False)
        with pytest.raises(ValidationError):
            Settings()  # type: ignore[call-arg]

    def test_settings_raises_validation_error_when_openai_api_key_missing(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Missing OPENAI_API_KEY raises ValidationError."""
        monkeypatch.setenv("TAVILY_API_KEY", TEST_TAVILY_KEY)
        monkeypatch.delenv("OPENAI_API_KEY", raising=False)
        with pytest.raises(ValidationError):
            Settings()  # type: ignore[call-arg]

    def test_settings_raises_error_when_max_search_results_too_high(
        self, required_env_vars: None, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """max_search_results > 20 raises ValueError."""
        monkeypatch.setenv("MAX_SEARCH_RESULTS", "25")
        with pytest.raises((ValueError, Exception)):
            Settings()  # type: ignore[call-arg]

    def test_settings_raises_error_when_max_search_results_too_low(
        self, required_env_vars: None, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """max_search_results < 1 raises ValueError."""
        monkeypatch.setenv("MAX_SEARCH_RESULTS", "0")
        with pytest.raises((ValueError, Exception)):
            Settings()  # type: ignore[call-arg]
