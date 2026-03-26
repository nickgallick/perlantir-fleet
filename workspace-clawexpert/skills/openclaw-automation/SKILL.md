---
name: openclaw-automation
description: Expert reference for OpenClaw automation: cron jobs, heartbeats, hooks, webhooks, polls, and Gmail Pub/Sub — all schedule kinds, session targets, delivery modes, retry policy, and troubleshooting.
---

# OpenClaw Automation

## Changelog
- 2026-03-20: Created from source docs — covers cron-jobs, cron-vs-heartbeat, hooks, webhook, poll, troubleshooting, auth-monitoring, gmail-pubsub

---

## Cron Jobs (Gateway Scheduler)

Cron is the Gateway's built-in scheduler. Jobs persist under `~/.openclaw/cron/jobs.json` and survive restarts.

### Two execution styles
- **Main session**: enqueue a system event → run on next heartbeat.
- **Isolated**: dedicated agent turn in `cron:<jobId>` or custom session, with delivery (announce by default or none).
- **Current session**: bind to the session where cron is created (`sessionTarget: "current"`).
- **Custom session**: run in a persistent named session (`sessionTarget: "session:custom-id"`).

### Schedule Kinds (all 3)

| Kind | Field | Example |
|------|-------|---------|
| `at` | `schedule.at` (ISO 8601) | `"2026-02-01T16:00:00Z"` |
| `every` | `schedule.everyMs` (ms) | `300000` (5 min) |
| `cron` | `schedule.expr` + optional `tz` | `"0 7 * * *"` |

ISO timestamps without timezone → treated as **UTC**. Cron expressions use `croner`. Without `tz`, gateway host timezone is used.

**Top-of-hour stagger**: recurring top-of-hour expressions (`0 * * * *`, `0 */2 * * *`) get a deterministic per-job stagger of up to 5 minutes. Fixed-hour like `0 7 * * *` remain exact.

Override stagger:
- `--stagger 30s` (or `1m`, `5m`) — explicit window
- `--exact` — force `staggerMs = 0`
- In JSON: `"schedule": { "staggerMs": 0 }`

### SessionTarget Options (all 4)

| Value | Behavior |
|-------|----------|
| `"main"` | System event → heartbeat prompt + main-session context |
| `"isolated"` | Dedicated turn in `cron:<jobId>`, fresh session each run |
| `"current"` | Resolved at creation → `session:<sessionKey>` |
| `"session:custom-id"` | Persistent named session, accumulates context |

**Defaults**: `systemEvent` payloads → `main`; `agentTurn` payloads → `isolated`.

### Payload Kinds (2)

**`systemEvent`** (main session only):
```json
{
  "kind": "systemEvent",
  "text": "Reminder text"
}
```

**`agentTurn`** (isolated session only):
```json
{
  "kind": "agentTurn",
  "message": "Summarize overnight updates.",
  "model": "opus",
  "thinking": "high",
  "timeoutSeconds": 120,
  "lightContext": true
}
```

`lightContext: true` → lightweight bootstrap, no workspace file injection. CLI: `--light-context`.

### WakeMode

- `"now"` (default): immediate heartbeat trigger
- `"next-heartbeat"`: wait for next scheduled heartbeat

### Delivery Modes (3)

| Mode | Behavior |
|------|----------|
| `"announce"` | Deliver to channel via outbound adapters + short summary to main session |
| `"webhook"` | POST finished event JSON to `delivery.to` URL |
| `"none"` | Internal only, no outbound message |

Default for isolated jobs when `delivery` omitted: `"announce"`.

Delivery config fields:
- `delivery.mode`: `announce` | `webhook` | `none`
- `delivery.channel`: `whatsapp` | `telegram` | `discord` | `slack` | `mattermost` | `signal` | `imessage` | `last`
- `delivery.to`: channel target or webhook URL
- `delivery.bestEffort`: avoid failing job if announce delivery fails

**Announce behavior details**:
- Uses isolated run's outbound payloads with normal chunking
- `HEARTBEAT_OK`-only responses not delivered
- If isolated run already sent to same target → delivery skipped to avoid duplicates
- Short summary posted to main session (respects `wakeMode`)

