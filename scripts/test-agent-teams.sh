#!/bin/bash
# =============================================================================
# Test suite for Agent Teams implementation
#
# Tests the hooks, worktree logic, settings wiring, and pre-flight checks
# that make up the parallel implementation infrastructure.
#
# Usage: ./scripts/test-agent-teams.sh
#
# What this tests (without spawning real agent teams):
#   1. Hook scripts: exit codes, input parsing, boundary detection
#   2. Worktree guard: blocks writes outside worktree, allows inside
#   3. Teammate hooks: correct behavior in main tree vs worktree
#   4. Settings.json: all env vars and hook wiring present
#   5. CLAUDE.md: enforcement rules, dependency documentation
#   6. Worktree lifecycle: create, verify, cleanup
# =============================================================================

set -euo pipefail

PASS=0
FAIL=0
CLEANUP_DIRS=()

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

cleanup() {
  for dir in "${CLEANUP_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      git worktree remove "$dir" --force 2>/dev/null || rm -rf "$dir"
    fi
  done
  # Prune stale worktree references
  git worktree prune 2>/dev/null || true
  # Remove test branches
  git branch -D test-worktree-guard-branch 2>/dev/null || true
}
trap cleanup EXIT

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
cd "$PROJECT_ROOT"

echo "=== Agent Teams Test Suite ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# ============================================================================
# 1. HOOK SCRIPT UNIT TESTS — worktree-guard.sh
# ============================================================================
echo "1. worktree-guard.sh — input parsing and main-tree bypass"

# Test 1a: Empty input → should allow (exit 0)
EXIT_CODE=0
echo '{}' | .claude/hooks/worktree-guard.sh 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
  pass "Empty input → exit 0 (allow)"
else
  fail "Empty input → exit $EXIT_CODE (expected 0)"
fi

# Test 1b: No file_path in input → should allow (exit 0)
EXIT_CODE=0
echo '{"tool_input": {"command": "git status"}}' | .claude/hooks/worktree-guard.sh 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
  pass "No file_path in input → exit 0 (allow)"
else
  fail "No file_path in input → exit $EXIT_CODE (expected 0)"
fi

# Test 1c: In main working tree with file_path → should allow (guard only active in worktrees)
EXIT_CODE=0
echo "{\"tool_input\": {\"file_path\": \"$PROJECT_ROOT/src/main.py\"}}" | .claude/hooks/worktree-guard.sh 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
  pass "Main working tree → exit 0 (guard skipped)"
else
  fail "Main working tree → exit $EXIT_CODE (expected 0 — guard should skip in main tree)"
fi
echo ""

# ============================================================================
# 2. WORKTREE GUARD — boundary enforcement inside a real worktree
# ============================================================================
echo "2. worktree-guard.sh — boundary enforcement in a real worktree"

WORKTREE_DIR="$PROJECT_ROOT/.worktrees/test-guard"
CLEANUP_DIRS+=("$WORKTREE_DIR")

# Create a test worktree
git worktree add "$WORKTREE_DIR" -b test-worktree-guard-branch HEAD 2>/dev/null

if [[ -d "$WORKTREE_DIR" ]]; then
  pass "Test worktree created at $WORKTREE_DIR"

  # Test 2a: Write INSIDE worktree → should allow (exit 0)
  EXIT_CODE=0
  echo "{\"tool_input\": {\"file_path\": \"$WORKTREE_DIR/src/test.py\"}}" \
    | (cd "$WORKTREE_DIR" && "$PROJECT_ROOT/.claude/hooks/worktree-guard.sh") 2>/dev/null || EXIT_CODE=$?
  if [[ "$EXIT_CODE" -eq 0 ]]; then
    pass "Write inside worktree → exit 0 (allowed)"
  else
    fail "Write inside worktree → exit $EXIT_CODE (expected 0)"
  fi

  # Test 2b: Write OUTSIDE worktree (to main tree) → should block (exit 2)
  EXIT_CODE=0
  echo "{\"tool_input\": {\"file_path\": \"$PROJECT_ROOT/src/main.py\"}}" \
    | (cd "$WORKTREE_DIR" && "$PROJECT_ROOT/.claude/hooks/worktree-guard.sh") 2>/dev/null || EXIT_CODE=$?
  if [[ "$EXIT_CODE" -eq 2 ]]; then
    pass "Write outside worktree → exit 2 (blocked)"
  else
    fail "Write outside worktree → exit $EXIT_CODE (expected 2 — should block)"
  fi

  # Test 2c: Write to /tmp (completely outside) → should block (exit 2)
  EXIT_CODE=0
  echo '{"tool_input": {"file_path": "/tmp/evil.py"}}' \
    | (cd "$WORKTREE_DIR" && "$PROJECT_ROOT/.claude/hooks/worktree-guard.sh") 2>/dev/null || EXIT_CODE=$?
  if [[ "$EXIT_CODE" -eq 2 ]]; then
    pass "Write to /tmp → exit 2 (blocked)"
  else
    fail "Write to /tmp → exit $EXIT_CODE (expected 2 — should block)"
  fi
