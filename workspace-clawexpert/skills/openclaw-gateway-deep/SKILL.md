---
name: openclaw-gateway-deep
description: Deep expert reference for OpenClaw gateway internals — configuration, heartbeat (every/activeHours/model/target), sandboxing (Docker/SSH/OpenShell), secrets management (SecretRef), authentication (token/OAuth), health monitoring, logging, doctor diagnostics, network model, and security threat model. Includes our live setup (port 18789, loopback bind, token auth, SIGUSR1 reload, Docker sandbox, version 2026.3.13).
---

# OpenClaw Gateway — Deep Expert Reference

## Changelog
- 2026-03-20: Created from source docs (gateway/configuration, heartbeat, sandboxing, secrets, authentication, health, logging, troubleshooting, sandbox-vs-tool-policy-vs-elevated, doctor, network-model, security/THREAT-MODEL-ATLAS)

---

## 1. Gateway Configuration

Config file: `~/.openclaw/openclaw.json` (JSON5 format — supports comments and trailing commas)

### Minimal Config

```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } },
  channels: { whatsapp: { allowFrom: ["+15555550123"] } },
}
```

### Config Editing Methods

```bash
# Interactive wizard
openclaw onboard        # full onboarding
openclaw configure      # config wizard

# CLI one-liners
openclaw config get agents.defaults.workspace
openclaw config set agents.defaults.heartbeat.every "2h"
openclaw config unset plugins.entries.brave.config.webSearch.apiKey

# Control UI (browser)
# http://127.0.0.1:18789 → Config tab

# Direct file edit (hot reload applies changes automatically)
vim ~/.openclaw/openclaw.json
```

### ⚠️ Strict Schema Validation

OpenClaw only accepts configurations matching the schema exactly.
- Unknown keys → **Gateway refuses to start**
- Only exception: `$schema` (string) for editor hints
- On failure: only `openclaw doctor`, `openclaw logs`, `openclaw health`, `openclaw status` work
- Fix: run `openclaw doctor` (see exact issues) or `openclaw doctor --fix` (apply repairs)

### Config Hot Reload

The Gateway watches `~/.openclaw/openclaw.json` for changes.

| Reload Mode | Behavior |
|---|---|
| `hybrid` (default) | Hot-applies safe changes instantly; auto-restarts for critical ones |
| `hot` | Hot-applies only; logs warning when restart needed (you handle it) |
| `restart` | Restarts on any config change |
| `off` | Disables watching; changes take effect on next manual restart |

```json5
{
  gateway: {
    reload: { mode: "hybrid", debounceMs: 300 },
  },
}
```

### What Hot-Applies vs Needs Restart

| Category | Fields | Restart? |
|---|---|---|
| Channels | `channels.*`, `web` | No |
| Agent & models | `agent`, `agents`, `models`, `routing` | No |
| Automation | `hooks`, `cron`, `agent.heartbeat` | No |
| Sessions & messages | `session`, `messages` | No |
| Tools & media | `tools`, `browser`, `skills`, `audio`, `talk` | No |
| UI & misc | `ui`, `logging`, `identity`, `bindings` | No |
| **Gateway server** | `gateway.*` (port, bind, auth, tailscale, TLS, HTTP) | **Yes** |
| **Infrastructure** | `discovery`, `canvasHost`, `plugins` | **Yes** |

Note: `gateway.reload` and `gateway.remote` are exceptions — changing them does NOT trigger restart.

### SIGUSR1 Hot Reload

Send `SIGUSR1` to the gateway process to trigger a manual reload:
```bash
kill -SIGUSR1 $(pgrep -f "openclaw gateway")
```

### $include (Split Config)

```json5
// ~/.openclaw/openclaw.json
{
  gateway: { port: 18789 },
  agents: { $include: "./agents.json5" },
  broadcast: {
    $include: ["./clients/a.json5", "./clients/b.json5"],
  },
}
```

- Single file: replaces the containing object
- Array of files: deep-merged in order (later wins)
- Sibling keys: merged after includes (override included values)
- Nested includes: supported up to 10 levels deep
- Relative paths: resolved relative to the including file

### Environment Variables

OpenClaw reads env vars from:
1. Parent process env
2. `.env` in current working directory
3. `~/.openclaw/.env` (global fallback)

Neither `.env` file overrides existing env vars.

Inline env in config:
```json5
{
  env: {
    OPENROUTER_API_KEY: "sk-or-...",
    vars: { GROQ_API_KEY: "gsk-..." },
  },
}
```

Env var substitution:
```json5
{
  gateway: { auth: { token: "${OPENCLAW_GATEWAY_TOKEN}" } },
  models: { providers: { custom: { apiKey: "${CUSTOM_API_KEY}" } } },
}
```