**Webhook behavior**:
- HTTP(S) URL required
- Auth: `Authorization: Bearer <cron.webhookToken>` if configured
- No channel delivery in webhook mode
- No main-session summary in webhook mode

### Telegram Delivery Targets (topics)
```
-1001234567890           (chat id only)
-1001234567890:topic:123 (explicit topic marker — preferred)
-1001234567890:123       (shorthand numeric suffix)
telegram:group:-1001234567890:topic:123
```

### Model and Thinking Overrides (isolated jobs)
```json
{
  "payload": {
    "kind": "agentTurn",
    "model": "anthropic/claude-sonnet-4-20250514",
    "thinking": "high"
  }
}
```
Resolution priority: 1) Job payload override, 2) Hook-specific defaults (e.g. `hooks.gmail.model`), 3) Agent config default.

### JSON Schema for Tool Calls

**One-shot, main session:**
```json
{
  "name": "Reminder",
  "schedule": { "kind": "at", "at": "2026-02-01T16:00:00Z" },
  "sessionTarget": "main",
  "wakeMode": "now",
  "payload": { "kind": "systemEvent", "text": "Reminder text" },
  "deleteAfterRun": true
}
```

**Recurring isolated with delivery:**
```json
{
  "name": "Morning brief",
  "schedule": { "kind": "cron", "expr": "0 7 * * *", "tz": "America/Los_Angeles" },
  "sessionTarget": "isolated",
  "wakeMode": "next-heartbeat",
  "payload": {
    "kind": "agentTurn",
    "message": "Summarize overnight updates.",
    "lightContext": true
  },
  "delivery": {
    "mode": "announce",
    "channel": "slack",
    "to": "channel:C1234567890",
    "bestEffort": true
  }
}
```

**Current session binding:**
```json
{
  "name": "Daily standup",
  "schedule": { "kind": "cron", "expr": "0 9 * * *" },
  "sessionTarget": "current",
  "payload": {
    "kind": "agentTurn",
    "message": "Summarize yesterday's progress."
  }
}
```

**Custom persistent session:**
```json
{
  "name": "Project monitor",
  "schedule": { "kind": "every", "everyMs": 300000 },
  "sessionTarget": "session:project-alpha-monitor",
  "payload": {
    "kind": "agentTurn",
    "message": "Check project status and update the running log."
  }
}
```

**cron.update:**
```json
{
  "jobId": "job-123",
  "patch": {
    "enabled": false,
    "schedule": { "kind": "every", "everyMs": 3600000 }
  }
}
```

**cron.run / cron.remove:**
```json
{ "jobId": "job-123", "mode": "force" }
{ "jobId": "job-123" }
```

### CLI Quick Reference

```bash
# One-shot reminder (auto-delete after success)
openclaw cron add \
  --name "Send reminder" \
  --at "2026-01-12T18:00:00Z" \
  --session main \
  --system-event "Reminder: submit expense report." \
  --wake now \
  --delete-after-run

# One-shot in 20 minutes
openclaw cron add \
  --name "Calendar check" \
  --at "20m" \
  --session main \
  --system-event "Next heartbeat: check calendar." \
  --wake now

# Recurring isolated → WhatsApp
openclaw cron add \
  --name "Morning status" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize inbox + calendar for today." \
  --announce \
  --channel whatsapp \
  --to "+15551234567"

# With stagger
openclaw cron add \
  --name "Minute watcher" \
  --cron "0 * * * * *" \
  --tz "UTC" \
  --stagger 30s \
  --session isolated \
  --message "Run minute watcher checks." \
  --announce

# Telegram topic delivery
openclaw cron add \
  --name "Nightly summary" \
  --cron "0 22 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize today." \
  --announce \
  --channel telegram \
  --to "-1001234567890:topic:123"

# Model + thinking override
openclaw cron add \
  --name "Deep analysis" \
  --cron "0 6 * * 1" \
  --session isolated \
  --message "Weekly deep analysis." \
  --model "opus" \
  --thinking high \
  --announce

# Pin job to specific agent
openclaw cron add --name "Ops sweep" --cron "0 6 * * *" --session isolated --message "Check ops queue" --agent ops
openclaw cron edit <jobId> --agent ops
openclaw cron edit <jobId> --clear-agent

# Manual run (force default, --due to only run when due)
openclaw cron run <jobId>
openclaw cron run <jobId> --due

# Edit job
openclaw cron edit <jobId> \
  --message "Updated prompt" \
  --model "opus" \
  --thinking low

# Force exact schedule (no stagger)
openclaw cron edit <jobId> --exact

# Run history
openclaw cron runs --id <jobId> --limit 50

# Immediate system event (no job)
openclaw system event --mode now --text "Next heartbeat: check battery."
```

