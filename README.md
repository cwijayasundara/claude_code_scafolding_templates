# Claude Code SDLC Scaffolding

Claude Code configuration files that enforce consistent coding standards and SDLC workflow across the team. Includes 9 custom commands, 5 enforcement rules (with OWASP security), 7 domain skills, 3 sub-agents, session ceremonies (`/gogogo` + `/wrapup`), starter permissions, and a conflict resolution system.

Copy the `.claude/` directory, `CLAUDE.md`, and bootstrap files into any project to get started.

## Quick Start

```bash
# Copy into your existing project
cp CLAUDE.md pyproject.toml Makefile .env.example .gitignore /path/to/your-project/
cp -r .claude/ /path/to/your-project/.claude/
cp -r src/ tests/ /path/to/your-project/

# Or start a new project from this scaffolding
cp -r . my-new-project/
cd my-new-project/
make build  # Install dev dependencies
```

Then customize `CLAUDE.md` for your project (set project name, tech stack, commands).

## What's Included

```
CLAUDE.md                                # Code standards, precedence rules,
                                         # Pre-Completion Checklist (10 items)
pyproject.toml                           # Ruff, mypy, pytest config (pre-configured)
Makefile                                 # All build/test/deploy targets
.env.example                             # Environment variable template
.gitignore                               # Python, Node, IDE, OS ignores

src/                                     # Source code directory (stub)
  __init__.py
  __main__.py                            # Entry point stub

tests/                                   # Test directories with markers
  conftest.py                            # Shared fixtures
  unit/
  integration/
  e2e/

.claude/
  settings.json                          # Hooks + starter permissions (pre-approved
                                         # safe commands to reduce permission popups)
  rules/
    security.md                          # Secrets, input validation, SQL injection, auth
    code-style.md                        # Structure, size, constants, type safety
    error-handling.md                    # try/except, logging, specific exceptions
    testing.md                           # TDD, fixtures, coverage, mock rules
    git-workflow.md                      # Branch naming, conventional commits
  commands/
    gogogo.md                            # /gogogo — Session startup ceremony
    interview.md                         # /interview — Requirements gathering
    decompose.md                         # /decompose — Requirements -> stories
    implement.md                         # /implement — TDD Red-Green-Refactor
    pr.md                                # /pr — Create pull request
    review.md                            # /review — 10-point quality review
    diagnose.md                          # /diagnose — Failure diagnosis + hotfix
    wrapup.md                            # /wrapup — Session completion ceremony
    create-prompt.md                     # /create-prompt — R.G.C.O.A. prompt builder
  agents/
    test-writer.yaml                     # TDD Red phase: writes failing tests
    code-reviewer.yaml                   # 10-point quality checklist
    architect.yaml                       # ADRs, C4 diagrams, tech evaluation
  skills/
    api-design/SKILL.md                  # REST conventions, Pydantic schemas
    database-patterns/SKILL.md           # Repository pattern, migrations
    testing/SKILL.md                     # TDD workflow, fixtures, mocking
    deployment/SKILL.md                  # Docker, Azure App Service, rollback
    langgraph-agents/SKILL.md            # LangGraph ReAct agents, tools, state
    react-frontend/SKILL.md             # React 18 + TypeScript, streaming UI
    claude-agent-teams/SKILL.md          # Opus 4.6 agent teams, tool_use, caching

claude-code-sdlc-framework-v2.md         # Framework theory and design rationale
```

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Backend | Python 3.12 / FastAPI / SQLAlchemy |
| Frontend | React 18 / TypeScript / Tailwind |
| AI/Agents | LangGraph / LangChain / Claude Opus 4.6 |
| Infrastructure | Azure App Service / Azure Database for PostgreSQL |
| Testing | pytest, Playwright, Locust, Schemathesis |
| CI/CD | GitHub Actions |

## The SDLC Workflow

### 0. Start Session

```
/gogogo
```

Loads project context, checks git status, shows ready work from backlog, and suggests what to work on next.

### 1. Interview (Optional)

For features without a written spec:

```
/interview
```

Claude asks 5-8 structured questions and produces `docs/requirements.md`.

### 2. Decompose Requirements

```
/decompose docs/requirements.md
```

Generates user stories with acceptance criteria, a dependency graph, and implementation order.

### 3. Implement with TDD

For each story in dependency order:

```
/implement docs/backlog/<epic>/<story>.md
```

Runs the TDD cycle: RED (failing tests) -> GREEN (make them pass) -> REFACTOR (Pre-Completion Checklist).

### 4. Create PR

```
/pr
```

### 5. Review

```
/review <pr-number>
```

### 6. Wrap Up Session

```
/wrapup
```

Commits changes, runs CI, pushes to remote, and generates a handoff summary for the next session.

## Context Management

Claude Code's context window fills up fast, and performance degrades as it fills. Follow these practices to stay efficient:

### Session Lifecycle
- Start every session with `/gogogo` — loads context, shows backlog, suggests next action
- End every session with `/wrapup` — commits, pushes, provides handoff summary for the next session
- This ensures clean handoffs between sessions and no "cold start" confusion

### Between Stories
- Run `/clear` after completing each story to reset the context window
- This prevents stale context from one story affecting the next

### During Long Implementation
- Use `/compact` when you notice Claude's responses getting less focused
- Add compaction instructions to CLAUDE.md so Claude knows what to preserve:
  - Modified files list
  - Current story context and acceptance criteria
  - Test commands and any failing test output

