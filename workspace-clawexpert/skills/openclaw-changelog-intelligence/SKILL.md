---
name: openclaw-changelog-intelligence
description: Complete OpenClaw changelog analysis — version history, config keys by version, breaking changes, upgrade paths. The authoritative reference for version-safe config changes. Covers 2026.1.5 through 2026.3.14 (Unreleased).
---

# OpenClaw Changelog Intelligence

## Changelog
- 2026-03-20: Created from full CHANGELOG.md analysis (versions 2026.1.5 → 2026.3.14/Unreleased)

---

## Version History Summary

### Unreleased (Next after 2026.3.13)
**Key New Features:**
- `sessions_yield` for orchestrators to end turn immediately with hidden follow-up payload
- `talk.silenceTimeoutMs` config for Talk mode auto-send threshold
- `cron sessionTarget: "current"` and `session:<id>` support
- Dashboard v2 (modular overview, chat, config, agent, session views; command palette)
- Fast mode toggles (`/fast`, `params.fastMode`) for OpenAI GPT-5.4 and Anthropic Claude
- Ollama, vLLM, SGLang moved to provider-plugin architecture
- OpenAI Responses WebSocket as default transport
- Kubernetes starter deployment with K8s manifests
- `browser.profiles.<name>.userDataDir` for attaching to existing Chromium browsers
- `channels.telegram.silentErrorReplies` config (default off)
- `browser.profiles.<name>.driver: "openclaw"` accepted (with legacy `"clawd"` alias)
- Health monitor with per-channel and per-account `healthMonitor.enabled` overrides
- `Telegram/--force-document` for uploading images as documents
- Android dark theme for onboarding
- `plugins.entries.<id>.hooks.allowPromptInjection` config

**Breaking Changes in Unreleased:**
- `nano-banana-pro` bundled skill removed → use `agents.defaults.imageGenerationModel.primary`
- Chrome extension relay path removed; `driver: "extension"` and `browser.relayBindHost` removed → run `openclaw doctor --fix` to migrate
- `openclaw/extension-api` public surface removed; use `openclaw/plugin-sdk/*` subpaths
- `ChannelMessageActionAdapter.describeMessageTool(...)` required for shared `message` tool; `listActions`, `getCapabilities`, `getToolSchema` removed
- Build-tool JVM injection env vars blocked from host exec (`MAVEN_OPTS`, `SBT_OPTS`, `GRADLE_OPTS`, `ANT_OPTS`, `GLIBC_TUNABLES`, `DOTNET_ADDITIONAL_DEPS`)

---

### 2026.3.13 (Current stable - our version)
**Key Features:**
- Android chat settings redesign
- iOS first-run welcome pager
- `Browser/existing-session` Chrome DevTools MCP attach mode
- Built-in browser `profile="user"` and `profile="chrome-relay"`
- `OPENCLAW_TZ` env var for Docker timezone pinning
- Cron `sessionTarget: "current"` and `session:<id>` support
- Telegram `--force-document` for image/GIF sends
- `agents.defaults.compaction.postIndexSync` config for post-compaction memory reindexing
- `agents.defaults.memorySearch.sync.sessions.postCompactionForce` config

**Breaking Changes in 2026.3.13:**
- **BREAKING:** Agents now load at most one root memory bootstrap file. `MEMORY.md` wins; `memory.md` only used when `MEMORY.md` is absent. If you had both files, merge before upgrade. Also fixes duplicate memory injection on case-insensitive Docker mounts.

**Security Fixes:**
- Bootstrap setup codes now single-use (prevents silent replay/widening to admin)
- Zero-width/soft-hyphen marker-splitting bypass blocked
- Multiple exec approval hardening fixes
- Telegram webhook secret validated before reading request body
- Telegram file URL redaction from error logs

---

### 2026.3.12
**Key Features:**
- Dashboard v2 Control UI with modular overview, chat, config, agent, session views
- Command palette, mobile bottom tabs, slash commands, search, export, pinned messages
- OpenAI GPT-5.4 fast mode with `/fast` toggle and `params.fastMode`
- Anthropic Claude fast mode (maps to `service_tier` API parameter)
- Ollama, vLLM, SGLang moved to provider-plugin architecture
- `sessions_yield` tool for orchestrators
- Slack Block Kit messages via `channelData.slack.blocks`
- `channels.slack.capabilities.interactiveReplies` (disabled by default)
- Short-lived bootstrap tokens for `/pair` and `openclaw qr` setup codes

**Security Fixes:**
- Device pairing setup codes switched to short-lived bootstrap tokens
- Implicit workspace plugin auto-load disabled (GHSA-99qw-6mr3-36qr)

---

### 2026.3.11
**Key Features:**
- iOS Home canvas with live agent overview
- macOS chat model picker with thinking-level persistence
- Ollama first-class setup with Local / Cloud + Local modes
- OpenCode Go provider added
- Multi-modal image and audio indexing for `memorySearch.extraPaths`
- Gemini `gemini-embedding-2-preview` memory search support
- `channels.discord.autoArchiveDuration` for auto-created threads
- ACP `sessions_spawn` with `resumeSessionId` for resuming existing conversations
- `Exec/child commands: OPENCLAW_CLI` env marker for subprocesses

**Breaking Changes in 2026.3.11:**
- Cron/doctor: tighten isolated cron delivery so cron jobs can no longer notify through ad hoc agent sends or fallback main-session summaries

**Security Fixes:**
- Gateway/WebSocket: browser origin validation enforced for all browser-originated connections (GHSA-5wcw-8jjv-m286) — critical: could grant untrusted origins `operator.admin`

---

### 2026.3.8
**Key Features:**
- `openclaw backup create` and `openclaw backup verify` commands
- `talk.silenceTimeoutMs` config for configurable silence detection
- TUI infers active agent from workspace
- `tools.web.search.brave.mode: "llm-context"` for Brave LLM Context endpoint
- `openclaw --version` now includes short git commit hash
- ACP provenance metadata (`openclaw acp --provenance off|meta|meta+receipt`)
- `channels.telegram.silentErrorReplies` (default off)

**Security Fixes:**
- Gateway auth: loopback hop spoofing ignored in trusted forwarding chains
- ACP: canonical tool identity for prompting; fail-closed on conflicting identity hints
- Subagents/follow-ups: ownership checks for `/subagents send`

---

### 2026.3.7
**Key Features:**
- `ContextEngine` plugin slot with full lifecycle hooks (bootstrap, ingest, assemble, compact, afterTurn, prepareSubagentSpawn, onSubagentEnded)
- ACP persistent Discord channel and Telegram topic binding storage
- Telegram per-topic `agentId` overrides in forum groups and DM topics
- Web UI Spanish locale support
- `gateway.auth.token` SecretRef support
- `OPENCLAW_EXTENSIONS` Docker build arg for pre-installing extension dependencies
- `plugins.entries.<id>.hooks.allowPromptInjection` config
- `agents.defaults.compaction.postCompactionSections` config
- `messages.tts.openai.baseUrl` config
- `channels.slack.typingReaction` config
- `channels.discord.allowBots: "mentions"` option
- `agents.defaults.compaction.recentTurnsPreserve` config exposed
- `Hooks/Compaction lifecycle` — `session:compact:before` and `session:compact:after` events
- `agents.defaults.compaction.model` for routing compaction through different model
- Gemini 3.1 Flash-Lite support

**Breaking Changes in 2026.3.7:**
- **BREAKING:** `gateway.auth.mode` required explicitly when both `gateway.auth.token` and `gateway.auth.password` are configured. Set `gateway.auth.mode` to `token` or `password` before upgrade.

---

