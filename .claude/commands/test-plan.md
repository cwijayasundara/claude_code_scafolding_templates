# /test-plan — Generate Test Plan from User Story

Read the user story at $ARGUMENTS.

Generate a comprehensive test plan that covers unit tests, integration tests, E2E tests, and test data requirements.

## Step 1: Analyze the Story

1. Read the story's **Acceptance Criteria** (Given/When/Then)
2. Read the story's **Dependencies** section to understand integration points
3. Read the story's **Expertise** tag to determine test scope:
   - `backend` → unit + integration tests, API contract tests
   - `frontend` → unit + integration + E2E tests (Playwright)
   - `fullstack` → all test types
   - `infra` → integration + smoke tests
   - `data` → unit + integration tests

## Step 2: Generate Unit Test Cases

For each acceptance criterion, generate test cases:

```markdown
### Unit Tests

| ID | Test Case | Input | Expected Output | Criteria |
|----|-----------|-------|-----------------|----------|
| UT-001 | test_<what>_<when>_<expected> | Description of input | Expected result | AC-1 |
| UT-002 | ... | ... | ... | AC-1 |
| UT-003 | ... | ... | ... | AC-2 |
```

Include:
- **Happy path**: normal/expected inputs for each criterion
- **Edge cases**: boundary values, empty inputs, max lengths
- **Error cases**: invalid inputs, missing required fields, unauthorized access
- **Each acceptance criterion** must map to at least 2 test cases (happy + error)

## Step 3: Generate Integration Test Cases

Identify integration points from the story (API calls, database queries, external services):

```markdown
### Integration Tests

| ID | Test Case | Components | Setup Required | Criteria |
|----|-----------|------------|----------------|----------|
| IT-001 | test_<what>_<when>_<expected> | API + DB | Test DB seeded | AC-1 |
| IT-002 | ... | ... | ... | AC-2 |
```

## Step 4: Generate E2E Test Scenarios (MANDATORY for frontend/fullstack)

For stories with `frontend` or `fullstack` expertise tag, you MUST generate Playwright E2E test scenarios. This is NOT optional — skipping this step blocks implementation.

### Step 4a: E2E Scenario Table

```markdown
### E2E Tests (Playwright)

| ID | Scenario | User Journey | Assertions | Criteria |
|----|----------|-------------|------------|----------|
| E2E-001 | test_<user_journey>_<expected> | Navigate to X → Fill Y → Click Z | Page shows success | AC-1 |
| E2E-002 | ... | ... | ... | AC-2 |
```

Each E2E scenario MUST include:
- **Pre-conditions**: what state the app must be in
- **Steps**: user actions (navigate, click, fill, select)
- **Assertions**: what the user should see (text, element, URL)
- **Cleanup**: any teardown needed
- **Selectors**: list of `data-testid` attributes the test will target

### Step 4b: Playwright Test Skeleton (MANDATORY)

For each E2E scenario in the table, generate a ready-to-implement Playwright test skeleton in the test plan. This skeleton is what the test-writer agent will use during `/implement` Phase 1.

```markdown
### Playwright Test Skeletons

#### E2E-001: test_<user_journey>_<expected>
\`\`\`python
import pytest
from playwright.async_api import Page, expect

BASE_URL = "http://localhost:3000"

@pytest.mark.e2e
async def test_<user_journey>_<expected>(page: Page):
    """Given <pre-condition>, when <user actions>, then <expected>."""
    # Setup
    await page.goto(f"{BASE_URL}/<path>")

    # Action
    await page.fill("[data-testid=<field>]", "<value>")
    await page.click("[data-testid=<button>]")

    # Assertion
    await expect(page.locator("[data-testid=<result>]")).to_be_visible()
    await expect(page.locator("[data-testid=<result>]")).to_contain_text("<expected text>")
\`\`\`

#### Required `data-testid` attributes
| Component | Selector | Purpose |
|-----------|----------|---------|
| <Component> | `data-testid="<name>"` | Target for E2E test |
```

**CRITICAL**: The skeletons MUST use Playwright's `page` API (`page.goto`, `page.fill`, `page.click`, `expect`). Static file analysis (reading `.tsx` source and checking for string patterns) is NOT a valid E2E test.

### Step 4c: Frontend Component Tests (MANDATORY for React)

For React components, generate component-level test scenarios using `@testing-library/react`:

```markdown
### Component Tests (React Testing Library)

| ID | Component | Renders | Interactions | Assertions | Criteria |
|----|-----------|---------|-------------|------------|----------|
| CT-001 | <ComponentName> | With props X | Click button Y | Shows text Z | AC-1 |
```

These are unit-level tests for individual React components, distinct from E2E tests:
- Use `render()` from `@testing-library/react` — NOT Python file reading
- Use `screen.getByTestId()`, `screen.getByRole()` for assertions
- Use `userEvent` or `fireEvent` for interactions
- Test file: `frontend/src/components/<Component>.test.tsx` or `tests/unit/test_<component>.tsx`

## Step 5: Define Test Data Requirements

```markdown
### Test Data

#### Factories (factory-boy)
| Factory | Model | Key Fields | Notes |
|---------|-------|------------|-------|
| UserFactory | UserCreate | email, password, name | Sequence for unique emails |
| ... | ... | ... | ... |

#### Fixtures (conftest.py)
| Fixture | Returns | Scope | Notes |
|---------|---------|-------|-------|
| sample_user | User | function | Created via UserFactory |
| authenticated_client | TestClient | function | Logged in with sample_user |
| ... | ... | ... | ... |

#### Seed Data (integration/E2E)
| Dataset | Records | Purpose |
|---------|---------|---------|
| test_users | 5 users with different roles | Role-based access testing |
| ... | ... | ... |
```

## Step 6: Write the Test Plan File

Save the test plan to `docs/test-plans/[story-id]-test-plan.md` with this structure:

```markdown
# Test Plan: [STORY-ID] — [Story Title]

## Story Reference
- Story: docs/backlog/[epic]/[story-id].md
- Expertise: [tag]
- Dependencies: [list]

## Test Summary
| Type | Count | Coverage Target |
|------|-------|-----------------|
| Unit | N | >= 80% |
| Integration | N | Key flows |
| E2E | N | Critical user journeys |

## Unit Tests
[Table from Step 2]

## Integration Tests
[Table from Step 3]

## E2E Tests
[Table from Step 4 — if applicable]

## Test Data
[From Step 5]

## Mocking Strategy
| Boundary | Mock Type | Used In |
|----------|-----------|---------|
| External API | httpx mock / respx | Unit, Integration |
| Database | SQLite in-memory | Unit |
| Filesystem | tmp_path fixture | Unit |
| LLM provider | Mock response | Unit |

## Playwright Configuration (if E2E)
- Base URL: `${STAGING_URL}` or `http://localhost:8000`
- Browser: chromium (default)
- MCP Server: `@playwright/mcp@latest` configured in `.mcp.json`
- Screenshots: on failure
- Trace: on first retry
```

## Step 7: Verify Traceability

Every acceptance criterion must be covered by at least one test case.
Print a traceability matrix:

```
Acceptance Criteria → Test Coverage:
  AC-1: UT-001, UT-002, IT-001, E2E-001 ✓
  AC-2: UT-003, IT-002 ✓
  AC-3: UT-004, E2E-002 ✓
```

If any criterion has zero tests → add test cases until covered.

DO NOT write test code. This generates the test PLAN only. The test-writer agent uses this plan during `/implement` Phase 1 (RED).
