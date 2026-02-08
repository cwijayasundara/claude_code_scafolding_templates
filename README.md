# Claude Code SDLC Scaffolding Template

Production-ready Claude Code configuration that enforces a full SDLC workflow with gated phases, TDD, and automated quality checks. Supports sequential and parallel (agent teams) implementation with dependency-safe wave batching.

**Includes:** 12 slash commands, 6 enforcement rules (Python + TypeScript/React), 7 domain skills, 3 sub-agents, 7 hooks, starter permissions, and a 12-point code review checklist.

---

## Framework Design

### Architecture Overview

The framework wraps Claude Code with six concentric enforcement layers. Each layer intercepts at a different point in the development lifecycle — from session startup to task completion — ensuring no code is written without requirements, no story starts without passing gates, and no PR merges without CI.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLAUDE.md                                   │
│              (Standards, Checklists, Mode Enforcement)              │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Slash Commands (12)                        │  │
│  │  /interview → /decompose → /implement → /pr → /wrapup       │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │                  Hooks (7)                              │  │  │
│  │  │  PreToolUse:  sdlc-gate | branch-guard | worktree-guard│  │  │
│  │  │  PostToolUse: lint-python | lint-frontend              │  │  │
│  │  │  Events:      teammate-idle | teammate-completed       │  │  │
│  │  │  ┌───────────────────────────────────────────────────┐  │  │  │
│  │  │  │              Rules (6)                            │  │  │  │
│  │  │  │  security | error-handling | code-style           │  │  │  │
│  │  │  │  testing  | git-workflow   | react-patterns       │  │  │  │
│  │  │  │  ┌─────────────────────────────────────────────┐  │  │  │  │
│  │  │  │  │           Sub-Agents (3)                    │  │  │  │  │
│  │  │  │  │  test-writer | code-reviewer | architect    │  │  │  │  │
│  │  │  │  │  ┌───────────────────────────────────────┐  │  │  │  │  │
│  │  │  │  │  │          Skills (7)                   │  │  │  │  │  │
│  │  │  │  │  │  api-design    | database-patterns    │  │  │  │  │  │
│  │  │  │  │  │  testing       | deployment           │  │  │  │  │  │
│  │  │  │  │  │  langgraph     | react-frontend       │  │  │  │  │  │
│  │  │  │  │  │  claude-agent-teams                   │  │  │  │  │  │
│  │  │  │  │  └───────────────────────────────────────┘  │  │  │  │  │
│  │  │  │  └─────────────────────────────────────────────┘  │  │  │  │
│  │  │  └───────────────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

**Precedence** (inner layers are advisory, outer layers are mandatory):

```
CLAUDE.md  >  Hooks  >  Rules  >  Sub-Agents  >  Skills
 (must)      (auto)   (must)     (delegated)    (advisory)
```

### SDLC Phase Pipeline

The framework enforces a strict phase pipeline. Each phase has a **gate** that blocks progression until artifacts are produced. Hooks enforce the gates automatically — Claude cannot skip phases.

```
  Phase 0         Phase 1          Phase 2              Phase 3
 ┌────────┐    ┌───────────┐    ┌──────────────┐    ┌──────────────────┐
 │/gogogo │───▶│/interview │───▶│ /decompose   │───▶│  /implement      │
 │        │    │           │    │ /test-plan   │    │  (TDD per story) │
 │ Load   │    │ Gather    │    │              │    │                  │
 │ context │    │ reqs      │    │ Break into   │    │  Red ──▶ Green   │
 │ + status│    │           │    │ epics/stories│    │    ──▶ Refactor  │
 └────────┘    └─────┬─────┘    │ + dep graph  │    │    ──▶ Validate  │
                     │          │ + test plans │    │                  │
                     ▼          └──────┬───────┘    └────────┬─────────┘
               ┌──────────┐           │                      │
               │ GATE:    │           ▼                      ▼
               │ docs/    │    ┌──────────────┐    ┌──────────────────┐
               │ require- │    │ GATE:        │    │ GATE:            │
               │ ments.md │    │ docs/backlog/│    │ make ci passes   │
               │ exists?  │    │ has stories? │    │ coverage >= 80%  │
               └──────────┘    └──────────────┘    └────────┬─────────┘
                                                            │
                Phase 4          Phase 5                    │
               ┌──────────┐    ┌───────────┐               │
               │  /pr     │◀───│  /review  │◀──────────────┘
               │          │    │           │
               │ CI + push│    │ 12-point  │
               │ + create │    │ checklist │
               │ PR       │    │           │
               └──────────┘    └─────┬─────┘
                                     │
                                     ▼
                              ┌───────────┐
                              │  /wrapup  │
                              │           │
                              │ Commit,   │
                              │ push,     │
                              │ handoff   │
                              └───────────┘
```

