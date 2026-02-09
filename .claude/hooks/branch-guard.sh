#!/bin/bash
# PreToolUse hook: prevent force-push and direct commits to main/master
# Matches Bash tool calls — blocks dangerous git operations on protected branches
#
# EXIT 0 = allow, EXIT 2 = block

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Skip if not a git command
if [[ "$COMMAND" != git* ]]; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null)

# Block force push to any branch
if echo "$COMMAND" | grep -qE 'push\s+.*--force|push\s+-f'; then
  echo "BLOCKED: Force push is not allowed. Use regular push or ask the user." >&2
  exit 2
fi

# Block direct commits on main/master
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  if echo "$COMMAND" | grep -qE '^git\s+commit'; then
    echo "BLOCKED: Direct commits to '$BRANCH' are not allowed." >&2
    echo "Create a feature branch first: git checkout -b feature/STORY-XXX-description" >&2
    exit 2
  fi
fi

# Block merging spike branches into any branch
if echo "$COMMAND" | grep -qE 'merge\s+spike/'; then
  echo "BLOCKED: Spike branches cannot be merged. Spike code is throwaway." >&2
  echo "Run '/spike wrap' to capture findings, then '/interview' to create stories." >&2
  exit 2
fi

# Block PR creation from spike branches
if [[ "$BRANCH" == spike/* ]]; then
  if echo "$COMMAND" | grep -qE 'gh\s+pr\s+create|gh\s+pr\s+ready'; then
    echo "BLOCKED: Cannot create PRs from spike branches." >&2
    echo "Run '/spike wrap' to capture findings, then '/interview' to create stories." >&2
    exit 2
  fi
fi

exit 0