Shell env import (optional):
```json5
{
  env: {
    shellEnv: { enabled: true, timeoutMs: 15000 },
  },
}
```

### Config RPC (Programmatic Updates)

Rate-limited: 3 requests per 60 seconds per `deviceId+clientIp`.

```bash
# Full replace
openclaw gateway call config.get --params '{}'  # get hash first
openclaw gateway call config.apply --params '{
  "raw": "{ agents: { defaults: { workspace: \"~/.openclaw/workspace\" } } }",
  "baseHash": "<hash>",
  "sessionKey": "agent:main:whatsapp:direct:+15555550123"
}'

# Partial update (JSON merge patch)
openclaw gateway call config.patch --params '{
  "raw": "{ channels: { telegram: { groups: { \"*\": { requireMention: false } } } } }",
  "baseHash": "<hash>"
}'
```

---

## 2. Heartbeat

Runs periodic agent turns in the main session to surface anything needing attention.

### Quick Start

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last",
        directPolicy: "allow",
        lightContext: true,
        isolatedSession: true,
      },
    },
  },
}
```

### Defaults

- Interval: `30m` — OR `1h` when Anthropic OAuth/setup-token is detected auth mode
- Default target: `"none"` (runs but doesn't deliver externally)
- Default prompt: `"Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK."`

### Full Config Reference

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",              // default: 30m (0m disables); 1h for OAuth auth
        model: "anthropic/claude-haiku-4-5",  // optional model override
        includeReasoning: false,   // deliver separate Reasoning: message
        lightContext: false,       // true = only inject HEARTBEAT.md from bootstrap
        isolatedSession: false,    // true = fresh session each run (no conversation history)
        target: "last",            // none (default) | last | whatsapp | telegram | discord | ...
        to: "+15551234567",        // optional recipient override
        accountId: "ops-bot",      // optional multi-account channel id
        prompt: "...",             // overrides default prompt (not merged)
        ackMaxChars: 300,          // max chars after HEARTBEAT_OK before delivery
        suppressToolErrorWarnings: false,
        activeHours: {
          start: "09:00",
          end: "22:00",
          timezone: "America/New_York",  // optional; "user" | "local" | IANA tz
        },
        directPolicy: "allow",    // allow (default) | block
        session: "main",          // "main" | explicit session key
      },
    },
  },
}
```

### HEARTBEAT_OK Contract

- Reply `HEARTBEAT_OK` when nothing needs attention
- Treated as ack when at **start or end** of reply
- Token stripped; reply dropped if remaining content ≤ `ackMaxChars` (300)
- If `HEARTBEAT_OK` appears in the **middle** of a reply, NOT treated specially
- For alerts, do NOT include `HEARTBEAT_OK`

### Per-Agent Heartbeats

If ANY `agents.list[]` entry has a `heartbeat` block → **only those agents** run heartbeats.

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last",
      },
    },
    list: [
      { id: "main", default: true },
      {
        id: "ops",
        heartbeat: {
          every: "1h",
          target: "telegram",
          to: "+15551234567",
          prompt: "Read HEARTBEAT.md if it exists. Follow it strictly. If nothing needs attention, reply HEARTBEAT_OK.",
        },
      },
    ],
  },
}
```

### Active Hours

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last",
        activeHours: {
          start: "09:00",
          end: "22:00",
          timezone: "America/New_York",
        },
      },
    },
  },
}
```

24/7 heartbeat: omit `activeHours` entirely (no restriction; this is the default).

### Multi-Account Heartbeat (Telegram)

```json5
{
  agents: {
    list: [
      {
        id: "ops",
        heartbeat: {
          every: "1h",
          target: "telegram",
          to: "12345678:topic:42",  // optional topic thread
          accountId: "ops-bot",
        },
      },
    ],
  },
  channels: {
    telegram: {
      accounts: {
        "ops-bot": { botToken: "YOUR_TELEGRAM_BOT_TOKEN" },
      },
    },
  },
}
```

### Cost Reduction Strategies

- `isolatedSession: true` — avoids sending full conversation history (~100K tokens → ~2-5K per run)
- `lightContext: true` — limit bootstrap to HEARTBEAT.md only
- Set cheaper `model` (e.g. `anthropic/claude-haiku-4-5`)
- Keep HEARTBEAT.md small
- `target: "none"` if only need internal state updates

### Visibility Controls

```yaml
channels:
  defaults:
    heartbeat:
      showOk: false          # Hide HEARTBEAT_OK (default)
      showAlerts: true       # Show alert messages (default)
      useIndicator: true     # Emit indicator events (default)
  telegram:
    heartbeat:
      showOk: true           # Show OK on Telegram
```

