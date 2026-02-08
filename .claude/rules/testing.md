# Testing Rules

Applies to: `tests/**/*.py`, `tests/**/*.ts`, `tests/**/*.tsx`

## TDD Workflow
- Every user story must have tests BEFORE implementation (TDD)
- Unit test coverage minimum: 80%

## Test Quality Standards
- Shared fixtures: if the same setup appears in 3+ test files, extract to `tests/conftest.py`
- BAD: every test file creates `Settings(api_key="test-key")` independently
- GOOD: `@pytest.fixture` in conftest.py -> `def settings(): return Settings(api_key="test-key")`
- Descriptive test names: `test_<what>_<when>_<expected>` (e.g., `test_login_with_invalid_password_returns_401`)
- One logical assertion per test — test one behavior, not five
- Mock at boundaries (external APIs, databases, filesystem) — never mock the thing you're testing
- Test error paths: every try/except in production code needs a test that triggers the except branch
- No hardcoded test data in assertions: use variables or fixtures, not inline magic values

## Helper Functions MUST Have Tests (MANDATORY)
- Every function in `utils/`, `helpers/`, or `lib/` directories MUST have dedicated unit tests
- Extracted helper functions must be tested independently — not just indirectly via callers
- BAD: `format_date()` is used in 5 places but has no dedicated tests — only tested indirectly
- GOOD: `test_format_date.py` (or `test_utils.py`) with explicit tests for `format_date()`
- BAD: `createApiClient()` helper used across services but only tested through service tests
- GOOD: `createApiClient.test.ts` with tests for error handling, timeout, retry logic

### Python
- All functions in `src/**/utils.py`, `src/**/helpers.py` → tests in `tests/unit/test_utils.py` (or per-module)
- All functions in `src/**/lib/` → corresponding tests in `tests/unit/`

### TypeScript
- All functions in `src/utils/`, `src/helpers/`, `src/lib/` → tests in `src/**/*.test.ts` or `tests/`
- Custom React hooks in `src/hooks/` → tests using `renderHook` from `@testing-library/react`

## Test File Size
- Test files may exceed 500 lines if well-organized with section comments separating test groups
- Split test files at 700+ lines into logical sub-files (e.g., `test_user_creation.py`, `test_user_update.py`)
- Use section comments to organize: `# --- Authentication Tests ---`, `# --- Validation Tests ---`

## Pre-Completion Checklist (for test files)
- Is setup duplicated across files? -> Extract to conftest.py
- Are test names descriptive? -> Follow `test_<what>_<when>_<expected>` pattern
- Does each test assert one behavior? -> Split multi-assertion tests
- Do all helper functions in `utils/`/`helpers/` have dedicated unit tests? -> Add them
