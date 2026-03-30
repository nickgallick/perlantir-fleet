# Aegis — RAI Trust Verification Audit
**Date:** 2026-03-30  
**Scope:** Remote Agent Invocation browser path trust model verification  
**Auditor:** Aegis  
**Verdict:** CONDITIONAL PASS — 1 P0, 2 P1s must be fixed before launch

---

## Executive Summary

The RAI architecture is fundamentally sound. One-shot semantics are correctly enforced. Provenance visibility is correctly separated. The signing and nonce model is strong. However, Forge's claim of "default-off challenge enablement" is factually incorrect in the migration — the DB default is `true` not `false`. Additionally, the SSRF protection code was written but never wired into the registration or invocation paths (dead code), and the public developer docs contain a signature verification algorithm that does not match the actual implementation.

---

## Per-Item Verdicts

### 1. Remote Agent Invocation is explicit opt-in per challenge
**❌ FAIL — P0**

**Claim:** default-off challenge enablement  
**Reality:** Migration `00038_remote_invocation.sql` line 96:
```sql
ADD COLUMN IF NOT EXISTS remote_invocation_supported boolean NOT NULL DEFAULT true;
```

The default is `TRUE`. Every existing challenge immediately has RAI enabled unless an admin explicitly turns it off. This is the opposite of opt-in. Compare to `web_submission_supported` (migration 00035) which correctly defaults to `FALSE`.

**Risk:** Every existing and future challenge is RAI-enabled by default. If a challenge type is not designed for machine invocation (e.g., it requires human interpretation context, a special format, or has hidden test sensitivity), it is exposed to RAI without the admin ever making a choice.

**Fix required:** Change migration default to `false`. Add explicit admin UI toggle. Backfill existing challenges if needed.

---

### 2. Old production web text submission is not still reachable in practice
**✅ PASS**

`/api/challenges/[id]/web-submit` exists but requires `challenge.web_submission_supported = true`, which defaults to `false`. The API gate is enforced at the backend:
```typescript
if (!challenge.web_submission_supported) {
  return NextResponse.json({ error: 'This challenge does not support web submission...' }, { status: 400 })
}
```

The workspace page enforces this on the UI too — serves `not_supported` state if `!remote_invocation_supported`. The old docs page redirects to RAI docs. The endpoint is still in the codebase but is inert by default.

---

### 3. One-shot semantics are enforced correctly
**✅ PASS**

Three-layer enforcement confirmed:

**Layer 1 — Entry terminal status check:**
```typescript
const terminalStatuses = ['submitted', 'judged', 'scored', 'failed', 'expired']
if (terminalStatuses.includes(e.status)) return jsonError('This entry has already been submitted...', 409)
```

**Layer 2 — Existing submission idempotency check:**
```typescript
// Checks for existing remote_invocation submission on this session
if (existingSub) return NextResponse.json({ outcome: 'duplicate' }, { status: 409 })
```

**Layer 3 — Entry status update timing:**
Entry only moves to `submitted` AFTER the submission row is confirmed written. This is the correct atomicity ordering.

---

### 4. Pre-submission failure does not burn an entry
**✅ PASS**

The code is explicitly correct and well-documented:
```typescript
// Entry is NOT consumed on invocation failure — user may retry
return jsonError(result.errorMessage, outcomeToStatus[result.outcome], {
  entry_consumed: false,
  retry_allowed: result.outcome === 'timeout' || result.outcome === 'error',
})
```

And on submission INSERT failure:
```typescript
if (subError || !submission) {
  return jsonError('Failed to record submission — your entry has not been consumed.', 500, {
    entry_consumed: false,
  })
}
```

Entry status update to `submitted` only occurs after confirmed submission write. Pre-submission failures (timeout, invalid_response, content_too_large, TCP error, platform error) all return `entry_consumed: false`.

---

### 5. Provenance visibility correctly separated across public / competitor / admin
**✅ PASS**

`/api/submissions/[submissionId]/breakdown` correctly enforces:

| Audience | Fields returned |
|----------|----------------|
| Public/spectator | `submission_source` only |
| Competitor (own) | `submission_source`, `endpoint_host`, `endpoint_environment`, `request_sent_at`, `response_latency_ms`, `response_content_hash`, `schema_valid` |
| Admin | Full: all above + `invocation_id`, `response_received_at`, `response_http_status` |

Full URL is not exposed to competitors. Error details are not exposed to competitors. The audience determination logic is correct — checks role, then agent ownership, then falls through to spectator.

---

### 6. Endpoint validation and invocation flows do not create obvious abuse or trust gaps
**⚠️ FAIL — P1 (SSRF protection not wired) + P2 (signature doc mismatch)**

#### AEG-P1-001 — SSRF Protection Is Dead Code
`/data/agent-arena/src/lib/rai/ip-guard.ts` contains both `validateEndpointUrl()` and `isPrivateIp()` with full implementation — but **neither function is imported or called anywhere** in:
- `/api/v1/agents/[id]/endpoint/route.ts` (PUT — registration)  
- `/api/v1/agents/[id]/endpoint/validate/route.ts` (validate)  
- `/api/challenges/[id]/invoke/route.ts` (invocation)

Verification:
```bash
grep -n "isPrivateIp\|validateEndpointUrl" /data/agent-arena/src/app/api/v1/agents/[id]/endpoint/route.ts
# (no output)
grep -n "isPrivateIp\|validateEndpointUrl" /data/agent-arena/src/app/api/challenges/[id]/invoke/route.ts
# (no output)
```

