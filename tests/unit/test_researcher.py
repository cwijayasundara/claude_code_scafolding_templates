"""Unit tests for src/agent/researcher.py — Research Agent."""

from unittest.mock import MagicMock, patch

import pytest
from src.agent.prompts import RESEARCH_SYSTEM_PROMPT
from src.agent.researcher import create_research_agent, run_research

from tests.conftest import TEST_FINDINGS, TEST_TOPIC

pytestmark = pytest.mark.unit


class TestCreateResearchAgent:
    """Test the create_research_agent factory."""

    @patch("src.agent.researcher.create_react_agent")
    def test_create_agent_returns_compiled_graph(
        self, mock_create: MagicMock, mock_llm: MagicMock, mock_search_tool: MagicMock
    ) -> None:
        """create_research_agent returns the graph from create_react_agent."""
        mock_graph = MagicMock()
        mock_create.return_value = mock_graph
        result = create_research_agent(mock_llm, [mock_search_tool])
        assert result is mock_graph

    @patch("src.agent.researcher.create_react_agent")
    def test_create_agent_passes_tools(
        self, mock_create: MagicMock, mock_llm: MagicMock, mock_search_tool: MagicMock
    ) -> None:
        """Tools list is passed to create_react_agent."""
        create_research_agent(mock_llm, [mock_search_tool])
        call_kwargs = mock_create.call_args.kwargs
        assert call_kwargs["tools"] == [mock_search_tool]

    @patch("src.agent.researcher.create_react_agent")
    def test_create_agent_passes_llm(
        self, mock_create: MagicMock, mock_llm: MagicMock, mock_search_tool: MagicMock
    ) -> None:
        """LLM instance is passed to create_react_agent."""
        create_research_agent(mock_llm, [mock_search_tool])
        call_kwargs = mock_create.call_args.kwargs
        assert call_kwargs["model"] is mock_llm

    @patch("src.agent.researcher.create_react_agent")
    def test_create_agent_passes_system_prompt(
        self, mock_create: MagicMock, mock_llm: MagicMock, mock_search_tool: MagicMock
    ) -> None:
        """System prompt is passed to create_react_agent."""
        create_research_agent(mock_llm, [mock_search_tool], system_prompt="custom prompt")
        call_kwargs = mock_create.call_args.kwargs
        assert call_kwargs["prompt"] == "custom prompt"

    @patch("src.agent.researcher.create_react_agent")
    def test_create_agent_uses_default_system_prompt(
        self, mock_create: MagicMock, mock_llm: MagicMock, mock_search_tool: MagicMock
    ) -> None:
        """Default system prompt is RESEARCH_SYSTEM_PROMPT."""
        create_research_agent(mock_llm, [mock_search_tool])
        call_kwargs = mock_create.call_args.kwargs
        assert call_kwargs["prompt"] == RESEARCH_SYSTEM_PROMPT


class TestRunResearch:
    """Test the run_research function."""

    def test_run_research_returns_string_result(
        self, mock_agent_response: dict[str, list[MagicMock]]
    ) -> None:
        """run_research extracts the final message content as a string."""
        mock_agent = MagicMock()
        mock_agent.invoke.return_value = mock_agent_response
        result = run_research(mock_agent, TEST_TOPIC)
        assert result == TEST_FINDINGS

    def test_run_research_invokes_agent_with_topic(self) -> None:
        """Agent is invoked with the topic in messages format."""
        mock_agent = MagicMock()
        mock_agent.invoke.return_value = {"messages": [MagicMock(content="result")]}
        run_research(mock_agent, TEST_TOPIC)
        mock_agent.invoke.assert_called_once_with({"messages": [("user", TEST_TOPIC)]})

    def test_run_research_returns_empty_string_when_no_messages(self) -> None:
        """run_research returns empty string when agent returns no messages."""
        mock_agent = MagicMock()
        mock_agent.invoke.return_value = {"messages": []}
        result = run_research(mock_agent, TEST_TOPIC)
        assert result == ""

    def test_run_research_raises_runtime_error_on_failure(self) -> None:
        """Agent invocation failure is wrapped in RuntimeError."""
        mock_agent = MagicMock()
        mock_agent.invoke.side_effect = Exception("API timeout")
        with pytest.raises(RuntimeError, match="Research agent failed"):
            run_research(mock_agent, TEST_TOPIC)


class TestSystemPrompt:
    """Test the RESEARCH_SYSTEM_PROMPT constant."""

    def test_system_prompt_is_non_empty_string(self) -> None:
        """System prompt is a non-empty string."""
        assert isinstance(RESEARCH_SYSTEM_PROMPT, str)
        assert len(RESEARCH_SYSTEM_PROMPT) > 0

    def test_system_prompt_includes_research_instructions(self) -> None:
        """System prompt contains research-related instruction keywords."""
        prompt_lower = RESEARCH_SYSTEM_PROMPT.lower()
        assert "search" in prompt_lower
        assert "research" in prompt_lower

    def test_system_prompt_includes_citation_requirements(self) -> None:
        """System prompt contains citation-related keywords."""
        prompt_lower = RESEARCH_SYSTEM_PROMPT.lower()
        assert "source" in prompt_lower or "cite" in prompt_lower
        assert "url" in prompt_lower or "reference" in prompt_lower

    def test_system_prompt_includes_output_format(self) -> None:
        """System prompt mentions output structure."""
        prompt_lower = RESEARCH_SYSTEM_PROMPT.lower()
        assert "summary" in prompt_lower
        assert "findings" in prompt_lower
