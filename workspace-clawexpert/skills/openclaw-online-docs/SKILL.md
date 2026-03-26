---
name: openclaw-online-docs
description: Advanced OpenClaw features — ACP protocol, multi-agent patterns, advanced compaction/memory, remote gateway, OpenShell, LLM-task, BTW, Lobster. Sourced from live docs.openclaw.ai and local repo docs.acp.md.
---

# OpenClaw Advanced Features — Live Docs Reference

## Changelog
- 2026-03-20: Created from live docs.openclaw.ai + local repos/openclaw/docs.acp.md. Covers: ACP, multi-agent routing, sessions, compaction, memory, context engine, heartbeat, sandboxing (Docker/SSH/OpenShell), remote gateway, multiple gateways, llm-task, subagents, ACP agents, BTW, Lobster.

---

## 1. ACP Protocol

### What It Is

`openclaw acp` is a **Gateway-backed ACP (Agent Client Protocol) bridge** over stdio. It is NOT a full ACP-native editor runtime. It forwards IDE prompts to a running OpenClaw Gateway over WebSocket, mapping ACP sessions to Gateway session keys.

**ACP = Agent Client Protocol** — a standard protocol for IDEs and coding agents (Zed, Codex, Claude Code) to talk to AI backends.

### Core Concepts

- ACP client spawns `openclaw acp`, speaks ACP messages over stdio
- The bridge connects to the Gateway using auth config (or CLI flags)
- ACP `prompt` → Gateway `chat.send`
- Gateway streaming events → ACP streaming events
- ACP `cancel` → Gateway `chat.abort` for active run

### Compatibility Matrix

| ACP area | Status | Notes |
|---|---|---|
| `initialize`, `newSession`, `prompt`, `cancel` | Implemented | Core bridge flow over stdio |
| `listSessions`, slash commands | Implemented | Session list maps to Gateway `sessions.list` |
| `loadSession` | Partial | Replays user/assistant text history only; no tools/system |
| Prompt content (text, resource, images) | Partial | Text/resources flattened; images → Gateway attachments |
| Session modes | Partial | `session/set_mode` supported; thought level, tool verbosity, reasoning |
| Session info and usage updates | Partial | Best-effort `session_info_update` + `usage_update` from cached snapshots |
| Tool streaming | Partial | `tool_call`/`tool_call_update` include raw I/O, text content |
| Per-session MCP servers | Unsupported | Bridge mode rejects; configure MCP at Gateway/agent layer |
| Client filesystem methods | Unsupported | No `fs/read_text_file`, `fs/write_text_file` |
| Client terminal methods | Unsupported | No `terminal/*` |
| Session plans / thought streaming | Unsupported | Emits output text and tool status only |

### Usage Examples

```bash
# Basic local
openclaw acp

# Remote Gateway
openclaw acp --url wss://gateway-host:18789 --token <token>

# Remote with token from file (preferred for security)
openclaw acp --url wss://gateway-host:18789 --token-file ~/.openclaw/gateway.token

# Attach to existing session key
openclaw acp --session agent:main:main

# Attach by label
openclaw acp --session-label "support inbox"

# Reset session before first prompt
openclaw acp --session agent:main:main --reset-session
```

### Selecting Agents

ACP routes by **Gateway session key**, not by agent directly.

```bash
openclaw acp --session agent:main:main
openclaw acp --session agent:design:main
openclaw acp --session agent:qa:bug-123
```

Default: isolated `acp:<uuid>` session per ACP client session.

### Session Mapping

Override session via CLI:
- `--session <key>`: direct Gateway session key
- `--session-label <label>`: resolve by label
- `--reset-session`: mint new transcript for the key

Or via ACP metadata per session:
```json
{
  "_meta": {
    "sessionKey": "agent:main:main",
    "sessionLabel": "support inbox",
    "resetSession": true,
    "requireExisting": false
  }
}
```

### Zed Editor Setup

```json
{
  "agent_servers": {
    "OpenClaw ACP": {
      "type": "custom",
      "command": "openclaw",
      "args": ["acp"],
      "env": {}
    }
  }
}
```

Target specific Gateway + agent:
```json
{
  "agent_servers": {
    "OpenClaw ACP": {
      "type": "custom",
      "command": "openclaw",
      "args": ["acp", "--url", "wss://gateway-host:18789", "--token", "<token>", "--session", "agent:design:main"],
      "env": {}
    }
  }
}
```

### Using with acpx (Codex, Claude Code)

```bash
# One-shot request
acpx openclaw exec "Summarize the active OpenClaw session state."

# Persistent named session
acpx openclaw sessions ensure --name codex-bridge
acpx openclaw -s codex-bridge --cwd /path/to/repo "Ask my work agent for recent context."
```

Override `~/.acpx/config.json` for consistent target:
```json
{
  "agents": {
    "openclaw": {
      "command": "env OPENCLAW_HIDE_BANNER=1 OPENCLAW_SUPPRESS_NOTES=1 openclaw acp --url ws://127.0.0.1:18789 --token-file ~/.openclaw/gateway.token --session agent:main:main"
    }
  }
}
```

### Debug Client

```bash
openclaw acp client

# Point at remote Gateway
openclaw acp client --server-args --url wss://gateway-host:18789 --token-file ~/.openclaw/gateway.token
```

### Options Reference

| Flag | Description |
|---|---|
| `--url <url>` | Gateway WebSocket URL |
| `--token <token>` | Gateway auth token |
| `--token-file <path>` | Read token from file (preferred) |
| `--password <password>` | Gateway auth password |
| `--password-file <path>` | Read password from file |
| `--session <key>` | Default session key |
| `--session-label <label>` | Default session label to resolve |
| `--require-existing` | Fail if session key/label not found |
| `--reset-session` | Reset session key before first use |
| `--no-prefix-cwd` | Don't prefix prompts with working directory |
| `--verbose, -v` | Verbose logging to stderr |

**Security note:** prefer `--token-file` over `--token` (avoids process listing exposure). Env vars: `OPENCLAW_GATEWAY_TOKEN`, `OPENCLAW_GATEWAY_PASSWORD`.