### 2026.3.2
**Key Features:**
- SecretRef support across 64 credential surfaces
- `pdf` tool with native Anthropic and Google PDF provider support
- `agents.defaults.pdfModel`, `pdfMaxBytesMb`, `pdfMaxPages` configs
- `sessions_spawn` inline file attachments (`tools.sessions_spawn.attachments` config)
- `tools.sessions_spawn.attachments` config with limits
- `channels.telegram.streaming` defaults to `"partial"` (was `"off"`)
- Telegram DM `sendMessageDraft` preview streaming
- `openclaw config validate` command
- `cli.banner.taglineMode` config (`random | default | off`)
- `agents.defaults.compaction.qualityGuard` config (disabled by default)
- `memorySearch.provider = "ollama"` support
- Zalo Personal plugin rebuilt with native `zca-js`

**Breaking Changes in 2026.3.2:**
- **BREAKING:** Onboarding defaults `tools.profile` to `messaging` for new local installs
- **BREAKING:** ACP dispatch now defaults to enabled unless `acp.dispatch.enabled=false`
- **BREAKING:** Plugin SDK removed `api.registerHttpHandler(...)` → use `api.registerHttpRoute(...)`
- **BREAKING:** Zalo Personal plugin no longer requires external `zca`-compatible CLI binaries

---

### 2026.3.1
**Key Features:**
- OpenAI Responses WebSocket-first by default (`transport: "auto"` with SSE fallback)
- Gateway container health probes (`/health`, `/healthz`, `/ready`, `/readyz`)
- Android camera, device permissions, notifications actions node commands
- Discord thread lifecycle controls (`idleHours`, `maxAgeHours`)
- Telegram per-DM `direct` + topic config with rich policy
- `agents.defaults.heartbeat.lightContext` for heartbeat lightweight bootstrap mode
- `--light-context` for cron agent turns
- OpenAI Responses WebSocket warm-up (`response.create` with `generate:false`)
- `params.openaiWsWarmup` for per-model control

**Breaking Changes in 2026.3.1:**
- **BREAKING:** Node exec approval payloads now require `systemRunPlan`
- **BREAKING:** Node `system.run` execution pins path-token commands to canonical `realpath`

---

### 2026.2.27
**Key Features:**
- `openai/gpt-5.4`, `openai/gpt-5.4-pro`, `openai-codex/gpt-5.4` support
- Android app renamed to `ai.openclaw.app`

---

### 2026.2.26
**Key Features:**
- External Secrets Management with full `openclaw secrets` workflow (`audit`, `configure`, `apply`, `reload`)
- ACP thread-bound agents as first-class runtimes
- `openclaw agents bindings`, `openclaw agents bind`, `openclaw agents unbind` commands
- Codex/WebSocket transport as default
- Channel plugins can own interactive onboarding flows
- `session.maintenance.maxDiskBytes` / `highWaterBytes` disk-budget controls
- `tools.web.search.brave.mode` with provider selection
- Perplexity provider switched to Search API with structured results

**Breaking Changes in 2026.2.26:**
- **BREAKING:** `gateway.auth.mode` explicitly required when both token and password configured (precursor to 2026.3.7 requirement)

---

### 2026.2.25
**Key Features:**
- `agents.defaults.heartbeat.directPolicy` (`allow | block`) replaces heartbeat DM toggle
- `agents.list[].heartbeat.directPolicy` per-agent override

**Breaking Changes in 2026.2.25:**
- **BREAKING:** Heartbeat direct/DM delivery default is now `allow`. To keep DM-blocked behavior from 2026.2.24, set `agents.defaults.heartbeat.directPolicy: "block"`

---

### 2026.2.24
**Key Features:**
- Talk mode multi-lingual stop keywords
- `agents.defaults.sandbox.docker.dangerouslyAllowContainerNamespaceJoin` break-glass config
- Security audit `security.trust_model.multi_user_heuristic`

**Breaking Changes in 2026.2.24:**
- **BREAKING:** Heartbeat delivery blocks direct/DM targets by default
- **BREAKING:** Docker `network: "container:<id>"` sandbox namespace-join blocked by default

---

### 2026.2.23
**Key Features:**
- `kilocode` provider (auth, onboarding, default model `kilocode/anthropic/claude-opus-4.6`)
- Vercel AI Gateway Claude shorthand model ref support
- `gateway.http.securityHeaders.strictTransportSecurity` config
- Sessions `openclaw sessions cleanup` with per-agent store targeting and disk-budget controls
- `tools.web.search.provider: "kimi"` (Moonshot) web search
- `agents.defaults.params` per-agent overrides (including `cacheRetention`, `temperature`, `maxTokens`)
- Memory bootstrap file snapshots cached per session key

---

### 2026.2.22
**Key Features:**
- Control UI Tools panel data-driven from runtime `tools.catalog`
- Gemini web search provider support (`gemini` for grounded search)
- Control UI full cron edit parity with run history
- Mistral provider support including memory embeddings and voice
- Auto-updater (`update.auto.*`) config, default off
- `openclaw update --dry-run` command
- Synology Chat native channel plugin
- Memory FTS multilingual stop-word support (Spanish, Portuguese, Japanese, Korean, Arabic)
- Discord allowlist canonicalization to IDs
- `channels.<channel>.streaming` unified config with enum values `off | partial | block | progress`
- `channels.slack.nativeStreaming` for Slack native stream toggle
- Removed legacy Gateway device-auth signature `v1` (must use `v2` with challenge nonce)

**Breaking Changes in 2026.2.22:**
- **BREAKING:** Channel preview-streaming config unified to `channels.<channel>.streaming`; legacy keys (`streamMode`, boolean Slack `streaming`) read and migrated by `openclaw doctor --fix`
- **BREAKING:** Legacy Gateway device-auth signature `v1` removed. Clients must sign `v2` payloads.
- **BREAKING:** CLI local onboarding sets `session.dmScope` to `per-channel-peer` by default for new configs
- **BREAKING:** Tool-failure replies hide raw error details by default; requires `/verbose on` or `/verbose full` for details
- **BREAKING:** Google Antigravity provider support removed; `google-antigravity-auth` plugin removed

---

### 2026.2.21
**Key Features:**
- Gemini 3.1 (`google/gemini-3.1-pro-preview`) support
- `channels.modelByChannel` for per-channel model overrides
- Discord streaming preview mode with partial/block options
- Discord lifecycle status reactions with emoji/timing overrides
- Discord voice channel join/leave via `/vc`
- Discord thread-bound subagent sessions
- `channels.discord.autoArchiveDuration` (inherited from 2026.3.11 listing)
- `agents.defaults.subagents.maxSpawnDepth` shared max spawn depth (default 2)
- `security.ownerDisplaySecret` HMAC secret from configuration

---

### 2026.2.19
**Key Features:**
- Apple Watch companion app (watch inbox, notification relay, gateway command surfaces)
- iOS APNs push registration
- `openclaw devices remove` and `openclaw devices clear` commands
- Mattermost native slash command support
- `channels.mattermost.commands.*` config

---

### 2026.2.17
**Key Features:**
- Anthropic 1M context beta header (`params.context1m: true`) → maps to `anthropic-beta: context-1m-2025-08-07`
- `anthropic/claude-sonnet-4-6` support
- `/subagents spawn` command
- Telegram inline button `style` support (`primary|success|danger`)
- `channels.telegram.reactionNotifications` config
- Discord Components v2 (buttons, selects, modals)
- Cron webhook delivery (`delivery.mode = "webhook"`)
- Cron per-job `schedule.staggerMs` and `openclaw cron add/edit --stagger`
- `tools.web.search.brave.mode: "llm-context"` option
- `browser.extraArgs` for custom Chrome launch arguments
- `talk.silenceTimeoutMs` (predates 2026.3.8 listing; added here)
- `agents.defaults.subagents.maxSpawnDepth` (default 2, actually first added here)
- `agents.defaults.subagents.announceTimeoutMs` config
- `models.[].thinkingDefault` per-model thinking defaults

---

