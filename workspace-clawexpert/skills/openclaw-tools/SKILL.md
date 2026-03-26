---
name: openclaw-tools
description: Expert reference for all OpenClaw agent tools — exec, web, subagents, skills, llm-task, browser, thinking, elevated, ACP agents, agent-send, diffs, reactions, slash-commands, lobster, loop-detection, btw, exec-approvals, capability-cookbook, pdf, skills-config.
---

# OpenClaw Tools

## Changelog
- 2026-03-20: Created from source docs — 21 tool files covering every agent tool, configuration, and capability

---

## Tool Index

All built-in tools. `deny` wins over `allow`. Case-insensitive matching. `*` wildcards supported.

```json5
{ tools: { deny: ["browser"] } }
```

### Tool Groups (shorthands)
| Group | Tools |
|-------|-------|
| `group:runtime` | `exec`, `bash`, `process` |
| `group:fs` | `read`, `write`, `edit`, `apply_patch` |
| `group:sessions` | `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status` |
| `group:memory` | `memory_search`, `memory_get` |
| `group:web` | `web_search`, `web_fetch` |
| `group:ui` | `browser`, `canvas` |
| `group:automation` | `cron`, `gateway` |
| `group:messaging` | `message` |
| `group:nodes` | `nodes` |
| `group:openclaw` | all built-in OpenClaw tools |

### Tool Profiles (base allowlist)
| Profile | Tools |
|---------|-------|
| `minimal` | `session_status` only |
| `coding` | `group:fs`, `group:runtime`, `group:sessions`, `group:memory`, `image` |
| `messaging` | `group:messaging`, `sessions_list`, `sessions_history`, `sessions_send`, `session_status` |
| `full` | no restriction (same as unset) |

```json5
{
  tools: {
    profile: "messaging",
    allow: ["slack", "discord"],
  }
}
```

### Provider-Specific Tool Policy
```json5
{
  tools: {
    profile: "coding",
    byProvider: {
      "google-antigravity": { profile: "minimal" },
      "openai/gpt-5.2": { allow: ["group:fs", "sessions_list"] },
    }
  }
}
```

---

## exec Tool

Run shell commands in the workspace.

### Parameters
- `command` (required)
- `workdir` (defaults to cwd)
- `env` (key/value overrides)
- `yieldMs` (default 10000): auto-background after delay
- `background` (bool): background immediately
- `timeout` (seconds, default 1800): kill on expiry
- `pty` (bool): run in pseudo-terminal (for TTY-only CLIs)
- `host` (`sandbox | gateway | node`): where to execute
- `security` (`deny | allowlist | full`): enforcement mode
- `ask` (`off | on-miss | always`): approval prompts
- `node` (string): node id/name for `host=node`
- `elevated` (bool): request elevated mode on gateway host

Notes:
- `host` defaults to `sandbox`
- `elevated` ignored when sandboxing is off
- gateway/node approvals controlled by `~/.openclaw/exec-approvals.json`
- Sets `OPENCLAW_SHELL=exec` in spawned environment
- If sandboxing is off and `host=sandbox` → fails closed (not silently gateway)
- `env.PATH` and `LD_*`/`DYLD_*` overrides rejected for host execution (prevent binary hijacking)

### Config
```json5
{
  tools: {
    exec: {
      notifyOnExit: true,           // system event + heartbeat when background exits
      approvalRunningNoticeMs: 10000, // notice when approval-gated exec runs > this (0 disables)
      host: "sandbox",
      security: "deny",             // sandbox default
      ask: "on-miss",
      node: null,
      pathPrepend: ["~/bin", "/opt/oss/bin"],
      safeBins: [],
      safeBinTrustedDirs: [],
      safeBinProfiles: {},
      applyPatch: {
        enabled: false,
        workspaceOnly: true,
        allowModels: ["gpt-5.2"],
      }
    }
  }
}
```

### Session Overrides
```
/exec host=gateway security=allowlist ask=on-miss node=mac-1
```

### Examples
```json
// Foreground
{ "tool": "exec", "command": "ls -la" }

// Background + poll
{"tool":"exec","command":"npm run build","yieldMs":1000}
{"tool":"process","action":"poll","sessionId":"<id>"}

// Send keys (tmux-style)
{"tool":"process","action":"send-keys","sessionId":"<id>","keys":["Enter"]}
{"tool":"process","action":"send-keys","sessionId":"<id>","keys":["C-c"]}
{"tool":"process","action":"send-keys","sessionId":"<id>","keys":["Up","Up","Enter"]}

// Submit (CR only)
{ "tool": "process", "action": "submit", "sessionId": "<id>" }

// Paste (bracketed by default)
{ "tool": "process", "action": "paste", "sessionId": "<id>", "text": "line1\nline2\n" }
```

