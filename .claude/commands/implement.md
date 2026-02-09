# /implement — TDD Implementation Cycle

Read the user story at $ARGUMENTS.

## Phase 0: Pre-flight Verification

Before starting TDD, verify ALL prerequisites are met:

1. **Requirements content check**: Read `docs/requirements.md` — verify it has >= 10 lines and at least 2 of these sections: `## Problem Statement`, `## Functional Requirements`, `## Target Users`, `## Non-Functional Requirements`. If it's a stub or missing, STOP and run `/interview`.
2. **Story content check**: Read the story file — verify it has >= 8 lines and includes `## User Story` or `## Acceptance Criteria` + `## Dependencies` headings. If it's a stub, STOP and run `/decompose`.
3. **Test plan check**: Check if `docs/test-plans/[story-id]-test-plan.md` exists. If not, run `/test-plan [story-file]` before proceeding.
4. **Feature branch check**: Verify you are on a `feature/*` branch. If on main/master, create one: `git checkout -b feature/STORY-XXX-short-description`.
5. **Dependency check**: Read the story's `## Dependencies` section. Verify ALL stories in `depends_on:` are Done. If any are not Done, STOP and report which dependencies are blocking.
6. **Asset dependency check**: If the story has an `## Asset Dependencies` section, scan the table for any row with status `missing`. If ANY asset is missing, STOP and report: "Blocked by missing assets: [list]. Provide the assets or remove them from the story before implementing."
7. **Agent Teams check**: Read `AGENT_TEAMS_ENFORCE` from `.claude/settings.json` env block. If `"true"`, check if this story is in a wave with 2+ Ready stories in `docs/backlog/parallel-batches.md`. If yes, STOP and redirect: "This story is in a multi-story wave. Use `/parallel-implement wave-N` instead."

All checks must pass before proceeding to Phase 1.

## Phase 1: RED (Failing Tests)
1. Read the story's acceptance criteria
2. Read the test plan at `docs/test-plans/[story-id]-test-plan.md`
   - If the test plan does NOT exist, generate it first: run `/test-plan [story-file]`
3. Spawn the test-writer sub-agent to write failing tests:
   - Unit tests in `tests/unit/` (mock external dependencies)
   - Integration tests in `tests/integration/` (real components, mock external APIs)
4. **Test data artifacts (MANDATORY)**: Read the test plan's **Test Data** section and create the actual code:
   - **Factories**: If the test plan lists factories (factory-boy), create them in `tests/factories.py` or `tests/factories/`
   - **Fixtures**: If the test plan lists fixtures, add them to `tests/conftest.py` (shared) or the relevant test file
   - **Seed data**: If the test plan lists seed datasets for integration/E2E, create them in `tests/fixtures/` or as pytest fixtures
   - **GATE**: Do NOT proceed to step 5 until every factory, fixture, and seed dataset listed in the test plan exists as actual code
5. **E2E test scripts (MANDATORY for frontend/fullstack)**: Read the story's `## Expertise` tag.
   If the tag is `frontend` or `fullstack`:
   - You MUST write Playwright E2E test scripts in `tests/e2e/` — this is NOT optional
   - Use the test plan's **E2E Tests** section for scenarios
   - Each acceptance criterion with a UI component MUST have at least one E2E test
   - Playwright MCP server is configured in `.mcp.json` — use it to validate selectors and user flows
   - E2E test structure:
     ```python
     @pytest.mark.e2e
     async def test_<user_journey>_<expected>(page: Page):
         """Given <pre-condition>, when <user actions>, then <assertion>."""
         await page.goto(f"{BASE_URL}/path")
         await page.fill("[data-testid=field]", "value")
         await page.click("[data-testid=submit]")
         await expect(page.locator("[data-testid=result]")).to_be_visible()
     ```
   - **GATE**: Do NOT proceed to step 6 if expertise is `frontend` or `fullstack` and `tests/e2e/` has no test scripts (only `__init__.py` does NOT count)
