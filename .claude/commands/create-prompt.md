# /create-prompt — Structured Prompt Builder

Build a high-quality system prompt using the R.G.C.O.A. framework (Role, Goal, Context, Output, Audience).

Useful when writing system prompts for LangGraph agents, Claude tool_use calls, or any LLM-powered component.

## Steps

1. **Gather requirements** — Ask the user these questions one at a time. If the user provides $ARGUMENTS, use it as the initial description and infer what you can before asking.

   ### R — Role
   > "What role should the AI play? (e.g., senior backend engineer, research analyst, customer support agent)"
   - Establish expertise level and domain
   - Include relevant constraints (e.g., "You are a Python expert who follows PEP 8")

   ### G — Goal
   > "What is the primary task or goal? What does success look like?"
   - Define the specific outcome expected
   - Include measurable criteria if possible (e.g., "produce a summary under 200 words")

   ### C — Context
   > "What context does the AI need? (e.g., available tools, data sources, constraints, prior conversation)"
   - List available tools, APIs, or data the AI can access
   - Specify what the AI should NOT do (negative constraints)
   - Include domain-specific terminology or rules

   ### O — Output
   > "What format should the output be in? (e.g., JSON, markdown, code block, structured report)"
   - Define the exact structure: fields, sections, format
   - Provide an example of ideal output if possible
   - Specify length constraints

   ### A — Audience
   > "Who will consume this output? (e.g., end users, other agents, developers, API callers)"
   - Adjust tone and technical level accordingly
   - Specify any accessibility or i18n requirements

2. **Draft the prompt** — Assemble the answers into a structured system prompt:

   ```
   # Role
   You are [role] with expertise in [domain].

   # Goal
   Your task is to [goal]. Success means [criteria].

   # Context
   You have access to: [tools/data]
   Constraints: [what NOT to do]
   Domain rules: [specific rules]

   # Output Format
   Respond in [format] with the following structure:
   [structure/example]

   # Audience
   Your output will be consumed by [audience]. Use [tone] and [technical level].
   ```

3. **Review and refine**:
   - Check for ambiguity — every instruction should have one interpretation
   - Check for completeness — are edge cases addressed?
   - Check for conflicts — do any instructions contradict each other?
   - Verify the prompt follows our precedence rules: Security > Error handling > Code style

4. **Output the final prompt**:
   - Present the complete prompt in a code block
   - Suggest where to place it (e.g., `src/agent/prompts.py` as a constant, or in a LangGraph node)
   - If the prompt will be used in a LangGraph agent, remind the user to define it as an `UPPER_SNAKE_CASE` constant per our code-style rules
