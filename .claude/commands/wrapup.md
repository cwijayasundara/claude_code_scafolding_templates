# /wrapup — Session Completion

End-of-session ceremony. Commit changes, validate, and provide a handoff summary for the next session.

## Steps

1. **Check for uncommitted work**:
   - Run `git status` to identify modified, staged, and untracked files
   - If there are uncommitted changes, ask: "Commit these changes before wrapping up?"
   - If yes, stage relevant files and commit with an appropriate conventional commit message
   - Do NOT commit files that contain secrets (.env, credentials, API keys)

2. **Run CI validation**:
   - Run `make ci` to execute lint, typecheck, and tests
   - If CI fails:
     - Show the failures clearly
     - Ask: "Fix these issues before wrapping up, or note them for next session?"
     - If fixing, resolve the issues and re-run `make ci`
     - If deferring, record failures in the handoff summary

3. **Update story status**:
   - Identify which story file(s) were being worked on (from branch name or recent commits)
   - Update the story file's status section if applicable:
     - Mark completed acceptance criteria
     - Note any remaining work

4. **Push to remote**:
   - Check if the branch has an upstream: `git rev-parse --abbrev-ref @{upstream}`
   - If upstream exists: `git push`
   - If no upstream: `git push -u origin HEAD`
   - If push fails, report the error (do not force-push)

5. **Generate handoff summary**:
   ```
   ## Session Handoff

   **Date**: YYYY-MM-DD
   **Branch**: feature/STORY-XXX-description
   **Story**: STORY-XXX — Brief description

   ### What Was Done
   - [List of commits made this session with messages]
   - [Key decisions made]

   ### Current State
   - CI: PASS / FAIL (details if failing)
   - Tests: XX passing, YY failing
   - Coverage: XX%
   - Lint/Type: clean / N issues

   ### What's Next
   - [Remaining acceptance criteria not yet implemented]
   - [Known issues or TODOs discovered during this session]
   - [Suggested next action for the next session]

   ### Files Modified
   - `src/module.py` — added search endpoint
   - `tests/unit/test_module.py` — added 5 tests for search
   ```

6. **Suggest next session startup**:
   - "Next session, run `/gogogo` to pick up where you left off."
