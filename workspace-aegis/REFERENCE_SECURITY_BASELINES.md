# REFERENCE_SECURITY_BASELINES.md — Aegis Security Benchmarks

These baselines anchor "secure enough" to a real bar for a competitive platform handling real money and competitive stakes.

---

## OWASP Access Control (Adapted for Bouts)

**A01 — Broken Access Control**
The most common and critical category for Bouts.

What correct access control looks like in Bouts:
- Every admin API route checks role at the server/middleware level — not just UI
- Supabase RLS policies enforce row-level access so DB queries only return data the user owns
- JWT claims are verified server-side — not trusted from client headers
- Admin role is verified from the DB/session, not from a URL parameter or client claim

What broken access control looks like:
- /api/admin routes that only check a UI flag, not a server-side role
- Supabase queries with no RLS — any authenticated user can read all rows
- "is_admin" claim in JWT that's never verified against the DB

**A02 — Cryptographic Failures**
- Service role key never in client-side code or API responses
- JWT secret not exposed in any error or response
- NEXT_PUBLIC_ variables contain only public config (anon key is acceptable)
- SUPABASE_SERVICE_ROLE_KEY server-side only

**A03 — Injection**
- No raw SQL in visible error messages
- No PostgresError "relation X does not exist" in API responses
- No stack traces in 500 responses
- Supabase parameterized queries (standard) prevent SQL injection — verify edge cases

**A05 — Security Misconfiguration**
- /qa-login must return 404
- No debug endpoints in production
- No admin test routes accessible
- ENABLE_QA_LOGIN env var must be false

**A07 — Identification and Auth Failures**
- Sessions expire properly
- New session created on login (no fixation)
- Password reset tokens single-use and time-limited
- Login failure messages don't reveal whether email exists

---

## Premium SaaS Auth/Session Standard

Based on how Stripe, Linear, and Vercel handle auth:

**Session lifecycle**:
- Session tokens rotate on sensitive operations (admin actions, payment)
- Session expires after reasonable inactivity
- "Remember me" is optional, not default
- Logout invalidates server-side session (not just clears cookie)

**Auth UX that doesn't sacrifice security**:
- Login errors don't distinguish "email not found" from "password wrong" (prevents enumeration)
- Reset password tokens sent to email, not exposed in URL parameters
- Onboarding cannot be replayed after completion

---

## Competitive Platform Judging Integrity Standard

Based on how Kaggle, Codeforces, and lichess.org handle result integrity:

**Immutability**:
- Scores locked when a match completes — no API allows post-hoc modification
- Judge configuration frozen at challenge activation (Bouts: activation_snapshot)
- Change history is auditable for any admin modification

**Anti-cheating**:
- Hidden test cases never exposed to competitors before or during judging
- Replay of past matches shows results, not the hidden tests
- Connector submission is one-way: submit solution, receive score — no inspect/compare path

**Score visibility**:
- Own detailed breakdown: visible to competitor after match
- Others' detailed breakdown: not visible (only aggregate leaderboard stats)
- Hidden test details: visible to admin only

---

## Admin Safety Standard

Based on how Retool and Linear handle destructive operations:

**Before any destructive action** (quarantine, reject, delete):
- Confirmation required (not just a button — a modal with clear consequence statement)
- Reason field required for pipeline state changes
- Action logged with: who, what, when, reason

**Audit trail requirements**:
- Admin actions are immutable log entries
- Admin cannot delete their own audit trail
- ClawExpert/Nick can review all admin actions taken

---

## Error Hygiene Standard

Based on how Stripe and Vercel handle errors:

**What users should see**:
- "Something went wrong. We've been notified." (for 500s)
- "Not found" (for 404s)
- Specific validation errors (for 400s): "Challenge family is required"

**What users should never see**:
- Stack traces
- File paths (/data/agent-arena/src/...)
- Database error messages (PostgresError, relation "X" does not exist)
- Environment variable names or values
- Internal system identifiers (session IDs, service role keys)

---

## Connector/Integration Trust Standard

Based on how Stripe API and Supabase handle third-party integration:

**Token handling**:
- API keys transmitted only in Authorization header — never in URL parameters or query strings
- API key errors return 401, not 403 (don't confirm that the route exists to an invalid caller)
- API key rotation path exists for compromised keys

**Integration error handling**:
- Malformed payloads return 400 with specific validation errors
- Over-sized payloads rejected with 413
- Integration endpoint never returns internal system state in error messages
