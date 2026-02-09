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
if grep -q "Anti-Bypass Rules" CLAUDE.md; then
  pass "Anti-Bypass Rules section found"
else
  fail "Anti-Bypass Rules section missing — bypass protections not documented"
fi
if grep -q "CRITICAL TRANSITION RULE" CLAUDE.md; then
  pass "Brainstorm-to-implementation transition rule found"
else
  fail "Brainstorm-to-implementation transition rule missing"
fi
echo ""

# ---- 3. Hooks exist and are executable ----
echo "3. Hooks"
for hook in .claude/hooks/sdlc-gate.sh .claude/hooks/branch-guard.sh .claude/hooks/lint-python.sh .claude/hooks/bash-file-guard.sh; do
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

# ---- 4. Hook wiring (settings.json) ----
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
  if grep -q "bash-file-guard.sh" .claude/settings.json; then
    pass "bash-file-guard.sh wired in settings"
  else
    fail "bash-file-guard.sh not referenced in settings — Bash redirect bypass not blocked"
  fi
else
  fail ".claude/settings.json missing"
fi
echo ""

# ---- 5. Custom commands exist ----
echo "5. Custom commands"
for cmd in gogogo interview decompose test-plan implement parallel-manual parallel-implement pr review diagnose wrapup spike; do
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
    pass "Agent teams ENABLED in settings (default — parallel implementation active)"
  elif [[ "$TEAMS_ENABLED" == "false" ]]; then
    warn "Agent teams disabled in settings — parallel implementation unavailable"
  else
    fail "Agent teams config not found in settings.json env block"
  fi
  TEAMS_ENFORCE=$(jq -r '.env.AGENT_TEAMS_ENFORCE // "not set"' .claude/settings.json 2>/dev/null)
  if [[ "$TEAMS_ENFORCE" == "true" ]]; then
    pass "Agent teams ENFORCE mode ON (default — /parallel-implement required for multi-story waves)"
  elif [[ "$TEAMS_ENFORCE" == "false" ]]; then
    warn "Agent teams enforce mode off — sequential /implement used even for multi-story waves"
  else
    fail "AGENT_TEAMS_ENFORCE not found in settings.json env block"
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

# ---- 11. Hardened gate validation ----
echo "11. Hardened SDLC gates"

# Check sdlc-gate.sh has content validation
if grep -q "REQ_LINE_COUNT" .claude/hooks/sdlc-gate.sh 2>/dev/null; then
  pass "sdlc-gate.sh validates requirements content length"
else
  fail "sdlc-gate.sh does NOT validate requirements content — stubs can bypass"
fi
if grep -q "SECTION_COUNT" .claude/hooks/sdlc-gate.sh 2>/dev/null; then
  pass "sdlc-gate.sh validates requirements section headings"
else
  fail "sdlc-gate.sh does NOT validate section headings — stubs can bypass"
fi
if grep -q "VALID_STORY_FOUND" .claude/hooks/sdlc-gate.sh 2>/dev/null; then
  pass "sdlc-gate.sh validates story file content"
else
  fail "sdlc-gate.sh does NOT validate story content — stubs can bypass"
fi

# Check expanded path coverage (not just src/ and tests/)
if grep -q '\.py.*\.ts.*\.tsx.*\.js.*\.jsx' .claude/hooks/sdlc-gate.sh 2>/dev/null; then
  pass "sdlc-gate.sh gates all code file types (.py/.ts/.tsx/.js/.jsx)"
else
  fail "sdlc-gate.sh does NOT gate all code file types"
fi

# Check conditional __init__.py
if grep -q 'LINE_COUNT.*-le 5' .claude/hooks/sdlc-gate.sh 2>/dev/null || \
   grep -q '__init__.py.*tests/' .claude/hooks/sdlc-gate.sh 2>/dev/null; then
  pass "sdlc-gate.sh has conditional __init__.py handling"
else
  fail "sdlc-gate.sh blanket-allows __init__.py — no content check"
fi

# Check bash-file-guard.sh exists, executable, wired
if [[ -f ".claude/hooks/bash-file-guard.sh" ]]; then
  pass "bash-file-guard.sh exists"
  if [[ -x ".claude/hooks/bash-file-guard.sh" ]]; then
    pass "bash-file-guard.sh is executable"
  else
    fail "bash-file-guard.sh is NOT executable"
  fi
  if grep -q "bash-file-guard.sh" .claude/settings.json 2>/dev/null; then
    pass "bash-file-guard.sh wired in settings.json"
  else
    fail "bash-file-guard.sh NOT wired in settings.json — Bash redirects can bypass gates"
  fi
  if grep -q "docs/requirements" .claude/hooks/bash-file-guard.sh 2>/dev/null; then
    pass "bash-file-guard.sh blocks redirects to docs/requirements.md"
  else
    fail "bash-file-guard.sh does NOT block redirects to requirements"
  fi
  if grep -q "docs/backlog" .claude/hooks/bash-file-guard.sh 2>/dev/null; then
    pass "bash-file-guard.sh blocks redirects to docs/backlog/"
  else
    fail "bash-file-guard.sh does NOT block redirects to backlog"
  fi
  if grep -q "docs/test-plans" .claude/hooks/bash-file-guard.sh 2>/dev/null; then
    pass "bash-file-guard.sh blocks redirects to docs/test-plans/"
  else
    fail "bash-file-guard.sh does NOT block redirects to test-plans"
  fi
