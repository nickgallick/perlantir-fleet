---
name: openclaw-plugins-deep
description: Complete OpenClaw plugin SDK analysis — every bundled plugin cataloged, high-value unused plugins identified, plugin architecture explained, configuration reference, and SDK guide for custom plugins.
---

# OpenClaw Plugin SDK & Catalog

## Changelog
- 2026-03-20: Created from direct source analysis of repos/openclaw/extensions/ and src/plugin-sdk/

---

## 1. Plugin Architecture

### How Plugins Work

OpenClaw plugins are TypeScript/JavaScript modules loaded from `extensions/` inside the OpenClaw package. Each plugin is a directory with:
- `index.ts` — the main plugin entrypoint
- `openclaw.plugin.json` — the plugin manifest (schema, metadata, hints)
- `src/` — implementation files
- `api.ts` / `runtime-api.ts` — re-exports from plugin-sdk for the extension's own use

### Plugin Registration Flow

1. OpenClaw reads `plugins.allow` + `plugins.deny` to determine eligible plugin IDs
2. For each eligible plugin, it reads `openclaw.plugin.json` to get metadata without loading runtime
3. If the plugin passes the allow/deny check and `plugins.entries.<id>.enabled !== false`, the plugin is loaded
4. The plugin's `register(api)` function is called with an `OpenClawPluginApi` instance
5. The plugin registers tools, hooks, services, commands, HTTP routes, etc. via the api

### Plugin Kinds

Plugins declare a `kind` field that activates exclusive slot behavior:
- `"memory"` — exclusive slot; only one memory plugin active at a time (controlled by `plugins.slots.memory`)
- `"context-engine"` — exclusive slot for context orchestration
- (no kind) — non-exclusive, multiple can coexist

### Plugin SDK Surface (`definePluginEntry`)

All plugins use `definePluginEntry()` from `openclaw/plugin-sdk/core`:

```typescript
definePluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  description: "What it does",
  kind?: "memory" | "context-engine",
  configSchema?: OpenClawPluginConfigSchema,
  register(api: OpenClawPluginApi) {
    // register tools, hooks, services, etc.
  }
})
```

### OpenClawPluginApi — Full Surface

```typescript
api.id                      // plugin ID
api.name                    // plugin name
api.version?                // plugin version
api.source                  // plugin source path
api.registrationMode        // "full" | "setup-only" | "setup-runtime"
api.config                  // full OpenClawConfig (read-only)
api.pluginConfig?           // plugin-specific config from plugins.entries.<id>.config
api.runtime                 // PluginRuntime — in-process native helpers
api.logger                  // { debug?, info, warn, error }

// Registration methods
api.registerTool(tool | factory, opts?)
api.registerHook(events, handler, opts?)
api.registerHttpRoute(params)
api.registerChannel(plugin)
api.registerGatewayMethod(method, handler)
api.registerCli(registrar, opts?)
api.registerService(service)
api.registerProvider(provider)
api.registerSpeechProvider(provider)
api.registerMediaUnderstandingProvider(provider)
api.registerImageGenerationProvider(provider)
api.registerWebSearchProvider(provider)
api.registerInteractiveHandler(registration)
api.registerCommand(command)
api.registerContextEngine(id, factory)
api.on(hookName, handler, opts?)  // typed lifecycle hooks
api.onConversationBindingResolved(handler)
api.resolvePath(input)
```

### Typed Lifecycle Hooks

The strongly-typed `api.on()` hook system covers:

| Hook Name | When It Fires | Can Return |
|---|---|---|
| `before_model_resolve` | Before model is chosen | `modelOverride`, `providerOverride` |
| `before_prompt_build` | After messages assembled, before LLM | `systemPrompt`, `prependContext`, `prependSystemContext`, `appendSystemContext` |
| `before_agent_start` | Legacy combined hook | Both prompt and model overrides |
| `llm_input` | Just before LLM call | (observability only) |
| `llm_output` | After LLM response | (observability only) |
| `agent_end` | After agent turn completes | (observability/capture) |
| `before_compaction` | Before session compaction | (prep/snapshot) |
| `after_compaction` | After compaction done | (cleanup) |
| `before_reset` | On /new or /reset | (cleanup) |
| `inbound_claim` | Message arrives from channel | `handled: boolean` |
| `message_received` | Message received event | (observability) |
| `message_sending` | Before message is sent | `content`, `cancel: true` |
| `message_sent` | After message delivered | (observability) |
| `before_tool_call` | Before any tool runs | `params`, `block`, `blockReason` |
| `after_tool_call` | After tool runs | (observability) |
| `tool_result_persist` | Before tool result written to JSONL | `message` (modified) |
| `before_message_write` | Before any message written to JSONL | `block`, `message` |
| `session_start` | Session begins | (init) |
| `session_end` | Session ends | (cleanup) |
| `subagent_spawning` | Before subagent spawned | `status: "ok" | "error"` |
| `subagent_delivery_target` | Before delivery target resolved | `origin` override |
| `subagent_spawned` | After subagent spawned | (observability) |
| `subagent_ended` | After subagent completes | (observability) |
| `gateway_start` | Gateway starts | (init) |
| `gateway_stop` | Gateway stops | (cleanup) |

