# Forge Review — Agent Arena

**Verdict: ❌ BLOCKED**
**Developer:** Maks
**Date:** 2026-03-22
**Codebase:** `/data/agent-arena`
**Architecture Spec:** `/data/.openclaw/workspace-forge/architecture-spec-agent-arena.md`
**Deploy:** https://agent-arena-roan.vercel.app
**Known patterns checked:** Missing error destructuring ✓, getSession vs getUser ✓, select('*') ✓, weak Zod validation ✓, RLS coverage ✓

---

## Executive Summary

Agent Arena is a substantial build — 189 TypeScript files, 18 DB tables, 17 API routes, 50+ components, 4 Edge Functions, live spectator system. TypeScript strict mode with only 1 `as any`. Auth correctly uses `getUser()` not `getSession()`. Supabase client separation is textbook. The build passes and deploys.

However, **13 P0 critical issues** block ship. The admin panel is wide open (`const isAdmin = true`), middleware auth protection doesn't work (route group parentheses aren't in URLs), users can SET their own coin balance via RLS, challenge entry scoring fields are directly editable, the rate limiter is in-memory (useless on Vercel serverless), and submissions aren't immutable. These are game-breaking security and anti-cheat failures that must be fixed before any user touches this.

---

## 32-Point Checklist Results

| # | Check | Result |
|---|-------|--------|
| 1 | Auth on every endpoint | ❌ Admin page hardcoded open, middleware broken |
| 2 | Input validation (Zod) | ⚠️ Present but path params unvalidated, weak constraints |
| 3 | No SQL injection | ✅ Parameterized via Supabase client |
| 4 | No XSS | ✅ React auto-escapes, event sanitizer present |
| 5 | CSRF protection | ⚠️ No Origin header check on POST routes |
| 6 | No hardcoded secrets | ✅ Env vars only (but .env.local on disk with service key) |
| 7 | RLS on all tables | ⚠️ RLS enabled on all 18 tables, but policies are too permissive |
| 8 | Rate limiting | ❌ In-memory Map — useless on Vercel serverless |
| 9 | No N+1 queries | ✅ Joins used correctly |
| 10 | No unbounded queries | ❌ admin/jobs fetches ALL jobs for stats, entries unbounded |
| 11 | No unnecessary re-renders | ✅ Server components used correctly |
| 12 | No waterfall requests | ✅ Parallel queries where appropriate |
| 13 | Business logic not in components | ✅ API routes handle logic |
| 14 | Consistent error shapes | ⚠️ Mostly `{error: string}` but inconsistent details field |
| 15 | Server vs client correct | ✅ Good separation |
| 16 | No circular deps | ✅ Clean import graph |
| 17 | No untyped `any` | ⚠️ 1 instance: `as any` cast in challenge-grid.tsx |
| 18 | Zod at trust boundaries | ✅ All API routes validate |
| 19 | DB queries using generated types | ⚠️ Types are manual, not generated from Supabase |
| 20 | No functions over 50 lines | ⚠️ 2 files exceed (events/stream 124 lines, agents/[id] 130 lines) |
| 21 | No magic numbers | ⚠️ MPS thresholds hardcoded without constants |
| 22 | Error handling covers failures | ❌ 19 Supabase queries missing error destructuring |
| 23 | No swallowed errors | ❌ 14 catch blocks discard errors entirely |
| 24 | Migrations reversible | ⚠️ No DOWN migrations provided |
| 25 | Indexes for filtered columns | ❌ 11 spec indexes missing |
| 26 | Transactions for multi-step mutations | ❌ credit_wallet missing SECURITY DEFINER |
| 27 | Race conditions addressed | ❌ Submission double-submit, seq_num TOCTOU race |
| 28 | External API timeouts | ⚠️ Supabase Broadcast no cleanup |
| 29 | New logic has tests | ❌ Zero test files |
| 30 | Keyboard accessible | ✅ Standard HTML + shadcn/ui |
| 31 | Structured logging | ❌ 4 console.error, 14 routes swallow errors |
| 32 | Graceful degradation | ⚠️ Mock data fallback exists but may mask real failures |

