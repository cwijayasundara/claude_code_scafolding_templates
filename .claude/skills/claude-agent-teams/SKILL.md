---
name: claude-agent-teams
description: Claude Opus 4.6 agent teams, Anthropic API tool_use patterns, multi-agent orchestration, extended thinking, prompt caching, and Claude Agent SDK patterns
---

# Skill: Claude Opus 4.6 Agent Teams

## When to Use
Apply this skill when building multi-agent systems powered by Claude, using the Anthropic API directly or via Claude Agent SDK, or orchestrating Claude-based agents with LangGraph.

## Claude Model Selection

### Model IDs (Latest)
| Model | ID | Best For |
|-------|-----|----------|
| Opus 4.6 | `claude-opus-4-6` | Complex reasoning, multi-step planning, code generation |
| Sonnet 4.5 | `claude-sonnet-4-5-20250929` | Balanced speed + quality, default for most tasks |
| Haiku 4.5 | `claude-haiku-4-5-20251001` | Fast, low-cost, simple tasks, classification |

### When to Use Which
- **Opus 4.6**: Architect agent, complex analysis, code review, planning
- **Sonnet 4.5**: Implementation agents, standard tool use, most agentic tasks
- **Haiku 4.5**: Router/classifier agents, simple extractions, high-volume tasks

## Anthropic API — Tool Use

### Defining Tools
```python
from anthropic import Anthropic

client = Anthropic()

tools = [
    {
        "name": "search_codebase",
        "description": "Search the codebase for files matching a pattern or containing specific code.",
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search query — file pattern or code snippet to find",
                },
                "file_type": {
                    "type": "string",
                    "enum": ["python", "typescript", "yaml", "all"],
                    "description": "Filter results by file type",
                },
            },
            "required": ["query"],
        },
    },
]
```

**Rules:**
- Tool `description` is critical — Claude uses it to decide when to call the tool
- Use `enum` for parameters with fixed options
- Mark truly required params in `required`, leave optional ones out
- Input schema follows JSON Schema format

### Agentic Tool-Use Loop
```python
MAX_AGENT_TURNS = 25
AGENT_MODEL = "claude-opus-4-6"

def run_agent(system_prompt: str, user_message: str, tools: list[dict]) -> str:
    """Run a Claude agent with tool use until completion."""
    messages = [{"role": "user", "content": user_message}]

    for turn in range(MAX_AGENT_TURNS):
        response = client.messages.create(
            model=AGENT_MODEL,
            max_tokens=4096,
            system=system_prompt,
            tools=tools,
            messages=messages,
        )

        # If Claude is done (no more tool calls), return the text
        if response.stop_reason == "end_turn":
            return _extract_text(response)

        # Process tool calls
        messages.append({"role": "assistant", "content": response.content})
        tool_results = _execute_tool_calls(response.content)
        messages.append({"role": "user", "content": tool_results})

    logger.warning("Agent hit max turns (%d)", MAX_AGENT_TURNS)
    return _extract_text(response)


def _extract_text(response) -> str:
    """Extract text content from Claude response."""
    return "".join(
        block.text for block in response.content if block.type == "text"
    )


def _execute_tool_calls(content: list) -> list[dict]:
    """Execute tool calls and return results."""
    results = []
    for block in content:
        if block.type == "tool_use":
            result = dispatch_tool(block.name, block.input)
            results.append({
                "type": "tool_result",
                "tool_use_id": block.id,
                "content": str(result),
            })
    return results
```

## Extended Thinking

### Enable Extended Thinking for Complex Reasoning
```python
response = client.messages.create(
    model="claude-opus-4-6",
    max_tokens=16000,
    thinking={
        "type": "enabled",
        "budget_tokens": 10000,  # Tokens allocated for internal reasoning
    },
    messages=messages,
)

# Access thinking content (for debugging/logging)
for block in response.content:
    if block.type == "thinking":
        logger.debug("Claude thinking: %s", block.thinking)
    elif block.type == "text":
        final_answer = block.text
```

