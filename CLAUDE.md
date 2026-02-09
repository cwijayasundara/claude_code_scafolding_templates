# Project: [Your Project Name]

## MANDATORY SDLC Workflow (MUST follow — NO exceptions)

**BLOCKING REQUIREMENT**: You MUST follow this workflow for ALL implementation tasks. You are FORBIDDEN from writing production code or tests without completing the prior steps. If a user says "implement X" or "build Y" or gives you a plan, you MUST still follow this workflow — do NOT skip steps.

### SDLC Mode: Full vs Lite

Controlled by `SDLC_MODE` in `.claude/settings.json` → `env` block. Default: `"full"`.

| Aspect | Full (default) | Lite |
|--------|---------------|------|
| Requirements | >= 10 lines, 2 sections | >= 5 lines, 1 section |
| Stories | >= 8 lines + Dependencies | >= 4 lines + Acceptance Criteria only |
| Coverage | 80% | 60% |
| Architecture/ADRs | Required | Skipped |
| Test plans | Required | Skipped (test-writer works from acceptance criteria) |
| Dependency graph | Required | Skipped |
| Parallel batches | Required | Skipped |
| E2E Playwright | Mandatory for frontend | Optional |
| Parallel implementation | Enforced (agent teams) | Sequential only |

**Always enforced in both modes**: feature branches, conventional commits, TDD Red-Green-Refactor, CI must pass, dependency checking (when Dependencies section exists).

To switch modes: edit `.claude/settings.json` → `env.SDLC_MODE` to `"full"` or `"lite"`.

### Workflow Summary Checklist

When summarizing or explaining this workflow, include ALL of these steps — do NOT collapse or omit any:

1. **`/gogogo`** — Session startup: load context, check git status, show ready work
2. **`/spike`** _(optional)_ — Time-boxed exploration for technical questions before committing to a direction
3. **`/interview`** — Gather structured requirements → `docs/requirements.md`
4. **`/decompose`** — Break requirements into epics, stories, and dependency graph → `docs/backlog/`
5. **Architecture** _(full mode only)_ — Generate C4 diagrams (`docs/architecture.md`) and ADRs (`docs/adr/`) for key technical decisions
6. **`/test-plan`** _(full mode only)_ — Generate test plans per story with test cases, test data, and E2E scenarios → `docs/test-plans/`
7. **`/implement`** or **`/parallel-implement`** — TDD per story: RED (failing tests + test data + E2E scripts) → GREEN (minimum code) → REFACTOR (clean up + validate test artifacts)
8. **`/pr`** — Run CI, generate PR description, create pull request
9. **`/review`** — Self-review against 12-point quality checklist + performance review
10. **`/wrapup`** — Commit, push, and generate handoff summary

**Key outputs that MUST exist before implementation begins:**
- `docs/requirements.md` — structured requirements (**full**: >= 10 lines, 2 sections; **lite**: >= 5 lines, 1 section)
- `docs/architecture.md` — C4 system/container/component diagrams _(full mode only)_
- `docs/adr/` — Architecture Decision Records for key technical choices _(full mode only)_
- `docs/backlog/` — story files (**full**: with acceptance criteria, dependencies, and asset dependencies; **lite**: acceptance criteria only)
- `docs/backlog/parallel-batches.md` — wave-based topological sort for parallel execution _(full mode only)_
- `docs/test-plans/` — test plans per story with unit, integration, and E2E test cases _(full mode only)_

**Key test artifacts that MUST be generated during implementation (enforced by `/implement`):**
- `tests/unit/` — unit test scripts for every new function/method
- `tests/integration/` — integration tests for API endpoints and service boundaries
- `tests/e2e/` — Playwright E2E test scripts (MANDATORY for `frontend`/`fullstack` stories, not just an empty directory)
- `tests/conftest.py` — shared fixtures, no duplicated setup across files
- `tests/factories.py` or `tests/factories/` — factory-boy factories listed in the test plan
- `tests/fixtures/` — seed data for integration/E2E tests listed in the test plan
- **Traceability**: every acceptance criterion maps to at least one passing test

### Phase 0: Session Start & Brainstorming
- Run `/gogogo` at the start of every session
- Brainstorming, discussing ideas, exploring architecture, and asking questions is ALWAYS welcome
- **CRITICAL TRANSITION RULE**: When the conversation shifts from "exploring ideas" to "let's build this":
  → Route through `/interview` to capture brainstorming output as structured requirements
  → NEVER jump from brainstorming directly to writing code
  → NEVER create stub documents to bypass gates — hooks validate content, not just existence