### Storage
- Job store: `~/.openclaw/cron/jobs.json`
- Run history: `~/.openclaw/cron/runs/<jobId>.jsonl` (JSONL, auto-pruned)
- Isolated run sessions: pruned by `cron.sessionRetention` (default `24h`)
- Override store path: `cron.store` in config

### Retry Policy

**Transient errors (retried)**: rate limit (429), provider overload, network errors (timeout, ECONNRESET), server errors (5xx), Cloudflare errors.

**Permanent errors (no retry)**: auth failures, config/validation errors.

**One-shot jobs (`at`)**: retry transient up to 3× with exponential backoff (30s → 1m → 5m). Permanent → disable immediately. Success → delete if `deleteAfterRun: true`.

**Recurring jobs (`cron`/`every`)**: exponential backoff (30s → 1m → 5m → 15m → 60m) before next scheduled run. Job stays enabled; backoff resets after next success.

### Configuration

```json5
{
  cron: {
    enabled: true,
    store: "~/.openclaw/cron/jobs.json",
    maxConcurrentRuns: 1,
    retry: {
      maxAttempts: 3,
      backoffMs: [60000, 120000, 300000],
      retryOn: ["rate_limit", "overloaded", "network", "server_error"],
    },
    webhook: "https://example.invalid/legacy",  // deprecated fallback
    webhookToken: "replace-with-token",
    sessionRetention: "24h",  // or false to disable
    runLog: {
      maxBytes: "2mb",
      keepLines: 2000,
    },
    failureDestination: {
      channel: "telegram",
      to: "<clawexpert-chat-id>"
    }
  }
}
```

Disable cron: `cron.enabled: false` or `OPENCLAW_SKIP_CRON=1`.

**Maintenance tuning examples**:
```json5
// Keep sessions for a week, bigger logs
{ cron: { sessionRetention: "7d", runLog: { maxBytes: "10mb", keepLines: 5000 } } }

// High-volume (tight retention)
{ cron: { sessionRetention: "12h", runLog: { maxBytes: "3mb", keepLines: 1500 } } }
```

### Gateway API Surface
`cron.list`, `cron.status`, `cron.add`, `cron.update`, `cron.remove`, `cron.run`, `cron.runs`

---

## Heartbeat vs Cron Decision Matrix

| Use Case | Recommended | Why |
|----------|-------------|-----|
| Check inbox every 30 min | Heartbeat | Batches with other checks, context-aware |
| Send daily report at 9am sharp | Cron (isolated) | Exact timing needed |
| Monitor calendar for upcoming events | Heartbeat | Natural fit for periodic awareness |
| Run weekly deep analysis | Cron (isolated) | Standalone task, can use different model |
| Remind me in 20 minutes | Cron (main, `--at`) | One-shot with precise timing |
| Background project health check | Heartbeat | Piggybacks on existing cycle |

### Decision Flowchart
```
Does the task need to run at an EXACT time?
  YES → Use cron
  NO  → Continue...

Does the task need isolation from main session?
  YES → Use cron (isolated)
  NO  → Continue...

Can this task be batched with other periodic checks?
  YES → Use heartbeat (add to HEARTBEAT.md)
  NO  → Use cron

Is this a one-shot reminder?
  YES → Use cron with --at
  NO  → Continue...

Does it need a different model or thinking level?
  YES → Use cron (isolated) with --model/--thinking
  NO  → Use heartbeat
```

