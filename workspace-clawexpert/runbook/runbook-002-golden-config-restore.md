# Runbook Entry 002: Golden Config Restore

## Date Discovered
2026-03-19

## Severity
Critical (when needed — this is the emergency recovery procedure)

## Symptoms
- Gateway won't start due to config errors
- Config file corrupted (invalid JSON)
- Unknown keys added that crash Zod validation
- Config accidentally overwritten with wrong content
- Agents behaving incorrectly due to config changes

## Root Cause
Configuration file (`/data/.openclaw/openclaw.json`) has been modified in a way that prevents normal operation. This can happen due to:
1. Manual editing mistakes (syntax errors, missing commas, trailing commas)
2. AI agents adding unsupported keys (e.g., `mcpServers`)
3. Incomplete writes (power loss, disk full during write)
4. Accidental overwrite by another process
5. Well-intentioned but incorrect "improvements" to config

## Solution

### Step 1: Identify Available Backups
```bash
# List all config backups, newest first
ls -lt /data/.openclaw/openclaw.json.backup.* 2>/dev/null

# If no backups exist, check for Docker volume backups
ls -lt /data/.openclaw/*.json* 2>/dev/null
```

### Step 2: Validate the Backup Before Restoring
```bash
# Pick a backup and validate it
cat /data/.openclaw/openclaw.json.backup.<timestamp> | python3 -m json.tool > /dev/null 2>&1 && echo "Backup valid" || echo "Backup also invalid"

# Check it doesn't have forbidden keys
python3 -c "
import json
with open('/data/.openclaw/openclaw.json.backup.<timestamp>') as f:
    config = json.load(f)
forbidden = ['mcpServers']
for key in config:
    if key in forbidden:
        print(f'WARNING: Backup contains forbidden key: {key}')
print('Backup key check complete')
"
```

### Step 3: Save Current (Broken) Config
```bash
# Save the broken config for analysis
cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.broken.$(date +%Y%m%d%H%M%S)
```

### Step 4: Restore the Backup
```bash
# Restore the validated backup
cp /data/.openclaw/openclaw.json.backup.<timestamp> /data/.openclaw/openclaw.json

# Final validation
cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1 && echo "Restored config valid" || echo "ERROR: Restored config invalid"
```

### Step 5: Restart and Verify
```bash
# Restart the gateway
docker restart openclaw-okny-openclaw-1

# Watch startup logs
docker logs --tail 30 openclaw-okny-openclaw-1

# Verify container is healthy
docker ps --filter name=openclaw --format "table {{.Names}}\t{{.Status}}"
```

### Step 6: Post-Restore Verification
```bash
# Verify all agents are responding (check logs for agent activity)
docker logs --tail 50 openclaw-okny-openclaw-1 2>&1 | grep -i -E "agent|ready|started"

# Verify Telegram bots are connected
docker logs --tail 50 openclaw-okny-openclaw-1 2>&1 | grep -i telegram

# Verify MCP tools are available
docker logs --tail 50 openclaw-okny-openclaw-1 2>&1 | grep -i -E "mcp|mcporter|tool"
```

## Prevention
1. **Always backup before editing config**:
   ```bash
   cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.backup.$(date +%Y%m%d%H%M%S)
   ```
2. **Maintain a "golden" known-good config**:
   ```bash
   cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.golden
   ```
3. **Validate after every edit**:
   ```bash
   cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1
   ```
4. **Show BEFORE and AFTER** for every config change
5. **Use the config audit skill** to validate schema compliance

## Creating a Golden Backup
When the system is running well and all agents are healthy:
```bash
# Create timestamped golden backup
cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.golden.$(date +%Y%m%d)

# Verify it
cat /data/.openclaw/openclaw.json.golden.$(date +%Y%m%d) | python3 -m json.tool > /dev/null && echo "Golden backup created and validated"
```

## Related Entries
- `runbook-001-mcpservers-crash.md` — Common cause of config corruption

## History
- 2026-03-19: Initial documentation of golden config restore procedure
