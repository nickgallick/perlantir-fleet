# TOOLS.md — Forge Development Resources

## Active Project: Bouts / Agent Arena

- **Live URL**: https://agent-arena-roan.vercel.app
- **Codebase**: `/data/agent-arena` (cloned on VPS)
- **GitHub**: https://github.com/nickgallick/Agent-arena
- **Stack**: Next.js 16 App Router, TypeScript strict, Tailwind, Supabase, Vercel
- **Deploy**: `cd /data/agent-arena && vercel deploy --prod --yes --token $(cat ~/.vercel/auth.json | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")`

## Supabase (Bouts)

- **URL**: https://gojpbtlajzigvyfkghrg.supabase.co
- **Credentials**: in `/data/agent-arena/.env.local`
- **Admin REST**: `curl "${SUPA_URL}/rest/v1/profiles?..." -H "apikey: ${SUPA_SERVICE}" -H "Authorization: Bearer ${SUPA_SERVICE}"`

## GitHub Access

- **Token**: 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
- **Clone Agent Arena**: `git clone https://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@github.com/nickgallick/Agent-arena.git`
- **Fleet repo**: https://github.com/nickgallick/perlantir-fleet

## Code Review Standards

- Severity: CRITICAL / HIGH / MEDIUM / LOW / GAS (blockchain)
- **CRITICAL**: Security vulnerability, data loss, auth bypass → block deploy
- **HIGH**: Bug that affects core functionality → fix before shipping
- **MEDIUM**: Quality issue, performance → fix in next sprint
- **LOW**: Style, minor improvement → optional

## Security Checklist (Every Review)

- [ ] No API keys or secrets in client-side code
- [ ] Auth checks on every protected API route
- [ ] RLS policies on all Supabase tables
- [ ] No `error.message` leaked to client in API responses
- [ ] Input validation on all user-submitted data
- [ ] No SQL injection via raw queries
- [ ] ENABLE_QA_LOGIN not set in production env

## Nick's Stack Reference

- **Next.js**: App Router, Server Components, Server Actions
- **Auth**: Supabase Auth (JWT)
- **DB**: Supabase Postgres with RLS
- **Styling**: Tailwind CSS
- **Deploy**: Vercel
- **Payments**: Stripe (when applicable)

## QA Credentials (Bouts)

- **QA user**: qa-bouts-001@mailinator.com
- **Role**: admin, is_admin: true, coins: 1450
- **Supabase ID**: e6e37b08-f0cc-4ced-b616-604fabb39bc2
- **QA login**: `/qa-login` — must NOT be enabled in prod

## Pipeline Position

Forge is step 2 in the pipeline:
1. Scout (research) → **Forge (architecture spec)** → Pixel (design) → Maks (build) → **Forge (code review)** → QA → Launch

On code review: if CRITICAL or HIGH issues found, return to Maks with complete fix code (not just description).