### 2026.2.15
**Key Features:**
- Discord Components v2 rich interactive agent prompts
- `llm_input` and `llm_output` plugin hook payloads exposed
- Nested sub-agents (depth configurable via `agents.defaults.subagents.maxSpawnDepth: 2`)
- `agents.defaults.subagents.maxChildrenPerAgent` config (default 5)
- Memory MMR re-ranking for hybrid search diversity (`memorySearch.query.hybrid.mmr`)
- Memory temporal decay scoring (`memorySearch.query.hybrid.temporalDecay`)
- `cron.webhookToken` dedicated webhook auth token
- `notify` (webhook delivery toggle in cron)

---

### 2026.2.14
**Key Features:**
- Telegram poll sending via `openclaw message poll`
- `slack.dmPolicy` + `slack.allowFrom` aliases (legacy `dm.policy` + `dm.allowFrom` remain)
- `discord.dmPolicy` + `discord.allowFrom` aliases
- `sandbox.browser.binds` for browser-container bind mounts

---

### 2026.2.13
**Key Features:**
- Podman-based setup (`setup-podman.sh`, Quadlet unit)
- Discord voice messages with waveform previews
- Outbound write-ahead delivery queue for crash recovery
- `sessions.parentForkMaxTokens` config (default 100000; 0 disables)
- `Cron/failureAlert.mode` (`announce|webhook`), `failureAlert.accountId`
- `cron.failureDestination` and per-job `delivery.failureDestination`
- Cron repeated-failure alerting configuration
- `channels.discord.eventQueue.listenerTimeout` per-account override

---

### 2026.2.12
**Key Features:**
- `openclaw plugins uninstall <id>` command
- `openclaw logs --local-time` flag
- Discord role-based allowlists and role-based agent routing
- Config `$schema` key accepted (JSON Schema editor tooling)
- Gateway/Hooks: `POST /hooks/agent` now rejects payload `sessionKey` overrides by default

**Breaking Changes in 2026.2.12:**
- **BREAKING:** Hooks `POST /hooks/agent` rejects `sessionKey` overrides by default. To keep fixed hook context, set `hooks.defaultSessionKey` (recommended: `hooks.allowedSessionKeyPrefixes: ["hook:"]`) or set `hooks.allowRequestSessionKey: true`

---

### 2026.2.9
**Key Features:**
- `commands.allowFrom` config for separate command authorization
- ClawDock shell helpers for Docker workflows
- `gateway.channelHealthCheckMinutes` config (default 5; 0 to disable)
- iOS node app with setup-code onboarding
- Grok (xAI) as `web_search` provider
- `gateway.http.endpoints.chatCompletions.enabled` config (default false; must opt-in)
- `agents.files` gateway RPC methods
- `hooks.allowedAgentIds` controls

---

### 2026.2.6
**Key Features:**
- Cron run history deep-links in dashboard
- `cron.wakeMode` default changed to `"now"` (was `"next-heartbeat"`)
- `openclaw/gpt-5.4` and `openai-codex/gpt-5.4` support
- xAI (Grok) provider support
- Baidu Qianfan provider support
- Web UI token usage dashboard
- Memory Voyage AI native support
- `cli.banner.taglineMode` (first appearance; also listed in 2026.3.2)

---

### 2026.2.3
**Key Features:**
- Cron announce delivery mode for isolated jobs
- `tools.sessions_spawn.attachments` limits (first listing)
- `messages.responsePrefix` per-channel and per-account overrides

---

### 2026.2.2
**Key Features:**
- Feishu/Lark plugin
- Web UI Agents dashboard
- QMD backend for workspace memory (`memory.backend: "qmd"` first formal)
- `agents.defaults.subagents.thinking` config (and per-agent `agents.list[].subagents.thinking`)

---

### 2026.2.1
**Key Features:**
- `channels.telegram` unification (renamed from `providers.telegram`)
- Agents `cacheRetention` → renamed from `cacheControlTtl` (back-compat mapping)
- Sessions `session.identityLinks` for cross-platform DM linking (first listed in 2026.1.16-1)
- Gateway requires TLS 1.3 minimum for TLS listeners

---

### 2026.1.31 - 2026.1.24
**Key Features:**
- `completion` command (Zsh/Bash/PowerShell/Fish)
- `channels.telegram.linkPreview` config
- Exec approvals `/approve` in-chat across all channels
- `gateway.auth.token` SecretRef support (first for this specific key)
- `diagnostics.stuckSessionWarnMs` config (default 120000ms)

---

### 2026.1.23 - 2026.1.22
**Key Features:**
- `/tools/invoke` HTTP endpoint
- Heartbeat per-channel visibility controls
- Fly.io deployment support
- `session.resetByChannel` per-channel reset overrides
- `messages.tts.openai.baseUrl` config (first appearance; also listed in 2026.3.7)
- Compaction safeguard adaptive chunking + progressive fallback

---

### 2026.1.21
**Key Features:**
- Lobster optional plugin tool
- `heartbeat.activeHours` support (active-hours windowing)
- `session.dmScope` session DM isolation (per-channel-peer default)
- Exec approvals wildcard agent allowlists (`*`)
- Nodes `openclaw node start` headless node host
- Sessions daily reset policy (`session.resetByChannel`)
- `agents.defaults.model.imageModel` config (also `agents.defaults.imageModel`)
- `session.mainKey` customization

---

### 2026.1.20 (Major feature release)
**Key Features:**
- ACP IDE integration (`openclaw acp`)
- Skills download installs with OS-filtered options
- Memory hybrid BM25 + vector search (FTS5) with weighted merging
- SQLite embedding cache
- OpenAI batch indexing for embeddings
- Gemini native embeddings provider for memory
- Nostr channel plugin
- Matrix E2EE support via matrix-bot-sdk
- Slack HTTP webhook mode
- Zalouser channel dock metadata
- Plugin slots with memory slot selector
- Gateway `/v1/responses` OpenResponses endpoint
- Usage `/usage cost` summaries
- Exec `host/security/ask` routing for gateway + node exec
- `/exec` directive for per-session exec defaults
- Exec approvals migrated to `~/.openclaw/exec-approvals.json`
- Nodes `system.run`/`system.which` via headless node host
- `sessions.parentForkMaxTokens` (first appearance)
- `agents.defaults.sandbox.browser.allowHostControl` config

---

### 2026.1.16-1 (Significant feature release)
**Key Features:**
- Hooks system introduced
- Inbound media understanding (image/audio/video)
- Zalo Personal plugin (`@openclaw/zalouser`)
- Vercel AI Gateway provider
- `session.identityLinks` for cross-platform DM session linking
- `web_search` country/language parameters
- `exec` PTY support
- `process send-keys`, `process submit` PTY helpers
- Skills user-invocable skill commands
- `memorySearch.experimental.sessionMemory` opt-in
- `tools.exec.applyPatch` experimental multi-file edit tool
- `openclaw plugins install` (path/tgz/npm)

**Breaking Changes in 2026.1.16-1:**
- **BREAKING:** `openclaw message` requires `target` (dropping `to`/`channelId`)
- **BREAKING:** Channel auth prefers config over env for Discord/Telegram/Matrix
- **BREAKING:** Drop legacy `chatType: "room"` → use `chatType: "channel"`
- **BREAKING:** `openclaw hooks` is now `openclaw webhooks`; hooks live under `openclaw hooks`
- **BREAKING:** `openclaw plugins install <path>` now copies into `~/.openclaw/extensions` (use `--link` to keep path-based loading)

---

### 2026.1.15
**Key Features:**
- Provider auth registry + `openclaw models auth login`
- `agents.defaults.heartbeat.*` per-agent heartbeat configuration
- 24h duplicate suppression for heartbeat alerts
- `session.dmScope` for multi-user DM isolation
- `channels.<channel>.defaultTo` outbound routing fallback
- Memory `node-llama-cpp` made optional dependency

---

### 2026.1.14
**Key Features:**
- `web_search`/`web_fetch` tools (Brave API)
- Chrome extension relay takeover mode
- Zalo channel plugin
- `openclaw security audit` (expanded)
- Matrix channel plugin (external)
- `channels.<provider>.configWrites` gating config

