# Aegis Full-Platform Trust & Security Audit — Bouts
**Date:** 2026-03-30
**Auditor:** Aegis 🛡
**URL:** https://agent-arena-roan.vercel.app
**Codebase:** /data/agent-arena
**Scope:** Full platform — auth, submissions, org boundaries, abuse, data exposure, methodology integrity
**Status:** RECOVERED — audit was mid-write when rate limit hit. This is the complete audit reconstructed from session transcript.

---

## 1. OVERALL VERDICT

### ⚠️ LAUNCH-SAFE WITH ISSUES

The platform has a solid security foundation: auth gates hold, admin routes are protected, injection attacks are rejected, and role boundaries are real. There are **no P0 launch blockers** — no unauthed access to protected resources, no judging manipulation vectors, no admin data in public responses.

However, there are **4 P1 issues** that must be addressed before launch, plus methodology integrity gaps that will undermine user trust if not resolved before real users compete.

---

## 2. SCORECARD

| Category | Score | Status |
|---|---|---|
| Authentication & Session | 9/10 | ✅ Strong |
| Role Boundaries & RBAC | 8/10 | ✅ Good |
| Submission Path Security | 7/10 | ⚠️ Issues |
| Org/Private Boundaries | 9/10 | ✅ Strong |
| Data & Error Exposure | 8/10 | ✅ Good |
| Abuse Resistance | 7/10 | ⚠️ Issues |
| Admin Safety | 9/10 | ✅ Strong |
| Cron/Internal Endpoints | 7/10 | ⚠️ Issues |
| Methodology Integrity | 6/10 | ⚠️ Gaps |
| API Hygiene | 8/10 | ✅ Good |
| QA Hygiene | 7/10 | ⚠️ Issues |

---

## 3. CONFIRMED PROTECTIONS

**Auth gates — all holding (verified live):**
- `/api/me` → 401 unauthed ✅
- `/api/admin/*` → 401 unauthed ✅
- `/api/internal/*` → 401 unauthed ✅
- `/api/cron/*` → 401 unauthed ✅
- `/api/webhooks/judge` → 401 unauthed ✅
- `/api/submissions/[id]/breakdown` → 401 unauthed ✅
- JWT manipulation (role escalation) → 401 ✅

**Admin route protection:**
- `requireAdmin()` checks both auth and DB role — no bypass via is_admin boolean trick ✅
- Admin analytics, health, developer-metrics all 401 unauthed ✅
- Connector key (GAUNTLET_INTAKE_API_KEY) rejected at admin endpoints ✅

**Submission ownership:**
- Connector: entry belongs to agent check ✅
- Web: entry belongs to authenticated user's agent ✅
- Session: `.eq('agent_id', agent.id)` enforced ✅
- v1 sessions/[id]/submissions: session must belong to authenticated user ✅

**Org/private boundaries (v1):**
- `canAccessOrgChallenge()` consistently applied across: challenge detail, session create, result fetch, breakdown fetch ✅
- Hard 404 (not 403) on private challenge access — no existence acknowledgment ✅
- Org membership required for org challenge listing ✅
- Sandbox token isolation: `is_sandbox` enforced via `enforceEnvironmentBoundary()` ✅
- v1 anonymous requests cannot see sandbox challenges ✅

**Judging integrity:**
- Challenge prompt/hidden tests not in any public API response ✅
- Judge weights, CDI scores, calibration results not in competitor-facing API ✅
- Replay blocked until challenge status = `complete` ✅
- Admin-only fields absent from all competitor/public API responses ✅

**Error hygiene:**
- No PostgresError, file paths, or env var names in responses ✅
- Generic "internal server error" in catch blocks ✅
- v1 responses use structured envelope (no raw DB error leakage) ✅

**Rate limiting (live):**
- Connector submit: 5/min per agent ✅
- Web submit: 3/min per user ✅
- Violations report: 3/hour per user ✅
- Token creation: 10/hour per user ✅

---

## 4. ISSUE LIST

### P1 FINDINGS

---

**AEG-P1-001 — Dual submission routes with inconsistent pipelines (methodology integrity risk)**
- **Routes:** `/api/v1/submissions` (POST) vs `/api/connector/submit` (POST)

The old v1/submissions route and the new connector/submit route are both live and both accept connector submissions. They behave fundamentally differently:

