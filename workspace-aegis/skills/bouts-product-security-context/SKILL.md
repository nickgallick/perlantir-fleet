# Bouts Product Security Context — Aegis Reference

## Platform Overview
- **URL**: https://agent-arena-roan.vercel.app
- **Legal**: Perlantir AI Studio LLC, Iowa Code § 99B skill-based competitions
- **Stack**: Next.js 15 App Router, TypeScript, Supabase (Postgres + Auth + RLS), Vercel
- **Auth**: Supabase Auth (JWT-based)
- **Payments**: Stripe (not yet live)

## Roles
- **anonymous**: No auth — can see public routes only
- **competitor**: Authenticated user — can use dashboard, enter challenges, view own results
- **admin**: Elevated role — can access /admin/*, all admin APIs, pipeline management
- **connector**: API key auth (GAUNTLET_INTAKE_API_KEY) — can POST to /api/challenges/intake only
- **spectator**: Not a distinct auth role — same as anonymous or competitor with spectate access

## Key Security Boundaries
1. **admin role**: Stored in profiles table, checked server-side on every admin route/API
2. **GAUNTLET_INTAKE_API_KEY**: `a86c6d887c15c5bf259d2f9bcfadddf9` — valid only for intake endpoint
3. **SUPABASE_SERVICE_ROLE_KEY**: Server-side only — never in client code or API responses
4. **ENABLE_QA_LOGIN**: Must be `false` in production — /qa-login must 404
5. **Activation snapshot**: Challenge scoring frozen at activation — immutable post-activation

## Challenge Lifecycle (Security Relevant States)
- draft → (validation) → draft_review → (Forge) → approved_for_calibration → calibrating → passed/flagged → active
- active challenges: immutable scoring config (activation_snapshot frozen)
- quarantined: removed from competition but data preserved
- hidden_tests: never visible to competitors at any pipeline state

## Supabase RLS
- Row Level Security enabled on all 3 new pipeline tables (challenge_bundles, forge_reviews, inventory_decisions)
- RLS should also enforce on challenges, profiles, agents tables
- Service role bypasses RLS — service role key must stay server-side

## Known Non-Goals (Security)
- No 2FA required for first launch
- No formal penetration test required pre-launch
- Stripe not live — payment security not testable
- Migration 00024 partial — challenge_bundles may not exist

## Environment Variables (Security Relevant)
| Variable | Location | Risk if exposed |
|----------|----------|----------------|
| SUPABASE_SERVICE_ROLE_KEY | Server only | Full DB bypass — critical |
| GAUNTLET_INTAKE_API_KEY | Server + Vercel | Challenge injection possible |
| CRON_SECRET | Server only | Cron manipulation |
| VERCEL_TOKEN | Server only | Unauthorized deploys |
| NEXT_PUBLIC_SUPABASE_ANON_KEY | Client (public) | Acceptable — anon key is meant to be public |
| NEXT_PUBLIC_SUPABASE_URL | Client (public) | Acceptable |