### `apply_patch` (experimental)
Enable explicitly. OpenAI/Codex models only. `workspaceOnly` defaults `true`.

---

## process Tool

Manage background exec sessions.

Actions: `list`, `poll`, `log`, `write`, `kill`, `clear`, `remove`

- `poll`: returns new output and exit status when complete
- `log`: line-based `offset`/`limit` (omit `offset` → last N lines)
- Scoped per agent; sessions from other agents not visible

---

## web_search / web_fetch

### Provider Decision Table
| Provider | Auth Key | Notes |
|----------|----------|-------|
| Brave | `BRAVE_API_KEY` | Structured results; `llm-context` mode; $5/mo free credit |
| Firecrawl | `FIRECRAWL_API_KEY` | Pairs with `firecrawl_scrape` |
| Gemini | `GEMINI_API_KEY` | AI-synthesized + Google Search grounding |
| Grok | `XAI_API_KEY` | xAI web-grounded responses |
| Kimi | `KIMI_API_KEY` / `MOONSHOT_API_KEY` | Moonshot web search |
| Perplexity | `PERPLEXITY_API_KEY` | `domain_filter` support |

**Auto-detection order**: Brave → Gemini → Grok → Kimi → Perplexity → Firecrawl.

### Config (Brave example)
```json5
{
  plugins: {
    entries: {
      brave: {
        config: {
          webSearch: {
            apiKey: "YOUR_BRAVE_API_KEY",
            mode: "llm-context",  // optional: "llm-context" returns page chunks
          }
        }
      }
    }
  },
  tools: { web: { search: { enabled: true, provider: "brave" } } }
}
```

### web_search Parameters
| Param | Description |
|-------|-------------|
| `query` | Required |
| `count` | 1-10 (default from `tools.web.search.maxResults`) |
| `country` | 2-letter ISO code |
| `language` | ISO 639-1 code |
| `freshness` | `day`/`week`/`month`/`year` |
| `date_after` / `date_before` | YYYY-MM-DD |
| `ui_lang` | Brave only |
| `domain_filter` | Perplexity only |

### web_fetch Parameters
- `url` (required)
- `extractMode`: `markdown` | `text`
- `maxChars`: clamped by `tools.web.fetch.maxCharsCap` (default 50000)
- Cached 15 minutes by default
- For JS-heavy sites → use browser tool

---

## Subagents / sessions Tools

### sessions_spawn
Start sub-agent or ACP session.

```json
{
  "task": "Build a feature",
  "runtime": "subagent",     // "subagent" (default) or "acp"
  "agentId": "codex",        // for ACP
  "thread": true,            // request thread binding
  "mode": "session"          // "run" (one-shot) or "session" (persistent, requires thread:true)
}
```

### sessions_list / sessions_history
Browse and read session data.

### sessions_send
Send message to a specific session.

### sessions_spawn `runtime: "acp"`
```json
{
  "task": "Open the repo and summarize failing tests",
  "runtime": "acp",
  "agentId": "codex",
  "thread": true,
  "mode": "session"
}
```

Resume existing ACP session:
```json
{
  "task": "Continue where we left off",
  "runtime": "acp",
  "agentId": "codex",
  "resumeSessionId": "<previous-session-id>"
}
```

---

## Skills Tool / Skills Config

### Skills Discovery (3 locations, workspace wins)
1. Bundled (shipped with OpenClaw)
2. Managed: `~/.openclaw/skills`
3. Workspace: `<workspace>/skills`

### Skills Config
```json5
{
  skills: {
    allowBundled: ["gemini", "peekaboo"],
    load: {
      extraDirs: ["~/Projects/agent-scripts/skills"],
      watch: true,
      watchDebounceMs: 250,
    },
    install: {
      preferBrew: true,
      nodeManager: "npm",
    },
    entries: {
      "image-lab": {
        enabled: true,
        apiKey: { source: "env", provider: "default", id: "GEMINI_API_KEY" },
        env: { GEMINI_API_KEY: "KEY_HERE" },
      },
      peekaboo: { enabled: true },
      sag: { enabled: false },
    }
  }
}
```

