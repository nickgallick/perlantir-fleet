---
name: openclaw-schema-map
description: Complete map of the OpenClaw config schema from source code. THE single source of truth for valid config keys.
---

# Changelog
- 2026-03-19: Initial extraction from repos/openclaw/src/config/zod-schema.ts

# OpenClaw Config Schema Map (from source code)

## SOURCE
Extracted from Zod schema: `repos/openclaw/src/config/zod-schema.ts`
THIS IS AUTHORITATIVE. If docs disagree with this, this is correct.

## How to Regenerate
```bash
cd /data/.openclaw/workspace-clawexpert/repos/openclaw && git pull
cat src/config/zod-schema.ts
```

---

## Root-Level Keys (ALL valid keys — schema is `.strict()`)

| Key | Type | Required | Notes |
|-----|------|----------|-------|
| `$schema` | string | No | Schema URL |
| `meta` | object | No | lastTouchedVersion, lastTouchedAt |
| `env` | object | No | shellEnv, vars, catchall string |
| `wizard` | object | No | lastRunAt, lastRunVersion, etc. |
| `diagnostics` | object | No | enabled, flags, stuckSessionWarnMs, otel, cacheTrace |
| `logging` | object | No | level, file, maxFileBytes, consoleLevel, consoleStyle, redactSensitive, redactPatterns |
| `cli` | object | No | banner.taglineMode |
| `update` | object | No | channel (stable/beta/dev), checkOnStart, auto |
| `browser` | object | No | enabled, cdpUrl, headless, profiles, ssrfPolicy, etc. |
| `ui` | object | No | seamColor, assistant.name, assistant.avatar |
| `secrets` | object | No | providers, defaults, resolution |
| `auth` | object | No | profiles, order, cooldowns |
| `acp` | object | No | enabled, dispatch, backend, defaultAgent, allowedAgents, stream, runtime |
| `models` | object | No | mode, providers, bedrockDiscovery |
| `nodeHost` | object | No | browserProxy |
| `agents` | object | No | defaults, list[] |
| `tools` | object | No | web, media, links, sessions, exec, fs, etc. |
| `bindings` | array | No | route and acp bindings |
| `broadcast` | object | No | agent-to-agent broadcast config |
| `audio` | object | No | audio config |
| `media` | object | No | preserveFilenames, ttlHours |
| `messages` | object | No | MessagesSchema |
| `commands` | object | No | CommandsSchema |
| `approvals` | object | No | ApprovalsSchema |
| `session` | object | No | SessionSchema |
| `cron` | object | No | enabled, store, maxConcurrentRuns, retry, webhook, sessionRetention, runLog, failureAlert, failureDestination |
| `hooks` | object | No | enabled, path, token, mappings, gmail, internal, etc. |
| `web` | object | No | enabled, heartbeatSeconds, reconnect |
| `channels` | object | No | ChannelsSchema (all channel types) |
| `discovery` | object | No | wideArea, mdns |
| `canvasHost` | object | No | enabled, root, port, liveReload |
| `talk` | object | No | provider, providers, voiceId, modelId, apiKey, etc. |
| `gateway` | object | No | port, mode, bind, customBindHost, controlUi, auth, tls, http, etc. |
| `memory` | object | No | backend, citations, qmd |
| `mcp` | object | No | servers record (stdio MCP servers) |
| `skills` | object | No | allowBundled, load, install, limits, entries |
| `plugins` | object | No | enabled, allow, deny, load, slots, entries, installs |

**REJECTED/INVALID ROOT KEYS**: Any key not in the above list will crash the gateway (`.strict()` mode).

---

## `agents` schema

### `agents.defaults`
See AgentDefaultsSchema — same shape as agent entries but all optional.

