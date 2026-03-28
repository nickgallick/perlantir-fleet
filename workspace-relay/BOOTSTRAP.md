# BOOTSTRAP.md — Relay Startup Checklist

On every session start:
1. Read `/data/.openclaw/CEO-DIRECTIVE.md` — Nick's permanent directive to all agents
2. Read `/data/.openclaw/FLEET-MEMORY.md` — shared fleet context and roster
3. Read SOUL.md — identity, mission, test layers, operating rules
4. Read MEMORY.md — automation state, flake tracker, regression history
5. Read AGENTS.md — full 13-agent roster and chain of command
6. Read USER.md — who you're serving
7. Read COVERAGE_MATRIX_TEMPLATE.md — current coverage state
8. Read TEST_DATA_AND_ROLES.md — accounts, fixtures, seeded data

## Quick Reference
- **App URL**: https://agent-arena-roan.vercel.app
- **QA credentials**: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
- **Playwright skill**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md
- **Runner**: `node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js /tmp/playwright-test-FILE.js`
- **Scripts**: /tmp/playwright-test-relay-*.js
- **Screenshots**: /tmp/relay-screenshots/
- **Reports**: /tmp/relay-automation-report-YYYYMMDD.md

## Escalation
- P0 automation findings → Forge immediately (@ForgeVPSBot)
- Coverage gaps or strategy → ClawExpert (@TheOpenClawExpertBot)
- Nick is @VPSClaw (ID: 7474858103)

## QA Team Coordination
- **Sentinel** = functional QA → when they find bugs, ask: should this be a regression test?
- **Polish** = product quality → when they find browser-visible issues, ask: can automation catch this?
- **Aegis** = security → when they find role-boundary issues, ask: can this be a role-based regression?

## Script Naming Convention
/tmp/playwright-test-relay-[layer]-[domain]-[YYYYMMDD].js
- Smoke: relay-smoke-public-20260329.js
- Critical path: relay-critical-auth-20260329.js
- Regression: relay-regression-challenge-entry-20260329.js

## Project State
Read HANDOFF.md for current audit/project state before starting any task.
After every session, update HANDOFF.md with results, findings, and next steps.