### TDD Cycle (Per Story)

Every story goes through `/implement` which enforces Red-Green-Refactor:

```
                    ┌─────────────────────────────┐
                    │  /implement <story-file>     │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  1. RED: Write failing tests │
                    │     (test-writer sub-agent)  │
                    │     commit: test: ...        │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  2. GREEN: Minimum code to   │
                    │     pass all tests           │
                    │     commit: feat: ...        │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  3. REFACTOR: Apply Pre-     │
                    │     Completion Checklist      │
                    │     commit: refactor: ...    │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  4. VALIDATE: make ci        │
                    │     coverage >= 80%          │
                    └─────────────────────────────┘
```

### Parallel Implementation (Agent Teams)

When multiple stories in a wave have no dependencies on each other, the framework can implement them in parallel. `/decompose` produces a topological sort that groups independent stories into waves:

```
  docs/backlog/dependency-graph.mmd          docs/backlog/parallel-batches.md
 ┌──────────────────────────────┐           ┌─────────────────────────────┐
 │  STORY-001 ──▶ STORY-004    │           │ Wave 1: [001, 002, 003]    │
 │  STORY-002 ──▶ STORY-005    │    ───▶   │ Wave 2: [004, 005]         │
 │  STORY-003 ──┘              │           │ Wave 3: [006]              │
 │  STORY-005 ──▶ STORY-006    │           │                             │
 └──────────────────────────────┘           └─────────────────────────────┘

  /parallel-implement wave-1
 ┌─────────────────────────────────────────────────────────────────┐
 │  Lead Session (delegate mode — coordinates, does NOT code)      │
 │                                                                 │
 │  ┌──────────────────┐ ┌──────────────────┐ ┌────────────────┐  │
 │  │ Teammate 1       │ │ Teammate 2       │ │ Teammate 3     │  │
 │  │ .worktrees/001/  │ │ .worktrees/002/  │ │ .worktrees/003/│  │
 │  │ STORY-001        │ │ STORY-002        │ │ STORY-003      │  │
 │  │ TDD cycle        │ │ TDD cycle        │ │ TDD cycle      │  │
 │  └────────┬─────────┘ └────────┬─────────┘ └───────┬────────┘  │
 │           │                    │                    │           │
 │           ▼                    ▼                    ▼           │
 │  ┌──────────────────────────────────────────────────────────┐   │
 │  │  Quality Hooks (automatic enforcement per teammate)      │   │
 │  │  • worktree-guard: blocks writes outside worktree        │   │
 │  │  • teammate-idle: rejects idle if CI fails               │   │
 │  │  • teammate-completed: rejects done if make ci fails     │   │
 │  └──────────────────────────────────────────────────────────┘   │
 │                                                                 │
 │  Lead: collect results → create PRs → clean up worktrees       │
 └─────────────────────────────────────────────────────────────────┘
```

### Hook Enforcement Model

Hooks intercept Claude Code tool calls at specific lifecycle events. They receive JSON on stdin and control whether the action proceeds (exit 0) or is blocked (exit 2 with feedback on stderr).

