---
name: langgraph-agents
description: "9 multi-agent patterns (LangGraph 1.2.x): Subagents, Deep Agents, Forward Tool, Hierarchical Teams, Context Quarantine, Skills, Handoffs, Router, Custom Workflows. Includes middleware, checkpointing, and decision framework."
---

# Skill: LangGraph & LangChain Multi-Agent Patterns

## When to Use
Apply this skill when building AI agents with LangGraph/LangChain. Covers single-agent ReAct through 9 multi-agent orchestration patterns.

> **Rule of thumb**: Start simple. Add tools before adding agents. Add agents only when complexity demands it.

## Reference Implementation
See [multi_agentic_patterns_langchain](https://github.com/cwijayasundara/multi_agentic_patterns_langchain) for working examples of all 9 patterns.

---

## Core Infrastructure

### Provider-Agnostic LLM Initialization
```python
from langchain.chat_models import init_chat_model
from langchain_core.language_models import BaseChatModel

def get_model(model_string: str = "anthropic:claude-opus-4-6") -> BaseChatModel:
    """Initialize a chat model. Format: 'provider:model_name'."""
    try:
        return init_chat_model(model_string)
    except Exception as exc:
        msg = f"Failed to initialize LLM '{model_string}': {exc}"
        logger.error(msg)
        raise RuntimeError(msg) from exc
```

### Key Imports
| What | Import |
|------|--------|
| Chat model init | `from langchain.chat_models import init_chat_model` |
| Base chat model | `from langchain_core.language_models import BaseChatModel` |
| Base tool / decorator | `from langchain_core.tools import BaseTool, tool` |
| ReAct agent | `from langgraph.prebuilt import create_react_agent` |
| Compiled graph | `from langgraph.graph.state import CompiledStateGraph` |
| State graph | `from langgraph.graph import StateGraph, START, END` |
| Message reducer | `from langgraph.graph.message import add_messages` |
| Parallel dispatch | `from langgraph.types import Send` |
| Interrupt | `from langgraph.types import interrupt` |
| Supervisor | `from langgraph_supervisor import create_supervisor` |
| Deep agents | `from deepagents import create_deep_agent` |
| Memory checkpoint | `from langgraph.checkpoint.memory import MemorySaver` |

### Tool Design Rules
- Docstring is MANDATORY — LLM reads it to decide when to use the tool
- Use typed parameters — schema auto-generated from type hints
- Raise `ValueError` for invalid inputs (LangGraph handles gracefully)
- Return concrete types, not dicts
- Wrap third-party tools in factory functions with dependency injection

### State Design Rules
- Use `TypedDict` for state (enables type checking)
- Use `Annotated[list, add_messages]` for message lists
- Keep state flat — avoid nested dicts
- Each node receives full state and returns partial updates

### Prompts as Module Constants
- Store in `src/agents/prompts.py` as UPPER_SNAKE_CASE constants
- Include methodology (HOW to reason) and output format (WHAT to produce)
- Use backslash line continuation (`"""\`) to avoid leading newline

---

## Quick Pattern Selector

```
"I need to coordinate domain experts"          → SUBAGENTS (Pattern 1)
"Tasks have many tool calls, context bloats"   → DEEP AGENTS (Pattern 2)
"Exact wording matters, can't paraphrase"      → FORWARD TOOL (Pattern 3)
"Multiple teams with internal structure"        → HIERARCHICAL (Pattern 4)
"Large data, only need summaries"              → QUARANTINE (Pattern 5)
"I want one agent that can do many things"     → SKILLS (Pattern 6)
"Users go through stages/steps"                → HANDOFFS (Pattern 7)
"Query multiple sources, combine results"      → ROUTER (Pattern 8)
"I need loops, branches, custom logic"         → CUSTOM (Pattern 9)
```

---

## Pattern 1: Subagents (Supervisor)

**When**: Multiple distinct domains, centralized workflow control, parallel execution needed.

A supervisor agent coordinates stateless subagents by calling them as tools. Strong context isolation — subagents don't share context.

```python
from langchain.agents import create_agent
from langgraph_supervisor import create_supervisor

model = get_model()

# Specialized subagents
budget_agent = create_agent(
    model=model, tools=BUDGET_TOOLS,
    name="budget_analyst", system_prompt=BUDGET_AGENT_PROMPT,
    middleware=create_subagent_middleware(),
)

investment_agent = create_agent(
    model=model, tools=INVESTMENT_TOOLS,
    name="investment_advisor", system_prompt=INVESTMENT_AGENT_PROMPT,
    middleware=create_subagent_middleware(),
)

# Supervisor coordinates them
workflow = create_supervisor(
    agents=[budget_agent, investment_agent],
    model=model, system_prompt=FINANCE_SUPERVISOR_PROMPT,
    middleware=create_supervisor_middleware(),
)
```

**Pros**: Strong context isolation, parallel execution, multi-hop support.
**Cons**: Extra latency (4 calls vs 3), higher token overhead.

---

## Pattern 2: Deep Agents

**When**: Tasks with many tool calls, large intermediate outputs, context management critical.

Solves context bloat by delegating to subagents in isolated contexts. Main agent receives only summaries, not raw data (~97% token reduction).

```python
from deepagents import create_deep_agent

research_subagent = {
    "name": "researcher",
    "description": "Conducts web research to gather information.",
    "system_prompt": "You are an expert researcher. Keep response under 500 words.",
    "tools": [web_search],
}

analysis_subagent = {
    "name": "analyst",
    "description": "Analyzes data and extracts insights.",
    "system_prompt": "You are a data analyst. Keep response under 400 words.",
    "tools": [analyze_data],
}

agent = create_deep_agent(
    model="anthropic:claude-opus-4-6",
    system_prompt=COORDINATOR_PROMPT,
    subagents=[research_subagent, analysis_subagent],
    name="research-coordinator",
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Research multi-agent patterns"}]
})
```

**Pros**: Prevents context bloat, built-in planning tools, specialized expertise.
**Cons**: Summaries are lossy, more complex debugging.

---

## Pattern 3: Supervisor with Forward Tool

**When**: Exact wording matters (legal, medical, financial), audit trails needed.

Forwards subagent responses **verbatim** — no paraphrasing or modification.

```python
def create_forward_tool(agent_name: str):
    @tool
    def forward_to_user(response: str) -> str:
        f"""Forward the {agent_name}'s response directly to the user."""
        return f"[FORWARDED FROM {agent_name.upper()}]\n\n{response}"
    return forward_to_user

supervisor = create_react_agent(
    model, tools=[route_to_specialist, forward_contract_response],
    prompt=SUPERVISOR_PROMPT,
)
```

---

## Pattern 4: Hierarchical Teams

**When**: Complex nested workflows, multiple teams with internal structure, 10+ specialists.

Each team is a compiled subgraph. Top supervisor coordinates teams, each team coordinates its own specialists.

```python
def create_marketing_team():
    workflow = StateGraph(TeamState)
    workflow.add_node("content", content_specialist)
    workflow.add_node("seo", seo_specialist)
    workflow.add_node("social", social_specialist)
    workflow.add_node("lead", marketing_lead)

    workflow.add_edge(START, "content")  # Parallel start
    workflow.add_edge(START, "seo")
    workflow.add_edge(START, "social")
    workflow.add_edge("content", "lead")  # Lead synthesizes
    workflow.add_edge("seo", "lead")
    workflow.add_edge("social", "lead")
    workflow.add_edge("lead", END)
    return workflow.compile()

# Top supervisor
supervisor = StateGraph(LaunchState)
supervisor.add_node("marketing", lambda s: marketing_team.invoke(...))
supervisor.add_node("engineering", lambda s: engineering_team.invoke(...))
```

---

## Pattern 5: Context Quarantine

**When**: Large tool outputs (database queries, file contents), cost optimization critical.

Subagents isolate large data, returning only summaries. Prevents context from growing to 100K+ tokens.

```python
def create_quarantine_workflow():
    data_collector = create_react_agent(
        model, tools=[query_database, fetch_api],
        prompt="Process data and return ONLY a 500-word summary...",
    )

    def collect_data(state):
        result = data_collector.invoke({"messages": [...]})
        return {"data_summary": result["messages"][-1].content}  # Summary only

    workflow = StateGraph(AnalysisState)
    workflow.add_node("collect", collect_data)       # Quarantine zone
    workflow.add_node("synthesize", synthesize_report)  # Clean context
    workflow.add_edge(START, "collect")
    workflow.add_edge("collect", "synthesize")
    workflow.add_edge("synthesize", END)
    return workflow.compile()
```

**Token savings**: Without quarantine ~100K tokens. With quarantine ~1.5K tokens (~97% reduction).

---

## Pattern 6: Skills (Dynamic Knowledge Loading)

**When**: Single agent, many specializations. Different teams develop skills independently.

Agent dynamically loads specialized prompts on-demand via `load_skill()` / `unload_skill()`.

```python
set_skills_directory("./skills")  # .md files with expertise

SKILLS_AGENT_PROMPT = """You are a versatile code assistant with access to specialized skills.
Always load relevant skills before answering technical questions.
Available: python-expert, go-expert, react-expert, sql-expert, rust-expert"""

agent = create_agent(
    model=model, tools=CODE_TOOLS,
    system_prompt=SKILLS_AGENT_PROMPT,
    middleware=create_skills_middleware(),
    checkpointer=checkpointer,
)
```

**Pros**: 40% token savings on repeat requests, direct user interaction.
**Cons**: Context accumulates across loaded skills.

---

## Pattern 7: Handoffs

**When**: Multi-stage conversations, sequential constraints, state-driven transitions (customer support, onboarding).

Agents hand off conversation dynamically. Active agent changes via tool calling, state persists across turns.

```python
# Agent with state-driven behavior changes
agent = create_react_agent(
    model, tools=SUPPORT_TOOLS,
    checkpointer=checkpointer,
    state_schema=SupportState,  # Tracks current_step, customer_info
    middleware=create_support_middleware(),
)
# Tools like transfer_to_billing() and transfer_to_tech() update state
# and change which agent is active
```

**Pros**: Natural conversation flow, sequential constraints enforced.
**Cons**: Cannot parallelize, requires state management.

---

## Pattern 8: Router (Parallel Dispatch)

**When**: Distinct knowledge verticals, parallel querying needed, result synthesis required.

Classifies queries and dispatches to agents in parallel using `Send()`. Stateless per-request.

```python
from langgraph.types import Send

def classify_query(state: RouterState) -> dict:
    sanitized = sanitize_query(state["query"])
    structured_llm = model.with_structured_output(ClassificationResult)
    result = structured_llm.invoke(CLASSIFICATION_PROMPT.format(query=sanitized))
    return {"classifications": [c.dict() for c in result.classifications]}

def route_to_agents(state: RouterState) -> list[Send]:
    """Dispatch to classified agents in parallel."""
    return [
        Send(f"{c['source']}_agent", {"query": c["query"]})
        for c in state["classifications"]
    ]

workflow = StateGraph(RouterState)
workflow.add_node("classify", classify_query)
workflow.add_node("docs_agent", docs_agent)
workflow.add_node("faq_agent", faq_agent)
workflow.add_node("synthesize", synthesize_results)
workflow.add_edge(START, "classify")
workflow.add_conditional_edges("classify", route_to_agents,
    ["docs_agent", "faq_agent", "synthesize"])
workflow.add_edge("docs_agent", "synthesize")
workflow.add_edge("faq_agent", "synthesize")
workflow.add_edge("synthesize", END)
```

---

## Pattern 9: Custom Workflows

**When**: Complex branching, iterative loops, write-review-revise cycles, quality gates.

Full control using StateGraph with conditional edges.

```python
def route_after_review(state: ContentState) -> Literal["finalize", "revise", "reject"]:
    if state["status"] == "approved":
        return "finalize"
    if state.get("revision_count", 0) >= MAX_REVISIONS:
        return "reject"
    return "revise"  # Loop back to write node

workflow = StateGraph(ContentState)
workflow.add_node("research", research_topic)
workflow.add_node("outline", create_outline)
workflow.add_node("write", write_draft)
workflow.add_node("review", review_content)
workflow.add_node("finalize", finalize_content)

workflow.add_edge(START, "research")
workflow.add_edge("research", "outline")
workflow.add_edge("outline", "write")
workflow.add_edge("write", "review")
workflow.add_conditional_edges("review", route_after_review,
    {"finalize": "finalize", "revise": "write", "reject": "reject"})
workflow.add_edge("finalize", END)
```

---

## Middleware Stack (LangChain 1.2.x)

### Available Middleware

| Middleware | Purpose | When to Use |
|-----------|---------|-------------|
| `SummarizationMiddleware` | Compress history at token limit | Long conversations |
| `ContextEditingMiddleware` | Remove old tool outputs | Tool-heavy agents |
| `ToolRetryMiddleware` | Retry failed tool calls with backoff | External API calls |
| `ModelFallbackMiddleware` | Switch to backup model on failure | Production systems |
| `HumanInTheLoopMiddleware` | Require approval for sensitive ops | Refunds, deletions |
| `ModelCallLimitMiddleware` | Prevent infinite loops | All production agents |
| `LLMToolSelectorMiddleware` | LLM selects relevant tools | Agents with 15+ tools |

### Middleware by Pattern

```python
# Subagents: full resilience for supervisor
supervisor_middleware = [SummarizationMiddleware(...), ToolRetryMiddleware(...), ModelFallbackMiddleware(...)]
subagent_middleware = [ToolRetryMiddleware(...)]  # Lightweight

# Handoffs: safety + cost control
support_middleware = [HumanInTheLoopMiddleware(...), ModelCallLimitMiddleware(...),
                      ContextEditingMiddleware(...), SummarizationMiddleware(...)]

# Skills: smart tool selection + context management
skills_middleware = [LLMToolSelectorMiddleware(...), ToolCallLimitMiddleware(...),
                     ContextEditingMiddleware(...), SummarizationMiddleware(...)]
```

---

## Comparison Table

| Requirement | Best Pattern |
|-------------|-------------|
| Coordinate domain experts (parallel) | **Subagents** |
| Tool-heavy tasks, context bloats | **Deep Agents** |
| Exact wording, audit trails | **Forward Tool** |
| Large org, multiple teams | **Hierarchical** |
| Large data, need summaries only | **Quarantine** |
| Single agent, many specializations | **Skills** |
| Sequential workflow + state | **Handoffs** |
| Parallel queries + synthesis | **Router** |
| Complex branching/looping | **Custom** |

## Performance: Token Usage (Multi-Domain Query)

```
Quarantine:   ~3,000 tokens  ██░░░░░░░░░░░░░ (Best isolation)
Deep Agents:  ~6,000 tokens  █████░░░░░░░░░░
Subagents:    ~9,000 tokens  ████████░░░░░░░
Router:       ~9,000 tokens  ████████░░░░░░░
Forward:     ~10,000 tokens  █████████░░░░░░
Hierarchical:~12,000 tokens  ██████████░░░░░
Handoffs:    ~14,000 tokens  ████████████░░░
Skills:      ~15,000 tokens  █████████████░░
```

---

## Checkpointing & Persistence

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()  # Dev only
# Production: SqliteSaver / PostgresSaver

graph = workflow.compile(checkpointer=checkpointer)
config = {"configurable": {"thread_id": "user-123"}}
result = graph.invoke({"messages": [("user", query)]}, config=config)
```

## LangSmith Observability

Set env vars for automatic tracing (no code changes):
```bash
LANGSMITH_API_KEY=your-key
LANGSMITH_PROJECT=my-project
LANGCHAIN_TRACING_V2=true
```

## Testing Agents

- **Unit tests**: Mock at LLM boundary with `MagicMock(spec=BaseChatModel)`
- **Integration tests**: Real LLM, gated by `@pytest.mark.integration`
- **Mock agent responses**: `{"messages": [MagicMock(content="result")]}`
- **Dependency chain**: `Settings → LLM → Tools → Agent → Run → Output`