else
  fail "Could not create test worktree — skipping boundary tests"
fi
echo ""

# ============================================================================
# 3. TEAMMATE-IDLE.SH — main branch bypass
# ============================================================================
echo "3. teammate-idle.sh — main branch bypass"

# Test 3a: On main branch → should allow idle (exit 0, lead session)
EXIT_CODE=0
.claude/hooks/teammate-idle.sh 2>/dev/null </dev/null || EXIT_CODE=$?
BRANCH=$(git branch --show-current 2>/dev/null)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  if [[ "$EXIT_CODE" -eq 0 ]]; then
    pass "On $BRANCH branch → exit 0 (lead session allowed to idle)"
  else
    fail "On $BRANCH branch → exit $EXIT_CODE (expected 0)"
  fi
else
  pass "Not on main (on '$BRANCH') — skipping main-branch test (run from main to verify)"
fi
echo ""

# ============================================================================
# 4. TEAMMATE-COMPLETED.SH — main branch bypass
# ============================================================================
echo "4. teammate-completed.sh — main branch skip"

# Test 4a: On main branch in main tree → should skip validation (exit 0)
EXIT_CODE=0
.claude/hooks/teammate-completed.sh 2>/dev/null </dev/null || EXIT_CODE=$?
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  if [[ "$EXIT_CODE" -eq 0 ]]; then
    pass "Main tree + main branch → exit 0 (coordination task, skip CI)"
  else
    fail "Main tree + main branch → exit $EXIT_CODE (expected 0)"
  fi
else
  pass "Not on main — skipping main-branch test"
fi
echo ""

# ============================================================================
# 5. SETTINGS.JSON — env vars and hook wiring completeness
# ============================================================================
echo "5. settings.json — agent teams configuration"

SETTINGS=".claude/settings.json"

# Check all required env vars
for var in AGENT_TEAMS_ENABLED AGENT_TEAMS_ENFORCE AGENT_TEAMS_MAX_TEAMMATES AGENT_TEAMS_WORKTREE_DIR AGENT_TEAMS_AUTO_CLEANUP; do
  VAL=$(jq -r ".env.$var // \"MISSING\"" "$SETTINGS" 2>/dev/null)
  if [[ "$VAL" != "MISSING" ]]; then
    pass "env.$var = \"$VAL\""
  else
    fail "env.$var missing from settings.json"
  fi
done

# Check hook events exist
for event in PreToolUse PostToolUse TeammateIdle TaskCompleted; do
  if jq -e ".hooks.$event" "$SETTINGS" >/dev/null 2>&1; then
    pass "hooks.$event configured"
  else
    fail "hooks.$event missing"
  fi
done

# Check specific hook scripts are wired
for script in worktree-guard.sh teammate-idle.sh teammate-completed.sh; do
  if grep -q "$script" "$SETTINGS"; then
    pass "$script wired in settings.json"
  else
    fail "$script NOT wired in settings.json"
  fi
done
echo ""

# ============================================================================
# 6. CLAUDE.MD — enforcement rules present
# ============================================================================
echo "6. CLAUDE.md — agent teams enforcement rules"

if grep -q "AGENT_TEAMS_ENFORCE" CLAUDE.md; then
  pass "AGENT_TEAMS_ENFORCE referenced in CLAUDE.md"
else
  fail "AGENT_TEAMS_ENFORCE not mentioned in CLAUDE.md — enforcement won't work"
fi

if grep -q "delegate mode" CLAUDE.md; then
  pass "Delegate mode documented in CLAUDE.md"
else
  fail "Delegate mode not mentioned in CLAUDE.md"
fi

if grep -q "depends_on" CLAUDE.md; then
  pass "Dependency tracking (depends_on) documented in CLAUDE.md"
else
  fail "depends_on not mentioned in CLAUDE.md — dependency enforcement unclear"
fi

if grep -q "NEVER run in parallel with their dependencies" CLAUDE.md; then
  pass "Dependency parallelization safety rule found"
else
  fail "Dependency parallelization safety rule missing from CLAUDE.md"
fi

if grep -q "TeammateIdle" CLAUDE.md; then
  pass "TeammateIdle hook documented in CLAUDE.md"
else
  fail "TeammateIdle hook not documented in CLAUDE.md"
fi
echo ""

# ============================================================================
# 7. PARALLEL-IMPLEMENT.MD — native agent teams patterns
# ============================================================================
echo "7. parallel-implement.md — uses native agent teams (not subagents)"

CMD=".claude/commands/parallel-implement.md"

# Should NOT reference Task tool (that's subagents)
if grep -qi "using the Task tool" "$CMD"; then
  fail "References 'Task tool' — this is the subagent pattern, not native agent teams"
else
  pass "Does not reference Task tool (correct — uses native teams)"
fi

# Should reference delegate mode
if grep -q "delegate mode" "$CMD"; then
  pass "References delegate mode"
else
  fail "Does not reference delegate mode"
