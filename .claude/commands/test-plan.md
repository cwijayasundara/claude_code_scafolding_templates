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

## Step 4: Generate E2E Test Scenarios (if frontend/fullstack)

For stories with UI components, generate Playwright E2E test scenarios:

```markdown
### E2E Tests (Playwright)

| ID | Scenario | User Journey | Assertions | Criteria |
|----|----------|-------------|------------|----------|
| E2E-001 | test_<user_journey>_<expected> | Navigate to X → Fill Y → Click Z | Page shows success | AC-1 |
| E2E-002 | ... | ... | ... | AC-2 |
```

Each E2E scenario includes:
- **Pre-conditions**: what state the app must be in
- **Steps**: user actions (navigate, click, fill, select)
- **Assertions**: what the user should see (text, element, URL)
- **Cleanup**: any teardown needed

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