- **Spike mode**: For time-boxed technical exploration (evaluate a library, prototype an approach), use `/spike` instead of the full SDLC. Spike branches (`spike/*`) bypass SDLC gates but CANNOT be merged or PR'd — findings must be converted to stories via `/interview`.
- If no backlog exists, tell the user: "Let's capture these ideas. Run `/interview` to turn them into requirements."

### Phase 1: Requirements (MUST complete before Phase 2)
- Run `/interview` to gather structured requirements
- Output: `docs/requirements.md`
- **GATE**: Do NOT proceed to Phase 2 without a requirements document
- **CONTENT GATE**: **Full**: `docs/requirements.md` must have >= 10 lines and at least 2 of these sections: `## Problem Statement`, `## Functional Requirements`, `## Target Users`, `## Non-Functional Requirements`. **Lite**: >= 5 lines and at least 1 section.

### Phase 2: Decomposition & Architecture (MUST complete before Phase 3)
- Run `/decompose docs/requirements.md` to break into epics and stories
- Output: `docs/backlog/` with story files, `docs/backlog/dependency-graph.mmd` _(full mode only)_
- Output: `docs/test-plans/` with test plans per story (generated by `/test-plan`) _(full mode only)_
- Generate `docs/architecture.md` (C4 diagrams) _(full mode only)_
- Generate ADRs in `docs/adr/` for key technical decisions _(full mode only)_
- **GATE**: Do NOT proceed to Phase 3 without stories in `docs/backlog/`
- **CONTENT GATE**: **Full**: each story must have >= 8 lines and include `## User Story` or `## Acceptance Criteria` + `## Dependencies` headings. **Lite**: each story must have >= 4 lines and include `## User Story` or `## Acceptance Criteria` (Dependencies not required).
- **ASSET GATE**: If any story has an `## Asset Dependencies` section with `missing` items, that story is **Blocked** until assets are provided. `/implement` checks this before starting.

### Phase 3: Implementation

**Implementation Mode** depends on `SDLC_MODE` and `AGENT_TEAMS_ENFORCE` in `.claude/settings.json`:
- **Lite mode**: Always sequential — one story at a time via `/implement`
- **Full mode** with `AGENT_TEAMS_ENFORCE=true` (default) → **Agent Teams mode**: parallel implementation via `/parallel-implement` for waves with 2+ independent stories
- **Full mode** with `AGENT_TEAMS_ENFORCE=false` → **Sequential mode**: one story at a time via `/implement`

#### Agent Teams Mode (default — `AGENT_TEAMS_ENFORCE=true`)
- **MANDATORY**: When a wave in `docs/backlog/parallel-batches.md` has 2+ Ready stories, you MUST use `/parallel-implement wave-N` (not sequential `/implement`)
- Single-story waves still use `/implement` (no benefit to parallelization)
- Process waves in order: Wave 1 must complete before Wave 2 starts
- Within each wave, ALL independent stories run in parallel via agent teammates
- **DEPENDENCY RULE**: Stories with `depends_on` relationships NEVER run in the same wave — the topological sort guarantees this, but verify before spawning teammates
- **GATE**: ALL stories in a wave must pass CI before the next wave starts
- If agent teams fail, fall back to `/parallel-manual` for that wave, then `/implement` as last resort

#### Sequential Mode (fallback — `AGENT_TEAMS_ENFORCE=false`)
- Pick the next ready story from `docs/backlog/implementation-order.md`
- Create feature branch: `git checkout -b feature/STORY-XXX-short-description`
- Run `/implement docs/backlog/[epic]/[story-id].md` which enforces:
  1. **RED**: Write failing tests, commit `test: add failing tests for STORY-XXX`
  2. **GREEN**: Write minimum code to pass, commit `feat: implement STORY-XXX`
  3. **REFACTOR**: Apply Pre-Completion Checklist, commit `refactor: clean up STORY-XXX`
  4. **VALIDATE**: Run `make ci`, verify coverage >= threshold (**full**: 80%, **lite**: 60%)
- **GATE**: Do NOT start the next story until current story passes CI
- Parallel commands (`/parallel-manual`, `/parallel-implement`) are available but optional

