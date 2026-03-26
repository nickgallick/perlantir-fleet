---
name: openclaw-concepts
description: Expert reference for all OpenClaw core concepts — agents, sessions, context, compaction, memory, multi-agent routing, model providers, failover, streaming, queues, pruning, system prompt, timezones, usage tracking, and features.
---

# OpenClaw Concepts

## Changelog
- 2026-03-20: Created from source docs — 19 concept files covering agent runtime, loop, workspace, architecture, sessions, context, context-engine, compaction, memory, multi-agent, model-providers, model-failover, streaming, queue, session-pruning, system-prompt, timezone, usage-tracking, features

---

## Agent Runtime

OpenClaw runs a single embedded agent runtime derived from **pi-mono**.

### Workspace (required)
`agents.defaults.workspace` is the agent's **only** working directory for tools and context. Default: `~/.openclaw/workspace`.

**Important**: workspace is the **default cwd**, not a hard sandbox. Absolute paths can reach outside unless sandboxing is enabled.

### Bootstrap Files (injected on first turn)
| File | Purpose |
|------|---------|
| `AGENTS.md` | Operating instructions + memory |
| `SOUL.md` | Persona, boundaries, tone |
| `TOOLS.md` | Tool usage guidance (not access control) |
| `BOOTSTRAP.md` | One-time first-run ritual (deleted after) |
| `IDENTITY.md` | Agent name/vibe/emoji |
| `USER.md` | User profile + preferred address |
| `HEARTBEAT.md` | Periodic checklist for heartbeat runs |
| `BOOT.md` | Startup checklist (via boot-md hook) |

Blank files skipped. Large files trimmed (per-file: `bootstrapMaxChars` default 20000; total: `bootstrapTotalMaxChars` default 150000).

### Skills Loading (3 locations, workspace wins on conflict)
1. Bundled (shipped with install)
2. Managed/local: `~/.openclaw/skills`
3. Workspace: `<workspace>/skills`

### Session Transcripts
`~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl`

### Model Refs
Use `provider/model` format. If model ID contains `/` (OpenRouter-style), include provider prefix: `openrouter/moonshotai/kimi-k2`.

### Block Streaming (steering)
When queue mode is `steer`, inbound messages inject into current run after each tool call. Remaining tool calls from current assistant message are skipped with "Skipped due to queued user message."

---

## Agent Loop

The agent loop is the full run: intake → context assembly → model inference → tool execution → streaming replies → persistence.

### Entry Points
- Gateway RPC: `agent` and `agent.wait`
- CLI: `agent` command

### How It Works
1. `agent` RPC validates params, resolves session, persists metadata → returns `{ runId, acceptedAt }` immediately
2. `agentCommand` runs agent: resolves model, loads skills, calls `runEmbeddedPiAgent`
3. `runEmbeddedPiAgent`: serializes via per-session + global queues, resolves model + auth, subscribes to pi events
4. Events bridge: tool events → `stream:"tool"`, assistant deltas → `stream:"assistant"`, lifecycle → `stream:"lifecycle"`
5. `agent.wait` waits for lifecycle end/error for `runId` → `{ status: ok|error|timeout, startedAt, endedAt, error? }`

### Queueing + Concurrency
Runs serialized per session key (session lane) then through global lane. Prevents tool/session races.

### Hook Points

**Internal hooks (Gateway hooks):**
- `agent:bootstrap` — before bootstrap files injected (can mutate `context.bootstrapFiles`)
- Command hooks: `/new`, `/reset`, `/stop`, other commands

**Plugin hooks (agent + gateway lifecycle):**
- `before_model_resolve` — pre-session, override provider/model
- `before_prompt_build` — inject `prependContext`, `systemPrompt`, `prependSystemContext`, `appendSystemContext`
- `before_agent_start` — legacy compatibility
- `agent_end` — inspect final message list after completion
- `before_compaction` / `after_compaction`
- `before_tool_call` / `after_tool_call`
- `tool_result_persist` — synchronously transform tool results before transcript write
- `message_received` / `message_sending` / `message_sent`
- `session_start` / `session_end`
- `gateway_start` / `gateway_stop`

