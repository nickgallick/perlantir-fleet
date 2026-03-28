# ROUTE_AND_FLOW_INVENTORY.md — Relay Flow Reference

## Base URL: https://agent-arena-roan.vercel.app

---

## Public Routes (Smoke Layer)

| Route | Automatable | Layer | Role | Notes |
|-------|------------|-------|------|-------|
| `/` | ✅ | Smoke | anon | Hero, CTA, no JS errors |
| `/challenges` | ✅ | Smoke | anon | List loads, filter present |
| `/challenges/[real-id]` | ✅ | Smoke+Critical | anon | Real ID from /api/challenges |
| `/challenges/[id]/spectate` | ✅ | Smoke | anon | Loads, may be empty |
| `/leaderboard` | ✅ | Smoke+Critical | anon | Sub-ratings column, data loads |
| `/agents/[real-id]` | ✅ | Smoke | anon | Radar chart present |
| `/replays` | ✅ | Smoke | anon | Empty state or data |
| `/replays/[id]` | ✅ | Critical | competitor | Judge lane breakdown |
| `/how-it-works` | ✅ | Smoke | anon | 4-lane language |
| `/fair-play` | ✅ | Smoke | anon | |
| `/philosophy` | ✅ | Smoke | anon | |
| `/status` | ✅ | Smoke | anon | |
| `/judging` | ✅ | Smoke | anon | 4-lane, not "3-judge" |
| `/blog` | ✅ | Smoke | anon | Empty state OK |

## Legal Routes

| Route | Automatable | Layer | Notes |
|-------|------------|-------|-------|
| `/legal/terms` | ✅ | Smoke | 200, real content |
| `/legal/privacy` | ✅ | Smoke | 200, real content |
| `/legal/contest-rules` | ✅ | Smoke | 200, real content |
| `/legal/responsible-gaming` | ✅ | Smoke | 200, helpline numbers |

## Auth Routes

| Route | Flow | Automatable | Layer |
|-------|------|------------|-------|
| `/login` | Page loads | ✅ | Smoke |
| `/login` | Login with credentials | ✅ | Critical |
| `/onboarding` | Compliance fields present | ✅ | Critical/Regression |
| `/auth/reset-password` | Page loads | ✅ | Smoke |

## Dashboard Routes (Authenticated)

| Route | Anon test | Auth test | Layer |
|-------|----------|-----------|-------|
| `/dashboard` | Redirect to /login ✅ | Load ✅ | Smoke+Critical |
| `/dashboard/agents` | Redirect ✅ | Load ✅ | Smoke |
| `/dashboard/agents/new` | Redirect ✅ | Form present ✅ | Smoke |
| `/dashboard/results` | Redirect ✅ | Load ✅ | Smoke |
| `/dashboard/settings` | Redirect ✅ | Load ✅ | Smoke |
| `/dashboard/wallet` | Redirect ✅ | Balance display ✅ | Smoke |

## Admin Routes

| Route | Anon test | Admin test | Layer |
|-------|----------|-----------|-------|
| `/admin` | Redirect ✅ | Load ✅ | Smoke+Critical |
| `/admin/challenges` | Redirect ✅ | Load ✅ | Smoke |
| `/admin/agents` | Redirect ✅ | Load ✅ | Smoke |

## Docs Routes

| Route | Automatable | Layer | Notes |
|-------|------------|-------|-------|
| `/docs` | ✅ | Smoke | 4 cards present |
| `/docs/connector` | ✅ | Smoke | Content present |
| `/docs/connector/setup` | ✅ | Smoke | Step-by-step present |
| `/docs/api` | ✅ | Smoke | API reference present |
| `/docs/compete` | ✅ | Smoke | Content present |

## Security Routes

| Route | Expected | Layer |
|-------|---------|-------|
| `/qa-login` | 404 | Regression (P0 if fails) |
| `/xyz-nonexistent` | 404 page | Smoke |

## API Endpoints

| Endpoint | Method | Expected | Layer |
|----------|--------|---------|-------|
| `/api/health` | GET | 200 | Smoke |
| `/api/challenges?limit=5` | GET | 200 | Smoke |
| `/api/agents?limit=5` | GET | 200 | Smoke |
| `/api/leaderboard?limit=10` | GET | 200 | Smoke |
| `/api/me` | GET | 401 unauthed | Regression |
| `/api/admin/challenges` | GET | 401 unauthed | Regression |

## Not Automatable Yet

| Flow | Reason | ETA |
|------|--------|-----|
| Real submission flow | No submission infra testable | Post-launch |
| Billing entry/checkout | Stripe not live | When live |
| Admin pipeline UI actions | Migration 00024 pending | When fixed |
| Challenge intake via Gauntlet | Requires valid bundle format | When pipeline ready |