### Known Limitations

- `loadSession` does NOT reconstruct historic tool calls, system notices, or richer event types
- Multiple ACP clients sharing the same Gateway session key → best-effort routing, not isolated
- Stop state mapping less expressive than fully ACP-native runtime
- Usage/token data is approximate only, no cost data, only emitted when Gateway marks totals as fresh
- ACP runtime child processes receive `OPENCLAW_SHELL=acp`

---

## 2. Multi-Agent Patterns

### What "One Agent" Means

An **agent** is a fully scoped brain with its own:
- **Workspace** (files, AGENTS.md, SOUL.md, USER.md, persona rules)
- **State directory** (`agentDir`) for auth profiles, model registry, per-agent config
- **Session store** (`~/.openclaw/agents/<agentId>/sessions`) with chat history + routing state

Auth profiles are per-agent (`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`). Never reuse `agentDir` across agents — causes auth/session collisions.

### Routing Rules (How Messages Pick an Agent)

**Most-specific wins, deterministic:**
1. `peer` match (exact DM/group/channel id)
2. `parentPeer` match (thread inheritance)
3. `guildId + roles` (Discord role routing)
4. `guildId` (Discord)
5. `teamId` (Slack)
6. `accountId` match for a channel
7. channel-level match (`accountId: "*"`)
8. fallback to default agent (`agents.list[].default`, else first list entry, default: `main`)

If multiple bindings match in the same tier, first in config order wins. Multiple match fields = AND semantics.

**Key:** a binding that omits `accountId` matches the default account only. Use `accountId: "*"` for channel-wide fallback.

### Session Key Patterns

- Direct chats: `agent:<agentId>:<mainKey>` (default `main`)
- `per-peer`: `agent:<agentId>:direct:<peerId>`
- `per-channel-peer`: `agent:<agentId>:<channel>:direct:<peerId>`
- Group chats: `agent:<agentId>:<channel>:group:<id>`
- Telegram topics: `...:group:<id>:topic:<threadId>`
- Cron: `cron:<job.id>` or custom `session:<custom-id>`

### Agent-to-Agent (sessions_send)

Off by default. Enable explicitly:
```json
{
  "tools": {
    "agentToAgent": {
      "enabled": false,
      "allow": ["home", "work"]
    }
  }
}
```

### Subagent Spawning (sessions_spawn)

```json
// sessions_spawn tool params:
{
  "task": "required",
  "label": "optional",
  "agentId": "optional - spawn under another agent if allowed",
  "model": "optional - overrides sub-agent model",
  "thinking": "optional - overrides thinking level",
  "runTimeoutSeconds": "optional - abort after N seconds",
  "thread": false,         // when true, requests channel thread binding
  "mode": "run|session",   // run = one-shot, session requires thread:true
  "cleanup": "delete|keep", // default: keep
  "sandbox": "inherit|require" // require rejects if target not sandboxed
}
```

Sub-agent session keys: `agent:<agentId>:subagent:<uuid>`

### allowAgents List

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "subagents": {
          "allowAgents": ["*"]  // or explicit list: ["ops", "research"]
        }
      }
    ]
  }
}
```

### maxSpawnDepth and maxChildrenPerAgent

```json
{
  "agents": {
    "defaults": {
      "subagents": {
        "maxSpawnDepth": 2,         // default: 1 (no nesting); 2 = orchestrator pattern
        "maxChildrenPerAgent": 5,   // max active children per agent session
        "maxConcurrent": 8,         // global concurrency lane cap
        "runTimeoutSeconds": 900,   // default timeout (0 = none)
        "archiveAfterMinutes": 60   // auto-archive after completion
      }
    }
  }
}
```

**Depth table:**

| Depth | Session key | Role | Can spawn? |
|---|---|---|---|
| 0 | `agent:<id>:main` | Main agent | Always |
| 1 | `agent:<id>:subagent:<uuid>` | Sub-agent (orchestrator if depth 2) | Only if `maxSpawnDepth >= 2` |
| 2 | `agent:<id>:subagent:<uuid>:subagent:<uuid>` | Leaf worker | Never |

### Subagent Announce

When a sub-agent finishes, it announces back to the requester. Announce payload includes:
- Result (assistant reply text, or latest toolResult if empty)
- Status: `completed successfully` / `failed` / `timed out` / `unknown`
- Compact runtime/token stats
- Delivery instruction (rewrite in normal assistant voice, don't forward raw metadata)
- `sessionKey`, `sessionId`, transcript path

If sub-agent replies exactly `ANNOUNCE_SKIP`, nothing is posted.

Nested announce chain (depth 2):
1. Depth-2 worker → announces to depth-1 orchestrator
2. Depth-1 orchestrator synthesizes → announces to main
3. Main delivers to user

### Tool Policy by Depth

- **Depth 1 (leaf, maxSpawnDepth=1)**: No session tools
- **Depth 1 (orchestrator, maxSpawnDepth≥2)**: Gets `sessions_spawn`, `subagents`, `sessions_list`, `sessions_history`
- **Depth 2 (leaf worker)**: No session tools, `sessions_spawn` always denied

### Subagent Context Injection

Sub-agents only get `AGENTS.md` + `TOOLS.md`. They do NOT get: `SOUL.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, `BOOTSTRAP.md`.

### Cascade Stop

- `/stop` in main chat → stops all depth-1 agents + cascades to their depth-2 children
- `/subagents kill <id>` → stops specific sub-agent + cascades
- `/subagents kill all` → stops all sub-agents for requester + cascades

### Multi-Agent Config Example (Telegram per-agent)

```json
{
  "agents": {
    "list": [
      { "id": "main", "workspace": "~/.openclaw/workspace-main" },
      { "id": "alerts", "workspace": "~/.openclaw/workspace-alerts" }
    ]
  },
  "bindings": [
    { "agentId": "main", "match": { "channel": "telegram", "accountId": "default" } },
    { "agentId": "alerts", "match": { "channel": "telegram", "accountId": "alerts" } }
  ],
  "channels": {
    "telegram": {
      "accounts": {
        "default": { "botToken": "123456:ABC...", "dmPolicy": "pairing" },
        "alerts": { "botToken": "987654:XYZ...", "dmPolicy": "allowlist", "allowFrom": ["tg:123456789"] }
      }
    }
  }
}
```

