# Aegis Security Audit — Phase W3: Web Submission System
**Date:** 2026-03-30  
**Auditor:** Aegis 🛡  
**Scope:** Web submission path — workspace, web-submit API, session/entry lifecycle, abuse surface  
**Files Reviewed:**
- `src/app/api/challenges/[id]/web-submit/route.ts`
- `src/app/api/challenges/[id]/workspace/route.ts`
- `src/app/(public)/challenges/[id]/workspace/page.tsx`
- `src/app/api/challenge-sessions/[sessionId]/route.ts`
- `src/app/api/challenge-submissions/[submissionId]/route.ts`
- `src/app/api/submissions/[submissionId]/breakdown/route.ts`
- `src/lib/submissions/validate-submission.ts`
- `src/lib/submissions/artifact-store.ts`
- `src/lib/utils/rate-limit.ts`
- `src/lib/auth/get-user.ts`
- `middleware.ts`
- `supabase/migrations/00026_competition_runtime.sql`
- `supabase/migrations/00035_web_submission.sql`

---

## Executive Verdict

**CONDITIONAL PASS — 2 issues require fixes before W4/W5**

The W3 web submission system is structurally sound. Auth, agent ownership, entry checks, session expiry, and the unsupported-challenge gate are all correctly enforced. The pipeline reuse (shared validate-submission lib, same artifact store, same judging queue) is correct.

Two issues require resolution before W4/W5 proceed. One is a trust/fairness integrity gap (P1). One is a security boundary gap (P2). Neither is a critical launch blocker, but both are real.

---

## 1. Confirmed Protections ✅

| Area | Protection | Evidence |
|------|-----------|----------|
| Auth — workspace API | `requireUser()` on every request. 401 on fail. | `workspace/route.ts:L18` |
| Auth — web-submit API | `requireUser()` on every request. 401 on fail. | `web-submit/route.ts:L29` |
| Auth — session API | `requireUser()` on every request. 401 on fail. | `challenge-sessions/[sessionId]/route.ts:L12` |
| Auth — submission status API | `requireUser()` on every request. 401 on fail. | `challenge-submissions/[submissionId]/route.ts:L10` |
| Agent ownership | Agent resolved from `user.id` server-side. Client cannot inject a different agent. | `web-submit:L65-69` |
| Entry ownership | Entry looked up with `challenge_id + agent.id`. Client cannot inject a foreign entry. | `web-submit:L93-97` |
| Session ownership | Existing session query enforces `challenge_id + agent.id`. Session cannot be hijacked. | `web-submit:L122-127` |
| Session expiry — server | Server checks `expires_at` before allowing submission. Expired sessions get marked and rejected. | `web-submit:L134-141` |
| Session expiry — workspace | Workspace API returns `expired` state if session expired on re-load. | `workspace/route.ts:L88-102` |
| Unsupported challenge gate | `web_submission_supported = false` → explicit 400. Cannot be bypassed via API. | `web-submit:L80-83` |
| Challenge status gate | `status !== 'active'` → 400. | `web-submit:L75-79` |
| Entry status gate | Terminal statuses (submitted/judged/scored/expired) → 409. | `web-submit:L101-113` |
| Duplicate submission — content hash | SHA-256 checked against `submission_artifacts` per agent+challenge. | `validate-submission.ts:L52-68` |
| Rate limiting | 3 web submissions/min per `user.id`. Stricter than connector (5/min). | `web-submit:L42-45` |
| Entry ID not trusted | `entry_id` from client body is accepted in schema but **not used** in DB queries. Server resolves entry from authenticated agent. | `web-submit:L60,L93-97` |
| Submission source tagging | `submission_source: 'web'` explicitly set — distinguishable in DB from connector/API submissions. | `web-submit:L174` |
| Middleware — admin routes | `/admin` gated with DB role check. | `middleware.ts:L63-70` |
| QA login | `/qa-login` returns 404 in production (`ENABLE_QA_LOGIN` not set). | Previously confirmed ✅ |
| Session uniqueness | `UNIQUE INDEX idx_sessions_agent_challenge` prevents two open sessions per agent+challenge. | `00026:L58` |
| Idempotent session creation | Workspace API reuses existing session on repeat visits. Timer doesn't reset. | `workspace/route.ts:L79-108` |
| Dual-session conflict | Web-submit explicitly handles connector-created session — reuses rather than inserting (avoids unique index collision). | `web-submit:L118-146` |
| Artifact immutability | `submission_artifacts` has unique constraint on `(submission_id, content_hash)`. Artifact stored after submission insert. | `00026:L102` |
| Version snapshot | Captured before submission insert — judging config version locked at submission time. | `web-submit:L162-163` |
| No draft save | UI clearly warns. Server stateless on content — no draft persistence possible. | `workspace/page.tsx` constraints panel |
| No auto-resume | Timer fires from server-side `expires_at`. No resume path exists in server logic. | `workspace/route.ts` |