### Tool Factory Pattern

Tools can be registered as factories that receive per-call context:

```typescript
api.registerTool(
  (ctx: OpenClawPluginToolContext) => {
    if (ctx.sandboxed) return null;  // Don't register in sandbox
    return myTool;
  },
  { optional: true }
);
```

Context provides: `config`, `workspaceDir`, `agentDir`, `agentId`, `sessionKey`, `sessionId`, `messageChannel`, `agentAccountId`, `requesterSenderId`, `senderIsOwner`, `sandboxed`.

### Plugin Manifest (`openclaw.plugin.json`)

```json
{
  "id": "my-plugin",
  "name": "Human Name",
  "description": "What it does",
  "kind": "memory",
  "configSchema": { "type": "object", "properties": { ... } },
  "enabledByDefault": false,
  "channels": ["telegram"],
  "providers": ["anthropic"],
  "skills": ["./skills"],
  "uiHints": {
    "someField": { "label": "...", "help": "...", "sensitive": true, "advanced": true }
  }
}
```

---

## 2. Complete Plugin Catalog

The full catalog is in `repos/openclaw/extensions/`. 68 total plugins cataloged.

### Channel Plugins (messaging surfaces)

| Plugin ID | What It Does | Default Enabled | Our Use |
|---|---|---|---|
| `telegram` | Telegram Bot API channel | Config-driven | ✅ Active (4 bots) |
| `discord` | Discord bot channel | Config-driven | ✅ Enabled |
| `slack` | Slack RTM/Events API channel | Config-driven | ✅ Enabled |
| `whatsapp` | WhatsApp Business channel | Config-driven | ✅ Enabled |
| `googlechat` | Google Chat spaces channel | Config-driven | ✅ Enabled |
| `nostr` | Nostr decentralized protocol channel | Config-driven | ✅ Enabled (harmless warning) |
| `signal` | Signal messenger via signal-cli | Config-driven | ❌ Disabled |
| `imessage` | iMessage via BlueBubbles or AppleScript | Config-driven | ❌ Disabled |
| `discord` | Discord bot channel | Config-driven | ✅ Enabled |
| `irc` | IRC channel | Config-driven | Not active |
| `matrix` | Matrix/Element channel | Config-driven | Not active |
| `mattermost` | Mattermost workspace | Config-driven | Not active |
| `msteams` | Microsoft Teams | Config-driven | Not active |
| `nextcloud-talk` | Nextcloud Talk | Config-driven | Not active |
| `feishu` | Feishu/Lark (ByteDance) | Config-driven | Not active |
| `line` | LINE messenger | Config-driven | Not active |
| `tlon` | Tlon/Urbit | Config-driven | Not active |
| `twitch` | Twitch chat | Config-driven | Not active |
| `synology-chat` | Synology Chat | Config-driven | Not active |
| `zai` | Zai channel | Config-driven | Not active |
| `zalo` | Zalo Vietnam messaging | Config-driven | Not active |
| `zalouser` | Zalo user-facing | Config-driven | Not active |
| `bluebubbles` | iMessage via BlueBubbles server | Config-driven | Not active |

### Model Provider Plugins