### Timeouts
- `agent.wait` default: 30s (`timeoutMs` param overrides)
- Agent runtime: `agents.defaults.timeoutSeconds` default 600s

### Reply Shaping
- `NO_REPLY` → silent token, filtered from outgoing payloads
- Messaging tool duplicates removed from final payload
- If no renderable payloads remain and tool errored → fallback tool error reply

---

## Agent Workspace

The workspace is the agent's home — its only working directory.

### Default Location
- Default: `~/.openclaw/workspace`
- With `OPENCLAW_PROFILE` set and not `"default"`: `~/.openclaw/workspace-<profile>`
- Override: `agent.workspace` in config

### Workspace File Map
| File | Description |
|------|-------------|
| `AGENTS.md` | Operating instructions; loaded every session |
| `SOUL.md` | Persona, tone, boundaries; loaded every session |
| `USER.md` | Who the user is and how to address them |
| `IDENTITY.md` | Agent name, vibe, emoji |
| `TOOLS.md` | Notes about local tools (guidance only) |
| `HEARTBEAT.md` | Optional tiny checklist for heartbeat runs |
| `BOOT.md` | Optional startup checklist on gateway restart |
| `BOOTSTRAP.md` | One-time first-run ritual; delete when done |
| `memory/YYYY-MM-DD.md` | Daily memory log (one per day) |
| `MEMORY.md` | Curated long-term memory (optional) |
| `skills/` | Workspace-specific skills |
| `canvas/` | Canvas UI files |

### Git Backup (recommended)
```bash
cd ~/.openclaw/workspace
git init
git add AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md memory/
git commit -m "Add agent workspace"
gh repo create openclaw-workspace --private --source . --remote origin --push
```

### Bootstrap Limits
- Per-file: `agents.defaults.bootstrapMaxChars` (default 20000)
- Total: `agents.defaults.bootstrapTotalMaxChars` (default 150000)
- Truncation warning: `agents.defaults.bootstrapPromptTruncationWarning` (`off`|`once`|`always`; default `once`)

---

## Gateway Architecture

Single long-lived Gateway owns all messaging surfaces.

### Components
- **Gateway (daemon)**: maintains provider connections, exposes typed WS API, validates inbound frames, emits events (`agent`, `chat`, `presence`, `health`, `heartbeat`, `cron`)
- **Clients** (mac app/CLI/web admin): send requests, subscribe to events
- **Nodes** (macOS/iOS/Android/headless): connect with `role: node`, provide device identity, expose commands (`canvas.*`, `camera.*`, `screen.record`, `location.get`)
- **Canvas host**: served under `/__openclaw__/canvas/` and `/__openclaw__/a2ui/`

### Wire Protocol
- Transport: WebSocket, text frames, JSON payloads
- First frame **must** be `connect`
- Requests: `{type:"req", id, method, params}` → `{type:"res", id, ok, payload|error}`
- Events: `{type:"event", event, payload, seq?, stateVersion?}`
- If `OPENCLAW_GATEWAY_TOKEN` set: `connect.params.auth.token` must match or socket closes

### Pairing + Local Trust
- All WS clients include device identity on `connect`
- New device IDs require pairing approval → device token issued
- Local connects (loopback/tailnet) can be auto-approved
- All connects sign `connect.challenge` nonce
- v3 signature also binds `platform` + `deviceFamily`

### Remote Access
```bash
# SSH tunnel
ssh -N -L 18789:127.0.0.1:18789 user@host
# Same handshake + auth token apply over tunnel
```

---

## Session Management

### Session Keys
- Direct chats follow `session.dmScope` (default `main`):
  - `main` → `agent:<agentId>:<mainKey>`
  - `per-peer` → `agent:<agentId>:direct:<peerId>`
  - `per-channel-peer` → `agent:<agentId>:<channel>:direct:<peerId>`
  - `per-account-channel-peer` → `agent:<agentId>:<channel>:<accountId>:direct:<peerId>`
