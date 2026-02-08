#!/bin/bash
# Validate that the SDLC scaffolding template is correctly set up.
# Run this after cloning the template to verify everything works.
#
# Usage: ./scripts/validate-template.sh

PASS=0
FAIL=0
WARN=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  WARN: $1"; WARN=$((WARN + 1)); }

echo "=== SDLC Template Validation ==="
echo ""

# ---- 1. Core files exist ----
echo "1. Core files"
for f in CLAUDE.md Makefile pyproject.toml requirements.txt requirements-dev.txt Dockerfile .gitignore .env.example; do
  if [[ -f "$f" ]]; then pass "$f exists"; else fail "$f missing"; fi
done
echo ""

# ---- 2. CLAUDE.md has mandatory workflow ----
echo "2. CLAUDE.md enforcement"
if grep -q "MANDATORY SDLC Workflow" CLAUDE.md; then
  pass "MANDATORY SDLC Workflow section found"
else
  fail "MANDATORY SDLC Workflow section missing — CLAUDE.md won't enforce the process"
fi
if grep -q "BLOCKING REQUIREMENT" CLAUDE.md; then
  pass "BLOCKING REQUIREMENT directive found"
else
  fail "BLOCKING REQUIREMENT directive missing — Claude may skip steps"
fi
if grep -q "GATE.*Do NOT proceed" CLAUDE.md; then
  pass "Phase gates found"
else
  fail "Phase gates missing — no enforcement between phases"
fi
echo ""

# ---- 3. Hooks exist and are executable ----
echo "3. Hooks"
for hook in .claude/hooks/sdlc-gate.sh .claude/hooks/branch-guard.sh .claude/hooks/lint-python.sh; do
  if [[ -f "$hook" ]]; then
    pass "$hook exists"
    if [[ -x "$hook" ]]; then
      pass "$hook is executable"
    else
      fail "$hook is NOT executable — run: chmod +x $hook"
    fi
  else
    fail "$hook missing"
  fi
done
echo ""

# ---- 4. settings.json wires hooks correctly ----
echo "4. Hook wiring (settings.json)"
if [[ -f ".claude/settings.json" ]]; then
  pass ".claude/settings.json exists"
  if grep -q "PreToolUse" .claude/settings.json; then
    pass "PreToolUse hooks configured"
  else
    fail "PreToolUse hooks missing — SDLC gates won't fire"
  fi
  if grep -q "PostToolUse" .claude/settings.json; then
    pass "PostToolUse hooks configured"
  else
    warn "PostToolUse hooks missing — lint-on-save won't work"
  fi
  if grep -q "sdlc-gate.sh" .claude/settings.json; then
    pass "sdlc-gate.sh wired in settings"
  else
    fail "sdlc-gate.sh not referenced in settings — gate won't fire"
  fi
  if grep -q "branch-guard.sh" .claude/settings.json; then
    pass "branch-guard.sh wired in settings"
  else
    fail "branch-guard.sh not referenced in settings — branch protection off"
  fi
else
  fail ".claude/settings.json missing"
fi
echo ""

# ---- 5. Custom commands exist ----
echo "5. Custom commands"
for cmd in gogogo interview decompose test-plan implement parallel-manual parallel-implement pr review diagnose wrapup; do
  if [[ -f ".claude/commands/$cmd.md" ]]; then
    pass "/$ $cmd command exists"
  else
    fail "/$cmd command missing"
  fi
done
echo ""

# ---- 6. Rules exist ----
echo "6. Rules"
for rule in security error-handling code-style testing git-workflow; do
  if [[ -f ".claude/rules/$rule.md" ]]; then
    pass "$rule rule exists"
  else
    fail "$rule rule missing"
  fi
done
echo ""

# ---- 7. Prerequisites ----
echo "7. Prerequisites"
if command -v jq &>/dev/null; then
  pass "jq installed (required by hooks)"
else
  fail "jq not installed — hooks will fail. Install: brew install jq"
fi
if command -v ruff &>/dev/null; then
  pass "ruff installed"
else
  warn "ruff not installed — lint hook won't work. Install: pip install ruff"
fi
if command -v mypy &>/dev/null; then
  pass "mypy installed"
else
  warn "mypy not installed — type check hook won't work. Install: pip install mypy"
fi
echo ""

# ---- 8. SDLC gate simulation ----
echo "8. SDLC gate simulation (what would happen if Claude tries to write code now)"
if [[ ! -f "docs/requirements.md" ]]; then
  pass "Gate 1 would BLOCK: docs/requirements.md missing (correct — forces /interview)"
else
  warn "Gate 1 would PASS: docs/requirements.md exists"
fi

