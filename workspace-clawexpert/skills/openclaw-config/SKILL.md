# Skill: OpenClaw Configuration

## Changelog
- 2026-03-20: Cross-reference added — see openclaw-gateway-deep skill for full gateway config, heartbeat, sandboxing, secrets, auth, troubleshooting
- 2026-03-20: Added CRITICAL version mismatch warning — see runbook-003
- 2026-03-19: Initial creation

## ⚠️ CRITICAL: Source Code ≠ Running Binary

**Our repos/openclaw is v2026.3.14. Our running container is v2026.3.12.**

NEVER add a config key found in the source repo without first verifying it exists in the RUNNING version.

Keys in 3.14 that are NOT in 3.12 (will crash gateway):
- `thinkingDefault` (agent entry level)
- `subagents.maxConcurrent` (agent entry level)

Before adding any new key from source:
1. `git log --oneline src/config/zod-schema*.ts | head -20` — find when it was added
2. Compare tag to our running version
3. If newer than 3.12 → document it, wait for update, do NOT add yet

See runbook-003 for full incident details.

## Overview
Deep knowledge of openclaw.json structure, valid keys, and configuration patterns.

## Config File Location
`/data/.openclaw/openclaw.json`

## Valid Top-Level Keys
The openclaw.json file is validated by a Zod schema. Only these keys are allowed:
- `name` — Instance name (string)
- `description` — Instance description (string)
- `url` — Instance URL (string)
- `model` — Default model identifier (string)
- `channels` — Array of channel configurations
- `auth` — Authentication configuration
- `agents` — Array of agent configurations
- `plugins` — Plugin configurations
- `systemPrompt` — Global system prompt (string)
- `workspace` — Workspace path (string)

### Exhaustive List of Valid Root-Level Keys
`plugins`, `tools`, `channels`, `meta`, `wizard`, `update`, `browser`, `auth`, `models`, `agents`, `bindings`, `commands`, `session`, `hooks`, `gateway`, `env`, `secrets`, `skills`, `cron`, `ui`, `discovery`, `logging`, `$schema`

### Known INVALID Keys (will crash the gateway)
- `mcpServers` — NEVER use, crashes on startup
- `mcp` — NEVER use, not a valid key
- `customBindHost` — NEVER use, not recognized by schema

## CRITICAL WARNINGS
1. **NEVER add unknown keys** — The Zod schema will reject them and crash the gateway on startup
2. **NEVER add `mcpServers`** — MCP must be configured via mcporter bridge only
3. **Always backup before editing**: `cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.backup.$(date +%Y%m%d%H%M%S)`

## Config Change Procedure
1. Backup current config
2. Show BEFORE state (relevant section)
3. Make change
4. Validate JSON: `cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null`
5. Show AFTER state (relevant section)
6. Restart if needed: `docker restart openclaw-okny-openclaw-1`
7. Verify logs for startup errors: `docker logs --tail 20 openclaw-okny-openclaw-1`

## Channel Configuration
```json
{
  "type": "telegram",
  "botToken": "BOT_TOKEN_HERE",
  "chatId": "CHAT_ID",
  "allowedUsers": ["7474858103"],
  "agent": "agent-name"
}
```

## Agent Configuration
```json
{
  "name": "agent-name",
  "model": "anthropic/claude-sonnet-4-6",
  "workspace": "/data/.openclaw/workspace-agentname",
  "systemPrompt": "Path or inline prompt"
}
```

## Auth Configuration
```json
{
  "auth": {
    "type": "token",
    "provider": "anthropic",
    "apiKey": "ANTHROPIC_API_KEY"
  }
}
```

## Model Identifiers
- `anthropic/claude-sonnet-4-6` — Sonnet (fast, capable, cost-effective)
- `anthropic/claude-opus-4-6` — Opus (most capable, slower, expensive)
- `anthropic/claude-haiku-4-5` — Haiku (fastest, cheapest, less capable)

## Common Mistakes
1. Adding `mcpServers` key → crashes gateway (use mcporter instead)
2. Adding custom keys for "notes" or "metadata" → crashes gateway
3. Malformed JSON (missing comma, trailing comma) → gateway won't start
4. Wrong model identifier format → agent fails to respond
5. Missing `allowedUsers` → anyone can message the bot

---

## IMPORTANT: gateway.remote.token behaviour (researched 2026-03-19)

### What gateway.remote.token actually is
`gateway.remote.token` is the token that **CLI clients use to connect to a remote gateway**. It is NOT the gateway server's own auth token. It is the *client-side credential* for when you run `openclaw status` or other CLI commands against a remote instance.

### Why it always equals gateway.auth.token in our setup
The onboard wizard intentionally sets `gateway.remote.token = gateway.auth.token` so that CLI commands can connect to the gateway without extra configuration. This is correct and expected behaviour for a local setup.

**The real reason our token "reverted":** The `OPENCLAW_GATEWAY_TOKEN` environment variable is set in the container to the same token value. The credential planner reads this env var and uses it as the remote token when resolving credentials — effectively overriding what we write to the file.

### The correct mental model
| Key | Purpose |
|-----|---------|
| `gateway.auth.token` | Server-side: what clients must present to authenticate |
| `gateway.remote.token` | Client-side: what the CLI uses to connect to a remote gateway |
| `OPENCLAW_GATEWAY_TOKEN` env | Runtime override for the remote token, takes precedence over config |

**For a local setup (our case):** having them the same is correct and intentional. The separation matters only if you have a separate remote gateway that uses a different token from the local one.

### Conclusion
Fix #5 (separating the tokens) was INCORRECT for our setup. They are supposed to be the same value. The original config was right. No action needed.
