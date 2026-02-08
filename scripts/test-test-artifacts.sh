#!/bin/bash
# =============================================================================
# Test suite for Test Artifact Generation Pipeline
#
# Validates that the test plan generation, test data factories, E2E test
# automation (Playwright), and story-to-test traceability infrastructure
# is correctly wired.
#
# Usage: ./scripts/test-test-artifacts.sh
#
# What this tests (without running Claude or Playwright):
#   1. Test plan command structure and content
#   2. Decompose → test plan integration
#   3. Implement → test plan + E2E integration
#   4. Playwright MCP configuration
#   5. Test-writer agent E2E support
#   6. Testing skill Playwright patterns
#   7. End-to-end pipeline wiring
# =============================================================================

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
cd "$PROJECT_ROOT"

echo "=== Test Artifact Generation — Test Suite ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# ============================================================================
# 1. TEST PLAN COMMAND — structure and content
# ============================================================================
echo "1. /test-plan command — structure and content"

CMD=".claude/commands/test-plan.md"

if [[ -f "$CMD" ]]; then
  pass "/test-plan command exists"
else
  fail "/test-plan command missing"
fi

# Check for key sections
for section in "Unit Test Cases" "Integration Test Cases" "E2E Test Scenarios" "Test Data Requirements" "Traceability"; do
  if grep -qi "$section" "$CMD" 2>/dev/null; then
    pass "Section found: $section"
  else
    fail "Section missing: $section"
  fi
done

# Check it generates test plan files
if grep -q "docs/test-plans/" "$CMD" 2>/dev/null; then
  pass "Outputs to docs/test-plans/ directory"
else
  fail "Does not reference docs/test-plans/ output path"
fi

# Check it references acceptance criteria
if grep -q "Acceptance Criteria" "$CMD" 2>/dev/null; then
  pass "References acceptance criteria from story"
else
  fail "Does not reference acceptance criteria"
fi

# Check it handles frontend/fullstack expertise
if grep -q "frontend.*fullstack\|fullstack.*frontend" "$CMD" 2>/dev/null; then
  pass "Handles frontend/fullstack expertise tags for E2E"
else
  fail "Does not differentiate by expertise tag"
fi

# Check it references Playwright
if grep -q "Playwright" "$CMD" 2>/dev/null; then
  pass "References Playwright for E2E tests"
else
  fail "Does not reference Playwright"
fi

# Check it produces a traceability matrix
if grep -q "traceability" "$CMD" 2>/dev/null; then
  pass "Produces traceability matrix (criteria → tests)"
else
  fail "No traceability matrix — can't verify full coverage"
fi

# Check it references factory-boy
if grep -q "factory" "$CMD" 2>/dev/null; then
  pass "References factory pattern for test data"
else
  fail "Does not reference factory pattern"
fi

echo ""

# ============================================================================
# 2. DECOMPOSE → TEST PLAN INTEGRATION
# ============================================================================
echo "2. /decompose → /test-plan integration"

DECOMPOSE=".claude/commands/decompose.md"

if grep -q "test-plan" "$DECOMPOSE" 2>/dev/null; then
  pass "/decompose references /test-plan"
else
  fail "/decompose does not reference /test-plan — test plans won't auto-generate"
fi

if grep -q "docs/test-plans/" "$DECOMPOSE" 2>/dev/null; then
  pass "/decompose generates files in docs/test-plans/"
else
  fail "/decompose does not reference docs/test-plans/"
fi

if grep -q "Step 8\|step 8\|8\." "$DECOMPOSE" 2>/dev/null; then
  pass "Test plan generation is a numbered step in /decompose"
else
  fail "Test plan generation is not a step in /decompose"
fi

echo ""

# ============================================================================
# 3. IMPLEMENT → TEST PLAN + E2E INTEGRATION
# ============================================================================
echo "3. /implement → test plan + E2E integration"

IMPLEMENT=".claude/commands/implement.md"

# Check it reads test plans
if grep -q "docs/test-plans/" "$IMPLEMENT" 2>/dev/null; then
  pass "/implement reads test plans from docs/test-plans/"
else
  fail "/implement does not reference docs/test-plans/"
fi

# Check auto-generation fallback
if grep -q "test-plan" "$IMPLEMENT" 2>/dev/null && grep -q "does NOT exist" "$IMPLEMENT" 2>/dev/null; then
  pass "/implement auto-generates test plan if missing"
else
  fail "/implement does not auto-generate test plan when missing"
fi

# Check E2E test generation for frontend/fullstack
if grep -q "frontend.*fullstack\|fullstack.*frontend" "$IMPLEMENT" 2>/dev/null; then
  pass "/implement generates E2E tests for frontend/fullstack stories"