STORY_COUNT=$(find docs/backlog -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$STORY_COUNT" -eq 0 ]]; then
  pass "Gate 2 would BLOCK: no stories in docs/backlog/ (correct — forces /decompose)"
else
  warn "Gate 2 would PASS: $STORY_COUNT stories found"
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  pass "Gate 3 would BLOCK: on $BRANCH branch (correct — forces feature branch)"
else
  warn "Gate 3 would PASS: on branch '$BRANCH'"
fi
echo ""

# ---- 9. Agent teams configuration ----
echo "9. Agent teams (parallel implementation)"
if [[ -f ".claude/commands/parallel-implement.md" ]]; then
  pass "/parallel-implement command exists"
else
  fail "/parallel-implement command missing"
fi
if [[ -f ".claude/commands/parallel-manual.md" ]]; then
  pass "/parallel-manual command exists"
else
  fail "/parallel-manual command missing"
fi
for hook in .claude/hooks/worktree-guard.sh .claude/hooks/teammate-completed.sh .claude/hooks/teammate-idle.sh; do
  if [[ -f "$hook" ]]; then
    pass "$hook exists"
    if [[ -x "$hook" ]]; then
      pass "$hook is executable"
    else
      fail "$hook is NOT executable — run: chmod +x $hook"
    fi
  else
    fail "$hook missing"
  fi
done
if [[ -f ".claude/settings.json" ]]; then
  TEAMS_ENABLED=$(jq -r '.env.AGENT_TEAMS_ENABLED // "not set"' .claude/settings.json 2>/dev/null)
  if [[ "$TEAMS_ENABLED" == "true" ]]; then
    warn "Agent teams ENABLED in settings — experimental feature is active"
  elif [[ "$TEAMS_ENABLED" == "false" ]]; then
    pass "Agent teams disabled in settings (default — enable with AGENT_TEAMS_ENABLED=true)"
  else
    warn "Agent teams config not found in settings.json env block"
  fi
  TEAMS_ENFORCE=$(jq -r '.env.AGENT_TEAMS_ENFORCE // "not set"' .claude/settings.json 2>/dev/null)
  if [[ "$TEAMS_ENFORCE" == "true" ]]; then
    warn "Agent teams ENFORCE mode is ON — Claude will require /parallel-implement for multi-story waves"
  elif [[ "$TEAMS_ENFORCE" == "false" ]]; then
    pass "Agent teams enforce mode off (default — sequential /implement used)"
  else
    warn "AGENT_TEAMS_ENFORCE not found in settings.json env block"
  fi
  if grep -q "worktree-guard.sh" .claude/settings.json; then
    pass "worktree-guard.sh wired in settings"
  else
    fail "worktree-guard.sh not referenced in settings"
  fi
  if grep -q "teammate-completed.sh" .claude/settings.json; then
    pass "teammate-completed.sh wired in settings"
  else
    fail "teammate-completed.sh not referenced in settings"
  fi
  if grep -q "teammate-idle.sh" .claude/settings.json; then
    pass "teammate-idle.sh wired in settings"
  else
    fail "teammate-idle.sh not referenced in settings"
  fi
  if grep -q "TeammateIdle" .claude/settings.json; then
    pass "TeammateIdle hook event configured"
  else
    fail "TeammateIdle hook event missing — idle teammates won't be validated"
  fi
fi
if grep -q ".worktrees/" .gitignore 2>/dev/null; then
  pass ".worktrees/ in .gitignore"
else
  fail ".worktrees/ not in .gitignore — worktrees would be tracked"
fi
echo ""

# ---- 10. MCP and Playwright configuration ----
echo "10. MCP and Playwright configuration"
if [[ -f ".mcp.json" ]]; then
  pass ".mcp.json exists"
  if grep -q "playwright" .mcp.json; then
    pass "Playwright MCP server configured in .mcp.json"
  else
    warn "Playwright MCP server not found in .mcp.json — E2E test automation unavailable"
  fi
  if grep -q "@playwright/mcp" .mcp.json; then
    pass "@playwright/mcp package referenced"
  else
    warn "@playwright/mcp package not referenced"
  fi
else
  warn ".mcp.json missing — MCP servers not configured (Playwright E2E unavailable)"
fi
if [[ -f ".claude/commands/test-plan.md" ]]; then
  pass "/test-plan command exists"
else
  fail "/test-plan command missing — test plans won't be generated from stories"
fi
if grep -q "test-plan" .claude/commands/decompose.md 2>/dev/null; then
  pass "/decompose references /test-plan for automatic test plan generation"
else
  warn "/decompose does not reference /test-plan — test plans must be generated manually"
fi
if grep -q "E2E" .claude/commands/implement.md 2>/dev/null; then
  pass "/implement includes E2E test phase"
else
  warn "/implement does not reference E2E tests"
fi
if grep -q "Playwright" .claude/skills/testing/SKILL.md 2>/dev/null; then
  pass "Testing skill includes Playwright E2E patterns"
else
  warn "Testing skill missing Playwright E2E patterns"
fi
if grep -q "e2e" .claude/agents/test-writer.yaml 2>/dev/null; then
  pass "Test-writer agent supports E2E tests"
else
  warn "Test-writer agent does not reference E2E tests"
fi
echo ""

# ---- Summary ----
echo "=== Summary ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "Template is correctly configured. All SDLC gates are in place."
else
  echo "Template has $FAIL issue(s) that need fixing. See FAIL items above."
  exit 1
fi