```
  Claude Code Tool Call
         │
         ▼
  ┌──────────────┐     ┌──────────────────────────────────────────────┐
  │ PreToolUse   │────▶│ sdlc-gate.sh                                │
  │ Write/Edit   │     │   Does docs/requirements.md exist?    ──No──▶ BLOCK
  │              │     │   Does docs/backlog/ have stories?    ──No──▶ BLOCK
  │              │     │   Are we on a feature branch?         ──No──▶ BLOCK
  │              │     │                                              │
  │              │────▶│ worktree-guard.sh                            │
  │              │     │   Is file inside teammate's worktree? ──No──▶ BLOCK
  └──────────────┘     └──────────────────────────────────────────────┘
         │
         ▼
  ┌──────────────┐     ┌──────────────────────────────────────────────┐
  │ PreToolUse   │────▶│ branch-guard.sh                              │
  │ Bash (git)   │     │   Is this git push --force?           ──Yes─▶ BLOCK
  │              │     │   Is this a commit to main/master?    ──Yes─▶ BLOCK
  └──────────────┘     └──────────────────────────────────────────────┘
         │
         ▼
    [Tool executes]
         │
         ▼
  ┌──────────────┐     ┌──────────────────────────────────────────────┐
  │ PostToolUse  │────▶│ lint-python.sh    (*.py files)               │
  │ Write/Edit   │     │   ruff check --fix && mypy                   │
  │              │────▶│ lint-frontend.sh  (*.ts, *.tsx files)        │
  │              │     │   eslint --fix && tsc --noEmit               │
  └──────────────┘     └──────────────────────────────────────────────┘
         │
         ▼
  ┌──────────────┐     ┌──────────────────────────────────────────────┐
  │ TeammateIdle │────▶│ teammate-idle.sh                             │
  │              │     │   Uncommitted changes?                ──Yes─▶ BLOCK
  │              │     │   make ci failing?                    ──Yes─▶ BLOCK
  └──────────────┘     └──────────────────────────────────────────────┘
         │
         ▼
  ┌──────────────┐     ┌──────────────────────────────────────────────┐
  │TaskCompleted │────▶│ teammate-completed.sh                        │
  │              │     │   make ci passes?                     ──No──▶ BLOCK
  └──────────────┘     └──────────────────────────────────────────────┘
```

### Rule Coverage Matrix

Rules apply to specific file globs. The framework covers both backend (Python) and frontend (TypeScript/React):

```
                        Python     TypeScript    React
  Rule                 src/**/*.py  src/**/*.ts  src/**/*.tsx
  ─────────────────    ──────────  ───────────  ───────────
  security.md              ✓           ✓            ✓
  error-handling.md        ✓           ✓            ✓
  code-style.md            ✓           ✓            ✓
  testing.md               ✓           ✓            ✓
  git-workflow.md          ✓           ✓            ✓
  react-patterns.md        -           ✓            ✓
```

### 12-Point Code Review Checklist

The `code-reviewer` sub-agent evaluates every PR against:

```
   #   Category                  Severity    Scope
  ───  ────────────────────────  ──────────  ──────────────
   1   SOLID Principles          WARNING     Python + TS
   2   Code Duplication          WARNING     Python + TS
   3   Hardcoded Values          WARNING     Python + TS
   4   Test Coverage             WARNING     Python + TS
   5   Error Handling            CRITICAL    Python + TS
   6   Security                  CRITICAL    Python + TS
   7   Performance               WARNING     Python + TS
   8   Documentation             SUGGESTION  Python + TS
   9   Logging                   WARNING     Python + TS
  10   Dead Code & Unused Code   WARNING     Python + TS
  11   React Anti-Patterns       CRITICAL    React/TS only
  12   Helper Function Tests     WARNING     Python + TS
```

---

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Python 3.12+ and `pip`
- Git and GitHub CLI (`gh`)

## Getting the Template

### Option A: Clone and reinitialize (recommended for new projects)

```bash
# 1. Clone the template repo
git clone https://github.com/cwijayasundara/claude_code_scafolding_templates.git my-project
cd my-project

# 2. Remove the template's git history and start fresh
rm -rf .git
git init
git add -A
git commit -m "feat: initial project from SDLC scaffolding template"

# 3. Install dev dependencies
make build

# 4. Verify everything works
make ci
```

### Option B: Copy into an existing project