else
  fail "/implement does not differentiate E2E by expertise tag"
fi

# Check Playwright test structure
if grep -q "Playwright" "$IMPLEMENT" 2>/dev/null; then
  pass "/implement references Playwright for E2E tests"
else
  fail "/implement does not reference Playwright"
fi

# Check it references .mcp.json
if grep -q ".mcp.json" "$IMPLEMENT" 2>/dev/null; then
  pass "/implement references .mcp.json for Playwright MCP"
else
  fail "/implement does not reference .mcp.json"
fi

# Check data-testid selector pattern
if grep -q "data-testid" "$IMPLEMENT" 2>/dev/null; then
  pass "/implement uses data-testid selector pattern"
else
  fail "/implement does not use data-testid selectors"
fi

# Check test data section reference
if grep -q "Test Data" "$IMPLEMENT" 2>/dev/null; then
  pass "/implement references test plan's Test Data section"
else
  fail "/implement does not reference Test Data from test plan"
fi

echo ""

# ============================================================================
# 4. PLAYWRIGHT MCP CONFIGURATION
# ============================================================================
echo "4. Playwright MCP configuration"

MCP=".mcp.json"

if [[ -f "$MCP" ]]; then
  pass ".mcp.json exists"
else
  fail ".mcp.json missing — Playwright MCP unavailable"
fi

# Validate JSON structure
if jq '.' "$MCP" >/dev/null 2>&1; then
  pass ".mcp.json is valid JSON"
else
  fail ".mcp.json is invalid JSON"
fi

# Check mcpServers key
if jq -e '.mcpServers' "$MCP" >/dev/null 2>&1; then
  pass "mcpServers key present"
else
  fail "mcpServers key missing"
fi

# Check playwright server
if jq -e '.mcpServers.playwright' "$MCP" >/dev/null 2>&1; then
  pass "playwright server configured"
else
  fail "playwright server not configured"
fi

# Check command is npx
if jq -r '.mcpServers.playwright.command' "$MCP" 2>/dev/null | grep -q "npx"; then
  pass "playwright server uses npx"
else
  fail "playwright server does not use npx"
fi

# Check args include @playwright/mcp
if jq -r '.mcpServers.playwright.args[]' "$MCP" 2>/dev/null | grep -q "@playwright/mcp"; then
  pass "@playwright/mcp@latest in args"
else
  fail "@playwright/mcp@latest not in args"
fi

echo ""

# ============================================================================
# 5. TEST-WRITER AGENT — E2E support
# ============================================================================
echo "5. Test-writer agent — E2E and test data support"

AGENT=".claude/agents/test-writer.yaml"

# E2E marker
if grep -q "e2e" "$AGENT" 2>/dev/null; then
  pass "Test-writer supports @pytest.mark.e2e"
else
  fail "Test-writer does not reference e2e marker"
fi

# Playwright
if grep -q "Playwright" "$AGENT" 2>/dev/null; then
  pass "Test-writer references Playwright"
else
  fail "Test-writer does not reference Playwright"
fi

# data-testid
if grep -q "data-testid" "$AGENT" 2>/dev/null; then
  pass "Test-writer uses data-testid selector strategy"
else
  fail "Test-writer does not reference data-testid selectors"
fi

# Factory pattern
if grep -q "factory" "$AGENT" 2>/dev/null; then
  pass "Test-writer references factory pattern"
else
  fail "Test-writer does not reference factory pattern"
fi

# Test plan integration
if grep -q "test-plan" "$AGENT" 2>/dev/null || grep -q "test plan" "$AGENT" 2>/dev/null; then
  pass "Test-writer integrates with test plans"
else
  fail "Test-writer does not reference test plans"
fi

# tests/e2e/ output
if grep -q "tests/e2e/" "$AGENT" 2>/dev/null; then
  pass "Test-writer outputs E2E tests to tests/e2e/"
else
  fail "Test-writer does not reference tests/e2e/ output"
fi

# Screenshot on failure
if grep -q "screenshot" "$AGENT" 2>/dev/null; then
  pass "Test-writer includes screenshot-on-failure"
else
  fail "Test-writer does not mention screenshot-on-failure"
fi

echo ""

# ============================================================================
# 6. TESTING SKILL — Playwright patterns
# ============================================================================
echo "6. Testing skill — Playwright E2E patterns"

SKILL=".claude/skills/testing/SKILL.md"

# Playwright section
if grep -q "Playwright" "$SKILL" 2>/dev/null; then
  pass "Testing skill includes Playwright section"
else
  fail "Testing skill missing Playwright section"
fi

# conftest fixture for E2E
if grep -q "authenticated_page\|authenticated_client" "$SKILL" 2>/dev/null; then
  pass "Testing skill has authenticated page fixture"