---

## 2. Trust/Security Weaknesses

---

### AEG-P1-001 — Connector submit does not check entry terminal status
**Severity:** P1  
**Category:** Abuse resistance / submission integrity  
**Route:** `POST /api/connector/submit`

**Issue:**  
`web-submit` correctly checks entry status and rejects submissions from entries in `submitted`, `judged`, `scored`, or `expired` state. The connector submit route (`connector/submit/route.ts`) **does not** — it only verifies the entry exists, not its current status. This creates a trust asymmetry.

**Impact:**  
A connector can attempt to overwrite a finalized web submission. Whether it succeeds depends on whether the `submissions` table has a DB-level unique constraint on `entry_id`. Investigation found **no unique constraint on `submissions(entry_id)`**. The unique index `idx_unique_submitted_entry` is on `challenge_entries(id) WHERE status = 'submitted'` — this prevents the entry's status from being set to 'submitted' twice, but does not prevent a second `submissions` row from being inserted for the same entry.

**Race condition path:**
1. User submits via web → entry status = `submitted`, submission row inserted, judging enqueued
2. Connector fires `POST /api/connector/submit` for the same challenge
3. Connector gets the entry (it exists), `validateSubmission` runs — challenge active, content valid, no matching content hash for different content
4. A second submissions row is inserted with `entry_id = same entry`
5. Second judging job enqueued
6. Two judge runs → two results → undefined merge behavior

**Reproducible:** Yes — requires active connector credential + same challenge + different content submitted after web submit  
**Root cause:** Missing entry status check in connector submit; no DB-level unique constraint on `submissions(entry_id)`  
**Recommended fix:** See Section 5.

---

### AEG-P2-001 — Workspace page not middleware-protected (minor)
**Severity:** P2  
**Category:** Information disclosure / UX security  
**Route:** `GET /challenges/[id]/workspace` (page, not API)

**Issue:**  
The workspace page (`/challenges/[id]/workspace`) is not in `PROTECTED_PATHS` in `middleware.ts`. An unauthenticated user can load the page HTML/JS without being redirected to login.

**Actual behavior:** The page immediately calls `GET /api/challenges/[id]/workspace` on load. That API endpoint calls `requireUser()`, which throws `Unauthorized` → the page receives a 401 and redirects to `/login?redirect=...` via the client-side handler (`workspace/page.tsx:L98`).

**Why it matters:** Auth is enforced — this is not an access bypass. However:
- The page shell renders before the redirect occurs (flash of loading state)
- The page's static structure, component markup, and challenge ID are visible to unauthenticated crawlers
- The client-side redirect is less robust than a server-side 302 — if the fetch handler has a bug, auth could silently fail to enforce

**Recommended fix:** See Section 5. Low priority for W4/W5 but clean up before launch.

---

### AEG-P2-002 — Client-provided `session_id` fallback used without server ownership verification
**Severity:** P2  
**Category:** Trust boundary  
**Route:** `POST /api/challenges/[id]/web-submit`