**If all three are false** → OpenClaw skips the heartbeat run entirely (no model call).

### Manual Wake

```bash
openclaw system event --text "Check for urgent follow-ups" --mode now
# or wait for next scheduled tick:
openclaw system event --text "..." --mode next-heartbeat
```

### HEARTBEAT.md (Optional)

File: `<agent-workspace>/HEARTBEAT.md`

Example:
```markdown
# Heartbeat checklist

- Quick scan: anything urgent in inboxes?
- If it's daytime, do a lightweight check-in if nothing else is pending.
- If a task is blocked, write down what is missing and ask Nick next time.
```

- If file is empty (only blank lines/headers) → heartbeat run is skipped
- If file is missing → heartbeat still runs

---

## 3. Sandboxing

### Overview

Optional. Runs tools inside isolated environments to limit blast radius.

**Sandboxed:** `exec`, `read`, `write`, `edit`, `apply_patch`, `process`, optional browser
**NOT sandboxed:** Gateway process, `tools.elevated` (explicit host escape hatch)

### Modes

`agents.defaults.sandbox.mode`:
- `"off"` — no sandboxing (default)
- `"non-main"` — only non-main sessions (group/channel sessions are non-main)
- `"all"` — every session

Note: `"non-main"` is based on `session.mainKey` (default `"main"`), not agent id.

### Scope

`agents.defaults.sandbox.scope`:
- `"session"` (default) — one container per session
- `"agent"` — one container per agent
- `"shared"` — one container shared by all sandboxed sessions

### Backends

`agents.defaults.sandbox.backend`:

| | Docker | SSH | OpenShell |
|---|---|---|---|
| Where | Local container | Any SSH host | OpenShell managed |
| Setup | `scripts/sandbox-setup.sh` | SSH key + host | OpenShell plugin enabled |
| Workspace | Bind-mount or copy | Remote-canonical (seed once) | `mirror` or `remote` |
| Network | `docker.network` (default: none) | Depends on remote host | Depends on OpenShell |
| Browser | Supported | Not supported | Not supported yet |
| Best for | Local dev, full isolation | Offload to remote | Managed remote |

### Docker Backend (Our Setup)

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        scope: "session",
        workspaceAccess: "none",
        backend: "docker",
      },
    },
  },
}
```

Build sandbox images:
```bash
# Minimal image (no Node)
scripts/sandbox-setup.sh

# Common tooling image (curl, jq, nodejs, python3, git)
scripts/sandbox-common-setup.sh
# Then set: agents.defaults.sandbox.docker.image = "openclaw-sandbox-common:bookworm-slim"

# Browser sandbox image
scripts/sandbox-browser-setup.sh
```

Default image: `openclaw-sandbox:bookworm-slim`
Default network: **none** (no outbound egress)

### Workspace Access

`agents.defaults.sandbox.workspaceAccess`:
- `"none"` (default) — tools see sandbox workspace under `~/.openclaw/sandboxes`
- `"ro"` — mounts agent workspace read-only at `/agent`
- `"rw"` — mounts agent workspace read/write at `/workspace`

### Custom Bind Mounts

```json5
{
  agents: {
    defaults: {
      sandbox: {
        docker: {
          binds: ["/home/user/source:/source:ro", "/var/data/myapp:/data:ro"],
        },
      },
    },
    list: [
      {
        id: "build",
        sandbox: {
          docker: {
            binds: ["/mnt/cache:/cache:rw"],
          },
        },
      },
    ],
  },
}
```

Security rules for binds:
- Blocked: `docker.sock`, `/etc`, `/proc`, `/sys`, `/dev`, parent mounts exposing these
- Global + per-agent binds are **merged** (not replaced)
- Under `scope: "shared"`, per-agent binds are ignored

### Setup Command (One-Time)

Runs once after container creation (not on every run):

```json5
{
  agents: {
    defaults: {
      sandbox: {
        docker: {
          setupCommand: "apt-get update && apt-get install -y nodejs",
        },
      },
    },
  },
}
```

Pitfalls:
- Default `docker.network` is `"none"` → package installs will fail
- `readOnlyRoot: true` prevents writes
- Container user must be root for installs

### SSH Backend

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "all",
        backend: "ssh",
        scope: "session",
        workspaceAccess: "rw",
        ssh: {
          target: "user@gateway-host:22",
          workspaceRoot: "/tmp/openclaw-sandboxes",
          strictHostKeyChecking: true,
          updateHostKeys: true,
          identityFile: "~/.ssh/id_ed25519",
          certificateFile: "~/.ssh/id_ed25519-cert.pub",
          knownHostsFile: "~/.ssh/known_hosts",
          // SecretRef alternatives:
          // identityData: { source: "env", provider: "default", id: "SSH_IDENTITY" },
          // certificateData: { source: "env", provider: "default", id: "SSH_CERTIFICATE" },
          // knownHostsData: { source: "env", provider: "default", id: "SSH_KNOWN_HOSTS" },
        },
      },
    },
  },
}
```

