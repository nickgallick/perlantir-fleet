# 003 — Config Crash: Source Code Ahead of Running Binary

**Date:** 2026-03-20
**Severity:** Critical
**Caused by:** ClawExpert (direct config write without version verification)

## What Happened
ClawExpert added `thinkingDefault: "adaptive"` and `subagents: { maxConcurrent: 4 }` directly to openclaw.json for the Forge agent. These keys were read from the cloned `repos/openclaw` source (v2026.3.14). Our running binary is **v2026.3.13**. These keys do not exist in 3.13's Zod schema. Gateway exited with code 1.

Docker logs showed:
```
Invalid config at openclaw.json:
- agents.list.5.subagents: Unrecognized key: maxConcurrent
- agents.list.5: Unrecognized key: thinkingDefault
OpenClaw exited with code 1
```

Nick had to manually remove the keys and restart the container from the host.

## Root Cause — Two Failures

**Failure 1:** ClawExpert wrote directly to openclaw.json.
ClawExpert must never write to openclaw.json. It recommends changes. Nick or Maks applies them. ClawExpert verifies after.

**Failure 2:** Keys read from source repo were assumed valid for the running binary.
The cloned repo is v2026.3.14 (HEAD). The running container is v2026.3.13. Any key introduced in 3.14 will crash 3.13. ClawExpert did not check which version introduced these keys before applying them.

## Correct Facts
- **Running version:** 2026.3.13
- **Source repo version:** 2026.3.14 (HEAD)
- **Keys that crashed:** `thinkingDefault` (agent entry), `subagents.maxConcurrent` (agent entry)
- **Recovery:** Nick manually removed keys from host, restarted container

## Permanent Rules (added 2026-03-20)

### Rule 1: ClawExpert NEVER writes to openclaw.json directly
- Analyze the current config ✅
- Recommend exact changes with before/after ✅
- Verify the config is valid after Nick/Maks applies ✅
- Write to openclaw.json directly ❌ Never

### Rule 2: Never add config keys from source without version verification
Before recommending ANY new config key found in `repos/openclaw/src/config/`:
1. Check when it was introduced: `git log --oneline repos/openclaw/src/config/zod-schema*.ts`
2. Compare the introducing commit/tag against our running version (2026.3.13)
3. Only recommend the key if it existed in 3.13 or earlier
4. If the key is newer: document it, note "available after upgrade to 3.14", do NOT recommend applying

## Keys Confirmed Broken in 3.13
- `agents.list[n].thinkingDefault` — introduced in 3.14
- `agents.list[n].subagents.maxConcurrent` — introduced in 3.14

## How to Recommend a Config Change (correct process)
```
Recommended change to openclaw.json:
BEFORE: { ... }
AFTER:  { ... }
Risk: [low/medium/high]
Schema source: [which zod-schema file + line]
Verified exists in 3.13: [yes/no]
```
Nick or Maks applies. ClawExpert then verifies with `openclaw doctor` or gateway response check.
