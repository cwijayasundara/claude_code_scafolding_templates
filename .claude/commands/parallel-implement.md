# /parallel-implement — Agent Teams Parallel Implementation

Orchestrate parallel story implementation using Claude Code's native agent teams feature.
The lead session (you) coordinates the team — each teammate implements one independent story.

**Status**: Experimental — requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

## Arguments

`$ARGUMENTS` should be one of:
- A wave identifier: `wave-1`, `wave-2`, etc. (from `docs/backlog/parallel-batches.md`)
- A comma-separated list of story IDs: `STORY-001,STORY-002,STORY-003`

## Pre-flight Checks (ALL must pass)

1. **Agent teams enabled** — verify:
   - Environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set
   - Setting `AGENT_TEAMS_ENABLED` is `"true"` in `.claude/settings.json` env block
   - If either is missing, suggest `/parallel-manual` as the stable alternative and STOP
2. **`docs/backlog/parallel-batches.md` exists** — if not, tell the user to run `/decompose` first
3. **Parse the requested wave or story list**:
   - If a wave: read `parallel-batches.md` and extract stories for that wave
   - If story IDs: validate each story file exists in `docs/backlog/`
4. **Dependency check**: verify ALL stories are Ready — no existing feature branches, all `depends_on` stories are Done. Stories with unresolved dependencies MUST NOT be included.
5. **Clean working tree**: `git status --porcelain` is empty
6. **Teammate count within limit**: story count <= `AGENT_TEAMS_MAX_TEAMMATES` (default 3)
   - If over limit, split into sub-batches and process sequentially
7. If any check fails, report the issue clearly and STOP

## Cost Warning

Display before creating the team:
```
Agent Teams Cost Estimate:
- Stories in this wave: N
- Each teammate uses its own context window (~7x a single /implement run)
- Total estimated cost: ~Nx7x base cost
- Stable alternative: /parallel-manual (1x cost per terminal)

Proceed? [y/N]
```

Wait for user confirmation before proceeding.

## Worktree Setup

Create a git worktree per story so teammates never conflict on files:

```bash
git worktree add .worktrees/STORY-XXX -b feature/STORY-XXX-short-description main
```

Repeat for each story. Each teammate will work in its own worktree directory.

## Team Creation

Use natural language to create the agent team. Tell Claude (yourself, the lead):

```
Create an agent team to implement Wave N stories in parallel.
Use delegate mode — I will only coordinate, not implement.

Spawn one teammate per story, each working in its own worktree:

Teammate 1 — "STORY-XXX-implementer":
  Working directory: .worktrees/STORY-XXX
  Task: Implement STORY-XXX following TDD Red-Green-Refactor.
  Require plan approval before making changes.

Teammate 2 — "STORY-YYY-implementer":
  Working directory: .worktrees/STORY-YYY
  Task: Implement STORY-YYY following TDD Red-Green-Refactor.
  Require plan approval before making changes.

[... one per story]
```

### Key orchestration instructions:

1. **Use delegate mode** (Shift+Tab after team creation) — the lead coordinates only, does NOT write code itself
2. **Require plan approval** for each teammate — they plan the TDD cycle first, the lead approves before implementation begins
3. **Each teammate gets its own worktree** — this prevents file conflicts between teammates

## Shared Task List

Create tasks in the shared task list for each story. Each task should include:

- **Story ID and title**
- **Story file path**: `docs/backlog/[epic]/STORY-XXX.md`
- **Worktree path**: `.worktrees/STORY-XXX`
- **Feature branch**: `feature/STORY-XXX-short-description`
- **Acceptance criteria** (from the story file)
- **Task dependencies**: if stories have inter-wave deps (they shouldn't in the same wave, but verify)

The shared task list ensures teammates can self-claim work and the lead can track progress.

## Teammate Instructions

Each teammate receives this prompt when spawned:

```
You are implementing a user story in your assigned git worktree.

## Your Assignment
- Story: STORY-XXX — [title]
- Worktree: .worktrees/STORY-XXX (this is your working directory)
- Branch: feature/STORY-XXX-short-description

## Story Details
[Include full content of the story file, including Dependencies and Acceptance Criteria sections]

## TDD Red-Green-Refactor Cycle

Follow this EXACTLY:

### 1. RED — Write failing tests first
- Read the acceptance criteria above
- Write test files in tests/ that cover ALL acceptance criteria
- Run: `make test-unit` — confirm tests FAIL
- Commit: `git commit -m "test: add failing tests for STORY-XXX"`

### 2. GREEN — Write minimum code to pass
- Implement in src/ — minimum code to make all tests pass
- Run: `make test-unit` — confirm tests PASS
- Commit: `git commit -m "feat: implement STORY-XXX"`

### 3. REFACTOR — Apply Pre-Completion Checklist
- No magic numbers → extract to UPPER_SNAKE_CASE constants
- No code duplication → extract helpers
- Every external call wrapped in try/except
- Logger in every module: `logger = logging.getLogger(__name__)`
- Functions under 30 lines, single responsibility
- Commit: `git commit -m "refactor: clean up STORY-XXX"`

### 4. VALIDATE — Run full CI
- Run: `make ci`
- Verify test coverage >= 80%
- If CI fails, fix and re-commit

## Rules
- ONLY work inside your worktree directory
- Do NOT push to remote — the lead handles PRs
- When done, message the lead with: story ID, branch name, CI pass/fail, coverage %
```

## Monitoring and Coordination

### As the lead, you should:
- **Stay in delegate mode** — do not implement code yourself
- **Review plans** — when a teammate submits a plan for approval, check it covers all acceptance criteria and follows TDD before approving
- **Monitor progress** via the shared task list — watch for tasks moving from pending → in_progress → completed
- **Message teammates** if they get stuck — use direct messages, not broadcast (broadcast costs scale with team size)
- **Wait for all teammates** to finish before proceeding — do not start post-completion until every teammate is done or explicitly failed

### Hooks that fire automatically:
- **`TeammateIdle`** (`teammate-idle.sh`): When a teammate goes idle, checks if their task's CI passes. If not, sends them back to fix.
- **`TaskCompleted`** (`teammate-completed.sh`): When a task is marked complete, runs `make ci` in the worktree. Exit code 2 rejects completion and sends the teammate back.

## Post-Completion

After ALL teammates finish:

1. **Collect results** from each teammate (via messages or task list):

   ```
   ## Parallel Implementation Results — Wave N

   | Story | Teammate | Branch | CI | Coverage | Status |
   |-------|----------|--------|----|----------|--------|
   | STORY-001 | STORY-001-implementer | feature/STORY-001-desc | PASS | 87% | Done |
   | STORY-002 | STORY-002-implementer | feature/STORY-002-desc | PASS | 92% | Done |
   | STORY-003 | STORY-003-implementer | feature/STORY-003-desc | FAIL | 73% | Retry |
   ```

2. **Create PRs** for passing stories (lead does this, not teammates):
   ```bash
   cd .worktrees/STORY-XXX
   git push -u origin feature/STORY-XXX-description
   gh pr create --title "feat: STORY-XXX — [title]" --body "..."
   ```

3. **Handle failures**: For stories that failed CI:
   - Show the failure output from the teammate
   - Suggest: "Run `/implement docs/backlog/[epic]/STORY-XXX.md` to fix manually"
   - Do NOT auto-retry — let the user decide

4. **Cleanup**:
   - Ask all teammates to shut down: "Ask all teammates to shut down"
   - Clean up the team: "Clean up the team"
   - If `AGENT_TEAMS_AUTO_CLEANUP` is `"true"`, remove worktrees for PASSING stories:
     ```bash
     git worktree remove .worktrees/STORY-XXX
     ```
   - Keep failed worktrees for debugging

## Error Handling

- **Teammate fails to spawn**: Log error, continue creating remaining teammates
- **Teammate crashes mid-implementation**: Worktree and branch are preserved — suggest manual recovery with `/implement`
- **All teammates fail**: Report failures, suggest falling back to `/parallel-manual`
- **Worktree creation fails**: Skip that story, continue with others
- **Lead exits before teammates finish**: Teammates may become orphaned — the user can resume them or kill via tmux
- Failed stories do NOT abort successful ones — each teammate is independent
