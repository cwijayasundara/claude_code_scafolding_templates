#!/bin/bash
# PostToolUse hook: lint and typecheck Python files after Write/Edit
# Claude Code hooks receive JSON on stdin (not env vars)
# Requires: jq, ruff, mypy

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

if [[ "$FILE_PATH" == *.py ]]; then
  ruff check --fix "$FILE_PATH" && mypy "$FILE_PATH" --ignore-missing-imports
fi