---

## 3. Session Management (Advanced)

### DM Scope Options

```json
{
  "session": {
    "dmScope": "per-channel-peer"
  }
}
```

Options:
- `main` (default): all DMs share main session — single-user only
- `per-peer`: isolate by sender id across channels
- `per-channel-peer`: isolate by channel + sender (recommended for multi-user inboxes)
- `per-account-channel-peer`: isolate by account + channel + sender (recommended for multi-account)

**Security:** if multiple users can DM your agent, use `per-channel-peer` or session isolation. Without it, Bob can see Alice's context.

### Session Maintenance

```json
{
  "session": {
    "maintenance": {
      "mode": "enforce",
      "pruneAfter": "30d",
      "maxEntries": 500,
      "rotateBytes": "10mb",
      "resetArchiveRetention": "14d",
      "maxDiskBytes": "1gb",
      "highWaterBytes": "800mb"
    }
  }
}
```

`mode: "warn"` = report only; `mode: "enforce"` = apply cleanup:
1. prune stale entries older than `pruneAfter`
2. cap count to `maxEntries` (oldest first)
3. archive transcript files for removed entries
4. purge old `*.deleted.*` and `*.reset.*` archives
5. rotate `sessions.json` when exceeding `rotateBytes`
6. if `maxDiskBytes` set, enforce disk budget

### Session Lifecycle

- **Daily reset**: default 4:00 AM local time on gateway host
- **Idle reset**: add `idleMinutes` for sliding window
- **Per-type overrides**: `resetByType` for `direct`, `group`, `thread`
- **Per-channel overrides**: `resetByChannel`
- Manual reset: `/new` or `/reset` + optional model alias (`/new claude-opus`)

### Send Policy

Block delivery for specific session types:
```json
{
  "session": {
    "sendPolicy": {
      "rules": [
        { "action": "deny", "match": { "channel": "discord", "chatType": "group" } },
        { "action": "deny", "match": { "keyPrefix": "cron:" } },
        { "action": "deny", "match": { "rawKeyPrefix": "agent:main:discord:" } }
      ],
      "default": "allow"
    }
  }
}
```

---

## 4. Compaction (Advanced)

### What Compaction Is

