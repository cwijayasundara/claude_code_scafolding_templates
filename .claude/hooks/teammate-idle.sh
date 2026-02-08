#!/bin/bash
# TeammateIdle hook: runs when a teammate is about to go idle.
# Checks if the teammate's work passes CI. If not, sends them back to fix.
#
# EXIT 0 = allow idle (teammate finished successfully)
# EXIT 2 = reject idle (stderr feedback sent to teammate to keep working)
#
# This hook uses the project root (which may be a worktree) to run CI.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [[ -z "$PROJECT_ROOT" ]]; then
  exit 0
fi

# Check if there are any commits on this branch beyond main
BRANCH=$(git branch --show-current 2>/dev/null)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  # Lead session going idle — that's fine
  exit 0
fi

# Only validate if Makefile exists
if [[ ! -f "$PROJECT_ROOT/Makefile" ]]; then
  exit 0
fi

# Check for uncommitted changes — teammate should commit before going idle
UNCOMMITTED=$(git status --porcelain 2>/dev/null)
if [[ -n "$UNCOMMITTED" ]]; then
  echo "You have uncommitted changes. Commit your work before finishing." >&2
  echo "Uncommitted files:" >&2
  echo "$UNCOMMITTED" >&2
  exit 2
fi

# Run CI to validate the teammate's work
cd "$PROJECT_ROOT" || exit 0

if make ci 2>&1; then
  echo "CI PASSED — teammate may go idle." >&2
  exit 0
else
  echo "CI FAILED — fix the issues before going idle." >&2
  echo "Run 'make ci' to see the failures, then fix and commit." >&2
  exit 2
fi
