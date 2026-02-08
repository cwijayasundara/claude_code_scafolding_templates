#!/bin/bash
# PostToolUse hook: lint and typecheck TypeScript/React files after Write/Edit
# Claude Code hooks receive JSON on stdin (not env vars)
# Graceful fallback: exits 0 if ESLint/tsc not installed (template doesn't force frontend)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# Only process .ts and .tsx files
if [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.tsx ]]; then
  exit 0
fi

# Find the nearest package.json to determine frontend root
SEARCH_DIR=$(dirname "$FILE_PATH")
FRONTEND_ROOT=""
while [[ "$SEARCH_DIR" != "/" && "$SEARCH_DIR" != "." ]]; do
  if [[ -f "$SEARCH_DIR/package.json" ]]; then
    FRONTEND_ROOT="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

# No package.json found — not a frontend project, skip silently
if [[ -z "$FRONTEND_ROOT" ]]; then
  exit 0
fi

# Run ESLint if available
if [[ -f "$FRONTEND_ROOT/node_modules/.bin/eslint" ]]; then
  npx --prefix "$FRONTEND_ROOT" eslint "$FILE_PATH" --fix --quiet 2>/dev/null
elif command -v npx &>/dev/null && [[ -f "$FRONTEND_ROOT/package.json" ]]; then
  # Try npx but don't fail if eslint isn't configured
  npx --prefix "$FRONTEND_ROOT" eslint "$FILE_PATH" --fix --quiet 2>/dev/null || true
fi

# Run TypeScript type checking if tsconfig exists
if [[ -f "$FRONTEND_ROOT/tsconfig.json" ]]; then
  if [[ -f "$FRONTEND_ROOT/node_modules/.bin/tsc" ]]; then
    npx --prefix "$FRONTEND_ROOT" tsc --noEmit 2>/dev/null || true
  fi
fi

# Always exit 0 — linting is advisory, don't block writes
exit 0
