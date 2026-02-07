"""Unit tests for src/llm.py — Configurable LLM Initialization."""

from unittest.mock import MagicMock, patch

import pytest
from src.llm import create_llm

pytestmark = pytest.mark.unit


class TestCreateLlm:
    """Test the create_llm function."""

    @patch("src.llm.init_chat_model")
    def test_create_llm_calls_init_chat_model_with_model_string(
        self, mock_init: MagicMock
    ) -> None:
        """init_chat_model is called with the full model string."""
        mock_init.return_value = MagicMock()
        create_llm("openai:gpt-5-mini")
        mock_init.assert_called_once_with("openai:gpt-5-mini")

    @patch("src.llm.init_chat_model")
    def test_create_llm_returns_model_instance(self, mock_init: MagicMock) -> None:
        """create_llm returns the model instance from init_chat_model."""
        expected_model = MagicMock()
        mock_init.return_value = expected_model
        result = create_llm("openai:gpt-5-mini")
        assert result is expected_model

    def test_create_llm_raises_value_error_for_missing_colon(self) -> None:
        """Model string without colon separator raises ValueError."""
        with pytest.raises(ValueError, match="Invalid model string"):
            create_llm("openai-gpt-5-mini")

    def test_create_llm_raises_value_error_for_empty_provider(self) -> None:
        """Model string with empty provider raises ValueError."""
        with pytest.raises(ValueError, match="Provider cannot be empty"):
            create_llm(":gpt-5-mini")

    def test_create_llm_raises_value_error_for_empty_model_name(self) -> None:
        """Model string with empty model name raises ValueError."""
        with pytest.raises(ValueError, match="Model name cannot be empty"):
            create_llm("openai:")

    @patch("src.llm.init_chat_model", side_effect=Exception("Connection failed"))
    def test_create_llm_raises_runtime_error_on_init_failure(
        self, mock_init: MagicMock
    ) -> None:
        """init_chat_model failure is wrapped in RuntimeError."""
        with pytest.raises(RuntimeError, match="Failed to initialize LLM"):
            create_llm("openai:gpt-5-mini")
