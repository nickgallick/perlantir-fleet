---
name: openclaw-source-code
description: Deep knowledge extracted from the OpenClaw source code. Updated by reading the actual repo.
---

# Changelog
- 2026-03-19: Initial extraction from repos/openclaw (v2026.3.14), repos/nemoclaw (v0.1.0), repos/anthropic-sdk-python

# OpenClaw Source Code Intelligence

## Repo Location
/data/.openclaw/workspace-clawexpert/repos/openclaw

## Principle
When answering ANY question about OpenClaw internals, config validity, or behavior:
1. First check openclaw-schema-map skill for pre-extracted schema knowledge
2. If not found, go read the actual source code in the repo
3. After reading source, update this skill so you don't re-read next time
4. ALWAYS prefer source code over documentation — source is truth

## Key Files

### Config Schema (THE MOST IMPORTANT FILE)
- **Path**: `repos/openclaw/src/config/zod-schema.ts`
- Exports `OpenClawSchema` — every valid config key via `.strict()`
- READ THIS to answer any "is this key valid?" question
- Imports from: zod-schema.agents.ts, zod-schema.core.ts, zod-schema.providers.ts, etc.

### Supporting Schema Files
- `zod-schema.core.ts` — SecretInputSchema, ModelsConfigSchema, IdentitySchema, TtsConfigSchema
- `zod-schema.agents.ts` — AgentsSchema, BindingsSchema, BroadcastSchema
- `zod-schema.agent-runtime.ts` — AgentEntrySchema, HeartbeatSchema, SandboxDockerSchema, ToolsSchema
- `zod-schema.agent-defaults.ts` — AgentDefaultsSchema
- `zod-schema.providers.ts` — ChannelsSchema (all channel types)
- `zod-schema.hooks.ts` — HookMappingSchema, HooksGmailSchema
- `zod-schema.session.ts` — CommandsSchema, MessagesSchema, SessionSchema

### MCP Handling
- **Path**: `repos/openclaw/src/config/mcp-config.ts`
- **Path**: `repos/openclaw/src/acp/translator.ts` (line 407)
- MCP capabilities are set to `{ http: false, sse: false }` in ACP translator
- The `mcp` key IS valid in config — it maps to `McpConfigSchema` with `servers` record
- Use `mcp.servers` for stdio MCP servers; mcporter bridge is the recommended pattern

### Plugin System
- **Path**: `repos/openclaw/src/config/zod-schema.ts` (PluginEntrySchema)
- Plugin entries live at `plugins.entries.<id>` with: enabled, hooks, subagent, config
- Plugin installs at `plugins.installs.<id>`
- Plugin slots: `plugins.slots.memory`, `plugins.slots.contextEngine`

### Gateway Entry
- **Path**: `repos/openclaw/src/config/zod-schema.ts` (gateway section)
- `gateway.bind`: "auto" | "lan" | "loopback" | "custom" | "tailnet"
- `gateway.mode`: "local" | "remote"
- `gateway.customBindHost`: valid key (contrary to old runbook entries)

### NemoClaw Integration
- **Mechanism**: OpenClaw **plugin** (not fork/wrapper)
- **Plugin ID**: `nemoclaw`
- **Plugin JSON**: `repos/nemoclaw/nemoclaw/openclaw.plugin.json`
- Installed via: `curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash`
- Runs OpenClaw inside OpenShell (k3s sandbox with Landlock + seccomp + network policies)
- Config keys: blueprintVersion, blueprintRegistry, sandboxName, inferenceProvider

### Agent Lifecycle (AgentEntrySchema)
Valid keys for each agent in `agents.list[]`:
- `id` (required), `default`, `name`, `workspace`, `agentDir`
- `model`, `skills`, `memorySearch`, `humanDelay`, `heartbeat`
- `identity`, `groupChat`, `subagents`, `sandbox`, `params`
- `tools`, `runtime`
- NO `systemPrompt` key directly on agent — that comes from workspace SOUL.md/AGENTS.md

### Session Management
- **Path**: `repos/openclaw/src/config/zod-schema.session.ts`
- `session` key maps to SessionSchema
- `commands` key maps to CommandsSchema
- `messages` key maps to MessagesSchema

## Version Intel
- **Repo HEAD**: 2026.3.14 (one patch ahead of our running 2026.3.13)
- **NemoClaw**: 0.1.0 alpha
- **Unreleased**: `/btw` side-questions command, OpenShell sandbox backend, Firecrawl integration, bundle plugins (Codex/Claude/Cursor), improved gateway health monitor

## Critical Discoveries

### MCP IS Valid in Config (Correction to old belief)
The `mcp` key IS in the schema: `mcp: McpConfigSchema`
```typescript
const McpConfigSchema = z.object({
  servers: z.record(z.string(), McpServerSchema).optional()
}).strict().optional();
```
mcporter is RECOMMENDED but native stdio MCP via `mcp.servers` IS supported.
ACP transport capabilities (http/sse) are disabled — that's different from stdio.

### `customBindHost` IS Valid
`gateway.customBindHost: z.string().optional()` — it IS in the schema.

### `$schema` Key IS Valid
`$schema: z.string().optional()` — the schema accepts it.

### Config `.strict()` at Root Level
`OpenClawSchema` uses `.strict()` — any unknown top-level key crashes the gateway.
Known valid root keys: $schema, meta, env, wizard, diagnostics, logging, cli, update, browser, ui, secrets, auth, acp, models, nodeHost, agents, tools, bindings, broadcast, audio, media, messages, commands, approvals, session, cron, hooks, web, channels, discovery, canvasHost, talk, gateway, memory, mcp, skills, plugins