---

### 2026.1.12 (Major rename release)
**Key Features:**
- **BREAKING RENAME:** chat "providers" → "channels" across CLI/RPC/config
- Memory vector search with SQLite index
- Voice-call plugin (full parity)
- Models: Synthetic provider, Moonshot Kimi K2
- One-shot cron schedules with ISO timestamps
- `agents.defaults.compaction.*` config (safeguard summarization, model fallbacks)
- Memory `openclaw memory` CLI
- `memory_search`/`memory_get` tools
- Tool profiles + group shorthands
- `tools.byProvider` tool policy overrides

**Breaking Changes in 2026.1.12:**
- **BREAKING:** Rename chat "providers" to "channels" (legacy config auto-migrates)
- **BREAKING:** Reject invalid/unknown config entries; run `openclaw doctor --fix` to repair

---

### 2026.1.11
**Key Features:**
- Plugins first-class (loader + CLI management)
- `$include` modular config support
- Pre-compaction memory flush turn
- `tools.exec.applyPatch` (multi-file edits, experimental)
- Plugins `openclaw plugins install`

---

### 2026.1.10
**Key Features:**
- `openclaw status` table-based with OS/update/gateway/daemon/agents/sessions
- `openclaw update` command
- OpenAI-compatible `/v1/chat/completions` endpoint (disabled by default)
- `gateway.http.endpoints.chatCompletions.enabled` config
- Z.AI (GLM) auth choice
- OpenRouter API key auth option

---

### 2026.1.9 (Major features)
**Key Features:**
- Microsoft Teams provider (now a plugin in later versions)
- OpenCode Zen + MiniMax API onboarding
- Token auth profiles + auth order
- `commands.config`/`commands.debug` config (disabled by default)
- `commands.restart` config (disabled by default)
- `gateway.http.endpoints.chatCompletions.enabled` (disabled by default)
- `agents.defaults.heartbeat.includeReasoning` config

**Breaking Changes in 2026.1.9:**
- **BREAKING:** Microsoft Teams is now a plugin; install `@openclaw/msteams`
- **BREAKING:** `openclaw message` now subcommands; requires `--provider` unless only one configured
- **BREAKING:** `/restart` and gateway restart tool disabled by default; enable with `commands.restart=true`

---

### 2026.1.8
**Key Features:**
- DMs locked down by default (pairing-first + allowlist guidance)
- Per-agent sandbox scope defaults
- `session.dmScope` for multi-user DM isolation (first in 2026.1.8)
- `dmPolicy: "pairing"` as new default (was open)

**Breaking Changes in 2026.1.8:**
- **BREAKING SECURITY:** Inbound DMs locked down by default (`dmPolicy="pairing"`)
- **BREAKING:** Sandbox `agent.sandbox.scope` defaults to `"agent"`
- **BREAKING:** Timestamps in agent envelopes now UTC; removed `messages.timestampPrefix`

---

### 2026.1.5
**Key Features:**
- `agents.defaults.imageModel` config (image-specific model)
- `image` tool routed to image model
- Model shorthands (`opus`, `sonnet`, `gpt`, `gpt-mini`, `gemini`, `gemini-flash`)
- `gateway.http.endpoints.chatCompletions.enabled` (first mention)

---

## Config Keys by Version (CRITICAL)

This is the authoritative reference. Do NOT use a key in a version where it wasn't introduced.

### Introduced in Unreleased (after 2026.3.13 - NOT safe in our version)
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `talk.silenceTimeoutMs` | Configurable silence before auto-send in Talk mode | number (ms) |
| `healthMonitor.enabled` | Per-channel/account health monitor override | boolean |
| `channels.telegram.silentErrorReplies` | Silent error replies (default off) | boolean |
| `browser.profiles.<name>.userDataDir` | Attach to existing Chromium user data dir | string path |
| `agents.defaults.imageGenerationModel.primary` | Primary image generation model | e.g. `"google/gemini-3-pro-image-preview"` |
| `plugins.entries.<id>.hooks.allowPromptInjection` | Allow prompt injection from plugin hooks | boolean |

### Introduced in 2026.3.13 (our current version — SAFE)
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `agents.defaults.compaction.postIndexSync` | Mode-aware post-compaction session reindexing | string |
| `agents.defaults.memorySearch.sync.sessions.postCompactionForce` | Force immediate memory refresh after compaction | boolean |
| `cron.sessionTarget` | Bind cron job to creating session or named session | `"current"`, `"session:<id>"`, `"main"`, `"isolated"` |

### Introduced in 2026.3.12
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `params.fastMode` | Per-session fast mode toggle | boolean |
| `channels.slack.capabilities.interactiveReplies` | Opt-in Slack button/select reply directives | boolean (default false) |

### Introduced in 2026.3.11
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `channels.discord.autoArchiveDuration` | Auto-archive duration for Discord threads | `60`, `1440`, `4320`, `10080` (minutes) |
| `memorySearch.extraPaths` | Extra paths for multimodal image/audio indexing | array of paths |

### Introduced in 2026.3.8
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `talk.silenceTimeoutMs` | Configurable silence threshold in Talk mode | number (ms); unset = platform default |
| `tools.web.search.brave.mode` | Brave search mode for LLM Context endpoint | `"default"`, `"llm-context"` |

### Introduced in 2026.3.7
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `gateway.auth.mode` | **REQUIRED** when both token+password configured | `"token"`, `"password"`, `"none"`, `"trusted-proxy"` |
| `gateway.auth.token` (SecretRef support) | Auth token with SecretRef support | SecretRef or string |
| `messages.tts.openai.baseUrl` | Custom base URL for OpenAI TTS | string URL |
| `channels.slack.typingReaction` | Reaction-based processing indicator for Socket Mode DMs | emoji string |
| `channels.discord.allowBots` | Bot message allowlisting | `"all"`, `"mentions"`, `false` |
| `agents.defaults.compaction.postCompactionSections` | AGENTS.md sections re-injected after compaction | array of section names |
| `agents.defaults.compaction.model` | Model for compaction summarization | provider/model string |
| `plugins.entries.<id>.hooks.allowPromptInjection` | Allow plugin prompt injection | boolean |
| `agents.defaults.compaction.recentTurnsPreserve` | Turns preserved verbatim during compaction | number |

### Introduced in 2026.3.2
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `agents.defaults.pdfModel` | Default model for PDF tool | provider/model string |
| `agents.defaults.pdfMaxBytesMb` | Max PDF size in MB | number |
| `agents.defaults.pdfMaxPages` | Max PDF pages | number |
| `tools.sessions_spawn.attachments` | Inline file attachment limits for sessions_spawn | object with size/count limits |
| `channels.telegram.streaming` | Telegram streaming mode (default changed to `"partial"`) | `"off"`, `"partial"`, `"block"`, `"progress"` |
| `channels.telegram.disableAudioPreflight` | Skip mention-detection preflight for voice notes | boolean (per group/topic config) |
| `cli.banner.taglineMode` | Control tagline in startup output | `"random"`, `"default"`, `"off"` |
| `agents.defaults.compaction.qualityGuard` | Enable compaction quality audits | boolean (default false) |
| `memorySearch.provider` | Memory search provider | `"openai"`, `"ollama"`, `"local"`, etc. |
| `memorySearch.fallback` | Fallback memory search provider | provider string |

### Introduced in 2026.3.1
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `agents.defaults.heartbeat.lightContext` | Lightweight bootstrap mode for heartbeat runs | boolean |
| `params.openaiWsWarmup` | OpenAI Responses WebSocket warm-up per model | boolean |

### Introduced in 2026.2.26
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `session.maintenance.maxDiskBytes` | Max disk budget for session maintenance | number (bytes) |
| `session.maintenance.highWaterBytes` | High-water mark for session maintenance | number (bytes) |

