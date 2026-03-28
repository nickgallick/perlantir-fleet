# ROUTE_INVENTORY.md — Polish Page Coverage Map

Use this file to track what was audited in each Polish audit. Mark every route.

**Base URL**: https://agent-arena-roan.vercel.app
**Last verified**: 2026-03-28

---

## Public / Marketing Routes

| Route | Priority | Desktop | Mobile (390px) | Polish Notes |
|-------|----------|---------|----------------|-------------|
| `/` | P0 — highest impact | | | Homepage: first impression, hierarchy, copy, hero |
| `/challenges` | P0 | | | Challenge browser: cards, filter UX, information density |
| `/challenges/[id]` | P0 | | | Challenge detail: stakes, CTA, info hierarchy |
| `/challenges/[id]/spectate` | P1 | | | Spectate: live data quality, visual treatment |
| `/leaderboard` | P0 | | | Sub-ratings visible, radar chart, ELO display |
| `/agents/[id]` | P1 | | | Agent profile: radar chart, stats maturity |
| `/replays` | P1 | | | Replay list: information hierarchy |
| `/replays/[id]` | P1 | | | Replay detail: judge lane breakdown quality |
| `/how-it-works` | P1 | | | Explainer: 4-lane language, not "3-judge" |
| `/fair-play` | P1 | | | Manifesto: conviction vs filler |
| `/philosophy` | P2 | | | Challenge design philosophy |
| `/status` | P2 | | | Arena status: operational credibility |
| `/blog` | P3 | | | May be empty — flag if broken empty state |
| `/judging` | P1 | | | Judging transparency: 4-lane, accurate description |

---

## Legal Routes (P0 — must have real content)

| Route | Priority | Audited | Notes |
|-------|----------|---------|-------|
| `/legal/terms` | P0 | | Real content? Entity name correct? |
| `/legal/privacy` | P0 | | Real content? |
| `/legal/contest-rules` | P0 | | Iowa address real (not placeholder)? |
| `/legal/responsible-gaming` | P0 | | Real helpline numbers? Iowa helpline present? |

---

## Auth Routes

| Route | Priority | Desktop | Mobile | Notes |
|-------|----------|---------|--------|-------|
| `/login` | P0 | | | Bouts logo, CTA clarity, trust signals |
| `/onboarding` | P0 | | | DOB + state + 6 checkboxes — compliance AND UX quality |
| `/auth/reset-password` | P1 | | | Password reset flow UX |

---

## Challenge Routes (Competitor Experience)

| Route | Priority | Desktop | Mobile | Notes |
|-------|----------|---------|--------|-------|
| `/challenges` | P0 | | | Browse, filter, discover |
| `/challenges/[real-id]` | P0 | | | Detail: info quality, CTA |
| `/challenges/[id]/spectate` | P1 | | | Spectate experience quality |

---

## Results / Breakdown Routes

| Route | Priority | Desktop | Mobile | Notes |
|-------|----------|---------|--------|-------|
| `/replays` | P1 | | | List quality |
| `/replays/[real-id]` | P1 | | | **Core polish target** — judge lane breakdown |
| `/leaderboard` | P0 | | | Sub-ratings, ELO, radar link |
| `/agents/[real-id]` | P1 | | | Radar chart, stats |

---

## Dashboard Routes (Competitor — requires auth)

| Route | Priority | Desktop | Mobile | Notes |
|-------|----------|---------|--------|-------|
| `/dashboard` | P1 | | | Post-login first impression |
| `/dashboard/agents` | P1 | | | Agent list quality |
| `/dashboard/agents/new` | P1 | | | Agent creation form UX |
| `/dashboard/results` | P1 | | | Results list quality |
| `/dashboard/settings` | P2 | | | Settings UX |
| `/dashboard/wallet` | P1 | | | Wallet balance display |

---

## Admin / Operator Routes (requires admin auth)

| Route | Priority | Desktop | Notes |
|-------|----------|---------|-------|
| `/admin` | P1 | | Admin overview quality |
| `/admin/challenges` | P1 | | Pipeline view — is it operationally useful? |
| `/admin/agents` | P2 | | Agent management |

---

## Docs Routes

| Route | Priority | Desktop | Notes |
|-------|----------|---------|-------|
| `/docs` | P0 | | Hub quality — 4 clear sections? |
| `/docs/connector` | P0 | | Completeness, accuracy, developer trust |
| `/docs/connector/setup` | P0 | | Step-by-step quality |
| `/docs/api` | P0 | | API reference quality, code examples |
| `/docs/compete` | P1 | | Competitor guide quality |

---

## Billing / Payment Routes (not yet live)

| Route | Priority | Status | Notes |
|-------|----------|--------|-------|
| Stripe billing flow | P0 when live | NOT LIVE | Do not test until Stripe keys added |
| Coin purchase flow | P0 when live | NOT BUILT | — |
| Wallet/transaction history | P1 when live | PARTIAL | `/dashboard/wallet` exists |

---

## System / Error Routes

| Route | Priority | Desktop | Mobile | Notes |
|-------|----------|---------|--------|-------|
| `/xyz-nonexistent` | P1 | | | 404 page quality — does it help or just block? |
| Server error (500) | P1 | | | If triggerable — error page quality |

---

## Coverage Tracking

### Coverage Codes
- ✅ = Audited, no significant issues
- ⚠️ = Audited, issues found (see findings log)
- ❌ = Not audited
- N/A = Not applicable (not built, not live)
- ~ = Partial confidence (limited access, missing data)

### After Each Audit: Fill in Desktop + Mobile Columns
Replace blank cells with ✅ / ⚠️ / ❌ / N/A / ~

### Minimum Coverage for a Ship Recommendation
All P0 routes must be ✅ or ⚠️ (not ❌) before Polish can recommend SHIP.
P1 routes should be ✅ or ⚠️ where accessible.
