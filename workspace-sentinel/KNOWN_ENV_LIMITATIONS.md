# Known Environment Limitations — Sentinel Reference

This file prevents false positives. Before logging a defect, check here.
If something is listed as "known/intentional", do not log it as a bug — log it as a risk item.

Last updated: 2026-03-29

---

## Not Built Yet (Do Not Test)

| Feature | Status | Who owns it |
|---------|--------|------------|
| Stripe billing / payments | Not live — keys not added | Nick (needs Stripe live keys + webhook) |
| Coin purchase flow | Not built | Maks |
| Prize payout flow | Not live | Maks + Stripe |
| bouts.gg domain | Not connected — still on agent-arena-roan.vercel.app | Nick |
| Oracle/blockchain integration | ORACLE_WALLET_ADDRESS + BASE_RPC_URL not set | Nick + Chain |
| Real-time submission runtime | Challenge execution sandbox | Maks |
| Live spectate with real data | May show empty or stub state | Forge/Maks |

---

## Known Issues (Bugs, Not Blockers)

| Issue | Severity | Status |
|-------|----------|--------|
| `/api/challenges/daily` returns 500 | P3 | No challenge with is_daily=true in DB. Route code is correct. Data state issue. |
| Landing page stats hardcoded | P2 | `src/app/page.tsx` lines 50-59. Not live data. |
| Iowa address placeholder in /legal/contest-rules | P1 | Nick needs to provide real address |
| bouts.gg domain not connected | P1 | Support email shows @agent-arena-roan.vercel.app |
| Connector docs don't show v0.1.1 badge | P2 | Stale version display |
| Test agents visible (final-auth-test, Testagentarwna) | P2 | Should not appear in production leaderboard |

---

## Intentionally Incomplete

| Item | Why | What to expect |
|------|-----|----------------|
| Blog | No posts yet | Page loads but may be empty |
| Replays | No real match history yet | Page loads but no replay data |
| Leaderboard data | No real competitions run yet | Page loads but agent data may be sparse |
| Agent profiles | Limited real data | Profiles may show minimal stats |
| challenge_bundles table | Migration 00024 partial | POST /api/challenges/intake will 500 until Forge fixes |

---

## Partial Infrastructure (Do Not Test Destructively)

| Item | Status | Risk if tested destructively |
|------|--------|------------------------------|
| Calibration system | Live but expensive | Running full calibration costs real tokens — only run if explicitly tasked |
| Mutation engine | Live | Creates new challenge records — avoid random triggering |
| Quality enforcement | Runs every 15min | Safe to read, avoid triggering manual runs repeatedly |
| Challenge pipeline | Partial (migration 00024) | Intake API will 500 until challenge_bundles exists |

---

## Environment Context

| Fact | Value |
|------|-------|
| Environment type | Production Vercel deploy |
| Database | Supabase (production project) |
| Real data | Yes — real users, real challenges |
| Reversible actions | Not all — destructive tests require approval |
| Seeded test data | Yes — test agents in DB (see TEST_DATA_AND_ACCOUNTS.md) |
| Staging environment | None — only production |

---

## False Positive Prevention

### "Module not found" or JS bundle errors in console
- Next.js RSC flight responses include `_rsc=` requests that abort — this is normal
- `net::ERR_ABORTED` on `_rsc=*` requests = normal Next.js behavior, not a bug

### Loading spinner on page load
- Bouts shows a "Initialising Node" loading overlay on cold page loads
- This is intentional design — not a stuck state
- If it persists >10 seconds, then flag it

### Empty leaderboard / empty replays
- No matches have been run yet — empty states are expected, not broken
- Flag if: no empty state message shown, or empty state looks broken/confusing

### Sub-ratings showing "Loading..." on leaderboard
- Data loads client-side via JS — curl/static HTML check won't see it
- Must verify with actual browser (Playwright) that data loads after JS execution

### 401 on /api/me
- Expected behavior for unauthenticated requests — NOT a bug

### Redirect on /dashboard unauthed
- Expected — should redirect to /login with ?redirect= param
- Only a bug if it does NOT redirect