### Introduced in 2026.2.25
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `agents.defaults.heartbeat.directPolicy` | Heartbeat DM delivery control | `"allow"`, `"block"` |
| `agents.list[n].heartbeat.directPolicy` | Per-agent heartbeat DM delivery control | `"allow"`, `"block"` |

### Introduced in 2026.2.23
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `gateway.http.securityHeaders.strictTransportSecurity` | HSTS header for HTTPS deployments | string (e.g. `"max-age=31536000"`) |
| `agents.defaults.params` | Per-agent params overrides (cacheRetention, temperature, maxTokens) | object |
| `agents.list[n].params` | Per-agent params (cacheRetention, temperature, maxTokens) | `{ cacheRetention: "1h", temperature: 0.7 }` |

### Introduced in 2026.2.22
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `update.auto.*` | Auto-updater config | object (disabled by default) |
| `channels.<channel>.streaming` | Unified streaming mode | `"off"`, `"partial"`, `"block"`, `"progress"` |
| `channels.slack.nativeStreaming` | Slack native stream toggle | boolean |

### Introduced in 2026.2.21
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `channels.modelByChannel` | Per-channel model overrides | `{ "telegram": "anthropic/claude-haiku-4-5" }` |
| `agents.defaults.subagents.maxSpawnDepth` | Max nested sub-agent depth | number (shared; default 2) |

### Introduced in 2026.2.19
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `channels.mattermost.commands.*` | Mattermost native slash command config | object |

### Introduced in 2026.2.17
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `params.context1m` | Anthropic 1M context beta for Opus/Sonnet | boolean (maps to `anthropic-beta: context-1m-2025-08-07`) |
| `models.[n].thinkingDefault` | Per-model thinking level default | `"off"`, `"low"`, `"high"`, `"xhigh"` |
| `agents.defaults.subagents.announceTimeoutMs` | Configurable announce call timeout | number (ms); default 60000 |
| `messages.suppressToolErrors` | Hide non-mutating tool-failure warnings | boolean |

### Introduced in 2026.2.15
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `memorySearch.query.hybrid.mmr` | MMR re-ranking for hybrid search diversity | boolean or config object |
| `memorySearch.query.hybrid.temporalDecay` | Temporal decay for hybrid search scoring | config object with half-life |
| `agents.defaults.subagents.maxChildrenPerAgent` | Max child sub-agents per parent | number (default 5) |
| `cron.webhookToken` | Dedicated webhook auth token for cron | string |

### Introduced in 2026.2.14
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `sandbox.browser.binds` | Browser-container bind mounts (separate from exec) | array of bind specs |

### Introduced in 2026.2.13
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `sessions.parentForkMaxTokens` | Max tokens for parent session fork inheritance | number (default 100000; 0 = disable) |
| `delivery.failureDestination` | Per-job failure delivery destination | routing object |
| `cron.failureDestination` | Global cron failure delivery destination | routing object |

### Introduced in 2026.2.12
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `hooks.defaultSessionKey` | Default session key for incoming hooks | string (e.g. `"hook:main"`) |
| `hooks.allowedSessionKeyPrefixes` | Allowed session key prefixes in hooks | array of strings |
| `hooks.allowRequestSessionKey` | Allow caller to override session key | boolean (default false) |

### Introduced in 2026.2.9
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `gateway.channelHealthCheckMinutes` | Periodic channel health check interval | number (default 5; 0 = disable) |
| `hooks.allowedAgentIds` | Restrict webhook agent routing | array of agent IDs |
| `gateway.http.endpoints.chatCompletions.enabled` | Enable OpenAI-compatible `/v1/chat/completions` endpoint | boolean (default false) |

### Introduced in 2026.2.6
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `memory.qmd.update.onBoot` | QMD update on gateway boot | boolean |
| `memory.qmd.searchMode` | QMD search mode | `"query"`, `"search"`, `"vsearch"` (default `"search"`) |

### Introduced in 2026.2.3
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `messages.responsePrefix` | Per-channel/account response prefix | string or object |

### Introduced in 2026.2.2
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `agents.defaults.subagents.thinking` | Default thinking level for sub-agents | `"off"`, `"low"`, `"high"`, `"xhigh"` |
| `agents.list[n].subagents.thinking` | Per-agent sub-agent thinking level | same as above |

### Introduced in 2026.2.1
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `cacheRetention` | Anthropic prompt cache TTL | `"5m"`, `"1h"`, etc. (renamed from `cacheControlTtl`) |

### Introduced in 2026.1.31 - 2026.1.24
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `channels.telegram.linkPreview` | Toggle outbound link previews | boolean |
| `diagnostics.stuckSessionWarnMs` | Stuck-session warning threshold | number (default 120000) |

### Introduced in 2026.1.23 - 2026.1.22
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `session.resetByChannel` | Per-channel reset policy overrides | object |

### Introduced in 2026.1.21
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `heartbeat.activeHours` | Active hours window for heartbeat | `{ start: "09:00", end: "22:00" }` |
| `session.mainKey` | Custom main session key | string |
| `session.dmScope` | DM session isolation mode | `"main"`, `"per-channel-peer"`, etc. |
| `agents.defaults.imageModel` | Default model for image analysis | provider/model string |

### Introduced in 2026.1.20
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `memorySearch.provider` | Memory embedding provider | `"openai"`, `"local"`, `"gemini"`, `"voyage"`, `"ollama"`, `"mistral"` |
| `memorySearch.fallback` | Fallback memory search provider | provider string |
| `memorySearch.experimental.sessionMemory` | Opt-in session transcript indexing | boolean |
| `memorySearch.sources` | Memory sources to index | array |
| `tools.byProvider` | Tool policy overrides by provider/model | object |
| `agents.defaults.sandbox.browser.allowHostControl` | Allow browser tool to control host browser | boolean |
| `exec.host` | Execution host routing | `"gateway"`, `"node"`, `"sandbox"` |
| `exec.security` | Exec security mode | `"allowlist"`, `"sandbox"`, `"deny"` |
| `exec.ask` | Exec approval ask mode | `"on-miss"`, `"always"`, `"off"` |
| `agents.list[n].sandbox.docker.setupCommand` | Sandbox Docker setup command | string or array of strings |

### Introduced in 2026.1.16-1
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `hooks.*` | Hooks system config | see hooks docs |
| `tools.exec.applyPatch` | Enable apply_patch tool | boolean (gated, experimental) |
| `session.identityLinks` | Cross-platform DM session linking | object |
| `web_search.country` | Country code for search results | 2-letter country code |
| `web_search.language` | Language for search results | language code |

### Introduced in 2026.1.15
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `agents.defaults.heartbeat.*` | Per-agent heartbeat configuration | object |
| `agents.list[n].heartbeat.*` | Per-agent heartbeat config | object |

### Introduced in 2026.1.12
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `channels.*` | Renamed from `providers.*` | replaces all providers.* keys |
| `tools.profile` | Tool profile shorthand | `"messaging"`, `"coding"`, `"minimal"`, etc. |
| `agents.defaults.compaction.*` | Compaction config | safeguard, model, sections, etc. |
| `memory.*` | Memory/embeddings config | see memory docs |

### Introduced in 2026.1.9 - 2026.1.8
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `commands.config` | Enable `/config` command | boolean (default false) |
| `commands.debug` | Enable `/debug` command | boolean (default false) |
| `commands.restart` | Enable `/restart` command | boolean (default false) |
| `dmPolicy` | DM access policy | `"open"`, `"pairing"`, `"allowlist"` |
| `agents.defaults.sandbox.scope` | Sandbox scope default | `"agent"`, `"session"`, `"shared"` |
| `agents.defaults.heartbeat.includeReasoning` | Deliver reasoning in heartbeat | boolean |
| `gateway.http.endpoints.chatCompletions.enabled` | Enable chat completions HTTP endpoint | boolean (default false) |

