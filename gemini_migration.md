# Gemini CLI Migration Guide: SDLC Scaffolding Template

## Context
This document captures the full analysis of what changes are needed to port the Claude Code SDLC scaffolding template to Gemini CLI. Use this as a reference when building the Gemini version.

---

## 1. Directory & File Structure Mapping

| Claude Code | Gemini CLI | Notes |
|-------------|-----------|-------|
| `.claude/` | `.gemini/` | Root config directory |
| `.claude/settings.json` | `.gemini/settings.json` | Different schema (see section 3) |
| `.claude/commands/*.md` | `.gemini/commands/*.toml` | **Format change**: Markdown → TOML |
| `.claude/rules/*.md` | No direct equivalent | Must embed in `GEMINI.md` via `@path` imports |
| `.claude/skills/*/SKILL.md` | No direct equivalent | Must embed in `GEMINI.md` via `@path` imports |
| `.claude/agents/*.yaml` | `.gemini/agents/*.md` | **Format change**: YAML → Markdown with YAML frontmatter |
| `.claude/hooks/*.sh` | `.gemini/hooks/*.sh` | Same concept, different event names and JSON schema |
| `CLAUDE.md` | `GEMINI.md` | Same concept, direct rename |
| `.mcp.json` | `.gemini/settings.json` → `mcpServers` | MCP config moves inside settings |

**Action**: Rename `.claude/` → `.gemini/`, `CLAUDE.md` → `GEMINI.md`, and convert file formats as detailed below.

---

## 2. Custom Commands: Markdown → TOML

### Claude Code format (`.claude/commands/implement.md`):
```markdown
# /implement — TDD Implementation Cycle
Read the user story at $ARGUMENTS.
## Phase 0: Pre-flight Verification
...
```

### Gemini CLI format (`.gemini/commands/implement.toml`):
```toml
description = "TDD Red-Green-Refactor cycle for a story (sequential)"
prompt = """
Read the user story at {{args}}.

## Phase 0: Pre-flight Verification
...
"""
```

### Changes needed for each command:
- Convert `.md` → `.toml` format
- Replace `$ARGUMENTS` → `{{args}}`
- Add `description` field (one-line summary for `/help` menu)
- Wrap prompt content in `prompt = """..."""`
- Subdirectories create namespaced commands with colons (e.g., `.gemini/commands/parallel/implement.toml` → `/parallel:implement`)

### Gemini CLI features available in commands:
- **Shell injection**: `!{shell command}` — executes shell and injects output into prompt
- **File injection**: `@{path/to/file}` — embeds file content into prompt
- **Auto shell-escaping**: `{{args}}` inside `!{...}` blocks are automatically escaped

### Files to convert (13 commands):
| Claude Code File | Gemini CLI File | Slash Command |
|---|---|---|
| `gogogo.md` | `gogogo.toml` | `/gogogo` |
| `interview.md` | `interview.toml` | `/interview` |
| `decompose.md` | `decompose.toml` | `/decompose` |
| `test-plan.md` | `test-plan.toml` | `/test-plan` |
| `implement.md` | `implement.toml` | `/implement` |
| `parallel-manual.md` | `parallel-manual.toml` | `/parallel-manual` |
| `parallel-implement.md` | **DROP** (no agent teams) | N/A |
| `pr.md` | `pr.toml` | `/pr` |
| `review.md` | `review.toml` | `/review` |
| `diagnose.md` | `diagnose.toml` | `/diagnose` |
| `wrapup.md` | `wrapup.toml` | `/wrapup` |
| `spike.md` | `spike.toml` | `/spike` |
| `create-prompt.md` | `create-prompt.toml` | `/create-prompt` |

---

## 3. Settings Schema Translation

