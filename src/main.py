"""CLI entry point for the Deep Research Agent v2."""

import argparse
import logging
import sys
from pathlib import Path

from pydantic import ValidationError

from src.agent.researcher import create_research_agent, run_research
from src.config import Settings
from src.llm import create_llm
from src.report.generator import generate_report
from src.tools.search import create_search_tool

logger = logging.getLogger(__name__)

PROGRAM_NAME = "deep-research-v2"
PROGRAM_DESCRIPTION = "AI-powered multi-step research agent that produces Markdown reports."
EXIT_SUCCESS = 0
EXIT_FAILURE = 1


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments.

    Args:
        argv: Argument list (defaults to sys.argv[1:]).

    Returns:
        Parsed arguments namespace.
    """
    parser = argparse.ArgumentParser(
        prog=PROGRAM_NAME,
        description=PROGRAM_DESCRIPTION,
    )
    parser.add_argument("topic", help="Research topic or question")
    parser.add_argument("-o", "--output", help="File path to write the report to")
    parser.add_argument("-m", "--model", help="Override LLM model (e.g., openai:gpt-5-mini)")
    parser.add_argument("--max-results", type=int, help="Max search results per query")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable debug logging")
    return parser.parse_args(argv)


def setup_logging(verbose: bool = False) -> None:
    """Configure logging based on verbosity.

    Args:
        verbose: If True, set log level to DEBUG.
    """
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )


def write_output(report: str, output_path: str | None) -> None:
    """Write the report to stdout or a file.

    Args:
        report: The generated report string.
        output_path: File path to write to, or None for stdout.

    Raises:
        OSError: If file writing fails.
    """
    if output_path is None:
        print(report)
        return

    try:
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        Path(output_path).write_text(report, encoding="utf-8")
        logger.info("Report written to %s", output_path)
    except OSError as exc:
        logger.error("Failed to write report to '%s': %s", output_path, exc)
        raise


def main(argv: list[str] | None = None) -> None:
    """Run the Deep Research Agent v2 pipeline.

    Args:
        argv: Optional argument list for testing.
    """
    args = parse_args(argv)
    setup_logging(verbose=args.verbose)

    try:
        settings = _load_settings(args)
        llm = create_llm(settings.model)
        search_tool = create_search_tool(settings.tavily_api_key, settings.max_search_results)
        agent = create_research_agent(llm, [search_tool])
        findings = run_research(agent, args.topic)
        report = generate_report(args.topic, findings, settings.model)
        write_output(report, args.output)
    except ValidationError as exc:
        logger.error("Configuration error: %s", exc)
        sys.exit(
            "Error: missing or invalid configuration. "
            "Check your .env file or environment variables. See .env.example"
        )
    except (ValueError, RuntimeError) as exc:
        logger.error("Pipeline error: %s", exc)
        sys.exit(f"Error: {exc}")
    except OSError as exc:
        logger.error("File I/O error: %s", exc)
        sys.exit(f"Error: failed to write output file — {exc}")


def _load_settings(args: argparse.Namespace) -> Settings:
    """Load settings with optional CLI overrides.

    Args:
        args: Parsed CLI arguments.

    Returns:
        A Settings instance with CLI overrides applied.

    Raises:
        ValidationError: If configuration is invalid.
    """
    kwargs: dict[str, object] = {}
    if args.model is not None:
        kwargs["model"] = args.model
    if args.max_results is not None:
        kwargs["max_search_results"] = args.max_results
    return Settings(**kwargs)  # type: ignore[arg-type, call-arg]
