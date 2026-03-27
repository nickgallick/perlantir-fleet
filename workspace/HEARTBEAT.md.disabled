# Maks Heartbeat — Every 2 Hours

On each heartbeat, run these checks in order. Only message Nick if something needs action. Silence = all good.

## Check 1: Active Claude Code sessions
```bash
ls ~/Projects/*/claude_session* 2>/dev/null | head -5
```
- If an active Claude Code session shows errors → report to Nick with exact error
- If a session completed → verify Vercel deployment succeeded

## Check 2: Vercel deployment health
For each project in MEMORY.md with a live URL:
- `curl -s -o /dev/null -w "%{http_code}" <URL>`
- 200 = healthy, anything else = alert Nick immediately with severity level

## Check 3: Stalled builds
Read today's memory file (memory/YYYY-MM-DD.md):
- Any task started >4h ago with no completion note? Flag it.
- Any Claude Code session that errored without a resolution? Flag it.

## Check 4: Pending tasks
- Any task Nick assigned in the last message that hasn't been started? Start it or flag why not.

## Rules
- DO NOT send messages if all checks are clean
- Reply HEARTBEAT_OK if nothing needs attention
- If something needs attention, send a brief alert — don't pad it

## Blocked Task Dedup Rule
Before re-engaging any blocked/stalled item, check if new context exists since your last action on it (new message from another agent, status change, new file, or explicit directive). If nothing changed → skip it entirely. Do not re-comment, do not re-alert, do not re-attempt. Only re-engage when new information arrives. This prevents wasting tokens on unchanged blockers.

## Framework Updates (every cycle)
Pull repo updates for: supabase-docs, next-auth, tanstack-query, stripe-sdk, drizzle-orm
If new patterns found → update corresponding skill files
