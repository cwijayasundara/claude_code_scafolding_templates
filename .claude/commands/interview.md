# /interview — Requirements Gathering

You are conducting a structured requirements interview to produce a focused requirements document. The user has an idea for a feature or project but may not have written formal requirements yet.

## Mode Detection

Read `SDLC_MODE` from `.claude/settings.json` → `env` block (default: `"full"`).

| Aspect | Full Mode | Lite Mode |
|--------|-----------|-----------|
| Questions | 5-8 total (3 phases) | 2-4 total (1 phase) |
| Output sections | 7 sections | 3 sections |
| Min output lines | >= 10 lines | >= 5 lines |
| Required sections | >= 2 of 4 | >= 1 of 4 |

---

## Full Mode Process (SDLC_MODE = "full")

### Phase 1: Understand the Vision (1-3 questions)
Ask about:
- What problem does this solve? Who is the user?
- What does success look like? How will they know it's working?
- Are there existing systems this needs to integrate with?

### Phase 2: Clarify Scope (2-4 questions)
Ask about:
- What are the must-have capabilities vs nice-to-haves?
- What are the constraints (timeline, tech stack, team size)?
- Are there any known technical risks or unknowns?
- What should this NOT do? (anti-requirements)

### Phase 3: Define Quality Attributes (1-2 questions)
Ask about:
- Performance requirements (latency, throughput, scale)
- Security and compliance requirements
- Availability and reliability expectations

### Full Mode Rules
- Ask ONE question at a time using the AskUserQuestion tool
- After each answer, decide if you need to go deeper or move to the next phase
- Keep the total interview to 5-8 questions (adapt based on complexity)
- If the user says "that's enough" or similar, wrap up immediately

### Full Mode Output
When the interview is complete, synthesize the answers into a requirements document:
1. Write to `docs/requirements.md` (or `$ARGUMENTS` if a path was given)
2. Format:
   - **Problem Statement**: 2-3 sentences
   - **Target Users**: who benefits
   - **Functional Requirements**: numbered list of capabilities
   - **Non-Functional Requirements**: performance, security, reliability
   - **Constraints**: tech stack, timeline, integration points
   - **Out of Scope**: explicit anti-requirements
   - **Open Questions**: anything still unclear
3. Tell the user: "Requirements captured. Run `/decompose docs/requirements.md` to break these into stories."

---

## Lite Mode Process (SDLC_MODE = "lite")

### Single Phase: Core Requirements (2-4 questions)
Ask about:
- What problem does this solve and what are the must-have capabilities?
- Who is the user and what does success look like?
- What are the constraints (tech stack, timeline, known risks)?
- _(Optional)_ What should this NOT do?

### Lite Mode Rules
- Ask ONE question at a time using the AskUserQuestion tool
- Keep the total interview to 2-4 questions — move fast
- If the user says "that's enough" or similar, wrap up immediately

### Lite Mode Output
When the interview is complete, synthesize the answers into a compact requirements document:
1. Write to `docs/requirements.md` (or `$ARGUMENTS` if a path was given)
2. Format (3 sections minimum):
   - **Problem Statement**: 2-3 sentences
   - **Functional Requirements**: numbered list of capabilities
   - **Constraints**: tech stack, timeline, known risks
3. Tell the user: "Requirements captured. Run `/decompose docs/requirements.md` to break these into stories."

---

DO NOT implement any code. Requirements gathering only.
