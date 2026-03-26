# Skill: OpenClaw Config Audit

## Changelog
- 2026-03-19: Initial creation

## Overview
Procedures for auditing openclaw.json to ensure correctness, security, and compliance with the Zod schema.

## Audit Checklist

### 1. JSON Validity
```bash
cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
```

### 2. Schema Compliance
Check for forbidden keys that will crash the gateway:
- `mcpServers` — MUST NOT exist (use mcporter bridge)
- Any unknown top-level key — MUST NOT exist (Zod rejects them)
- Verify only known keys are present: `name`, `description`, `url`, `model`, `channels`, `auth`, `agents`, `plugins`, `systemPrompt`, `workspace`

### 3. Channel Audit
For each channel in the `channels` array:
- [ ] `type` is valid (e.g., "telegram")
- [ ] `botToken` is present and not empty
- [ ] `botToken` format looks valid (not truncated)
- [ ] `chatId` is present
- [ ] `allowedUsers` includes owner ID `7474858103`
- [ ] `agent` references a valid agent name

### 4. Agent Audit
For each agent in the `agents` array:
- [ ] `name` is present and unique
- [ ] `model` uses valid identifier format (`provider/model-name`)
- [ ] `workspace` path exists on disk
- [ ] `systemPrompt` file exists (if path reference)

### 5. Auth Audit
- [ ] `auth` section exists
- [ ] `type` is "token"
- [ ] `provider` is "anthropic"
- [ ] `apiKey` is present and not empty
- [ ] `apiKey` starts with expected prefix

### 6. Security Audit
- [ ] No API keys duplicated or exposed in logs
- [ ] `allowedUsers` is not empty on any channel (prevents open access)
- [ ] Bot tokens are not shared across environments
- [ ] No plaintext passwords in config

## Audit Procedure
```bash
# Step 1: Backup before any changes
cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.backup.$(date +%Y%m%d%H%M%S)

# Step 2: Validate JSON
cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1

# Step 3: Check for forbidden keys
python3 -c "
import json
with open('/data/.openclaw/openclaw.json') as f:
    config = json.load(f)
forbidden = ['mcpServers']
known = ['name','description','url','model','channels','auth','agents','plugins','systemPrompt','workspace']
for key in config:
    if key in forbidden:
        print(f'CRITICAL: Forbidden key found: {key}')
    elif key not in known:
        print(f'WARNING: Unknown key found: {key}')
    else:
        print(f'OK: {key}')
"

# Step 4: Check workspace paths exist
# (read config, extract workspace paths, verify with ls)
```

## Drift Detection with MD5
```bash
# Generate MD5 hash of current config
md5sum /data/.openclaw/openclaw.json

# Save hash for future comparison
md5sum /data/.openclaw/openclaw.json > /data/.openclaw/workspace-clawexpert/config-audit-history/config-hash-$(date +%Y%m%d%H%M%S).md5

# Compare to last saved hash
LATEST_HASH=$(ls -t /data/.openclaw/workspace-clawexpert/config-audit-history/config-hash-*.md5 2>/dev/null | head -1)
if [ -n "$LATEST_HASH" ]; then
    md5sum -c "$LATEST_HASH" 2>/dev/null && echo "✅ Config unchanged" || echo "⚠️ Config has changed"
else
    echo "No previous hash found — saving initial hash"
    mkdir -p /data/.openclaw/workspace-clawexpert/config-audit-history
    md5sum /data/.openclaw/openclaw.json > /data/.openclaw/workspace-clawexpert/config-audit-history/config-hash-$(date +%Y%m%d%H%M%S).md5
fi
```
If config changed and ClawExpert didn't make the change → flag as unexpected modification and investigate.

## Diff Against Backup
```bash
# Compare current config to most recent backup
diff <(python3 -m json.tool /data/.openclaw/openclaw.json) <(python3 -m json.tool /data/.openclaw/openclaw.json.backup.<latest>)
```

## Automated Config Validation Script
```bash
#!/bin/bash
echo "=== OpenClaw Config Audit ==="
CONFIG="/data/.openclaw/openclaw.json"

# JSON validity
if python3 -m json.tool "$CONFIG" > /dev/null 2>&1; then
    echo "✅ JSON: Valid"
else
    echo "❌ JSON: INVALID - CRITICAL"
    exit 1
fi

# Forbidden keys
if python3 -c "import json; c=json.load(open('$CONFIG')); exit(1 if 'mcpServers' in c else 0)" 2>/dev/null; then
    echo "✅ No mcpServers key"
else
    echo "❌ mcpServers found - CRITICAL - Remove immediately"
fi

echo "=== Audit Complete ==="
```
