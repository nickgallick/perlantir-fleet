# Forge Re-Review — Agent Arena (Fix Iteration 1)

**Verdict: ⚠️ PASS WITH NOTES**
**Developer:** Maks
**Date:** 2026-03-22
**Previous Verdict:** ❌ BLOCKED (13 P0, 19 P1)
**Known patterns checked:** Missing error destructuring ✓, getSession vs getUser ✓, select('*') ✓, weak Zod validation ✓, RLS coverage ✓

---

## P0 Verification — All 13 Fixed ✅

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1 | Admin page hardcoded open | ✅ FIXED | Server component, `getUser()` + DB role check, non-admin redirects |
| 2 | Middleware auth broken | ✅ FIXED | Real URL paths, admin role check in middleware, redirect with `?redirect=` |
| 3 | Coin balance exploit | ✅ FIXED | `prevent_coin_modification()` trigger blocks direct UPDATE |
| 4 | Entry scores editable | ✅ FIXED | Status guard on RLS + `prevent_score_modification()` trigger, service_role exempted |
| 5 | In-memory rate limiter | ✅ FIXED | Upstash Redis → Supabase RPC → fail-open. Persistent across cold starts |
| 6 | Judge scores visible early | ✅ FIXED | RLS join checks `challenges.status = 'complete'` OR entry owner |
| 7 | OAuth no rate limit | ✅ FIXED | IP-based 5 req/min on `/api/auth/github` |
| 8 | Missing SECURITY DEFINER | ✅ FIXED | Both `credit_wallet()` and `update_agent_elo()` with `SET search_path = public` |
| 9 | Sequence number race | ✅ FIXED | `pg_advisory_xact_lock(hashtext(p_entry_id::text))` serializes |
| 10 | Double-submit race | ✅ FIXED | Atomic `submit_entry()` with `SELECT ... FOR UPDATE` |
| 11 | Table name mismatch | ✅ FIXED | `arena_wallets` (balance) + `wallets` (transactions) aligned |
| 12 | pick_job() broken | ✅ FIXED | `scheduled_for <= NOW()` + `ORDER BY priority ASC, scheduled_for ASC` |
| 13 | Missing pg_cron | ✅ FIXED | `CREATE EXTENSION IF NOT EXISTS "pg_cron"` with idempotent schedule |

## P1 Bonus Fixes Verified

| Fix | Status |
|-----|--------|
| authenticateConnector extracted | ✅ Shared utility, all 4 routes import it, error destructured, explicit columns, `is_active` check |
| select('*') replaced | ✅ Zero instances remaining in API routes. Explicit column constants defined. |
| Error destructuring added | ✅ All modified routes use `{ data, error }`. PGRST116 handled correctly. |
| UUID validation on path params | ✅ `z.string().uuid()` on agents, challenges, replays |
| requireAdmin 503 on DB outage | ✅ Explicit error check, logs error, throws 503 not 403 |
| Admin challenges uses createAdminClient | ✅ Verified |
| 11 missing indexes added | ✅ Including composite and partial indexes |

---

## Remaining Issues

### P2 — Medium (fix before next milestone)

| # | File | Issue |
|---|------|-------|
| 1 | 9 API route files | **Catch blocks still swallow errors** — `catch {` without error variable or logging. Routes: me/results, admin/challenges, admin/judge, admin/jobs, challenges/route, challenges/[id], challenges/[id]/enter, leaderboard/[weightClass], v1/agents/ping. The modified routes (me/route, agents/[id], submissions) now log properly — but the unmodified ones still discard errors silently. |
| 2 | `admin/jobs/route.ts:51` | **Unbounded stats query** — `select('status')` on ALL jobs with no LIMIT. Should use `GROUP BY status` aggregation. |
| 3 | `components/challenges/challenge-grid.tsx:31` | **`as any` cast** — `category={challenge.category as any}`. Fix `Challenge.category` type to use proper union type. |
| 4 | `console.warn` in rate-limit.ts | **Warn on every request when no backend configured** — Will flood logs in dev. Should warn once or use a flag. |
| 5 | `rate_limit_check()` | **No cleanup cron scheduled** — `cleanup_rate_limits()` exists but no cron.schedule call for it. Rate limit buckets will accumulate. |

### P3 — Low (suggestions)

| # | Issue |
|---|-------|
| 1 | Still no test files. Not blocking for this iteration but should be next priority. |
| 2 | CSRF Origin header check still missing on POST routes. Low risk since Supabase auth uses PKCE, but defense in depth. |
| 3 | `challenge_prompts.difficulty` still TEXT not SMALLINT per spec. |
| 4 | Types in `src/types/challenge.ts` still use `string` for category/format/status — should be union types (causes the `as any`). |

---

## What Improved

The quality jump from round 1 to round 2 is significant:

- **Zero P0 issues remaining** — all 13 security/anti-cheat holes patched
- **Error handling pattern fixed** in all modified routes — proper `{ data, error }` destructuring with PGRST116 awareness
- **Rate limiter is production-grade** — Upstash → Supabase → fail-open cascade
- **Admin auth is defense-in-depth** — middleware check + server component check + DB role verification
- **Anti-cheat hardened** — triggers block direct score/coin manipulation, advisory locks prevent races, atomic functions for critical operations
- **Column exposure eliminated** — explicit column constants, no `select('*')`
- **Shared utilities extracted** — authenticateConnector, getClientIp, proper rate limit signatures

---

## Verdict

**⚠️ PASS WITH NOTES**

All 13 P0 critical issues are verified fixed. The 7 P1 bonus fixes are solid. The remaining issues are P2/P3 — important for code quality but not ship-blocking.

**Conditions for full PASS on next review:**
1. Fix the 9 remaining swallowed catch blocks (add error logging)
2. Fix the unbounded jobs stats query
3. Schedule rate_limit cleanup cron
4. Fix the `as any` by correcting the Challenge type

**Estimated work:** ~2 hours for all remaining items.

---

🔥 Forge