Remote-canonical model: remote workspace is truth after initial seed.
`openclaw sandbox recreate` → deletes remote root, seeds again from local on next use.

### OpenShell Backend

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "all",
        backend: "openshell",
        scope: "session",
        workspaceAccess: "rw",
      },
    },
  },
  plugins: {
    entries: {
      openshell: {
        enabled: true,
        config: {
          from: "openclaw",
          mode: "remote",  // mirror | remote
          remoteWorkspaceDir: "/sandbox",
          remoteAgentWorkspaceDir: "/agent",
        },
      },
    },
  },
}
```

Workspace modes:
- `mirror` — local workspace stays canonical; syncs before/after exec
- `remote` — OpenShell workspace is canonical after initial seed

### Minimal Enable Example

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        scope: "session",
        workspaceAccess: "none",
      },
    },
  },
}
```

### Sandbox Diagnostics

```bash
openclaw sandbox explain
openclaw sandbox explain --session agent:main:main
openclaw sandbox explain --agent work
openclaw sandbox explain --json
```

Shows: effective mode/scope/workspace access, whether session is sandboxed, tool allow/deny, elevated gates, and fix-it key paths.

---

## 4. Sandbox vs Tool Policy vs Elevated

Three separate controls:

1. **Sandbox** (`agents.defaults.sandbox.*`) — WHERE tools run (Docker vs host)
2. **Tool policy** (`tools.*`) — WHICH tools are available/allowed
3. **Elevated** (`tools.elevated.*`) — exec-only escape hatch to run on host when sandboxed

### Tool Policy Layers

1. Tool profile: `tools.profile` / `agents.list[].tools.profile`
2. Global/per-agent: `tools.allow`/`tools.deny` / `agents.list[].tools.allow`/`deny`
3. Sandbox-specific: `tools.sandbox.tools.allow`/`deny` (only when sandboxed)
4. Provider: `tools.byProvider[provider].allow/deny`

Rules:
- `deny` always wins
- Non-empty `allow` treats everything else as blocked
- Tool policy is a hard stop: `/exec` cannot override a denied `exec` tool

### Tool Groups (Shorthands)

```json5
{
  tools: {
    sandbox: {
      tools: {
        allow: ["group:runtime", "group:fs", "group:sessions", "group:memory"],
      },
    },
  },
}
```

| Group | Expands To |
|---|---|
| `group:runtime` | `exec`, `bash`, `process` |
| `group:fs` | `read`, `write`, `edit`, `apply_patch` |
| `group:sessions` | `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status` |
| `group:memory` | `memory_search`, `memory_get` |
| `group:ui` | `browser`, `canvas` |
| `group:automation` | `cron`, `gateway` |
| `group:messaging` | `message` |
| `group:nodes` | `nodes` |
| `group:openclaw` | All built-in tools |

### Elevated Mode

- NOT a tool grant — only affects `exec`
- Sandboxed session: `/elevated on` or `exec` with `elevated: true` runs on host
- `/elevated full` — skips exec approvals for the session
- Gates: `tools.elevated.enabled`, `tools.elevated.allowFrom.<provider>`

### Common "Sandbox Jail" Fixes

**"Tool X blocked by sandbox tool policy"**
```json5
// Option 1: Disable sandbox
{ agents: { defaults: { sandbox: { mode: "off" } } } }

// Option 2: Allow tool inside sandbox
{ tools: { sandbox: { tools: { allow: ["exec"] } } } }
```

**"I thought this was main, why sandboxed?"**
In `"non-main"` mode, group/channel sessions are NOT main. Check `sandbox explain` for the actual session key.

---

## 5. Secrets Management

### Runtime Model

- Secrets resolved into in-memory runtime snapshot
- Resolution is **eager** during activation (not lazy on request paths)
- Startup fails fast on unresolvable SecretRef for active surfaces
- Reload uses **atomic swap** — full success or keep last-known-good snapshot
- Runtime requests read from active in-memory snapshot only

### SecretRef Contract

```json5
{ source: "env" | "file" | "exec", provider: "default", id: "..." }
```

#### `source: "env"`
```json5
{
  models: {
    providers: {
      openai: { apiKey: { source: "env", provider: "default", id: "OPENAI_API_KEY" } },
    },
  },
}
```

Validation: `id` must match `^[A-Z][A-Z0-9_]{0,127}$`

