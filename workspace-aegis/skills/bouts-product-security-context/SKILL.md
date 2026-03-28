# Bouts Product Security Context — Aegis Reference

## Platform Overview
- **URL**: https://agent-arena-roan.vercel.app
- **Codebase**: /data/agent-arena
- **Legal**: Perlantir AI Studio LLC, Iowa Code § 99B skill-based competitions
- **Stack**: Next.js 15 App Router, TypeScript strict, Supabase (Postgres + Auth + RLS), Vercel
- **Auth provider**: Supabase Auth (JWT-based, sessions managed by Supabase)

## Environment Variables (Security Classified)
| Variable | Location | Risk if exposed |
|----------|----------|----------------|
| `SUPABASE_SERVICE_ROLE_KEY` | Server only | Full DB bypass — CRITICAL |
| `GAUNTLET_INTAKE_API_KEY` | Server + Vercel | Unauthorized challenge injection |
| `CRON_SECRET` | Server only | Cron endpoint manipulation |
| `VERCEL_TOKEN` | Server only | Unauthorized deploys |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Client (public) | Acceptable — meant to be public, RLS enforces access |
| `NEXT_PUBLIC_SUPABASE_URL` | Client (public) | Acceptable |
| `NEXT_PUBLIC_APP_URL` | Client (public) | Acceptable |

Values (for audit verification only — never log or expose):
- Anon key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (starts with eyJ)
- Supabase URL: `https://gojpbtlajzigvyfkghrg.supabase.co`
- Full credentials in `/data/agent-arena/.env.local`

## Role Architecture
| Role | How set | What it grants |
|------|---------|---------------|
| anonymous | No auth | Public routes only |
| authenticated (competitor) | Supabase Auth session | Dashboard, challenge entry, own results |
| admin | profiles.role = 'admin' in DB | /admin/*, all admin APIs |
| connector | API key auth (GAUNTLET_INTAKE_API_KEY) | POST /api/challenges/intake only |

**Critical**: Admin role is stored in the `profiles` table, checked server-side. It is NOT determined solely by JWT claims.

## Security Architecture
- **Frontend gating**: Next.js middleware + route-level checks (first layer)
- **API gating**: Server-side role check at each API route handler (enforced layer)
- **DB gating**: Supabase RLS policies on protected tables (defense-in-depth)
- **Connector auth**: Bearer token check at intake endpoint (single-purpose key)

## Challenge Security Model
- **Hidden tests**: Never in any API response to competitor or anonymous role
- **Judge configuration**: Admin only — weights, thresholds, scoring rubric not public
- **Activation snapshot**: Frozen at activation — immutable scoring config
- **CDI / calibration data**: Admin only
- **pipeline_status**: Admin only (internal state machine)

## Key Security Boundaries (test these first)
1. `/qa-login` → 404 (must not exist in production)
2. `/admin/*` → 401/redirect for unauth, 403 for non-admin
3. `/api/admin/*` → 401 for unauth, 403 for non-admin (at API level, not just UI)
4. `/api/me` → 401 for unauth
5. GAUNTLET_INTAKE_API_KEY → only valid for `/api/challenges/intake`
6. Challenge detail API → no hidden_tests, no judge_weights for any public role
7. Activation snapshot → no mutation endpoint for active challenges

## Known Non-Goals (do not flag)
- No 2FA (not required for this product category)
- Stripe not live (payment security not testable)
- No formal penetration test (not required for first launch)
- /api/cron/challenge-quality is open (intentional — cron runner access)
- NEXT_PUBLIC_SUPABASE_ANON_KEY in client code (acceptable — anon key is public by design)

## Supabase RLS Tables (must have RLS enabled)
- `profiles` — user profiles including role field
- `challenges` — challenge data including hidden fields
- `agents` — agent registrations
- `challenge_bundles` — Gauntlet intake bundles (admin only)
- `challenge_forge_reviews` — Forge review records (admin only)
- `challenge_inventory_decisions` — operator decisions (admin only)
- `arena_wallets` — user coin balances

## Codebase Reference
- Auth middleware: `src/middleware.ts` or `middleware.ts`
- Admin route check pattern: `src/app/api/admin/*/route.ts`
- RLS policies: Supabase dashboard > Authentication > Policies
- Environment check: `/data/agent-arena/.env.local`
- Challenge intake: `src/app/api/challenges/intake/route.ts`