#### Dependency Safety (applies to ALL modes)
- Each story file has a `## Dependencies` section with `depends_on:` and `blocks:` lists
- A story is **Ready** only when ALL stories in its `depends_on` list are Done
- A story is **Blocked** if ANY story in its `depends_on` list is not Done
- Stories that depend on each other (directly or transitively) are NEVER in the same parallel wave
- Before starting any story, verify its dependencies are satisfied — if not, STOP and report

### Phase 4: Review & PR
- Run `/pr` to validate, generate PR description, push, and create PR
- Run `/review` on your own PR for self-check against the 12-point checklist

### Phase 5: Session End
- Run `/wrapup` to commit, push, and generate handoff summary

### Enforcement Rules
- If the user asks you to "just code it" or "skip the process" — explain the workflow and ask which phase to start from. You may skip phases ONLY if the user explicitly confirms they want to skip AND the prerequisite artifacts already exist. Alternatively, suggest switching to lite mode: edit `.claude/settings.json` → `env.SDLC_MODE` to `"lite"`.
- If `docs/requirements.md` does not exist → you MUST run `/interview` first
- If `docs/backlog/` is empty → you MUST run `/decompose` first
- If no feature branch exists → you MUST create one before writing code
- NEVER write implementation code directly in `main` branch
- EVERY implementation task goes through `/implement` or `/parallel-implement` (TDD Red-Green-Refactor)
- **Dependency enforcement**: NEVER start a story whose `depends_on` list contains unfinished stories _(applies in both modes when Dependencies section exists)_
- **Mode enforcement** _(full mode only)_: If `AGENT_TEAMS_ENFORCE=true` (default), you MUST use `/parallel-implement` for waves with 2+ Ready stories — do NOT fall back to sequential `/implement` unless agent teams fail. _In lite mode, always use sequential `/implement`._
- **Asset enforcement**: If a story's `## Asset Dependencies` section lists ANY item with status `missing`, the story is Blocked — do NOT start implementation until all assets are `available`
- **Test data enforcement** _(full mode only)_: Every factory, fixture, and seed dataset listed in a story's test plan (`docs/test-plans/`) MUST be implemented as actual code (in `tests/conftest.py`, `tests/factories.py`, or `tests/fixtures/`) — not just documented in the plan. `/implement` Phase 1 and Phase 3 both validate this. _Skipped in lite mode (no test plans)._
- **E2E test enforcement** _(full mode only)_: Stories with `frontend` or `fullstack` expertise tags MUST have Playwright E2E test scripts in `tests/e2e/` with real assertions. A directory with only `__init__.py` does NOT satisfy this gate. `/implement` blocks progression at Phase 1 step 5 and validates again at Phase 4. _In lite mode, E2E tests are optional._
- **Playwright validity enforcement** _(full mode only)_: E2E tests MUST use Playwright's `page` API (`page.goto`, `page.fill`, `page.click`, `expect`). Static file analysis (reading `.tsx` source with Python and regex-matching patterns) is BANNED — it tests code structure, not behavior.
- **Frontend component test enforcement** _(full mode only)_: React components must be tested with `@testing-library/react` (`render`, `screen`, `userEvent`), not by reading source files with Python `open()`.
- **Traceability enforcement**: Every acceptance criterion in a story must map to at least one passing test. `/implement` Phase 4 validates this before allowing `/pr`.