### Main Session vs Isolated Session

| | Heartbeat | Cron (main) | Cron (isolated) |
|---|---|---|---|
| Session | Main | Main (via system event) | `cron:<jobId>` or custom |
| History | Shared | Shared | Fresh each run / Persistent (custom) |
| Context | Full | Full | None / Cumulative (custom) |
| Model | Main model | Main model | Can override |
| Output | Delivered if not `HEARTBEAT_OK` | Heartbeat prompt + event | Announce summary (default) |

### Cost Profile

| Mechanism | Cost Profile |
|-----------|-------------|
| Heartbeat | One turn every N min; scales with HEARTBEAT.md size |
| Cron (main) | Adds event to next heartbeat (no isolated turn) |
| Cron (isolated) | Full agent turn per job; can use cheaper model |

---

## Hooks (Event-Driven Automation)

Hooks run inside the Gateway when agent events fire. Discovery from directories; managed via CLI.

### Hook Discovery (3 directories, precedence order)
1. `<workspace>/hooks/` — per-agent, highest precedence
2. `~/.openclaw/hooks/` — user-installed, shared
3. `<openclaw>/dist/hooks/bundled/` — shipped with OpenClaw

### Hook Structure
```
my-hook/
├── HOOK.md          # Metadata + documentation
└── handler.ts       # Handler implementation
```

**HOOK.md frontmatter:**
```yaml
---
name: my-hook
description: "Short description"
metadata: { "openclaw": { "emoji": "🔗", "events": ["command:new"], "requires": { "bins": ["node"] } } }
---
```

**handler.ts:**
```typescript
const myHandler = async (event) => {
  if (event.type !== "command" || event.action !== "new") return;
  console.log(`[my-hook] Triggered: ${event.sessionKey}`);
  event.messages.push("✨ Hook executed!");
};
export default myHandler;
```

### Event Types (all)

**Command Events:**
- `command` — all command events
- `command:new` — `/new` command
- `command:reset` — `/reset` command
- `command:stop` — `/stop` command

**Session Events:**
- `session:compact:before` — right before compaction
- `session:compact:after` — after compaction completes

**Agent Events:**
- `agent:bootstrap` — before workspace bootstrap files injected (can mutate `context.bootstrapFiles`)

**Gateway Events:**
- `gateway:startup` — after channels start and hooks are loaded

**Message Events:**
- `message` — all message events
- `message:received` — inbound message (may contain raw `<media:audio>` placeholders)
- `message:transcribed` — message fully processed including audio transcription
- `message:preprocessed` — after all media + link understanding completes
- `message:sent` — outbound message successfully sent

**Plugin Hook Events (synchronous, not event-stream):**
- `tool_result_persist` — transform tool results before written to session transcript

**Compaction lifecycle (via plugin hook runner):**
- `before_compaction`, `after_compaction`

### Message Event Context

```typescript
// message:received
{ from, content, timestamp?, channelId, accountId?, conversationId?, messageId?, metadata? }

// message:sent
{ to, content, success, error?, channelId, accountId?, conversationId?, messageId?, isGroup?, groupId? }

// message:transcribed
{ body?, bodyForAgent?, transcript, channelId, conversationId?, messageId? }

// message:preprocessed
{ body?, bodyForAgent?, transcript?, channelId, conversationId?, messageId?, isGroup?, groupId? }
```

### Bundled Hooks Reference

**💾 session-memory** — saves session context to workspace memory on `/new`
- Events: `command:new`
- Output: `<workspace>/memory/YYYY-MM-DD-slug.md`
- Requires: `workspace.dir` configured
- `openclaw hooks enable session-memory`

**📎 bootstrap-extra-files** — injects additional bootstrap files during `agent:bootstrap`
- Events: `agent:bootstrap`
- Config:
```json
{
  "hooks": { "internal": { "entries": { "bootstrap-extra-files": {
    "enabled": true,
    "paths": ["packages/*/AGENTS.md", "packages/*/TOOLS.md"]
  }}}}
}
```