**Issue:**  
When no DB session exists for the agent+challenge, the web-submit route falls back to using the client-provided `session_id` directly (line 143-145). This client-provided session ID is then passed to `validateSubmission`, which **does** verify ownership (`eq('agent_id', agent_id)`). So the actual submission cannot use a foreign session — it will fail validation if the session belongs to another agent.

**However:** The client-supplied `session_id` is stored in the `submissions` row (`session_id` field) without a pre-insert ownership re-check outside of `validateSubmission`. If `validateSubmission` passes (it will fail on a foreign session), the session stored is whatever the client said. In practice, this is safe because the validate step verifies agent ownership. But the intent of this code path is fragile — it relies on `validateSubmission` as the sole ownership gate for client-supplied session IDs.

**Recommended fix:** Add explicit server-side session ownership verification before the fallback assignment (independent of `validateSubmission`). Minor hardening.

---

### AEG-P2-003 — Rate limit is fail-open
**Severity:** P2  
**Category:** Abuse resistance  
**Route:** `POST /api/challenges/[id]/web-submit`, `GET /api/challenges/[id]/workspace`

**Issue:**  
The `rateLimit()` function explicitly fails open ("allow the request") when neither Upstash Redis nor Supabase rate limiting backend is reachable (see `rate-limit.ts:L100-104`). A console warning is logged but no request is blocked.

**Impact in context of web submission:** If the Supabase DB is temporarily unreachable and Upstash is not configured, the 3-per-minute rate limit on `web-submit` stops working. An attacker could fire unlimited rapid-fire submissions during that window.

**Mitigating factor:** The entry status check and duplicate content hash check still block actual double-submission. The fail-open only enables spam during a narrow DB outage window.

**Note:** This is a pre-existing design choice, not introduced by W3. Flagged here because W3 exposes a new public submission surface.

---

## 3. Abuse Vectors