| Behavior | `/api/v1/submissions` | `/api/connector/submit` |
|---|---|---|
| Inserts into `submissions` table | ❌ No | ✅ Yes |
| Creates immutable artifact | ❌ No | ✅ Yes |
| Content hash dedup | ❌ No | ✅ Yes |
| `submission_source` tagging | ❌ No | ✅ Yes |
| Version snapshot | ❌ No | ✅ Yes |
| Judging queue (`enqueue_judging_job`) | ❌ No (fires edge functions directly) | ✅ Yes |
| Event logging | ❌ No | ✅ Yes |
| Scope enforcement (`submission:create`) | ❌ Bypassed | ✅ Enforced |

The v1/submissions route updates `challenge_entries` directly, creates no `submissions` record, stores no artifact, and triggers judging via direct edge function calls. No audit trail. Submissions via this path will not appear in result/breakdown queries that JOIN via the submissions table.

**Fix:** Deprecate `/api/v1/submissions` as a submission endpoint or redirect it to `/api/connector/submit`. Do not run two inconsistent pipelines simultaneously.

---

**AEG-P1-002 — Sandbox challenges visible to anonymous users via `/api/challenges`**

The legacy `GET /api/challenges` route returns sandbox challenges (`[Sandbox]` prefixed titles) to unauthenticated users. The v1 route correctly applies `sandboxFilter()`. The old route applies no `is_sandbox` filter at all. `/api/challenges/[id]` also returns full sandbox challenge detail to anonymous users.

**Verified live:** `curl https://agent-arena-roan.vercel.app/api/challenges` returns [Sandbox] Hello Bouts, [Sandbox] Echo Agent, etc.

**Fix:** Add `.eq('is_sandbox', false)` to `/api/challenges` and `/api/challenges/[id]` for unauthenticated requests.

---

**AEG-P1-003 — Reserve and upcoming challenges fully discoverable via public API**

Both `/api/challenges` and `/api/v1/challenges` return all challenges regardless of status — including `reserve` (11 challenges) and `upcoming` (39+ challenges) with full titles, descriptions, formats, and difficulty profiles. Pipeline-internal test challenges (`Pipeline-Test: [title]`) also visible.

**Impact:** Competitors can read descriptions of upcoming challenges before they go live. Strategic advantage for agents pre-tuned to specific challenges.

**Fix:** Filter public challenge lists to `active` and `complete` statuses. Add `.in('status', ['active', 'complete'])` to non-admin public challenge queries. Or make explicit product decision to allow preview.

---

**AEG-P1-004 — Cron endpoints fail-open when `CRON_SECRET` is unset**

Both `GET /api/cron/challenge-quality` and `GET /api/cron/gauntlet` use a fail-open guard:

```typescript
if (cronSecret && authHeader !== `Bearer ${cronSecret}`) { return 401 }
// ^^^ if cronSecret is unset, this whole block is skipped
```

If `CRON_SECRET` env var is missing, any anonymous caller can trigger challenge quarantine/flagging and challenge generation (real LLM cost). Contrast with `/api/internal/process-jobs` which correctly uses `if (!cronSecret || ...)` (fail-closed).

**Fix:**
```typescript
if (!cronSecret || authHeader !== `Bearer ${cronSecret}`) {
  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
}
```
Apply to both cron routes.

---

### P2 FINDINGS

**AEG-P2-001 — `/qa-login` returns HTTP 200 with "Not Found" content**
The page renders the custom 404 UI but HTTP status is 200. The route exists, it just shows a 404 page. A scanner sees it resolves to something rather than a hard 404.

**AEG-P2-002 — `/api/challenges/[id]` has no status gate for reserve/upcoming**
If a user knows the UUID of a reserve challenge, they can retrieve full detail before it goes live.

**AEG-P2-003 — v1/submissions does not use `submission:create` scope gate**
The old route bypasses the v1 scope system entirely. The new v1/sessions/[id]/submissions correctly uses `requireScope()`.

**AEG-P2-004 — Public replays endpoint has no org_id filter**
`GET /api/replays` lists all judged/scored/complete entries with no org_id check. Future org-private challenges could leak entries here.

**AEG-P2-005 — `/api/challenges` has no org_id filter**
Theoretical now (zero org challenges exist) but becomes a real bug once org features are used.

---

### P3 FINDINGS

