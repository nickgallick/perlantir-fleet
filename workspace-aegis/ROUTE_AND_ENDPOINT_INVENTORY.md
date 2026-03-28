# ROUTE_AND_ENDPOINT_INVENTORY.md — Aegis Coverage Map

Every Aegis audit marks tested routes. No implied coverage.

**Base URL**: https://agent-arena-roan.vercel.app
**Coverage codes**: ✅ tested/pass | ⚠️ tested/issue | ❌ not tested | N/A not applicable

---

## Public Pages

| Route | Auth required | Expected anon access | Tested | Notes |
|-------|-------------|---------------------|--------|-------|
| `/` | No | 200 | | |
| `/challenges` | No | 200 | | |
| `/challenges/[id]` | No | 200 | | No hidden test data in response |
| `/challenges/[id]/spectate` | No | 200 | | |
| `/leaderboard` | No | 200 | | No private user data |
| `/agents/[id]` | No | 200 | | No private agent data |
| `/replays` | No | 200 | | |
| `/replays/[id]` | No | 200 | | No admin-only breakdown data |
| `/how-it-works` | No | 200 | | |
| `/fair-play` | No | 200 | | |
| `/philosophy` | No | 200 | | |
| `/status` | No | 200 | | |
| `/judging` | No | 200 | | |
| `/legal/terms` | No | 200 | | |
| `/legal/privacy` | No | 200 | | |
| `/legal/contest-rules` | No | 200 | | |
| `/legal/responsible-gaming` | No | 200 | | |

---

## Auth Routes

| Route | Expected behavior | Auth bypass test | Tested |
|-------|-----------------|-----------------|--------|
| `/login` | 200 | N/A | |
| `/onboarding` | 200 | Check if skippable | |
| `/auth/reset-password` | 200 | Check token validation | |

---

## Protected Routes (Auth + Role Required)

### Dashboard (competitor + admin)
| Route | Anon expected | Competitor expected | Admin expected | Tested |
|-------|-------------|--------------------|----|-------|
| `/dashboard` | → /login | 200 | 200 | |
| `/dashboard/agents` | → /login | 200 | 200 | |
| `/dashboard/agents/new` | → /login | 200 | 200 | |
| `/dashboard/results` | → /login | 200 | 200 | |
| `/dashboard/settings` | → /login | 200 | 200 | |
| `/dashboard/wallet` | → /login | 200 | 200 | |

### Admin Only
| Route | Anon expected | Competitor expected | Admin expected | Tested |
|-------|-------------|--------------------|----|-------|
| `/admin` | → /login | 403 | 200 | |
| `/admin/challenges` | → /login | 403 | 200 | |
| `/admin/agents` | → /login | 403 | 200 | |

---

## Security Check Routes
| Route | Expected | Tested |
|-------|---------|--------|
| `/qa-login` | 404 | |
| `/xyz-nonexistent` | 404 (proper error page) | |
| `/api/internal/*` | 401/404 | |

---

## API Endpoints — Public (no auth)

| Endpoint | Method | Tested | Notes |
|----------|--------|--------|-------|
| `/api/health` | GET | | 200 + status:ok |
| `/api/challenges` | GET | | No hidden data in response |
| `/api/challenges/[id]` | GET | | No hidden tests, no judge config |
| `/api/agents` | GET | | No private fields |
| `/api/leaderboard` | GET | | |
| `/api/cron/challenge-quality` | GET | | Idempotent, no abuse |

---

## API Endpoints — Auth Required

| Endpoint | Method | Anon test | Competitor test | Admin test | Tested |
|----------|--------|----------|----------------|-----------|--------|
| `/api/me` | GET | 401 | 200 | 200 | |
| `/api/me` | PATCH | 401 | 200 (own) | 200 | |
| `/api/admin/challenges` | GET | 401 | 403 | 200 | |
| `/api/admin/forge-review` | GET | 401 | 403 | 200 | |
| `/api/admin/forge-review` | POST | 401 | 403 | 200 | |
| `/api/admin/inventory` | GET | 401 | 403 | 200 | |
| `/api/admin/inventory` | POST | 401 | 403 | 200 | |
| `/api/admin/calibration` | POST | 401 | 403 | 200 | |
| `/api/admin/challenge-quality` | GET | 401 | 403 | 200 | |

---

## API Endpoints — API Key Auth (Connector)

| Endpoint | Method | No key | Wrong key | Valid key | Tested |
|----------|--------|--------|----------|-----------|--------|
| `/api/challenges/intake` | POST | 401 | 401 | 200 | |

---

## Internal / Cron Endpoints

| Endpoint | Status | Expected | Tested |
|----------|--------|---------|--------|
| `/api/internal/run-migration-024` | Should be 404/disabled post-migration | 404 | |
| `/api/cron/*` | Open but idempotent | 200, safe | |

---

## Billing Routes (not yet live)

| Endpoint | Status | Notes |
|----------|--------|-------|
| Stripe webhook | Not configured | Test when live |
| Coin purchase | Not built | — |
| Payout endpoint | Not built | — |

---

## Coverage Minimum for Ship Recommendation
Aegis cannot recommend SHIP unless these are all marked ✅ or ⚠️:
- All admin routes tested (anon + competitor + admin)
- All admin API endpoints tested (anon + competitor + admin)
- /api/me tested (anon + competitor)
- /qa-login tested (must be 404)
- /api/challenges/[id] tested (no hidden data leakage)
- Intake API tested (no key + wrong key + valid key)
