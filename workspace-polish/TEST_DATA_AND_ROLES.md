# TEST_DATA_AND_ROLES.md — Polish Role Fixtures & Test Conditions

Use this file to ensure consistent test conditions across every Polish audit.

---

## Role Definitions

### Role 1: Anonymous User (unauthenticated)
**Who they are**: First-time visitor, evaluating whether Bouts is credible
**What they can access**: All public routes, legal pages, docs
**What they cannot access**: Dashboard, admin, authenticated APIs
**Polish test focus**: Homepage impression, challenge discovery, trust signals, mobile experience
**Test condition**: No cookies, no auth, private/incognito browser window

### Role 2: Authenticated Competitor
**Who they are**: Developer who has registered an agent and is competing
**What they can access**: Public routes + dashboard, challenge entry, results
**What they cannot access**: Admin/operator routes
**Polish test focus**: Dashboard quality, challenge detail, results and breakdowns, wallet
**Credentials**: qa-bouts-001@mailinator.com / BoutsQA2026!
**Note**: This account has admin role — use it for admin testing too. For pure competitor testing, register a fresh mailinator account.

### Role 3: Admin / Operator
**Who they are**: Perlantir team member managing challenges, reviewing pipeline, enforcing quality
**What they can access**: All routes + /admin/*
**Polish test focus**: Admin surface quality, pipeline workflow usability, system language
**Credentials**: qa-bouts-001@mailinator.com / BoutsQA2026! (admin role confirmed)

### Role 4: Restricted User (blocked state)
**Who they are**: User attempting to register from a restricted state
**States blocked**: WA, AZ, LA, MT, ID
**Polish test focus**: Is the state-blocking UX clear, fair, and non-embarrassing?
**Test condition**: Register a new account, enter a restricted state in onboarding
**Expected outcome**: Clear message explaining restriction, not a confusing error
**Polish evaluation**: Does the rejection feel professional, or does it feel broken/rude?

### Role 5: Connector / Integration User
**Who they are**: Developer integrating their AI agent via the connector CLI
**What they interact with**: /docs/connector, /docs/connector/setup, /docs/api, /docs/compete
**Polish test focus**: Docs quality, setup guide usability, API reference accuracy
**Test condition**: Read docs as a developer who just found Bouts for the first time

### Role 6: Paid User (future — Stripe not live)
**Who they are**: User who has purchased coins or entered a paid challenge
**What they interact with**: /dashboard/wallet, coin purchase flow, prize pool displays
**Polish test focus**: Payment UX trust signals, wallet clarity, prize pool display
**Status**: NOT TESTABLE until Stripe goes live. Do not attempt to test.

---

## Seeded Data States

### Known Challenge States (as of 2026-03-28)
- **Active challenges**: 50 challenges in active state (all passed quality enforcement)
- **Real challenge ID for testing**: `41f952c5-b302-406e-a75a-c5f7a63a8ea4`
- **Challenge families in DB**: Check /api/challenges for current live data
- **Status**: All 50 passed CDI check (0 flagged, 0 quarantined)

### Known Agent States
- **Real agent ID for testing**: `7efe187f-147b-47fc-8b7d-71129b44c994`
- **Test agents** (should NOT appear in production leaderboard):
  - `final-auth-test`
  - `Testagentarwna`
- **Polish note**: If test agents appear in public leaderboard, flag as P2 (test data in production)

### Known Result/Match States
- **Real match data**: Limited — no actual competitive matches run yet
- **Replays**: May be empty or sparse (no real competition history)
- **Polish implication**: Evaluate empty states for replays, leaderboard, results

### Seeded Broken/Edge States
- `/api/challenges/daily` → 500 (no is_daily=true challenge in DB) — NOT a Polish issue (Sentinel's domain)
- Landing page stats → hardcoded — IS a Polish issue (P2: fake/static data)
- `challenge_bundles` table may not exist (migration 00024 partial) — affects pipeline UI

---

## Test Environment Setup

### For Anonymous Audit
1. Use private/incognito browser window OR clear cookies
2. Start from `/` with no auth state
3. Do NOT use QA credentials during this role test

### For Authenticated Audit
1. Navigate to `/login`
2. Email: qa-bouts-001@mailinator.com
3. Password: BoutsQA2026!
4. Verify redirect to `/dashboard` on success
5. Check `/api/me` returns 200 to confirm auth

### For Admin Audit
Same credentials as authenticated — qa-bouts-001 has admin role.
Verify by accessing `/admin` — should load, not redirect.

### For Mobile Audit
Use Playwright with viewport `{ width: 390, height: 844 }` or browser dev tools.
Primary test: no horizontal scroll on any route.

### For Connector/Docs Audit
Read-only — no credentials needed.
Approach as a developer who just discovered Bouts.

---

## Empty State Test Conditions

These are the states Polish must evaluate on every audit:

| State | How to trigger | What to evaluate |
|-------|---------------|-----------------|
| Empty leaderboard | Access /leaderboard with no real data | Does it explain why? Guide next action? |
| Empty replays | Access /replays with no match history | Helpful empty state or blank screen? |
| Empty dashboard agents | Log in with a new account (no agents) | Does it guide agent registration? |
| Empty dashboard results | Log in with a new account (no results) | Explains there are no results yet? |
| Empty admin queue | No items in forge review queue | Does the empty state look intentional? |
| 404 page | Access /xyz-nonexistent | Does it help user navigate back? |

---

## What Polish Tests vs What Sentinel Tests

| Test type | Owner |
|-----------|-------|
| Does the login flow work? | Sentinel |
| Does the login page feel premium and trustworthy? | Polish |
| Does /api/me return 401? | Sentinel |
| Does the empty dashboard feel helpful or broken? | Polish |
| Are admin routes blocked for unauthed users? | Sentinel |
| Do admin surfaces feel operationally serious? | Polish |
| Are legal pages returning 200? | Sentinel |
| Do legal pages feel real or copy-pasted? | Polish |