- Group chats → `agent:<agentId>:<channel>:group:<id>`
- Telegram forum topics → append `:topic:<threadId>`
- Cron jobs → `cron:<job.id>` (isolated) or `session:<custom-id>` (persistent)
- Webhooks → `hook:<uuid>`
- Node runs → `node-<nodeId>`

### Secure DM Mode
```json5
{ session: { dmScope: "per-channel-peer" } }
```
Without this, all users share the same conversation context (data leak risk).

### Lifecycle + Resets
- Daily reset: default 4:00 AM local time on gateway host
- Idle reset: `idleMinutes` adds sliding window (whichever expires first wins)
- `resetTriggers`: `/new`, `/reset` (configurable)
- `/new <model>` accepts model alias, `provider/model`, or provider name

### Maintenance Defaults
- `session.maintenance.mode`: `warn`
- `pruneAfter`: `30d`
- `maxEntries`: `500`
- `rotateBytes`: `10mb`
- `resetArchiveRetention`: `30d`

Modes: `warn` (reports only), `enforce` (applies cleanup).

**Enforce order**: prune stale → cap entry count → archive transcripts → purge archives → rotate sessions.json → enforce disk budget.

```json5
{ session: { maintenance: { mode: "enforce", pruneAfter: "45d", maxEntries: 800 } } }
```

### Send Policy
```json5
{
  session: {
    sendPolicy: {
      rules: [
        { action: "deny", match: { channel: "discord", chatType: "group" } },
        { action: "deny", match: { keyPrefix: "cron:" } },
      ],
      default: "allow",
    }
  }
}
```

### Configuration
```json5
{
  session: {
    dmScope: "per-channel-peer",
    identityLinks: { alice: ["telegram:123456789", "discord:987654321012345678"] },
    reset: { mode: "daily", atHour: 4, idleMinutes: 120 },
    resetByType: {
      thread: { mode: "daily", atHour: 4 },
      direct: { mode: "idle", idleMinutes: 240 },
      group: { mode: "idle", idleMinutes: 120 },
    },
    mainKey: "main",
  }
}
```

### Inspecting
```bash
openclaw status
openclaw sessions --json
openclaw gateway call sessions.list --params '{}'
# In chat: /status, /context list, /context detail, /stop, /compact
```

---

## Context

Context = **everything OpenClaw sends to the model for a run**, bounded by context window (token limit).

### Mental Model
- **System prompt**: rules, tools, skills list, time/runtime, workspace files
- **Conversation history**: messages + assistant replies for this session
- **Tool calls/results + attachments**: command output, files, images/audio

### Inspect
```
/status          → how full is my window?
/context list    → what's injected + rough sizes
/context detail  → deeper breakdown per file/tool/skill
/usage tokens    → append per-reply usage footer
/compact         → summarize older history
```

### What Counts Toward Context Window
System prompt + conversation history + tool calls + tool results + attachments + compaction summaries + pruning artifacts + provider headers.