### Introduced in 2026.1.5
| Config Key | What It Does | Valid Values / Example |
|---|---|---|
| `agents.defaults.imageModel` | Image-specific model config | `{ primary: "provider/model", fallbacks: [] }` |
| Model shorthands in config | `opus`, `sonnet`, `gpt`, `gpt-mini`, `gemini`, `gemini-flash` | string aliases |

---

## Breaking Changes & Deprecations (Full List)

### 2026.3.13
- **Memory bootstrap**: Only one root bootstrap file loaded. `MEMORY.md` wins; `memory.md` is fallback only. Merge both files before upgrade if you used both.

### 2026.3.12
- Implicit workspace plugin auto-load disabled (security fix `GHSA-99qw-6mr3-36qr`)
- Device pairing setup codes changed to short-lived bootstrap tokens

### 2026.3.11
- Cron isolated delivery tightened: cron jobs can no longer notify through ad hoc agent sends or fallback main-session summaries. Use `openclaw doctor --fix` to migrate legacy cron storage.

### 2026.3.7
- **BREAKING:** `gateway.auth.mode` required when both `token` and `password` configured. Set to `"token"` or `"password"` before upgrade.

### 2026.3.2
- **BREAKING:** Onboarding defaults `tools.profile` to `"messaging"` for new local installs
- **BREAKING:** ACP dispatch defaults to enabled; use `acp.dispatch.enabled=false` to disable
- **BREAKING:** Plugin SDK removed `api.registerHttpHandler(...)` → use `api.registerHttpRoute(...)`
- **BREAKING:** Zalo Personal plugin no longer requires external CLI binaries; use `openclaw channels login --channel zalouser` to refresh sessions

### 2026.3.1
- **BREAKING:** Node exec approval payloads require `systemRunPlan`
- **BREAKING:** Node `system.run` pins path-token commands to canonical `realpath` in both allowlist and approval execution

### 2026.2.25
- **BREAKING:** Heartbeat `directPolicy` default changed to `"allow"`. To keep DM-blocked behavior from 2026.2.24, set `agents.defaults.heartbeat.directPolicy: "block"`

### 2026.2.24
- **BREAKING:** Heartbeat delivery blocks direct/DM targets by default (reverted in 2026.2.25)
- **BREAKING:** Docker `network: "container:<id>"` sandbox namespace-join blocked by default; set `agents.defaults.sandbox.docker.dangerouslyAllowContainerNamespaceJoin: true` to keep

### 2026.2.22
- **BREAKING:** Channel preview-streaming config unified to `channels.<channel>.streaming` enum; `streamMode` and boolean Slack `streaming` still read but migrate with `openclaw doctor --fix`
- **BREAKING:** Legacy Gateway device-auth signature `v1` removed; clients must use `v2` with `connect.challenge` nonce
- **BREAKING:** CLI local onboarding sets `session.dmScope: "per-channel-peer"` by default
- **BREAKING:** Tool-failure replies hide raw error details by default; need `/verbose on` or `/verbose full`
- **BREAKING:** Google Antigravity provider removed; `google-antigravity-auth` plugin removed; migrate to `google-gemini-cli` or other providers

### 2026.2.12
- **BREAKING:** `POST /hooks/agent` rejects payload `sessionKey` overrides by default. Set `hooks.defaultSessionKey` or `hooks.allowRequestSessionKey: true` to restore

### 2026.1.16-1
- **BREAKING:** `openclaw message` requires `target` (dropping `to`/`channelId`)
- **BREAKING:** Channel auth prefers config over env for Discord/Telegram/Matrix
- **BREAKING:** `chatType: "room"` dropped → use `chatType: "channel"`
- **BREAKING:** `openclaw hooks` → `openclaw webhooks`; hooks = `openclaw hooks`
- **BREAKING:** `openclaw plugins install <path>` copies to `~/.openclaw/extensions`; use `--link` for path-based loading

### 2026.1.12
- **BREAKING:** Chat "providers" renamed to "channels" (config auto-migrates via `openclaw doctor`)
- **BREAKING:** Invalid/unknown config entries cause gateway startup failure

### 2026.1.9
- **BREAKING:** Microsoft Teams is now a plugin; install `@openclaw/msteams`
- **BREAKING:** `openclaw message` now subcommands; requires `--provider` unless single provider
- **BREAKING:** `/restart` and gateway restart tool disabled by default; enable with `commands.restart=true`
- **BREAKING:** iOS minimum version is 18.0

### 2026.1.8
- **BREAKING SECURITY:** DMs locked down by default (`dmPolicy="pairing"`) for Telegram/WhatsApp/Signal/iMessage/Discord/Slack
- **BREAKING:** Sandbox `agent.sandbox.scope` defaults to `"agent"`
- **BREAKING:** Timestamps in agent envelopes now UTC; `messages.timestampPrefix` removed
- **BREAKING:** `autoReply` removed from Discord/Slack/Telegram; use `requireMention`
- **BREAKING:** `whatsapp.groups`, `telegram.groups`, `imessage.groups` act as allowlists when set

### 2026.1.29
- **BREAKING:** Gateway auth mode `"none"` removed; requires token/password (Tailscale Serve identity allowed)

---

## Upgrade Path: 2026.3.13 → 2026.3.14

Our specific upgrade from current stable to next stable.

### New Config Keys Available After Upgrade
| Key | Action Required? |
|---|---|
| `talk.silenceTimeoutMs` | Optional — configure if you use Talk mode |
| `healthMonitor.enabled` per-channel/per-account | Optional override |
| `channels.telegram.silentErrorReplies` | Optional (default off, no action needed) |
| `browser.profiles.<name>.userDataDir` | Optional — for existing-session Chrome attach |
| `agents.defaults.imageGenerationModel.primary` | Required IF you used `nano-banana-pro` skill |
| `plugins.entries.<id>.hooks.allowPromptInjection` | Optional — for plugin hook prompt injection |

### Breaking Changes to Watch For
1. **`nano-banana-pro` skill removed** → If used, replace with `agents.defaults.imageGenerationModel.primary: "google/gemini-3-pro-image-preview"` in config
2. **Chrome extension relay path removed** → Run `openclaw doctor --fix` to migrate `driver: "extension"` browser configs to `existing-session` or `user`
3. **`openclaw/extension-api` public surface removed** → If you have custom plugins using this import, they need updating to `openclaw/plugin-sdk/*` subpaths
4. **`ChannelMessageActionAdapter` API changes** → `listActions`, `getCapabilities`, `getToolSchema` removed; use `describeMessageTool(...)`
5. **Build-tool JVM env vars blocked** → `MAVEN_OPTS`, `SBT_OPTS`, `GRADLE_OPTS`, `ANT_OPTS`, `GLIBC_TUNABLES`, `DOTNET_ADDITIONAL_DEPS` no longer passed to exec commands

### New Features We Can Use After Upgrade
- `sessions_yield` for orchestrators (skip queued work, hidden follow-up into next turn)
- Dashboard v2 with modular views, command palette, mobile bottom tabs
- OpenAI fast mode (`/fast`, `params.fastMode`)
- Anthropic fast mode (maps to `service_tier`)
- Ollama, vLLM, SGLang as provider plugins
- Kubernetes deployment starter
- `browser.profiles.<name>.userDataDir` for attaching to existing Chromium
- Telegram `--force-document` for image sends
- `cron.sessionTarget: "current"` or `"session:<id>"`

### Migration Steps
1. **Before upgrade**: Back up config with `openclaw backup create`
2. **Check `nano-banana-pro`**: If you use it, set `agents.defaults.imageGenerationModel.primary` in config
3. **Check browser config**: If `driver: "extension"` anywhere, run `openclaw doctor --fix` after upgrade
4. **Check custom plugins**: If any use `openclaw/extension-api`, they need to be updated
5. **Run after upgrade**: `openclaw doctor --fix && openclaw plugins update`