### Anti-Bypass Rules (Hook-Enforced)
- **No stub documents**: `sdlc-gate.sh` validates content, not just file existence. Thresholds are mode-dependent: **full**: requirements >= 10 lines + 2 sections, stories >= 8 lines + required sections. **Lite**: requirements >= 5 lines + 1 section, stories >= 4 lines + Acceptance Criteria.
- **No Bash redirect bypass**: `bash-file-guard.sh` blocks `echo/printf/cat` redirects targeting `docs/requirements.md`, `docs/backlog/`, `docs/test-plans/`, and code files (.py/.ts/.tsx/.js/.jsx).
- **Expanded file coverage**: SDLC gates apply to ALL code files (.py/.ts/.tsx/.js/.jsx), not just `src/` and `tests/`. Exempt paths: `docs/`, `.claude/`, `.github/`, `scripts/`, config files.
- **Conditional `__init__.py`**: Allowed in `tests/` always. In `src/`, only allowed if <= 5 lines (package marker). Larger `__init__.py` must pass all SDLC gates.
- **Test plan required for src/** _(full mode only)_: Writing to `src/` requires a test plan in `docs/test-plans/STORY-XXX-*` (derived from branch name). Writing to `tests/` is allowed without a test plan (RED phase = test-first). _Skipped in lite mode._
- **Spike branch isolation**: `spike/*` branches bypass SDLC gates for free exploration, but `branch-guard.sh` blocks `git merge spike/*` and `gh pr create` on spike branches. Spike code NEVER reaches main — convert findings to stories via `/interview`.

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
- **`.claude/rules/security.md`** — Secrets, input validation, SQL injection, auth, HTTPS, frontend fetch timeouts
- **`.claude/rules/code-style.md`** — Structure, size limits, constants, type safety, no duplication, no dead code
- **`.claude/rules/error-handling.md`** — try/except, try/catch, logging, specific exceptions (Python + TypeScript)
- **`.claude/rules/testing.md`** — TDD, fixtures, coverage, mock-at-boundaries, helper function tests
- **`.claude/rules/react-patterns.md`** — React keys, useEffect cleanup, empty catch blocks, fetch timeouts, no `any`
- **`.claude/rules/git-workflow.md`** — Branching, conventional commits, squash merge

### Quick Reference (MUST)
- Max function: 50 lines. Max file: 500 lines. Single responsibility
- No magic numbers/strings — extract to UPPER_SNAKE_CASE constants
- No code duplication — extract helpers/fixtures
- No dead code — no unused imports, no commented-out code, no empty stubs
- Every external call wrapped in try/except (Python) or try/catch (TypeScript)
- No empty catch blocks — every catch MUST log AND handle the error
- Every fetch() MUST have a timeout (AbortSignal.timeout or AbortController)
- Every Python module: `logger = logging.getLogger(__name__)`. No `print()` for operations
- Full type hints (Python) / strict TypeScript. No `Any` or `any` types
- React: no array-index keys, useEffect MUST return cleanup for subscriptions/timers
- TDD: tests BEFORE implementation. Min coverage: **full** 80%, **lite** 60%
- All helper functions in utils/helpers/ MUST have dedicated unit tests

## Pre-Completion Checklist — Backend (Python)
MUST verify before finishing ANY Python file:
1. Are there magic numbers or string literals? -> Extract to named constants
2. Is there duplicated code (same pattern in 2+ places)? -> Extract to helper/fixture
3. Does every external call have error handling (try/except)? -> Add it
4. Does the module have `logger = logging.getLogger(__name__)`? -> Add it
5. Are all return types specific (no `Any`)? -> Use concrete types
6. Is any function > 50 lines? -> Split it
7. Does the function do more than one thing? -> Split it (SRP)
8. Is `print()` used for operational output? -> Replace with `logger.info()`
9. If tests: is setup duplicated across files? -> Extract to conftest.py
10. Are error messages actionable? -> Tell the user what to do, not just what failed
11. Is there dead code (unused imports, commented-out code, empty stubs)? -> Delete it
12. Do all helper functions in utils/helpers/ have dedicated unit tests? -> Add them

## Pre-Completion Checklist — Frontend (TypeScript/React)
MUST verify before finishing ANY TypeScript/React file:
1. Are there magic numbers or string literals? -> Extract to named constants
2. Is there duplicated code (same pattern in 2+ places)? -> Extract to utils/ or shared component
3. Does every fetch() have a timeout? -> Add `AbortSignal.timeout(DEFAULT_FETCH_TIMEOUT_MS)`
4. Is every fetch/SDK call in a try/catch? -> Add error handling
5. Are there empty catch blocks? -> Add logging (`console.error`) AND error state handling
6. Are all types specific (no `any`)? -> Use `unknown` with type guards
7. Is any function > 50 lines? -> Split it
8. Are array indices used as React keys? -> Use stable unique IDs
9. Does every useEffect with subscriptions/timers return a cleanup function? -> Add cleanup
10. Is there dead code (unused imports, commented-out code, unused props/state)? -> Delete it
11. Do all helper functions in utils/helpers/hooks have dedicated unit tests? -> Add them
12. Is user-supplied content rendered safely? -> Use DOMPurify or React auto-escaping

## Agent Teams (Parallel Implementation)

**Four settings control SDLC and agent teams behavior (all in `.claude/settings.json` → `env` block):**

| Setting | Default | Purpose |
|---------|---------|---------|
| `SDLC_MODE` | `"full"` | `"full"` = all artifacts required; `"lite"` = fast-track pipeline |
| `AGENT_TEAMS_ENABLED` | `"true"` | Unlocks `/parallel-implement` command _(full mode only)_ |
| `AGENT_TEAMS_ENFORCE` | `"true"` | When `"true"`, FORCES parallel implementation for multi-story waves _(full mode only)_ |
| `AGENT_TEAMS_MAX_TEAMMATES` | `"3"` | Max concurrent teammates per wave |

**Also requires:** environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

**Enabling modes:**
- **Parallel enforced** (default): both `ENABLED` and `ENFORCE` are `"true"` — Claude MUST use `/parallel-implement` for waves with 2+ independent stories
- **Parallel available**: set `ENFORCE=false` — `/parallel-implement` is available but optional
- **Sequential only**: set both `ENABLED` and `ENFORCE` to `"false"` — only `/implement` is used

**Cost considerations:**
- Each teammate uses ~7x the tokens of a single `/implement` run
- Stable alternative: `/parallel-manual` uses standard worktrees at 1x cost per terminal
- Use `/parallel-implement` only when time savings justify the token cost

**How it works (native Claude Code agent teams):**
- `/decompose` generates `docs/backlog/parallel-batches.md` with wave-based topological sort
- Each story file has a `## Dependencies` section with explicit `depends_on:` and `blocks:` lists
- Stories with dependencies are placed in later waves — they NEVER run in parallel with their dependencies
- `/parallel-implement wave-N` creates a native agent team:
  - The lead session (you) coordinates in **delegate mode** — it does NOT write code
  - One **teammate** is spawned per independent story, each in its own git worktree
  - Teammates require **plan approval** from the lead before implementing
  - Teammates communicate via the **shared task list** and **mailbox messaging**
- **Quality hooks** fire automatically:
  - `TeammateIdle` → `teammate-idle.sh`: rejects idle if CI fails or uncommitted changes exist
  - `TaskCompleted` → `teammate-completed.sh`: rejects task completion if `make ci` fails
  - `PreToolUse` → `worktree-guard.sh`: prevents teammates from writing outside their worktree

## Context Management
- Run `/clear` between stories to reset context window
- Use `/compact` when context grows large — preserves key state while reclaiming space
- When compacting, preserve: list of modified files, current story context, test commands, and any failing test output
- Use subagents for codebase investigation to avoid polluting main context
- Each agent teammate has its own context window — no shared state between teammates

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
- `/gogogo` — Session startup: load context, check git status, show ready work and parallel options
- `/interview` — Requirements gathering via structured interview before decomposition
- `/decompose <requirements-doc>` — Break requirements into epics, stories, dependency graph, parallel batches
- `/test-plan <story-file>` — Generate test plan with test cases, test data, and E2E scenarios from story
- `/implement <story-file>` — TDD Red->Green->Refactor cycle for a story (sequential)
- `/parallel-manual <wave|stories>` — Set up git worktrees for manual parallel implementation (stable)
- `/parallel-implement <wave|stories>` — Agent teams parallel implementation (default for multi-story waves)
- `/pr` — Run CI, generate PR description, create PR
- `/review <pr-number>` — Review a PR against 12-point checklist
- `/diagnose <failure-report>` — Diagnose test failures and create hotfix
- `/wrapup` — Session completion: commit, CI, push, handoff summary
- `/spike <description>` — Time-boxed exploration: creates `spike/*` branch, suspends SDLC gates, blocks merge/PR
- `/create-prompt` — Build a structured prompt using R.G.C.O.A. framework

## Sub-Agents
- **test-writer** — TDD Red phase: writes failing tests from acceptance criteria
- **code-reviewer** — 12-point quality review checklist (SOLID, duplication, error handling, security, dead code, React anti-patterns, helper tests)
- **performance-reviewer** — 10-point performance checklist (N+1 queries, missing indexes, unbounded collections, memory leaks, bundle size, re-renders, pagination, connection pools)
- **architect** — ADRs, C4 diagrams, tech evaluation

## Skills
- **api-design** — REST conventions, Pydantic schemas, error format, pagination
- **database-patterns** — Repository pattern, async sessions, migrations, N+1 prevention
- **testing** — TDD workflow, fixtures, factory pattern, mock-at-boundaries, Playwright E2E, frontend testing
- **deployment** — Docker multi-stage, Azure App Service, deployment slots, Key Vault, rollback
- **langgraph-agents** — ReAct agents, StateGraph, tool factories, checkpointing, multi-agent handoffs
- **react-frontend** — React 18 + TypeScript components, streaming UI, state management, Tailwind
- **claude-agent-teams** — Opus 4.6 agent teams, tool_use, extended thinking, prompt caching, multi-model orchestration
