"""Unit tests for src/tools/search.py — Tavily Search Tool."""

from unittest.mock import MagicMock, patch

import pytest
from src.tools.search import DEFAULT_MAX_RESULTS, create_search_tool

pytestmark = pytest.mark.unit

TEST_API_KEY = "test-tavily-key"


class TestCreateSearchTool:
    """Test the create_search_tool factory function."""

    @patch("src.tools.search.TavilySearch")
    def test_create_search_tool_returns_tool_instance(
        self, mock_tavily_cls: MagicMock
    ) -> None:
        """create_search_tool returns a tool instance."""
        mock_tool = MagicMock()
        mock_tavily_cls.return_value = mock_tool
        result = create_search_tool(TEST_API_KEY)
        assert result is mock_tool

    @patch("src.tools.search.TavilySearch")
    def test_create_search_tool_passes_max_results(
        self, mock_tavily_cls: MagicMock
    ) -> None:
        """max_results parameter is passed to TavilySearch."""
        create_search_tool(TEST_API_KEY, max_results=10)
        mock_tavily_cls.assert_called_once_with(max_results=10, tavily_api_key=TEST_API_KEY)

    @patch("src.tools.search.TavilySearch")
    def test_create_search_tool_uses_default_max_results(
        self, mock_tavily_cls: MagicMock
    ) -> None:
        """Default max_results is used when not specified."""
        create_search_tool(TEST_API_KEY)
        mock_tavily_cls.assert_called_once_with(
            max_results=DEFAULT_MAX_RESULTS, tavily_api_key=TEST_API_KEY
        )

    @patch(
        "src.tools.search.TavilySearch",
        side_effect=Exception("Invalid API key"),
    )
    def test_create_search_tool_raises_runtime_error_on_failure(
        self, mock_tavily_cls: MagicMock
    ) -> None:
        """Tool creation failure is wrapped in RuntimeError."""
        with pytest.raises(RuntimeError, match="Failed to create Tavily search tool"):
            create_search_tool(TEST_API_KEY)