| Plugin ID | What It Does | Notes |
|---|---|---|
| `anthropic` | Anthropic Claude models | ✅ Our primary provider |
| `openai` | OpenAI GPT models | Available |
| `google` | Google Gemini models | Available |
| `ollama` | Local Ollama models | Available |
| `openrouter` | OpenRouter multi-provider | Available |
| `github-copilot` | GitHub Copilot models | Available |
| `amazon-bedrock` | AWS Bedrock models | Available |
| `microsoft` | Azure OpenAI + Microsoft | Available |
| `huggingface` | HuggingFace Inference | Available |
| `nvidia` | NVIDIA NIM/NGC | Available |
| `mistral` | Mistral AI models | Available |
| `xai` | xAI Grok models | Available |
| `perplexity` | Perplexity AI | Available |
| `together` | Together AI | Available |
| `cohere` (via openrouter) | — | — |
| `byteplus` | BytePlus/Volcengine | Available |
| `moonshot` | Moonshot AI (Kimi) | Available |
| `minimax` | MiniMax models | Available |
| `modelstudio` | Alibaba ModelStudio | Available |
| `qianfan` | Baidu Qianfan | Available |
| `qwen-portal-auth` | Alibaba Qwen portal | Available |
| `volcengine` | Volcengine (ByteDance) | Available |
| `cloudflare-ai-gateway` | Cloudflare AI Gateway proxy | Available |
| `vercel-ai-gateway` | Vercel AI Gateway | Available |
| `sglang` | SGLang inference server | Available |
| `vllm` | vLLM server | Available |
| `chutes` | Chutes AI | Available |
| `kilocode` | KiloCode coding provider | Available |
| `kimi-coding` | Kimi coding provider | Available |
| `opencode` | OpenCode provider | Available |
| `opencode-go` | OpenCode Go | Available |
| `venice` | Venice AI | Available |
| `synthetic` | Synthetic provider (Anthropic-compatible) | Available |
| `copilot-proxy` | GitHub Copilot proxy | Available |
| `xiaomi` | Xiaomi AI models | Available |
| `fal` | Fal.ai (image generation) | Available |

### Tool/Feature Plugins (non-channel, non-provider)

#### `lobster`
- **What it does**: Runs Lobster pipeline workflows as a local-first runtime with typed JSON envelopes and resumable human approvals.
- **Tools added**: `lobster` (actions: `run`, `resume`)
- **Config keys**: `plugins.entries.lobster` — no config keys, empty schema
- **Enabled by default**: No — must be in `plugins.allow` or tools.alsoAllow
- **Note**: Disabled in sandboxed mode (`ctx.sandboxed === true`). Requires `lobster` CLI in PATH.
- **Use case**: Orchestrating multi-step pipelines with approval gates. Ideal for Maks/MaksPM workflows.

#### `llm-task`
- **What it does**: Runs a generic JSON-only LLM subtask with schema validation. Designed for orchestration from Lobster or multi-agent flows via `openclaw.invoke`.
- **Tools added**: `llm-task`
- **Config keys**:
  ```json
  "plugins.entries.llm-task.config": {
    "defaultProvider": "anthropic",
    "defaultModel": "claude-haiku-4-5",
    "defaultAuthProfileId": "...",
    "allowedModels": ["anthropic/claude-haiku-4-5"],
    "maxTokens": 4096,
    "timeoutMs": 30000
  }
  ```
- **Enabled by default**: No
- **Use case**: Structured JSON extraction, classification, or subtask delegation from a parent agent without spawning a full session.

#### `diffs`
- **What it does**: Produces visual diff artifacts (unified or split view) as PNG/PDF files or in-gateway HTML viewer URLs. Injects agent guidance via `before_prompt_build` hook.
- **Tools added**: `diffs`
- **HTTP routes added**: `/plugins/diffs` (prefix, plugin auth)
- **Config keys**:
  ```json
  "plugins.entries.diffs.config": {
    "defaults": {
      "theme": "dark",
      "layout": "unified",
      "fontFamily": "Fira Code",
      "fontSize": 15,
      "mode": "both",
      "fileFormat": "png",
      "fileQuality": "standard"
    },
    "security": {
      "allowRemoteViewer": false
    }
  }
  ```
- **Enabled by default**: No
- **Use case**: Maks coding agent showing code changes visually; QA review of PR diffs; send rendered PNG to Nick via Telegram.

#### `memory-core`
- **What it does**: File-backed memory search and retrieval using OpenClaw's built-in MEMORY.md/memory file system. The default/free memory implementation.
- **Kind**: `memory` (exclusive slot)
- **Tools added**: `memory_search`, `memory_get`
- **CLI commands**: `openclaw memory`
- **Config keys**: None (empty config schema)
- **Enabled by default**: Yes (part of core experience)
- **Use case**: Current memory system for all agents. Stores to MEMORY.md files.

#### `memory-lancedb`
- **What it does**: LanceDB vector database backed long-term memory with OpenAI embeddings. Auto-recall (injects relevant memories before agent start) and auto-capture (stores important user messages after agent turn). Full CRUD memory tools.
- **Kind**: `memory` (exclusive slot — replaces memory-core when active)
- **Tools added**: `memory_recall`, `memory_store`, `memory_forget`
- **CLI commands**: `openclaw ltm list`, `openclaw ltm search <query>`, `openclaw ltm stats`
- **Config keys**:
  ```json
  "plugins.entries.memory-lancedb.config": {
    "embedding": {
      "apiKey": "${OPENAI_API_KEY}",
      "model": "text-embedding-3-small",
      "baseUrl": "https://api.openai.com/v1",
      "dimensions": 1536
    },
    "dbPath": "~/.openclaw/memory/lancedb",
    "autoCapture": true,
    "autoRecall": true,
    "captureMaxChars": 500
  }
  ```
