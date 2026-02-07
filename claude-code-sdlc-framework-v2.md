# Claude Code Across the Entire SDLC
## A Comprehensive Framework for Engineering Teams

---

## Executive Summary

This framework covers the complete lifecycle of using Claude Code — from session startup through post-deployment validation — with specific attention to areas often overlooked:

1. **Session continuity**: `/gogogo` and `/wrapup` ceremonies prevent cold starts and ensure clean handoffs between sessions.
2. **Security-first rules**: OWASP-aware security rules with explicit precedence (Security > Error handling > Code style > Skills).
3. **Team orchestration**: How to assign stories to multiple engineers, each with their own Claude Code instance, working in parallel without chaos.
4. **Post-deployment testing**: Running automated test suites against the deployed application as the final CI/CD gate.
5. **Feedback loops**: What happens when tests fail at any stage — the retry and remediation cycles that keep the pipeline self-healing.

The scaffolding includes **9 commands**, **5 rules**, **7 skills**, **3 sub-agents**, **starter permissions**, and **bootstrap files** — all designed to work together. The approach is grounded in **Spec-Driven Development**, where human intent flows through structured specifications that Claude Code executes deterministically. The goal is 3–10x velocity improvement while maintaining architectural control.

---

## The Holistic Picture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  SESSION START: /gogogo                                                  │
│  → Load project context, check git, show backlog, suggest next action   │
└────────────────────────────────┬────────────────────────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    HUMAN: Requirements Input                             │
│              (PRDs, meeting notes, business cases)                        │
└────────────────────────────────┬────────────────────────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: DECOMPOSITION                                                  │
│  Claude Code: Requirements → Epics → Stories → Acceptance Criteria       │
│  Claude Code: Push to Jira/ADO/Linear                                    │
│  Claude Code: Generate dependency graph + implementation order           │
│  Output: Ordered backlog with story dependencies mapped                  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 ▼
┌──────────────────────────────────┬──────────────────────────────────────┐
│  PHASE 2: TEST PLANNING          │  PHASE 3: ARCHITECTURE & DESIGN      │
│  → Test strategy per story       │  → C4 diagrams (context/container)   │
│  → Test case specifications      │  → OpenAPI contracts (source of      │
│  → Test data + fixtures          │    truth)                            │
│  → E2E scenario scripts          │  → Data model / ERD                  │
│  (runs in parallel with Phase 3) │  → ADRs for key decisions            │
└──────────────────────────────────┴─────────────────┬────────────────────┘
                                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 4: STORY ASSIGNMENT & TEAM ORCHESTRATION                          │
