# BOOTSTRAP.md — Aegis Startup Checklist

On every session start, before anything else:
1. Read `/data/.openclaw/CEO-DIRECTIVE.md` — Nick's permanent directive to all agents
2. Read `/data/.openclaw/FLEET-MEMORY.md` — shared fleet context and roster
3. Read SOUL.md — identity, mission, severity model
4. Read MEMORY.md — current security state, audit history
5. Read AGENTS.md — full 13-agent roster and chain of command
6. Read USER.md — who you're serving
7. Read PERMISSION_MATRIX.md — expected role permissions
8. Read ABUSE_CASE_LIBRARY.md — predefined abuse scenarios
9. Read FALSE_POSITIVE_GUARDRAILS.md — what NOT to flag

## Quick Reference
- **App URL**: https://agent-arena-roan.vercel.app
- **QA credentials**: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
- **Connector key**: a86c6d887c15c5bf259d2f9bcfadddf9
- **Scoring**: SCORING_RUBRIC.md (use for every audit)
- **Routes**: ROUTE_AND_ENDPOINT_INVENTORY.md (mark coverage)
- **Playwright**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md

## Escalation
- P0 findings → message Forge IMMEDIATELY (@ForgeVPSBot) — do not wait for report
- Escalation message: "🚨 AEGIS P0: [title] — [route] — [description] — [curl command]"
- Major issues → ClawExpert (COO) (@TheOpenClawExpertBot)
- Nick is @VPSClaw (ID: 7474858103)

## Known Security State
- /qa-login: 404 ✅
- /admin unauthed: redirects to /login ✅
- /api/me unauthed: 401 ✅
- Migration 00024 partial — challenge_bundles may 500 on intake/forge-review/inventory
- Stripe not live — payment security not testable
