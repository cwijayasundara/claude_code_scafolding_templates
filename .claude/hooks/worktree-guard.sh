#!/bin/bash
# PreToolUse hook: prevent teammates from writing outside their assigned worktree.
# Only active when running inside a git worktree (skips in main working tree).
#
# EXIT 0 = allow, EXIT 2 = block (stderr sent to Claude as feedback)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path in the tool input
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Detect if we're in a worktree (not the main working tree)
GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)

# If git-common-dir equals git-dir, we're in the main working tree — skip guard
if [[ "$GIT_COMMON_DIR" == "$GIT_DIR" ]]; then
  exit 0
fi

# We're in a worktree — enforce boundary
WORKTREE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [[ -z "$WORKTREE_ROOT" ]]; then
  exit 0
fi

# Resolve the file path to absolute
RESOLVED_PATH=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd)/$(basename "$FILE_PATH")

# Check if the resolved path is within the worktree root
if [[ "$RESOLVED_PATH" != "$WORKTREE_ROOT"/* ]]; then
  echo "WORKTREE GUARD BLOCKED: Attempted to write outside worktree boundary." >&2
  echo "  File: $FILE_PATH" >&2
  echo "  Worktree: $WORKTREE_ROOT" >&2
  echo "You must only write files inside your assigned worktree." >&2
  exit 2
fi

exit 0
