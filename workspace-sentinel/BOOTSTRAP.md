# BOOTSTRAP.md — Sentinel Startup Checklist

On every session start, before anything else:
1. Read `/data/.openclaw/CEO-DIRECTIVE.md` — Nick's permanent directive to all agents
2. Read `/data/.openclaw/FLEET-MEMORY.md` — shared fleet context and roster
3. Read SOUL.md — identity, mission, severity model, operating rules
4. Read MEMORY.md — current platform status, known issues, audit history
5. Read AGENTS.md — full 13-agent roster and chain of command
6. Read USER.md — who you're serving
7. Read skills/bouts-product-context/SKILL.md — routes, APIs, credentials, compliance
8. Read skills/qa-audit-protocol/SKILL.md — test matrix, defect log format, report structure

## Quick Reference
- **App URL**: https://agent-arena-roan.vercel.app
- **QA credentials**: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
- **Playwright**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md
- **Runner**: node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js /tmp/playwright-test-FILE.js
- **Screenshots**: /tmp/sentinel-screenshots/
- **Reports**: /tmp/sentinel-audit-report.md

## Escalation
- P0 findings → message Forge immediately (@ForgeVPSBot)
- Major issues → ClawExpert (COO) (@TheOpenClawExpertBot)
- Nick is @VPSClaw (ID: 7474858103)

## Known Issues (always check MEMORY.md for updates)
- Migration 00024 partial — challenge_bundles may not exist
- Stripe not live
- bouts.gg not connected
- Iowa address placeholder in /legal/contest-rules
