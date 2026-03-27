# HANDOFF.md — Forge Context (read on every startup)
# Last updated: 2026-03-26

## Active Project: Bouts / Agent Arena

### Key Facts
- **Live URL**: https://agent-arena-roan.vercel.app
- **Codebase**: `/data/agent-arena` (already cloned on this VPS)
- **GitHub repo**: https://github.com/nickgallick/Agent-arena
- **GitHub token**: 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
- **Stack**: Next.js App Router, TypeScript strict, Tailwind, Supabase, Vercel
- **Deploy command**: `cd /data/agent-arena && vercel deploy --prod --yes --token $(cat ~/.vercel/auth.json | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")`
- **Vercel org/project**: team_h7szk9Nd73ydfud2R8vnQwSx / prj_Nlf54QOI9zrMmLGJ7ZtJjL9hslzt

### Supabase
- **URL**: https://gojpbtlajzigvyfkghrg.supabase.co
- **Credentials**: in `/data/agent-arena/.env.local`
- **Personal Access Token (Supabase CLI/Management API)**: sbp_851afa9dfe477af8cb5c9a6e2c22ecdab2d5960b

### QA
- **QA user**: qa-bouts-001@mailinator.com (admin role, coins: 1450)
- **QA login**: `/qa-login` — MUST NOT be enabled in prod (`ENABLE_QA_LOGIN` env var)

### Fixes Applied (commit 8003cf4 — deployed and live)
1. Judging filter tab on /challenges page
2. Replay placement field with medal emoji
3. Agent slug 400 fix (UUID vs name/slug lookup)
4. Admin role for QA user

### Known Open Issues
- `/api/challenges/daily` returns 500 — DB schema issue (non-blocking, handled gracefully)
- Landing stats hardcoded in `src/app/page.tsx` lines 50-59
- Test agents in DB: `final-auth-test`, `Testagentarwna`
- Connector docs don't show v0.1.1 badge

### Current Tasks (as of 2026-03-26)
- [ ] Make logo larger (Nick requested)
- [ ] Center "Ready to Compete?" hero section on desktop homepage (left-aligned, should be centered)

## Update This File
After every significant session, update the "Current Tasks" and "Fixes Applied" sections so the next session starts with full context.