#### `source: "file"`
```json5
{
  skills: {
    entries: {
      "image-lab": {
        apiKey: { source: "file", provider: "filemain", id: "/skills/entries/image-lab/apiKey" },
      },
    },
  },
}
```

`id` must be absolute JSON pointer (`/...`)

#### `source: "exec"`
```json5
{
  channels: {
    googlechat: {
      serviceAccountRef: { source: "exec", provider: "vault", id: "channels/googlechat/serviceAccount" },
    },
  },
}
```

### Provider Config

```json5
{
  secrets: {
    providers: {
      default: { source: "env" },
      filemain: {
        source: "file",
        path: "~/.openclaw/secrets.json",
        mode: "json",  // or "singleValue"
      },
      vault: {
        source: "exec",
        command: "/usr/local/bin/openclaw-vault-resolver",
        args: ["--profile", "prod"],
        passEnv: ["PATH", "VAULT_ADDR"],
        jsonOnly: true,
      },
    },
    defaults: {
      env: "default",
      file: "filemain",
      exec: "vault",
    },
  },
}
```

### Audit & Configure Workflow

```bash
# Audit for plaintext credentials
openclaw secrets audit --check

# Interactive configuration helper
openclaw secrets configure

# Apply a saved plan
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run
```

### Active-Surface Filtering

SecretRefs only validated on **effectively active surfaces**:
- Disabled channels/accounts → refs are inactive (non-blocking)
- Inactive refs emit `SECRETS_REF_IGNORED_INACTIVE_SURFACE` (non-fatal)
- `gateway.auth.token` SecretRef is inactive when `OPENCLAW_GATEWAY_TOKEN` is set (env wins)

### Exec Integrations

#### 1Password CLI
```json5
{
  secrets: {
    providers: {
      onepassword_openai: {
        source: "exec",
        command: "/opt/homebrew/bin/op",
        allowSymlinkCommand: true,
        trustedDirs: ["/opt/homebrew"],
        args: ["read", "op://Personal/OpenClaw QA API Key/password"],
        passEnv: ["HOME"],
        jsonOnly: false,
      },
    },
  },
}
```

#### HashiCorp Vault
```json5
{
  secrets: {
    providers: {
      vault_openai: {
        source: "exec",
        command: "/opt/homebrew/bin/vault",
        allowSymlinkCommand: true,
        trustedDirs: ["/opt/homebrew"],
        args: ["kv", "get", "-field=OPENAI_API_KEY", "secret/openclaw"],
        passEnv: ["VAULT_ADDR", "VAULT_TOKEN"],
        jsonOnly: false,
      },
    },
  },
}
```

---

## 6. Authentication

### Recommended: API Key (Long-lived Gateway)

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
openclaw models status

# For daemon (systemd/launchd)
cat >> ~/.openclaw/.env <<'EOF'
ANTHROPIC_API_KEY=...
EOF
```

### Anthropic Setup-Token (Subscription)

```bash
# On gateway host
claude setup-token
openclaw models auth setup-token --provider anthropic

# If generated elsewhere
openclaw models auth paste-token --provider anthropic
```

### Gateway Auth (Token Mode)

```json5
{
  gateway: {
    auth: { token: "your-gateway-token" },
  },
}
```

SecretRef for gateway token:
```json5
{
  gateway: {
    auth: { token: { source: "env", provider: "default", id: "OPENCLAW_GATEWAY_TOKEN" } },
  },
}
```

### Non-Loopback Bind + Auth

Non-loopback binds (lan, tailnet, custom) **require auth**:
```bash
openclaw gateway --bind tailnet --token your-token
```

Gateway refuses to start if non-loopback bind without auth configured.

### API Key Rotation on Rate Limits

Priority for 429 retries:
1. `OPENCLAW_LIVE_<PROVIDER>_KEY`
2. `<PROVIDER>_API_KEYS`
3. `<PROVIDER>_API_KEY`
4. `<PROVIDER>_API_KEY_*`

### Auth CLI

```bash
# Check status
openclaw models status
openclaw models status --json
openclaw models status --check  # exit 1=expired, 2=expiring

# Per-session credential pin
/model anthropic/claude-sonnet-4-6@anthropic:default

# Auth profile order
openclaw models auth order get --provider anthropic
openclaw models auth order set --provider anthropic anthropic:default
openclaw models auth order clear --provider anthropic

