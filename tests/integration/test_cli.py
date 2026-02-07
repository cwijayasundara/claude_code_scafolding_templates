"""Integration tests for the full CLI pipeline."""

from unittest.mock import MagicMock, patch

import pytest

pytestmark = pytest.mark.integration


class TestFullPipeline:
    """Test the full CLI pipeline with all external deps mocked."""

    @patch("src.main.generate_report", return_value="# Research Report: Test\n\nContent")
    @patch("src.main.run_research", return_value="Research findings about quantum computing...")
    @patch("src.main.create_research_agent")
    @patch("src.main.create_search_tool")
    @patch("src.main.create_llm")
    @patch("src.main.Settings")
    def test_full_pipeline_produces_report(
        self,
        mock_settings: MagicMock,
        mock_llm: MagicMock,
        mock_tool: MagicMock,
        mock_agent: MagicMock,
        mock_research: MagicMock,
        mock_report: MagicMock,
        capsys: pytest.CaptureFixture[str],
    ) -> None:
        """Complete pipeline from topic to report output."""
        mock_settings.return_value = MagicMock(
            model="openai:gpt-5-mini",
            tavily_api_key="test-key",
            max_search_results=5,
        )
        from src.main import main

        main(["quantum computing advances"])

        captured = capsys.readouterr()
        assert "# Research Report: Test" in captured.out

        # Verify pipeline was called in order
        mock_settings.assert_called_once()
        mock_llm.assert_called_once()
        mock_tool.assert_called_once()
        mock_agent.assert_called_once()
        mock_research.assert_called_once()
        mock_report.assert_called_once()

    @patch("src.main.generate_report", return_value="# Report")
    @patch("src.main.run_research", return_value="findings")
    @patch("src.main.create_research_agent")
    @patch("src.main.create_search_tool")
    @patch("src.main.create_llm")
    @patch("src.main.Settings")
    def test_full_pipeline_with_model_override(
        self,
        mock_settings: MagicMock,
        mock_llm: MagicMock,
        mock_tool: MagicMock,
        mock_agent: MagicMock,
        mock_research: MagicMock,
        mock_report: MagicMock,
    ) -> None:
        """Pipeline passes CLI model override to Settings."""
        mock_settings.return_value = MagicMock(
            model="openai:gpt-4o",
            tavily_api_key="test-key",
            max_search_results=5,
        )
        from src.main import main

        main(["topic", "--model", "openai:gpt-4o"])
        mock_settings.assert_called_once_with(model="openai:gpt-4o")

    @patch("src.main.generate_report", return_value="# Report")
    @patch("src.main.run_research", return_value="findings")
    @patch("src.main.create_research_agent")
    @patch("src.main.create_search_tool")
    @patch("src.main.create_llm")
    @patch("src.main.Settings")
    def test_full_pipeline_writes_to_file(
        self,
        mock_settings: MagicMock,
        mock_llm: MagicMock,
        mock_tool: MagicMock,
        mock_agent: MagicMock,
        mock_research: MagicMock,
        mock_report: MagicMock,
        tmp_path: pytest.TempPathFactory,
    ) -> None:
        """Pipeline writes report to file when --output is specified."""
        mock_settings.return_value = MagicMock(
            model="openai:gpt-5-mini",
            tavily_api_key="test-key",
            max_search_results=5,
        )
        output_file = str(tmp_path / "out.md")  # type: ignore[operator]
        from pathlib import Path

        from src.main import main

        main(["topic", "--output", output_file])
        assert Path(output_file).read_text() == "# Report"
