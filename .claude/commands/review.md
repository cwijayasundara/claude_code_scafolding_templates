# /review — Review a Pull Request

Review the PR at $ARGUMENTS (PR number or URL).

## Steps

1. **Fetch the PR**:
   ```bash
   gh pr checkout $ARGUMENTS
   gh pr diff $ARGUMENTS
   ```

2. **Review against the 8-point checklist**:

   ### 1. SOLID Principles
   - Single Responsibility per class/module?
   - Open/Closed: extensible without modification?
   - Dependency Inversion: depends on abstractions?

   ### 2. Code Duplication
   - Any copy-paste code? Run: `jscpd --min-lines 5 src/`
   - Similar patterns that need a shared abstraction?

   ### 3. Hardcoded Values
   - Magic numbers, inline URLs, credentials?
   - All config from env vars or config files?

   ### 4. Test Coverage
   - All new functions have tests?
   - Edge cases and error conditions covered?
   - Coverage ≥ 80%?

   ### 5. Error Handling
   - All error paths handled?
   - Proper HTTP status codes + RFC 7807 format?
   - Errors logged with context?

   ### 6. Security
   - No secrets in code?
   - Input validation on external data?
   - No injection vulnerabilities?
   - Auth checks on protected endpoints?

   ### 7. Performance
   - No N+1 queries?
   - No blocking I/O in async context?
   - Efficient database queries?

   ### 8. Documentation
   - Public APIs have docstrings?
   - Complex logic explained?

3. **Post findings** as PR review comments:
   ```
   **[CRITICAL]** src/services/auth.py:45 — Password stored in plaintext
   Suggestion: Use passlib.hash.bcrypt to hash before storing

   **[WARNING]** src/routers/tasks.py:23 — Missing pagination limit cap
   Suggestion: Add max per_page=100 to prevent excessive queries

   **[SUGGESTION]** src/models/task.py:12 — Consider adding index on status column
   ```

4. **Summary**: Overall assessment (Approve / Request Changes / Comment)