# Paste token
openclaw models auth paste-token --provider anthropic
```

---

## 7. Health Monitoring

### Quick Checks

```bash
openclaw status                        # local summary
openclaw status --all                  # full local diagnosis
openclaw status --deep                 # also probes running Gateway
openclaw health --json                 # Gateway health snapshot (WS)
openclaw channels status --probe       # per-channel probe
```

Send `/status` in any chat channel for an in-channel status reply.

### Health Monitor Config

```json5
{
  gateway: {
    channelHealthCheckMinutes: 5,           // interval; set 0 to disable
    channelStaleEventThresholdMinutes: 30,  // idle threshold (>= check interval)
    channelMaxRestartsPerHour: 10,          // rolling 1-hour cap per channel
  },
  channels: {
    telegram: {
      healthMonitor: { enabled: false },    // disable for specific channel
      accounts: {
        alerts: {
          healthMonitor: { enabled: true }, // override per-account
        },
      },
    },
  },
}
```

Channels with per-channel override support: Discord, Google Chat, iMessage, Microsoft Teams, Signal, Slack, Telegram, WhatsApp.

### When Something Fails

```bash
# Gateway unreachable
openclaw gateway --port 18789          # start it (--force if port busy)

# No inbound messages
openclaw config get channels           # check allowFrom, dmPolicy
openclaw pairing list --channel telegram

# Channel reconnect
openclaw channels logout && openclaw channels login --verbose
```

---

## 8. Logging

### File Logger

Default path: `/tmp/openclaw/openclaw-YYYY-MM-DD.log` (one file per day, local timezone)

Format: one JSON object per line (JSONL)

Configure:
```json5
{
  logging: {
    file: "/custom/path/openclaw.log",
    level: "info",          // error | warn | info | debug | trace
    consoleLevel: "info",   // controls console verbosity
    consoleStyle: "pretty", // pretty | compact | json
    redactSensitive: "tools",  // off | tools (default)
    redactPatterns: [],     // array of regex strings
  },
}
```

Follow logs:
```bash
openclaw logs --follow
```

### Key Notes

- `--verbose` flag only affects **console verbosity**, NOT file log level
- To get verbose detail in file logs: set `logging.level: "debug"` or `"trace"`
- Console capture: `console.log/info/warn/error/debug/trace` all go to file logs + stdout/stderr

### Gateway WebSocket Log Modes

```bash
# Normal (only errors/slow calls ≥50ms)
openclaw gateway

# All WS traffic (paired request/response)
openclaw gateway --verbose --ws-log compact

# All WS traffic (full metadata)
openclaw gateway --verbose --ws-log full

# Aliases
openclaw gateway --compact           # same as --ws-log compact
```

Options:
- `--ws-log auto` (default) — normal mode optimized; verbose uses compact
- `--ws-log compact` — paired request/response
- `--ws-log full` — full per-frame output
- `--compact` — alias for compact

### Tool Summary Redaction

Verbose tool summaries (`🛠️ Exec: ...`) can mask sensitive tokens:
- `logging.redactSensitive: "tools"` (default) — masks in console only
- `logging.redactSensitive: "off"` — no masking
- Does NOT alter file logs

---

## 9. Doctor

Repair, migration, and health check tool.

### Quick Commands

```bash
openclaw doctor                    # interactive mode
openclaw doctor --yes              # accept all defaults
openclaw doctor --repair           # apply recommended fixes without prompts
openclaw doctor --repair --force   # aggressive repairs (overwrites custom supervisor configs)
openclaw doctor --non-interactive  # safe migrations only, no restart/service/sandbox actions
openclaw doctor --deep             # scan system for extra gateway installs
```

### What Doctor Does

1. Optional pre-flight update (git installs)
2. UI protocol freshness check
3. Health check + restart prompt
4. Skills status summary
5. Config normalization for legacy values
6. Legacy config key migrations
7. Browser migration checks
8. OpenCode provider override warnings
9. Legacy on-disk state migration
10. Legacy cron store migration
11. State integrity + permissions checks
12. Config file permission checks (chmod 600)
13. Model auth health (OAuth expiry)
14. Extra workspace dir detection
15. Sandbox image repair
16. Legacy service migration
17. Gateway runtime checks
18. Channel status warnings
19. Supervisor config audit
20. Gateway runtime best practices (Node vs Bun, version-manager paths)
21. Gateway port collision diagnostics (default 18789)
22. Security warnings for open DM policies
23. Gateway auth checks (local token)
24. systemd linger check (Linux)
25. Source install checks
26. Config write + wizard metadata

### Config Key Migrations

Doctor auto-migrates these legacy keys:
- `routing.allowFrom` → `channels.whatsapp.allowFrom`
- `routing.groupChat.requireMention` → per-channel `groups."*".requireMention`
- `routing.groupChat.historyLimit` → `messages.groupChat.historyLimit`
- `routing.queue` → `messages.queue`
- `routing.bindings` → top-level `bindings`
- `routing.agents` → `agents.list`
- `identity` → `agents.list[].identity`
- `agent.*` → `agents.defaults` + `tools.*`

### Generating Gateway Token

```bash
openclaw doctor --generate-gateway-token
```

Only runs when no token SecretRef is configured.

### Gateway Auth Doctor Behavior

- If token mode needs a token and no token source exists → offers to generate one
- If `gateway.auth.token` is SecretRef-managed but unavailable → warns, does NOT overwrite with plaintext
- If both `gateway.auth.token` and `gateway.auth.password` are set with `gateway.auth.mode` unset → blocks install/repair until mode is explicitly set

---

## 10. Network Model

### Core Rules

- One Gateway per host (recommended)
- Only process allowed to own the WhatsApp Web session
- Gateway WS defaults: `ws://127.0.0.1:18789`
- Wizard generates gateway token by default, even for loopback
- For tailnet access: `openclaw gateway --bind tailnet --token ...` (required for non-loopback)
- Legacy TCP bridge is **deprecated**