**Fields:**
- `allowBundled`: optional allowlist for bundled skills only
- `load.extraDirs`: additional skill directories (lowest precedence)
- `load.watch`: watch folders + refresh skills snapshot (default: true)
- `install.preferBrew`: prefer brew installers (default: true)
- `install.nodeManager`: `npm` | `pnpm` | `yarn` | `bun` (default: npm)
- `entries.<skillKey>.enabled`: false disables even if bundled/installed
- `entries.<skillKey>.env`: env vars injected for agent run (host runs only)
- `entries.<skillKey>.apiKey`: plaintext or SecretRef

**Per-agent skills**: use `agents.list[].tools.alsoAllow` or workspace `skills/` folder.

---

## llm-task (optional plugin tool)

JSON-only LLM task with optional schema validation. Ideal for workflow automation.

### Enable
```json
{
  "plugins": { "entries": { "llm-task": { "enabled": true } } },
  "agents": { "list": [{ "id": "main", "tools": { "allow": ["llm-task"] } }] }
}
```

### Config
```json
{
  "plugins": { "entries": { "llm-task": { "enabled": true, "config": {
    "defaultProvider": "openai-codex",
    "defaultModel": "gpt-5.4",
    "allowedModels": ["openai-codex/gpt-5.4"],
    "maxTokens": 800,
    "timeoutMs": 30000
  }}}}
}
```

### Parameters
`prompt` (required), `input`, `schema` (JSON Schema), `provider`, `model`, `thinking`, `authProfileId`, `temperature`, `maxTokens`, `timeoutMs`

Returns: `details.json` with parsed JSON, validated against `schema` when provided.

---

## browser Tool

Control dedicated OpenClaw-managed browser (separate from personal browser).

### Core Actions
- `status`, `start`, `stop`, `tabs`, `open`, `focus`, `close`
- `snapshot` (aria/ai)
- `screenshot` (returns image block + `MEDIA:<path>`)
- `act` (click/type/drag/select/fill/resize/wait/evaluate)
- `navigate`, `console`, `pdf`, `upload`, `dialog`
- Profile management: `profiles`, `create-profile`, `delete-profile`, `reset-profile`

### Profiles
- `openclaw`: managed isolated browser (default) — no personal data
- `user`: attach to real signed-in Chrome via Chrome DevTools MCP
- Custom profiles: `name`, `cdpPort`, `color`, driver type

### Config
```json5
{
  browser: {
    enabled: true,
    defaultProfile: "openclaw",
    color: "#FF4500",
    headless: false,
    executablePath: "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    ssrfPolicy: {
      dangerouslyAllowPrivateNetwork: true,  // default trusted-network mode
    },
    profiles: {
      openclaw: { cdpPort: 18800, color: "#FF4500" },
      work: { cdpPort: 18801, color: "#0066CC" },
      user: { driver: "existing-session", attachOnly: true, color: "#00AA00" },
      remote: { cdpUrl: "http://10.0.0.42:9222", color: "#00AA00" },
    }
  }
}
```

Notes:
- Browser control service binds to loopback on port derived from `gateway.port` (default: 18791 = gateway + 2)
- `attachOnly: true` → never launch local browser; only attach if already running
- `profile="user"` for logged-in sessions (user must be at computer to approve attach prompt)
- Control via `?profile=<name>` or `--browser-profile` CLI

### Remote CDP (Browserless, Browserbase)
```json5
{
  browser: {
    profiles: {
      browserless: { cdpUrl: "https://production-sfo.browserless.io?token=<KEY>", color: "#00AA00" },
      browserbase: { cdpUrl: "wss://connect.browserbase.com?apiKey=<KEY>", color: "#F97316" },
    }
  }
}
```

---

## Thinking Tool / `/think` Directive

Control model reasoning level.

### Levels
`off`, `minimal`, `low`, `medium`, `high`, `xhigh` (GPT-5.2 + Codex models only)

### Per-message
`/think:low` or `/think:off` in message (directive, stripped before model sees it)

### Per-cron-job
```json
{ "payload": { "kind": "agentTurn", "thinking": "high" } }
```

### Anthropic Claude 4.6 Defaults
Defaults to `adaptive` thinking when no explicit level set.

Override in model params:
```json5
{ "agents": { "defaults": { "models": { "anthropic/claude-opus-4-6": { "params": { "thinking": "medium" } } } } } }
```

---

