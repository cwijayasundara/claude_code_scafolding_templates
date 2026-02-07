"""Research agent built with LangGraph ReAct pattern."""

import logging

from langchain_core.language_models import BaseChatModel
from langchain_core.tools import BaseTool
from langgraph.graph.state import CompiledStateGraph
from langgraph.prebuilt import create_react_agent

from src.agent.prompts import RESEARCH_SYSTEM_PROMPT

logger = logging.getLogger(__name__)

USER_ROLE = "user"


def create_research_agent(
    llm: BaseChatModel,
    tools: list[BaseTool],
    system_prompt: str = RESEARCH_SYSTEM_PROMPT,
) -> CompiledStateGraph:
    """Create a LangGraph ReAct research agent.

    Args:
        llm: The language model to use for reasoning.
        tools: List of tools the agent can use (e.g., search).
        system_prompt: System instructions for the agent.

    Returns:
        A compiled LangGraph agent ready for invocation.
    """
    logger.info("Creating research agent with %d tools", len(tools))
    agent = create_react_agent(model=llm, tools=tools, prompt=system_prompt)
    logger.info("Research agent created successfully")
    return agent


def run_research(agent: CompiledStateGraph, topic: str) -> str:
    """Run the research agent on a given topic.

    Args:
        agent: A compiled LangGraph agent.
        topic: The research topic or question.

    Returns:
        The agent's final research findings as a string.

    Raises:
        RuntimeError: If the agent invocation fails.
    """
    logger.info("Starting research on topic: %s", topic)
    try:
        result = agent.invoke({"messages": [(USER_ROLE, topic)]})
    except Exception as exc:
        logger.error("Research agent failed: %s", exc)
        msg = f"Research agent failed for topic '{topic}': {exc}"
        raise RuntimeError(msg) from exc

    messages = result.get("messages", [])
    if not messages:
        logger.warning("Agent returned no messages for topic: %s", topic)
        return ""

    final_content = messages[-1].content
    logger.info("Research completed for topic: %s", topic)
    return str(final_content)
