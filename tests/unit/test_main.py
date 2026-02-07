"""Unit tests for src/main.py — CLI Interface."""

from unittest.mock import MagicMock, patch

import pytest
from src.main import parse_args

pytestmark = pytest.mark.unit


class TestParseArgs:
    """Test the parse_args function."""

    def test_parse_args_extracts_topic(self) -> None:
        """Positional topic argument is extracted."""
        args = parse_args(["AI safety research"])
        assert args.topic == "AI safety research"

    def test_parse_args_extracts_output_flag(self) -> None:
        """--output flag is parsed correctly."""
        args = parse_args(["quantum computing", "--output", "report.md"])
        assert args.output == "report.md"

    def test_parse_args_extracts_short_output_flag(self) -> None:
        """-o shorthand for --output works."""
        args = parse_args(["topic", "-o", "out.md"])
        assert args.output == "out.md"

    def test_parse_args_extracts_model_flag(self) -> None:
        """--model flag is parsed correctly."""
        args = parse_args(["topic", "--model", "openai:gpt-4o"])
        assert args.model == "openai:gpt-4o"

    def test_parse_args_extracts_max_results_flag(self) -> None:
        """--max-results flag is parsed as integer."""
        args = parse_args(["topic", "--max-results", "10"])
        assert args.max_results == 10

    def test_parse_args_extracts_verbose_flag(self) -> None:
        """--verbose flag sets verbose to True."""
        args = parse_args(["topic", "--verbose"])
        assert args.verbose is True

    def test_parse_args_defaults_are_none(self) -> None:
        """Optional flags default to None/False when not provided."""
        args = parse_args(["just a topic"])
        assert args.output is None
        assert args.model is None
        assert args.max_results is None
        assert args.verbose is False


class TestMainErrorHandling:
    """Test main() error handling paths."""

    @patch("src.main.Settings")
    def test_main_exits_on_config_error(self, mock_settings: MagicMock) -> None:
        """Configuration error produces SystemExit."""
        from pydantic import ValidationError

        mock_settings.side_effect = ValidationError.from_exception_data(
            title="Settings",
            line_errors=[],
        )
        from src.main import main

        with pytest.raises(SystemExit):
            main(["test topic"])

    @patch("src.main.generate_report", return_value="# Report")
    @patch("src.main.run_research", return_value="findings")
    @patch("src.main.create_research_agent")
    @patch("src.main.create_search_tool")
    @patch("src.main.create_llm", side_effect=ValueError("bad model"))
    @patch("src.main.Settings")
    def test_main_exits_on_llm_error(
        self,
        mock_settings: MagicMock,
        mock_llm: MagicMock,
        mock_tool: MagicMock,
        mock_agent: MagicMock,
        mock_research: MagicMock,
        mock_report: MagicMock,
    ) -> None:
        """LLM initialization error produces SystemExit."""
        mock_settings.return_value = MagicMock(
            model="bad", tavily_api_key="key", max_search_results=5
        )
        from src.main import main

        with pytest.raises(SystemExit):
            main(["test topic"])

    @patch("src.main.generate_report", return_value="# Report")
    @patch("src.main.run_research", return_value="findings")
    @patch("src.main.create_research_agent")
    @patch("src.main.create_search_tool")
    @patch("src.main.create_llm")
    @patch("src.main.Settings")
    def test_main_writes_to_stdout_by_default(
        self,
        mock_settings: MagicMock,
        mock_llm: MagicMock,
        mock_tool: MagicMock,
        mock_agent: MagicMock,
        mock_research: MagicMock,
        mock_report: MagicMock,
        capsys: pytest.CaptureFixture[str],
    ) -> None:
        """Report is printed to stdout when no --output specified."""
        mock_settings.return_value = MagicMock(
            model="openai:gpt-5-mini",
            tavily_api_key="key",
            max_search_results=5,
        )
        from src.main import main

        main(["test topic"])
        captured = capsys.readouterr()
        assert "# Report" in captured.out

    @patch("src.main.generate_report", return_value="# Report")
    @patch("src.main.run_research", return_value="findings")
    @patch("src.main.create_research_agent")
    @patch("src.main.create_search_tool")
    @patch("src.main.create_llm")
    @patch("src.main.Settings")
    def test_main_writes_to_file_when_output_specified(
        self,
        mock_settings: MagicMock,
        mock_llm: MagicMock,
        mock_tool: MagicMock,
        mock_agent: MagicMock,
        mock_research: MagicMock,
        mock_report: MagicMock,
        tmp_path: pytest.TempPathFactory,
    ) -> None:
        """Report is written to file when --output is specified."""
        mock_settings.return_value = MagicMock(
            model="openai:gpt-5-mini",
            tavily_api_key="key",
            max_search_results=5,
        )
        output_file = str(tmp_path / "report.md")  # type: ignore[operator]
        from src.main import main

        main(["test topic", "--output", output_file])
        from pathlib import Path

        content = Path(output_file).read_text()
        assert "# Report" in content

    @patch("src.main.generate_report", return_value="# Report")
    @patch("src.main.run_research", side_effect=RuntimeError("API timeout"))
    @patch("src.main.create_research_agent")
    @patch("src.main.create_search_tool")
    @patch("src.main.create_llm")
    @patch("src.main.Settings")
    def test_main_exits_on_research_error(
        self,
        mock_settings: MagicMock,
        mock_llm: MagicMock,
        mock_tool: MagicMock,
        mock_agent: MagicMock,
        mock_research: MagicMock,
        mock_report: MagicMock,
    ) -> None:
        """Research error produces SystemExit."""
        mock_settings.return_value = MagicMock(
            model="openai:gpt-5-mini",
            tavily_api_key="key",
            max_search_results=5,
        )
        from src.main import main

        with pytest.raises(SystemExit):
            main(["test topic"])