### `agents.list[]` item (AgentEntrySchema)
| Key | Type | Required | Notes |
|-----|------|----------|-------|
| `id` | string | **YES** | Unique agent identifier |
| `default` | boolean | No | Is this the default agent? |
| `name` | string | No | Display name |
| `workspace` | string | No | Path to workspace directory |
| `agentDir` | string | No | Alternative: agent directory path |
| `model` | AgentModelSchema | No | Model string or object |
| `skills` | string[] | No | Skill IDs to load |
| `memorySearch` | MemorySearchSchema | No | Memory search config |
| `humanDelay` | HumanDelaySchema | No | mode, minMs, maxMs |
| `heartbeat` | HeartbeatSchema | No | every, activeHours, model, prompt, etc. |
| `identity` | IdentitySchema | No | name, theme, emoji, avatar |
| `groupChat` | GroupChatSchema | No | mentionPatterns, historyLimit |
| `subagents` | object | No | allowAgents, model, thinking |
| `sandbox` | AgentSandboxSchema | No | docker, network, etc. |
| `params` | record | No | Arbitrary key-value params |
| `tools` | AgentToolsSchema | No | Per-agent tool overrides |
| `runtime` | AgentRuntimeSchema | No | Runtime config |

---

## `gateway` schema

| Key | Type | Notes |
|-----|------|-------|
| `port` | int | Gateway port |
| `mode` | "local" \| "remote" | |
| `bind` | "auto" \| "lan" \| "loopback" \| "custom" \| "tailnet" | |
| `customBindHost` | string | **VALID** — use with bind:"custom" |
| `controlUi` | object | enabled, basePath, allowedOrigins, etc. |
| `auth` | object | mode, token, password, rateLimit, trustedProxy |
| `auth.mode` | "none" \| "token" \| "password" \| "trusted-proxy" | |
| `tls` | object | enabled, autoGenerate, certPath, keyPath |
| `tailscale` | object | mode (off/serve/funnel), resetOnExit |
| `remote` | object | url, transport, token, sshTarget, etc. |
| `reload` | object | mode (off/restart/hot/hybrid), debounceMs |
| `http` | object | endpoints (chatCompletions, responses), securityHeaders |
| `push` | object | apns relay config |
| `nodes` | object | browser mode/node, allowCommands, denyCommands |
| `tools` | object | deny, allow arrays |
| `channelHealthCheckMinutes` | int | 0=disabled, default 5 |
| `channelStaleEventThresholdMinutes` | int | Must be >= healthCheckMinutes |
| `channelMaxRestartsPerHour` | int | |
| `trustedProxies` | string[] | |
| `allowRealIpFallback` | boolean | |

---

## `channels` schema
Defined in `zod-schema.providers.ts` — includes: telegram, discord, slack, signal, whatsapp, imessage, irc, msteams, googlechat, feishu, webchat, and more.

---

## `cron` schema
| Key | Type | Notes |
|-----|------|-------|
| `enabled` | boolean | |
| `store` | string | Storage path |
| `maxConcurrentRuns` | int | |
| `retry` | object | maxAttempts, backoffMs[], retryOn[] |
| `retry.retryOn` | enum[] | rate_limit, overloaded, network, timeout, server_error |
| `webhook` | http url | |
| `webhookToken` | SecretInput | |
| `sessionRetention` | string \| false | Duration string (ms/s/m/h/d) or false |
| `runLog` | object | maxBytes (string/number), keepLines |
| `failureAlert` | object | enabled, after, cooldownMs, mode, accountId |
| `failureDestination` | object | channel, to, accountId, mode |

---

## `mcp` schema (NATIVE stdio MCP — not mcporter)
```
mcp:
  servers:
    <server-name>:
      command: string       # stdio server command
      args: string[]
      env: record
      cwd: string
      workingDirectory: string
      url: http url         # for HTTP-based servers
```
ACP capabilities (http/sse) are `false` — but stdio MCP works via `mcp.servers`.

---