### Injected Workspace Files
By default (if present): `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, `BOOTSTRAP.md`.

### Skills in Context
System prompt includes compact **skills list** (name + description + location). Skill instructions NOT included by default — model reads `SKILL.md` only when needed.

### Tools: Two Costs
1. Tool list text in system prompt (visible)
2. Tool schemas (JSON, invisible but counted)

---

## Context Engine

Controls how OpenClaw builds model context for each run.

### Lifecycle Points
1. **Ingest** — store new message
2. **Assemble** — build ordered messages fitting token budget
3. **Compact** — summarize older history
4. **After turn** — persist state, trigger background compaction

### Built-in `legacy` Engine
- Ingest: no-op
- Assemble: pass-through (sanitize → validate → limit pipeline)
- Compact: built-in summarization
- After turn: no-op

### Plugin Engines
```json5
{
  plugins: {
    slots: { contextEngine: "my-engine" },
    entries: { "my-engine": { enabled: true } }
  }
}
```

### ContextEngine Interface
| Member | Purpose |
|--------|---------|
| `info` | Engine id, name, version, `ownsCompaction` flag |
| `ingest(params)` | Store single message |
| `assemble(params)` | Build context for model run → `AssembleResult` |
| `compact(params)` | Summarize/reduce context |

`assemble` returns: `{ messages, estimatedTokens (required), systemPromptAddition? }`.

### `ownsCompaction`
- `true` → engine owns compaction; OpenClaw disables Pi's built-in auto-compaction
- `false` → Pi's auto-compaction may still run; engine's `compact()` still handles `/compact` and overflow recovery

Switch back to legacy: set `contextEngine: "legacy"` or remove key.

---

## Compaction

Compaction **summarizes older conversation** into a compact summary entry and keeps recent messages intact. Persists in session JSONL history.

### Auto-compaction (default on)
When session nears context window limit, auto-compaction triggers and may retry original request.

Signals: `🧹 Auto-compaction complete` in verbose mode; `/status` shows `🧹 Compactions: <count>`.

### Manual Compaction
```
/compact Focus on decisions and open questions
```

### Compaction vs Pruning
- **Compaction**: summarizes + **persists** in JSONL
- **Session pruning**: trims old **tool results** only, **in-memory**, per request

### Model Override for Compaction
```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "model": "openrouter/anthropic/claude-sonnet-4-5"
      }
    }
  }
}
```

### Pre-compaction Memory Flush
Before compaction, a **silent agentic turn** runs to remind model to write durable memory.

```json5
{
  agents: {
    defaults: {
      compaction: {
        reserveTokensFloor: 20000,
        memoryFlush: {
          enabled: true,
          softThresholdTokens: 4000,
          systemPrompt: "Session nearing compaction. Store durable memories now.",
          prompt: "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store.",
        }
      }
    }
  }
}
```

---

## Memory

Memory = plain Markdown in the agent workspace. Files are source of truth.

### Memory Files
- `memory/YYYY-MM-DD.md` — daily log (append-only), read today + yesterday at session start
- `MEMORY.md` — curated long-term memory (**only load in main, private session**)

### Memory Tools
- `memory_search` — semantic recall over indexed snippets
- `memory_get` — targeted read of specific Markdown file/line range

### When to Write Memory
- Decisions, preferences, durable facts → `MEMORY.md`
- Day-to-day notes + running context → `memory/YYYY-MM-DD.md`
- "Remember this" → write it down

### Vector Memory Search Config
```json5
{
  agents: {
    defaults: {
      memorySearch: {
        provider: "openai",       // openai | gemini | voyage | mistral | ollama | local
        model: "text-embedding-3-small",
        extraPaths: ["../team-docs"],
        query: {
          hybrid: {
            enabled: true,
            vectorWeight: 0.7,
            textWeight: 0.3,
            candidateMultiplier: 4,
            mmr: { enabled: true, lambda: 0.7 },
            temporalDecay: { enabled: true, halfLifeDays: 30 },
          }
        }
      }
    }
  }
}
```

Auto-detection order (when provider unset): local → openai → gemini → voyage → mistral.

### QMD Backend (experimental)
```json5
{ memory: { backend: "qmd" } }
```
Combines BM25 + vectors + reranking. Requires `qmd` CLI on PATH.

---

## Multi-Agent Routing

### What Is "One Agent"?
- Own **workspace** (AGENTS.md/SOUL.md/USER.md, persona)
- Own **state directory** (`agentDir`) for auth profiles, model registry
- Own **session store** under `~/.openclaw/agents/<agentId>/sessions`
- Auth profiles are **per-agent**; never reuse `agentDir` across agents

### Routing Rules (most-specific wins)
1. `peer` match (exact DM/group/channel id)
2. `parentPeer` match (thread inheritance)
3. `guildId + roles` (Discord role routing)
4. `guildId` (Discord)
5. `teamId` (Slack)
6. `accountId` match for a channel
7. Channel-level match (`accountId: "*"`)
8. Fallback to default agent

### Bindings Config Example (WhatsApp multi-user)
```json5
{
  agents: {
    list: [
      { id: "alex", workspace: "~/.openclaw/workspace-alex" },
      { id: "mia", workspace: "~/.openclaw/workspace-mia" },
    ]
  },
  bindings: [
    { agentId: "alex", match: { channel: "whatsapp", peer: { kind: "direct", id: "+15551230001" } } },
    { agentId: "mia", match: { channel: "whatsapp", peer: { kind: "direct", id: "+15551230002" } } },
  ]
}
```

### Per-Agent Sandbox and Tool Configuration
```json5
{
  agents: {
    list: [
      { id: "personal", workspace: "~/.openclaw/workspace-personal", sandbox: { mode: "off" } },
      {
        id: "family",
        workspace: "~/.openclaw/workspace-family",
        sandbox: { mode: "all", scope: "agent" },
        tools: {
          allow: ["read"],
          deny: ["exec", "write", "edit", "apply_patch"],
        }
      }
    ]
  }
}
```

---

## Model Providers (Overview)

Model refs use `provider/model` format. If `agents.defaults.models` is set, it becomes the allowlist.

### Key Providers
| Provider | ID | Auth |
|----------|-----|------|
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` or setup-token |
| OpenAI | `openai` | `OPENAI_API_KEY` |
| OpenAI Codex | `openai-codex` | OAuth (ChatGPT) |
| Google | `google` | `GEMINI_API_KEY` |
| OpenRouter | `openrouter` | `OPENROUTER_API_KEY` |
| Ollama | `ollama` | None (local) |
| Moonshot | `moonshot` | `MOONSHOT_API_KEY` |

