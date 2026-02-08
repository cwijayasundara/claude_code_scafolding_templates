# /parallel-manual — Manual Parallel Implementation via Git Worktrees

Set up git worktrees for parallel story implementation across multiple terminals.
This is the **stable** alternative to `/parallel-implement` — no experimental features required.

## Arguments

`$ARGUMENTS` should be one of:
- A wave identifier: `wave-1`, `wave-2`, etc. (from `docs/backlog/parallel-batches.md`)
- A comma-separated list of story IDs: `STORY-001,STORY-002,STORY-003`

## Pre-flight Checks

1. **Verify `docs/backlog/parallel-batches.md` exists** — if not, tell the user to run `/decompose` first
2. **Parse the requested wave or story list**:
   - If a wave: read `parallel-batches.md` and extract stories for that wave
   - If story IDs: validate each story file exists in `docs/backlog/`
3. **Verify all stories are Ready** (not In Progress, Blocked, or Done):
   - Check no existing feature branch: `git branch --list 'feature/STORY-XXX*'`
   - Check dependencies are satisfied (all deps in prior waves are Done)
4. **Verify clean working tree**: `git status --porcelain` should be empty
5. If any check fails, report the issue and stop — do NOT proceed with partial setup

## Worktree Setup

For each story in the batch:

1. Determine the worktree directory: `.worktrees/STORY-XXX`
2. Create the worktree with a feature branch:
   ```bash
   git worktree add .worktrees/STORY-XXX -b feature/STORY-XXX-short-description main
   ```
3. Verify the worktree was created successfully

## Output: Terminal Instructions

After creating all worktrees, output a clear set of per-terminal instructions:

```
## Parallel Implementation Setup Complete

Created N worktrees for [Wave X / custom batch]:

### Terminal 1 — STORY-XXX: [Story Title]
```bash
cd .worktrees/STORY-XXX
claude
# Then run: /implement docs/backlog/[epic]/STORY-XXX.md
```

### Terminal 2 — STORY-YYY: [Story Title]
```bash
cd .worktrees/STORY-YYY
claude
# Then run: /implement docs/backlog/[epic]/STORY-YYY.md
```

### ... (one per story)

### After All Stories Complete
```bash
# Merge each feature branch back (from main worktree):
git checkout main
git merge feature/STORY-XXX-description
git merge feature/STORY-YYY-description
# ... repeat for each story

# Clean up worktrees:
git worktree remove .worktrees/STORY-XXX
git worktree remove .worktrees/STORY-YYY
# ... repeat for each story

# Or clean up all at once:
git worktree list | grep '.worktrees/' | awk '{print $1}' | xargs -I{} git worktree remove {}
```
```

## Key Points

- Each terminal runs its own independent `claude` session with `/implement`
- Cost is 1x per terminal session (same as sequential, just concurrent)
- Each worktree has its own feature branch — no merge conflicts during implementation
- The SDLC hooks (`sdlc-gate.sh`) work correctly per-worktree since they use `git rev-parse --show-toplevel`
- Stories in the same wave are independent by definition — no coordination needed

## Error Recovery

- If a worktree creation fails: report the error and skip that story (continue with others)
- If a terminal session fails mid-implementation: the worktree and branch are preserved — just `cd` back in and resume
- If you need to abort: `git worktree remove .worktrees/STORY-XXX --force` per worktree

DO NOT implement any code. This command only sets up worktrees and prints instructions.