fi

# Should reference plan approval
if grep -q "plan approval" "$CMD" || grep -q "Require plan approval" "$CMD"; then
  pass "References plan approval for teammates"
else
  fail "Does not reference plan approval"
fi

# Should reference shared task list
if grep -q "shared task list" "$CMD" || grep -q "Shared Task List" "$CMD"; then
  pass "References shared task list"
else
  fail "Does not reference shared task list"
fi

# Should reference natural language team creation
if grep -q "Create an agent team" "$CMD"; then
  pass "Uses natural language team creation"
else
  fail "Does not use natural language team creation pattern"
fi

# Should reference TeammateIdle hook
if grep -q "TeammateIdle" "$CMD"; then
  pass "References TeammateIdle hook"
else
  fail "Does not reference TeammateIdle hook"
fi

# Should reference teammate messaging
if grep -q "message the lead" "$CMD" || grep -q "Message teammates" "$CMD"; then
  pass "References inter-agent messaging"
else
  fail "Does not reference inter-agent messaging"
fi

# Should reference team cleanup
if grep -q "Clean up the team" "$CMD"; then
  pass "References team cleanup"
else
  fail "Does not reference team cleanup"
fi
echo ""

# ============================================================================
# 8. DECOMPOSE.MD — story dependency format
# ============================================================================
echo "8. decompose.md — story dependency format"

DECOMPOSE=".claude/commands/decompose.md"

if grep -q "depends_on:" "$DECOMPOSE"; then
  pass "Story format includes depends_on"
else
  fail "Story format missing depends_on — dependency tracking broken"
fi

if grep -q "blocks:" "$DECOMPOSE"; then
  pass "Story format includes blocks"
else
  fail "Story format missing blocks"
fi

if grep -q "CRITICAL RULE" "$DECOMPOSE"; then
  pass "Critical rule about dependency parallelization present"
else
  fail "Critical rule missing — dependent stories could end up in same wave"
fi

if grep -q "parallel-batches.md" "$DECOMPOSE"; then
  pass "Generates parallel-batches.md"
else
  fail "Does not generate parallel-batches.md"
fi
echo ""

# ============================================================================
# 9. WORKTREE LIFECYCLE — create and cleanup
# ============================================================================
echo "9. Worktree lifecycle — create, list, remove"

LIFECYCLE_DIR="$PROJECT_ROOT/.worktrees/test-lifecycle"
CLEANUP_DIRS+=("$LIFECYCLE_DIR")

# Create
git worktree add "$LIFECYCLE_DIR" -b test-lifecycle-branch HEAD 2>/dev/null
if [[ -d "$LIFECYCLE_DIR/.git" || -f "$LIFECYCLE_DIR/.git" ]]; then
  pass "Worktree created successfully"
else
  fail "Worktree creation failed"
fi

# Verify it shows in worktree list
if git worktree list | grep -q "test-lifecycle"; then
  pass "Worktree appears in 'git worktree list'"
else
  fail "Worktree not in 'git worktree list'"
fi

# Verify CLAUDE.md is accessible in worktree (teammates need project context)
if [[ -f "$LIFECYCLE_DIR/CLAUDE.md" ]]; then
  pass "CLAUDE.md accessible in worktree (teammates get project context)"
else
  fail "CLAUDE.md not found in worktree — teammates won't have project context"
fi

# Verify .claude/ is accessible in worktree
if [[ -d "$LIFECYCLE_DIR/.claude" ]]; then
  pass ".claude/ directory accessible in worktree (hooks/rules/commands available)"
else
  fail ".claude/ not found in worktree — hooks won't fire for teammates"
fi

# Remove
git worktree remove "$LIFECYCLE_DIR" --force 2>/dev/null
git branch -D test-lifecycle-branch 2>/dev/null || true
if [[ ! -d "$LIFECYCLE_DIR" ]]; then
  pass "Worktree removed cleanly"
else
  fail "Worktree removal failed — directory still exists"
fi
echo ""

# ============================================================================
# 10. GITIGNORE — .worktrees/ excluded
# ============================================================================
echo "10. Gitignore — worktrees excluded from tracking"

if grep -q "^\.worktrees/" .gitignore 2>/dev/null || grep -q "^\.worktrees" .gitignore 2>/dev/null; then
  pass ".worktrees/ in .gitignore"
else
  fail ".worktrees/ not in .gitignore — worktrees would be tracked by git"
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "=== Agent Teams Test Summary ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "All agent teams tests passed."
  echo ""
  echo "To do a live end-to-end test:"
  echo "  1. Enable: set AGENT_TEAMS_ENABLED=true in .claude/settings.json env block"
  echo "  2. Set env: export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
  echo "  3. Create test stories: /interview → /decompose docs/requirements.md"
  echo "  4. Run: /parallel-implement wave-1"
  echo "  5. Verify: teammates spawn, delegate mode active, plans approved, CI passes"
else
  echo "Agent teams tests have $FAIL failure(s). Fix the issues above."
  exit 1
fi