Compaction **summarizes older conversation** into a compact summary entry and keeps recent messages intact. Persists in JSONL session history. Different from pruning (pruning trims tool results in-memory only, doesn't persist).

### Compaction Config

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "model": "openrouter/anthropic/claude-sonnet-4-6",
        "identifierPolicy": "strict",
        "reserveTokensFloor": 20000,
        "memoryFlush": {
          "enabled": true,
          "softThresholdTokens": 4000,
          "systemPrompt": "Session nearing compaction. Store durable memories now.",
          "prompt": "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store."
        }
      }
    }
  }
}
```

**identifierPolicy:**
- `"strict"` (default): preserves opaque identifiers during summarization
- `"off"`: disables identifier preservation
- `"custom"`: use with `identifierInstructions` for custom text

**model override:** use a different (potentially more capable) model for compaction summarization than the primary model. Works with local models too:
```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "model": "ollama/llama3.1:8b"
      }
    }
  }
}
```

### Auto-Compaction

Triggers automatically when session nears/exceeds context window. Indicators:
- `🧹 Auto-compaction complete` in verbose mode
- `/status` showing `🧹 Compactions: <count>`

### memoryFlush (Pre-Compaction Memory Ping)

When session is close to auto-compaction, OpenClaw triggers a **silent agentic turn** reminding model to write durable memory BEFORE compaction.

- Soft threshold: flush triggers when `contextWindow - reserveTokensFloor - softThresholdTokens` is exceeded
- Silent by default: prompts include `NO_REPLY`
- Two prompts: user prompt + system prompt append
- One flush per compaction cycle (tracked in `sessions.json`)
- Skipped if workspace is `workspaceAccess: "ro"` or `"none"`

### Manual Compaction

```
/compact
/compact Focus on decisions and open questions
```

### Compaction vs Pruning

| | Compaction | Pruning |
|---|---|---|
| What | Summarizes older conversation | Trims old tool results |
| Persistence | Yes (in JSONL) | No (in-memory only) |
| Trigger | Context window full or manual | Before each LLM call |

### Context Engine Plugin Slot

Active context engine is selected via `plugins.slots.contextEngine`:

```json
{
  "plugins": {
    "slots": {
      "contextEngine": "lossless-claw"
    },
    "entries": {
      "lossless-claw": {
        "enabled": true
      }
    }
  }
}
```

Default: `"legacy"`. Plugin engines can implement any compaction strategy (DAG summaries, vector retrieval, etc.).

`ownsCompaction: true` → engine owns all compaction, OpenClaw disables built-in auto-compaction.
`ownsCompaction: false` → Pi's built-in may still run, but engine's `compact()` handles `/compact` and overflow recovery.

---

## 5. Memory (Advanced)

### Memory Architecture

Memory = plain Markdown in agent workspace. Files are source of truth. Model only "remembers" what's written to disk.

Two layers:
- `memory/YYYY-MM-DD.md` — daily log (append-only), read today + yesterday at session start
- `MEMORY.md` — curated long-term memory, loaded in main/private session only (never in group contexts). `MEMORY.md` takes precedence over lowercase `memory.md`.

### Memory Tools

- `memory_search` — semantic recall over indexed snippets
- `memory_get` — targeted read of specific Markdown file/line range

Both degrade gracefully when file doesn't exist (return empty instead of throwing `ENOENT`).

### When to Write Memory

- Decisions, preferences, durable facts → `MEMORY.md`
- Day-to-day notes and running context → `memory/YYYY-MM-DD.md`
- "Remember this" requests → write immediately, don't keep in RAM

### Memory Backend Options

Default backend: `memory-core` (builtin). Disable: `plugins.slots.memory = "none"`.

**Vector memory search:** builds small vector index over `MEMORY.md` and `memory/*.md` for semantic queries. Supports:
- Multiple embedding providers: OpenAI, Gemini, Voyage, Mistral, Ollama, local GGUF
- Optional QMD sidecar backend for advanced retrieval
- Post-processing: MMR diversity re-ranking, temporal decay
- Hybrid search: BM25 + vector

Full config reference: `/reference/memory-config` (embedding provider setup, QMD backend, hybrid search tuning, multimodal memory).

### Memory Flush Config (Pre-Compaction)

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "reserveTokensFloor": 20000,
        "memoryFlush": {
          "enabled": true,
          "softThresholdTokens": 4000,
          "systemPrompt": "Session nearing compaction. Store durable memories now.",
          "prompt": "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store."
        }
      }
    }
  }
}
```

---

## 6. Heartbeat (Advanced Config)

### What Heartbeat Is

Heartbeat runs **periodic agent turns** in the main session so the model can surface anything that needs attention without spamming you.

Default interval: `30m` (or `1h` for Anthropic OAuth/setup-token).

### Full Config Reference

```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "30m",
        "model": "anthropic/claude-opus-4-6",
        "includeReasoning": false,
        "lightContext": false,
        "isolatedSession": false,
        "target": "last",
        "to": "+15551234567",
        "accountId": "ops-bot",
        "prompt": "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.",
        "ackMaxChars": 300,
        "suppressToolErrorWarnings": false,
        "activeHours": {
          "start": "09:00",
          "end": "22:00",
          "timezone": "America/New_York"
        },
        "session": "main",
        "directPolicy": "allow"
      }
    }
  }
}
```

### Field Reference

| Field | Default | Description |
|---|---|---|
| `every` | `30m` | Interval (duration string; `0m` disables) |
| `model` | (agent primary) | Optional model override for heartbeat runs |
| `includeReasoning` | `false` | Also deliver separate `Reasoning:` message |
| `lightContext` | `false` | Only inject HEARTBEAT.md from workspace bootstrap files |
| `isolatedSession` | `false` | Each heartbeat in fresh session (no conversation history) |
| `target` | `none` | `last` \| `none` \| channel id (e.g. `"telegram"`, `"whatsapp"`) |
| `to` | — | Recipient override (E.164, chat id, `<chatId>:topic:<threadId>`) |
| `accountId` | — | Account id for multi-account channels |
| `prompt` | (default text) | Override default prompt body (not merged) |
| `ackMaxChars` | `300` | Max chars allowed after HEARTBEAT_OK |
| `suppressToolErrorWarnings` | `false` | Suppress tool error warning payloads |
| `activeHours` | (always) | Time window: `start` (HH:MM), `end` (HH:MM, 24:00 ok), `timezone` |
| `session` | `main` | Session key for heartbeat runs |
| `directPolicy` | `allow` | `allow` or `block` for direct/DM targets |

### HEARTBEAT_OK Response Contract

- If nothing needs attention → reply `HEARTBEAT_OK`
- `HEARTBEAT_OK` at **start or end** of reply → stripped if remaining content ≤ `ackMaxChars`
- `HEARTBEAT_OK` in the **middle** → not treated specially
- For alerts → do NOT include `HEARTBEAT_OK`, return only alert text
- If HEARTBEAT.md is missing → heartbeat still runs
- If HEARTBEAT.md is effectively empty (only blank lines + headers) → heartbeat SKIPPED

### Cost Reduction Tips

- `isolatedSession: true` → ~100K tokens down to ~2-5K per run
- `lightContext: true` → limit bootstrap to HEARTBEAT.md only
- Set cheaper `model` (e.g. `ollama/llama3.2:1b`)
- Keep HEARTBEAT.md small
- `target: "none"` for internal state updates only

### Scope and Precedence

1. `channels.<channel>.accounts.<id>.heartbeat` (highest)
2. `channels.<channel>.heartbeat`
3. `channels.defaults.heartbeat`
4. `agents.list[].heartbeat` (per-agent override)
5. `agents.defaults.heartbeat` (global baseline)

If ANY `agents.list[]` entry has a `heartbeat` block, ONLY those agents run heartbeats.

### activeHours Timezone Options

- Omitted or `"user"`: uses `agents.defaults.userTimezone` or host tz
- `"local"`: always host tz
- IANA identifier (e.g. `"Asia/Kuala_Lumpur"`): used directly
- Same `start` + `end` = zero-width window = heartbeats always skipped (bug trap)

### Visibility Controls

```yaml
channels:
  defaults:
    heartbeat:
      showOk: false       # Hide HEARTBEAT_OK (default)
      showAlerts: true    # Show alert messages (default)
      useIndicator: true  # Emit indicator events (default)
  telegram:
    heartbeat:
      showOk: true        # Show OK acknowledgments on Telegram
```

If all three (`showOk`, `showAlerts`, `useIndicator`) are `false`, OpenClaw skips heartbeat run entirely.

### Manual Wake

```bash
openclaw system event --text "Check for urgent follow-ups" --mode now
openclaw system event --text "Check for urgent follow-ups" --mode next-heartbeat
```

### Telegram Topic Routing

Use `to: "<chatId>:topic:<messageThreadId>"`:
```json
{
  "heartbeat": {
    "every": "1h",
    "target": "telegram",
    "to": "12345678:topic:42",
    "accountId": "ops-bot"
  }
}
```

---

## 7. Remote Gateway

### Core Idea

- Gateway WebSocket binds to **loopback** on port 18789 (default)
- For remote use: forward loopback port over SSH, or use tailnet/VPN

### Remote Mode Config

```json
{
  "gateway": {
    "mode": "remote",
    "remote": {
      "url": "ws://127.0.0.1:18789",
      "token": "your-token"
    }
  }
}
```

Or with wss:
```json
{
  "gateway": {
    "remote": {
      "url": "wss://gateway-host:18789",
      "token": "your-token",
      "tlsFingerprint": "<fingerprint>"
    }
  }
}
```

### CLI Config

```bash
openclaw config set gateway.remote.url wss://gateway-host:18789
openclaw config set gateway.remote.token <token>
```

Or flags per command:
```bash
openclaw acp --url wss://gateway-host:18789 --token-file ~/.openclaw/gateway.token
```

### SSH Tunnel

```bash
ssh -N -L 18789:127.0.0.1:18789 user@host
```

With tunnel up: `openclaw health`, `openclaw status --deep`, `openclaw gateway call` all reach remote.

### Credential Precedence

**Local mode:**
- token: `OPENCLAW_GATEWAY_TOKEN` → `gateway.auth.token` → `gateway.remote.token` (fallback only if local unset)
- password: `OPENCLAW_GATEWAY_PASSWORD` → `gateway.auth.password` → `gateway.remote.password`

**Remote mode:**
- token: `gateway.remote.token` → `OPENCLAW_GATEWAY_TOKEN` → `gateway.auth.token`
- password: `OPENCLAW_GATEWAY_PASSWORD` → `gateway.remote.password` → `gateway.auth.password`

**Important:** CLI `--url` overrides NEVER reuse implicit config/env credentials. Pass `--token` or `--password` explicitly.

### Tailscale Integration

```json
{
  "gateway": {
    "auth": {
      "allowTailscale": true
    }
  }
}
```

Authenticates Control UI/WebSocket via Tailscale identity headers. HTTP API endpoints still require token/password auth.

### Security Rules

- Keep Gateway loopback-only unless you need broader bind
- Plaintext `ws://` loopback-only by default; for private networks: `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1`
- Non-loopback binds (`lan`/`tailnet`/`custom`) MUST use auth tokens/passwords
- `gateway.remote.token`/`.password` are CLIENT credential sources, not server auth config
- `gateway.remote.tlsFingerprint` pins remote TLS cert for `wss://`

### Bootstrap Token (Node Pairing)

Used for initial node pairing (iOS/Android companion apps). Separate from gateway auth token. See node-connect skill for details.

### Multiple Gateways on Same Host

Isolation checklist (all required):
- `OPENCLAW_CONFIG_PATH` — per-instance config
- `OPENCLAW_STATE_DIR` — per-instance sessions/creds/caches
- `agents.defaults.workspace` — per-instance workspace root
- `gateway.port` — unique per instance (use `--port`)
- Derived ports (browser: base+2, CDP: auto-allocate) must not overlap

**Recommended approach: profiles**
```bash
openclaw --profile main gateway --port 18789
openclaw --profile rescue gateway --port 19001
```

**Port spacing:** leave at least 20 ports between base ports.

---

## 8. OpenShell Sandbox

### What It Is

OpenShell is a **managed sandbox backend** for OpenClaw. Instead of local Docker containers, OpenClaw delegates sandbox lifecycle to the `openshell` CLI, which provisions remote environments with SSH-based command execution.

Reuses the same core SSH transport as the generic SSH backend, adds:
- OpenShell-specific lifecycle (`sandbox create/get/delete`, `sandbox ssh-config`)
- Optional `mirror` workspace mode (bidirectional sync)

### Sandbox Backend Comparison

| | Docker | SSH | OpenShell |
|---|---|---|---|
| Where it runs | Local container | Any SSH host | OpenShell managed |
| Setup | `scripts/sandbox-setup.sh` | SSH key + target | OpenShell plugin + CLI |
| Workspace model | Bind-mount or copy | Remote-canonical (seed once) | `mirror` or `remote` |
| Network control | `docker.network` | Depends on remote | Depends on OpenShell |
| Browser sandbox | Supported | Not supported | Not supported yet |
| Best for | Local dev, full isolation | Offloading to remote | Managed remote + optional two-way sync |

### Enable OpenShell

```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",
        "backend": "openshell",
        "scope": "session",
        "workspaceAccess": "rw"
      }
    }
  },
  "plugins": {
    "entries": {
      "openshell": {
        "enabled": true,
        "config": {
          "from": "openclaw",
          "mode": "remote",
          "remoteWorkspaceDir": "/sandbox",
          "remoteAgentWorkspaceDir": "/agent"
        }
      }
    }
  }
}
```

### Workspace Modes

#### `mirror` (local stays canonical)

Behavior:
- Before `exec`: OpenClaw syncs local workspace INTO OpenShell sandbox
- After `exec`: OpenClaw syncs remote workspace BACK to local workspace
- File tools operate through sandbox bridge
- Local workspace = source of truth between turns

Use when:
- You edit files locally outside OpenClaw and want changes visible in sandbox
- You want OpenShell to behave like Docker backend
- You want host workspace to reflect sandbox writes after each turn

Tradeoff: extra sync cost before and after exec.

#### `remote` (OpenShell workspace is canonical)

Behavior:
- First sandbox creation: OpenClaw seeds remote workspace from local workspace ONCE
- After that: `exec`, `read`, `write`, `edit`, `apply_patch` operate DIRECTLY against remote OpenShell
- OpenClaw does NOT sync remote changes back

Use when:
- Sandbox should live primarily on the remote side
- Lower per-turn sync overhead
- Don't want host-local edits to silently overwrite remote state

**Important:** after host edits, use `openclaw sandbox recreate` to re-seed.

### OpenShell Config Reference

All config under `plugins.entries.openshell.config`:

| Key | Type | Default | Description |
|---|---|---|---|
| `mode` | `"mirror"` or `"remote"` | `"mirror"` | Workspace sync mode |
| `command` | string | `"openshell"` | Path/name of `openshell` CLI |
| `from` | string | `"openclaw"` | Sandbox source for first-time create |
| `gateway` | string | — | OpenShell gateway name (`--gateway`) |
| `gatewayEndpoint` | string | — | OpenShell gateway endpoint URL |
| `policy` | string | — | OpenShell policy ID for sandbox creation |
| `providers` | string[] | `[]` | Provider names to attach when sandbox created |
| `gpu` | boolean | `false` | Request GPU resources |
| `autoProviders` | boolean | `true` | Pass `--auto-providers` during create |
| `remoteWorkspaceDir` | string | `"/sandbox"` | Primary writable workspace inside sandbox |
| `remoteAgentWorkspaceDir` | string | `"/agent"` | Agent workspace mount (read-only access) |
| `timeoutSeconds` | number | `120` | Timeout for `openshell` CLI operations |

### Sandbox Scope Options

- `"session"` (default): one container per session
- `"agent"`: one container per agent
- `"shared"`: one container shared by all sandboxed sessions

### Sandbox Mode Options

- `"off"`: no sandboxing
- `"non-main"`: sandbox only non-main sessions (group/channel)
- `"all"`: every session sandboxed

### workspaceAccess Options

- `"none"` (default): tools see sandbox workspace under `~/.openclaw/sandboxes`
- `"ro"`: mounts agent workspace read-only at `/agent`
- `"rw"`: mounts agent workspace read/write at `/workspace`

### Lifecycle Commands

```bash
openclaw sandbox list
openclaw sandbox explain
openclaw sandbox recreate --all
```

Recreate after changing: `backend`, `from`, `mode`, `policy`.

### Current OpenShell Limitations

- Sandbox browser NOT supported
- `sandbox.docker.binds` does NOT apply
- Docker-specific `sandbox.docker.*` knobs only for Docker backend

---

## 9. LLM-Task Tool

### What It Does

`llm-task` is an **optional plugin tool** that runs a JSON-only LLM task and returns structured output, optionally validated against JSON Schema.

**Use case:** workflow engines like Lobster — add a single LLM step without custom OpenClaw code. Keeps workflow deterministic while allowing classification/summarization/drafting.

### Enable

```json
{
  "plugins": {
    "entries": {
      "llm-task": { "enabled": true }
    }
  },
  "agents": {
    "list": [
      {
        "id": "main",
        "tools": { "allow": ["llm-task"] }
      }
    ]
  }
}
```

Note: registered with `optional: true`, so must be explicitly allowlisted.

### Optional Config

```json
{
  "plugins": {
    "entries": {
      "llm-task": {
        "enabled": true,
        "config": {
          "defaultProvider": "openai-codex",
          "defaultModel": "gpt-5.4",
          "defaultAuthProfileId": "main",
          "allowedModels": ["openai-codex/gpt-5.4"],
          "maxTokens": 800,
          "timeoutMs": 30000
        }
      }
    }
  }
}
```

`allowedModels`: allowlist of `provider/model` strings. If set, requests outside list are rejected.

### Tool Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `prompt` | string | Yes | The task prompt |
| `input` | any | No | Input data passed to model |
| `schema` | object | No | JSON Schema for output validation |
| `provider` | string | No | Override provider |
| `model` | string | No | Override model |
| `thinking` | string | No | Reasoning preset: `"low"`, `"medium"` |
| `authProfileId` | string | No | Override auth profile |
| `temperature` | number | No | Override temperature |
| `maxTokens` | number | No | Override max tokens |
| `timeoutMs` | number | No | Override timeout |

### Output

Returns `details.json` containing parsed JSON, validated against `schema` when provided.

### Example: Lobster Workflow Step

```lobster
openclaw.invoke --tool llm-task --action json --args-json '{
  "prompt": "Given the input email, return intent and draft.",
  "thinking": "low",
  "input": {
    "subject": "Hello",
    "body": "Can you help?"
  },
  "schema": {
    "type": "object",
    "properties": {
      "intent": { "type": "string" },
      "draft": { "type": "string" }
    },
    "required": ["intent", "draft"],
    "additionalProperties": false
  }
}'
```

### Safety Notes

- JSON-only: model instructed to output only JSON (no code fences, no commentary)
- No tools exposed to model for this run
- Treat output as untrusted unless validated with `schema`
- Put approvals BEFORE any side-effecting step (send, post, exec)

### When to Use vs Regular Agent Turn

- **Use llm-task**: when you need structured JSON output in a deterministic pipeline (Lobster workflow, data transformation, classification)
- **Use regular agent turn**: when you need tools, tool loops, file access, or conversational flow

---

## 10. BTW Side Questions

### What It Does

`/btw` lets you ask a quick side question about the current session without polluting conversation history.

Mental model:
- Same session context (as background only)
- Separate one-shot side query
- No tool calls
- No future context pollution
- No transcript persistence (ephemeral)

### How to Use

```
/btw what changed?
/btw what file are we editing?
/btw what does this error mean?
/btw summarize the current task in one sentence
/btw what is 17 * 19?
```

### What It Does NOT Do

- Does NOT create a new durable session
- Does NOT continue unfinished main task
- Does NOT run tools or agent tool loops
- Does NOT write BTW question/answer to transcript history
- Does NOT appear in `chat.history`
- Does NOT survive a reload

### How Context Works

If main run is currently active, OpenClaw snapshots current message state and includes in-flight main prompt as background context, while explicitly telling model:
- Answer only the side question
- Do not resume or complete the unfinished main task
- Do not emit tool calls or pseudo-tool calls

### Delivery Model

BTW uses `chat.side_result` event (NOT `chat` event). This separation prevents clients from treating it as regular conversation history.

**Platform behavior:**
- **TUI**: rendered inline, visibly distinct, dismissible with `Enter` or `Esc`, not replayed on reload
- **External channels** (Telegram, WhatsApp, Discord): delivered as clearly labeled one-off reply
- **Control UI/web**: Gateway emits correctly as `chat.side_result`; client-side rendering still pending in some UIs

### When to Use BTW vs Normal

- **BTW**: quick clarification, factual side answer, temporary answer that should NOT become future context
- **Normal message**: when you WANT the answer to become part of session's future working context

---

## 11. Lobster (Deterministic Workflow Pipelines)

### What It Is

Lobster is a workflow shell that lets OpenClaw run multi-step tool sequences as a single, deterministic operation with explicit **approval checkpoints**.

Key value props:
- **One call instead of many**: one Lobster tool call → structured result (vs many back-and-forth)
- **Approvals built in**: side effects halt workflow until explicitly approved
- **Resumable**: halted workflows return a token; approve and resume without re-running

### How It Works

OpenClaw launches local `lobster` CLI in **tool mode** and parses a JSON envelope from stdout. If pipeline pauses for approval, tool returns `resumeToken` to continue later.

### Enable Lobster

Lobster is an **optional plugin tool** (not enabled by default).

Recommended (additive, safe — doesn't override core tools):
```json
{
  "tools": {
    "alsoAllow": ["lobster"]
  }
}
```

Per-agent:
```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "tools": {
          "alsoAllow": ["lobster"]
        }
      }
    ]
  }
}
```

**Avoid** `tools.allow: ["lobster"]` unless you want restrictive allowlist mode.

### Tool Parameters

#### `run` action

```json
{
  "action": "run",
  "pipeline": "gog.gmail.search --query 'newer_than:1d' | email.triage",
  "cwd": "workspace",
  "timeoutMs": 30000,
  "maxStdoutBytes": 512000
}
```

Run workflow file with args:
```json
{
  "action": "run",
  "pipeline": "/path/to/inbox-triage.lobster",
  "argsJson": "{\"tag\":\"family\"}"
}
```

#### `resume` action

```json
{
  "action": "resume",
  "token": "<resumeToken>",
  "approve": true
}
```

Set `approve: false` to cancel/deny.

#### Optional params

| Param | Default | Description |
|---|---|---|
| `cwd` | — | Relative working directory (must stay within process cwd) |
| `timeoutMs` | `20000` | Kill subprocess if exceeded |
| `maxStdoutBytes` | `512000` | Kill subprocess if stdout exceeds this |
| `argsJson` | — | JSON string passed to `lobster run --args-json` (workflow files only) |

### Output Envelope

Returns JSON with one of three statuses:

```json
{
  "ok": true,
  "status": "needs_approval",
  "output": [{ "summary": "5 need replies, 2 need action" }],
  "requiresApproval": {
    "type": "approval_request",
    "prompt": "Send 2 draft replies?",
    "items": [],
    "resumeToken": "..."
  }
}
```

Status values:
- `ok` → finished successfully
- `needs_approval` → paused; `requiresApproval.resumeToken` needed to resume
- `cancelled` → explicitly denied or cancelled

### Workflow Files (.lobster)

YAML/JSON with `name`, `args`, `steps`, `env`, `condition`, `approval` fields:

```yaml
name: inbox-triage
args:
  tag:
    default: "family"
steps:
  - id: collect
    command: inbox list --json
  - id: categorize
    command: inbox categorize --json
    stdin: $collect.stdout
  - id: approve
    command: inbox apply --approve
    stdin: $categorize.stdout
    approval: required
  - id: execute
    command: inbox apply --execute
    stdin: $categorize.stdout
    condition: $approve.approved
```

Notes:
- `stdin: $step.stdout` and `stdin: $step.json` pass prior step output
- `condition` (or `when`) can gate steps on `$step.approved`

### Inline Pipeline Syntax

```bash
# Map items into tool calls
gog.gmail.search --query 'newer_than:1d' \
  | openclaw.invoke --tool message --action send --each --item-key message --args-json '{"provider":"telegram","to":"..."}'
```

```bash
# Chain small CLIs
inbox list --json | inbox categorize --json | inbox apply --json
```

### Approval Gates Pattern

1. Pipeline runs → hits `approve` step
2. OpenClaw tool returns `needs_approval` with `resumeToken`
3. User reviews, sends approve/reject
4. OpenClaw calls `resume` with `token` + `approve: true/false`
5. Pipeline continues (or cancels)

### Cron + Heartbeat Integration

Lobster pairs well with cron and heartbeat for automated pipelines:
- Cron triggers a session turn at scheduled time
- Agent calls Lobster tool with pipeline
- If needs approval → pauses, notifies user
- User approves → pipeline resumes

Example: daily email triage at 9am via cron → Lobster email.triage → pause for approval → resume on approval.

### Lobster + LLM-Task

For pipelines needing structured LLM steps within Lobster, use `llm-task`:

```lobster
openclaw.invoke --tool llm-task --action json --args-json '{
  "prompt": "Classify this email as urgent/routine/spam.",
  "input": { "subject": "...", "body": "..." },
  "schema": {
    "type": "object",
    "properties": {
      "category": { "type": "string", "enum": ["urgent", "routine", "spam"] }
    },
    "required": ["category"]
  }
}'
```

### Safety Properties

- **Local subprocess only**: no network calls from plugin itself
- **No secrets management**: calls OpenClaw tools that handle OAuth
- **Sandbox-aware**: disabled when tool context is sandboxed
- **Hardened**: fixed executable name (`lobster`) on PATH; timeouts and output caps enforced

### Troubleshooting

| Symptom | Fix |
|---|---|
| `lobster subprocess timed out` | Increase `timeoutMs` or split long pipeline |
| `lobster output exceeded maxStdoutBytes` | Raise `maxStdoutBytes` or reduce output |
| `lobster returned invalid JSON` | Ensure pipeline runs in tool mode, prints only JSON |
| `lobster failed (code …)` | Run same pipeline in terminal to inspect stderr |

### ACP Agent Bindings (Persistent Conversations)

For persistent ACP bindings to Discord/Telegram topics:

```json
{
  "bindings": [
    {
      "type": "acp",
      "agentId": "codex",
      "match": {
        "channel": "telegram",
        "peer": { "kind": "group", "id": "-1001234567890:topic:42" }
      },
      "acp": { "cwd": "/workspace/repo", "mode": "persistent" }
    }
  ]
}
```

Telegram topic ID format: `-100<chatId>:topic:<N>` (where `-100<chatId>` is the group/supergroup id and `N` is the thread id).

---

## 12. ACP Agents (External Coding Harnesses)

### What It Is

ACP agents let OpenClaw run external coding harnesses (Pi, Claude Code, Codex, OpenCode, Gemini CLI) through an ACP backend plugin.

Session key: `agent:<agentId>:acp:<uuid>` (vs `agent:<agentId>:subagent:<uuid>` for sub-agents)

### ACP vs Sub-Agents

| Area | ACP session | Sub-agent run |
|---|---|---|
| Runtime | ACP backend plugin (acpx) | OpenClaw native |
| Session key | `agent:<agentId>:acp:<uuid>` | `agent:<agentId>:subagent:<uuid>` |
| Main commands | `/acp ...` | `/subagents ...` |
| Spawn tool | `sessions_spawn` with `runtime:"acp"` | `sessions_spawn` (default) |

### ACP Config

```json
{
  "acp": {
    "enabled": true,
    "dispatch": { "enabled": true },
    "backend": "acpx",
    "defaultAgent": "codex",
    "allowedAgents": ["pi", "claude", "codex", "opencode", "gemini", "kimi"],
    "maxConcurrentSessions": 8,
    "stream": {
      "coalesceIdleMs": 300,
      "maxChunkChars": 1200
    },
    "runtime": {
      "ttlMinutes": 120
    }
  }
}
```

### Spawn ACP Session from Tool

```json
{
  "task": "Open the repo and summarize failing tests",
  "runtime": "acp",
  "agentId": "codex",
  "thread": true,
  "mode": "session"
}
```

- `mode: "session"` requires `thread: true`
- `mode: "run"` = one-shot

### ACP Permission Config

```bash
openclaw config set plugins.entries.acpx.config.permissionMode approve-all
openclaw config set plugins.entries.acpx.config.nonInteractivePermissions fail
```

| `permissionMode` | Behavior |
|---|---|
| `approve-all` | Auto-approve all file writes + shell commands |
| `approve-reads` | Auto-approve reads only (default) |
| `deny-all` | Deny all permission prompts |

| `nonInteractivePermissions` | Behavior |
|---|---|
| `fail` | Abort session with AcpRuntimeError (default) |
| `deny` | Silently deny permission, continue gracefully |

**Important:** default `approve-reads` + `fail` means write/exec in ACP sessions can throw `AcpRuntimeError`. Use `approve-all` or `nonInteractivePermissions: deny` for graceful operation.

---

## Our Setup Notes (7-Agent System)

### Current Configuration Context

- **Version**: 2026.3.13 (running), 2026.3.14 (source, one ahead)
- **Deployment**: Docker on Hostinger VPS (72.61.127.59)
- **Container**: openclaw-okny-openclaw-1
- **Gateway port**: 18789 (loopback bind)
- **Auth**: Anthropic API (token mode)
- **Primary model**: anthropic/claude-sonnet-4-6

### Active Agents

| Agent | Channel | Model | Notes |
|---|---|---|---|
| Maks (main) | Telegram (primary bot) | claude-sonnet-4-6 | Coding, general |
| MaksPM | Telegram (@VPSPMClawBot) | claude-opus-4-6 | Orchestrator |
| Scout | Telegram (research bot) | claude-opus-4-6 | Research |
| ClawExpert | Telegram (ops bot) | claude-sonnet-4-6 | Ops, monitoring (me) |
| Launch | Telegram (@PerlantirLaunchBot) | claude-opus-4-6 | GTM |
| Pixel (design) | TBD | TBD | UI/UX |
| Forge (build) | TBD | TBD | Build/QA |

### ACP Protocol Applicability

ACP is most relevant for:
- Connecting Zed or other ACP-aware IDEs to any of our agents via `openclaw acp --session agent:<id>:main`
- Using Claude Code from Codex-style tooling: `acpx openclaw exec "Ask Maks for context"`
- Our remote gateway setup (VPS) means ACP clients need `--url wss://72.61.127.59:18789 --token <token>` (or via SSH tunnel on port 18789)

### Multi-Agent Pipeline (MaksPM Orchestrator)

Current pipeline: Nick → MaksPM → Scout → Pixel → Maks → Forge → MaksPM QA → Launch

For subagent spawning in this pipeline:
- MaksPM would need `maxSpawnDepth: 2` to spawn and coordinate child agents
- Per-agent `allowAgents` lists need to explicitly permit cross-agent spawning
- `sessions_send` is the current inter-agent communication mechanism (requires `tools.agentToAgent.enabled: true`)

### Heartbeat Configuration

Current heartbeats should use `isolatedSession: true` + `lightContext: true` to minimize token cost on VPS. Recommended target: `"last"` with Telegram as primary channel.

For ClawExpert ops monitoring: heartbeat with `activeHours: { start: "08:00", end: "24:00", timezone: "Asia/Kuala_Lumpur" }`.

### Remote Gateway Access

Our VPS setup: loopback bind + SSH tunnel for remote access. Token auth. `gateway.remote.url` + `gateway.remote.token` for CLI config.

ACP from macOS: `openclaw acp --url ws://127.0.0.1:18789 --token-file ~/.openclaw/gateway.token` (after SSH tunnel).

### Sandbox Configuration

Currently using Docker sandbox. Per SOUL.md rules: never suggest mcpServers in openclaw.json. MCP via mcporter bridge only.

For agents handling untrusted input (e.g., Scout processing external websites), `sandbox.mode: "non-main"` is appropriate.

### Memory Architecture

All agents use workspace-based memory:
- `/data/.openclaw/workspace-clawexpert/memory/` for ClawExpert
- `/data/.openclaw/workspace/memory/` for Maks/Scout
- MEMORY.md for curated long-term knowledge

Memory flush before compaction is enabled by default — ensure workspace is writable (not `ro`).

### Lobster/LLM-Task Potential

High value for Nick's pipeline:
- Lobster for deterministic email triage, deploy workflows, approval gates
- `llm-task` for structured classification within Lobster (intent detection, priority scoring)
- Pairs with heartbeat cron for scheduled automated pipelines
- `needs_approval` flow = natural fit for Telegram approval bot pattern

### BTW Usage

`/btw` is available in any session. Useful during long coding runs with Maks to ask side questions without polluting the session context (e.g., `/btw what's the current git branch?` while a large refactor is in progress).

---

*Sources: docs.openclaw.ai (2026-03-20), repos/openclaw/docs.acp.md (local)*