## Elevated Mode

`exec`-only escape hatch to run on host when sandboxed.

- `/elevated on` → current session uses host for exec
- `/elevated full` → skip exec approvals for session
- Does NOT grant extra tools; only affects `exec`
- If already running direct → effectively no-op
- NOT skill-scoped; does NOT override tool allow/deny

Gates:
- `tools.elevated.enabled`
- `tools.elevated.allowFrom.<provider>` (sender allowlists)
- Per-agent: `agents.list[].tools.elevated.enabled` + `agents.list[].tools.elevated.allowFrom`

---

## ACP Agents

ACP (Agent Client Protocol) sessions for external coding harnesses: Pi, Claude Code, Codex, OpenCode, Gemini CLI.

### ACP vs Sub-agents
| Area | ACP session | Sub-agent run |
|------|-------------|---------------|
| Runtime | ACP backend plugin (e.g. acpx) | OpenClaw native sub-agent |
| Session key | `agent:<agentId>:acp:<uuid>` | `agent:<agentId>:subagent:<uuid>` |
| Main commands | `/acp ...` | `/subagents ...` |
| Spawn tool | `sessions_spawn` with `runtime:"acp"` | `sessions_spawn` (default) |

### Required Config
```json5
{
  acp: {
    enabled: true,
    dispatch: { enabled: true },
    backend: "acpx",
    defaultAgent: "codex",
    allowedAgents: ["pi", "claude", "codex", "opencode", "gemini", "kimi"],
    maxConcurrentSessions: 8,
    stream: { coalesceIdleMs: 300, maxChunkChars: 1200 },
    runtime: { ttlMinutes: 120 },
  }
}
```

### ACP Command Cookbook
| Command | What it does | Example |
|---------|-------------|---------|
| `/acp spawn` | Create session; optional thread bind | `/acp spawn codex --mode persistent --thread auto` |
| `/acp cancel` | Cancel in-flight turn | `/acp cancel` |
| `/acp steer` | Send steer instruction | `/acp steer prioritize failing tests` |
| `/acp close` | Close session + unbind | `/acp close` |
| `/acp status` | Show runtime state | `/acp status` |
| `/acp model` | Set model override | `/acp model anthropic/claude-opus-4-5` |
| `/acp permissions` | Set approval policy | `/acp permissions strict` |
| `/acp timeout` | Set timeout (seconds) | `/acp timeout 120` |
| `/acp cwd` | Set working directory | `/acp cwd /workspace/repo` |
| `/acp sessions` | List recent sessions | `/acp sessions` |
| `/acp doctor` | Backend health check | `/acp doctor` |

### Thread Binding Config
```json5
{
  session: { threadBindings: { enabled: true, idleHours: 24, maxAgeHours: 0 } },
  channels: {
    discord: { threadBindings: { enabled: true, spawnAcpSessions: true } },
    telegram: { threadBindings: { enabled: true, spawnAcpSessions: true } }
  }
}
```

### Sandbox Compatibility
ACP sessions run on host runtime. From sandboxed sessions: use `runtime:"subagent"` instead.

---

## agent-send / sessions_send

Send messages directly to sessions or agents.

```json
{
  "tool": "sessions_send",
  "sessionKey": "agent:main:telegram:direct:123456789",
  "message": "Here is your update"
}
```

---

## Diffs Tool (optional plugin)

Read-only diff viewer and PNG/PDF file renderer.

### Enable
```json
{ "tools": { "alsoAllow": ["diffs"] } }
```

Actions: view unified diffs, render PNG/PDF before/after comparisons.

---

## Reactions Tool

Send emoji reactions to messages.

```json
{
  "tool": "message",
  "action": "react",
  "channel": "telegram",
  "messageId": "12345",
  "reaction": "👍"
}
```

Supported channels: Telegram, Discord, Slack, WhatsApp (limited), iMessage.

---

## Slash Commands

Gateway-side commands; the model never sees them.

### Key Commands
| Command | Behavior |
|---------|----------|
| `/status` | Session context usage, model, thinking toggles |
| `/context list` | Injected files + sizes |
| `/context detail` | Deep breakdown per file/tool/skill |
| `/compact [instructions]` | Force compaction |
| `/new [model]` | Reset session; optional model change |
| `/reset` | Reset session |
| `/stop` | Abort current run + queued followups |
| `/model <alias>` | Switch model for session |
| `/think:<level>` | Per-message thinking level |
| `/verbose` | Toggle verbose tool summaries |
| `/reasoning on/off/stream` | Control reasoning visibility |
| `/elevated on/off/full` | Toggle elevated exec |
| `/fast on/off` | Toggle fast mode (priority tier) |
| `/queue <mode>` | Set queue mode for session |
| `/exec host=... security=... ask=... node=...` | Set exec defaults |
| `/send on/off/inherit` | Control outbound delivery |
| `/usage tokens/full/off/cost` | Toggle usage footer |

