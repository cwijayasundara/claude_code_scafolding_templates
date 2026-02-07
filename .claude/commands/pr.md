# /pr — Create Pull Request

Create a pull request for the current branch.

## Steps

1. **Validate** — Run `make ci`. Abort if anything fails.

2. **Generate PR description**:
   - Title: `[STORY-ID] Brief description` (under 70 chars)
   - Body:
     ```
     ## Summary
     - What changed and why (1-3 bullet points)

     ## Story
     Link to the user story file in docs/backlog/

     ## Changes
     - List each changed file with a brief explanation

     ## Tests
     - List tests added/modified
     - Coverage percentage for new code

     ## Checklist
     - [ ] Tests pass (`make ci`)
     - [ ] Coverage ≥ 80%
     - [ ] No lint/type errors
     - [ ] No hardcoded values
     - [ ] Follows SOLID principles
     - [ ] Public APIs documented
     ```

3. **Push and create PR**:
   ```bash
   git push -u origin HEAD
   gh pr create --title "[STORY-ID] description" --body-file /tmp/pr-desc.md --base main
   ```

4. **Request reviewers** per CODEOWNERS (if configured)

5. **Output** the PR URL for the engineer to share