else
  fail "Testing skill missing authenticated page fixture"
fi

# data-testid strategy
if grep -q "data-testid" "$SKILL" 2>/dev/null; then
  pass "Testing skill documents data-testid selector strategy"
else
  fail "Testing skill missing data-testid guidance"
fi

# Test plan generation section
if grep -q "Test Plan Generation" "$SKILL" 2>/dev/null; then
  pass "Testing skill has Test Plan Generation section"
else
  fail "Testing skill missing Test Plan Generation section"
fi

# Test data generation section
if grep -q "Test Data Generation\|Test Data" "$SKILL" 2>/dev/null; then
  pass "Testing skill has Test Data Generation section"
else
  fail "Testing skill missing Test Data Generation section"
fi

# Factory-boy example
if grep -q "factory.Factory\|factory-boy\|factory.Sequence" "$SKILL" 2>/dev/null; then
  pass "Testing skill has factory-boy examples"
else
  fail "Testing skill missing factory-boy examples"
fi

# Seed data
if grep -q "seed" "$SKILL" 2>/dev/null; then
  pass "Testing skill has seed data guidance"
else
  fail "Testing skill missing seed data guidance"
fi

# MCP reference
if grep -q ".mcp.json\|MCP" "$SKILL" 2>/dev/null; then
  pass "Testing skill references Playwright MCP"
else
  fail "Testing skill does not reference MCP"
fi

echo ""

# ============================================================================
# 7. END-TO-END PIPELINE WIRING
# ============================================================================
echo "7. End-to-end pipeline wiring"

# CLAUDE.md references /test-plan
if grep -q "/test-plan" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md lists /test-plan command"
else
  fail "CLAUDE.md does not list /test-plan command"
fi

# CLAUDE.md Phase 2 mentions test plans
if grep -q "docs/test-plans/" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md Phase 2 references test plan output"
else
  fail "CLAUDE.md Phase 2 does not reference test plans"
fi

# Makefile has E2E targets
if grep -q "test-e2e" Makefile 2>/dev/null; then
  pass "Makefile has test-e2e target"
else
  fail "Makefile missing test-e2e target"
fi

if grep -q "test-e2e-headed" Makefile 2>/dev/null; then
  pass "Makefile has test-e2e-headed target (visual debugging)"
else
  fail "Makefile missing test-e2e-headed target"
fi

if grep -q "test-e2e-trace" Makefile 2>/dev/null; then
  pass "Makefile has test-e2e-trace target (trace recording)"
else
  fail "Makefile missing test-e2e-trace target"
fi

# Pipeline flow: decompose → test-plan → implement → tests
echo ""
echo "  Pipeline flow check:"
echo "    /decompose → generates stories + calls /test-plan per story"
STEP1=$(grep -c "test-plan" "$DECOMPOSE" 2>/dev/null || echo 0)
echo "      /decompose → /test-plan references: $STEP1"

echo "    /test-plan → generates docs/test-plans/[story-id]-test-plan.md"
STEP2=$(grep -c "docs/test-plans/" "$CMD" 2>/dev/null || echo 0)
echo "      /test-plan → test plan output references: $STEP2"

echo "    /implement → reads test plan → spawns test-writer → writes unit + integration + E2E"
STEP3=$(grep -c "test-plan\|Test Data\|E2E" "$IMPLEMENT" 2>/dev/null || echo 0)
echo "      /implement → test plan + E2E references: $STEP3"

echo "    test-writer → reads test plan → writes tests (unit + integration + E2E)"
STEP4=$(grep -c "test.plan\|Test Plan\|E2E\|Playwright" "$AGENT" 2>/dev/null || echo 0)
echo "      test-writer → test plan + E2E references: $STEP4"

if [[ "$STEP1" -gt 0 && "$STEP2" -gt 0 && "$STEP3" -gt 0 && "$STEP4" -gt 0 ]]; then
  pass "Full pipeline is wired: decompose → test-plan → implement → test-writer"
else
  fail "Pipeline has broken links — check references above"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "=== Test Artifacts Test Summary ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "All test artifact checks passed."
  echo ""
  echo "To do a live end-to-end test of test artifact generation:"
  echo "  1. Run /interview to create docs/requirements.md"
  echo "  2. Run /decompose docs/requirements.md to generate stories + test plans"
  echo "  3. Run /test-plan on a story to verify test plan generation"
  echo "  4. Run /implement on a story (with feature branch) to verify TDD cycle"
  echo "  5. Test Playwright MCP (if installed): npx @playwright/mcp@latest --help"
else
  echo "Test artifact checks have $FAIL failure(s). Fix the issues above."
  exit 1
fi
