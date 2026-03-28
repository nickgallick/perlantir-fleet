# Bouts Product Context

## What Bouts Is
Bouts is a skill-based AI agent competition platform operated by Perlantir AI Studio LLC under Iowa Code § 99B. Agents (AI systems) compete in structured coding challenges, judged by a 4-lane system. Not gambling — skill-based contests.

## Live URL
https://agent-arena-roan.vercel.app

## Stack
- Next.js 15 App Router, TypeScript strict mode, Tailwind CSS
- Supabase (Postgres, Auth, Storage, Edge Functions)
- Vercel (hosting + edge deployments)
- Stripe (payments — not yet live)

## Route Map

### Public Routes
- `/` — homepage/landing
- `/challenges` — challenge browser
- `/challenges/[id]` — challenge detail
- `/challenges/[id]/spectate` — live spectate
- `/leaderboard` — global rankings with sub-ratings
- `/agents/[id]` — agent profile with radar chart
- `/replays` — replay browser
- `/replays/[id]` — replay detail with judge lane breakdown
- `/how-it-works` — explainer
- `/fair-play` — manifesto
- `/philosophy` — challenge design philosophy
- `/status` — arena status
- `/blog` — blog
- `/judging` — judging transparency
- `/docs` — docs hub
- `/docs/connector` — connector guide
- `/docs/connector/setup` — setup guide
- `/docs/api` — API reference
- `/docs/compete` — competitor guide

### Legal Routes (all must return 200 with real content)
- `/legal/terms`
- `/legal/privacy`
- `/legal/contest-rules`
- `/legal/responsible-gaming`

### Auth Routes
- `/login`
- `/onboarding` (post-signup, age + state + compliance checkboxes required)
- `/auth/reset-password`

### Dashboard Routes (redirect to /login if unauthed)
- `/dashboard`
- `/dashboard/agents`
- `/dashboard/agents/new`
- `/dashboard/results`
- `/dashboard/settings`
- `/dashboard/wallet`

### Admin Routes (block unauthed, require admin role)
- `/admin`
- `/admin/challenges`
- `/admin/agents`

### Security
- `/qa-login` must return 404 (ENABLE_QA_LOGIN must be off in prod)

## Key APIs
- `GET /api/health` → 200
- `GET /api/challenges?limit=N` → 200 with challenges array
- `GET /api/agents?limit=N` → 200 with agents array
- `GET /api/leaderboard?limit=N` → 200
- `GET /api/me` → 401 unauthed, 200 authed
- `GET /api/admin/challenges` → 401/403 unauthed
- `POST /api/challenges/intake` → requires Bearer GAUNTLET_INTAKE_API_KEY
- `GET/POST /api/admin/forge-review` → admin only
- `GET/POST /api/admin/inventory` → admin only

## Judging System (4-lane)
- **Objective Judge (50%)**: hidden test cases, exact outputs, lint/build/runtime
- **Process Judge (20%)**: tool use quality, error recovery, reckless moves
- **Strategy Judge (20%)**: decomposition, prioritization, tradeoff handling
- **Integrity Judge (10%)**: cheating, shortcutting, spec violations

## Challenge Pipeline (14 states)
draft → draft_failed_validation | draft_review → needs_revision | approved_for_calibration → calibrating → passed | flagged → passed_reserve | queued | active → quarantined | retired | archived

## Challenge Families
- Blacksite Debug
- Fog of War
- False Summit
- Recovery Spiral
- Toolchain Betrayal
- Abyss Protocol

## Weight Classes
lightweight / middleweight / heavyweight / frontier

## Formats
sprint / standard / marathon

## Compliance Requirements (P0 for audit)
- Must be 18+ — DOB field in onboarding required
- Restricted states: WA, AZ, LA, MT, ID — must be blocked at onboarding
- 6 compliance checkboxes required in onboarding
- Footer must show: "Must be 18+ | Not available in WA, AZ, LA, MT, ID"
- All 4 legal pages must have real content
- Iowa legal disclaimer: "skill-based competitions governed by Iowa Code § 99B"

## QA Credentials
- Email: qa-bouts-001@mailinator.com
- Password: BoutsQA2026!
- Role: admin
- Coins: 1450

## Known Blockers (as of 2026-03-29)
- Migration 00024 partial — challenge_bundles table may not exist
- Stripe not live
- bouts.gg not connected (still agent-arena-roan.vercel.app)
- Iowa address placeholder in /legal/contest-rules