**When to enable:**
- Architecture decisions and trade-off analysis
- Multi-step planning and decomposition
- Complex debugging and root cause analysis
- Code review requiring deep understanding

**When NOT to enable:**
- Simple classifications or extractions
- High-throughput, low-latency tasks
- Haiku model (not supported)

## Multi-Agent Team Architecture

### Agent Roles Pattern
Define specialized agents with clear responsibilities:

```python
ARCHITECT_SYSTEM_PROMPT = """\
You are a software architect. Your role:
- Analyze requirements and design system architecture
- Create ADRs for key technical decisions
- Produce C4 diagrams (Mermaid format)
- Evaluate technology trade-offs

You do NOT write implementation code.
"""

IMPLEMENTER_SYSTEM_PROMPT = """\
You are a senior developer implementing features using TDD.
- Write failing tests first (Red phase)
- Implement minimum code to pass tests (Green phase)
- Refactor for clean code (Refactor phase)

Follow the project's CLAUDE.md code standards strictly.
"""

REVIEWER_SYSTEM_PROMPT = """\
You are a code reviewer. Review against this checklist:
1. SOLID principles
2. No code duplication
3. No magic numbers/strings
4. Error handling on all external calls
5. Logging with appropriate levels
6. Type hints on all functions
7. Tests cover happy + error paths
8. No security vulnerabilities
"""
```

### Orchestrator Pattern (Agent-of-Agents)
```python
ORCHESTRATOR_MODEL = "claude-opus-4-6"    # Smart orchestrator
WORKER_MODEL = "claude-sonnet-4-5-20250929"  # Efficient workers

def orchestrate_task(task_description: str) -> str:
    """Use Opus to plan, Sonnet to execute."""
    # Step 1: Opus plans the approach
    plan = run_agent(
        system_prompt=PLANNER_PROMPT,
        user_message=task_description,
        tools=planning_tools,
        model=ORCHESTRATOR_MODEL,
    )

    # Step 2: Sonnet executes each step
    results = []
    for step in parse_plan(plan):
        result = run_agent(
            system_prompt=IMPLEMENTER_PROMPT,
            user_message=step,
            tools=implementation_tools,
            model=WORKER_MODEL,
        )
        results.append(result)

    # Step 3: Opus reviews and synthesizes
    return run_agent(
        system_prompt=REVIEWER_PROMPT,
        user_message=format_results(results),
        tools=review_tools,
        model=ORCHESTRATOR_MODEL,
    )
```

### Cost Optimization
- Use **Haiku** for routing/classification (which agent should handle this?)
- Use **Sonnet** for most implementation work
- Use **Opus** only for planning, review, and complex reasoning
- This tiered approach reduces cost by 5-10x vs using Opus for everything

## Prompt Caching

### Enable Prompt Caching for System Prompts
```python
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=4096,
    system=[
        {
            "type": "text",
            "text": long_system_prompt,
            "cache_control": {"type": "ephemeral"},
        }
    ],
    messages=messages,
)
```

**When to use:**
- Long system prompts (>1000 tokens) reused across multiple calls
- Tool definitions that don't change between calls
- Large context documents passed repeatedly
- Saves up to 90% on input token costs for cached content

## Claude with LangGraph Integration

### Using Claude as LangGraph's LLM
```python
from langchain.chat_models import init_chat_model

# Claude via init_chat_model (recommended)
llm = init_chat_model("anthropic:claude-opus-4-6")

# Or direct ChatAnthropic
from langchain_anthropic import ChatAnthropic
llm = ChatAnthropic(model="claude-opus-4-6", temperature=0)
```

