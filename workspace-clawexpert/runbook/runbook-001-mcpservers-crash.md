# Runbook Entry 001: mcpServers Key Crashes Gateway

## Date Discovered
2026-03-19

## Severity
Critical

## Symptoms
- OpenClaw gateway fails to start
- Container enters crash loop (restart loop)
- Logs show Zod schema validation error
- Error message references unexpected key `mcpServers` in configuration
- All agents become unresponsive simultaneously

## Root Cause
The `openclaw.json` configuration file is validated against a strict Zod schema on gateway startup. The `mcpServers` key is NOT part of this schema. When present, Zod's strict validation rejects the entire config file, preventing the gateway from initializing.

This commonly happens when:
1. Following generic MCP documentation that suggests adding `mcpServers` to config
2. An AI agent suggests adding MCP server configuration directly to openclaw.json
3. Copying config examples from other platforms that support native mcpServers

## Solution

### Immediate Fix
```bash
# Step 1: Check if mcpServers is the cause
docker logs --tail 30 openclaw-okny-openclaw-1 2>&1 | grep -i "zod\|validation\|mcpServers"

# Step 2: Backup the broken config
cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.broken.$(date +%Y%m%d%H%M%S)

# Step 3: Remove the mcpServers key
python3 -c "
import json
with open('/data/.openclaw/openclaw.json', 'r') as f:
    config = json.load(f)
if 'mcpServers' in config:
    del config['mcpServers']
    with open('/data/.openclaw/openclaw.json', 'w') as f:
        json.dump(config, f, indent=2)
    print('Removed mcpServers key')
else:
    print('mcpServers key not found')
"

# Step 4: Validate the fixed config
cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1 && echo "Config valid" || echo "Config still invalid"

# Step 5: Restart the gateway
docker restart openclaw-okny-openclaw-1

# Step 6: Verify startup
docker logs --tail 20 openclaw-okny-openclaw-1
```

### Alternative: Restore from Backup
```bash
# Find most recent good backup
ls -la /data/.openclaw/openclaw.json.backup.* | tail -5

# Restore it
cp /data/.openclaw/openclaw.json.backup.<latest-good> /data/.openclaw/openclaw.json

# Restart
docker restart openclaw-okny-openclaw-1
```

## ⚠️ CORRECTION (2026-03-19) — Partial Fix to Original Entry

**Original belief**: `mcpServers` is never valid in openclaw.json.
**Truth from source code**: The correct key is `mcp.servers` (NOT `mcpServers`). Reading `zod-schema.ts` confirmed:
- `mcpServers` (root level) = INVALID → causes Zod crash ✅ (original runbook correct)
- `mcp.servers` (nested) = VALID → supported native stdio MCP

**The real prevention rule:** Never use `mcpServers` (root key). Use `mcp.servers` for native stdio MCP, or mcporter bridge for MCP management.

## Prevention
1. **NEVER add `mcpServers` as a root key** — causes Zod strict validation crash
2. For native stdio MCP: use `mcp.servers` (nested, valid in schema)
3. For managed MCP: use mcporter bridge (recommended for complex setups)
4. Before editing openclaw.json, always backup first
5. After editing, always validate JSON before restarting

## The Correct Ways to Add MCP Servers
```json
// ✅ VALID — native stdio MCP
{
  "mcp": {
    "servers": {
      "my-server": {
        "command": "npx",
        "args": ["-y", "my-mcp-server"]
      }
    }
  }
}

// ❌ INVALID — crashes gateway
{
  "mcpServers": { ... }
}
```
See `skills/openclaw-mcp/SKILL.md` for mcporter bridge details.

## Related Entries
- `runbook-002-golden-config-restore.md` — How to restore config from backup

## History
- 2026-03-19: Initial discovery and documentation