- **Enabled by default**: No
- **Note**: Requires LanceDB native bindings — may fail on some platforms. Requires OpenAI API key for embeddings.
- **Use case**: Cross-session persistent memory for Nick's preferences, decisions, entities. Stronger than file-based memory for semantic recall.

#### `firecrawl`
- **What it does**: Firecrawl-powered web scraping and search. Handles JS-heavy or bot-protected pages where plain `web_fetch` is weak.
- **Tools added**: `firecrawl_scrape`, `firecrawl_search`
- **Web search provider**: Registers Firecrawl as a web search provider alternative to Brave
- **Config keys**:
  ```json
  "plugins.entries.firecrawl.config": {
    "webSearch": {
      "apiKey": "fc-...",
      "baseUrl": "https://api.firecrawl.dev"
    }
  }
  ```
- **Enabled by default**: No
- **Use case**: Scout agent deep research on JS-heavy sites; competitor analysis; startup research where Brave misses content.

#### `brave`
- **What it does**: Registers the Brave Search web search provider. Powers the `web_search` tool when configured.
- **Tools added**: None directly (adds a web search provider)
- **Config keys**:
  ```json
  "plugins.entries.brave.config": {
    "webSearch": {
      "apiKey": "BSA...",
      "mode": "web"
    }
  }
  ```
- **Enabled by default**: Loaded when `BRAVE_API_KEY` is set
- **Note**: This is what currently powers all agents' `web_search` tool.

#### `openshell`
- **What it does**: Registers an OpenShell-backed sandbox backend for agent exec and file tools. Provides isolated SSH-based command execution with mirrored workspaces.
- **Config keys**:
  ```json
  "plugins.entries.openshell.config": {
    "command": "openshell",
    "gateway": "my-gateway",
    "policy": "/path/to/policy.yaml",
    "timeoutSeconds": 60
  }
  ```
- **Enabled by default**: No — requires openshell CLI
- **Use case**: Isolated coding sandbox for Maks when Docker exec is not sufficient.

#### `device-pair`
- **What it does**: Generates QR codes and setup codes for pairing mobile companion apps (iOS/Android). Issues bootstrap tokens and manages pairing approval via CLI commands.
- **Config keys**:
  ```json
  "plugins.entries.device-pair.config": {
    "publicUrl": "wss://72.61.127.59:18789"
  }
  ```
- **Enabled by default**: No
- **Note**: Required for mobile app pairing. If VPS doesn't have public WebSocket URL configured here, pairing fails.

#### `thread-ownership`
- **What it does**: Prevents multiple agents from responding in the same Slack thread. Uses HTTP calls to a `slack-forwarder` ownership API. Hooks `message_received` and `message_sending`.
- **Config keys**:
  ```json
  "plugins.entries.thread-ownership.config": {
    "forwarderUrl": "http://slack-forwarder:8750",
    "abTestChannels": ["C1234567890"]
  }
  ```
- **Enabled by default**: No
- **Note**: Only meaningful if you run multiple agents on the same Slack workspace.
- **Use case**: If Maks and MaksPM ever share a Slack channel, prevents double-posting.

#### `diagnostics-otel`
- **What it does**: Exports OpenTelemetry diagnostic events from OpenClaw. Registers a service that connects to an OTEL collector. Hooks into diagnostic events + log transport.
- **Config keys**: None (empty config schema)
- **Enabled by default**: No
- **Use case**: Production observability — send spans/traces to Grafana, Jaeger, Datadog, etc.

#### `acpx`
- **What it does**: ACP runtime backend powered by the `acpx` CLI. Provides the coding agent session management for Codex/Claude Code integrations. Supports MCP server injection.
- **Config keys**:
  ```json
  "plugins.entries.acpx.config": {
    "command": "/path/to/acpx",
    "permissionMode": "approve-all",
    "timeoutSeconds": 120,
    "mcpServers": {
      "my-server": {
        "command": "node",
        "args": ["server.js"],
        "env": { "TOKEN": "..." }
      }
    }
  }
  ```
- **Enabled by default**: No — auto-loaded when ACP sessions are requested
- **Note**: Powers the `sessions_spawn` with `runtime:"acp"` pattern.

#### `voice-call`
- **What it does**: Full voice call integration via Twilio, Telnyx, or Plivo. Handles inbound/outbound calls, STT/TTS pipeline, streaming via OpenAI Realtime API.
- **Config keys**: Extensive — see manifest above. Key fields: `provider`, `fromNumber`, `twilio.*`, `telnyx.*`, `tts.*`, `streaming.*`
- **Enabled by default**: No
- **Use case**: Nick wants to receive/make AI calls.

