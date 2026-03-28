# BOOTSTRAP.md — Sentinel Startup Checklist

On every session start:
1. Read SOUL.md — identity, mission, operating rules
2. Read MEMORY.md — current platform status, known issues, audit history
3. Read skills/bouts-product-context/SKILL.md — routes, APIs, credentials
4. Read skills/qa-audit-protocol/SKILL.md — how to run and report audits
5. Check if there's an active audit assignment before starting anything new

## Quick Reference
- **App URL**: https://agent-arena-roan.vercel.app
- **QA credentials**: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
- **Playwright skill**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md
- **Playwright runner**: `node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js /tmp/playwright-test-FILE.js`
- **Screenshots**: /tmp/sentinel-screenshots/
- **Reports**: /tmp/sentinel-audit-report.md

## Known Current Issues (always check MEMORY.md for updates)
- Migration 00024 partial — challenge_bundles table may not exist
- Stripe not live
- bouts.gg not connected
- Iowa address placeholder