│                                                                          │
│  Tech Lead / Engineering Manager:                                        │
│    • Reviews dependency graph + implementation order                      │
│    • Assigns stories to engineers based on expertise + independence       │
│    • Each engineer gets their own git worktree + Claude Code instance     │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │ Engineer A    │  │ Engineer B    │  │ Engineer C    │                   │
│  │ Worktree: A   │  │ Worktree: B   │  │ Worktree: C   │                   │
│  │ Stories:      │  │ Stories:      │  │ Stories:      │                   │
│  │  101 (auth)   │  │  104 (catalog)│  │  107 (payment)│                   │
│  │  102 (roles)  │  │  105 (search) │  │  108 (checkout│                   │
│  │  103 (session)│  │  106 (filter) │  │  109 (receipt)│                   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                   │
│         ▼                 ▼                 ▼                            │
│     TDD Cycle          TDD Cycle         TDD Cycle                       │
│  Red→Green→Refactor  Red→Green→Refactor Red→Green→Refactor               │
└─────────────────────────────┬───────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 5: PR + CODE REVIEW                                               │
│                                                                          │
│  Per story:                                                              │
│    1. Claude Code creates PR (auto-generated description)                │
│    2. Claude GitHub Action auto-reviews (quality, security, standards)   │
│    3. Peer engineer reviews (human approval required)                    │
│    4. If feedback → Claude Code fixes → re-review                        │
│    5. Squash merge to main                                               │
│                                                                          │
│  ┌──────────────────── FEEDBACK LOOP ─────────────────────┐              │
│  │  Review comments → Claude fixes → Tests pass → Re-review│              │
│  │  Repeat until approved                                  │              │
│  └─────────────────────────────────────────────────────────┘              │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 6: CI/CD PIPELINE                                                 │
│                                                                          │
│  On merge to main:                                                       │
│    ┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────┐      │
│    │  BUILD   │ →  │  UNIT     │ →  │  INTEG   │ →  │  SECURITY    │      │
│    │         │    │  TESTS   │    │  TESTS   │    │  SCAN        │      │
│    └────┬────┘    └────┬─────┘    └────┬─────┘    └──────┬───────┘      │
│         │              │              │                   │              │
│         │    ┌─────────┘    ┌────────┘         ┌────────┘              │
│         ▼    ▼              ▼                   ▼                        │
│    ┌──────────────────────────────────────────────────┐                  │
│    │           ANY FAILURE → STOP + NOTIFY             │                  │
│    │     Claude Code diagnoses + fixes + re-runs       │                  │
│    └──────────────────────────────────────────────────┘                  │
│                                                                          │
│    All pass → Deploy to STAGING                                          │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 7: POST-DEPLOYMENT TESTING (on STAGING)                           │
│                                                                          │
│    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐        │
│    │  SMOKE   │ →  │  E2E     │ →  │  PERF    │ →  │  CONTRACT│        │
│    │  TESTS   │    │  TESTS   │    │  TESTS   │    │  TESTS   │        │
│    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘        │
│         │              │              │              │                   │
│         ▼              ▼              ▼              ▼                   │
│    ┌───────────────────────────────────────────────────────┐             │
│    │  ALL PASS → Human gate → Promote to PRODUCTION        │             │
│    │  ANY FAIL → Claude Code diagnoses, fixes, re-deploys  │             │
│    └───────────────────────────────────────────────────────┘             │
│                                                                          │
│    On PRODUCTION:                                                        │
│    → Smoke tests (health checks, critical paths)                         │
│    → Synthetic monitoring (continuous canary tests)                       │
│    → If failure → Auto-rollback + incident workflow                      │
└────────────────────────────────┬────────────────────────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  SESSION END: /wrapup                                                    │
│  → Commit changes, run CI, push to remote, generate handoff summary     │
│  → Next session: /gogogo picks up from handoff                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Foundation: The CLAUDE.md Constitution

Before any SDLC activity, set up the project's `CLAUDE.md` at the repo root. This is Claude Code's persistent context — read at every session start.

### 1.1 Core CLAUDE.md Template

Keep it under 300 lines. Use progressive disclosure — reference detailed docs by path rather than embedding them.

```markdown
# Project: [Name]

## Tech Stack
- Backend: Python 3.12 / FastAPI / SQLAlchemy
- Frontend: React 18 / TypeScript / Tailwind
- Infrastructure: Azure App Service / Azure Blob Storage
- Testing: pytest (unit/integration), Playwright (E2E), Locust (perf)
- CI/CD: GitHub Actions

## Precedence (Conflict Resolution)

When rules, skills, or instructions conflict, follow this priority (highest first):

1. **Security rules** (`.claude/rules/security.md`) — always wins
2. **Error handling rules** (`.claude/rules/error-handling.md`) — safety over style
3. **Code style rules** (`.claude/rules/code-style.md`) — consistency over preference
4. **Testing rules** (`.claude/rules/testing.md`) — quality enforcement
5. **Git workflow rules** (`.claude/rules/git-workflow.md`) — process standards
6. **Skill recommendations** (`.claude/skills/`) — advisory, can be overridden by rules above

## Architecture
- See @docs/architecture.md for C4 diagrams
- See @docs/adr/ for Architecture Decision Records
- See @docs/api/openapi.yaml for API contracts (source of truth)

## Code Standards

Detailed rules with BAD/GOOD examples are in `.claude/rules/`:
- **`.claude/rules/security.md`** — Secrets, input validation, SQL injection, auth, HTTPS
- **`.claude/rules/code-style.md`** — Structure, size limits, constants, type safety, no duplication
- **`.claude/rules/error-handling.md`** — try/except, logging, specific exceptions
- **`.claude/rules/testing.md`** — TDD, fixtures, coverage, mock-at-boundaries
- **`.claude/rules/git-workflow.md`** — Branching, conventional commits, squash merge

### Quick Reference (MUST — enforced by CI hooks)
- SOLID principles: Single Responsibility per class/module
- No code duplication: Extract shared logic into utils/ or shared/
- No hardcoded values: All config via env vars or config files
- Type safety: Full type hints (Python), strict TypeScript
- Max function length: 30 lines. Max file length: 300 lines
- All public functions must have docstrings/JSDoc
- Every user story must have tests BEFORE implementation (TDD)
- Unit test coverage minimum: 80%

### Recommendations (SHOULD)
- Prefer composition over inheritance
- Dependency injection for testability
- Cyclomatic complexity under 10 per function
- Name by intent, not implementation

## Git Workflow
- Branch: feature/STORY-123-short-description
- Commits: conventional (feat:, fix:, refactor:, test:)
- One story per branch, one PR per story
- Squash merge to main

## Commands
- Build: `make build`
- Unit tests: `make test-unit`
- Integration tests: `make test-integration`
- E2E tests: `make test-e2e`
- All tests: `make test`
- Lint + typecheck: `make lint`
- Full CI: `make ci`
- Deploy staging: `make deploy-staging`
- Smoke tests: `make test-smoke --env=staging`

## Custom Commands
- `/gogogo` — Session startup: load context, check git status, show ready work
- `/interview` — Requirements gathering via structured interview
- `/decompose` — Break requirements into epics, stories, dependency graph
- `/implement` — TDD Red->Green->Refactor cycle for a story
- `/pr` — Run CI, generate PR description, create PR
- `/review` — Review a PR against 10-point checklist
- `/diagnose` — Diagnose test failures and create hotfix
- `/wrapup` — Session completion: commit, CI, push, handoff summary
- `/create-prompt` — Build a structured prompt using R.G.C.O.A. framework
```

### 1.2 Starter Permissions & Deterministic Hooks

**Starter permissions** reduce permission popup fatigue by pre-approving safe commands. Unlike hooks, permissions don't execute anything — they just suppress the "allow this command?" prompt for known-safe tools.

**Hooks** execute automatically and cannot be skipped. They are the deterministic enforcement layer.

```json
{
  "permissions": {
    "allow": [
      "Bash(python3 *)",
      "Bash(python *)",
      "Bash(pip *)",
      "Bash(pytest *)",
      "Bash(ruff *)",
      "Bash(mypy *)",
      "Bash(make *)",
      "Bash(make)",
      "Bash(git *)",
      "Bash(gh *)",
      "Bash(node *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(docker *)",
      "Bash(az *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(ls)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "command": "ruff check --fix $FILE && mypy $FILE --ignore-missing-imports",
        "description": "Lint and type-check after every edit"
      },
      {
        "matcher": "Write|Edit|MultiEdit",
        "command": "jscpd --min-lines 5 --threshold 0 src/",
        "description": "Detect code duplication"
      }
    ],
    "PreCommit": [
      {
        "command": "make ci",
        "description": "Full CI validation before any commit"
      }
    ]
  }
}
```

**Why starter permissions?** During a typical TDD session, Claude Code runs `pytest`, `ruff`, `mypy`, `make`, and `git` commands dozens of times. Without pre-approved permissions, each invocation triggers a confirmation prompt that breaks flow. Starter permissions eliminate this friction for known-safe commands while still requiring approval for destructive or unfamiliar operations.

### 1.3 Rules, Skills, Sub-Agents, and Commands

```
.claude/
├── settings.json                # Starter permissions + hooks
├── rules/                       # 5 rules (auto-loaded by file path)
│   ├── security.md              # OWASP: secrets, injection, auth, HTTPS
│   ├── code-style.md            # Structure, size, constants, types
│   ├── error-handling.md        # try/except, logging, specific exceptions
│   ├── testing.md               # TDD, fixtures, coverage, mocking
│   └── git-workflow.md          # Branching, conventional commits
├── skills/                      # 7 domain skills
│   ├── api-design/SKILL.md
│   ├── database-patterns/SKILL.md
│   ├── testing/SKILL.md
│   ├── deployment/SKILL.md
│   ├── langgraph-agents/SKILL.md
│   ├── react-frontend/SKILL.md
│   └── claude-agent-teams/SKILL.md
├── agents/                      # 3 sub-agents
│   ├── test-writer.yaml         # TDD Red phase specialist
│   ├── code-reviewer.yaml       # Quality review specialist
│   └── architect.yaml           # Design decision specialist
└── commands/                    # 9 custom commands
    ├── gogogo.md                # Session startup ceremony
    ├── interview.md             # Requirements gathering
    ├── decompose.md             # Requirements → stories
    ├── implement.md             # TDD implementation cycle
    ├── pr.md                    # Create PR with description
    ├── review.md                # Review a PR
    ├── diagnose.md              # Diagnose test failures
    ├── wrapup.md                # Session completion ceremony
    └── create-prompt.md         # R.G.C.O.A. prompt builder
```

### 1.4 Conflict Resolution

When rules, skills, or CLAUDE.md instructions conflict, the precedence order is:

1. **Security rules** — always wins (no secrets, input validation, etc.)
2. **Error handling rules** — safety over style
3. **Code style rules** — consistency over preference
4. **Testing rules** — quality enforcement
5. **Git workflow rules** — process standards
6. **Skill recommendations** — advisory only, can be overridden by any rule above

This prevents ambiguity: if a skill recommends a pattern that violates a security rule, the security rule wins. The precedence is defined in `CLAUDE.md` and Claude Code follows it automatically.

### 1.5 Session Ceremonies

Session ceremonies provide structure around the start and end of each Claude Code session, preventing "cold starts" and ensuring clean handoffs.

#### Starting a Session: `/gogogo`

```
/gogogo
```

**What it does:**
1. Loads project context from CLAUDE.md and architecture docs
2. Runs `git status` + `git log --oneline -5` to check current state
3. Scans `docs/backlog/` to classify stories as Ready, In Progress, Blocked, or Done
4. Lists open feature branches and any stale branches (no commits in 7+ days)
5. Suggests the next action: resume in-progress work, start a ready story, or review a PR

**Why it matters:** Without a startup ceremony, engineers waste 5-10 minutes at the start of each session re-orienting Claude to the project state. `/gogogo` compresses this to seconds and ensures nothing falls through the cracks.

#### Ending a Session: `/wrapup`

```
/wrapup
```

**What it does:**
1. Checks for uncommitted changes and offers to commit them
2. Runs `make ci` to validate everything passes
3. Updates the story file with completed acceptance criteria
4. Pushes to remote (`git push -u origin HEAD` if needed)
5. Generates a handoff summary: what was done, current CI state, what's next

**Why it matters:** Without a completion ceremony, engineers lose context between sessions — uncommitted work is forgotten, CI failures are discovered too late, and the next session starts with confusion. `/wrapup` creates a clean checkpoint.

#### Session Lifecycle

```
/gogogo → /interview → /decompose → /implement → /pr → /review → /wrapup
   ↑                                                                  │
   └──────────────── next session picks up from handoff ──────────────┘
```

### 1.6 Prompt Engineering: `/create-prompt`

For teams building agentic applications, `/create-prompt` provides a structured workflow for writing system prompts using the R.G.C.O.A. framework:

- **R**ole — What expertise and persona the AI should adopt
- **G**oal — The specific task and success criteria
- **C**ontext — Available tools, data, constraints, domain rules
- **O**utput — Expected format, structure, and length
- **A**udience — Who consumes the output, tone, and technical level

This prevents ad-hoc prompt writing that produces inconsistent agent behavior. The command walks through each dimension interactively, then assembles a complete system prompt ready for use in LangGraph nodes or Claude tool_use calls.

---

## 2. Requirements → Epics → Stories (Phase 1)

### 2.1 Custom Command: `/decompose`

```markdown
# .claude/commands/decompose.md
Read the requirements document at $ARGUMENTS.

1. Identify capability areas → create Epics
2. For each Epic, create User Stories (INVEST criteria):
   - Independent, Negotiable, Valuable, Estimable, Small, Testable
3. For each Story:
   - Title: As a [role], I want [capability], so that [benefit]
   - Acceptance Criteria: Given/When/Then (min 3 per story)
   - Story Points: Fibonacci (1, 2, 3, 5, 8)
   - Dependencies: which other stories must complete first
   - Expertise tag: backend / frontend / fullstack / infra / data
4. Generate dependency graph (Mermaid) → docs/backlog/dependency-graph.mmd
5. Generate implementation order → docs/backlog/implementation-order.md
   Using: foundation → infrastructure → contracts → core → integration → UI
6. Output stories to docs/backlog/[epic-name]/[story-id].md

DO NOT implement any code. Planning only.
```

### 2.2 Push to Project Management

```bash
claude -p "Read docs/backlog/ and create Jira stories in project PROJ.
  Set sprint to 'Sprint 14'. Add story points, acceptance criteria,
  and dependency links between stories."
```

---

## 3. Test Planning & Architecture (Phases 2 & 3 — Parallel)

These run in parallel since they're independent activities.

### 3.1 Test Plan Generation

```bash
claude --permission-mode plan -p "
  Read all user stories in docs/backlog/.
  For each story, generate a test plan covering:
  1. Unit tests (happy path + edge cases + error conditions)
  2. Integration tests (API contracts, database interactions)  
  3. E2E test scenarios (critical user journeys on deployed app)
  4. Performance test scenarios (load, stress, soak)
  5. Contract tests (API producer/consumer compatibility)
  Output to docs/test-plans/[story-id]-test-plan.md
  DO NOT write any test code yet."
```

### 3.2 Architecture Generation

```bash
claude --permission-mode plan -p "
  Read all requirements in docs/backlog/ and tech stack in CLAUDE.md.
  Produce:
  1. C4 Context + Container diagrams (Mermaid)
  2. Component diagrams per service
  3. Data model (ERD)
  4. OpenAPI 3.1 contract (source of truth)
  5. Architecture Decision Records
  Output to docs/architecture/ and docs/api/"
```

---

## 4. Story Assignment & Team Orchestration (Phase 4)

This is the critical team coordination piece. There are three models depending on team size and complexity.

### 4.1 Model A: Manual Assignment (Small Teams, 2–5 Engineers)

The Tech Lead or Engineering Manager reviews the dependency graph and implementation order, then assigns stories to engineers.

**Assignment Principles:**

```
1. DEPENDENCY CHAINS → Same engineer
   Stories 101→102→103 (sequential dependency) → assign to one person
   to minimize handoff overhead and context switching.

2. INDEPENDENT STORIES → Parallelize across engineers  
   Stories 104, 107, 110 (no dependencies on each other) → 
   assign to different engineers for maximum parallelism.

3. EXPERTISE MATCH → Route by tag
   Backend stories → backend engineers
   Frontend stories → frontend engineers
   Infrastructure stories → platform/DevOps engineers

4. COMPLEXITY BALANCE → Distribute evenly
   Don't give one engineer all the 8-point stories.
   Mix 1-2 complex stories with simpler ones per sprint.
```

**The Tech Lead creates an assignment board:**

```markdown
# Sprint 14 — Story Assignments

## Engineer A (Backend Senior) — Auth Domain
| Story | Points | Dependencies | Status |
|-------|--------|-------------|--------|
| STORY-101: User registration | 3 | None | Ready |
| STORY-102: Role-based access | 5 | 101 | Blocked |
| STORY-103: Session management | 3 | 101 | Blocked |

## Engineer B (Fullstack) — Catalog Domain  
| Story | Points | Dependencies | Status |
|-------|--------|-------------|--------|
| STORY-104: Product listing | 3 | None | Ready |
| STORY-105: Search & filter | 5 | 104 | Blocked |
| STORY-106: Product detail | 2 | 104 | Blocked |

## Engineer C (Backend Mid) — Payments Domain
| Story | Points | Dependencies | Status |
|-------|--------|-------------|--------|
| STORY-107: Payment types | 3 | None | Ready |
| STORY-108: Checkout flow | 8 | 101, 107 | Blocked |
| STORY-109: Receipt gen | 2 | 108 | Blocked |
```

**Each engineer's workflow:**

```bash
# Engineer A sets up their workspace
git worktree add trees/STORY-101 -b feature/STORY-101-user-registration
cd trees/STORY-101
claude  # Start Claude Code session

# Inside Claude Code:
/implement docs/backlog/auth/story-101.md

# When STORY-101 is merged, move to STORY-102:
git worktree add trees/STORY-102 -b feature/STORY-102-rbac
cd trees/STORY-102
git merge main  # Pick up STORY-101's merged code
claude
/implement docs/backlog/auth/story-102.md
```

### 4.2 Model B: Agent Teams (Individual Engineer, Multiple Stories in Parallel)

A single engineer can use Claude Code's Agent Teams (shipped with Opus 4.6, Feb 2025) to parallelize independent stories within their assignment:

```bash
# Enable Agent Teams
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Start Claude Code and create a team
claude

# Inside Claude Code:
"Create an agent team for Sprint 14 Auth domain.
 Spawn 3 teammates:
 - Teammate 1: Implement STORY-101 (user registration) in trees/STORY-101
 - Teammate 2: Implement STORY-104 (product listing) in trees/STORY-104  
 - Teammate 3: Implement STORY-107 (payment types) in trees/STORY-107
 
 Each teammate must follow TDD (Red→Green→Refactor).
 Each creates their own feature branch and PR.
 Use delegate mode — you coordinate only, don't implement."
```

The lead orchestrates, teammates work in isolated worktrees with independent context windows, communicate via shared task list and messaging. You monitor via split panes (tmux/iTerm2) or in-process mode (Shift+Up/Down).

### 4.3 Model C: GitHub-Driven Assignment (Larger Teams, Issue-Based)

For larger teams, use GitHub Issues as the assignment mechanism with Claude Code GitHub Actions automating the implementation:

```yaml
# .github/workflows/claude-implement.yml
name: Claude Auto-Implement
on:
  issues:
    types: [labeled]

jobs:
  implement:
    if: github.event.label.name == 'claude-implement'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Read this issue and implement the user story using TDD.
            1. Write failing tests from acceptance criteria
            2. Implement minimal code to pass tests
            3. Refactor for quality (SOLID, DRY, clean code)
            4. Run make ci to validate everything
            5. Create a PR linked to this issue
          claude_args: "--max-turns 30"
```

**The workflow:**
1. Tech Lead creates GitHub Issues from the backlog (or Claude Code pushes them)
2. Issues are assigned to engineers in GitHub
3. Engineer adds the `claude-implement` label to their assigned issue
4. Claude Code Action creates a branch, implements with TDD, creates a PR
5. Engineer reviews the PR, provides feedback, iterates
6. Once satisfied, engineer approves and merges

**For an engineer working locally:**
```bash
# Pick up an assigned issue
claude --from-issue 42
# Claude reads the issue, creates branch, implements with TDD, creates PR
```

### 4.4 Cross-Engineer Coordination Patterns

| Situation | Pattern |
|-----------|---------|
| Story B depends on Story A (different engineers) | Engineer B waits for A's PR to merge to main, then rebases. Use GitHub "blocked" labels to signal. |
| Shared interface needed (API contract) | Generate OpenAPI contract FIRST. Both engineers code against the contract, not each other's implementation. |
| Merge conflicts between parallel stories | Each engineer rebases on main regularly (after each story merge). Claude Code can auto-resolve simple conflicts. |
| Code review of peer's PR | Engineer uses `claude --from-pr 456` to review, or uses `@claude` in PR comments for automated analysis. |
| Shared utility needed by multiple stories | Assign shared utility as its own story (e.g., STORY-100: logging utility), implement first, merge to main before dependent stories start. |

---

## 5. Implementation Per Story (Phase 4 continued)

### 5.1 The TDD Cycle with Sub-Agents

```
┌─────────────────────────────────────────────────────┐
│  RED: Test-Writer Sub-Agent (isolated context)       │
│  → Reads story + acceptance criteria                 │
│  → Writes FAILING tests (cannot see implementation)  │
│  → Generates test data fixtures                      │
│  → Verifies tests FAIL → commits                     │
├─────────────────────────────────────────────────────┤
│  GREEN: Main Agent                                   │
│  → Reads failing tests                               │
│  → Implements MINIMUM code to pass                   │
│  → Runs tests after each file change (hook)          │
│  → All pass → commits                                │
├─────────────────────────────────────────────────────┤
│  REFACTOR: Main Agent                                │
│  → Extract duplicated code to shared modules         │
│  → Enforce SOLID compliance                          │
│  → Improve naming and documentation                  │
│  → Run full CI: make ci                              │
│  → All pass → commits                                │
├─────────────────────────────────────────────────────┤
│  VALIDATE: Full CI hook                              │
│  → Lint + typecheck + unit tests + integration tests │
│  → Coverage check (≥80%)                             │
│  → Duplication check                                 │
│  → Security scan                                     │
│  → ALL PASS → ready for PR                           │
│  → ANY FAIL → diagnose and fix (loop back)           │
└─────────────────────────────────────────────────────┘
```

### 5.2 TDD Guard Enforcement

Install the TDD Guard hook to mechanically enforce Red→Green→Refactor:

```bash
npm install -g tdd-guard
# Configure via /hooks in Claude Code:
# Matcher: Write|Edit|MultiEdit|TodoWrite
# Command: tdd-guard
```

This intercepts every file modification and blocks: (a) implementation without a failing test, (b) implementation exceeding what the test requires, (c) adding multiple tests simultaneously.

### 5.3 Code Quality Guardrails

| Concern | Enforcement | Tool |
|---------|-------------|------|
| No secrets in code | Security rule (`.claude/rules/security.md`) | Path-scoped to `src/**/*.py` |
| Input validation | Security rule | Pydantic models at API boundaries |
| SQL injection prevention | Security rule | Parameterized queries / ORM only |
| No code duplication | PostToolUse hook | `jscpd` / `pylint --duplicate-code` |
| SOLID principles | CLAUDE.md rules + review sub-agent | Manual/automated review |
| No hardcoding | Code style rule + PostToolUse hook | Named constants, no magic numbers |
| Test coverage ≥80% | PreCommit hook | `pytest --cov --cov-fail-under=80` |
| Type safety | PostToolUse hook | `mypy` / `tsc --noEmit` |
| Linting | PostToolUse hook | `ruff` / `eslint` |
| Max complexity | CI pipeline | `flake8` / `eslint` complexity rules |
| HTTPS + timeouts | Security rule | All external calls use HTTPS with timeouts |
| Error response safety | Security rule | No stack traces or internal details in API responses |
| Dependency security | CI pipeline + advisory | `pip audit` / `safety check` / Trivy |

**Security rule precedence:** The security rule (`.claude/rules/security.md`) always takes priority over other rules. If a code style recommendation conflicts with a security requirement, security wins. See Section 1.4 for the full conflict resolution matrix.

---

## 6. Pull Requests & Code Review (Phase 5)

### 6.1 Creating PRs

Custom command `.claude/commands/pr.md`:

```markdown
1. Run `make ci` — abort if anything fails
2. Generate PR description:
   - Title: [STORY-ID] Brief description
   - Summary: what changed and why
   - Files changed with brief explanation
   - Tests added/modified
   - Link to user story
3. Push and create PR:
   gh pr create --title "[STORY-ID] desc" --body-file /tmp/pr-desc.md --base main
4. Request reviewers per CODEOWNERS
```

### 6.2 Automated Review via GitHub Actions

```yaml
name: Claude Code Review
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Review this PR against:
            1. SOLID principles
            2. No code duplication (vs existing codebase)
            3. No hardcoded values
            4. Test coverage for new code
            5. Error handling completeness
            6. Security (no secrets, injection, XSS)
            7. Performance (no N+1, unnecessary allocations)
            8. Documentation (public APIs)
            Provide severity (critical/warning/suggestion) per finding.
```

### 6.3 The Review Feedback Loop

```
PR Created
    ↓
Auto-review (Claude GitHub Action) ──→ Comments posted
    ↓
Peer review (Human engineer) ──→ Additional comments
    ↓
┌── ANY FEEDBACK? ──────────────────────────────────┐
│   YES:                                            │
│   claude --from-pr 123                            │
│   → Claude reads all review comments              │
│   → Fixes each issue                              │
│   → Runs make ci                                  │
│   → Commits: "fix: address review - [summary]"   │
│   → Pushes to update PR                           │
│   → Replies to each comment explaining the fix    │
│   → Loop back to Auto-review                      │
│                                                   │
│   NO: All approved → Squash merge to main         │
└───────────────────────────────────────────────────┘
```

---

## 7. CI/CD Pipeline with Post-Deployment Testing (Phases 6 & 7)

This is the complete pipeline — unit tests run in CI, but the critical final gate is **executing test automation against the actual deployed application**.

### 7.1 The Full Pipeline

```yaml
# .github/workflows/pipeline.yml
name: Full CI/CD Pipeline

on:
  push:
    branches: [main]

jobs:
  # ═══════════════════════════════════════════════════
  # STAGE 1: BUILD + UNIT TESTS (CI)
  # ═══════════════════════════════════════════════════
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: make install
      - name: Lint + Type Check
        run: make lint
      - name: Unit Tests
        run: make test-unit -- --coverage --cov-fail-under=80
      - name: Integration Tests
        run: make test-integration
      - name: Security Scan (SAST)
        uses: github/codeql-action/analyze@v3
      - name: Dependency Vulnerability Scan
        run: trivy fs --severity HIGH,CRITICAL .
      - name: Build Docker Image
        run: docker build -t $IMAGE_TAG .
      - name: Push to Azure Container Registry
        run: az acr login --name $ACR_NAME && docker push $IMAGE_TAG

  # ═══════════════════════════════════════════════════
  # STAGE 2: DEPLOY TO STAGING
  # ═══════════════════════════════════════════════════
  deploy-staging:
    needs: ci
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to Azure App Service (Staging Slot)
        run: |
          az webapp config container set --name $SERVICE_NAME \
            --resource-group $RESOURCE_GROUP --slot staging \
            --image $IMAGE_TAG
          az webapp config appsettings set --name $SERVICE_NAME \
            --resource-group $RESOURCE_GROUP --slot staging \
            --settings "ENV=staging"

  # ═══════════════════════════════════════════════════
  # STAGE 3: POST-DEPLOYMENT TESTS (on live staging)
  # ═══════════════════════════════════════════════════
  post-deploy-tests:
    needs: deploy-staging
    runs-on: ubuntu-latest
    steps:
      # 3a. Smoke Tests — quick health checks
      - name: Smoke Tests
        run: |
          make test-smoke --env=staging
        # Hits key endpoints, verifies 200s, checks DB connectivity,
        # validates auth flow works end-to-end

      # 3b. E2E Tests — full user journeys on deployed app
      - name: E2E Tests (Playwright)
        run: |
          STAGING_URL=${{ vars.STAGING_URL }} \
          npx playwright test --project=staging
        # Runs complete user journeys: registration → login → 
        # create order → payment → receipt

      # 3c. API Contract Tests — verify OpenAPI compliance
      - name: Contract Tests
        run: |
          schemathesis run docs/api/openapi.yaml \
            --base-url=${{ vars.STAGING_URL }} \
            --checks all
        # Validates every endpoint matches the OpenAPI spec
        # Catches schema drift between spec and implementation

      # 3d. Performance Tests — verify response times
      - name: Performance Tests (Locust)
        run: |
          locust -f tests/perf/locustfile.py \
            --host=${{ vars.STAGING_URL }} \
            --users=50 --spawn-rate=10 --run-time=2m \
            --headless --csv=perf-results
          python tests/perf/validate_results.py perf-results
        # Validates: p95 < 500ms, error rate < 1%, throughput > 100 rps

      # 3e. Upload test results
      - name: Upload Test Reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: post-deploy-test-reports
          path: |
            playwright-report/
            perf-results*.csv

  # ═══════════════════════════════════════════════════
  # STAGE 4: AUTO-REMEDIATION (if tests fail)
  # ═══════════════════════════════════════════════════
  remediate:
    needs: post-deploy-tests
    if: failure()
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
    steps:
      - uses: actions/checkout@v4
      - name: Download failure reports
        uses: actions/download-artifact@v4
        with:
          name: post-deploy-test-reports
          path: test-reports/

      - name: Claude Diagnose + Fix
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Post-deployment tests have FAILED on staging.
            
            1. Read the test failure reports in test-reports/
            2. Diagnose the root cause of each failure
            3. Determine if it's a code bug, config issue, or environment problem
            4. If code bug: fix it, run unit + integration tests locally
            5. Create a hotfix PR with the fix
            6. If config/environment: create a GitHub issue with diagnosis
            
            Do NOT deploy. Create a PR for human review.
          claude_args: "--max-turns 15"

  # ═══════════════════════════════════════════════════
  # STAGE 5: PROMOTE TO PRODUCTION (manual gate)
  # ═══════════════════════════════════════════════════
  deploy-production:
    needs: post-deploy-tests
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval in GitHub
    steps:
      - name: Swap Staging to Production
        run: |
          az webapp deployment slot swap --name $SERVICE_NAME \
            --resource-group $RESOURCE_GROUP \
            --slot staging --target-slot production

      # Production smoke tests
      - name: Production Smoke Tests
        run: make test-smoke --env=production

      # If smoke tests fail → auto-rollback
      - name: Rollback on Failure (swap back)
        if: failure()
        run: |
          az webapp deployment slot swap --name $SERVICE_NAME \
            --resource-group $RESOURCE_GROUP \
            --slot staging --target-slot production
```

### 7.2 The Failure → Fix → Retry Loop

This is the self-healing mechanism that closes the loop:

```
┌──────────────────────────────────────────────────────────────┐
│                    POST-DEPLOY TESTS FAIL                      │
└────────────────────────────────┬─────────────────────────────┘
                                 ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 1: DIAGNOSE                                            │
│  Claude Code reads failure reports:                           │
│  → Playwright HTML report (screenshots of failures)           │
│  → Contract test violations (schema mismatches)               │
│  → Performance test CSV (which endpoints are slow)            │
│  → Stack traces from smoke test failures                      │
└────────────────────────────────┬─────────────────────────────┘
                                 ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 2: CLASSIFY                                            │
│                                                              │
│  Code Bug → Fix the code, create hotfix PR                    │
│  Config Issue → Fix env vars / secrets, re-deploy             │
│  Schema Drift → Update OpenAPI spec OR fix implementation     │
│  Performance → Optimize query / add caching / fix N+1         │
│  Environment → Flag for DevOps (infra issue, not code)        │
└────────────────────────────────┬─────────────────────────────┘
                                 ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 3: FIX + VERIFY                                        │
│                                                              │
│  Claude Code:                                                │
│  1. Creates hotfix branch from main                           │
│  2. Applies fix                                               │
│  3. Runs unit + integration tests locally                     │
│  4. Creates hotfix PR                                         │
│  5. Auto-review runs on the PR                                │
│                                                              │
│  Human:                                                      │
│  1. Reviews hotfix PR                                         │
│  2. Approves → merge                                          │
│  3. Pipeline re-runs from the top                             │
│  4. Post-deploy tests re-execute on staging                   │
│  5. Pass → promote to production                              │
│  6. Fail again → loop back to diagnose (max 3 retries)        │
└──────────────────────────────────────────────────────────────┘
```

### 7.3 Custom Command: `/diagnose`

```markdown
# .claude/commands/diagnose.md
Read the test failure reports at $ARGUMENTS.

For each failure:
1. Identify the failing test and its assertion
2. Trace the failure to root cause in the codebase
3. Classify: code_bug | config_issue | schema_drift | perf_regression | env_issue
4. If code_bug or schema_drift or perf_regression:
   - Create a hotfix branch: hotfix/[test-name]-[date]
   - Apply the minimal fix
   - Run the relevant tests locally to verify
   - Run make ci for full validation
   - Create a PR with diagnosis + fix explanation
5. If config_issue or env_issue:
   - Create a GitHub issue with full diagnosis
   - Tag as "infrastructure" and assign to DevOps
```

### 7.4 Generating the Test Automation Scripts

Claude Code generates the actual E2E and performance test scripts that run against the deployed app:

```bash
claude -p "
  Read the user stories in docs/backlog/ and test plans in docs/test-plans/.
  Generate Playwright E2E tests in tests/e2e/ that:
  1. Run against a configurable STAGING_URL or PRODUCTION_URL
  2. Cover all critical user journeys end-to-end
  3. Include visual regression checks (screenshot comparison)
  4. Handle auth flows (login, token refresh, logout)
  5. Are resilient to timing (use proper waits, not sleep)
  6. Generate HTML reports with failure screenshots

  Generate Locust performance tests in tests/perf/ that:
  1. Simulate realistic user behavior patterns
  2. Validate p95 latency < 500ms for all endpoints
  3. Validate error rate < 1% under load
  4. Export CSV results for trend analysis

  Generate contract tests using Schemathesis:
  1. Validate all endpoints match docs/api/openapi.yaml
  2. Check response schemas, status codes, headers
  3. Fuzz inputs to find edge cases"
```

---

## 8. Pipeline Generation

Claude Code generates the deployment infrastructure itself:

```bash
claude -p "
  Read CLAUDE.md and docs/architecture/.
  Generate:
  1. GitHub Actions CI/CD pipeline (the full pipeline from Section 7.1)
  2. Terraform IaC for Azure App Service + Azure Database for PostgreSQL + Azure Service Bus
  3. Docker multi-stage build (lean production image)
  4. Staging and production environment configs
  5. Monitoring: Azure Monitor alerts for error rate, latency, CPU
  6. Rollback script: automated rollback on smoke test failure
  
  Security best practices:
  - Pin actions by commit SHA
  - Least-privilege permissions per job
  - OIDC for cloud provider auth (no static keys)
  - Secrets via GitHub Secrets only"
```

---

## 9. Tooling Ecosystem Summary

### Core Scaffolding (included in this repo)

| Component | Count | Purpose |
|-----------|-------|---------|
| **CLAUDE.md** | 1 | Project constitution with precedence rules, pre-completion checklist |
| **Rules** | 5 | Security, code style, error handling, testing, git workflow — with BAD/GOOD examples |
| **Commands** | 9 | `/gogogo`, `/interview`, `/decompose`, `/implement`, `/pr`, `/review`, `/diagnose`, `/wrapup`, `/create-prompt` |
| **Skills** | 7 | API design, DB patterns, testing, deployment, LangGraph, React, Claude agents |
| **Sub-agents** | 3 | test-writer, code-reviewer, architect |
| **Starter permissions** | 17 | Pre-approved safe Bash commands (python, pytest, ruff, mypy, make, git, etc.) |
| **Hooks** | 2 | PostToolUse (lint+typecheck), PreCommit (full CI) |
| **Bootstrap files** | 5 | pyproject.toml, Makefile, .env.example, .gitignore, src/ + tests/ stubs |

### External Tools (optional integrations)

| Tool | Purpose | Setup |
|------|---------|-------|
| **Agent Teams** | Multi-agent parallel orchestration | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| **TDD Guard** | Enforce Red→Green→Refactor | `npm install -g tdd-guard` + hooks |
| **claude-code-action** | GitHub PR automation | `/install-github-app` |
| **worktree-workflow** | Parallel development toolkit | `github.com/anthropics/worktree-workflow` |
| **cc-sdd** | Spec-driven development framework | `npx cc-sdd@latest --claude` |
| **Codacy Guardrails MCP** | Real-time security scanning | Codacy MCP setup |
| **GitHub CLI (gh)** | PR/issue management from terminal | `brew install gh` |
| **Playwright** | E2E test automation (post-deploy) | `npm install -D @playwright/test` |
| **Locust** | Performance test automation | `pip install locust` |
| **Schemathesis** | API contract testing | `pip install schemathesis` |

---

## 10. Anti-Patterns

1. **"Vibe coding" for production** — Unstructured prompting works for prototypes, not production. Always plan, then implement.

2. **Skipping CLAUDE.md** — Without persistent context, Claude's output is inconsistent.

3. **Assigning dependent stories to different engineers without a contract** — Always generate the shared interface (OpenAPI spec, shared types) first as its own story.

4. **Trusting AI output without running tests** — Hooks and TDD Guard exist for a reason. Never skip `make ci`.

5. **Single-threaded when you could parallelize** — Independent stories on different worktrees is the biggest velocity multiplier.

6. **No post-deployment testing** — Unit tests passing in CI means nothing if the deployed app doesn't work. E2E on staging is mandatory.

7. **No feedback loop on failures** — When tests fail, the pipeline should diagnose + fix + retry, not just fail and wait for manual intervention.

8. **Not iterating on CLAUDE.md** — When Claude gets something wrong, add a rule. When rules stop being needed, prune them.

9. **No session boundaries** — Starting Claude Code without `/gogogo` leads to cold-start confusion. Ending without `/wrapup` loses session context. Use ceremonies to maintain continuity across sessions.

10. **Hardcoded secrets in source code** — The security rule exists for a reason. All secrets via environment variables, Key Vault, or `.env` files (never committed). Violations should be caught by the security rule before they reach a commit.

11. **No conflict resolution** — When CLAUDE.md says one thing and a skill says another, without explicit precedence, Claude guesses. Define precedence (Security > Error handling > Code style > Skills) and stick to it.

12. **Permission popup fatigue** — Without starter permissions, engineers click "allow" reflexively or abandon Claude Code. Pre-approve safe commands to maintain flow while still gating destructive operations.

---

## 11. Expected Outcomes

| Metric | Traditional | With Claude Code | Gain |
|--------|------------|------------------|------|
| Requirements → Stories | 1 week | 1–2 hours | 5–10x |
| Test plan generation | 2–3 days | 2–4 hours | 4–8x |
| Implementation per story | 2–5 days | 0.5–1 day | 3–5x |
| PR creation + description | 30–60 min | 2–5 min | 10x |
| Code review turnaround | 1–2 days | Minutes (auto) | 10x+ |
| CI/CD pipeline creation | 1–2 days | 1–2 hours | 5–10x |
| Post-deploy test authoring | 3–5 days | 2–4 hours | 5–10x |
| Failure diagnosis | 1–4 hours | 5–15 min | 5–15x |

---

## 12. Getting Started Checklist

### Phase 1: Foundation (Day 1)
- [ ] Install Claude Code: `npm install -g @anthropic-ai/claude-code`
- [ ] Copy scaffolding into your project (CLAUDE.md, .claude/, pyproject.toml, Makefile, etc.)
- [ ] Customize CLAUDE.md: set project name, tech stack, and `make` targets
- [ ] Verify starter permissions in `.claude/settings.json` match your stack
- [ ] Verify hooks work: edit a `.py` file and confirm ruff + mypy run automatically
- [ ] Run `/gogogo` to confirm session startup works

### Phase 2: Workflow (Day 2-3)
- [ ] Create custom commands if not using scaffolding defaults
- [ ] Review and customize rules in `.claude/rules/` (security, code-style, error-handling, testing, git)
- [ ] Verify precedence rules in CLAUDE.md match your team's priorities
- [ ] Install TDD Guard for test-first enforcement (optional)
- [ ] Create test-writer sub-agent
- [ ] Run a pilot: `/interview` → `/decompose` → `/implement` → `/pr` on a small feature
- [ ] End session with `/wrapup` to verify handoff summary generation

### Phase 3: CI/CD & Team (Week 1-2)
- [ ] Configure Claude GitHub Action for automated PR review
- [ ] Set up git worktree workflow for parallel development
- [ ] Write E2E test suite (Playwright) targeting staging URL
- [ ] Write contract tests (Schemathesis) against OpenAPI spec
- [ ] Write performance tests (Locust) with acceptance thresholds
- [ ] Configure CI/CD pipeline with all 5 stages
- [ ] Enable Agent Teams for multi-agent orchestration
- [ ] Run a full sprint with 3-5 stories to validate the end-to-end workflow

### Phase 4: Iterate (Ongoing)
- [ ] Iterate on CLAUDE.md based on what Claude gets wrong
- [ ] Add new rules to `.claude/rules/` for recurring mistakes
- [ ] Use `/create-prompt` when building system prompts for LangGraph agents
- [ ] Prune rules that are no longer needed
- [ ] Share what works with the team — scaffolding is a living document

---

*Adopt incrementally. Start with CLAUDE.md + hooks + starter permissions + `/gogogo`. Add rules, commands, and skills as your team builds confidence. The full framework (9 commands, 5 rules, 7 skills, 3 agents) compounds — each piece makes the others more effective.*
