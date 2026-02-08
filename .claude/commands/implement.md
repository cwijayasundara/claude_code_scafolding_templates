# /implement — TDD Implementation Cycle

Read the user story at $ARGUMENTS.

Follow the TDD Red → Green → Refactor cycle:

## Phase 1: RED (Failing Tests)
1. Read the story's acceptance criteria
2. Read the test plan at `docs/test-plans/[story-id]-test-plan.md`
   - If the test plan does NOT exist, generate it first: run `/test-plan [story-file]`
3. Spawn the test-writer sub-agent to write failing tests:
   - Unit tests in `tests/unit/` (mock external dependencies)
   - Integration tests in `tests/integration/` (real components, mock external APIs)
   - Use the test plan's **Test Data** section to create factories and fixtures
4. If the story has `frontend` or `fullstack` expertise tag:
   - Write E2E test scripts in `tests/e2e/` using Playwright
   - Use the test plan's **E2E Tests** section for scenarios
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
5. Verify ALL new tests FAIL (they must — no implementation yet)
6. Commit: `test: add failing tests for [STORY-ID]`

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
13. Run full CI: `make ci`
14. ALL must pass. If anything fails, fix it.
15. Commit: `refactor: clean up [STORY-ID] implementation`

## Phase 4: VALIDATE
1. Run `make ci` one final time
2. Verify coverage ≥ 80% for new code
3. Verify no lint or type errors
4. Verify Pre-Completion Checklist from CLAUDE.md (all 10 items) is satisfied
5. Ready for PR — run `/pr` when done
