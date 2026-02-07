"""Configurable LLM initialization using langchain's init_chat_model."""

import logging

from langchain.chat_models import init_chat_model
from langchain_core.language_models import BaseChatModel

logger = logging.getLogger(__name__)

MODEL_SEPARATOR = ":"
MIN_MODEL_STRING_PARTS = 2


def create_llm(model_string: str) -> BaseChatModel:
    """Initialize a chat model from a provider:model_name string.

    Args:
        model_string: Model identifier in "provider:model_name" format
            (e.g., "openai:gpt-5-mini").

    Returns:
        An initialized BaseChatModel instance.

    Raises:
        ValueError: If model_string format is invalid.
        RuntimeError: If model initialization fails.
    """
    _validate_model_string(model_string)
    logger.info("Initializing LLM: %s", model_string)
    try:
        model = init_chat_model(model_string)
    except Exception as exc:
        logger.error("Failed to initialize LLM '%s': %s", model_string, exc)
        msg = f"Failed to initialize LLM '{model_string}': {exc}"
        raise RuntimeError(msg) from exc
    logger.info("LLM initialized successfully: %s", model_string)
    return model


def _validate_model_string(model_string: str) -> None:
    """Validate the provider:model_name format.

    Raises:
        ValueError: If the format is invalid.
    """
    if MODEL_SEPARATOR not in model_string:
        msg = (
            f"Invalid model string '{model_string}'. "
            f"Expected format: 'provider{MODEL_SEPARATOR}model_name' "
            f"(e.g., 'openai{MODEL_SEPARATOR}gpt-5-mini')"
        )
        raise ValueError(msg)

    parts = model_string.split(MODEL_SEPARATOR, maxsplit=1)
    provider, model_name = parts[0].strip(), parts[1].strip()

    if not provider:
        msg = f"Provider cannot be empty in model string '{model_string}'"
        raise ValueError(msg)

    if not model_name:
        msg = f"Model name cannot be empty in model string '{model_string}'"
        raise ValueError(msg)