**Directives** (stripped before model sees message): `/think`, `/verbose`, `/reasoning`, `/elevated`, `/model`, `/queue`

**Inline shortcuts** (allowlisted senders only): e.g. `hey /status` in normal message.

---

## Lobster (workflow runtime)

Typed workflow runtime with resumable approvals and deterministic multi-step pipelines.

### Enable
```json5
{
  tools: { alsoAllow: ["lobster"] },
  plugins: { entries: { lobster: { enabled: true } } }
}
```

Requires `lobster` CLI on PATH.

### When Lobster Fits
- Multi-step automation needing fixed pipeline of tool calls
- Approval gates (side effects pause until you approve, then resume)
- Resumable runs (continue paused workflow without re-running earlier steps)

### Pairing with Cron/Heartbeat
- Cron/heartbeat decide **when** run happens
- Lobster defines **what steps** happen once run starts

---

## Loop Detection

Track recent tool-call history and block/warn on repetitive no-progress loops.

```json5
{
  tools: {
    loopDetection: {
      enabled: true,
      warningThreshold: 10,
      criticalThreshold: 20,
      globalCircuitBreakerThreshold: 30,
      historySize: 30,
      detectors: {
        genericRepeat: true,
        knownPollNoProgress: true,
        pingPong: true,
      }
    }
  }
}
```

Detectors:
- `genericRepeat`: repeated same tool + same params
- `knownPollNoProgress`: repeating poll-like tools with identical outputs
- `pingPong`: alternating A/B/A/B no-progress patterns

Per-agent override: `agents.list[].tools.loopDetection`.

---

## BTW (Background Task Watcher)

Background exit notifications. When `tools.exec.notifyOnExit: true` (default), backgrounded exec sessions enqueue a system event and request a heartbeat on exit.

---

## Exec Approvals

Policy for gateway/node exec runs. State in `~/.openclaw/exec-approvals.json`.

### Security Modes
- `deny`: block all (sandbox default)
- `allowlist`: only allowlisted resolved binary paths
- `full`: skip approvals entirely

### Ask Modes
- `off`: no prompts
- `on-miss`: prompt when binary not in allowlist (default)
- `always`: prompt for every exec

### Allowlist Mechanics
Manual allowlist matches **resolved binary paths only** (no basename matches). Chaining (`;`, `&&`, `||`) and redirections rejected in allowlist mode unless all segments allowlisted or safe bins.

### Safe Bins
```json5
{
  tools: {
    exec: {
      safeBins: ["grep", "sed", "awk"],
      safeBinTrustedDirs: ["/opt/homebrew/bin"],
      safeBinProfiles: {
        "grep": { minPositional: 1, maxPositional: 2, allowedValueFlags: ["-n", "-i", "-r"] }
      }
    }
  }
}
```

Safe bins = stdin-only stream filters. Do NOT add interpreter/runtime binaries (python3, node, ruby, bash). Use explicit allowlist entries for those.

When approvals pending: exec returns `status: "approval-pending"` with approval ID. Gateway emits system events on completion.

---

## Capability Cookbook

Rules for adding new capabilities:

1. Plugin = ownership boundary; capability = shared core contract
2. Create a capability when: multiple vendors could implement it AND channels/tools should consume it without caring about vendor AND core needs to own fallback/policy/config/delivery

### Standard Sequence
1. Define typed core contract
2. Add plugin registration
3. Add shared runtime helper
4. Wire one real vendor plugin as proof
5. Move consumers onto runtime helper
6. Add contract tests
7. Document operator-facing config

### What Goes Where
- **Core**: request/response types, provider registry, fallback behavior, config schema, runtime helper
- **Vendor plugin**: vendor API calls, auth handling, normalization, capability registration
- **Feature/channel plugin**: calls `api.runtime.*` or `plugin-sdk/*-runtime` helper; never calls vendor directly

### Image Generation (example)
- `agents.defaults.imageModel` = analyze images
- `agents.defaults.imageGenerationModel` = generate images