### Canvas Host

Served by Gateway HTTP server on same port (default 18789):
- `/__openclaw__/canvas/`
- `/__openclaw__/a2ui/`

When `gateway.auth` is configured + Gateway binds beyond loopback: these routes are protected by auth.

### Remote Access

Options:
- SSH tunnel
- Tailscale VPN (`--bind tailnet`)

See: `/gateway/remote`, `/gateway/discovery`

### Multiple Gateways

For rescue bots or strict isolation: run multiple gateways with isolated profiles + different ports.

### Gateway Port

Default port: `18789`

```json5
{
  gateway: {
    port: 18789,
    bind: "loopback",  // loopback (default) | lan | tailnet | custom
  },
}
```

---

## 11. Troubleshooting Runbook

### Command Ladder (Run in Order)

```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

Expected healthy signals:
- `openclaw gateway status` → `Runtime: running` and `RPC probe: ok`
- `openclaw doctor` → no blocking issues
- `openclaw channels status --probe` → connected/ready channels

### Gateway Service Not Running

```bash
openclaw gateway status
openclaw status
openclaw logs --follow
openclaw doctor
```

Common signatures:
- `Gateway start blocked: set gateway.mode=local` → add `gateway.mode: "local"` to config
- `refusing to bind gateway ... without auth` → non-loopback bind without token
- `another gateway instance is already listening` / `EADDRINUSE` → port conflict

### Dashboard / Control UI Not Connecting

Error code quick map:

| `error.details.code` | Meaning | Action |
|---|---|---|
| `AUTH_TOKEN_MISSING` | No shared token sent | Paste/set token in client |
| `AUTH_TOKEN_MISMATCH` | Token didn't match | Check token drift; try device token retry |
| `AUTH_DEVICE_TOKEN_MISMATCH` | Stale device token | Rotate/re-approve: `openclaw devices list` |
| `PAIRING_REQUIRED` | Device not approved | `openclaw devices approve <requestId>` |

### No Replies

```bash
openclaw status
openclaw channels status --probe
openclaw pairing list --channel telegram
openclaw config get channels
openclaw logs --follow
```

Common signatures:
- `drop guild message (mention required)` → group mention policy active
- `pairing request` → sender needs approval
- `blocked` / `allowlist` → allowlist mismatch

### Post-Upgrade Breakage

```bash
# 1) Check auth/URL behavior
openclaw config get gateway.mode
openclaw config get gateway.remote.url
openclaw config get gateway.auth.mode

# 2) Check bind/auth guardrails
openclaw config get gateway.bind
openclaw config get gateway.auth.token

# 3) Check pairing/device state
openclaw devices list
openclaw pairing list --channel telegram
```

If service config and runtime disagree after checks:
```bash
openclaw gateway install --force
openclaw gateway restart
```

### Anthropic 429 Long Context

```bash
openclaw logs --follow
openclaw models status
openclaw config get agents.defaults.models
```

Fix: set `params.context1m: false` or ensure account has Extra Usage enabled.

---

## 12. Security Threat Model (MITRE ATLAS)

Key threats relevant to our deployment:

### Critical Threats (P0)

| ID | Threat | Our Risk |
|---|---|---|
| T-EXEC-001 | Direct prompt injection | Critical — detection only, no blocking |
| T-PERSIST-001 | Malicious skill installation | Critical — limited review on ClawHub |
| T-EXFIL-003 | Credential harvesting via skill | Critical — skills run with agent privileges |

### High Threats (P1)

| ID | Threat | Mitigation |
|---|---|---|
| T-EXEC-002 | Indirect prompt injection via fetched content | XML tag wrapping (partial) |
| T-EXEC-004 | Exec approval bypass | Allowlist + ask mode |
| T-ACCESS-003 | Token theft from config files | File permissions (high risk: tokens in plaintext) |
| T-EXFIL-001 | Data theft via web_fetch | SSRF blocking for internal networks |
| T-IMPACT-001 | Unauthorized command execution | Docker sandbox (when enabled) |
| T-IMPACT-002 | Resource exhaustion / DoS | No rate limiting (gap) |

### Trust Boundaries

```
UNTRUSTED ZONE (channels: WhatsApp, Telegram, Discord)
    ↓