#### `talk-voice`
- **What it does**: Voice synthesis for messages — registers TTS commands (`/tts`) and manages speech providers. Works with ElevenLabs, OpenAI TTS, Microsoft TTS.
- **Config keys**: Inherits from `messages.tts` config
- **Enabled by default**: No

#### `memory-core` (see above under tool plugins)

#### `open-prose`
- **What it does**: Delivers plugin-shipped prose writing skills bundle. No runtime code — skills only.
- **Config keys**: None
- **Enabled by default**: No
- **Note**: Skills are loaded from `./skills` in the plugin directory.

#### `phone-control`
- **What it does**: Controls device capabilities (camera, screen recording, calendar, contacts, reminders, SMS) via armed state management. Uses `/arm` and `/disarm` commands with expiry.
- **Config keys**: None
- **Enabled by default**: No
- **Use case**: Mobile companion app extended controls.

#### `elevenlabs`
- **What it does**: Registers ElevenLabs as a speech synthesis provider for TTS.
- **Config keys**: ElevenLabs API key + model/voice config
- **Enabled by default**: No

#### `shared`
- **What it does**: Internal shared utilities — not a user-facing plugin.

#### `synthetic`
- **What it does**: Anthropic-compatible multi-model synthetic inference provider. For testing/dev.

---

## 3. High-Value Plugins We're Not Using

### 🔴 Priority 1: `llm-task`

**What it does**: Runs structured JSON-only LLM subtasks from within agent workflows. The agent calls `llm-task` with a prompt + JSON schema and gets validated JSON back — without spinning up a full session.

**Why it's valuable for our 7-agent pipeline**:
- MaksPM can use `llm-task` to classify tasks, score quality, or extract structured data from Maks's output without spawning a subagent
- Maks can use it for tight reasoning loops (classify this bug → JSON output)
- Scout can extract structured research data without session overhead
- Lower latency + cost than full subagent for single-turn structured tasks

**How to enable**:
Add to `plugins.allow` array and configure:
```json
"plugins": {
  "allow": ["whatsapp", "discord", "telegram", "slack", "nostr", "googlechat", "llm-task"],
  "entries": {
    "llm-task": {
      "enabled": true,
      "config": {
        "defaultProvider": "anthropic",
        "defaultModel": "claude-haiku-4-5",
        "maxTokens": 2048,
        "timeoutMs": 30000
      }
    }
  }
}
```

**Risk**: Low. Read-only LLM calls. No filesystem or network side effects beyond the LLM call itself.

---

### 🔴 Priority 2: `diffs`

**What it does**: Produces PNG/PDF diff artifacts and an HTML diff viewer. The `diffs` tool takes `before` + `after` text (or a unified patch) and renders a visual diff. Injects agent guidance via `before_prompt_build`.

**Why it's valuable for our 7-agent pipeline**:
- Maks's code reviews become visual — send rendered PNG directly to Nick on Telegram
- MaksPM QA step can visually compare PRE vs POST state of code changes
- Pixel (design agent) can diff CSS/HTML changes visually
- Eliminates the "wall of text diff" problem in Telegram messages

**How to enable**:
```json
"plugins": {
  "allow": ["whatsapp", "discord", "telegram", "slack", "nostr", "googlechat", "diffs"],
  "entries": {
    "diffs": {
      "enabled": true,
      "config": {
        "defaults": {
          "theme": "dark",
          "layout": "unified",
          "mode": "both",
          "fileFormat": "png",
          "fileQuality": "standard"
        },
        "security": {
          "allowRemoteViewer": false
        }
      }
    }
  }
}
```

**Risk**: Low. Renders local artifacts in tmp dir. No network calls. `allowRemoteViewer: false` keeps viewer URLs loopback-only.

---

### 🟡 Priority 3: `memory-lancedb`

**What it does**: LanceDB vector database + OpenAI embeddings for semantic long-term memory. Auto-recalls relevant memories before each agent turn. Auto-captures user preferences/decisions after each turn.

**Why it's valuable for our 7-agent pipeline**:
- Nick's preferences, decisions, and project context persist across sessions semantically
- ClawExpert auto-remembers past operational findings without manual MEMORY.md
- Scout remembers past research to avoid duplication
- Superior to file-based memory for "what did Nick say about X last week?"

**Prerequisite**: OpenAI API key (for embeddings). Works with `OPENAI_API_KEY` env var.