### Subagents for Investigation
- Use subagents (test-writer, code-reviewer, architect) for codebase investigation
- Subagents run in their own context — they don't pollute the main conversation
- Good for: searching code patterns, reading multiple files, analyzing dependencies

### Interview Before Decompose
- For larger features, run `/interview` first to let Claude ask clarifying questions
- This produces a focused requirements summary before running `/decompose`
- Avoids wasting context on back-and-forth about requirements

## Enforcement Layers

| Layer | What | When |
|-------|------|------|
| **Starter Permissions** | Pre-approved safe commands (python, pytest, ruff, mypy, make, git, etc.) | Reduces permission popups |
| **Hooks** (automatic) | `ruff + mypy` after every file edit; `make ci` before every commit | Cannot be skipped |
| **CLAUDE.md** (advisory) | Standards summary, Pre-Completion Checklist, precedence rules, context management | Claude reads on every session |
| **Rules** (modular) | BAD/GOOD examples in `.claude/rules/` (security, code-style, error-handling, testing, git) | Auto-loaded per path |
| **Commands** (workflow) | `/gogogo` + `/wrapup` ceremonies; `/implement` TDD; `/review` quality; `/create-prompt` | Invoked per session/story |
| **Agents** (specialized) | test-writer, code-reviewer, architect | Called by commands |
| **Skills** (knowledge) | 7 domain skills with YAML frontmatter (API, DB, testing, deployment, LangGraph, React, Claude agents) | Referenced as needed |

## Rules Reference

Rules are auto-loaded based on file path and enforced in precedence order (highest first):

| Rule | Scope | What It Covers |
|------|-------|---------------|
| **security** | `src/**/*.py` | No secrets in code, input validation, SQL injection, auth, HTTPS, error responses, path safety |
| **code-style** | `**/*.py`, `**/*.ts`, `**/*.tsx` | Structure, size limits (30 lines/fn, 300 lines/file), constants, type safety, no duplication |
| **error-handling** | `src/**/*.py` | try/except for external calls, specific exceptions, logging, no print() |
| **testing** | `tests/**/*.py` | TDD workflow, shared fixtures, descriptive names, mock-at-boundaries, 80% coverage |
| **git-workflow** | all | Branch naming, conventional commits, squash merge, one story per branch |

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/gogogo` | Session startup — load context, check git, show backlog, suggest next action |
| `/interview` | Requirements gathering via structured questions |
| `/decompose` | Break requirements into epics, stories, dependency graph |
| `/implement` | TDD Red-Green-Refactor cycle for a story |
| `/pr` | Run CI, generate PR description, create PR |
| `/review` | Review a PR against 10-point quality checklist |
| `/diagnose` | Diagnose test failures and create hotfix |
| `/wrapup` | Session completion — commit, CI, push, handoff summary |
| `/create-prompt` | Build structured prompts using R.G.C.O.A. framework |

## Skills Reference

| Skill | What It Covers |
|-------|---------------|
| **api-design** | REST conventions, Pydantic schemas, RFC 7807 errors, pagination |
| **database-patterns** | Repository pattern, async SQLAlchemy, Alembic migrations, N+1 prevention |
| **testing** | TDD workflow, pytest fixtures, factory pattern, mock-at-boundaries |
| **deployment** | Docker multi-stage, Azure App Service, deployment slots, Key Vault, rollback |
| **langgraph-agents** | ReAct agents, StateGraph, tool factories, checkpointing, multi-agent handoffs, deep agents |
| **react-frontend** | React 18 + TypeScript, component patterns, streaming UI for agents, TanStack Query, Tailwind |
| **claude-agent-teams** | Opus 4.6 tool_use, extended thinking, prompt caching, multi-model orchestration, agent SDK |

## Customization

### CLAUDE.md

Edit the following sections for your project:
- **Project name and tech stack** at the top
- **Commands section** — update `make` targets to match your build system
- **Code Standards** — adjust rules to your team's preferences (line length, coverage threshold, etc.)

### pyproject.toml

Pre-configured with:
- `ruff` (linting + formatting, line-length 100)
- `mypy` (strict mode)
- `pytest` (markers for unit/integration/e2e/smoke/perf, 80% coverage threshold)

### .claude/settings.json

Includes two sections:

**Starter permissions** — Pre-approved commands that won't trigger permission prompts during normal development (python, pytest, ruff, mypy, make, git, gh, node, npm, docker, az, mkdir, ls). Add or remove commands to match your stack.

**Hooks** — The hooks assume your project has:
- `ruff` and `mypy` installed (for PostToolUse lint hook)
- A `make ci` target (for PreCommit hook)

Update the hook commands if your project uses different tools:

```json
{
  "permissions": {
    "allow": [
      "Bash(python3 *)",
      "Bash(pytest *)",
      "Bash(make *)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "command": "your-lint-command $FILE",
        "description": "Lint and type-check after every edit"
      }
    ],
    "PreCommit": [
      {
        "command": "your-ci-command",
        "description": "Full CI validation before any commit"
      }
    ]
  }
}
```

### Skills

Skills contain domain knowledge. Keep the ones relevant to your stack, remove the rest, or add new ones by creating `.claude/skills/<name>/SKILL.md`. All skills have YAML frontmatter with `name` and `description` for auto-discovery.

## Reference

See `claude-code-sdlc-framework-v2.md` for the full framework theory and design rationale behind the enforcement layers, commands, agents, and skills.
