"""Shared pytest configuration and fixtures."""

from datetime import UTC, datetime
from unittest.mock import MagicMock

import pytest
from langchain_core.language_models import BaseChatModel
from langchain_core.tools import BaseTool


def pytest_configure(config: pytest.Config) -> None:
    """Register custom markers."""
    config.addinivalue_line("markers", "unit: Unit tests (fast, no external dependencies)")
    config.addinivalue_line(
        "markers", "integration: Integration tests (may use real components, mock external)"
    )
    config.addinivalue_line("markers", "e2e: End-to-end tests (requires API keys)")


TEST_OPENAI_KEY = "test-openai-key"
TEST_TAVILY_KEY = "test-tavily-key"
TEST_MODEL = "openai:gpt-5-mini"
TEST_TOPIC = "impact of AI on healthcare"
TEST_FINDINGS = (
    "AI is transforming healthcare through improved diagnostics, "
    "drug discovery, and personalized medicine. "
    "Sources: https://example.com/ai-health, https://example.com/diagnostics"
)
TEST_TIMESTAMP = datetime(2025, 1, 15, 10, 30, 0, tzinfo=UTC)


@pytest.fixture
def required_env_vars(monkeypatch: pytest.MonkeyPatch) -> None:
    """Set the minimum required environment variables for Settings."""
    monkeypatch.setenv("OPENAI_API_KEY", TEST_OPENAI_KEY)
    monkeypatch.setenv("TAVILY_API_KEY", TEST_TAVILY_KEY)


@pytest.fixture
def mock_llm() -> MagicMock:
    """Provide a mock BaseChatModel instance."""
    return MagicMock(spec=BaseChatModel)


@pytest.fixture
def mock_search_tool() -> MagicMock:
    """Provide a mock search tool."""
    return MagicMock(spec=BaseTool)


@pytest.fixture
def mock_agent_response() -> dict[str, list[MagicMock]]:
    """Provide a mock agent response with messages."""
    message = MagicMock()
    message.content = TEST_FINDINGS
    return {"messages": [message]}


@pytest.fixture
def fixed_timestamp() -> datetime:
    """Provide a fixed timestamp for deterministic tests."""
    return TEST_TIMESTAMP