**📝 command-logger** — logs all commands to `~/.openclaw/logs/commands.log`
- Events: `command`
- Format: JSONL `{"timestamp","action","sessionKey","senderId","source"}`
- `openclaw hooks enable command-logger`

**🚀 boot-md** — runs `BOOT.md` when gateway starts
- Events: `gateway:startup`
- Requires: `workspace.dir`, internal hooks enabled

### Hook CLI
```bash
openclaw hooks list
openclaw hooks list --eligible
openclaw hooks list --verbose
openclaw hooks info session-memory
openclaw hooks check
openclaw hooks enable session-memory
openclaw hooks disable command-logger
```

### Configuration (new format)
```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "session-memory": { "enabled": true },
        "command-logger": { "enabled": false },
        "my-hook": {
          "enabled": true,
          "env": { "MY_CUSTOM_VAR": "value" }
        }
      },
      "load": {
        "extraDirs": ["/path/to/more/hooks"]
      }
    }
  }
}
```

### Best Practices
- Keep handlers fast (async fire-and-forget for slow work)
- Handle errors gracefully (never throw — lets other handlers run)
- Filter events early (return early if not relevant)
- Use specific event keys in metadata

---

## Webhooks

Gateway exposes HTTP webhook endpoints for external triggers.

### Enable
```json5
{
  hooks: {
    enabled: true,
    token: "shared-secret",
    path: "/hooks",
    allowedAgentIds: ["hooks", "main"],  // omit or "*" for any
  }
}
```

### Auth
- `Authorization: Bearer <token>` (recommended)
- `x-openclaw-token: <token>`
- Query-string tokens rejected (`?token=...` → 400)

### `POST /hooks/wake`
```json
{ "text": "New email received", "mode": "now" }
```
- `text` (required): event description
- `mode` optional: `now` (default) | `next-heartbeat`
- Effect: enqueues system event for **main** session

### `POST /hooks/agent`
```json
{
  "message": "Run this",
  "name": "Email",
  "agentId": "hooks",
  "sessionKey": "hook:email:msg-123",
  "wakeMode": "now",
  "deliver": true,
  "channel": "last",
  "to": "+15551234567",
  "model": "openai/gpt-5.2-mini",
  "thinking": "low",
  "timeoutSeconds": 120
}
```
- `message` (required): prompt for the agent
- `agentId`: route to specific agent (unknown → fallback to default)
- `sessionKey`: rejected unless `hooks.allowRequestSessionKey=true`
- `deliver` (bool, default `true`): send response to messaging channel
- `channel`: `last` | `whatsapp` | `telegram` | `discord` | `slack` | `mattermost` | `signal` | `imessage` | `msteams`
- Effect: **isolated** agent turn, always posts summary to main session

### Session Key Policy
```json5
// Recommended (secure)
{
  hooks: {
    enabled: true,
    token: "${OPENCLAW_HOOKS_TOKEN}",
    defaultSessionKey: "hook:ingress",
    allowRequestSessionKey: false,
    allowedSessionKeyPrefixes: ["hook:"],
  }
}

// Legacy compatibility
{
  hooks: {
    enabled: true,
    token: "${OPENCLAW_HOOKS_TOKEN}",
    allowRequestSessionKey: true,
    allowedSessionKeyPrefixes: ["hook:"],
  }
}
```

### Response Codes
- `200` — success (wake or agent accepted)
- `401` — auth failure
- `429` — rate limited after repeated auth failures
- `400` — invalid payload
- `413` — oversized payload

### Example Curl
```bash
curl -X POST http://127.0.0.1:18789/hooks/wake \
  -H 'Authorization: Bearer SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"text":"New email received","mode":"now"}'

curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'x-openclaw-token: SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Summarize inbox","name":"Email","wakeMode":"next-heartbeat"}'

# Different model
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'x-openclaw-token: SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Summarize inbox","name":"Email","model":"openai/gpt-5.2-mini"}'
```

