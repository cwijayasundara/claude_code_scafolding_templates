# /decompose — Requirements Decomposition

Read the requirements document at $ARGUMENTS.

1. Identify capability areas → create Epics
2. For each Epic, create User Stories (INVEST criteria):
   - Independent, Negotiable, Valuable, Estimable, Small, Testable
3. For each Story, generate a file with these MANDATORY sections:
   - **Title**: As a [role], I want [capability], so that [benefit]
   - **Acceptance Criteria**: Given/When/Then (min 3 per story)
   - **Story Points**: Fibonacci (1, 2, 3, 5, 8)
   - **Dependencies** (MANDATORY section — even if empty):
     - `depends_on: [STORY-XXX, STORY-YYY]` — stories that MUST be completed before this one can start
     - `blocks: [STORY-AAA, STORY-BBB]` — stories that cannot start until this one completes
     - If no dependencies: `depends_on: []` (explicitly state none)
     - Dependency reasons: for each dependency, explain WHY (e.g., "needs DB schema from STORY-001")
   - **Expertise tag**: backend / frontend / fullstack / infra / data
   - **Parallelization**: `can_parallel_with: [STORY-XXX]` — stories that share the same wave (auto-computed)

   Story file format:
   ```markdown
   # STORY-XXX: [Title]

   ## User Story
   As a [role], I want [capability], so that [benefit].

   ## Story Points: N

   ## Expertise: backend|frontend|fullstack|infra|data

   ## Dependencies
   - depends_on: [STORY-001, STORY-002]
   - blocks: [STORY-010]
   - Reason: Requires the user model from STORY-001 and the auth middleware from STORY-002

   ## Acceptance Criteria
   - Given ... When ... Then ...
   - Given ... When ... Then ...
   - Given ... When ... Then ...

   ## Asset Dependencies
   _External assets required before implementation can start. Omit section if none._

   | Asset | Type | Location | Status |
   |-------|------|----------|--------|
   | logo.svg | svg | src/assets/logo.svg | available |
   | Stripe API key | api_key | .env STRIPE_SECRET_KEY | missing |

   _Types: svg, api_key, design_mockup, sdk, data_file, other_
   _Statuses: available, missing — any `missing` item blocks implementation_
   ```

   **CRITICAL RULE**: Two stories that have a dependency relationship (direct or transitive) MUST NOT appear in the same parallel wave. The topological sort in step 7 enforces this — but verify it explicitly.
4. Generate dependency graph (Mermaid) → docs/backlog/dependency-graph.mmd
5. Generate implementation order → docs/backlog/implementation-order.md
   Using: foundation → infrastructure → contracts → core → integration → UI
6. Output stories to docs/backlog/[epic-name]/[story-id].md
7. Generate parallel execution batches → docs/backlog/parallel-batches.md
   - Perform topological sort on the dependency graph
   - Group stories into sequential "waves":
     - **Wave 1**: Stories with zero dependencies (foundation layer)
     - **Wave N**: Stories whose ALL dependencies are in waves 1..N-1
   - For each wave, output:
     - Wave number and story count
     - List of stories with: ID, title, story points, expertise tag
     - Total story points for the wave
     - Estimated parallel speedup (wave points / max single story points)
   - Format as a table per wave, e.g.:
     ```
     ## Wave 1 (Foundation) — 3 stories, 8 points
     | Story | Title | Points | Expertise | Dependencies |
     |-------|-------|--------|-----------|-------------|
     | STORY-001 | Set up project skeleton | 2 | infra | none |
     | STORY-002 | Define data models | 3 | backend | none |
     | STORY-003 | Create design system | 3 | frontend | none |

     ## Wave 2 — 2 stories, 5 points (requires Wave 1)
     ...
     ```
   - At the bottom, add a summary:
     ```
     ## Parallel Execution Summary
     | Wave | Stories | Points | Can Parallelize |
     |------|---------|--------|-----------------|
     | 1 | 3 | 8 | Yes (3 independent) |
     | 2 | 2 | 5 | Yes (2 independent) |
     | 3 | 1 | 5 | No (single story) |
     | **Total** | **6** | **18** | Sequential: 18pts, Parallel: ~10pts |
     ```

8. Generate test plans for each story → `docs/test-plans/[story-id]-test-plan.md`
   - For each story file created in step 6, run `/test-plan docs/backlog/[epic]/[story-id].md`
   - This generates test cases (unit, integration, E2E), test data requirements, and traceability matrix
   - The test-writer agent uses these plans during `/implement` Phase 1 (RED)
   - E2E test plans are generated for stories with `frontend` or `fullstack` expertise tags
   - Ensure `docs/test-plans/` directory is created

DO NOT implement any code. Planning and test planning only.