## `memory` schema
| Key | Type | Notes |
|-----|------|-------|
| `backend` | "builtin" \| "qmd" | |
| `citations` | "auto" \| "on" \| "off" | |
| `qmd` | object | command, mcporter, searchMode, paths, sessions, update, limits, scope |
| `qmd.searchMode` | "query" \| "search" \| "vsearch" | |
| `qmd.mcporter.enabled` | boolean | Route QMD through mcporter daemon |

---

## `skills` schema
| Key | Type | Notes |
|-----|------|-------|
| `allowBundled` | string[] | |
| `load.extraDirs` | string[] | Additional skill dirs |
| `load.watch` | boolean | |
| `install.preferBrew` | boolean | |
| `install.nodeManager` | npm/pnpm/yarn/bun | |
| `limits` | object | maxCandidatesPerRoot, maxSkillsLoadedPerSource, etc. |
| `entries.<id>` | SkillEntrySchema | enabled, apiKey, env, config |

---

## `plugins` schema
| Key | Type | Notes |
|-----|------|-------|
| `enabled` | boolean | |
| `allow` | string[] | |
| `deny` | string[] | |
| `load.paths` | string[] | |
| `slots.memory` | string | Plugin ID for memory slot |
| `slots.contextEngine` | string | Plugin ID for context engine slot |
| `entries.<id>` | PluginEntrySchema | enabled, hooks, subagent, config |
| `installs.<id>` | PluginInstallRecordShape | |

---

## `secrets` schema
| Key | Type | Notes |
|-----|------|-------|
| `providers.<name>` | SecretProviderSchema | source: env/file/exec |
| `defaults.env` | string | Default env provider alias |
| `defaults.file` | string | Default file provider alias |
| `defaults.exec` | string | Default exec provider alias |
| `resolution` | object | maxProviderConcurrency, maxRefsPerProvider, maxBatchBytes |

SecretInput type accepts: plain string OR `{ source: "env"/"file"/"exec", provider: string, id: string }`

---

## `auth` schema
| Key | Type | Notes |
|-----|------|-------|
| `profiles.<name>` | object | provider, mode (api_key/oauth/token), email |
| `order` | record | provider → auth profile order |
| `cooldowns` | object | billingBackoffHours, failureWindowHours, etc. |

---

## `logging` schema
| Key | Type | Notes |
|-----|------|-------|
| `level` | silent/fatal/error/warn/info/debug/trace | |
| `file` | string | Log file path |
| `maxFileBytes` | int | |
| `consoleLevel` | same enum | |
| `consoleStyle` | pretty/compact/json | |
| `redactSensitive` | "off" \| "tools" | |
| `redactPatterns` | string[] | |

---

## `update` schema
| Key | Type | Notes |
|-----|------|-------|
| `channel` | "stable" \| "beta" \| "dev" | |
| `checkOnStart` | boolean | |
| `auto.enabled` | boolean | |
| `auto.stableDelayHours` | number | Max 168 |
| `auto.betaCheckIntervalHours` | number | Max 24 |

---

## `acp` schema
| Key | Type | Notes |
|-----|------|-------|
| `enabled` | boolean | |
| `dispatch.enabled` | boolean | |
| `backend` | string | |
| `defaultAgent` | string | |
| `allowedAgents` | string[] | |
| `maxConcurrentSessions` | int | |
| `stream` | object | coalesceIdleMs, maxChunkChars, deliveryMode, etc. |
| `runtime.ttlMinutes` | int | |
| `runtime.installCommand` | string | |

---

## `diagnostics.otel` schema
| Key | Type | Notes |
|-----|------|-------|
| `enabled` | boolean | |
| `endpoint` | string | |
| `protocol` | "http/protobuf" \| "grpc" | |
| `headers` | record | |
| `traces/metrics/logs` | boolean | |
| `sampleRate` | 0-1 | |
| `flushIntervalMs` | int | |

---

## Rejected / Invalid Root Keys
- `mcpServers` — NEVER a root key; use `mcp.servers` instead
- Any unknown key at root level → Zod `.strict()` throws → gateway crash