**Score: 10 ✅, 10 ⚠️, 12 ❌ = BLOCKED**

---

## P0 — Critical (13 issues, blocks merge)

### 1. Admin page hardcoded open
**File:** `src/app/admin/page.tsx:14`
**Problem:** `const isAdmin = true` — admin panel (challenge creation, user management, feature flags, job queue) is accessible to everyone. No auth check, no server-side role verification.
**Fix:** Import `requireAdmin()`, make this a server component or add client-side auth check with server verification.

### 2. Middleware auth protection broken
**File:** `middleware.ts:5-7` + `src/lib/supabase/middleware.ts:29`
**Problem:** Middleware checks `pathname.startsWith('/(dashboard)')` but Next.js route groups with parentheses are stripped from URLs. The path is `/agents`, `/results`, `/wallet` — never `/(dashboard)/agents`. The `isProtected` variable is computed but never used. All dashboard routes are accessible without authentication.
**Fix:** Check actual URL paths: `['/agents', '/results', '/wallet', '/settings']` or use a prefix pattern that matches real URLs.

### 3. Users can SET their own coin balance
**File:** `00001_initial_schema.sql` — profiles table + UPDATE policy
**Problem:** `profiles.coins` column with "Users can update own profile" policy. Any authenticated user can `UPDATE profiles SET coins = 999999 WHERE id = auth.uid()`. Game-breaking exploit.
**Fix:** DROP `coins` from profiles (use arena_wallets only), or add trigger to prevent coin modification via UPDATE policy.

### 4. Challenge entry scoring fields directly editable
**File:** `00001_initial_schema.sql` — challenge_entries UPDATE policy
**Problem:** "Users can update own entries" policy has no column or status guard. Users can directly UPDATE `final_score`, `placement`, `elo_change`, `coins_awarded` on their own entries. Complete anti-cheat bypass.
**Fix:** Restrict UPDATE to `status IN ('entered', 'assigned', 'in_progress')` and exclude scoring columns from updatable fields.

### 5. In-memory rate limiter useless on serverless
**File:** `src/lib/utils/rate-limit.ts`
**Problem:** Uses `Map` in process memory. Vercel serverless functions are stateless — each cold start gets a fresh Map. Rate limiting is effectively disabled in production. Every API route depends on this.
**Fix:** Use Upstash Redis (`@upstash/ratelimit`) or Vercel KV. The architecture spec explicitly specifies this.

### 6. Judge scores visible during active challenges
**File:** `00001_initial_schema.sql` — judge_scores RLS
**Problem:** Policy is `USING (true)` — anyone can read all judge scores at any time. Leaks judging results during active challenges, enabling gaming.
**Fix:** Join-based policy: only visible when `challenges.status = 'complete'` or user owns the entry.

### 7. GitHub OAuth endpoint has no rate limiting
**File:** `src/app/api/auth/github/route.ts`
**Problem:** No `rateLimit()` call. Attacker can spam OAuth initiation to generate unlimited Supabase auth sessions.
**Fix:** Add IP-based rate limiting (5 req/min).

### 8. `credit_wallet()` and `update_agent_elo()` missing SECURITY DEFINER
**File:** `00003_forge_fixes.sql`
**Problem:** Both functions write to tables with restrictive RLS (arena_wallets, agent_ratings). Without SECURITY DEFINER, they run as the calling user who has no write policies. Coin credits and ELO updates silently fail in production.
**Fix:** Add `SECURITY DEFINER SET search_path = public`.

### 9. `get_next_seq_num()` race condition
**File:** `00004_live_events.sql:36-44`
**Problem:** `SELECT COALESCE(MAX(seq_num), 0) + 1` is a classic TOCTOU race. Two concurrent spectator events for the same entry get duplicate sequence numbers.
**Fix:** Use `INSERT ... RETURNING` with a serial/sequence, or advisory locking.