### Custom Providers via `models.providers`
```json5
{
  models: {
    providers: {
      lmstudio: {
        baseUrl: "http://localhost:1234/v1",
        apiKey: "LMSTUDIO_KEY",
        api: "openai-completions",
        models: [{ id: "minimax-m2.5-gs32", name: "MiniMax M2.5", contextWindow: 200000 }],
      }
    }
  }
}
```

### API Key Rotation
Priority: `OPENCLAW_LIVE_<PROVIDER>_KEY` → `<PROVIDER>_API_KEYS` → `<PROVIDER>_API_KEY` → `<PROVIDER>_API_KEY_*`.
Retry with next key on rate-limit only; non-rate-limit fails immediately.

---

## Model Failover

### Auth Profile Rotation Order
1. Explicit config: `auth.order[provider]`
2. Configured profiles: `auth.profiles` filtered by provider
3. Stored profiles: entries in `auth-profiles.json`

Round-robin: OAuth before API keys, oldest last-used first, cooldown/disabled moved to end.

**Session stickiness**: profile pinned per session for cache warmth. Resets on: session reset, compaction, profile cooldown.

### Cooldown (exponential backoff)
1 min → 5 min → 25 min → 1 hour (cap). State stored in `auth-profiles.json`.

### Billing Disables
Billing failures → profile marked disabled (starts 5 hours, doubles per failure, caps 24 hours).

### Model Fallback
If all profiles for a provider fail, moves to next model in `agents.defaults.model.fallbacks`.

---

## Streaming + Chunking

### Two Separate Layers
1. **Block streaming (channels)**: emit completed blocks as assistant writes — normal channel messages
2. **Preview streaming (Telegram/Discord/Slack)**: update temporary preview message while generating

No true token-delta streaming to channel messages. Preview streaming is message-based (send + edits).

