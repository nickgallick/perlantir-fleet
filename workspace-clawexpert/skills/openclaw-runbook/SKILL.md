# Skill: OpenClaw Runbook Management

## Changelog
- 2026-03-20: Cross-reference added — see openclaw-automation skill for comprehensive cron, heartbeat, hooks, webhook, poll, and automation troubleshooting
- 2026-03-19: Initial creation

## Overview
Procedures for maintaining the ClawExpert operational runbook — a living knowledge base of known issues, solutions, and patterns.

## Runbook Location
`/data/.openclaw/workspace-clawexpert/runbook/`

## Runbook Entry Format
Each entry is a markdown file named: `runbook-NNN-descriptive-name.md`

```markdown
# Runbook Entry NNN: Descriptive Title

## Date Discovered
YYYY-MM-DD

## Severity
Critical / Warning / Info

## Symptoms
What you observe when this issue occurs.

## Root Cause
Why it happens.

## Solution
Exact commands or steps to fix it.

## Prevention
How to prevent it from happening again.

## Related Entries
Links to related runbook entries.

## History
- YYYY-MM-DD: Initial discovery and documentation
- YYYY-MM-DD: Updated with additional context
```

## When to Create a New Entry
- New error type encountered that required investigation
- New failure mode discovered
- Workaround found for a known issue
- Pattern identified that could affect future operations
- Lesson learned from an incident

## When to Update an Existing Entry
- New information about root cause
- Better or faster solution found
- Additional symptoms identified
- Related entries discovered
- Prevention measures improved

## Runbook Maintenance
1. Review entries monthly for accuracy
2. Remove entries for issues fixed in newer versions
3. Cross-reference related entries
4. Keep solutions tested and current
5. Add frequency tracking (how often does this occur?)

## Current Entries
- `runbook-001-mcpservers-crash.md` — Adding mcpServers to openclaw.json crashes gateway
- `runbook-002-golden-config-restore.md` — Restoring config from golden backup

## Indexing
Keep this skill file updated with the list of current entries under "Current Entries" above. This serves as the runbook index.
