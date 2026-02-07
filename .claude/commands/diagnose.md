# /diagnose — Diagnose Test Failures

Read the test failure reports at $ARGUMENTS.

For each failure:

1. **Identify** the failing test and its assertion
2. **Trace** the failure to root cause in the codebase
3. **Classify** the failure:
   - `code_bug` — Logic error in source code
   - `config_issue` — Wrong environment variable or config
   - `schema_drift` — Implementation doesn't match OpenAPI spec
   - `perf_regression` — Response time exceeds threshold
   - `env_issue` — Infrastructure or environment problem

4. **If code_bug, schema_drift, or perf_regression**:
   - Create a hotfix branch: `hotfix/[test-name]-[date]`
   - Apply the minimal fix
   - Run the relevant tests locally to verify the fix
   - Run `make ci` for full validation
   - Create a PR with:
     - Root cause analysis
     - Fix explanation
     - Link to failing test report
     - Test verification results

5. **If config_issue or env_issue**:
   - Create a GitHub issue with:
     - Full diagnosis and evidence
     - Affected endpoints/services
     - Suggested remediation steps
     - Tag as "infrastructure"
     - Assign to DevOps team

6. **Output** a summary table:
   | Test | Classification | Action | Status |
   |------|---------------|--------|--------|
   | test_login_flow | code_bug | Hotfix PR #123 | Fixed |
   | test_health | env_issue | Issue #456 | Escalated |