```json5
{
  agents: {
    defaults: {
      imageGenerationModel: {
        primary: "google/gemini-3-pro-image-preview",
        fallbacks: ["fal/fal-ai/flux/dev"],
      }
    }
  }
}
```

---

## pdf Tool

Analyze one or more PDF documents.

### Availability
Tool registered when OpenClaw can resolve PDF-capable model config:
1. `agents.defaults.pdfModel`
2. Fallback to `agents.defaults.imageModel`
3. Best effort from available auth

### Parameters
- `pdf` (string): one PDF path or URL
- `pdfs` (string[]): multiple, up to 10
- `prompt`: default `"Analyze this PDF document."`
- `pages`: filter like `"1-5"` or `"1,3,7-9"`
- `model`: optional override
- `maxBytesMb`: per-PDF size cap (default 10)

### Modes
- **Native mode** (Anthropic + Google): sends raw PDF bytes directly; `pages` not supported
- **Extraction fallback**: extract text → render page images if text < 200 chars

### Config
```json5
{
  agents: {
    defaults: {
      pdfModel: {
        primary: "anthropic/claude-opus-4-6",
        fallbacks: ["openai/gpt-5-mini"],
      },
      pdfMaxBytesMb: 10,
      pdfMaxPages: 20,
    }
  }
}
```

### Examples
```json
// Single PDF
{ "pdf": "/tmp/report.pdf", "prompt": "Summarize in 5 bullets" }

// Multiple PDFs
{ "pdfs": ["/tmp/q1.pdf", "/tmp/q2.pdf"], "prompt": "Compare risks" }

// Page-filtered
{ "pdf": "https://example.com/report.pdf", "pages": "1-3,7", "model": "openai/gpt-5-mini" }
```

---

## message Tool

Send messages and channel actions.

### Core Actions
- `send` (text + optional media)
- `poll` (WhatsApp/Discord/MS Teams)
- `react` / `reactions` / `read` / `edit` / `delete`
- `pin` / `unpin` / `list-pins`
- `thread-create` / `thread-list` / `thread-reply`
- `search`, `sticker`
- `member-info`, `role-info`, `emoji-list`, `emoji-upload`, `sticker-upload`
- `role-add`, `role-remove`, `channel-info`, `channel-list`
- `voice-status`, `event-list`, `event-create`
- `timeout`, `kick`, `ban`

---

## cron Tool

Manage Gateway cron jobs from within agent turns.

Actions: `status`, `list`, `add`, `update`, `remove`, `run`, `runs`, `wake`

---

## gateway Tool

```json
{
  "action": "restart"  // sends SIGUSR1 for in-process restart
}
```

Other actions: `config.schema.lookup`, `config.get`

---

## image Tool

Analyze an image with configured image model.

Parameters: `image` (required path or URL), `prompt`, `model`, `maxBytesMb`

Only available when `agents.defaults.imageModel` is configured.

## image_generate Tool

Generate images with configured image-generation model.

Parameters: `action` (`generate`/`list`), `prompt` (required), `image`/`images` (reference for edit), `model`, `size`, `resolution` (`1K`/`2K`/`4K`), `count` (1-4, default 1)

Only available when `agents.defaults.imageGenerationModel` is configured (or inferred).

---

## nodes Tool

Discover and target paired nodes.

Actions: `status`, `describe`, `pending`, `approve`, `reject`, `notify`, `run`, `camera_list`, `camera_snap`, `camera_clip`, `screen_record`, `location_get`, `notifications_list`, `notifications_action`, `device_status`, `device_info`, `device_permissions`, `device_health`

---

## canvas Tool

Drive node Canvas.

Actions: `present`, `hide`, `navigate`, `eval`, `snapshot`, `a2ui_push`, `a2ui_reset`

---

## Our Setup (ClawExpert)

- **Web search**: Brave API (`BRAVE_API_KEY` configured)
- **Browser**: enabled, default profile `openclaw`
- **Exec**: sandbox mode (non-main sessions sandboxed)
- **Tool policy**: standard coding profile on Maks, messaging profile on specialized agents
- **Skills**: skills from `~/.openclaw/skills` + workspace-specific in each workspace
- **Loop detection**: disabled by default (enable if needed per agent)
- **ACP**: not configured (use sub-agents via `sessions_spawn`)
- **llm-task**: not enabled (use cron isolated jobs instead)