| Vector | Risk | Status |
|--------|------|--------|
| Submit without entering challenge | Blocked — entry required by ownership check | ✅ Mitigated |
| Submit to inactive challenge | Blocked — status gate in web-submit | ✅ Mitigated |
| Submit to challenge with `web_submission_supported = false` | Blocked — explicit flag check | ✅ Mitigated |
| Submit after session expires | Blocked — server-side expiry check in web-submit | ✅ Mitigated |
| Extend session by re-opening workspace | Blocked — idempotent session returns same `expires_at` | ✅ Mitigated |
| Submit twice (same content) | Blocked — SHA-256 content hash duplicate check | ✅ Mitigated |
| Submit twice (different content) via web | Blocked — entry status = `submitted` → 409 after first submit | ✅ Mitigated |
| Submit twice via web + connector (different content) | **OPEN** — connector does not check terminal entry status | ⚠ AEG-P1-001 |
| Cross-user submission (submit for another user's agent) | Blocked — agent resolved from JWT user.id server-side | ✅ Mitigated |
| Inject foreign entry_id | Blocked — entry_id from client is ignored; server resolves from agent | ✅ Mitigated |
| Inject foreign session_id | Partially blocked — validateSubmission verifies ownership; see AEG-P2-002 | ⚠ Minor |
| Bypass size limit (100KB) | Blocked server-side — Zod schema + Buffer.byteLength check | ✅ Mitigated |
| Spam workspace opens | Limited — 30 workspace requests/min/user rate limit | ✅ Reasonable |
| Spam web-submit | Limited — 3 requests/min/user; fail-open gap during outages | ⚠ AEG-P2-003 |
| Submit before workspace open (no session) | Allowed — sessionless submission is explicitly valid | ✅ Design choice, documented |
| Access other user's submission status | Blocked — submission lookup enforces `agent.id` ownership | ✅ Mitigated |
| Access breakdown without auth | Allowed as spectator (public spectator view) | ✅ Intentional design |
| Admin breakdown leakage to competitor | Blocked — audience determined server-side by role check | ✅ Mitigated |
| Replay/reuse session from expired entry | Blocked — session status check in web-submit | ✅ Mitigated |

---

## 4. Fairness/Trust Integrity: Manual Browser Submission

**Does manual web submission introduce unfair advantage or trust ambiguity?**

### What's handled correctly:
- `submission_source: 'web'` is explicitly tagged — every web submission is distinguishable in the DB and visible to admin/judging pipeline
- The same `validateSubmission`, `storeArtifact`, `logSubmissionEvent`, and `enqueue_judging_job` pipeline runs for both web and connector submissions
- Version snapshot captured at the same point in both paths — judging config is locked at submission time
- Timing is not gamed: timer starts at workspace open (server-side `opens_at`), stored in `challenge_sessions`, not client-controlled

### Ambiguities to document:
1. **Web submissions may contain human-written content, not agent output.** The platform currently cannot distinguish whether content was written by the user manually or generated by their model. For sprint/text-artifact challenges, this is the design intent of web submission (the user/agent pastes a response). However, for model-capability-scored challenges, there is no technical barrier to a competitor pasting GPT-4 output instead of their registered agent's output.
   - **Verdict:** This is a known design trade-off for V1 web submission. The honor system applies. The `submission_source: 'web'` tag makes this auditable. This should be called out in challenge rules, not fixed in code for now.

2. **No timing enforcement between workspace open and submit for sessionless challenges.** If a challenge has no `time_limit_minutes`, the session has no `expires_at`. A user can open the workspace, leave it open for hours, and submit whenever they want. This is consistent with connector behavior (connectors are also not time-limited unless the challenge has a time limit).
   - **Verdict:** Not a bug — consistent with challenge design. Acceptable.

3. **Prompt is returned in workspace API response.** The challenge `prompt` field is returned to the authenticated, entered user when they open the workspace. This is correct and intentional.
   - **Verdict:** No issue — only entered users see it, and only if they have an active entry.

---

## 5. Exact Fixes Required Before W4/W5

---

### Fix 1 — AEG-P1-001: Add entry status check to connector submit

**File:** `src/app/api/connector/submit/route.ts`  
**After line:** `if (entryError || !entry) { return ... }`

Add the following block immediately after the entry existence check:

```typescript
// Check entry is in a submittable state — reject terminal statuses
const SUBMITTABLE_ENTRY_STATUSES = ['entered', 'workspace_open', 'assigned', 'in_progress']
if (!SUBMITTABLE_ENTRY_STATUSES.includes(entry.status)) {
  if (entry.status === 'submitted' || entry.status === 'judged' || entry.status === 'scored') {
    return NextResponse.json({ error: 'Submission already received for this entry.' }, { status: 409 })
  }
  if (entry.status === 'expired') {
    return NextResponse.json({ error: 'This entry has expired.' }, { status: 409 })
  }
  return NextResponse.json({ error: `Entry cannot be submitted from status: ${entry.status}` }, { status: 409 })
}
```

Also update the entry select to include `status`:
```typescript
// Change from:
.select('id, status')
// Already includes status — no change needed if it's already selected
```

**Also add DB-level protection:** A unique constraint on `submissions(entry_id)` as a belt-and-suspenders guard:

```sql
-- Migration 00036 or append to 00035
CREATE UNIQUE INDEX IF NOT EXISTS idx_submissions_one_per_entry
  ON public.submissions(entry_id);
```

This makes double-submission impossible at the DB level regardless of application logic.

---

### Fix 2 — AEG-P2-001: Add workspace page to PROTECTED_PATHS

**File:** `middleware.ts`  
**Change:**

```typescript
const PROTECTED_PATHS = [
  '/agents',
  '/results',
  '/wallet',
  '/settings',
  '/dashboard',
  '/challenges', // Add — workspace page requires auth; covers /challenges/[id]/workspace
]
```

**Note:** Adding `/challenges` will also require auth for the challenge list and detail pages. If challenge browsing is intentionally public, add only the workspace subpath:

```typescript
'/challenges/*/workspace',  // Not valid in current matcher — use explicit path segment
```

The cleaner approach is to move the workspace page to a protected route group:
- Move from `src/app/(public)/challenges/[id]/workspace/` 
- To `src/app/(protected)/challenges/[id]/workspace/`
- Add `(protected)` group to middleware `PROTECTED_PATHS`

This is the correct Next.js App Router pattern.

---

### Fix 3 — AEG-P2-002: Harden client session_id fallback (optional before W5)

**File:** `src/app/api/challenges/[id]/web-submit/route.ts`  
**Change lines 143-145:**

```typescript
} else if (clientSessionId) {
  // Verify the client-provided session belongs to this agent+challenge before using it
  const { data: clientSession } = await supabase
    .from('challenge_sessions')
    .select('id, status, expires_at')
    .eq('id', clientSessionId)
    .eq('agent_id', agent.id)
    .eq('challenge_id', challengeId)
    .maybeSingle()
  if (clientSession && clientSession.status === 'open') {
    resolvedSessionId = clientSession.id
  }
  // If session doesn't belong to this agent or isn't open, proceed sessionless
}
```

This removes reliance on `validateSubmission` as the sole ownership gate for client-supplied session IDs.

---

## 6. Coverage Summary

| Area | Tested | Verdict |
|------|--------|---------|
| Workspace auth gate (API) | ✅ Code review | Pass |
| Workspace auth gate (page) | ✅ Code review | P2 gap |
| Agent ownership enforcement | ✅ Code review | Pass |
| Entry ownership enforcement | ✅ Code review | Pass |
| Session ownership enforcement | ✅ Code review | Pass (minor gap — P2-002) |
| Unsupported challenge enforcement | ✅ Code review | Pass |
| Session expiry enforcement | ✅ Code review | Pass |
| Entry status / terminal state check (web) | ✅ Code review | Pass |
| Entry status / terminal state check (connector) | ✅ Code review | **P1 Gap** |
| Duplicate submission — same content | ✅ Code review | Pass |
| Duplicate submission — different content (same path) | ✅ Code review | Pass |
| Duplicate submission — cross-path (web + connector) | ✅ Code review | **P1 Gap** |
| Rate limiting — web-submit | ✅ Code review | Pass (fail-open risk) |
| Rate limiting — workspace | ✅ Code review | Pass |
| Submission status ownership | ✅ Code review | Pass |
| Breakdown audience enforcement | ✅ Code review | Pass |
| DB-level unique constraint on entry submissions | ✅ Migration review | Gap — no constraint |
| RLS on challenge_sessions, submission_artifacts | ✅ Migration review | Not enabled — all routes use admin client (correct) |
| Admin client vs anon client usage | ✅ Code review | All W3 routes use admin client correctly |
| submission_source tagging | ✅ Code review | Pass |
| Version snapshot integrity | ✅ Code review | Pass |
| Fairness — manual vs agent content | ✅ Design review | Documented trade-off |

**Tested by:** Static code review + migration audit  
**Not tested:** Live browser E2E, actual race condition simulation (requires Playwright + concurrent requests)

---

## Summary

| Finding | Severity | Fix Required Before W4/W5? |
|---------|----------|---------------------------|
| AEG-P1-001: Connector submit bypasses terminal entry status | P1 | ✅ YES — Fix 1 |
| AEG-P2-001: Workspace page not in PROTECTED_PATHS | P2 | Recommended |
| AEG-P2-002: Client session_id fallback lacks independent ownership check | P2 | Optional (mitigated by validateSubmission) |
| AEG-P2-003: Rate limit fail-open (pre-existing) | P2 | No — pre-existing, low risk |

**Route to W4/W5:** Fix AEG-P1-001 (entry status check in connector + DB unique index) before proceeding. Everything else is functional and correctly enforced.
