# Skill: OpenClaw Troubleshooting

## Changelog
- 2026-03-19: Initial creation

## Overview
Systematic troubleshooting procedures for OpenClaw issues. Always start with log inspection.

## Troubleshooting Protocol
1. **Check logs first** — Always. No exceptions.
2. **Identify the layer** — Is it container, config, auth, network, or application?
3. **Check recent changes** — What changed since it last worked?
4. **Isolate the issue** — Narrow down to specific component
5. **Fix and verify** — Apply fix, check logs again, confirm resolution
6. **Document** — Add to runbook if it's a new issue

## Decision Tree

### System Won't Start
```
Container down?
├── Yes → docker logs openclaw-okny-openclaw-1
│   ├── JSON parse error → Config file corrupted → Restore backup
│   ├── Zod validation error → Invalid key in openclaw.json → Remove key
│   ├── Port already in use → Another process using port → Kill or change port
│   ├── Image not found → Pull image again
│   └── OOM killed → Increase memory limit
└── No (container running but not responding)
    ├── Check process: docker exec openclaw-okny-openclaw-1 ps aux
    ├── Check memory: docker stats --no-stream openclaw-okny-openclaw-1
    └── Check connectivity: curl the API endpoints
```

### Agent Not Responding
```
Agent not responding?
├── Check if agent is configured in openclaw.json
├── Check model identifier is correct
├── Check logs for agent-specific errors
├── Check API key validity
├── Check rate limits
└── Restart container as last resort
```

### Telegram Bot Not Working
```
Bot not responding to messages?
├── Check bot token is valid (not revoked)
├── Check chatId is correct
├── Check allowedUsers includes the user
├── Check logs for Telegram errors
├── Check Telegram API connectivity
│   └── docker exec openclaw-okny-openclaw-1 curl -s https://api.telegram.org/bot<token>/getMe
└── Check webhook vs polling mode
```

### MCP Tools Not Working
```
MCP tools unavailable?
├── Is mcporter running?
│   └── docker exec openclaw-okny-openclaw-1 ps aux | grep mcporter
├── Check mcporter logs
├── Is the MCP server configured in mcporter (NOT openclaw.json)?
├── Check API keys for MCP services (e.g., BRAVE_API_KEY)
└── Restart mcporter bridge
```

### High Memory Usage
```
Memory usage high?
├── Check what's using memory: docker stats --no-stream
├── Check for large workspaces: du -sh /data/.openclaw/workspace*
├── Check for log accumulation
├── Restart container to free memory
└── If persistent: may need to increase container memory limit
```

## Unrecognized Key Crash Fix
**Symptom**: Gateway crashes on startup with Zod validation error about an unrecognized key.
**Cause**: Invalid/unknown key in openclaw.json (e.g., `mcpServers`, `mcp`, `customBindHost`, or any typo).
**Fix**:
```bash
# 1. Identify the bad key from logs
docker logs --tail 30 openclaw-okny-openclaw-1 2>&1 | grep -i "unrecognized\|unknown\|invalid"

# 2. Remove the key using python3
python3 -c "
import json
with open('/data/.openclaw/openclaw.json') as f:
    config = json.load(f)
del config['BAD_KEY_NAME']  # Replace BAD_KEY_NAME with the actual key
with open('/data/.openclaw/openclaw.json', 'w') as f:
    json.dump(config, f, indent=2)
print('Key removed successfully')
"

# 3. Restart
docker restart openclaw-okny-openclaw-1

# 4. Check logs
docker logs --tail 20 openclaw-okny-openclaw-1
```

## Known Harmless Warnings
These appear in logs but are NOT problems:
- `nostr module missing` — Nostr integration not installed, not needed
- `apply_patch` entries — Normal patch operation logs
- `autoSelectFamily` — Node.js DNS resolution deprecation warning, harmless

## Emergency Procedures

### Config Corrupted — Quick Restore
```bash
# Find most recent backup
ls -la /data/.openclaw/openclaw.json.backup.* | tail -5

# Restore
cp /data/.openclaw/openclaw.json.backup.<latest> /data/.openclaw/openclaw.json

# Restart
docker restart openclaw-okny-openclaw-1

# Verify
docker logs --tail 20 openclaw-okny-openclaw-1
```

### Container Won't Stop
```bash
# Graceful stop (10s timeout)
docker stop openclaw-okny-openclaw-1

# Force kill if stuck
docker kill openclaw-okny-openclaw-1

# Remove and recreate if needed
docker rm openclaw-okny-openclaw-1
# Then recreate using docker-compose or original run command
```

### Complete System Recovery
```bash
# 1. Stop everything
docker stop openclaw-okny-openclaw-1

# 2. Restore config from backup
cp /data/.openclaw/openclaw.json.backup.<known-good> /data/.openclaw/openclaw.json

# 3. Verify config
cat /data/.openclaw/openclaw.json | python3 -m json.tool

# 4. Start
docker start openclaw-okny-openclaw-1

# 5. Watch logs
docker logs -f openclaw-okny-openclaw-1
```