### Claude Code `settings.json`:
```json
{
  "permissions": {
    "allow": [
      "Bash(python3 *)",
      "Bash(pytest *)",
      "Bash(make *)",
      "Bash(git *)",
      "Bash(gh *)",
      "Bash(node *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(docker *)"
    ]
  },
  "env": {
    "SDLC_MODE": "full",
    "AGENT_TEAMS_ENABLED": "true",
    "AGENT_TEAMS_ENFORCE": "true",
    "AGENT_TEAMS_MAX_TEAMMATES": "3"
  },
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...]
  }
}
```

### Gemini CLI `settings.json` (equivalent):
```json
{
  "tools": {
    "allowed": [
      "run_shell_command:python3 *",
      "run_shell_command:pytest *",
      "run_shell_command:make *",
      "run_shell_command:git *",
      "run_shell_command:gh *",
      "run_shell_command:node *",
      "run_shell_command:npm *",
      "run_shell_command:npx *",
      "run_shell_command:docker *"
    ]
  },
  "experimental": {
    "enableAgents": true
  },
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp"]
    }
  },
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "write_file|replace",
        "hooks": [
          {
            "name": "sdlc-gate",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/sdlc-gate.sh",
            "timeout": 10000
          }
        ]
      },
      {
        "matcher": "run_shell_command",
        "hooks": [
          {
            "name": "branch-guard",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/branch-guard.sh",
            "timeout": 10000
          },
          {
            "name": "bash-file-guard",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/bash-file-guard.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "AfterTool": [
      {
        "matcher": "write_file|replace",
        "hooks": [
          {
            "name": "lint-python",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/lint-python.sh",
            "timeout": 30000
          },
          {
            "name": "lint-frontend",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/lint-frontend.sh",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

### Field-by-field mapping:

| Claude Code Field | Gemini CLI Equivalent | Notes |
|---|---|---|
| `permissions.allow` | `tools.allowed` | Syntax differs: `Bash(cmd *)` → tool-specific patterns |
| `env.SDLC_MODE` | Custom `.gemini/sdlc-config.json` or shell env var | **Gemini has no `env` block** — use `SDLC_MODE` env var or a sidecar JSON file that hooks read |
| `env.AGENT_TEAMS_*` | **Drop entirely** | No agent teams in Gemini |
| `hooks.PreToolUse` | `hooks.BeforeTool` | Same concept, different event name |
| `hooks.PostToolUse` | `hooks.AfterTool` | Same concept, different event name |
| `hooks.TeammateIdle` | **No equivalent** | Drop |
| `hooks.TaskCompleted` | **No equivalent** | Drop |
| Hook `matcher: "Write\|Edit\|MultiEdit"` | `matcher: "write_file\|replace"` | Tool names differ |
| Hook `matcher: "Bash"` | `matcher: "run_shell_command"` | Tool names differ |
| N/A | `.mcp.json` moves here | `mcpServers` block in settings |
| N/A | `experimental.enableAgents` | Required to use sub-agents |

### Handling SDLC_MODE without env block

Since Gemini CLI has no `env` block in settings.json, use one of these approaches:

**Option A (recommended)**: Shell environment variable
```bash
export SDLC_MODE=full  # or "lite"
```
Hooks read via `$SDLC_MODE` directly. Document in `.env.example`.

**Option B**: Sidecar config file `.gemini/sdlc-config.json`
```json
{"SDLC_MODE": "full"}
```
Hooks read via `jq -r '.SDLC_MODE' "$PROJECT_ROOT/.gemini/sdlc-config.json"`.

---

## 4. Hook Event Mapping

### Event name translation:

| Claude Code Event | Gemini CLI Event | Mapping Quality |
|---|---|---|
| `PreToolUse` | `BeforeTool` | Direct equivalent — same stdin JSON + exit code model |
| `PostToolUse` | `AfterTool` | Direct equivalent |
| `TeammateIdle` | **None** | No agent teams lifecycle events — drop |
| `TaskCompleted` | **None** | No task completion events — drop |
| N/A | `SessionStart` | **New** — could auto-run `/gogogo` on session start |
| N/A | `BeforeAgent` | **New** — runs before agent planning loop |
| N/A | `BeforeModel` | **New** — intercept/modify prompts before LLM call |
| N/A | `BeforeToolSelection` | **New** — filter available tools dynamically |

### Hook input JSON differences:

**Claude Code** stdin:
```json
{
  "tool_input": {
    "file_path": "/src/app.py",
    "content": "..."
  }
}
```

**Gemini CLI** stdin:
```json
{
  "tool_name": "write_file",
  "input": {
    "path": "/src/app.py",
    "content": "..."
  }
}
```

### Changes needed per hook script:

The core bash logic (git checks, file validation, line counting) is **100% portable**. Only the `jq` field paths for extracting file paths from stdin JSON need updating.

**Claude Code jq**:
```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.command // empty')
```

**Gemini CLI jq** (adjust to actual schema):
```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.input.path // .input.command // empty')
```

### Hook disposition:

| Hook File | Action | New Event | New Matcher |
|---|---|---|---|
| `sdlc-gate.sh` | **Port** — update jq paths | `BeforeTool` | `write_file\|replace` |
| `branch-guard.sh` | **Port** — update jq paths | `BeforeTool` | `run_shell_command` |
| `bash-file-guard.sh` | **Port** — update jq paths | `BeforeTool` | `run_shell_command` |
| `lint-python.sh` | **Port** — update jq paths | `AfterTool` | `write_file\|replace` |
| `lint-frontend.sh` | **Port** — update jq paths | `AfterTool` | `write_file\|replace` |
| `worktree-guard.sh` | **Drop** — agent teams only | N/A | N/A |
| `teammate-idle.sh` | **Drop** — agent teams only | N/A | N/A |
| `teammate-completed.sh` | **Drop** — agent teams only | N/A | N/A |

### Gemini hook environment variables:
Hooks receive these env vars automatically:
- `GEMINI_PROJECT_DIR` — project root path
- `GEMINI_SESSION_ID` — unique session identifier
- `GEMINI_CWD` — current working directory

Use `$GEMINI_PROJECT_DIR` instead of `git rev-parse --show-toplevel` for project root (or keep git command as fallback).

---

## 5. Agent/Sub-Agent Definition Translation

### Claude Code format (`.claude/agents/test-writer.yaml`):
```yaml
name: test-writer
description: TDD Red phase — writes failing tests from acceptance criteria
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
file_restrictions:
  writable:
    - tests/
  readable:
    - src/
    - docs/
