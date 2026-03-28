# FALSE_POSITIVE_GUARDRAILS.md — Aegis Over-Flagging Prevention

Security auditors can drift into paranoia. This file keeps Aegis disciplined and credible.

---

## The Core Principle
Only file a finding when you can demonstrate an actual issue — not a theoretical one.

**Observed issue**: You sent a request and received unauthorized data. → File it.
**Theoretical concern**: "An attacker might be able to..." without testing it. → Investigate first. Only file if confirmed.

---

## What NOT to Flag

### Don't flag route non-existence as security
If a route returns 404, that's correct behavior. A 404 is not a security gap — it means the endpoint doesn't exist.

### Don't treat staging roughness as production-critical
Internal endpoints that are rough, verbose, or undocumented are not automatically security issues unless they expose data or allow unauthorized actions.

### Don't confuse missing features with exploit paths
"There's no rate limiting on login" is worth flagging if you can demonstrate brute force is practical.
"There's no 2FA" is not a P0 for a competitive platform that isn't handling high-value financial accounts.

### Don't overstate frontend-only issues
If an admin button is hidden from competitor UI but the backend correctly blocks the API → not a security issue. Frontend-only restriction without backend verification IS an issue.

### Don't flag public data as information disclosure
Public API responses containing public information (challenge names, public profiles, leaderboard data) are not information disclosure.

### Don't flag CSRF on read-only endpoints
GET requests without side effects don't need CSRF protection.

### Don't flag /api/cron/challenge-quality as a security issue
This endpoint is intentionally open (it runs quality enforcement). The concern is only if it's destructive on repeat calls — test for idempotency, not just accessibility.

---

## Severity Discipline

### Downgrade from P0 when:
- The attack requires already-authenticated admin access to execute
- The "exploit" doesn't actually expose data or change state
- The issue only exists in a non-production state or known environment limitation

### Downgrade from P1 when:
- The issue is theoretical without a demonstrated path
- The issue requires attacker knowledge that would also imply the attacker already has access
- The issue is in an admin-only flow and requires admin credentials to reach

---

## The Evidence Standard
**P0**: Provide the exact HTTP request and response that demonstrates the issue.
**P1**: Provide reproduction steps and at minimum a description of the response received.
**P2**: Provide enough detail that another auditor could reproduce it.
**P3**: Description sufficient, reproduction steps optional.

If you can't provide evidence for a P0/P1 → it's a concern, not a finding. Note it in the risk register.

---

## Known Acceptable Gaps (Do Not Flag)

| Item | Why acceptable |
|------|---------------|
| /api/cron/challenge-quality is open | Intentional — cron runner access |
| No 2FA on login | Not required for this product category |
| Stripe not live | Known — not a security issue, it's a missing feature |
| challenge_bundles table may not exist | Known environment state — not a security issue |
| Support email on old domain | Known — not a security issue, P2 trust issue for Polish |
