# Skill: OpenClaw Health Checks

## Changelog
- 2026-03-19: Initial creation

## Overview
Systematic health check procedures for the OpenClaw deployment. These checks are run during Phase 1 of every heartbeat cycle.

## Quick Health Check (30 seconds)
```bash
# One-liner health check
docker ps --filter name=openclaw --format "{{.Status}}" && \
df -h /data --output=pcent | tail -1 && \
docker logs --tail 5 openclaw-okny-openclaw-1 2>&1 | grep -i -c error
```

## Full Health Check Suite

### 1. Container Status
```bash
docker ps --filter name=openclaw --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
**Expected**: Container `openclaw-okny-openclaw-1` shows "Up" with healthy uptime
**Failure**: Container not listed → Critical, start immediately
**Failure**: Status shows "Restarting" → Critical, check logs for crash loop

### 2. Disk Usage
```bash
df -h /data
du -sh /data/.openclaw/ 2>/dev/null
du -sh /data/.openclaw/workspace* 2>/dev/null
```
**Thresholds**:
- < 80% → ✅ Healthy
- 80-90% → ⚠️ Warning — plan cleanup
- \> 90% → 🚨 Critical — clean immediately

**Cleanup targets** (safest first):
1. Old backup files: `ls -la /data/.openclaw/openclaw.json.backup.*`
2. Docker build cache: `docker system prune -f`
3. Old logs: `docker logs` output is managed by Docker

### 3. Memory Usage
```bash
free -h
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" openclaw-okny-openclaw-1
```
**Thresholds**:
- < 70% → ✅ Healthy
- 70-90% → ⚠️ Warning — monitor trend
- \> 90% → 🚨 Critical — restart container, investigate cause

### 4. Config Integrity
```bash
cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1 && echo "✅ Config valid" || echo "🚨 Config INVALID"
```
**Failure**: Invalid JSON → Critical, restore from backup immediately

### 5. API Connectivity
```bash
# Test Anthropic API reachability
docker exec openclaw-okny-openclaw-1 curl -s -o /dev/null -w "%{http_code}" \
  https://api.anthropic.com/v1/messages \
  -H "x-api-key: test" \
  -H "anthropic-version: 2023-06-01" 2>/dev/null
```
**Expected**: 401 (API reachable, auth rejected as expected with test key)
**Failure**: 000 or timeout → Network issue
**Failure**: 403 → API key may be revoked

### 6. Process Health
```bash
docker exec openclaw-okny-openclaw-1 ps aux 2>/dev/null | head -20
docker logs --tail 5 openclaw-okny-openclaw-1 2>&1
```
**Check for**: Zombie processes, OOM kills, segfaults, abnormal process count

## Health Report Format
```
📊 Health Check Results
├── Container: [✅/⚠️/🚨] [status details]
├── Disk: [✅/⚠️/🚨] [usage %]
├── Memory: [✅/⚠️/🚨] [usage %]
├── Config: [✅/🚨] [valid/invalid]
├── API: [✅/⚠️/🚨] [reachable/unreachable]
└── Processes: [✅/⚠️/🚨] [normal/abnormal]
```

## Severity Summary

**CRITICAL** — Immediate action required:
- Container down or crash-looping
- Config invalid (JSON parse error or Zod validation failure)
- Auth broken (API key revoked or missing)
- Disk usage > 90%

**WARNING** — Monitor and plan remediation:
- Memory usage > 70%
- Disk usage > 80%
- Logs > 500MB accumulated
- Unexpected container restart
- Missing bot (expected agent not responding)

**INFO** — No action needed:
- Normal resource fluctuations
- Minor log warnings (nostr, autoSelectFamily, apply_patch)

## Escalation Matrix
| Check | Warning | Critical |
|-------|---------|----------|
| Container | Restarted recently | Down or crash-looping |
| Disk | > 80% used | > 90% used |
| Memory | > 70% container limit | > 90% container limit |
| Config | Drift from backup | Invalid JSON |
| API | Intermittent failures | Persistent unreachable |
| Processes | High count | Zombies or OOM |