### `POST /hooks/<name>` (mapped)
Resolved via `hooks.mappings`. Options:
- `hooks.presets: ["gmail"]` — enable Gmail mapping
- `hooks.mappings` — define `match`, `action`, templates in config
- `hooks.transformsDir` + `transform.module` — JS/TS transform module
- `deliver: true` + `channel`/`to` — route replies to chat
- `agentId` — route to specific agent
- `allowUnsafeExternalContent: true` — disable safety wrapper (dangerous)

---

## Polls

### Supported Channels
- Telegram
- WhatsApp (web channel)
- Discord
- MS Teams (Adaptive Cards)

### CLI
```bash
# Telegram
openclaw message poll --channel telegram --target 123456789 \
  --poll-question "Ship it?" --poll-option "Yes" --poll-option "No"
openclaw message poll --channel telegram --target -1001234567890:topic:42 \
  --poll-question "Pick a time" --poll-option "10am" --poll-option "2pm" \
  --poll-duration-seconds 300

# WhatsApp
openclaw message poll --target +15555550123 \
  --poll-question "Lunch today?" --poll-option "Yes" --poll-option "No" --poll-option "Maybe"
openclaw message poll --target 123456789@g.us \
  --poll-question "Meeting time?" --poll-option "10am" --poll-option "2pm" --poll-multi

# Discord
openclaw message poll --channel discord --target channel:123456789 \
  --poll-question "Snack?" --poll-option "Pizza" --poll-option "Sushi"
openclaw message poll --channel discord --target channel:123456789 \
  --poll-question "Plan?" --poll-option "A" --poll-option "B" --poll-duration-hours 48

# MS Teams
openclaw message poll --channel msteams --target conversation:19:abc@thread.tacv2 \
  --poll-question "Lunch?" --poll-option "Pizza" --poll-option "Sushi"
```

**Options:**
- `--channel`: `whatsapp` (default), `telegram`, `discord`, or `msteams`
- `--poll-multi`: allow multiple selections
- `--poll-duration-hours`: Discord-only (default 24)
- `--poll-duration-seconds`: Telegram-only (5-600 seconds)
- `--poll-anonymous` / `--poll-public`: Telegram-only

### Gateway RPC
Method: `poll`
Params: `to` (required), `question` (required), `options` (required string[]), `maxSelections`, `durationHours`, `durationSeconds` (Telegram), `isAnonymous` (Telegram), `channel` (default: whatsapp), `idempotencyKey` (required)

### Channel Differences
- **Telegram**: 2-10 options; supports forum topics via `threadId` or `:topic:` targets; `durationSeconds` (5-600s); anonymous/public polls
- **WhatsApp**: 2-12 options; `maxSelections` within option count; ignores `durationHours`
- **Discord**: 2-10 options; `durationHours` clamped 1-768 (default 24); `maxSelections > 1` → multi-select
- **MS Teams**: Adaptive Card polls (no native poll API); votes recorded in `~/.openclaw/msteams-polls.json`

---

## Troubleshooting

### Command Ladder
```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe

# Automation-specific
openclaw cron status
openclaw cron list
openclaw system heartbeat last
```

### Cron Not Firing
```bash
openclaw cron status
openclaw cron list
openclaw cron runs --id <jobId> --limit 20
openclaw logs --follow
```

**Common signatures:**
- `cron: scheduler disabled; jobs will not run automatically` → disabled in config/env
- `cron: timer tick failed` → scheduler crashed; inspect log context
- `reason: not-due` → manual run without `--force` and job not due

### Cron Fired But No Delivery
```bash
openclaw cron runs --id <jobId> --limit 20
openclaw channels status --probe
```

**Common signatures:**
- Run `ok` but mode is `none` → no external message expected
- Delivery target missing/invalid → run succeeds, outbound skipped
- `unauthorized`, `missing_scope`, `Forbidden` → channel auth/permissions issue

