#!/bin/bash
# PreToolUse hook: block Bash redirects that bypass Write/Edit SDLC gates
# EXIT 0 = allow, EXIT 2 = block (stderr sent to Claude as feedback)
#
# Prevents: echo/printf/cat/heredoc redirects creating or overwriting:
# 1. SDLC artifacts (docs/requirements.md, docs/backlog/, docs/test-plans/)
# 2. Code files (.py/.ts/.tsx/.js/.jsx) outside exempt paths
#
# Quick-skip: exit 0 if command doesn't contain redirect operators or file-moving commands

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Quick-skip: no redirect/copy/move operators → allow
if [[ "$COMMAND" != *">"* && "$COMMAND" != *"tee "* && "$COMMAND" != *"cp "* && "$COMMAND" != *"mv "* ]]; then
  exit 0
fi

# --- Block redirects targeting SDLC artifact paths ---
# Patterns: echo/printf/cat ... > docs/requirements.md, docs/backlog/*, docs/test-plans/*
if echo "$COMMAND" | grep -qE '(>|tee\s+|cp\s+.*\s+|mv\s+.*\s+).*(docs/requirements\.md|docs/backlog/|docs/test-plans/)'; then
  echo "BLOCKED: Cannot create or overwrite SDLC artifacts via Bash redirects." >&2
  echo "Use the proper SDLC commands instead:" >&2
  echo "  - docs/requirements.md → Run /interview" >&2
  echo "  - docs/backlog/ → Run /decompose" >&2
  echo "  - docs/test-plans/ → Run /test-plan" >&2
  echo "These commands generate validated content — stubs are not allowed." >&2
  exit 2
fi

# --- Block redirects creating code files outside exempt paths ---
# Match: > path/to/file.py, > path/to/file.ts, etc.
if echo "$COMMAND" | grep -qE '(>|tee\s+|cp\s+.*\s+|mv\s+.*\s+).*\.(py|ts|tsx|js|jsx)\b'; then
  # Allow if target is in exempt paths
  TARGET_PATH=$(echo "$COMMAND" | grep -oE '(>|tee\s+|cp\s+.*\s+|mv\s+.*\s+)\s*\S+\.(py|ts|tsx|js|jsx)' | grep -oE '\S+\.(py|ts|tsx|js|jsx)$')
  if [[ -n "$TARGET_PATH" ]]; then
    # Exempt: docs/, .claude/, .github/, scripts/
    if [[ "$TARGET_PATH" == docs/* ]] || \
       [[ "$TARGET_PATH" == .claude/* ]] || \
       [[ "$TARGET_PATH" == .github/* ]] || \
       [[ "$TARGET_PATH" == scripts/* ]] || \
       [[ "$TARGET_PATH" == */docs/* ]] || \
       [[ "$TARGET_PATH" == */.claude/* ]] || \
       [[ "$TARGET_PATH" == */.github/* ]] || \
       [[ "$TARGET_PATH" == */scripts/* ]]; then
      exit 0
    fi
    echo "BLOCKED: Cannot create code files via Bash redirects — use Write/Edit tools instead." >&2
    echo "The Write/Edit tools enforce SDLC gates (requirements, backlog, feature branch)." >&2
    echo "Bash redirects bypass these gates and are not allowed for code files." >&2
    exit 2
  fi
fi

# --- Block heredoc patterns targeting SDLC artifacts ---
if echo "$COMMAND" | grep -qE "cat\s*<<.*>(.*docs/requirements\.md|.*docs/backlog/|.*docs/test-plans/)"; then
  echo "BLOCKED: Cannot create SDLC artifacts via heredoc redirects." >&2
  echo "Use /interview, /decompose, or /test-plan commands instead." >&2
  exit 2
fi

exit 0