### Block Streaming Controls
- `agents.defaults.blockStreamingDefault`: `"on"`/`"off"` (default off)
- Channel overrides: `*.blockStreaming` (non-Telegram needs explicit `true`)
- `agents.defaults.blockStreamingBreak`: `"text_end"` | `"message_end"`
- `agents.defaults.blockStreamingChunk`: `{ minChars, maxChars, breakPreference? }`
- `agents.defaults.blockStreamingCoalesce`: `{ minChars?, maxChars?, idleMs? }`

### Preview Streaming Modes
| Channel | `off` | `partial` | `block` | `progress` |
|---------|-------|-----------|---------|------------|
| Telegram | ✅ | ✅ | ✅ | maps to `partial` |
| Discord | ✅ | ✅ | ✅ | maps to `partial` |
| Slack | ✅ | ✅ | ✅ | ✅ |

Canonical config key: `channels.<channel>.streaming`

---

## Command Queue

Serializes inbound auto-reply runs through a lane-aware FIFO queue.

### Queue Modes
| Mode | Behavior |
|------|----------|
| `steer` | Inject immediately into current run (cancels pending tool calls after next tool boundary) |
| `followup` | Enqueue for next agent turn after current run ends |
| `collect` | Coalesce all queued messages into single followup turn (default) |
| `steer-backlog` | Steer now AND preserve for followup turn |
| `interrupt` (legacy) | Abort active run, then run newest message |

**Defaults**: all surfaces → `collect`

```json5
{
  messages: {
    queue: {
      mode: "collect",
      debounceMs: 1000,
      cap: 20,
      drop: "summarize",
      byChannel: { discord: "collect" },
    }
  }
}
```

### Per-session: send `/queue <mode>` as standalone command.

---

## Session Pruning

Trims **old tool results** from in-memory context right before each LLM call. Does NOT rewrite JSONL history.

### When It Runs
- Mode `"cache-ttl"`: only if last Anthropic call is older than `ttl` (default 5 min)
- Only active for Anthropic API calls (and OpenRouter Anthropic models)

### What Can Be Pruned
- Only `toolResult` messages
- User + assistant messages never modified
- Last `keepLastAssistants` assistant messages protected
- Tool results with **image blocks** skipped

### Defaults (when enabled)
- `ttl`: `"5m"`
- `keepLastAssistants`: `3`
- `softTrimRatio`: `0.3`
- `hardClearRatio`: `0.5`
- `minPrunableToolChars`: `50000`
- `softTrim`: `{ maxChars: 4000, headChars: 1500, tailChars: 1500 }`
- `hardClear`: `{ enabled: true, placeholder: "[Old tool result content cleared]" }`

### Config
```json5
{
  agents: {
    defaults: {
      contextPruning: {
        mode: "cache-ttl",
        ttl: "5m",
        tools: { allow: ["exec", "read"], deny: ["*image*"] }
      }
    }
  }
}
```

---

## System Prompt

Built by OpenClaw for every agent run. Not user-editable directly.

### Structure (sections)
1. **Tooling**: tool list + short descriptions
2. **Safety**: guardrail reminder (advisory only; use tool policy/sandboxing for hard enforcement)
3. **Skills**: how to load skill instructions on demand
4. **OpenClaw Self-Update**: config.apply + update.run
5. **Workspace**: working directory
6. **Documentation**: local docs path + public mirror
7. **Workspace Files (injected)**: bootstrap files included below
8. **Sandbox**: when enabled, shows sandbox paths
9. **Current Date & Time**: timezone only (no dynamic clock — cache stable)
10. **Reply Tags**: optional syntax for supported providers
11. **Heartbeats**: heartbeat prompt + ack behavior
12. **Runtime**: host, OS, node, model, thinking level

### Prompt Modes
- `full` (default): all sections
- `minimal`: subagents; omits Skills, Memory Recall, Self-Update, Model Aliases, User Identity, Reply Tags, Messaging, Silent Replies, Heartbeats
- `none`: base identity line only

### Sub-agent Bootstrap
Sub-agent sessions inject only `AGENTS.md` and `TOOLS.md`.

