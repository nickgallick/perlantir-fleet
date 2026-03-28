# SCORING_RUBRIC.md — Aegis Security Scoring Framework

Every Aegis audit must produce scores for all 11 categories using this exact rubric.

---

## The 11 Scored Categories

### 1. Auth / Session Integrity (weight: 12%)
Are authentication and sessions correctly implemented and resistant to abuse?
- 1–3: Broken auth, sessions trivially hijackable, CSRF possible
- 4–5: Auth works but session management has gaps
- 6–7: Solid auth, minor session hardening gaps
- 8: Strong auth, proper session lifecycle, no obvious weaknesses
- 9–10: Enterprise-grade auth with refresh rotation, proper expiry, abuse-resistant

### 2. Role-Based Access Control (weight: 15%)
Are role boundaries correctly enforced on both frontend AND backend?
- 1–3: Role checks only on frontend, backend unprotected
- 4–5: Backend protected but role escalation possible via edge cases
- 6–7: Solid RBAC with minor gaps in secondary routes
- 8: All routes and APIs correctly gated by role at backend
- 9–10: Defense-in-depth: RLS + middleware + API checks, no escalation paths found

### 3. API / Internal Endpoint Protection (weight: 12%)
Are all API routes properly protected and not over-exposing data?
- 1–3: Admin APIs accessible without auth, internal endpoints exposed
- 4–5: Primary APIs protected but internal/cron routes accessible
- 6–7: Good protection, minor over-exposure in response data
- 8: All APIs correctly gated, response data scoped to role
- 9–10: Defense-in-depth, no unauthorized access paths, data minimization applied

### 4. Runtime / Submission Abuse Resistance (weight: 10%)
Can competitors gain unfair advantage through technical abuse?
- 1–3: Duplicate submissions allowed, no rate limiting, replay attacks possible
- 4–5: Basic protection but clear abuse paths exist
- 6–7: Most abuse cases handled, edge cases remain
- 8: Robust abuse resistance for all identified paths
- 9–10: Hardened against all known and foreseeable abuse cases

### 5. Judging / Result Integrity (weight: 12%)
Are judging results tamper-proof, immutable, and correctly scoped?
- 1–3: Results can be manipulated, scores mutable post-activation
- 4–5: Results protected but leakage of judge config or test cases possible
- 6–7: Solid integrity, minor information disclosure
- 8: Activation-frozen scoring, no judge leakage, correct result visibility
- 9–10: Complete result integrity, adversarial probing finds nothing

### 6. Breakdown / Data Visibility by Role (weight: 10%)
Can users see only what their role entitles them to see?
- 1–3: Competitor can see admin-only breakdown data or hidden test cases
- 4–5: Visibility mostly correct but edge cases expose wrong data
- 6–7: Good visibility controls, minor API response data leakage
- 8: Role-scoped visibility enforced at API level, not just UI
- 9–10: Complete visibility isolation, adversarial API probing finds nothing

### 7. Admin Safety / Auditability (weight: 10%)
Are admin actions safe, confirmed, and auditable?
- 1–3: Destructive admin actions with no confirmation, no audit trail
- 4–5: Some confirmation, limited audit logging
- 6–7: Most destructive actions confirmed, basic audit trail
- 8: All destructive actions require confirmation + reason, full audit trail
- 9–10: Enterprise-grade admin safety, complete immutable audit log, reason capture

### 8. Connector / Integration Trust (weight: 8%)
Is the connector integration secure and trustworthy for developers?
- 1–3: Connector token exposed in docs/logs, integration has security gaps
- 4–5: Connector functional but token hygiene or error handling poor
- 6–7: Solid integration security, minor hygiene gaps
- 8: Secure token handling, safe error responses, docs accurate
- 9–10: Defense-in-depth integration security, abuse-resistant

### 9. Billing / Payment Trust (weight: 8%)
Are payment flows resistant to abuse? (Not yet live — score when available)
- N/A until Stripe goes live. Score as 0 (excluded from weighted calculation) until then.

### 10. Secrets / Error Hygiene (weight: 8%)
Are secrets protected and error messages safe?
- 1–3: DB errors visible, env vars in responses, stack traces exposed
- 4–5: Most secrets protected but some verbose error states
- 6–7: Clean error handling, minor information disclosure in edge cases
- 8: No secrets in responses, generic error messages, no stack traces
- 9–10: Perfect error hygiene, security headers present, content security policy

### 11. Overall Product Trustworthiness (weight: 5%)
Holistic assessment: would a security-aware developer or operator trust this platform?
- 1–3: Fundamental security failures visible to any observer
- 4–5: Works but would not pass a basic security review
- 6–7: Solid but not enterprise-grade
- 8: Would pass a reasonable security review
- 9–10: Enterprise-grade security posture

---

## Weighted Score Calculation

```
Score = (Auth × 0.12) + (RBAC × 0.15) + (API × 0.12) + (Abuse × 0.10) +
        (Judging × 0.12) + (Visibility × 0.10) + (Admin × 0.10) +
        (Connector × 0.08) + (Secrets × 0.08) + (Trust × 0.05)
```
*(Billing excluded until live — redistribute its weight proportionally)*

---

## Letter Grade Conversion

| Score | Grade | Meaning |
|-------|-------|---------|
| 9.0–10.0 | A+ | Elite security posture |
| 8.5–8.9 | A | Enterprise-ready |
| 8.0–8.4 | A- | Ship confidently |
| 7.5–7.9 | B+ | Ship with targeted hardening |
| 7.0–7.4 | B | Conditional ship |
| 6.5–6.9 | B- | Ship with mandatory P1 fixes |
| 6.0–6.4 | C+ | Do not ship without P1 resolution |
| 5.0–5.9 | C | Major security work needed |
| 4.0–4.9 | D | Serious security failures |
| <4.0 | F | Not launch-ready |

---

## Ship Thresholds

### NO-SHIP (any one triggers it)
- Any P0 unresolved
- RBAC score ≤ 4 (role boundaries broken)
- Auth/Session score ≤ 4
- Judging Integrity score ≤ 4
- Weighted overall < 6.0
- /qa-login accessible
- Admin APIs accessible without auth
- DB errors or secrets in any response

### CONDITIONAL SHIP
- Zero P0s
- All P1s documented with owner + fix timeline
- Weighted overall ≥ 6.5
- No category score < 5
- RBAC ≥ 6, Auth ≥ 6, Judging ≥ 6

### SHIP
- Zero P0s
- P1s resolved or explicitly accepted by Nick
- Weighted overall ≥ 7.5
- No category score < 6
- RBAC ≥ 7, Auth ≥ 7, Judging ≥ 7, Secrets ≥ 7