### 10. Submission double-submit race condition
**File:** `src/app/api/v1/submissions/route.ts:49-56`
**Problem:** Checks `entry.status !== 'assigned'` then updates to `submitted`. Between read and write, another request can submit for the same entry. No `SELECT ... FOR UPDATE` or unique constraint on submission.
**Fix:** Use Postgres function with `FOR UPDATE` locking, or add unique constraint.

### 11. Table name mismatch: `arena_wallets` vs `wallets`
**File:** `src/app/api/me/route.ts:28` queries `arena_wallets`, but migration 00001 creates `wallets`
**Problem:** Code references a table that doesn't exist in the original migration. Migration 00003 creates `arena_wallets` as a separate table. The old `wallets` table (transaction log) and new `arena_wallets` (balance) coexist but the `wallet_transactions` table from the spec is completely missing. No audit trail with balance snapshots.
**Fix:** Reconcile table names and create `wallet_transactions` per spec.

### 12. `pick_job()` ignores priority and scheduled_for
**File:** `00003_forge_fixes.sql`
**Problem:** Orders only by `created_at ASC`, doesn't check `scheduled_for <= NOW()`. High-priority jobs get no priority. Future-scheduled jobs execute immediately. Judging pipeline ordering broken.
**Fix:** Add `AND scheduled_for <= NOW()` filter, `ORDER BY priority ASC, scheduled_for ASC`.

### 13. Missing `pg_cron` extension (migration 00004 calls `cron.schedule()`)
**File:** `00004_live_events.sql` calls `cron.schedule()` but no migration creates the extension
**Problem:** Live events cleanup cron will fail on deploy.
**Fix:** Add `CREATE EXTENSION IF NOT EXISTS "pg_cron"` in migration 00001.

---

## P1 — High (19 issues, fix before merge)

### 14. 19 Supabase queries missing error destructuring
**Files:** All API routes (me/route.ts, agents/[id], challenges/[id], replays, admin/jobs, all v1 connector routes)
**Problem:** Destructure `{ data }` without `{ error }`. DB failures return null silently — masked as "not found" instead of 500.
**Pattern:** This is Maks's #1 known blind spot. Every `.from().select()` needs `{ data, error }`.

### 15. Path params not validated across 6 routes
**Files:** `agents/[id]`, `challenges/[id]`, `challenges/[id]/enter`, `replays/[entryId]`, `leaderboard/[weightClass]`, `admin/judge/[challengeId]`
**Problem:** URL params used directly in DB queries without `z.string().uuid()` validation.

### 16. `select('*')` over-fetching in 7 routes
**Files:** `me/route.ts`, `agents/[id]` GET/PATCH, `challenges/route.ts`, `challenges/[id]`, `admin/jobs`, `v1/challenges/assigned`
**Problem:** May expose internal fields like `api_key_hash`, judge prompts, admin config.

### 17. `requireAdmin()` masks DB errors as auth failures
**File:** `src/lib/auth/require-admin.ts:6`
**Problem:** Doesn't check Supabase error on profile query. A DB outage returns "Forbidden" instead of 500.

### 18. `authenticateConnector()` duplicated 4 times
**Files:** All 4 v1 connector routes copy-paste the same function.
**Fix:** Extract to `@/lib/auth/authenticate-connector.ts`.

### 19. Missing `wallet_transactions` table
Spec defines it with `wallet_id` FK, `balance_after`, and `type` CHECK. No audit trail exists.

### 20. `model_registry` schema completely wrong
Migration uses `id TEXT` (name as PK). Spec requires `id UUID`, `name TEXT UNIQUE`, `mps SMALLINT CHECK (1-100)`.

### 21. `agents` table missing spec columns
Missing: `model_id UUID REFERENCES model_registry(id)`, `metadata JSONB`, `search_vector TSVECTOR`. Has unauthorized `soul_config jsonb`.

### 22. `job_queue` missing `priority` and `scheduled_for`
Both required by spec and used by `pick_job()`.

### 23. `judge_scores` wrong types, no CHECK constraints
Spec: `SMALLINT CHECK (BETWEEN 1 AND 10)`. Migration: `real default 0` with no CHECK.

