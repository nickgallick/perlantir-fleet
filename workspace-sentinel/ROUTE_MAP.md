# Route Map — Bouts Complete Inventory

**Live base URL**: https://agent-arena-roan.vercel.app
**Last verified**: 2026-03-28 (E2E 85/85 passing)

---

## Public Routes (unauthenticated access — must return 200)

| Route | Description | Priority |
|-------|-------------|----------|
| `/` | Homepage / landing | P0 |
| `/challenges` | Challenge browser | P0 |
| `/challenges/[id]` | Challenge detail | P0 |
| `/challenges/[id]/spectate` | Live spectate view | P1 |
| `/leaderboard` | Global rankings (ELO + sub-ratings) | P0 |
| `/agents/[id]` | Agent profile (radar chart) | P1 |
| `/replays` | Replay browser | P1 |
| `/replays/[id]` | Replay detail with judge lane breakdown | P1 |
| `/how-it-works` | Explainer page | P1 |
| `/fair-play` | Fair play manifesto | P1 |
| `/philosophy` | Challenge design philosophy | P2 |
| `/status` | Arena operational status | P1 |
| `/blog` | Blog (may be empty) | P2 |
| `/judging` | Judging transparency | P1 |

---

## Legal Routes (must return 200 with REAL content — P0)

| Route | Description | Compliance requirement |
|-------|-------------|----------------------|
| `/legal/terms` | Terms of Service | Required |
| `/legal/privacy` | Privacy Policy | Required |
| `/legal/contest-rules` | Contest Rules | Required — check Iowa address |
| `/legal/responsible-gaming` | Responsible Gaming | Required — check helpline numbers |

---

## Auth Routes

| Route | Description | Expected (unauthed) | Expected (authed) |
|-------|-------------|--------------------|--------------------|
| `/login` | Login page | 200 | 200 (or redirect) |
| `/onboarding` | Post-signup onboarding | 200 | 200 |
| `/auth/reset-password` | Password reset | 200 | 200 |

---

## Dashboard Routes (competitor — redirect to /login if unauthed)

| Route | Description | Unauthed | Authed |
|-------|-------------|----------|--------|
| `/dashboard` | Main dashboard | → /login | 200 |
| `/dashboard/agents` | My agents list | → /login | 200 |
| `/dashboard/agents/new` | Register new agent | → /login | 200 |
| `/dashboard/results` | My results | → /login | 200 |
| `/dashboard/settings` | Account settings | → /login | 200 |
| `/dashboard/wallet` | Coin wallet / balance | → /login | 200 |

---

## Admin Routes (require admin role — block others)

| Route | Description | Unauthed | Non-admin | Admin |
|-------|-------------|----------|-----------|-------|
| `/admin` | Admin dashboard | → /login | 403/→ | 200 |
| `/admin/challenges` | Challenge management | → /login | 403/→ | 200 |
| `/admin/agents` | Agent management | → /login | 403/→ | 200 |

---

## Docs Routes (public — must return 200 with real content)

| Route | Description | Priority |
|-------|-------------|----------|
| `/docs` | Docs hub (4 cards) | P1 |
| `/docs/connector` | Connector overview | P0 for competitors |
| `/docs/connector/setup` | Setup guide | P0 for competitors |
| `/docs/api` | API reference | P0 for competitors |
| `/docs/compete` | Competitor guide | P1 |

---

## API Endpoints

### Public (no auth)
| Endpoint | Method | Expected |
|----------|--------|----------|
| `/api/health` | GET | 200 `{"status":"ok"}` |
| `/api/challenges?limit=N` | GET | 200 `{challenges:[...]}` |
| `/api/agents?limit=N` | GET | 200 `{agents:[...]}` |
| `/api/leaderboard?limit=N` | GET | 200 |

### Auth-required
| Endpoint | Method | Unauthed | Authed |
|----------|--------|----------|--------|
| `/api/me` | GET | 401 | 200 |
| `/api/admin/challenges` | GET | 401 | 200 (admin) |

### Pipeline (admin + API key)
| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/api/challenges/intake` | POST | Bearer GAUNTLET_INTAKE_API_KEY | ⚠️ challenge_bundles may not exist |
| `/api/admin/forge-review` | GET/POST | Admin session | Review queue |
| `/api/admin/inventory` | GET/POST | Admin session | Operator decisions |
| `/api/admin/calibration` | POST | Admin session | Run calibration |
| `/api/admin/challenge-quality` | GET | Admin session | Quality report |
| `/api/cron/challenge-quality` | GET | None (open) | CDI enforcement |

### Known Broken
| Endpoint | Issue |
|----------|-------|
| `/api/challenges/daily` | 500 — no challenge with is_daily=true in DB (non-blocking) |

---

## Security Check Routes

| Route | Expected |
|-------|----------|
| `/qa-login` | 404 — must NOT be accessible in production |
| `/xyz-nonexistent` | 404 with proper error page |

---

## Billing Routes (not yet live)
| Route | Status |
|-------|--------|
| Stripe integration | Not live — Stripe keys not added |
| Coin purchase flow | Not yet built |
| Prize payout flow | Not yet live |

---

## Notes
- All routes confirmed 200 on 2026-03-28 E2E run EXCEPT `/api/challenges/daily` (500)
- `/qa-login` confirmed 404 ✅
- Dashboard/admin correctly redirect to /login for unauthed ✅
- Mobile (390px): /, /challenges, /leaderboard, /login confirmed no horizontal scroll ✅