```bash
# 1. Clone the template to a temporary location
git clone https://github.com/cwijayasundara/claude_code_scafolding_templates.git /tmp/sdlc-template

# 2. Copy the files you need into your project
cp /tmp/sdlc-template/CLAUDE.md /path/to/your-project/
cp -r /tmp/sdlc-template/.claude/ /path/to/your-project/.claude/
cp -r /tmp/sdlc-template/.github/ /path/to/your-project/.github/

# 3. Optionally copy bootstrap files (skip any you already have)
cp /tmp/sdlc-template/pyproject.toml /path/to/your-project/
cp /tmp/sdlc-template/Makefile /path/to/your-project/
cp /tmp/sdlc-template/.env.example /path/to/your-project/
cp /tmp/sdlc-template/.gitignore /path/to/your-project/
cp /tmp/sdlc-template/Dockerfile /path/to/your-project/
cp -r /tmp/sdlc-template/src/ /path/to/your-project/src/
cp -r /tmp/sdlc-template/tests/ /path/to/your-project/tests/

# 4. Clean up
rm -rf /tmp/sdlc-template
```

### Option C: Download without git history

```bash
# Download and extract (no git history)
gh repo clone cwijayasundara/claude_code_scafolding_templates my-project -- --depth=1
cd my-project && rm -rf .git
```

## Post-Setup: What to Customize

After cloning, you **must** update these files for your project:

### 1. `CLAUDE.md` (required)

Open `CLAUDE.md` and update:

```markdown
# Project: [Your Project Name]       <-- Replace with your project name

## Tech Stack
- Backend: Python 3.12 / FastAPI     <-- Adjust to your actual stack
```

Also update the `## Commands` section if your `make` targets differ.

### 2. `pyproject.toml` (required)

```toml
[project]
name = "my-project"                   # <-- Your project name
version = "0.1.0"
description = "Your project description"  # <-- Your description
dependencies = []                     # <-- Add your runtime dependencies
```

The linting (`ruff`), type-checking (`mypy`), and test (`pytest`) configurations are pre-configured and ready to use.

### 3. `.env.example` (required)

Update with the environment variables your project actually needs:

```bash
# Replace the example variables with your own
YOUR_API_KEY=your-key-here
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/mydb
```

Then create your local `.env` from it:

```bash
cp .env.example .env
# Edit .env with real values (never committed — already in .gitignore)
```

### 4. `.claude/settings.json` (optional)

The starter permissions pre-approve common dev commands so Claude Code doesn't prompt you for each one. Review and adjust:

```json
{
  "permissions": {
    "allow": [
      "Bash(python3 *)",
      "Bash(pytest *)",
      "Bash(make *)",
      "Bash(git *)"
    ]
  }
}
```

Add or remove commands to match your stack (e.g., add `"Bash(cargo *)"` for Rust).

### 5. `.claude/skills/` (optional)

Keep the skills relevant to your stack, delete the rest:

```bash
# Example: remove skills you don't need
rm -rf .claude/skills/react-frontend/       # No frontend
rm -rf .claude/skills/langgraph-agents/     # No LangGraph
rm -rf .claude/skills/deployment/           # Custom deployment
```

Add new skills by creating `.claude/skills/<name>/SKILL.md` with YAML frontmatter.

### 6. `.github/workflows/` (optional)

The CI workflow (`ci.yml`) runs `ruff`, `mypy`, unit tests, integration tests, and coverage checks on every push/PR. Update `release.yml` to match your Docker image name and registry.

## Using the Template with Claude Code

Once set up, open your project in a terminal and launch Claude Code:

```bash
cd my-project
claude
```

Claude Code automatically reads `CLAUDE.md` and `.claude/` on startup. The rules, skills, and commands are immediately available.

### Start a Session

```
/gogogo
```

This loads project context, checks git status, shows your backlog, shows parallel options, and suggests what to work on next. **Always start here.**

### Choosing an Implementation Mode

The framework supports three modes. Choose based on your team size, budget, and risk tolerance:

| Mode | Command | Setup | Token Cost | Best For |
|------|---------|-------|-----------|----------|
| **Sequential** (default) | `/implement` | None | 1x | Solo dev, early projects |
| **Manual Parallel** | `/parallel-manual` | Multiple terminals | 1x per terminal | Teams, cost-conscious |
| **Agent Teams** | `/parallel-implement` | Experimental flag | ~7x per teammate | Speed-critical, budget available |

To switch modes, edit `.claude/settings.json` -> `env` block:

```jsonc
"env": {
  "AGENT_TEAMS_ENABLED": "true",   // unlock /parallel-implement
  "AGENT_TEAMS_ENFORCE": "true",   // FORCE parallel for multi-story waves
  "AGENT_TEAMS_MAX_TEAMMATES": "3" // max concurrent teammates
}
```

