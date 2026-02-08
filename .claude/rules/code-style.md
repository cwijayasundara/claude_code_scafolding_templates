# Code Style Rules

Applies to: `**/*.py`, `**/*.ts`, `**/*.tsx`

## Structure & Size
- Max function length: 50 lines. Max file length: 500 lines
- Test files may exceed 500 lines if well-organized with section comments separating test groups; split at 700+ lines
- All public functions must have docstrings/JSDoc
- Single Responsibility: each function does ONE thing
- BAD: a `main()` that parses args, loads config, initializes services, runs logic, AND prints output
- GOOD: split into `parse_args()`, `build_config()`, `run_pipeline()`, `main()` — each does one thing

## No Hardcoded Values
- NEVER use magic numbers or magic strings inline — extract to named constants
- BAD: `return slug[:80]`
- GOOD: `MAX_SLUG_LENGTH = 80` then `return slug[:MAX_SLUG_LENGTH]`
- BAD: `("user", f"Do something...")`
- GOOD: `ROLE_USER = "user"` then `(ROLE_USER, f"Do something...")`
- BAD: `now.strftime("%Y-%m-%d")` used in multiple places
- GOOD: `DATE_FORMAT = "%Y-%m-%d"` then `now.strftime(DATE_FORMAT)`
- All config values come from Settings, env vars, or config files — never from literals in business logic

## No Code Duplication
- If you construct the same object with similar args in 2+ places, extract a helper function
- BAD: copy-pasting `Settings(api_key="test-key")` in every test file
- GOOD: shared `@pytest.fixture` in `tests/conftest.py` that all test files use
- BAD: two functions with identical logic but different parameter names
- GOOD: one function with parameters, called from both places

## No Dead Code (MANDATORY)
- No unused imports, variables, or functions — delete them, don't comment them out
- No commented-out code — use git history to recover old code if needed
- No placeholder functions with `pass`, empty stubs, or `// TODO` implementations that do nothing

### Python
- BAD: `import os` when `os` is never used
- BAD: `# result = old_function(data)` — commented-out call left in source
- BAD: `def process_legacy(data): pass` — empty stub never called
- GOOD: Remove unused imports, delete dead functions, use git to find old code

### TypeScript / React
- BAD: `import { useState } from 'react'` when `useState` is never used
- BAD: `const oldHandler = () => { /* deprecated */ }` — dead function left in source
- BAD: `// const result = await fetchData(id);` — commented-out code
- GOOD: Remove unused imports, delete dead components, enable `noUnusedLocals` in tsconfig
- Enable `noUnusedLocals` and `noUnusedParameters` in `tsconfig.json` to catch dead code at compile time

## Constants
- All literal values used as identifiers, limits, formats, or configuration MUST be named constants
- Define constants at module level, UPPER_SNAKE_CASE
- BAD: `if retries > 3:` / `role = "admin"` / `timeout = 30`
- GOOD: `MAX_RETRIES = 3` / `ROLE_ADMIN = "admin"` / `DEFAULT_TIMEOUT_SECONDS = 30`

## Type Safety
- Full type hints on all function signatures (Python) or strict TypeScript
- NEVER use `Any` as a return type — use the specific type, a Union, or a Protocol
- BAD: `def create_agent(llm, tools) -> Any:`
- GOOD: `def create_agent(llm: BaseChatModel, tools: list[BaseTool]) -> CompiledGraph:`
- BAD: `def process(data):` (no type hints)
- GOOD: `def process(data: dict[str, str]) -> ProcessResult:`

## Recommendations (SHOULD)
- Prefer composition over inheritance
- Dependency injection for testability — accept dependencies as parameters, don't construct them inline
- Cyclomatic complexity under 10 per function
- Name by intent, not implementation (e.g., `calculate_shipping_cost` not `do_math`)
- Prefer early returns over deep nesting
