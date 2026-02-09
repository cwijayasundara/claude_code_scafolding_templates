# /spike — Time-Boxed Exploration Mode

Start a time-boxed spike to explore a technical question, prototype an approach, or evaluate a library — without SDLC ceremony.

## Arguments
- `$ARGUMENTS` — Short description of what you're investigating (e.g., "evaluate Redis vs Memcached for caching")

## Phase 0: Set Up Spike Branch

1. Generate a spike ID: `SPIKE-NNN` (increment from highest existing spike branch, or start at `SPIKE-001`)
2. Create branch: `git checkout -b spike/SPIKE-NNN-<slugified-description>`
3. Announce time-box:
   > "Spike started. You have **2 hours** to explore. SDLC gates are suspended on this branch."
   > "When done, run `/spike wrap` to capture findings or discard."

## Phase 1: Explore Freely

- Write throwaway code, prototypes, benchmarks — no tests required
- SDLC gates (`sdlc-gate.sh`) are **suspended** on `spike/*` branches
- You MAY write to any file without requirements, backlog, or test plans
- **BLOCKED actions on spike branches:**
  - `/implement` — STOP: "Cannot implement on a spike branch. Convert findings to stories first."
  - `/pr` — STOP: "Cannot create PRs from spike branches. Run `/spike wrap` to capture findings."
  - `git merge spike/*` into any branch — blocked by `branch-guard.sh`
  - `gh pr create` — blocked by `branch-guard.sh`

## Phase 2: Wrap Up (`/spike wrap`)

When the user says "wrap up", "done", or runs `/spike wrap`:

1. **Summarize findings** in a markdown block:
   ```
   ## Spike: SPIKE-NNN — <description>
   ### Question
   <what we set out to learn>
   ### Findings
   <what we learned, with code snippets if useful>
   ### Recommendation
   <go/no-go decision, with rationale>
   ### Next Steps
   <if go: "Run /interview to capture as requirements" | if no-go: "Discard branch">
   ```

2. **Ask the user**:
   - **Convert to stories**: "Run `/interview` to turn these findings into requirements and stories."
   - **Discard**: Delete the spike branch (`git checkout main && git branch -D spike/SPIKE-NNN-...`)

3. **NEVER merge spike code directly** — spike branches are disposable. Production code goes through the full SDLC.
