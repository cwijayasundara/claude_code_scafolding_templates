#!/bin/bash
# TaskCompleted hook: validate CI when a task is marked as complete.
# Runs `make ci` in the project root to verify the implementation.
#
# EXIT 0 = accept completion
# EXIT 2 = reject completion (send feedback to fix issues)
#
# Works in both worktree (parallel) and main tree (sequential) contexts.
# In the main working tree on main/master branch, skips validation
# (lead session completing coordination tasks, not implementation).

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [[ -z "$PROJECT_ROOT" ]]; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null)

# Skip validation for the lead session on main/master (coordination tasks)
GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
if [[ "$GIT_COMMON_DIR" == "$GIT_DIR" && ("$BRANCH" == "main" || "$BRANCH" == "master") ]]; then
  exit 0
fi

# Check if Makefile exists
if [[ ! -f "$PROJECT_ROOT/Makefile" ]]; then
  echo "WARNING: No Makefile found in $PROJECT_ROOT — skipping CI validation." >&2
  exit 0
fi

# Run CI validation
echo "Running CI validation for task completion in: $PROJECT_ROOT" >&2
cd "$PROJECT_ROOT" || exit 0

if make ci 2>&1; then
  echo "CI PASSED — task completion accepted." >&2
  exit 0
else
  echo "CI FAILED — task completion rejected." >&2
  echo "Fix the failing tests/lint issues and try again." >&2
  exit 2
fi