### Heartbeat Suppressed or Skipped
```bash
openclaw system heartbeat last
openclaw config get agents.defaults.heartbeat
openclaw channels status --probe
```

**Common signatures:**
- `heartbeat skipped` with `reason=quiet-hours` → outside `activeHours`
- `requests-in-flight` → main lane busy; heartbeat deferred
- `empty-heartbeat-file` → `HEARTBEAT.md` has no actionable content
- `alerts-disabled` → visibility settings suppress outbound messages

### Timezone / activeHours Gotchas
```bash
openclaw config get agents.defaults.heartbeat.activeHours
openclaw config get agents.defaults.heartbeat.activeHours.timezone
openclaw cron list
```

- Cron without `--tz` → uses gateway host timezone
- `activeHours.timezone` unset → falls back to `userTimezone` or host timezone
- ISO timestamps without timezone → UTC for cron `at` schedules

### Auth Monitoring
```bash
openclaw models status --check
# Exit codes: 0=OK, 1=expired/missing, 2=expiring soon (within 24h)
```

---

## Gmail Pub/Sub Integration

**Goal**: Gmail watch → Pub/Sub push → `gog gmail watch serve` → OpenClaw webhook.

### Prerequisites
- `gcloud` installed + logged in
- `gogcli` installed + authorized
- OpenClaw hooks enabled
- Tailscale (supported push endpoint)

### Hook Config (enable Gmail preset)
```json5
{
  hooks: {
    enabled: true,
    token: "OPENCLAW_HOOK_TOKEN",
    path: "/hooks",
    presets: ["gmail"],
  }
}
```

### Gmail Mapping with Delivery
```json5
{
  hooks: {
    mappings: [{
      match: { path: "gmail" },
      action: "agent",
      wakeMode: "now",
      name: "Gmail",
      sessionKey: "hook:gmail:{{messages[0].id}}",
      messageTemplate: "New email from {{messages[0].from}}\nSubject: {{messages[0].subject}}\n{{messages[0].snippet}}\n{{messages[0].body}}",
      model: "openai/gpt-5.2-mini",
      deliver: true,
      channel: "last",
    }],
    gmail: {
      model: "openrouter/meta-llama/llama-3.3-70b-instruct:free",
      thinking: "off",
    }
  }
}
```

### Wizard (recommended)
```bash
openclaw webhooks gmail setup --account openclaw@gmail.com
openclaw webhooks gmail run  # manual daemon
```

### One-Time GCP Setup
```bash
gcloud auth login
gcloud config set project <project-id>
gcloud services enable gmail.googleapis.com pubsub.googleapis.com
gcloud pubsub topics create gog-gmail-watch
gcloud pubsub topics add-iam-policy-binding gog-gmail-watch \
  --member=serviceAccount:gmail-api-push@system.gserviceaccount.com \
  --role=roles/pubsub.publisher
gog gmail watch start \
  --account openclaw@gmail.com \
  --label INBOX \
  --topic projects/<project-id>/topics/gog-gmail-watch
```

### Push Handler
```bash
gog gmail watch serve \
  --account openclaw@gmail.com \
  --bind 127.0.0.1 \
  --port 8788 \
  --path /gmail-pubsub \
  --token <shared> \
  --hook-url http://127.0.0.1:18789/hooks/gmail \
  --hook-token OPENCLAW_HOOK_TOKEN \
  --include-body \
  --max-bytes 20000
```

### Cleanup
```bash
gog gmail watch stop --account openclaw@gmail.com
gcloud pubsub subscriptions delete gog-gmail-watch-push
gcloud pubsub topics delete gog-gmail-watch
```

---

## Our Setup

- **cron.failureDestination**: configured to route failures → ClawExpert Telegram channel
- **7 agents** all have heartbeats configured (see `agents.list[].heartbeat` in openclaw.json)
- Gateway port: `18789` (loopback bind)
- Hook token: stored in env, not plaintext config
- Auth monitoring: `openclaw models status --check` (exit 0/1/2)
- Brave API key: configured for `web_search`
- Main models: Anthropic API key auth (not OAuth setup-token)
