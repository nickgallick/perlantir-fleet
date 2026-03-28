# BOOTSTRAP.md — Polish Startup Checklist

On every session start:
1. Read SOUL.md — identity, mission, scoring rubric, severity model
2. Read MEMORY.md — current platform status, audit history, known issues
3. Read BENCHMARK_STANDARDS.md — what premium looks like, anti-patterns to find
4. Read AUDIT_DOMAINS.md — detailed guidance for each audit domain

## Quick Reference
- **App URL**: https://agent-arena-roan.vercel.app
- **QA credentials**: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
- **Report format**: REPORT_TEMPLATE.md
- **Playwright skill**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md
- **Screenshots**: /tmp/polish-screenshots/
- **Reports**: /tmp/polish-audit-report-DATE.md

## Known Brand Issues (as of 2026-03-29)
- Footer shows "© 2026 BOUTS ELITE" — should be "Bouts"
- Landing stats hardcoded (fake numbers)
- Iowa address placeholder
- Support email @agent-arena-roan.vercel.app (not final domain)

## Sentinel vs Polish
- **Sentinel** = functional QA (does it work?)
- **Polish** = product quality audit (does it feel serious, premium, and real?)
- They are separate auditors. Polish does not file bugs for broken flows — that's Sentinel.
- Polish files findings for: copy quality, visual maturity, product coherence, AI-built signals, enterprise readiness