else
  fail "bash-file-guard.sh missing — Bash redirect bypass not protected"
fi

# Check test plan gate for src/
if grep -q "test-plans.*STORY" .claude/hooks/sdlc-gate.sh 2>/dev/null; then
  pass "sdlc-gate.sh requires test plan for src/ writes"
else
  fail "sdlc-gate.sh does NOT require test plan for src/ writes"
fi

# Check implement.md has pre-flight
if grep -q "Pre-flight Verification" .claude/commands/implement.md 2>/dev/null; then
  pass "/implement has Phase 0 pre-flight verification"
else
  fail "/implement missing Phase 0 pre-flight — prerequisites not checked"
fi
echo ""

# ---- 12. Spike exploration mode ----
echo "12. Spike exploration mode"
if [[ -f ".claude/commands/spike.md" ]]; then
  pass "/spike command exists"
else
  fail "/spike command missing"
fi
if grep -q "spike/" .claude/hooks/sdlc-gate.sh 2>/dev/null; then
  pass "sdlc-gate.sh has spike branch exemption"
else
  fail "sdlc-gate.sh missing spike branch exemption — spike branches will be blocked"
fi
if grep -q "merge.*spike" .claude/hooks/branch-guard.sh 2>/dev/null; then
  pass "branch-guard.sh blocks merging spike branches"
else
  fail "branch-guard.sh does NOT block spike merges — spike code could reach main"
fi
if grep -q "pr.*create.*spike\|spike.*pr.*create" .claude/hooks/branch-guard.sh 2>/dev/null; then
  pass "branch-guard.sh blocks PR creation from spike branches"
else
  # Also check for the pattern where spike branch check wraps gh pr create
  if grep -q 'spike/\*' .claude/hooks/branch-guard.sh 2>/dev/null && grep -q 'gh.*pr.*create' .claude/hooks/branch-guard.sh 2>/dev/null; then
    pass "branch-guard.sh blocks PR creation from spike branches"
  else
    fail "branch-guard.sh does NOT block PR creation from spike branches"
  fi
fi
if grep -q "Spike" CLAUDE.md 2>/dev/null || grep -q "spike" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md references spike mode"
else
  fail "CLAUDE.md does not mention spike mode"
fi
echo ""

# ---- 13. Performance reviewer agent ----
echo "13. Performance reviewer agent"
if [[ -f ".claude/agents/performance-reviewer.yaml" ]]; then
  pass "performance-reviewer.yaml exists"
  if grep -q "name: performance-reviewer" .claude/agents/performance-reviewer.yaml 2>/dev/null; then
    pass "performance-reviewer.yaml has correct name field"
  else
    fail "performance-reviewer.yaml missing name field"
  fi
  if grep -q "allowed_tools" .claude/agents/performance-reviewer.yaml 2>/dev/null; then
    pass "performance-reviewer.yaml has allowed_tools"
  else
    fail "performance-reviewer.yaml missing allowed_tools"
  fi
  if grep -q "N+1\|N.1" .claude/agents/performance-reviewer.yaml 2>/dev/null; then
    pass "performance-reviewer.yaml checks N+1 queries"
  else
    fail "performance-reviewer.yaml missing N+1 query check"
  fi
  if grep -q "pagination\|Pagination" .claude/agents/performance-reviewer.yaml 2>/dev/null; then
    pass "performance-reviewer.yaml checks pagination"
  else
    fail "performance-reviewer.yaml missing pagination check"
  fi
else
  fail "performance-reviewer.yaml missing"
fi
if grep -q "performance-reviewer" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md references performance-reviewer agent"
else
  fail "CLAUDE.md does not reference performance-reviewer agent"
fi
echo ""

# ---- 14. Asset dependency gate ----
echo "14. Asset dependency gate"
if grep -q "Asset Dependencies" .claude/commands/decompose.md 2>/dev/null; then
  pass "/decompose includes Asset Dependencies section in story template"
else
  fail "/decompose missing Asset Dependencies section — stories won't track external assets"
fi
if grep -q "Asset Dependencies\|asset.*missing\|Asset.*dependency\|asset dependency" .claude/commands/implement.md 2>/dev/null; then
  pass "/implement checks asset dependencies before starting"
else
  fail "/implement does NOT check asset dependencies — blocked stories may start"
fi
if grep -q "ASSET GATE\|Asset.*enforcement\|asset enforcement" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md documents asset dependency gate"
else
  fail "CLAUDE.md does not document asset dependency gate"
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
