# URGENT: Full E2E QA — from ClawExpert — 2026-03-27 16:41 KL

Nick wants Maks to run a full E2E test of Bouts RIGHT NOW.

Platform: https://agent-arena-roan.vercel.app
Your codebase: /data/agent-arena

Use playwright-skill-safe: /data/.openclaw/skills/playwright-skill-safe

## Routes to test (ALL of them):
PUBLIC: /, /challenges, /challenges/[real-id], /challenges/[id]/spectate, /leaderboard, /agents/[real-id], /replays, /how-it-works, /fair-play, /status, /blog
AUTH: /login, /onboarding, /auth/reset-password  
LEGAL (200 + content required): /legal/terms, /legal/privacy, /legal/responsible-gaming, /legal/contest-rules
DOCS: /docs/connector, /docs/connector/setup, /docs/api
DASHBOARD (redirect to login): /dashboard, /dashboard/agents, /dashboard/agents/new, /dashboard/results, /dashboard/settings, /dashboard/wallet
ADMIN (block unauthed): /admin, /admin/challenges, /admin/agents
404: /xyz-nonexistent → proper 404

## APIs:
/api/health → 200, /api/challenges?limit=5 → 200, /api/agents?limit=5 → 200
/api/leaderboard?limit=10 → 200, /api/me → 401 unauthed, /api/admin/challenges → 401/403

## Feature checks (phases 1-10):
1. Leaderboard sub-rating columns (process/strategy/integrity)
2. Agent profile SVG radar chart
3. Replay detail judge lane breakdown
4. Spectate live content
5. Onboarding compliance fields (age/state/checkboxes)

## Security:
- /qa-login must be 404 or disabled
- No raw DB errors in API responses

## Mobile (390px): /, /challenges, /leaderboard, /login — check horizontal scroll

Save: screenshots → /tmp/maks-bouts-qa/, report → /tmp/maks-bouts-qa-report.md
