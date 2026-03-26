# Skill: OpenClaw Log Analysis

## Changelog
- 2026-03-19: Initial creation

## Overview
Procedures for analyzing OpenClaw container logs to detect issues, patterns, and anomalies.

## Log Access
```bash
# All logs
docker logs openclaw-okny-openclaw-1

# Recent logs (last N lines)
docker logs --tail 100 openclaw-okny-openclaw-1

# Time-bounded logs
docker logs --since 1h openclaw-okny-openclaw-1
docker logs --since "2026-03-19T12:00:00" openclaw-okny-openclaw-1

# Follow live
docker logs -f openclaw-okny-openclaw-1

# Both stdout and stderr
docker logs openclaw-okny-openclaw-1 2>&1
```

## Error Classification

### Critical Errors (Act Immediately)
- `FATAL` / `fatal` — Process is crashing
- `ENOENT` on config files — Config missing or moved
- `EACCES` — Permission denied, process can't access needed files
- `OOMKilled` — Out of memory, container killed
- `Zod` / `validation` errors — Config schema violation
- `ETIMEDOUT` on API calls — Network connectivity lost
- Connection refused to Anthropic API — Auth or network issue

### Warning Errors (Monitor)
- `ECONNRESET` — Connection reset, usually transient
- `429` / `rate limit` — API rate limiting, may need throttling
- `timeout` — Slow responses, may indicate overload
- Memory usage warnings — Approaching limits

### Known Harmless (Ignore)
- `nostr module missing` — Nostr not installed, not needed
- `apply_patch` entries — Normal operation
- `autoSelectFamily` — Node.js deprecation warning, harmless
- `ExperimentalWarning` — Node.js experimental feature warnings

## Analysis Procedures

### Error Scan
```bash
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i -E "error|exception|fatal|crash|panic|ENOENT|EACCES|ETIMEDOUT" | grep -v -E "nostr|apply_patch|autoSelectFamily" | tail -30
```

### Warning Scan
```bash
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i "warn" | grep -v -E "nostr|apply_patch|autoSelectFamily" | tail -20
```

### Activity Analysis
```bash
# Message throughput
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -c -i "message"

# API call frequency
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -c -i "anthropic\|api.*call"

# Agent activity
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i -E "agent|maks|scout|clawexpert|makspm" | tail -20
```

### Pattern Detection
```bash
# Repeated errors (potential loop)
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i error | sort | uniq -c | sort -rn | head -10

# Error frequency over time
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i error | awk '{print $1}' | sort | uniq -c
```

## Log Analysis Checklist
1. [ ] Run error scan — any new error types?
2. [ ] Run warning scan — any increasing warnings?
3. [ ] Check activity levels — any agents silent?
4. [ ] Check for repeated errors — any error loops?
5. [ ] Compare to baseline — anything unusual?
6. [ ] Update runbook with any new patterns found

## Escalation Rules
- New error type never seen before → Investigate immediately, add to runbook
- Error count > 10 in 1 hour → Warning level escalation
- Error count > 50 in 1 hour → Critical level escalation
- Any `FATAL` or `OOM` → Critical, immediate action
- API connectivity errors → Warning, check in 5 minutes, escalate if persistent
