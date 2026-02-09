# /gogogo — Session Startup

Start-of-session ceremony. Load project context, check environment, and present ready work.

## Steps

1. **Load project context**:
   - Read `CLAUDE.md` for project standards and commands
   - Read `docs/architecture.md` if it exists (for current architecture overview)
   - Identify the tech stack and active deployment target

2. **Check environment health**:
   - Run `git status` to check current branch, uncommitted changes, and upstream sync
   - Run `git log --oneline -5` to show recent commits
   - Check for unresolved merge conflicts
   - Verify dev dependencies are installed: `make build` (skip if lock file unchanged)

3. **Show ready work from backlog**:
   - List all story files in `docs/backlog/` (recursively)
   - Classify each story:
     - **Ready** — no blocking dependencies, not started
     - **In Progress** — has a feature branch or partial implementation
     - **Blocked** — depends on unfinished stories
     - **Done** — all acceptance criteria met, merged to main
   - Present the list sorted by priority (Ready first, then In Progress)

4. **Show parallel execution options** (primary path):
   - Check if `docs/backlog/parallel-batches.md` exists
   - If it does, read it and identify waves with 2+ Ready stories
   - For each parallelizable wave, show:
     - Wave number, story count, total story points
     - List of Ready stories in that wave
   - Suggest commands — agent teams first:
     - Check `AGENT_TEAMS_ENABLED` in `.claude/settings.json` env block
     - If agent teams enabled (default): "Run `/parallel-implement wave-N` to implement N stories in parallel with agent teams"
     - Fallback: "Run `/parallel-manual wave-N` to set up worktrees for manual parallel implementation"
   - If no waves have 2+ Ready stories, skip this section

5. **Check for in-progress work**:
   - List open feature branches: `git branch --list 'feature/*'`
   - For each, show last commit date and whether it has a PR open
   - Highlight any stale branches (no commits in 7+ days)

6. **Present session options**:
   - If there's an in-progress story with uncommitted work: "Resume work on [story]?"
   - If a wave has 2+ Ready stories: "Start wave N with `/parallel-implement wave-N`?" (primary suggestion)
   - If there's a single ready story at the top of the backlog: "Start [story] with `/implement`?"
   - If there's a PR awaiting review: "Review PR #[N] with `/review`?"
   - If no stories exist: "Let's capture your ideas — run `/interview` to turn them into requirements."

7. **Output a session summary**:
   ```
   ## Session Ready

   **Branch**: feature/STORY-XXX-description (3 ahead, 0 behind main)
   **Last commit**: feat: implement search endpoint (2h ago)
   **Uncommitted**: 2 modified files

   ### Backlog
   | Status | Story | Priority |
   |--------|-------|----------|
   | In Progress | STORY-XXX — Search API | P1 |
   | Ready | STORY-YYY — Filter UI | P1 |
   | Blocked | STORY-ZZZ — Analytics | P2 (blocked by STORY-XXX) |

   ### Parallel Options
   | Wave | Ready Stories | Points | Command |
   |------|-------------|--------|---------|
   | Wave 2 | STORY-YYY, STORY-AAA | 6 | `/parallel-implement wave-2` |

   ### Suggested Next Action
   > Wave 2 has 2 Ready stories — run `/parallel-implement wave-2` to implement in parallel.
   > Or run `/parallel-manual wave-2` for manual worktree setup.
   ```
