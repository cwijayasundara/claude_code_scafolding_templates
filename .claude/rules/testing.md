# Testing Rules

Applies to: `tests/**/*.py`

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

## Pre-Completion Checklist (for test files)
- Is setup duplicated across files? -> Extract to conftest.py
- Are test names descriptive? -> Follow `test_<what>_<when>_<expected>` pattern
- Does each test assert one behavior? -> Split multi-assertion tests