**How to enable**:
1. Set exclusive memory slot to lancedb:
```json
"plugins": {
  "allow": ["whatsapp", "discord", "telegram", "slack", "nostr", "googlechat", "memory-lancedb"],
  "slots": {
    "memory": "memory-lancedb"
  },
  "entries": {
    "memory-lancedb": {
      "enabled": true,
      "config": {
        "embedding": {
          "apiKey": "${OPENAI_API_KEY}",
          "model": "text-embedding-3-small"
        },
        "autoCapture": true,
        "autoRecall": true,
        "captureMaxChars": 500
      }
    }
  }
}
```
2. Verify LanceDB native bindings work on Docker Linux: `docker exec openclaw-okny-openclaw-1 node -e "require('@lancedb/lancedb')"` (may need platform check first)

**Risk**: Medium. Requires LanceDB native bindings (may fail on some Linux builds). Adds OpenAI API cost for embeddings. Test in isolation before switching from memory-core. Check: `plugins.slots.memory = "memory-lancedb"` activates it.

---

### 🟡 Priority 4: `lobster`

**What it does**: Runs Lobster workflow pipelines with resumable human approvals. The `lobster` tool accepts `action: "run"` with a pipeline name and JSON args, or `action: "resume"` with a token.

**Why it's valuable for our 7-agent pipeline**:
- Multi-step agent workflows with approval gates — Maks proposes, Nick approves, Maks continues
- Typed JSON envelope means deterministic output for downstream agents
- `lobster` CLI acts as a workflow runtime that integrates with OpenClaw's approval system

**Prerequisite**: `lobster` CLI installed and in PATH.

**How to enable**:
```json
"plugins": {
  "allow": ["whatsapp", "discord", "telegram", "slack", "nostr", "googlechat", "lobster"],
  "entries": {
    "lobster": {
      "enabled": true
    }
  }
}
```

**Risk**: Low (disabled in sandbox mode automatically). No config required.

---

### 🟢 Priority 5: `diagnostics-otel`

**What it does**: Exports OpenTelemetry spans/traces/metrics to a configured OTEL collector. Hooks into `emitDiagnosticEvent` and the logger transport.

**Why it's valuable**:
- Production observability for the 7-agent pipeline
- Monitor agent response times, LLM latency, tool call frequency
- Send to Grafana Cloud free tier for real dashboards

**How to enable** (requires OTEL collector endpoint):
```json
"plugins": {
  "allow": [..., "diagnostics-otel"],
  "entries": {
    "diagnostics-otel": {
      "enabled": true
    }
  }
}
```

**Risk**: Low. Observability-only. No behavior change. Add OTEL collector endpoint via env vars.

---

## 4. Our Current Plugin Config

### What's Enabled

From `openclaw.json` as of 2026-03-20:

```json
"plugins": {
  "allow": ["whatsapp", "discord", "telegram", "slack", "nostr", "googlechat"],
  "entries": {
    "whatsapp": { "enabled": true },
    "discord": { "enabled": true },
    "imessage": { "enabled": false },
    "telegram": { "enabled": true },
    "slack": { "enabled": true },
    "nostr": { "enabled": true },
    "signal": { "enabled": false },
    "googlechat": { "enabled": true }
  },
  "installs": {}
}
```

### Analysis

- **Only channel plugins are managed.** Zero tool/feature plugins are explicitly enabled.
- `plugins.allow` acts as an allowlist — only the 6 listed channel plugins are eligible.
- `imessage` and `signal` are explicitly disabled (correct for VPS without Apple hardware / signal-cli).
- **No tool plugins** (`llm-task`, `diffs`, `lobster`, etc.) are in the allow list.
- **Memory**: Running default `memory-core` (file-backed MEMORY.md) since no `plugins.slots.memory` override.
- **Web search**: Brave is auto-loaded from `BRAVE_API_KEY` env var — NOT via `plugins.allow` (Brave is a bundled web search provider that loads automatically when the API key is present).

### Why This Config Is Conservative

The original config was set up for channel safety — only whitelisting messaging channels to prevent unintended tool exposure. This is correct for production but leaves high-value features completely disabled.

The `plugins.allow` list being channel-only means `llm-task`, `diffs`, `lobster`, and other tool plugins cannot load even if they're in `plugins.entries` with `enabled: true`.

**To unlock tool plugins**: Add their IDs to `plugins.allow`.

---

## 5. Plugin Configuration Reference

### `plugins.allow` (array of strings)

When set, ONLY listed plugin IDs are eligible to load. Acts as an inventory control.

```json
"plugins": {
  "allow": ["telegram", "discord", "slack", "diffs", "llm-task"]
}
```

**Critical**: If `plugins.allow` is set, a plugin NOT listed cannot load even if it has `enabled: true` in `plugins.entries`. You must add it to both places.