---

## Feature Timeline

### Multi-agent / Subagents
- **2026.1.5**: Initial subagent support
- **2026.1.9**: Sub-agent context trimmed; spawn depth controls
- **2026.1.12**: `sessions_spawn` with thinking level override
- **2026.1.20**: `sessions_spawn` nested workspaces, workspace inheritance
- **2026.2.2**: `agents.defaults.subagents.thinking` config
- **2026.2.15**: Nested sub-agents with `maxSpawnDepth: 2`; `maxChildrenPerAgent` default 5
- **2026.2.21**: `agents.defaults.subagents.maxSpawnDepth` shared (default 2)
- **2026.3.1**: ACP thread-bound agents as first-class runtimes
- **2026.3.12**: `sessions_yield` for orchestrators to end turn immediately
- **2026.3.14/Unreleased**: Feishu/ACP conversation binding; `streamTo: "parent"` for ACP spawns

### Cron System
- **2026.1.9**: Basic cron with jobs, scheduling
- **2026.1.12**: One-shot schedules with ISO timestamps; per-agent cron targeting
- **2026.1.20**: Daily reset policy; cron run-log access
- **2026.2.2**: Announce delivery mode for isolated jobs
- **2026.2.3**: Hard migration to announce/none delivery; legacy field removal
- **2026.2.9**: `gateway.channelHealthCheckMinutes` (indirectly related)
- **2026.2.13**: Write-ahead delivery queue; failure alerting
- **2026.2.17**: Cron webhook delivery `delivery.mode: "webhook"`; `cron.webhookToken`
- **2026.2.26**: Full cron failure alert config with per-job overrides
- **2026.3.2**: `cron.sessionTarget` with more options
- **2026.3.13**: `cron.sessionTarget: "current"` and `session:<id>`

### Memory / Compaction
- **2026.1.5**: Initial memory support
- **2026.1.12**: Memory vector search with SQLite; `openclaw memory` CLI; `memory_search`/`memory_get` tools
- **2026.1.15**: Pre-compaction memory flush
- **2026.1.20**: Hybrid BM25 + vector search; SQLite embedding cache; OpenAI batch indexing; Gemini embeddings
- **2026.2.2**: QMD backend (`memory.backend: "qmd"`)
- **2026.2.6**: `memory.qmd.searchMode` config
- **2026.2.15**: MMR re-ranking; temporal decay scoring
- **2026.2.22**: FTS multilingual stop-words (Spanish, Portuguese, Japanese, Korean, Arabic)
- **2026.2.23**: `agents.defaults.params.cacheRetention` for per-agent cache tuning
- **2026.3.7**: `agents.defaults.compaction.model` for compaction with different model
- **2026.3.13**: `agents.defaults.compaction.postIndexSync` for post-compaction reindexing

### Skills System
- **2026.1.5**: Initial skills
- **2026.1.16-1**: Skills user-invocable skill commands; download installs
- **2026.1.21**: Exec approvals for skill auto-allow
- **2026.2.22**: Skills removed from bundled (food-order, etc.)
- **2026.3.2**: `agents.defaults.compaction.qualityGuard` for quality-checking compaction summaries
- **Unreleased**: `maxSkillsPromptChars` catalog fallback; `nano-banana-pro` removed

### Heartbeat activeHours
- **2026.1.21**: `heartbeat.activeHours` introduced (`{ start: "HH:MM", end: "HH:MM" }`)
- **2026.1.15**: Per-agent heartbeat configuration (`agents.defaults.heartbeat.*`)
- **2026.2.22**: `agents.defaults.heartbeat.directPolicy` replaces DM toggle
- **2026.2.25**: `directPolicy` default changed to `"allow"` (DMs allowed again)

### thinkingDefault (per-model)
- **2026.2.17**: `models.[n].thinkingDefault` per-model thinking defaults introduced
- **2026.3.1**: `agents.defaults` Anthropic Claude 4.6 models default to `adaptive`

### Context Pruning / Session Pruning
- **2026.1.8**: Per-agent sandbox scope defaults; session tool visibility
- **2026.1.20**: Daily reset policy; sessions maintenance
- **2026.2.9**: Sessions prune stale entries; cap session store size
- **2026.2.13**: `session.maintenance.maxDiskBytes` / `highWaterBytes`
- **2026.2.26**: External Secrets full workflow; sessions storage hardening
- **2026.3.8**: Context pruning for image-only tool results

### Hooks System
- **2026.1.16-1**: Hooks system introduced with bundled hooks, CLI tooling
- **2026.2.2**: Hook lifecycle fixes; wire 9 previously unwired hooks
- **2026.2.12**: `hooks.defaultSessionKey`, `hooks.allowedSessionKeyPrefixes`, `hooks.allowRequestSessionKey`; `POST /hooks/agent` rejects sessionKey overrides by default
- **2026.2.13**: Hooks session-memory improvements
- **2026.3.7**: Compaction lifecycle hooks (`session:compact:before`, `session:compact:after`)

### ACP Protocol
- **2026.1.20**: ACP IDE integration (`openclaw acp`)
- **2026.2.26**: ACP thread-bound agents as first-class runtimes; persistent channel bindings
- **2026.3.1**: `sessions_spawn` with `resumeSessionId` for ACP
- **2026.3.8**: ACP provenance metadata (`--provenance off|meta|meta+receipt`)
- **2026.3.11**: `channels.discord.autoArchiveDuration`; Discord/Telegram ACP topic bindings
- **2026.3.12**: Enhanced ACP event handling; `sessions_yield`

### Canvas / A2UI
- **2026.1.9**: Canvas host, canvas operations
- **2026.1.20**: Gateway canvas capability for control UI
- **2026.2.19**: iOS APNs integration; node canvas capability refresh
- **Unreleased**: Canvas expand-to-canvas button; session navigation from Canvas views

---

## Known Bugs Fixed Per Version

### 2026.3.13 (Our Current Version)
- Dashboard: full chat history reload on every live tool result (caused UI freeze/re-render storms)
- Gateway: unanswered gateway RPC calls leak hanging promises indefinitely
- Ollama: native `thinking` and `reasoning` fields promoted into final assistant text (leaked internal thoughts)
- Browser/existing-session: transport errors should trigger reconnects while tool-level errors preserve session
- Control UI: shared token auth dropped before first WebSocket handshake on HTTP Control UI
- Gateway/session reset: `lastAccountId` and `lastThreadId` not preserved across resets
- macOS/exec approvals: gateway-triggered `system.run` not following configured policy
- Telegram: media downloads failed when falling back between proxy and direct networking
- Windows: gateway status showing `Runtime: unknown` for scheduled task installs
- ACP: gateway startup using plugin runtime instead of direct helpers for Telegram/Discord probes
- Cron/isolated sessions: isolated cron jobs deadlocking when compaction or queued inner work runs
- Config validation: `agents.list[].params` (cacheRetention, temperature, maxTokens) incorrectly rejected
- Config validation: `tools.web.fetch.readability` and `tools.web.fetch.firecrawl` failing validation
- Config validation: `channels.signal.groups` schema support missing
- Config validation: `discovery.wideArea.domain` unrecognized
- Telegram: media error logging bot tokens into logs (token leakage)
- Memory/session sync: metadata-only auto-compactions undercounting multi-compaction runs

### 2026.3.12
- Models/Kimi Coding: tool calls degrading to XML/plain-text instead of real tool_use blocks
- TUI: duplicate assistant replies in `openclaw tui`
- Telegram/model picker: inline model button selections not persisting correctly
- Cron/proactive delivery: transient-send retries replaying duplicate messages after restart
- Multiple security fixes (GHSA-level)