**AEG-P3-001 — Internal migration endpoints still live in production**
`/api/internal/run-migration` and `/api/internal/apply-migration` are orphaned post-migration endpoints. Protected but unnecessary attack surface.

**AEG-P3-002 — `v1/events/stream` returns 405 instead of 401 for unauthenticated GET**
Minor: discloses route existence and expected method.

**AEG-P3-003 — API key format hinted in 401 error response**
The hint `"Send API key via x-arena-api-key header or Authorization: Bearer aa_xxx"` in `/api/v1/submissions` 401 response mildly discloses expected key format.

---

## 5. ABUSE VECTORS / TRUST GAPS

| Abuse Case | Status | Notes |
|---|---|---|
| Duplicate submission (connector) | ✅ Blocked | Terminal status check in connector/submit |
| Duplicate submission (v1/submissions) | ⚠️ Partial | SUBMITTABLE_STATUSES blocks but no submissions table dedup |
| Late submission after deadline | ✅ Blocked | validateChallengeTimeWindow enforced |
| Oversized payload | ✅ Blocked | 100KB limit + validateSubmission |
| Malformed payload | ✅ Blocked | Zod validation on all routes |
| Wrong challenge state | ✅ Blocked | challenge.status !== 'active' gate |
| JWT manipulation / role escalation | ✅ Blocked | Supabase verifies signature server-side |
| Cross-competitor data bleed | ✅ Blocked | All owned-object checks use auth.user_id |
| Competitor accessing admin | ✅ Blocked | requireAdmin() enforced, verified live |
| Connector key to admin routes | ✅ Blocked | Rejected at admin endpoints |
| Hidden test extraction | ✅ Blocked | Not in any public API response |
| Judge weight leakage | ✅ Blocked | Absent from all public API responses |
| Replay before challenge complete | ✅ Blocked | challenge.status === 'complete' gate |
| Cron replay | ✅ Idempotent | CDI enforcement pass is read-oriented |
| DB error leakage | ✅ Blocked | Generic messages in all catch blocks |

---

## 6. METHODOLOGY INTEGRITY RISKS

1. **Dual submission pipelines** — AEG-P1-001 above. Submissions via old path have no artifact, no content hash, no audit trail. Cannot prove what was submitted.

2. **Reserve/upcoming challenge discovery** — Sophisticated API users can enumerate all upcoming challenge descriptions before launch. Enables pre-tuning.

3. **No DB-level UNIQUE constraint on `submissions(entry_id)`** — Application-level status check and submissions INSERT are not atomic. Under concurrent rapid requests, duplicate judging is possible.

4. **Self-reported model field (`reported_model`) is unverified** — Platform cannot verify an agent claiming to be `claude-3-5-sonnet` actually used it. Weight class / reputation built on unverifiable root.

5. **No visual distinction between `verified` and `legacy` submission paths** — When both appear in leaderboards, they are indistinguishable to users.

---

## 7. EXACT FIXES BEFORE LAUNCH (Prioritized)

**15 min — Fix cron fail-open guards (AEG-P1-004)**
Change `if (cronSecret && ...)` to `if (!cronSecret || ...)` in challenge-quality and gauntlet routes.

**30 min — Deprecate `/api/v1/submissions` as submission path (AEG-P1-001)**
Add redirect or 410 Gone response pointing to `/api/connector/submit`.

**30 min — Add `is_sandbox: false` filter to `/api/challenges` (AEG-P1-002)**
One-line query change.

**1 hour — Filter challenge list to active/complete statuses (AEG-P1-003)**
Add `.in('status', ['active', 'complete'])` to non-admin public challenge queries. Or make explicit product decision.

**30 min — Remove orphaned migration endpoints (AEG-P3-001)**
Delete `/api/internal/run-migration` and `/api/internal/apply-migration` routes.

---

## RESUME INSTRUCTIONS

Aegis had just finished writing this audit and hit the rate limit on the write. The full findings above are reconstructed from the session transcript. When resuming Aegis, say:

"Aegis — your full audit was recovered. The file is at /data/.openclaw/workspace-aegis/AUDIT_FULL_PLATFORM_TRUST_2026-03-30.md. Please review it, confirm the findings are accurate, and send a summary to Forge with the P1 fix list. Priority order: AEG-P1-004 first (cron fail-open), then AEG-P1-001 (dual submission routes), then AEG-P1-002 (sandbox leakage), then AEG-P1-003 (reserve challenge visibility)."
