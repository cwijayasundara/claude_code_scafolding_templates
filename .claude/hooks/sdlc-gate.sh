#!/bin/bash
# PreToolUse hook: enforce SDLC gates before allowing writes to src/ or tests/
# EXIT 0 = allow, EXIT 2 = block (stderr sent to Claude as feedback)
#
# Gates enforced:
# 1. docs/requirements.md must exist (Phase 1 output)
# 2. docs/backlog/ must have story files (Phase 2 output)
# 3. Must be on a feature/* branch, not main
#
# Skips enforcement for non-code files (config, docs, etc.)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.command // empty')

# Only gate writes to src/ and tests/ directories
if [[ "$FILE_PATH" != */src/* && "$FILE_PATH" != */tests/* ]]; then
  exit 0
fi

# Allow __init__.py files (package markers, not implementation)
BASENAME=$(basename "$FILE_PATH")
if [[ "$BASENAME" == "__init__.py" ]]; then
  exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Gate 1: Requirements document must exist
if [[ ! -f "$PROJECT_ROOT/docs/requirements.md" ]]; then
  echo "SDLC GATE BLOCKED: docs/requirements.md does not exist." >&2
  echo "You must run /interview first to gather requirements before writing code." >&2
  echo "Tell the user: 'No requirements document found. Run /interview first.'" >&2
  exit 2
fi

# Gate 2: Backlog must have story files
STORY_COUNT=$(find "$PROJECT_ROOT/docs/backlog" -name "*.md" -not -name "implementation-order.md" -not -name "dependency-graph.mmd" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$STORY_COUNT" -eq 0 ]]; then
  echo "SDLC GATE BLOCKED: No user stories found in docs/backlog/." >&2
  echo "You must run /decompose docs/requirements.md first to create stories." >&2
  echo "Tell the user: 'No stories in backlog. Run /decompose first.'" >&2
  exit 2
fi

# Gate 3: Must be on a feature branch, not main/master
BRANCH=$(git branch --show-current 2>/dev/null)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "SDLC GATE BLOCKED: You are on the '$BRANCH' branch." >&2
  echo "Create a feature branch first: git checkout -b feature/STORY-XXX-description" >&2
  echo "NEVER write implementation code directly on $BRANCH." >&2
  exit 2
fi

# All gates passed
exit 0