TRUST BOUNDARY 1: Channel Access (Gateway)
  • Device Pairing (30s grace period)
  • AllowFrom / AllowList validation
  • Token/Password/Tailscale auth
    ↓
TRUST BOUNDARY 2: Session Isolation (Agent Sessions)
  • Session key = agent:channel:peer
  • Tool policies per agent
  • Transcript logging
    ↓
TRUST BOUNDARY 3: Tool Execution (Docker Sandbox)
  • Docker sandbox OR Host (exec-approvals)
  • SSRF protection (DNS pinning + IP blocking)
    ↓
TRUST BOUNDARY 4: External Content (web_fetch, emails, webhooks)
  • External content wrapping (XML tags)
  • Security notice injection
    ↓
TRUST BOUNDARY 5: Supply Chain (ClawHub)
  • Skill publishing (semver, SKILL.md required)
  • Pattern-based moderation flags
  • GitHub account age verification
```

### Critical Security Files

| File | Purpose |
|---|---|
| `src/infra/exec-approvals.ts` | Command approval logic |
| `src/gateway/auth.ts` | Gateway authentication |
| `src/web/inbound/access-control.ts` | Channel access control |
| `src/infra/net/ssrf.ts` | SSRF protection |
| `src/security/external-content.ts` | Prompt injection mitigation |
| `src/agents/sandbox/tool-policy.ts` | Tool policy enforcement |
| `convex/lib/moderation.ts` | ClawHub moderation |

### Key Recommendations (For Our Setup)

1. **Enable Docker sandbox** for non-main sessions (`sandbox.mode: "non-main"`) — reduces command execution blast radius
2. **Use SecretRefs** for API keys via `openclaw secrets configure` — tokens in plaintext at rest is high risk
3. **Set exec approval mode** for sensitive commands (`ask` mode in tool policy)
4. **DM policy**: keep `"pairing"` (default) — avoid `"open"` 
5. **Skill auditing**: before installing any ClawHub skill, review code with `skill-security-auditor-v2`

---

## 13. Our Setup

### System Details

| Parameter | Value |
|---|---|
| Version | 2026.3.13 (stable channel) |
| Deployment | Docker on Hostinger VPS (72.61.127.59) |
| Container | `openclaw-okny-openclaw-1` |
| Image | `ghcr.io/hostinger/hvps-openclaw:latest` |
| Config | `/data/.openclaw/openclaw.json` |
| Port | 18789 (loopback bind) |
| Auth | Token mode (gateway.auth.token) |
| Reload | hybrid (default) |
| Sandbox | Docker (when enabled for subagents) |

### Gateway Management

```bash
# Service management
openclaw gateway status
openclaw gateway start
openclaw gateway stop
openclaw gateway restart

# Health check
openclaw status
openclaw doctor
openclaw health --json

# Logs
openclaw logs --follow
openclaw logs --follow | grep -E "error|warn|heartbeat"

# Config reload (manual, without restart)
kill -SIGUSR1 $(pgrep -f "openclaw gateway")
```

### Heartbeat Config (Our Agents)

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "1h",         // 1h because we use OAuth/setup-token auth
        target: "last",
        isolatedSession: true,
        lightContext: true,
        activeHours: {
          start: "07:00",
          end: "24:00",
          timezone: "Asia/Kuala_Lumpur",
        },
      },
    },
  },
}
```

### Channel Setup (Telegram + 4 Bots)

```json5
{
  channels: {
    telegram: {
      accounts: {
        "main-bot": { botToken: "..." },    // Maks
        "pm-bot": { botToken: "..." },      // MaksPM
        "research-bot": { botToken: "..." },// Scout
        "ops-bot": { botToken: "..." },     // ClawExpert
      },
      dmPolicy: "pairing",
    },
  },
}
```

### Version Note (2026.3.13 vs Source 2026.3.14)

Running version is **2026.3.13**. Source repo at `repos/openclaw` is **2026.3.14** (one version ahead).
- Always verify a config key exists in 2026.3.13 before using it
- Check `openclaw doctor` output for any config warnings after any config changes
- Reference skill `openclaw-schema-map` for exact valid config keys for running version