Also set the environment variable in your `.env`:
```bash
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

### Mode 1: Sequential (Default)

Stories are implemented one at a time. This is the simplest and most stable workflow.

```
/interview                              # 1. Gather requirements
/decompose docs/requirements.md         # 2. Break into stories + dependency graph
/implement docs/backlog/<story>.md      # 3. TDD: Red -> Green -> Refactor
/pr                                     # 4. Run CI + create pull request
/review 42                              # 5. Review PR #42
/wrapup                                 # 6. Commit, push, handoff summary
```

Each story goes through the full TDD cycle (Red -> Green -> Refactor -> Validate). The next story only starts after the current one passes CI.

### Mode 2: Manual Parallel (`/parallel-manual`)

Independent stories run concurrently in separate terminals using git worktrees. Same cost as sequential — just faster wall-clock time.

```
/decompose docs/requirements.md         # Generates parallel-batches.md with waves
/parallel-manual wave-1                  # Creates worktrees, prints per-terminal instructions
```

This creates one git worktree per story and prints instructions like:

```
Terminal 1:  cd .worktrees/STORY-001 && claude   ->  /implement docs/backlog/.../STORY-001.md
Terminal 2:  cd .worktrees/STORY-002 && claude   ->  /implement docs/backlog/.../STORY-002.md
Terminal 3:  cd .worktrees/STORY-003 && claude   ->  /implement docs/backlog/.../STORY-003.md
```

After all terminals complete, merge branches and clean up worktrees from the main tree.

### Mode 3: Agent Teams (`/parallel-implement`)

Uses Claude Code's **native agent teams** feature (Opus 4.6). The lead session creates a team, spawns one teammate per story, and coordinates via a shared task list and inter-agent messaging — all within a single terminal.

```
/decompose docs/requirements.md         # Generates waves with dependency analysis
/parallel-implement wave-1               # Creates agent team, spawns teammates
```

**How it works:**
1. The lead creates git worktrees (one per story) to avoid file conflicts
2. The lead creates a native agent team and spawns one teammate per story
3. The lead enters **delegate mode** — coordinates only, does NOT write code
4. Each teammate requires **plan approval** from the lead before implementing
5. Teammates run the TDD cycle (Red -> Green -> Refactor -> Validate) independently
6. Quality hooks fire automatically:
   - `TeammateIdle` — rejects idle if CI fails or uncommitted changes
   - `TaskCompleted` — rejects task completion if `make ci` fails
   - `worktree-guard.sh` — blocks writes outside the teammate's worktree
7. The lead collects results, creates PRs for passing stories, cleans up

**Requires:**
1. Environment variable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
2. Setting: `AGENT_TEAMS_ENABLED=true` in `.claude/settings.json`

**Enforced mode** (`AGENT_TEAMS_ENFORCE=true`): Claude is REQUIRED to use `/parallel-implement` for any wave with 2+ independent stories. Sequential `/implement` is only used for single-story waves or as a fallback if agent teams fail.

### How Story Dependencies Prevent Unsafe Parallelization

The `/decompose` command generates a `## Dependencies` section in every story file:

```markdown
## Dependencies
- depends_on: [STORY-001, STORY-002]
- blocks: [STORY-010]
- Reason: Requires the user model from STORY-001 and the auth middleware from STORY-002
```

The dependency graph is used to compute **waves** via topological sort:

```
Wave 1: [STORY-001, STORY-002, STORY-003]   <- zero dependencies, safe to parallelize
Wave 2: [STORY-004, STORY-005]               <- depend on Wave 1 stories only
Wave 3: [STORY-006]                           <- depends on Wave 2 stories
```

**Rules enforced by the framework:**
- Stories with `depends_on` relationships are NEVER in the same wave
- A wave only starts after ALL stories in previous waves are Done
- Before starting any story, its `depends_on` list is verified — blocked stories are rejected
- The `sdlc-gate.sh` hook blocks code writes if prerequisite gates are not met

### Between Stories

```
/clear                                  # Reset context window between stories
/compact                                # Compress context during long sessions
```

### Other Commands