### `plugins.deny` (array of strings)

Hard block list — overrides allow. Use for emergency rollback.

```json
"plugins": {
  "deny": ["some-risky-plugin"]
}
```

### `plugins.entries.<id>.enabled` (boolean)

Per-plugin on/off switch. Requires restart.

```json
"plugins": {
  "entries": {
    "llm-task": { "enabled": true },
    "imessage": { "enabled": false }
  }
}
```

### `plugins.entries.<id>.config` (object)

Plugin-defined config payload — validated by the plugin's own schema. Use only documented fields; undocumented fields cause Zod validation errors.

```json
"plugins": {
  "entries": {
    "diffs": {
      "enabled": true,
      "config": {
        "defaults": { "theme": "dark" },
        "security": { "allowRemoteViewer": false }
      }
    }
  }
}
```

### `plugins.entries.<id>.hooks.allowPromptInjection` (boolean)

Controls whether a plugin can mutate prompts via `before_prompt_build` and `before_agent_start` hooks. Default: `true` (allowed).

Set to `false` to block prompt injection from a specific plugin while keeping other features:

```json
"plugins": {
  "entries": {
    "memory-lancedb": {
      "enabled": true,
      "hooks": {
        "allowPromptInjection": false
      }
    }
  }
}
```

**Note**: When `false`, the `before_prompt_build` hook is blocked entirely; `before_agent_start` will still fire but `systemPrompt`, `prependContext`, `prependSystemContext`, `appendSystemContext` fields are ignored. `modelOverride` and `providerOverride` from `before_agent_start` still work.

### `plugins.slots.memory` (string)

Selects the active memory plugin. Only one memory plugin can be active at a time.

```json
"plugins": {
  "slots": {
    "memory": "memory-lancedb"
  }
}
```

Use `"none"` to disable all memory plugins.

### `plugins.slots.contextEngine` (string)

Selects the active context engine plugin.

### `tools.alsoAllow` (array of strings)

Global additive tool allowlist on top of the selected tool profile. Use for adding specific tools without rewriting the entire allow list.

```json
"tools": {
  "alsoAllow": ["diffs", "memory_recall"]
}
```

**Important constraint**: Cannot be used together with `tools.allow` in the same scope — OpenClaw throws a validation error: "tools policy cannot set both allow and alsoAllow."

### Per-Agent Tool Override

```json
"agents": {
  "list": [
    {
      "id": "maks",
      "tools": {
        "alsoAllow": ["diffs", "llm-task"]
      }
    }
  ]
}
```

### `plugins.load.paths` (array of strings)

Additional directories scanned for plugins beyond built-in defaults.

```json
"plugins": {
  "load": {
    "paths": ["/data/.openclaw/custom-plugins"]
  }
}
```

---

## 6. Plugin SDK — Building Custom Plugins

If you ever want to build a custom plugin for ClawExpert, here is the exact pattern:

### Minimal Plugin Structure

```
my-plugin/
├── openclaw.plugin.json    # manifest
├── index.ts                # entrypoint
└── src/
    └── my-tool.ts
```

### `openclaw.plugin.json`

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "description": "What it does",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "myOption": { "type": "string" }
    }
  },
  "uiHints": {
    "myOption": {
      "label": "My Option",
      "help": "Help text",
      "sensitive": false
    }
  }
}
```

### `index.ts`

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/core";
import type { OpenClawPluginApi } from "openclaw/plugin-sdk/core";

export default definePluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  description: "What it does",
  configSchema: myConfigSchema, // or emptyPluginConfigSchema()
  register(api: OpenClawPluginApi) {
    const cfg = api.pluginConfig as { myOption?: string };

    // Register a tool
    api.registerTool({
      name: "my_tool",
      label: "My Tool",
      description: "Does something useful",
      parameters: Type.Object({
        input: Type.String({ description: "Input text" })
      }),
      async execute(_toolCallId, params) {
        const result = await doSomething(params.input as string);
        return {
          content: [{ type: "text", text: result }],
          details: { result }
        };
      }
    });

    // Register a lifecycle hook
    api.on("before_agent_start", async (event, ctx) => {
      if (!event.prompt) return;
      return {
        prependContext: `Context from my plugin: ${something}`
      };
    });

    // Register a background service
    api.registerService({
      id: "my-plugin-service",
      start: async (ctx) => {
        ctx.logger.info("my-plugin: service started");
        // start background work
      },
      stop: async (ctx) => {
        ctx.logger.info("my-plugin: service stopped");
      }
    });

    // Register a CLI command
    api.registerCli(({ program, config }) => {
      program
        .command("my-cmd")
        .description("My CLI command")
        .action(async () => {
          console.log("Running my CLI command");
        });
    }, { commands: ["my-cmd"] });

    // Register a plugin command (bypasses LLM)
    api.registerCommand({
      name: "myplugin",
      description: "My slash command",
      acceptsArgs: true,
      requireAuth: true,
      handler: async (ctx) => {
        return { text: `Got: ${ctx.args}` };
      }
    });
  }
});
```