### 2026.3.11
- Telegram/inbound media: IPv4 fallback for SSRF-guarded file downloads
- Gateway/Telegram stale-socket restart guard: Telegram providers misclassified as stale due to long uptime
- Onboarding/headless Linux daemon probe: crash on SSH/headless VPS environments
- Memory/QMD mcporter Windows spawn: retry via bare `mcporter` shell resolution on `spawn EINVAL`
- Feishu/streaming recovery: stale `streamingStartPromise` after HTTP 400 card creation failure
- macOS/remote gateway: PortGuardian killing Docker Desktop on gateway port in remote mode
- ACP/Discord startup: stuck ACP worker children on gateway restart

### 2026.3.8
- Telegram/DM routing: same DM triggering duplicate replies
- Cron/Telegram announce delivery: plain Telegram targets reporting `delivered: true` with no actual delivery
- Matrix/DM routing: safer fallback for broken `m.direct` homeservers
- Config/runtime snapshots: follow-up reads not seeing file-backed secret values after config writes
- Browser/CDP: normalize loopback direct WebSocket CDP URLs back to HTTP(S)
- Telegram/media downloads: time out only stalled body reads (not slow downloads)
- Gateway/restart timeout recovery: non-zero exit on restart timeout so launchd/systemd restart properly
- Docker/token persistence: token not reused on `docker-setup.sh` reruns

### 2026.3.7
- Memory/Hybrid search: BM25 relevance ordering reversed (stronger matches ranked lower)
- Gateway/Telegram stale-socket: non-event-liveness channels misclassified as stale
- Memory/QMD: Windows `mcporter.cmd` failing with `spawn EINVAL`
- Models/openai-completions: usage-only stream chunks causing parser crashes
- Gateway/chat streaming: pre-tool text lost in live chat deltas
- Discord/reconnect: HELLO stall causing gateway zombie processes
- Many security fixes (15+ GHSA advisories)

### 2026.3.2
- Feishu/Outbound: renderMode not respected in outbound sends
- Gateway/Subagent TLS pairing: `sessions_spawn` failing with `gateway.tls.enabled=true` in Docker/LAN
- Slack/socket auth failure: retry-looping indefinitely instead of failing fast
- Gateway/macOS LaunchAgent: npm upgrades losing owner-only file permissions
- Many security fixes (20+ GHSA advisories)

### 2026.3.1
- Feishu/Streaming: partial updates dropping content
- Feishu/Sessions announce: group targets normalizing `group:`/`channel:` incorrectly
- Web UI/Cron: configured agent model defaults not in cron model suggestions
- Cron/Delivery: `delivery.mode: "none"` not actually disabling delivery

### 2026.2.17
- Telegram: DM streaming transport inconsistencies
- Gateway/Auth: device-auth tokens not cleared after `device token mismatch`
- macOS: `openclaw update` not offered due to wrong appcast version
- Voice-call: auto-end calls when media streams disconnect
- iOS/Chat: ChatSheet routing causing cross-client session collisions
- Gateway: `config.patch` object arrays replacing whole arrays instead of merging by `id`

### 2026.2.14
- CLI/Installation: Docker installation hanging on macOS
- Sessions: invalid persisted `sessionFile` metadata aborting session resolution
- Webchat/silent token leak: `NO_REPLY` tokens appearing in chat history

### 2026.2.13
- Cron: one-shot `at` jobs re-firing on restart after skip/error
- Sessions: cap session store size; prune stale entries
- Outbound: write-ahead delivery queue for crash recovery (lost messages on restart)

### 2026.2.9
- Cron: one-shot `at` jobs re-firing on restart
- Gateway: post-compaction amnesia fixed (injected transcript writes preserve Pi session chain)
- Model failover: HTTP 400 errors now failover-eligible

### Docker/Telegram specific fixes (relevant to our setup)
- **2026.3.13**: Telegram IPv4 sticky fallback preserved across polling restarts
- **2026.3.13**: Docker/timezone override via `OPENCLAW_TZ` env var
- **2026.3.12**: Gateway plugins startup: bundled channel plugins no longer recompile TypeScript on every startup
- **2026.3.11**: Telegram/poll restarts: unrelated network errors no longer bouncing Telegram polling
- **2026.3.8**: Docker/token persistence on reconfigure: token reused in `docker-setup.sh` reruns
- **2026.3.7**: `docker-setup.sh` now macOS Bash 3.2 compatible
- **2026.3.2**: Docker/sandbox bootstrap hardening: `OPENCLAW_SANDBOX` explicit parsing
- **2026.2.22**: Docker/Image permissions normalized to prevent plugin discovery blocks
- **2026.2.17**: Docker/Browser: Chromium installed to correct path for runtime user
- **2026.1.12**: Docker: container port for gateway command instead of host port

---

## Quick Reference: Config Keys Safe in Our Version (2026.3.13)

All keys listed under "Introduced in 2026.3.13" and earlier are safe. Key highlights:

```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "directPolicy": "allow",
        "lightContext": false,
        "activeHours": { "start": "08:00", "end": "22:00" }
      },
      "subagents": {
        "thinking": "low",
        "maxSpawnDepth": 2,
        "maxChildrenPerAgent": 5,
        "announceTimeoutMs": 60000
      },
      "compaction": {
        "model": "anthropic/claude-haiku-4-5",
        "postCompactionSections": ["Session Startup", "Red Lines"],
        "recentTurnsPreserve": 5,
        "qualityGuard": false,
        "postIndexSync": "async"
      },
      "memorySearch": {
        "sync": {
          "sessions": {
            "postCompactionForce": false
          }
        }
      },
      "params": {
        "cacheRetention": "1h",
        "temperature": 0.7
      },
      "imageModel": "google/gemini-3-flash-preview",
      "pdfModel": "anthropic/claude-sonnet-4-6",
      "pdfMaxBytesMb": 10,
      "pdfMaxPages": 50
    }
  },
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "your-token"
    },
    "channelHealthCheckMinutes": 5,
    "http": {
      "endpoints": {
        "chatCompletions": { "enabled": false }
      }
    }
  },
  "channels": {
    "telegram": {
      "streaming": "partial",
      "linkPreview": true,
      "reactionNotifications": "own"
    }
  },
  "cron": {
    "sessionTarget": "current"
  },
  "session": {
    "dmScope": "per-channel-peer",
    "mainKey": "agent:main:main"
  },
  "hooks": {
    "defaultSessionKey": "hook:main",
    "allowedSessionKeyPrefixes": ["hook:"],
    "allowRequestSessionKey": false
  },
  "tools": {
    "web": {
      "search": {
        "brave": {
          "mode": "default"
        }
      }
    }
  }
}
```

## Keys NOT Safe in 2026.3.13 (introduced later)

The following keys will cause Zod validation failures and crash the gateway if added:
- `talk.silenceTimeoutMs` (Unreleased)
- `healthMonitor.enabled` per-channel (Unreleased)
- `channels.telegram.silentErrorReplies` (Unreleased)
- `browser.profiles.<name>.userDataDir` (Unreleased, though browser profiles exist)
- Any `channels.discord.autoArchiveDuration` at runtime if not in 2026.3.13 schema (check schema)

---

## Notes for ClawExpert Operations

1. **Our version is 2026.3.13** — the source code in `repos/openclaw` is 2026.3.14 (one version ahead). Always verify keys against the RUNNING version schema, not the source.

2. **Before adding any config key**: Cross-reference this skill with `nick-schema-designer` and check `repos/openclaw/src/config/zod-schema.ts` in the 2026.3.13 tag if uncertain.

3. **`gateway.auth.mode` is required** in 2026.3.13+ when both token and password are configured. Our setup uses token only, so this is fine.

4. **The `channels.*` rename** happened in 2026.1.12. All config should use `channels.telegram.*` not `providers.telegram.*`.

5. **Telegram streaming defaults changed** in 2026.3.2 to `"partial"`. New setups get live preview streaming by default.

6. **Memory bootstrap**: Only `MEMORY.md` (case-sensitive) is loaded as of 2026.3.13. The `memory.md` (lowercase) is only a fallback when `MEMORY.md` is absent.