**Impact:** A competitor can register `http://169.254.169.254/latest/meta-data` or any other private/SSRF target as their endpoint URL. Bouts will make an outbound HTTP call to it. On Vercel serverless the cloud metadata endpoint is accessible. The code to block this is written but disconnected.

**Fix:** Import and call `validateEndpointUrl()` in the endpoint PUT route before saving, and call `isPrivateIp()` in the invoke route before executing the outbound request.

#### AEG-P2-001 — Docs Signature Verification Algorithm Doesn't Match Implementation
The docs (`/docs/remote-invocation`) provide a signature verification example developers will use to verify incoming requests:

**Docs say** (both Node.js and Python examples):
```
signing_string = timestamp.invocation_id.bodyHash
```

**Actual implementation** (`sign-request.ts`):
```
payload = method + "\n" + url + "\n" + timestamp_ms + "\n" + nonce + "\n" + body_sha256
```

The formats are completely different. Fields differ (nonce vs invocation_id; method + url present in code, absent from docs). Any developer implementing signature verification using the published docs will fail verification on every legitimate request. This undermines the stated trust model.

Additionally, the docs reference `X-Bouts-Invocation-Id` as a header but the actual implementation sends `X-Bouts-Nonce` — invocation_id is in the body, not the header.

---

### 7. Zero-retry behavior is actually enforced
**⚠️ CONDITIONAL PASS — with documentation mismatch**

The invoke route hardcodes `maxRetries: 0`:
```typescript
maxRetries: 0,  // explicit comment: "Default 0 retries — explicit safety"
```

And `isRetryable()` in `invoke-agent.ts` explicitly makes all production outcomes non-retryable (including 5xx, timeout, invalid_response). The `maxAttempts = maxRetries + 1 = 1` means the retry loop runs exactly once regardless.

**However — two discrepancies:**

1. **DB default is 1, not 0:** `remote_endpoint_max_retries integer DEFAULT 1` in the migration. The endpoint config UI allows 0–2 retries. But the invoke route ignores the stored value and always passes `maxRetries: 0`. The stored value has no effect — which is correct behavior but creates misleading config state.

2. **Docs say "1 retry on connection error":** The timeout/failure behavior table in the docs says: *"Retries: 1 retry on connection error (not on timeout or invalid response)"*. This contradicts the actual zero-retry enforcement. The code comment says pure TCP failure may retry if `max_retries=1` — but since the invoke route hardcodes 0, this never happens.

**Risk:** Low trust risk (actual behavior is correct), but documentation misleads developers and creates confusion about platform behavior.

---

### 8. Trust language matches what the product technically proves
**⚠️ PARTIAL — docs accuracy gap**

The high-level trust model language (what Bouts verifies, what Bouts records, what remains outside Bouts' control) is accurate and appropriately scoped. The "What this is NOT" section correctly disclaims hosted execution.

**Gaps found:**
- Signature verification examples are wrong (AEG-P2-001 above)
- Retry behavior documented incorrectly
- The docs comparison table says "Trust level: Machine-originated" for RAI — this is accurate and appropriate given the caveats that are also disclosed

---

## Consolidated Finding Log

| ID | Sev | Category | Route | Summary |
|----|-----|----------|-------|---------|
| AEG-P0-001 | P0 | Access Control | DB migration + challenges table | `remote_invocation_supported` defaults `TRUE` — not opt-in |
| AEG-P1-001 | P1 | SSRF / Integration Security | `/api/v1/agents/[id]/endpoint` (PUT) + invoke | SSRF protection code written but never called — dead code |
| AEG-P2-001 | P2 | Trust / Docs | `/docs/remote-invocation` | Signature verification algorithm in docs doesn't match implementation |
| AEG-P2-002 | P2 | Trust / Docs | `/docs/remote-invocation` | Retry behavior documented as "1 retry" but code enforces 0 retries |

---

## Remaining Trust/Integrity Blockers

**P0 — Must fix before any challenge goes live with RAI:**
- `remote_invocation_supported` default must be `false`. Right now every challenge is RAI-enabled by default. If Forge activates challenges without explicitly setting this to false, they all accept RAI invocations without a deliberate admin choice.

**P1 — Must fix before production traffic:**
- Wire `validateEndpointUrl()` into endpoint registration PUT. Wire `isPrivateIp()` into invoke route pre-flight. The code is already written — it just needs to be called.

**P2 — Fix before docs are public:**
- Correct the signature verification algorithm in both Node.js and Python examples to match `sign-request.ts` actual format. Fix the retry documentation.

---

## Launch Safety Verdict

**NOT LAUNCH-SAFE AS-IS.**

The P0 (default-on not default-off) means the stated trust model — "admin explicitly enables RAI per challenge" — is not what ships. Every challenge is RAI-enabled by default. This is a product integrity claim failure, not just a hygiene issue.

The P1 SSRF gap is an active security risk on a path that makes outbound HTTP requests from Bouts infrastructure to user-registered URLs.

Fix sequence:
1. **P0 first:** Change migration default to `false`, verify no existing challenges need backfill
2. **P1 second:** Wire `validateEndpointUrl` into endpoint PUT, wire `isPrivateIp` into invoke pre-flight
3. **P2 last:** Correct docs signature algorithm + retry table

After P0 and P1 are confirmed fixed, RAI is launch-safe from a trust standpoint.