### Multi-Model LangGraph Agent Team
```python
# Different Claude models for different graph nodes
planner_llm = init_chat_model("anthropic:claude-opus-4-6")
worker_llm = init_chat_model("anthropic:claude-sonnet-4-5-20250929")
classifier_llm = init_chat_model("anthropic:claude-haiku-4-5-20251001")

# Wire into graph nodes
graph = StateGraph(TeamState)
graph.add_node("classify", create_react_agent(classifier_llm, [], CLASSIFIER_PROMPT))
graph.add_node("plan", create_react_agent(planner_llm, planning_tools, PLANNER_PROMPT))
graph.add_node("execute", create_react_agent(worker_llm, impl_tools, WORKER_PROMPT))
graph.add_node("review", create_react_agent(planner_llm, review_tools, REVIEWER_PROMPT))
```

## Claude Code Sub-Agents

### Defining Custom Sub-Agents
Sub-agents in `.claude/agents/` run in isolated contexts with restricted tool access:

```yaml
# .claude/agents/test-writer.yaml
name: test-writer
description: Writes failing tests from acceptance criteria (TDD Red phase)
model: claude-sonnet-4-5-20250929
tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
allowed_paths:
  write: ["tests/**"]
  read: ["**"]
instructions: |
  You are a test-writer agent. Read the story file and write failing tests.
  NEVER modify files in src/. Only write to tests/.
```

**Key patterns:**
- `allowed_paths.write` restricts where the agent can create/modify files
- `allowed_paths.read` allows reading the full codebase for context
- Each agent has a single responsibility
- Use Sonnet for implementation agents, Opus for review/architecture agents

### Agent Team Composition
| Agent | Model | Can Write | Purpose |
|-------|-------|-----------|---------|
| architect | Opus 4.6 | `docs/**` | ADRs, C4 diagrams, tech decisions |
| test-writer | Sonnet 4.5 | `tests/**` | TDD Red phase — failing tests |
| code-reviewer | Opus 4.6 | (read-only) | 10-point quality review |
| implementer | Sonnet 4.5 | `src/**` | TDD Green phase — make tests pass |

## Error Handling for Claude API

### Retry with Backoff
```python
from anthropic import (
    Anthropic,
    APIConnectionError,
    RateLimitError,
    APIStatusError,
)

MAX_RETRIES = 3
INITIAL_BACKOFF_SECONDS = 1.0

client = Anthropic(max_retries=MAX_RETRIES)

# Or manual retry for finer control
try:
    response = client.messages.create(...)
except RateLimitError:
    logger.warning("Rate limited, backing off")
    time.sleep(INITIAL_BACKOFF_SECONDS)
    # retry...
except APIConnectionError as exc:
    logger.error("Connection failed: %s", exc)
    raise
except APIStatusError as exc:
    logger.error("API error %d: %s", exc.status_code, exc.message)
    raise
```

### Token Budget Management
```python
MODEL_CONTEXT_LIMITS = {
    "claude-opus-4-6": 200000,
    "claude-sonnet-4-5-20250929": 200000,
    "claude-haiku-4-5-20251001": 200000,
}
OUTPUT_TOKEN_BUFFER = 4096
SAFETY_MARGIN = 0.9  # Use 90% of context to avoid edge cases

def estimate_available_tokens(model: str, messages: list) -> int:
    """Estimate remaining context budget."""
    limit = MODEL_CONTEXT_LIMITS[model]
    used = client.count_tokens(messages)  # approximate
    return int(limit * SAFETY_MARGIN) - used - OUTPUT_TOKEN_BUFFER
```

## Testing Claude Agents

### Mock the Anthropic Client
```python
from unittest.mock import MagicMock, patch

@pytest.fixture
def mock_anthropic():
    """Mock Anthropic client for unit tests."""
    with patch("src.agent.Anthropic") as mock:
        client = MagicMock()
        mock.return_value = client

        # Configure mock response
        response = MagicMock()
        response.stop_reason = "end_turn"
        response.content = [MagicMock(type="text", text="Test response")]
        client.messages.create.return_value = response

        yield client
```

### Test Tool Dispatch
```python
def test_tool_dispatch_calls_correct_handler():
    result = dispatch_tool("search_codebase", {"query": "def main"})
    assert isinstance(result, str)
    assert len(result) > 0
```
