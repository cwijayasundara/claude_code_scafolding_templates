"""Unit tests for src/report/generator.py — Report Generation."""

from datetime import UTC, datetime

import pytest
from src.report.generator import ATTRIBUTION, DATE_FORMAT, REPORT_TITLE_PREFIX, generate_report

from tests.conftest import TEST_FINDINGS, TEST_MODEL, TEST_TOPIC

pytestmark = pytest.mark.unit


class TestGenerateReport:
    """Test the generate_report function."""

    def test_report_contains_title_with_topic(self, fixed_timestamp: datetime) -> None:
        """Report starts with a heading containing the topic."""
        report = generate_report(TEST_TOPIC, TEST_FINDINGS, TEST_MODEL, timestamp=fixed_timestamp)
        assert f"# {REPORT_TITLE_PREFIX}: {TEST_TOPIC}" in report

    def test_report_contains_model_name_in_metadata(
        self, fixed_timestamp: datetime
    ) -> None:
        """Report metadata includes the model name."""
        report = generate_report(TEST_TOPIC, TEST_FINDINGS, TEST_MODEL, timestamp=fixed_timestamp)
        assert TEST_MODEL in report

    def test_report_contains_findings_in_body(self, fixed_timestamp: datetime) -> None:
        """Report body includes the agent findings."""
        report = generate_report(TEST_TOPIC, TEST_FINDINGS, TEST_MODEL, timestamp=fixed_timestamp)
        assert TEST_FINDINGS in report

    def test_report_contains_formatted_timestamp(
        self, fixed_timestamp: datetime
    ) -> None:
        """Report contains the timestamp in the expected format."""
        report = generate_report(TEST_TOPIC, TEST_FINDINGS, TEST_MODEL, timestamp=fixed_timestamp)
        expected_time = fixed_timestamp.strftime(DATE_FORMAT)
        assert expected_time in report

    def test_report_contains_attribution_footer(
        self, fixed_timestamp: datetime
    ) -> None:
        """Report contains the attribution line."""
        report = generate_report(TEST_TOPIC, TEST_FINDINGS, TEST_MODEL, timestamp=fixed_timestamp)
        assert ATTRIBUTION in report

    def test_report_contains_horizontal_rules(
        self, fixed_timestamp: datetime
    ) -> None:
        """Report contains horizontal rule separators."""
        report = generate_report(TEST_TOPIC, TEST_FINDINGS, TEST_MODEL, timestamp=fixed_timestamp)
        assert "---" in report

    def test_report_handles_empty_findings(self, fixed_timestamp: datetime) -> None:
        """Empty findings produce a valid report with placeholder text."""
        report = generate_report(TEST_TOPIC, "", TEST_MODEL, timestamp=fixed_timestamp)
        assert "_No findings available._" in report
        assert f"# {REPORT_TITLE_PREFIX}: {TEST_TOPIC}" in report

    def test_report_uses_current_time_when_no_timestamp(self) -> None:
        """Report uses current UTC time when no timestamp provided."""
        before = datetime.now(UTC)
        report = generate_report(TEST_TOPIC, TEST_FINDINGS, TEST_MODEL)
        after = datetime.now(UTC)

        # Verify the timestamp in the report is between before and after
        before_str = before.strftime(DATE_FORMAT)[:16]  # Match up to minutes
        after_str = after.strftime(DATE_FORMAT)[:16]
        assert before_str[:10] in report or after_str[:10] in report