### Key Plugin SDK Imports

```typescript
// Core entry/types
import { definePluginEntry, emptyPluginConfigSchema } from "openclaw/plugin-sdk/core";
import type { OpenClawPluginApi, AnyAgentTool, OpenClawPluginConfigSchema } from "openclaw/plugin-sdk/core";

// Config types
import type { OpenClawConfig } from "openclaw/plugin-sdk/core";

// Sandbox (for openshell-style plugins)
import { registerSandboxBackend } from "openclaw/plugin-sdk/sandbox";

// Speech providers
import type { SpeechProviderPlugin } from "openclaw/plugin-sdk/core";

// Diagnostics
import { emitDiagnosticEvent, onDiagnosticEvent } from "openclaw/plugin-sdk/diagnostics-otel";
import { registerLogTransport } from "openclaw/plugin-sdk/diagnostics-otel";
```

### Tool Return Shape

```typescript
return {
  content: [{ type: "text", text: "Human-readable result" }],
  details: { key: "value" }  // structured data for chaining
};
```

### Config Schema — Zod or JSON Schema

For simple cases, use TypeBox + safeParse pattern:
```typescript
import { Type } from "@sinclair/typebox";
import Ajv from "ajv";

const schema = Type.Object({
  apiKey: Type.String(),
  enabled: Type.Optional(Type.Boolean())
});
```

Or use the built-in `emptyPluginConfigSchema()` for plugins that need no config.

### Installing a Custom Plugin

1. Place plugin in `~/.openclaw/extensions/my-plugin/`
2. Add to `openclaw.json`:
```json
"plugins": {
  "load": { "paths": ["~/.openclaw/extensions"] },
  "entries": {
    "my-plugin": { "enabled": true }
  }
}
```
3. Or use `openclaw plugins install` from ClawHub if published.

---

## Our Setup Notes

### Current State (2026-03-20)
- **7 plugins in allow list**: telegram, discord, slack, whatsapp, nostr, googlechat — ALL channel plugins
- **0 tool/feature plugins** explicitly enabled
- **Memory**: file-backed memory-core (default)
- **Web search**: Brave auto-loaded via BRAVE_API_KEY env var

### Recommended Config Changes

**Safe to add immediately** (no external dependencies):
```json
"plugins": {
  "allow": [
    "whatsapp", "discord", "telegram", "slack", "nostr", "googlechat",
    "diffs",
    "llm-task",
    "lobster"
  ],
  "entries": {
    "diffs": {
      "enabled": true,
      "config": {
        "defaults": { "theme": "dark", "mode": "both" },
        "security": { "allowRemoteViewer": false }
      }
    },
    "llm-task": {
      "enabled": true,
      "config": {
        "defaultProvider": "anthropic",
        "defaultModel": "claude-haiku-4-5",
        "maxTokens": 2048
      }
    }
  }
}
```

**After verifying LanceDB bindings** (requires OpenAI API key for embeddings):
```json
"plugins": {
  "slots": { "memory": "memory-lancedb" },
  "entries": {
    "memory-lancedb": {
      "enabled": true,
      "config": {
        "embedding": {
          "apiKey": "${OPENAI_API_KEY}",
          "model": "text-embedding-3-small"
        },
        "autoCapture": true,
        "autoRecall": true
      }
    }
  }
}
```

### Important Warnings

1. **`plugins.allow` is an allowlist** — if it's set, ONLY those plugin IDs can load. To unlock `diffs`, you MUST add `"diffs"` to the `allow` array.

2. **`tools.allow` and `tools.alsoAllow` cannot coexist** in the same scope — Zod throws a validation error. Check current tool policy before adding `alsoAllow`.

3. **`memory-lancedb` is `kind: "memory"`** — enabling it with `plugins.slots.memory = "memory-lancedb"` disables `memory-core`. Existing MEMORY.md-based memories won't auto-migrate.

4. **Source version is 2026.3.14 but running 2026.3.13** — verify plugin IDs haven't changed between versions before applying. All plugins above are confirmed present in the running version.

5. **Config backup before changes**: `cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.bak.$(date +%Y%m%d%H%M%S)`

6. **Always restart after plugin changes**: `openclaw gateway restart` or restart the Docker container.