### 24. Missing anti-Sybil trigger
Spec defines `check_single_agent_per_user()` — not present. Users can create unlimited agents.

### 25. `challenge_prompts.difficulty` wrong type
Spec: `SMALLINT CHECK (BETWEEN 1 AND 5)`. Migration: `TEXT` with string values.

### 26. 11 spec indexes missing
Including GIN indexes for full-text search, partial indexes for active challenges, composite indexes for leaderboard queries.

### 27. Type definitions use `string` instead of unions
**File:** `src/types/challenge.ts` — `category: string`, `format: string`, `status: string` should be union types. This causes the only `as any` in the codebase.

### 28. Zero test files
Architecture spec requires unit tests for ELO, MPS, validators, API key, badges, quests + integration + E2E. None exist.

### 29. Realtime channel not cleaned up
**File:** `src/app/api/v1/events/stream/route.ts:109` — creates channel, sends broadcast, never calls `removeChannel()`.

### 30. Unbounded queries
**File:** `admin/jobs/route.ts:44` fetches ALL jobs for stats. `challenges/[id]/route.ts:28` fetches all entries with no LIMIT.

### 31. admin/challenges POST uses user Supabase client
**File:** `src/app/api/admin/challenges/route.ts` — uses `createClient()` (user session) not `createAdminClient()` for admin operations. May fail if RLS doesn't allow admin inserts through user session.

### 32. Missing CSRF Origin header check
No POST/PATCH routes validate the `Origin` header matches `NEXT_PUBLIC_APP_URL`.

---

## P2 — Medium (12 issues)

### 33-38. 14 catch blocks swallow errors without logging
### 39. 4 `console.error` statements (should be structured logging)
### 40. GitHub OAuth route creates inline Supabase client instead of shared
### 41. Middleware `isProtected` computed but never used (dead code)
### 42. `badges.rarity` CHECK includes 'uncommon' not in spec
### 43. `weight_classes` missing `sort_order`, `active` vs `is_active`
### 44. Missing DOWN migrations (not reversible)

---

## P3 — Low (5 issues)

### 45. Health endpoint hardcodes version `1.0.0`
### 46. Inconsistent error response shapes (`{error}` vs `{error, details}`)
### 47. MPS thresholds hardcoded as magic numbers
### 48. Runtime constants in type files
### 49. `void` used to suppress unused variable warnings

---

## What's Good

- **TypeScript strict: true** with only 1 `as any` in 189 files — excellent discipline
- **Auth uses `getUser()` not `getSession()`** on server — correct and secure
- **Supabase client separation** is textbook: client.ts / server.ts / admin.ts / middleware.ts
- **Zod validation** present at every API boundary with proper `safeParse`
- **Event sanitizer** (`sanitize-event.ts`) has 12 regex patterns for secrets, IPs, connection strings — thorough defense in depth
- **RLS enabled on all 18 tables** — the policies need tightening but the gates exist
- **Glicko-2 rating system** via proper npm package — better than basic ELO
- **Live spectator system** with sequence numbers and broadcast — architecturally sound
- **Job queue** with atomic `pick_job()` using `FOR UPDATE SKIP LOCKED` — correct pattern
- **0 `console.log` statements** — no debug artifacts
- **Clean component hierarchy** — arena components, shadcn/ui, proper server/client split
- **Mock data fallback** when Supabase env missing — good DX for development

---

## Verdict

**❌ BLOCKED — 13 P0 issues, 19 P1 issues**

The build is substantial and architecturally sound in many areas, but the security holes are critical. The open admin panel, broken middleware auth, direct coin/score manipulation via RLS, and non-functional rate limiting make this unshippable.

**Top 5 must-fix before re-review:**
1. Fix admin page auth (server-side `requireAdmin()`)
2. Fix middleware to protect actual URL paths
3. Lock down RLS: no coin/score direct updates, immutable submissions, judge scores hidden until complete
4. Implement real rate limiting (Upstash Redis)
5. Add SECURITY DEFINER to coin/ELO functions

**Estimated fix time:** 4-6 hours for P0s, another 4-6 for P1s.

---

🔥 Forge
