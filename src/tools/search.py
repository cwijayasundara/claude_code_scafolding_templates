"""Tavily search tool factory for the research agent."""

import logging

from langchain_core.tools import BaseTool
from langchain_tavily import TavilySearch

logger = logging.getLogger(__name__)

SEARCH_TOOL_NAME = "tavily_search"
DEFAULT_MAX_RESULTS = 5


def create_search_tool(
    api_key: str,
    max_results: int = DEFAULT_MAX_RESULTS,
) -> BaseTool:
    """Create a Tavily search tool for use with a LangGraph agent.

    Args:
        api_key: Tavily API key.
        max_results: Maximum number of search results per query.

    Returns:
        A configured TavilySearch tool instance.

    Raises:
        RuntimeError: If tool creation fails.
    """
    logger.info("Creating Tavily search tool (max_results=%d)", max_results)
    try:
        tool: BaseTool = TavilySearch(
            max_results=max_results,
            tavily_api_key=api_key,
        )
    except Exception as exc:
        logger.error("Failed to create search tool: %s", exc)
        msg = f"Failed to create Tavily search tool: {exc}"
        raise RuntimeError(msg) from exc
    logger.info("Tavily search tool created successfully")
    return tool