### Skills Prompt Format
```xml
<available_skills>
  <skill>
    <name>...</name>
    <description>...</description>
    <location>...</location>
  </skill>
</available_skills>
```

### Time Handling
- `agents.defaults.userTimezone`: IANA timezone for system prompt
- `agents.defaults.timeFormat`: `auto` | `12` | `24`
- System prompt includes only **timezone** (no dynamic clock; use `session_status` for current time)

---

## Timezones

### Message Envelopes
```json5
{
  agents: {
    defaults: {
      envelopeTimezone: "local",  // "utc" | "local" | "user" | IANA tz
      envelopeTimestamp: "on",    // "on" | "off"
      envelopeElapsed: "on",      // "on" | "off"
    }
  }
}
```

Examples:
- Local (default): `[Signal Alice +1555 2026-01-18 00:19 PST] hello`
- Fixed tz: `[Signal Alice +1555 2026-01-18 06:19 GMT+1] hello`
- Elapsed: `[Signal Alice +1555 +2m 2026-01-18T05:19Z] follow-up`

### User Timezone for System Prompt
```json5
{ agents: { defaults: { userTimezone: "America/Chicago" } } }
```

---

## Usage Tracking

### Where It Shows
- `/status`: current session model, context, last response tokens, estimated cost (API key only)
- `/usage full`: per-reply usage footer with estimated cost (API key only; OAuth hides cost)
- `/usage tokens`: tokens only
- `openclaw status --usage`: full per-provider breakdown
- `openclaw channels list`: usage snapshot alongside provider config

### Providers + Credentials
- Anthropic (Claude): OAuth tokens in auth profiles
- GitHub Copilot: OAuth tokens
- Gemini CLI: OAuth tokens
- OpenAI Codex: OAuth tokens
- MiniMax: API key (`MINIMAX_CODE_PLAN_KEY` or `MINIMAX_API_KEY`)
- z.ai: API key via env/config/auth store

### Features That Can Spend Keys
1. Core model responses (chat + tools)
2. Media understanding (audio/image/video)
3. Memory embeddings (when remote provider configured)
4. Web search tool (Brave/Gemini/Grok/Kimi/Perplexity)
5. Web fetch (Firecrawl when API key present)
6. Provider usage snapshots (status/health commands)
7. Compaction summarization
8. Model scan/probe (`openclaw models scan`)
9. Talk (speech, ElevenLabs)
10. Skills (third-party APIs via `skills.entries.<name>.apiKey`)

---

## Features

### Core Channels
- WhatsApp (Baileys), Telegram (grammY), Discord (channels.discord.js), Mattermost (plugin), iMessage (local imsg CLI, macOS)

### Capabilities
- Multi-agent routing with isolated sessions
- Subscription auth (Anthropic/OpenAI via OAuth)
- Sessions: direct → shared `main`; groups → isolated
- Group chat with mention-based activation
- Media: images, audio, documents in and out
- Voice note transcription hook
- WebChat + macOS menu bar app
- iOS node: pairing, Canvas, camera, screen recording, location, voice
- Android node: pairing, Connect tab, chat sessions, voice, Canvas/camera, device/notifications/contacts/calendar/motion/photos/SMS commands
- Streaming and chunking for long responses

---

## Our Setup (ClawExpert)

- **OpenClaw version**: 2026.3.13 (stable)
- **Deployment**: Docker on Hostinger VPS
- **Agents**: Maks (main/Sonnet), MaksPM (pm/Haiku), Scout (research/Opus), ClawExpert (ops/Sonnet), Launch (gtm/Haiku)
- **Auth**: Anthropic API key mode (not OAuth/setup-token)
- **Primary model**: `anthropic/claude-sonnet-4-6`
- **Session scope**: `per-channel-peer` for secure DM isolation
- **Workspace**: `/data/.openclaw/workspace` (Maks), `/data/.openclaw/workspace-clawexpert` (ClawExpert)
- **Gateway port**: 18789, loopback bind