instructions: |
  You are a test-writer agent. Your job is to write
  failing tests from acceptance criteria...
```

### Gemini CLI format (`.gemini/agents/test-writer.md`):
```markdown
---
name: test-writer
description: TDD Red phase — writes failing tests from acceptance criteria
kind: local
tools:
  - read_file
  - write_file
  - replace
  - glob
  - grep_search
  - run_shell_command
model: gemini-2.5-pro
temperature: 0.2
max_turns: 15
timeout_mins: 10
---

You are a test-writer agent. Your job is to write
failing tests from acceptance criteria...

**File restrictions** (enforced by convention — no native support):
- Write ONLY to `tests/` directory
- Read from `src/`, `docs/`, and `tests/`
```

### Tool name mapping:

| Claude Code Tool | Gemini CLI Tool |
|---|---|
| `Read` | `read_file` |
| `Write` | `write_file` |
| `Edit` | `replace` |
| `Glob` | `glob` |
| `Grep` | `grep_search` |
| `Bash` | `run_shell_command` |
| `WebSearch` | `web_search` |
| `WebFetch` | `web_fetch` |
| `Task` (spawn sub-agent) | Automatic — main agent routes to sub-agents based on `description` |

### Agent files to convert:

| Claude Code File | Gemini CLI File | Notes |
|---|---|---|
| `test-writer.yaml` | `test-writer.md` | Port instructions + tool mapping |
| `code-reviewer.yaml` | `code-reviewer.md` | Port instructions + tool mapping |
| `architect.yaml` | `architect.md` | Port instructions + tool mapping |
| `performance-reviewer.yaml` | `performance-reviewer.md` | Port instructions + tool mapping |

### Key differences:
- **No `file_restrictions`** — Gemini sub-agents don't support writable/readable path constraints natively. Encode as instructions in the system prompt instead.
- **Sub-agents require opt-in** — Must set `"experimental": {"enableAgents": true}` in settings.json
- **YOLO mode** — Sub-agents execute tools without per-step user confirmation
- **No parallel execution** — Sub-agents run sequentially (parallel tracked in GitHub issues)

---

## 6. Rules & Skills — Use `@path` Imports in GEMINI.md

### Problem
Claude Code loads `.claude/rules/*.md` automatically based on file glob patterns. Gemini CLI has no rules/skills system.

### Solution: `@path` imports in GEMINI.md

Gemini CLI supports `@path/to/file.md` syntax in context files to include external content. Keep the rule files in `.gemini/rules/` and import them:

```markdown
# GEMINI.md

## Project Rules
@.gemini/rules/security.md
@.gemini/rules/code-style.md
@.gemini/rules/error-handling.md
@.gemini/rules/testing.md
@.gemini/rules/git-workflow.md
@.gemini/rules/react-patterns.md

## Skills Reference
@.gemini/skills/api-design/SKILL.md
@.gemini/skills/database-patterns/SKILL.md
@.gemini/skills/testing/SKILL.md
@.gemini/skills/deployment/SKILL.md
@.gemini/skills/langgraph-agents/SKILL.md
@.gemini/skills/react-frontend/SKILL.md
```

### Rule content changes needed:
**None** — all 6 rule files contain generic coding standards (security, error handling, code style, testing, git workflow, React patterns) with no Claude-specific content. They are 100% portable.

### Skill content changes needed:
- **6 of 7 skills**: No changes — content is framework-agnostic
- **`claude-agent-teams/SKILL.md`**: **Drop entirely** — covers Anthropic API patterns, Claude model selection, and agent teams architecture. Replace with a Gemini-specific skill if needed.

---

## 7. Agent Teams / Parallel Implementation

### What Claude Code has (that Gemini doesn't):

| Feature | Claude Code | Gemini CLI |
|---|---|---|
| Native agent teams | `TeamCreate`, `SendMessage` tools | Not available |
| Shared task lists | `TaskCreate`, `TaskUpdate`, `TaskList` | Not available |
| Inter-agent messaging | Direct messages, broadcasts | Not available |
| Delegate mode | Lead coordinates, doesn't code | Not available |
| Plan approval | Teammates submit plans for review | Not available |
| Parallel sub-agent execution | Multiple teammates run concurrently | Not available (Issue [#14963](https://github.com/google-gemini/gemini-cli/issues/14963)) |
| Agent lifecycle hooks | `TeammateIdle`, `TaskCompleted` | Not available |
| Worktree isolation | `worktree-guard.sh` per teammate | Not available |

### What to do:

1. **Drop `/parallel-implement`** command entirely
2. **Keep `/parallel-manual`** — git worktrees + multiple terminals works with any CLI
3. **Remove all `AGENT_TEAMS_*` settings** from config
4. **Remove 3 hooks**: `worktree-guard.sh`, `teammate-idle.sh`, `teammate-completed.sh`
5. **Remove `claude-agent-teams` skill**
6. **Update `GEMINI.md`**: Remove agent teams section, document sequential-only + manual parallel
7. **Set `SDLC_MODE` default to `"lite"`** — without agent teams, lite mode is the natural default

### Manual parallel workaround:
The `/parallel-manual` command (git worktrees + separate terminal sessions) works identically with Gemini CLI:
```
Terminal 1: cd .worktrees/STORY-001 && gemini   ->  /implement docs/backlog/.../STORY-001.md
Terminal 2: cd .worktrees/STORY-002 && gemini   ->  /implement docs/backlog/.../STORY-002.md
```

---

## 8. MCP Configuration

### Claude Code (`.mcp.json` at project root):
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp"]
    }
  }
}
```

### Gemini CLI (inside `.gemini/settings.json`):
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp"]
    }
  }
}
```

**Action**: Delete `.mcp.json` and move its content into `.gemini/settings.json` under `mcpServers`. The MCP server definitions are protocol-level and identical between CLIs.

---

## 9. Model References to Update

| Location | Claude Reference | Gemini Replacement |
|---|---|---|
| `CLAUDE.md` → Tech Stack | "Claude Opus 4.6" | "Gemini 2.5 Pro" |
| `CLAUDE.md` → Sub-Agents | "test-writer", "code-reviewer" | Same names, different format |
| `claude-agent-teams` skill | Anthropic API patterns | **Drop entirely** |
| Agent definition files | (inherits model) | Add `model: gemini-2.5-pro` explicitly |
| Commands mentioning "Claude" | Various | Replace with "Gemini" |
| `Co-Authored-By` in git commits | `Claude Opus 4.6 <noreply@anthropic.com>` | `Gemini 2.5 Pro <noreply@google.com>` (or similar) |

---

## 10. GEMINI.md Structure (replacing CLAUDE.md)

The bulk of `CLAUDE.md` is portable. Key changes:

### Remove entirely:
- Agent Teams section (lines 209-243 in current CLAUDE.md)
- References to `/parallel-implement`
- `AGENT_TEAMS_*` settings table
- TeammateIdle/TaskCompleted hook documentation

### Update:
- Title: `# Project: [Your Project Name]` (same)
- Tech stack: Replace "Claude Opus 4.6" → "Gemini 2.5 Pro"
- Settings references: `.claude/settings.json` → `.gemini/settings.json`
- Mode enforcement: Remove agent teams mode, keep sequential + manual parallel
- Coverage: keep full/lite mode thresholds
- Hook names in documentation: `PreToolUse` → `BeforeTool`, etc.

### Add:
- `@path` imports for rules and skills (see section 6)
- `SessionStart` hook documentation (Gemini-only)
- Note about sub-agents being experimental

---

## 11. Validation Scripts

### `scripts/validate-template.sh` changes:
- All path checks: `.claude/` → `.gemini/`
- `CLAUDE.md` → `GEMINI.md`
- Settings.json field checks: update to Gemini schema
- Remove agent teams checks (section 9)
- Remove TeammateIdle/TaskCompleted checks
- Add: check `experimental.enableAgents` in settings
- Add: check `mcpServers` in settings (instead of `.mcp.json`)
- Command file extension: `.md` → `.toml`

### `scripts/test-lite-mode.sh` changes:
- Update settings.json path and schema in test setup
- Update jq paths for Gemini JSON format
- Core test logic (line counting, section checking) unchanged

### `scripts/test-agent-teams.sh`:
- **Drop entirely** — no agent teams in Gemini

---

## 12. Summary: Effort Estimate

| Component | Files | Effort | What Changes |
|---|---|---|---|
| **Directory rename** | All `.claude/` | Trivial | `.claude/` → `.gemini/`, `CLAUDE.md` → `GEMINI.md` |
| **Commands** (12 files) | `.toml` conversion | **Medium** | Markdown → TOML, `$ARGUMENTS` → `{{args}}` |
| **Hooks** (5 portable) | JSON path updates | **Low** | Event names, tool names, jq field paths |
| **Agents** (4 files) | Format conversion | **Low** | YAML → Markdown+frontmatter, tool name mapping |
| **Settings** | Schema rewrite | **Medium** | Completely different schema |
| **Rules** (6 files) | No content changes | **None** | Add `@` imports to GEMINI.md |
| **Skills** (6 portable) | Import mechanism | **Low** | Add `@` imports to GEMINI.md; drop 1 skill |
| **GEMINI.md** | Rewrite references | **Medium** | Remove agent teams, update tool/model names |
| **Agent teams** | Drop entirely | **Low** (deletion) | Remove 3 hooks, 1 command, 1 skill, settings |
| **MCP config** | Move into settings | **Trivial** | `.mcp.json` content → settings `mcpServers` |
| **Validation scripts** | Update paths + schema | **Low** | Path changes, drop agent teams tests |

### Overall: ~60-70% directly portable. ~30-40% is agent teams (dropped) + format conversions (mechanical).

---

## 13. What You Lose (No Gemini Equivalent)

1. **Native agent teams** — parallel story implementation via teammates
2. **Inter-agent messaging** — SendMessage, broadcast
3. **Shared task lists** — TaskCreate/Update/List coordination
4. **Agent lifecycle hooks** — TeammateIdle, TaskCompleted
5. **Delegate mode** — lead coordinates without writing code
6. **Plan approval** — teammates submit plans for lead approval
7. **File restrictions on agents** — `file_restrictions.writable` / `readable` (encode in prompts instead)

## 14. What You Gain (Gemini-Only Features)

1. **`SessionStart` hook** — could auto-run `/gogogo` on session start
2. **`BeforeModel` hook** — intercept/modify prompts before LLM call
3. **`BeforeToolSelection` hook** — filter available tools dynamically
4. **Environment variable redaction** — automatic secret masking built-in
5. **`@path` imports** in GEMINI.md — modular context composition (cleaner than monolithic file)
6. **Chat save/resume** — `/chat save`, `/chat resume` for session persistence
7. **`BeforeAgent` hook** — inject context before planning loop starts

---

## 15. Migration Checklist

Use this checklist when executing the migration:

- [ ] Create `.gemini/` directory structure mirroring `.claude/`
- [ ] Convert 12 commands from `.md` to `.toml` format
- [ ] Port 5 hooks (update event names, tool matchers, jq paths)
- [ ] Convert 4 agents from `.yaml` to `.md` with YAML frontmatter
- [ ] Write `.gemini/settings.json` with new schema (tools, hooks, mcpServers, experimental)
- [ ] Create `GEMINI.md` from `CLAUDE.md` (remove agent teams, add `@` imports, update references)
- [ ] Move `.mcp.json` content into settings.json `mcpServers`
- [ ] Copy 6 rule files unchanged to `.gemini/rules/`
- [ ] Copy 6 skill files unchanged to `.gemini/skills/` (drop `claude-agent-teams`)
- [ ] Choose SDLC_MODE approach (env var vs sidecar JSON) and update hooks
- [ ] Update `validate-template.sh` for new paths and schema
- [ ] Update `test-lite-mode.sh` for new settings format
- [ ] Drop `test-agent-teams.sh`
- [ ] Drop `parallel-implement.toml` command
- [ ] Drop 3 agent-teams hooks
- [ ] Test: run validation scripts
- [ ] Test: verify hooks fire correctly with Gemini CLI

---

## Sources

- [Gemini CLI Configuration](https://geminicli.com/docs/get-started/configuration/)
- [Gemini CLI Hooks](https://geminicli.com/docs/hooks/)
- [Writing Hooks for Gemini CLI](https://geminicli.com/docs/hooks/writing-hooks/)
- [Gemini CLI Commands](https://geminicli.com/docs/cli/commands/)
- [Gemini CLI Custom Commands](https://geminicli.com/docs/cli/custom-commands/)
- [Gemini CLI Sub-agents (experimental)](https://geminicli.com/docs/core/subagents/)
- [Parallel Subagent Execution — Issue #14963](https://github.com/google-gemini/gemini-cli/issues/14963)
- [Parallel Subagent Execution — Issue #17749](https://github.com/google-gemini/gemini-cli/issues/17749)
- [Multi-Agent Architecture Proposal — Discussion #7637](https://github.com/google-gemini/gemini-cli/discussions/7637)
- [Google Developers Blog: Hooks for Gemini CLI](https://developers.googleblog.com/tailor-gemini-cli-to-your-workflow-with-hooks/)
