# Project: [Your Project Name]

## Tech Stack
- Backend: Python 3.12 / FastAPI / SQLAlchemy
- Frontend: React 18 / TypeScript / Tailwind
- AI/Agents: LangGraph / LangChain / Claude Opus 4.6
- Infrastructure: Azure App Service / Azure Database for PostgreSQL
- Testing: pytest (unit/integration), Playwright (E2E), Locust (perf), Schemathesis (contract)
- CI/CD: GitHub Actions

## Architecture
- Generate @docs/architecture.md for C4 diagrams (use `/decompose` workflow)
- Generate @docs/adr/ for Architecture Decision Records
- Generate @docs/api/openapi.yaml for API contracts (if applicable)

## Precedence (Conflict Resolution)

When rules, skills, or instructions conflict, follow this priority (highest first):

1. **Security rules** (`.claude/rules/security.md`) — always wins
2. **Error handling rules** (`.claude/rules/error-handling.md`) — safety over style
3. **Code style rules** (`.claude/rules/code-style.md`) — consistency over preference
4. **Testing rules** (`.claude/rules/testing.md`) — quality enforcement
5. **Git workflow rules** (`.claude/rules/git-workflow.md`) — process standards
6. **Skill recommendations** (`.claude/skills/`) — advisory, can be overridden by rules above

Example: if a skill suggests a code pattern that violates a security rule, the security rule wins.

## Code Standards

Detailed rules with BAD/GOOD examples are in `.claude/rules/`:
- **`.claude/rules/security.md`** — Secrets, input validation, SQL injection, auth, HTTPS
- **`.claude/rules/code-style.md`** — Structure, size limits, constants, type safety, no duplication
- **`.claude/rules/error-handling.md`** — try/except, logging, specific exceptions
- **`.claude/rules/testing.md`** — TDD, fixtures, coverage, mock-at-boundaries
- **`.claude/rules/git-workflow.md`** — Branching, conventional commits, squash merge

### Quick Reference (MUST)
- Max function: 30 lines. Max file: 300 lines. Single responsibility
- No magic numbers/strings — extract to UPPER_SNAKE_CASE constants
- No code duplication — extract helpers/fixtures
- Every external call wrapped in try/except with specific exceptions
- Every module: `logger = logging.getLogger(__name__)`. No `print()` for operations
- Full type hints. No `Any` return types
- TDD: tests BEFORE implementation. Min 80% coverage

## Pre-Completion Checklist (MUST verify before finishing ANY file)
1. Are there magic numbers or string literals? -> Extract to named constants
2. Is there duplicated code (same pattern in 2+ places)? -> Extract to helper/fixture
3. Does every external call have error handling (try/except)? -> Add it
4. Does the module have `logger = logging.getLogger(__name__)`? -> Add it
5. Are all return types specific (no `Any`)? -> Use concrete types
6. Is any function > 30 lines? -> Split it
7. Does the function do more than one thing? -> Split it (SRP)
8. Is `print()` used for operational output? -> Replace with `logger.info()`
9. If tests: is setup duplicated across files? -> Extract to conftest.py
10. Are error messages actionable? -> Tell the user what to do, not just what failed

## Context Management
- Run `/clear` between stories to reset context window
- Use `/compact` when context grows large — preserves key state while reclaiming space
- When compacting, preserve: list of modified files, current story context, test commands, and any failing test output
- Use subagents for codebase investigation to avoid polluting main context

## Commands
- Build: `make build`
- Unit tests: `make test-unit`
- Integration tests: `make test-integration`
- E2E tests: `make test-e2e`
- Smoke tests: `make test-smoke`
- All tests: `make test`
- Lint + typecheck: `make lint`
- Full CI: `make ci`
- Deploy staging: `make deploy-staging`
- Deploy production: `make deploy-production`

## Custom Commands
- `/gogogo` — Session startup: load context, check git status, show ready work
- `/interview` — Requirements gathering via structured interview before decomposition
- `/decompose <requirements-doc>` — Break requirements into epics, stories, dependency graph
- `/implement <story-file>` — TDD Red->Green->Refactor cycle for a story
- `/pr` — Run CI, generate PR description, create PR
- `/review <pr-number>` — Review a PR against 10-point checklist
- `/diagnose <failure-report>` — Diagnose test failures and create hotfix
- `/wrapup` — Session completion: commit, CI, push, handoff summary
- `/create-prompt` — Build a structured prompt using R.G.C.O.A. framework

## Sub-Agents
- **test-writer** — TDD Red phase: writes failing tests from acceptance criteria
- **code-reviewer** — 10-point quality review checklist
- **architect** — ADRs, C4 diagrams, tech evaluation

## Skills
- **api-design** — REST conventions, Pydantic schemas, error format, pagination
- **database-patterns** — Repository pattern, async sessions, migrations, N+1 prevention
- **testing** — TDD workflow, fixtures, factory pattern, mock-at-boundaries
- **deployment** — Docker multi-stage, Azure App Service, deployment slots, Key Vault, rollback
- **langgraph-agents** — ReAct agents, StateGraph, tool factories, checkpointing, multi-agent handoffs
- **react-frontend** — React 18 + TypeScript components, streaming UI, state management, Tailwind
- **claude-agent-teams** — Opus 4.6 agent teams, tool_use, extended thinking, prompt caching, multi-model orchestration
