# /decompose — Requirements Decomposition

Read the requirements document at $ARGUMENTS.

1. Identify capability areas → create Epics
2. For each Epic, create User Stories (INVEST criteria):
   - Independent, Negotiable, Valuable, Estimable, Small, Testable
3. For each Story:
   - Title: As a [role], I want [capability], so that [benefit]
   - Acceptance Criteria: Given/When/Then (min 3 per story)
   - Story Points: Fibonacci (1, 2, 3, 5, 8)
   - Dependencies: which other stories must complete first
   - Expertise tag: backend / frontend / fullstack / infra / data
4. Generate dependency graph (Mermaid) → docs/backlog/dependency-graph.mmd
5. Generate implementation order → docs/backlog/implementation-order.md
   Using: foundation → infrastructure → contracts → core → integration → UI
6. Output stories to docs/backlog/[epic-name]/[story-id].md

DO NOT implement any code. Planning only.
