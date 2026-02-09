#!/bin/bash
# Test SDLC Lite Mode vs Full Mode
# Validates that sdlc-gate.sh respects SDLC_MODE thresholds
#
# Usage: ./scripts/test-lite-mode.sh

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
GATE="$PROJECT_ROOT/.claude/hooks/sdlc-gate.sh"
TMPDIR=$(mktemp -d)

# --- Setup: create minimal lite-valid artifacts in temp dir ---
setup_test_env() {
  local mode="$1"
  rm -rf "$TMPDIR"
  mkdir -p "$TMPDIR/docs/backlog/core" "$TMPDIR/.claude" "$TMPDIR/src"

  # 5-line requirements (passes lite >= 5, fails full >= 10)
  cat > "$TMPDIR/docs/requirements.md" <<'REQS'
# Requirements
## Problem Statement
We need a widget that does things.
## Functional Requirements
1. It must work.
REQS

  # 4-line story with Acceptance Criteria only (no Dependencies section)
  cat > "$TMPDIR/docs/backlog/core/STORY-001.md" <<'STORY'
# STORY-001: Widget
## User Story
As a user, I want a widget.
## Acceptance Criteria
- Given input, When submitted, Then saved
STORY

  # settings.json with requested mode
  echo "{\"env\":{\"SDLC_MODE\":\"$mode\"}}" > "$TMPDIR/.claude/settings.json"

  # Init git repo on a feature branch
  cd "$TMPDIR"
  git init -q
  git checkout -q -b feature/STORY-001-widget 2>/dev/null
  cd "$PROJECT_ROOT"
}

# Helper: run the gate hook against a file path
run_gate() {
  local file_path="$1"
  echo "{\"tool_input\":{\"file_path\":\"$file_path\"}}" | \
    bash "$GATE" 2>&1
}

echo "=== SDLC Lite Mode Tests ==="
echo ""

# --- Test 1: Full mode should BLOCK 5-line requirements ---
echo "Test 1: Full mode blocks 5-line requirements"
setup_test_env "full"
cd "$TMPDIR"
RESULT=$(run_gate "$TMPDIR/src/app.py")
EXIT_CODE=$?
cd "$PROJECT_ROOT"
if [[ $EXIT_CODE -eq 2 ]]; then
  pass "Full mode blocked 5-line requirements (exit $EXIT_CODE)"
else
  fail "Full mode should block 5-line requirements but got exit $EXIT_CODE"
fi

# --- Test 2: Lite mode should ALLOW 5-line requirements ---
echo "Test 2: Lite mode allows 5-line requirements"
setup_test_env "lite"
cd "$TMPDIR"
RESULT=$(run_gate "$TMPDIR/src/app.py")
EXIT_CODE=$?
cd "$PROJECT_ROOT"
if [[ $EXIT_CODE -eq 0 ]]; then
  pass "Lite mode allowed 5-line requirements (exit $EXIT_CODE)"
else
  fail "Lite mode should allow 5-line requirements but got exit $EXIT_CODE: $RESULT"
fi

# --- Test 3: Lite mode allows story without Dependencies section ---
echo "Test 3: Lite mode allows story without Dependencies section"
setup_test_env "lite"
cd "$TMPDIR"
RESULT=$(run_gate "$TMPDIR/src/widget.py")
EXIT_CODE=$?
cd "$PROJECT_ROOT"
if [[ $EXIT_CODE -eq 0 ]]; then
  pass "Lite mode allowed story without Dependencies section (exit $EXIT_CODE)"
else
  fail "Lite mode should allow story without Dependencies but got exit $EXIT_CODE: $RESULT"
fi

# --- Test 4: Full mode blocks story without Dependencies section ---
echo "Test 4: Full mode blocks story without Dependencies section"
setup_test_env "full"
cd "$TMPDIR"
RESULT=$(run_gate "$TMPDIR/src/widget.py")
EXIT_CODE=$?
cd "$PROJECT_ROOT"
if [[ $EXIT_CODE -eq 2 ]]; then
  pass "Full mode blocked story without Dependencies (exit $EXIT_CODE)"
else
  fail "Full mode should block story without Dependencies but got exit $EXIT_CODE"
fi

# --- Test 5: Lite mode skips test plan gate for src/ writes ---
echo "Test 5: Lite mode skips test plan check for src/ writes"
setup_test_env "lite"
# No docs/test-plans/ directory — should still pass in lite
cd "$TMPDIR"
RESULT=$(run_gate "$TMPDIR/src/widget.py")
EXIT_CODE=$?
cd "$PROJECT_ROOT"
if [[ $EXIT_CODE -eq 0 ]]; then
  pass "Lite mode skipped test plan check for src/ writes (exit $EXIT_CODE)"
else
  fail "Lite mode should skip test plan check but got exit $EXIT_CODE: $RESULT"
fi

# --- Test 6: Full mode blocks src/ writes without test plan ---
echo "Test 6: Full mode blocks src/ writes without test plan"
setup_test_env "full"
# Make story valid for full mode (add Dependencies + enough lines)
cat > "$TMPDIR/docs/backlog/core/STORY-001.md" <<'FULLSTORY'
# STORY-001: Widget
## User Story
As a user, I want a widget so that I can do things.
## Acceptance Criteria
- Given input, When submitted, Then saved
- Given saved, When loaded, Then displayed
## Dependencies
- depends_on: []
- blocks: []
FULLSTORY
# Make requirements valid for full mode (>= 10 lines)
cat > "$TMPDIR/docs/requirements.md" <<'FULLREQS'
# Requirements
## Problem Statement
We need a widget that does things well.
This is a critical business need.
## Functional Requirements
1. It must work correctly.
2. It must be fast.
## Target Users
- Developers building widgets
## Non-Functional Requirements
- Response time under 200ms
FULLREQS
cd "$TMPDIR"
RESULT=$(run_gate "$TMPDIR/src/widget.py")
EXIT_CODE=$?
cd "$PROJECT_ROOT"
if [[ $EXIT_CODE -eq 2 ]] && echo "$RESULT" | grep -q "test plan"; then
  pass "Full mode blocked src/ write without test plan (exit $EXIT_CODE)"
else
  fail "Full mode should block src/ without test plan but got exit $EXIT_CODE: $RESULT"
fi

# --- Test 7: Default (no SDLC_MODE) behaves as full ---
echo "Test 7: Default mode (no SDLC_MODE) behaves as full"
setup_test_env "full"
# Remove SDLC_MODE from settings
echo '{"env":{}}' > "$TMPDIR/.claude/settings.json"
cd "$TMPDIR"
RESULT=$(run_gate "$TMPDIR/src/app.py")
EXIT_CODE=$?
cd "$PROJECT_ROOT"
if [[ $EXIT_CODE -eq 2 ]]; then
  pass "Default mode (no SDLC_MODE) behaves as full — blocked 5-line requirements (exit $EXIT_CODE)"
else
  fail "Default mode should behave as full but got exit $EXIT_CODE"
fi

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "=== Summary ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
if [[ $FAIL -eq 0 ]]; then
  echo "  All lite mode tests passed!"
else
  echo "  $FAIL test(s) failed."
  exit 1
fi