6. Verify ALL new tests FAIL (they must — no implementation yet)
7. **RED phase artifact checklist** — verify before committing:
   - [ ] Unit test files exist in `tests/unit/` for this story
   - [ ] Integration test files exist in `tests/integration/` (if test plan has integration tests)
   - [ ] Test data factories/fixtures from the test plan are implemented as actual code
   - [ ] E2E test scripts exist in `tests/e2e/` (if expertise is `frontend` or `fullstack`)
   - If ANY item is missing, STOP and create it before proceeding
8. Commit: `test: add failing tests for [STORY-ID]`

## Phase 2: GREEN (Minimum Implementation)
1. Read the failing tests — they define EXACTLY what to implement
2. Write the MINIMUM code to make all tests pass
3. Do NOT add extra features, optimization, or gold-plating
4. Run tests after each file change to track progress
5. When ALL tests pass, commit: `feat: implement [STORY-ID]`

## Phase 3: REFACTOR (Clean Up)
Apply CLAUDE.md Pre-Completion Checklist to every file changed:
1. Extract any duplicated code to shared modules
2. Enforce Single Responsibility — if a function does 2+ things, split it
3. Improve naming — name by intent, not implementation
4. Extract all magic numbers and string literals to named constants (UPPER_SNAKE_CASE)
5. Add `logger = logging.getLogger(__name__)` to every module
6. Replace all `print()` with `logger.info()` or appropriate log level
7. Wire `log_level` config to `logging.basicConfig()` at startup if applicable
8. Add try/except around every external call (API, filesystem, network)
9. Ensure CLI entry points catch errors and show user-friendly messages
10. Ensure all return types are specific (no `Any`)
11. Ensure functions are ≤30 lines, files are ≤300 lines
12. Verify test fixtures are shared via conftest.py (no duplicated setup across files)
13. **Test data validation**: Re-read the test plan's **Test Data** section. For every factory, fixture, and seed dataset listed:
    - Verify the corresponding code exists (in `tests/conftest.py`, `tests/factories.py`, or `tests/fixtures/`)
    - If a factory/fixture is referenced in tests but not defined → create it
    - If a fixture is duplicated across test files → consolidate into `tests/conftest.py`
14. **E2E completeness check** (if expertise is `frontend` or `fullstack`):
    - Verify every acceptance criterion with a UI element has a corresponding E2E test in `tests/e2e/`
    - Verify E2E tests use `data-testid` selectors (not brittle CSS/XPath selectors)
    - Verify E2E tests have proper setup/teardown (login state, test data seeding, cleanup)
15. Run full CI: `make ci`
16. ALL must pass. If anything fails, fix it.
17. Commit: `refactor: clean up [STORY-ID] implementation`

## Phase 4: VALIDATE
1. Run `make ci` one final time
2. Verify coverage ≥ 80% for new code
3. Verify no lint or type errors
4. Verify Pre-Completion Checklist from CLAUDE.md (all 12 items) is satisfied
5. **Test artifact checklist** — ALL must be satisfied before PR:
   - [ ] Unit tests exist and pass for every new function/method
   - [ ] Integration tests exist and pass for every API endpoint / service boundary
   - [ ] Test data artifacts (factories, fixtures, seed data) from the test plan are implemented as code — not just documented in the plan
   - [ ] E2E Playwright test scripts exist in `tests/e2e/` with real assertions (if story expertise is `frontend` or `fullstack`)
   - [ ] E2E tests cover every acceptance criterion that has a user-facing UI element
   - [ ] `tests/conftest.py` has shared fixtures — no duplicated setup across test files
   - [ ] Traceability: every acceptance criterion in the story maps to at least one passing test
   - If ANY item is not satisfied, STOP and fix it before proceeding to `/pr`
6. Ready for PR — run `/pr` when done
