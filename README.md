# Claude Code SDLC Scaffolding Templates

Production-ready Claude Code configuration that enforces consistent coding standards and a full SDLC workflow. Includes 9 slash commands, 5 enforcement rules (with OWASP security), 7 domain skills, 3 sub-agents, session ceremonies, starter permissions, and automated quality hooks.

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

This loads project context, checks git status, shows your backlog, and suggests what to work on next. **Always start here.**

### The Development Cycle

```
/interview                              # 1. Gather requirements (optional)
/decompose docs/requirements.md         # 2. Break into stories
/implement docs/backlog/<story>.md      # 3. TDD: Red -> Green -> Refactor
/pr                                     # 4. Run CI + create pull request
/review 42                              # 5. Review PR #42
/wrapup                                 # 6. Commit, push, handoff summary
```

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
CLAUDE.md                                # Code standards, precedence rules,
                                         # Pre-Completion Checklist (10 items)
pyproject.toml                           # Ruff, mypy, pytest config (pre-configured)
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
  settings.json                          # Hooks + starter permissions
  rules/
    security.md                          # Secrets, input validation, SQL injection
    code-style.md                        # Size limits, constants, type safety
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
    claude-agent-teams/SKILL.md          # Claude agent teams, tool_use, caching

.github/
  workflows/
    ci.yml                               # Lint + test on push/PR
    release.yml                          # Docker build on tag

claude-code-sdlc-framework-v2.md         # Framework theory and design rationale
```

## How the Enforcement Layers Work

The template uses a layered approach — each layer catches different issues at different times:

| Layer | What It Does | When It Runs |
|-------|-------------|--------------|
| **Starter Permissions** | Pre-approves safe commands (python, pytest, make, git, etc.) | Every tool call |
| **PostToolUse Hook** | Runs `ruff check --fix` + `mypy` after every file edit | Automatic, after Write/Edit |
| **PreCommit Hook** | Runs `make ci` (lint + all tests) before every git commit | Automatic, before commit |
| **Rules** | BAD/GOOD examples for security, code style, error handling, testing, git | Auto-loaded by file path |
| **CLAUDE.md** | Standards summary, Pre-Completion Checklist, precedence rules | Read every session |
| **Commands** | Slash commands for the full SDLC workflow | Invoked by user |
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

## Reference

| Resource | Description |
|----------|-------------|
| `CLAUDE.md` | Code standards, commands, and Pre-Completion Checklist |
| `.claude/rules/` | Detailed BAD/GOOD examples for each rule category |
| `.claude/skills/` | Domain knowledge documents with YAML frontmatter |
| `claude-code-sdlc-framework-v2.md` | Full framework theory and design rationale |
| [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code) | Official Claude Code documentation |
