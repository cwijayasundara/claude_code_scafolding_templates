---
name: testing
description: TDD Red-Green-Refactor workflow, pytest fixtures and markers, factory pattern, mock-at-boundaries strategy, and coverage requirements
---

# Skill: Testing

## When to Use
Apply this skill when writing tests, setting up test infrastructure, or debugging test failures.

## TDD Workflow (Red → Green → Refactor)

### Red Phase (test-writer sub-agent)
1. Read the story's acceptance criteria
2. Write failing tests that encode each acceptance criterion
3. Include happy path, edge cases, and error conditions
4. Verify all tests FAIL before proceeding
5. Commit: `test: add failing tests for STORY-XXX`

### Green Phase (main agent)
1. Read the failing tests
2. Implement MINIMUM code to make tests pass
3. No extra features, no premature optimization
4. Run tests after each file change
5. All pass → commit: `feat: implement STORY-XXX`

### Refactor Phase (main agent)
1. Extract duplication to shared modules
2. Improve naming and structure
3. Enforce SOLID principles
4. Apply CLAUDE.md Pre-Completion Checklist (all 10 items)
5. Run full `make ci` — all must pass
6. Commit: `refactor: clean up STORY-XXX implementation`

## Test Categories & Markers

| Marker | Directory | What It Tests | Speed |
|--------|-----------|---------------|-------|
| `@pytest.mark.unit` | `tests/unit/` | Business logic with mocked deps | Fast (<1s) |
| `@pytest.mark.integration` | `tests/integration/` | Full stack with test DB | Medium (<5s) |
| `@pytest.mark.e2e` | `tests/e2e/` | User journeys on deployed app | Slow (<30s) |
| `@pytest.mark.smoke` | `tests/smoke/` | Health checks on deployed app | Fast (<2s) |
| `@pytest.mark.perf` | `tests/perf/` | Load/stress testing | Slow (minutes) |

## Shared Fixtures (MUST follow)

Extract to `tests/conftest.py` when the same setup appears in 3+ test files.

**BAD — duplicated setup in every test file:**
```python
# tests/unit/test_service_a.py
def test_something():
    settings = Settings(api_key="test-key", db_url="sqlite:///:memory:")
    ...

# tests/unit/test_service_b.py
def test_other():
    settings = Settings(api_key="test-key", db_url="sqlite:///:memory:")
    ...
```

**GOOD — shared fixture in conftest.py:**
```python
# tests/conftest.py
@pytest.fixture
def settings():
    return Settings(api_key="test-key", db_url="sqlite:///:memory:")

# tests/unit/test_service_a.py
def test_something(settings):
    ...  # settings injected by pytest
```

### Common Fixtures to Create
- `settings` — pre-configured Settings instance with test values
- `tmp_output` — temporary directory for file output tests (use `tmp_path`)
- `mock_external_api` — pre-configured mock for external API calls
- `sample_data` — representative test data for the domain

## Fixture Patterns

### Database Fixture (auto-rollback)
```python
@pytest.fixture
async def db_session(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSession(engine) as session:
        yield session
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

### Authenticated Client Fixture
```python
@pytest.fixture
async def authenticated_client(client, sample_user):
    # Register + login, return client with Authorization header
    ...
```

### Factory Pattern (factory-boy)
Use factories for creating test data with sensible defaults:
```python
class UserFactory(factory.Factory):
    class Meta:
        model = UserCreate
    email = factory.Sequence(lambda n: f"user{n}@test.com")
    password = "SecurePass123!"
    name = factory.Faker("name")
```

## Mock-at-Boundaries Strategy
- Unit tests: mock external dependencies (APIs, databases, filesystem, network)
- Integration tests: use real internal components, mock only external services
- E2E tests: no mocks, test against real deployed service
- NEVER mock the thing you're testing

**Typical boundaries to mock:**
| Boundary | What to mock | Example |
|----------|-------------|---------|
| External API | HTTP client / SDK | `patch("src.client.requests.get")` |
| Database | Repository / session | `MagicMock(spec=UserRepository)` |
| Filesystem | File I/O | `tmp_path` fixture, `patch("builtins.open")` |
| LLM provider | Chat model | `patch("src.llm.init_chat_model")` |
| Time | datetime.now | `patch("src.module.datetime")` |

## Test Quality Rules
- **Descriptive names**: `test_<what>_<when>_<expected>` — not `test_1` or `test_happy`
- **One concept per test**: test one behavior, assert one outcome
- **No test duplication**: shared setup goes in conftest.py
- **Test error paths**: every try/except in production code needs a test that triggers the except branch
- **No hardcoded test data in assertions**: use variables or fixtures, not inline magic values

## Coverage Requirements
- Minimum 80% line coverage (enforced by CI)
- Focus coverage on business logic (services), not boilerplate
- Use `# pragma: no cover` sparingly and only for truly unreachable code

## Running Tests
```bash
make test-unit          # Fast, mocked, runs on every change
make test-integration   # Full stack, test DB, runs in CI
make test-e2e           # Against deployed app, needs STAGING_URL
make test-smoke         # Quick health checks, needs BASE_URL
make test-perf          # Load testing, needs target URL
make test               # Unit + integration (default CI suite)
```
