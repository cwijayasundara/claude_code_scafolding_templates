# Git Workflow Rules

## Branching
- Branch naming: `feature/STORY-123-short-description`
- One story per branch, one PR per story
- Squash merge to main

## Commits
- Use conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- Commit message describes the "why", not the "what"
- TDD commits follow the pattern:
  1. `test: add failing tests for STORY-XXX` (Red phase)
  2. `feat: implement STORY-XXX` (Green phase)
  3. `refactor: clean up STORY-XXX implementation` (Refactor phase)