```
/diagnose <failure-output>              # Diagnose test failures, create hotfix
/create-prompt                          # Build structured prompt (R.G.C.O.A.)
```

## What's Included

```
.mcp.json                                # MCP server config (Playwright E2E)
CLAUDE.md                                # Standards, mode enforcement,
                                         # Pre-Completion Checklists (Backend + Frontend)
pyproject.toml                           # Ruff (ERA,T20,C90), mypy, pytest config
Makefile                                 # All build/test/deploy targets
.env.example                             # Environment variable template
.gitignore                               # Python, Node, IDE, OS ignores
Dockerfile                               # Multi-stage Python 3.12 build
.dockerignore                            # Lean Docker context

src/                                     # Source code directory (stub)
  __init__.py
  __main__.py                            # Entry point stub

tests/                                   # Test directories with markers
  conftest.py                            # Shared fixtures
  unit/
  integration/
  e2e/

.claude/
  settings.json                          # Hooks + starter permissions + agent teams config
  rules/
    security.md                          # Secrets, input validation, SQL injection, frontend fetch
    code-style.md                        # Size limits (50/500), constants, type safety, dead code
    error-handling.md                    # try/except + try/catch, logging (Python + TypeScript)
    testing.md                           # TDD, fixtures, coverage, helper function tests
    git-workflow.md                      # Branch naming, conventional commits
    react-patterns.md                    # React keys, useEffect cleanup, empty catch, no any
  commands/
    gogogo.md                            # /gogogo — Session startup ceremony
    interview.md                         # /interview — Requirements gathering
    decompose.md                         # /decompose — Requirements -> stories + waves + test plans
    test-plan.md                         # /test-plan — Generate test plan from story
    implement.md                         # /implement — TDD Red-Green-Refactor + E2E (sequential)
    parallel-manual.md                   # /parallel-manual — Worktree setup for manual parallel
    parallel-implement.md                # /parallel-implement — Agent teams parallel TDD
    pr.md                                # /pr — Create pull request
    review.md                            # /review — 12-point quality review
    diagnose.md                          # /diagnose — Failure diagnosis + hotfix
    wrapup.md                            # /wrapup — Session completion ceremony
    create-prompt.md                     # /create-prompt — R.G.C.O.A. prompt builder
  hooks/
    sdlc-gate.sh                         # PreToolUse: blocks code without reqs/stories/branch
    branch-guard.sh                      # PreToolUse: blocks force-push and commits to main
    worktree-guard.sh                    # PreToolUse: confines teammates to their worktree
    lint-python.sh                       # PostToolUse: ruff + mypy after Python file edits
    lint-frontend.sh                     # PostToolUse: eslint + tsc after TS/TSX file edits
    teammate-idle.sh                     # TeammateIdle: rejects idle if CI fails
    teammate-completed.sh                # TaskCompleted: rejects completion if CI fails
  agents/
    test-writer.yaml                     # TDD Red phase: writes failing tests
    code-reviewer.yaml                   # 12-point quality checklist
    architect.yaml                       # ADRs, C4 diagrams, tech evaluation
  skills/
    api-design/SKILL.md                  # REST conventions, Pydantic schemas
    database-patterns/SKILL.md           # Repository pattern, migrations
    testing/SKILL.md                     # TDD workflow, fixtures, mocking, Playwright E2E
    deployment/SKILL.md                  # Docker, Azure App Service, rollback
    langgraph-agents/SKILL.md            # LangGraph ReAct agents, tools, state
    react-frontend/SKILL.md              # React 18 + TypeScript, streaming UI
    claude-agent-teams/SKILL.md          # Claude agent teams, tool_use, caching

.github/
  workflows/
    ci.yml                               # Lint + test on push/PR
    release.yml                          # Docker build on tag

scripts/
  validate-template.sh                   # Template validation (67 checks)
  test-agent-teams.sh                    # Agent teams validation (44 checks)
  test-test-artifacts.sh                 # Test artifact pipeline validation (49 checks)
```

## How the Enforcement Layers Work

The template uses a layered approach — each layer catches different issues at different times:

| Layer | What It Does | When It Runs |
|-------|-------------|--------------|
| **Starter Permissions** | Pre-approves safe commands (python, pytest, make, git, etc.) | Every tool call |
| **SDLC Gate Hook** | Blocks code writes without requirements, stories, or feature branch | Automatic, before Write/Edit |
| **Worktree Guard Hook** | Prevents teammates from writing outside their assigned worktree | Automatic, before Write/Edit |
| **Branch Guard Hook** | Blocks force-push and direct commits to main/master | Automatic, before Bash git commands |
| **Lint Python Hook** | Runs `ruff check --fix` + `mypy` after Python file edits | Automatic, after Write/Edit |
| **Lint Frontend Hook** | Runs `eslint --fix` + `tsc --noEmit` after TS/TSX file edits | Automatic, after Write/Edit |
| **Teammate Idle Hook** | Rejects idle if CI fails or uncommitted changes exist | Automatic, on TeammateIdle |
| **Teammate Completed Hook** | Runs `make ci` when a task is marked complete | Automatic, on TaskCompleted |
| **Rules** | BAD/GOOD examples for security, code style, error handling, testing, git, React | Auto-loaded by file path |
| **CLAUDE.md** | Standards, mode enforcement, dependency rules, Pre-Completion Checklists | Read every session |
| **Commands** | Slash commands for sequential and parallel SDLC workflows | Invoked by user |
| **Agents** | Specialized sub-agents (test-writer, code-reviewer, architect) | Called by commands |
| **Skills** | Domain knowledge (API design, DB patterns, deployment, etc.) | Referenced as needed |

### Precedence (when rules conflict)

1. Security rules (always win)
2. Error handling rules
3. Code style rules
4. Testing rules
5. Git workflow rules
6. Skill recommendations (advisory)

## Make Targets

```bash
make help               # Show all targets with descriptions
make build              # Install project + dev dependencies
make lint               # Run ruff + mypy
make format             # Auto-fix lint issues
make test-unit          # Run unit tests with coverage
make test-integration   # Run integration tests
make test-e2e           # Run end-to-end tests
make test               # Run unit + integration (default CI suite)
make ci                 # Full CI: lint + test (used by pre-commit hook)
make deploy-staging     # Deploy to Azure staging slot (configure first)
make deploy-production  # Swap staging to production
```

## Default Tech Stack

The template is pre-configured for this stack, but every part is customizable:

| Layer | Technologies |
|-------|-------------|
| Backend | Python 3.12 / FastAPI / SQLAlchemy |
| Frontend | React 18 / TypeScript / Tailwind |
| AI/Agents | LangGraph / LangChain / Claude Opus 4.6 |
| Infrastructure | Azure App Service / Azure Database for PostgreSQL |
| Testing | pytest, Playwright, Locust, Schemathesis |
| CI/CD | GitHub Actions |

## Context Management Tips

Claude Code's context window fills up during long sessions. Follow these practices:

- **Start/end ceremony**: `/gogogo` at start, `/wrapup` at end — clean handoffs between sessions
- **Clear between stories**: `/clear` after completing each story to reset context
- **Compact when needed**: `/compact` during long sessions to reclaim space while preserving key state
- **Delegate investigation**: Use sub-agents (test-writer, code-reviewer, architect) for codebase exploration — they don't pollute main context
- **Interview first**: For large features, `/interview` before `/decompose` to avoid requirements back-and-forth
- **Agent teams context**: Each teammate has its own context window — no shared state. The lead session coordinates via task lists, not shared memory

## Testing the Framework

Three test scripts validate different aspects of the framework. Run them all to verify your setup:

```bash
# Run all three test suites
./scripts/validate-template.sh       # 67 checks: core files, hooks, settings, gates
./scripts/test-agent-teams.sh        # 44 checks: worktree guard, hooks, settings, patterns
./scripts/test-test-artifacts.sh     # 49 checks: test plans, Playwright, pipeline wiring
```

## Reference

| Resource | Description |
|----------|-------------|
| `CLAUDE.md` | Code standards, commands, and Pre-Completion Checklists (Backend + Frontend) |
| `.claude/rules/` | Detailed BAD/GOOD examples for each rule category (6 files) |
| `.claude/skills/` | Domain knowledge documents with YAML frontmatter (7 skills) |
| [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code) | Official Claude Code documentation |
