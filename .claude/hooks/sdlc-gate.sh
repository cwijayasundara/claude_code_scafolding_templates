#!/bin/bash
# PreToolUse hook: enforce SDLC gates before allowing writes to code files
# EXIT 0 = allow, EXIT 2 = block (stderr sent to Claude as feedback)
#
# Gates enforced:
# 1. docs/requirements.md must exist with real content (>= 10 lines, required sections)
# 2. docs/backlog/ must have story files with required sections
# 3. Must be on a feature/* branch, not main
# 4. Test plan must exist for src/ writes (derived from branch name)
#
# Expanded coverage: gates ANY .py/.ts/.tsx/.js/.jsx file, not just src/ and tests/
# Exemptions: docs/, .claude/, .github/, config files, __init__.py (conditional)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.command // empty')

# --- Exempt paths: docs, tooling, config files ---
if [[ "$FILE_PATH" == */docs/* ]] || \
   [[ "$FILE_PATH" == */.claude/* ]] || \
   [[ "$FILE_PATH" == */.github/* ]] || \
   [[ "$FILE_PATH" == */scripts/* ]]; then
  exit 0
fi

# Exempt known config files by basename
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  Makefile|Dockerfile|docker-compose*.yml|pyproject.toml|setup.py|setup.cfg| \
  requirements*.txt|package.json|package-lock.json|tsconfig*.json| \
  .gitignore|.env*|.eslintrc*|.prettierrc*|tailwind.config*|vite.config*| \
  next.config*|postcss.config*|jest.config*|playwright.config*| \
  conftest.py|pytest.ini|.mcp.json|*.toml|*.cfg|*.ini|*.lock)
    exit 0
    ;;
esac

# --- Only gate code files (.py, .ts, .tsx, .js, .jsx) ---
if [[ "$FILE_PATH" != *.py && "$FILE_PATH" != *.ts && "$FILE_PATH" != *.tsx && \
      "$FILE_PATH" != *.js && "$FILE_PATH" != *.jsx ]]; then
  exit 0
fi

# --- Conditional __init__.py handling ---
if [[ "$BASENAME" == "__init__.py" ]]; then
  # Always allow __init__.py in tests/
  if [[ "$FILE_PATH" == */tests/* ]]; then
    exit 0
  fi
  # In src/ or elsewhere, allow only if content is <= 5 lines (package marker)
  WRITE_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')
  LINE_COUNT=$(echo "$WRITE_CONTENT" | wc -l | tr -d ' ')
  if [[ "$LINE_COUNT" -le 5 ]]; then
    exit 0
  fi
  # Larger __init__.py falls through to SDLC gates
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# --- Gate 1: Requirements document must exist with real content ---
REQUIREMENTS_FILE="$PROJECT_ROOT/docs/requirements.md"
if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
  echo "SDLC GATE BLOCKED: docs/requirements.md does not exist." >&2
  echo "You must run /interview first to gather requirements before writing code." >&2
  echo "Tell the user: 'No requirements document found. Run /interview first.'" >&2
  exit 2
fi

# Content validation: requirements must have >= 10 lines
REQ_LINE_COUNT=$(wc -l < "$REQUIREMENTS_FILE" | tr -d ' ')
if [[ "$REQ_LINE_COUNT" -lt 10 ]]; then
  echo "SDLC GATE BLOCKED: docs/requirements.md is a stub ($REQ_LINE_COUNT lines, need >= 10)." >&2
  echo "Run /interview to generate real requirements — do not create stub files." >&2
  exit 2
fi

# Content validation: must have at least 2 of 4 required section headings
SECTION_COUNT=0
grep -q "^## Problem Statement" "$REQUIREMENTS_FILE" && SECTION_COUNT=$((SECTION_COUNT + 1))
grep -q "^## Functional Requirements" "$REQUIREMENTS_FILE" && SECTION_COUNT=$((SECTION_COUNT + 1))
grep -q "^## Target Users" "$REQUIREMENTS_FILE" && SECTION_COUNT=$((SECTION_COUNT + 1))
grep -q "^## Non-Functional Requirements" "$REQUIREMENTS_FILE" && SECTION_COUNT=$((SECTION_COUNT + 1))

if [[ "$SECTION_COUNT" -lt 2 ]]; then
  echo "SDLC GATE BLOCKED: docs/requirements.md lacks required sections (found $SECTION_COUNT/4, need >= 2)." >&2
  echo "Required sections: '## Problem Statement', '## Functional Requirements', '## Target Users', '## Non-Functional Requirements'" >&2
  echo "Run /interview to generate proper requirements." >&2
  exit 2
fi

# --- Gate 2: Backlog must have story files with real content ---
STORY_COUNT=$(find "$PROJECT_ROOT/docs/backlog" -name "*.md" \
  -not -name "implementation-order.md" \
  -not -name "dependency-graph.mmd" \
  -not -name "parallel-batches.md" \
  2>/dev/null | wc -l | tr -d ' ')

if [[ "$STORY_COUNT" -eq 0 ]]; then
  echo "SDLC GATE BLOCKED: No user stories found in docs/backlog/." >&2
  echo "You must run /decompose docs/requirements.md first to create stories." >&2
  echo "Tell the user: 'No stories in backlog. Run /decompose first.'" >&2
  exit 2
fi

# Validate at least one story file has real content (>= 8 lines + required headings)
VALID_STORY_FOUND=false
while IFS= read -r story_file; do
  STORY_LINES=$(wc -l < "$story_file" | tr -d ' ')
  if [[ "$STORY_LINES" -ge 8 ]]; then
    HAS_STORY_SECTION=false
    HAS_DEPS_SECTION=false
    grep -q "^## User Story\|^## Acceptance Criteria" "$story_file" && HAS_STORY_SECTION=true
    grep -q "^## Dependencies" "$story_file" && HAS_DEPS_SECTION=true
    if $HAS_STORY_SECTION && $HAS_DEPS_SECTION; then
      VALID_STORY_FOUND=true
      break
    fi
  fi
done < <(find "$PROJECT_ROOT/docs/backlog" -name "*.md" \
  -not -name "implementation-order.md" \
  -not -name "dependency-graph.mmd" \
  -not -name "parallel-batches.md" 2>/dev/null)

if ! $VALID_STORY_FOUND; then
  echo "SDLC GATE BLOCKED: Story files in docs/backlog/ are stubs (missing content or required sections)." >&2
  echo "Each story must have >= 8 lines and include '## User Story' or '## Acceptance Criteria' + '## Dependencies' headings." >&2
  echo "Run /decompose docs/requirements.md to generate proper stories." >&2
  exit 2
fi

# --- Gate 3: Must be on a feature branch, not main/master ---
BRANCH=$(git branch --show-current 2>/dev/null)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "SDLC GATE BLOCKED: You are on the '$BRANCH' branch." >&2
  echo "Create a feature branch first: git checkout -b feature/STORY-XXX-description" >&2
  echo "NEVER write implementation code directly on $BRANCH." >&2
  exit 2
fi

# --- Gate 4: Test plan must exist for src/ writes (derived from branch name) ---
if [[ "$FILE_PATH" == */src/* ]]; then
  # Extract story ID from branch name (e.g., feature/STORY-001-description → STORY-001)
  STORY_ID=$(echo "$BRANCH" | grep -oE 'STORY-[0-9]+' | head -1)
  if [[ -n "$STORY_ID" ]]; then
    TEST_PLAN_EXISTS=$(find "$PROJECT_ROOT/docs/test-plans" -name "${STORY_ID}-*" -o -name "${STORY_ID}.*" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$TEST_PLAN_EXISTS" -eq 0 ]]; then
      echo "SDLC GATE BLOCKED: No test plan found for $STORY_ID in docs/test-plans/." >&2
      echo "Run /test-plan on the story file first to generate a test plan before writing src/ code." >&2
      echo "Writing tests/ files is allowed (RED phase = test-first)." >&2
      exit 2
    fi
  fi
fi

# All gates passed
exit 0
