---
name: owasp-stack-specific
description: OWASP Top 10 mapped to our exact stack — Next.js + Supabase + TypeScript + Tailwind. Used during every code review to catch vulnerabilities specific to our architecture.
---

# OWASP Top 10 — Our Stack

For each vulnerability: what it is, how it manifests in OUR stack, what to check in code review, and the exact fix.

## A01: Broken Access Control

**In our stack:**
- Missing RLS policies on Supabase tables (RLS is off by default on SQL-created tables)
- API routes (Next.js Route Handlers) without auth middleware
- IDOR via predictable IDs in Next.js routes — `params.id` used without ownership check
- Missing `.eq('user_id', session.user.id)` on Supabase queries
- Service role key (`SUPABASE_SERVICE_ROLE_KEY`) used in client-accessible code or Route Handlers that should use user-scoped client
- `select('*')` leaking columns the user shouldn't see

**WebSocket-specific A01 issues:**
- WebSocket connections bypass traditional HTTP auth middleware — Next.js middleware does NOT intercept WebSocket upgrades
- No automatic CORS enforcement on WebSocket upgrade — must manually validate Origin header
- Connection-level auth vs message-level auth — BOTH needed. Auth on connect doesn't mean every message is authorized.
- Horizontal privilege escalation: accessing another user's agent session via crafted WebSocket messages (e.g., changing session ID in message payload)
- CSWSH (Cross-Site WebSocket Hijacking): attacker's site opens WebSocket to your server, browser sends cookies automatically → authenticated access without user consent

**Review checklist:**
- [ ] Every table in `public` schema has RLS enabled?
- [ ] Every API route checks session via `supabase.auth.getSession()` or `auth.getClaims()`?
- [ ] Every query that returns user-specific data filters by `auth.uid()`?
- [ ] Service role key ONLY in server-side code (never `NEXT_PUBLIC_`)?
- [ ] No direct ID manipulation possible without ownership verification?
- [ ] RLS policies use `(select auth.uid())` pattern for performance?
- [ ] WebSocket connections validate Origin header against allowlist?
- [ ] WebSocket auth happens before any messages are processed?
- [ ] Each WebSocket message checks authorization for the requested action?

**Fix patterns:**
```sql
-- RLS policy for user-owned data
create policy "Users can only access own data"
on my_table for all
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
```
```ts
// Next.js: user-scoped Supabase client
import { createServerClient } from '@supabase/ssr'
// NOT: createClient(url, SERVICE_ROLE_KEY)
```

## A02: Cryptographic Failures

**In our stack:**
- `NEXT_PUBLIC_` env vars exposing secrets (service role key, API keys)
- Supabase service role key in client bundle
- Sensitive data stored unencrypted in Supabase (PII, financial data)
- Missing HTTPS (Vercel handles this, but custom domains need verification)
- JWT secrets too short or predictable
- Passwords stored in plaintext (Supabase Auth handles hashing, but custom auth might not)

**Review checklist:**
- [ ] No `SUPABASE_SERVICE_ROLE_KEY` in any `NEXT_PUBLIC_` variable?
- [ ] No API keys or secrets in client-side code?
- [ ] Sensitive columns (SSN, financial data) encrypted at rest?
- [ ] Custom domains have SSL configured?
- [ ] No secrets in git history (check `.env` not committed)?

## A03: Injection

**In our stack:**
- Supabase `.rpc()` with string concatenation in SQL functions
- `dangerouslySetInnerHTML` in React rendering user-generated content
- XSS via unsanitized user content rendered in JSX (React auto-escapes `{}` but NOT `dangerouslySetInnerHTML`)
- SQL injection through raw queries in Supabase Edge Functions
- Template literal injection in Supabase `.or()` or `.filter()` with user input

**Review checklist:**
- [ ] No string concatenation in SQL queries or RPC calls?
- [ ] No `dangerouslySetInnerHTML` with user content (or sanitized with DOMPurify)?
- [ ] Zod validation on ALL inputs at API boundaries?
- [ ] Parameterized queries only in Edge Functions?
- [ ] No user input directly in `.or()`, `.filter()`, or `.textSearch()` without sanitization?

**Fix pattern:**
```ts
// BAD: string concatenation
const { data } = await supabase.rpc('search', { query: userInput })
// In SQL: EXECUTE 'SELECT * FROM items WHERE name = ' || query  ← INJECTION

// GOOD: parameterized
// In SQL: SELECT * FROM items WHERE name = $1 (using function params)
```

## A04: Insecure Design

**In our stack:**
- No rate limiting on Next.js API routes (Vercel has basic limits, but no per-endpoint control)
- No account lockout after failed Supabase Auth attempts
- Predictable auto-increment IDs instead of UUIDs (Supabase defaults to UUID, but custom tables might not)
- No defense in depth — relying solely on RLS without application-level checks
- Missing CSRF protection on Server Actions (Next.js handles some, but custom implementations may not)
- No idempotency on financial or state-changing operations

**Review checklist:**
- [ ] All primary keys are UUID, not sequential integers?
- [ ] Rate limiting implemented on sensitive endpoints?
- [ ] Financial operations have idempotency keys?
- [ ] Defense in depth — both RLS AND application-level auth checks?

## A05: Security Misconfiguration

**In our stack:**
- RLS disabled on tables (Supabase default for SQL-created tables)
- CORS set to `*` in Next.js config or Supabase
- Detailed error messages/stack traces in production API responses
- Debug logging enabled in production
- Missing security headers (CSP, X-Frame-Options, HSTS) — Next.js `next.config.ts` headers
- Supabase Dashboard access not restricted (weak passwords, no 2FA)
- Default Supabase email templates exposing internal URLs

**WebSocket-specific A05 issues:**
- Default `ws://` instead of `wss://` in development leaking into production
- No message size limits (`maxPayload`) → memory exhaustion DoS
- No connection rate limiting → connection flooding DoS
- Exposed WebSocket debug endpoints in production
- Missing Origin header validation → CSWSH vulnerability
- Verbose error messages over WebSocket revealing internal state (stack traces, file paths, DB errors)
- WebSocket compression enabled by default (`perMessageDeflate`) → potential CRIME/BREACH-style attacks

**Review checklist:**
- [ ] All `public` schema tables have RLS enabled?
- [ ] CORS configured for specific origins only?
- [ ] API errors return generic messages, not stack traces?
- [ ] `next.config.ts` includes security headers?
- [ ] No `console.log` of sensitive data in production?
- [ ] All WebSocket connections use `wss://` in production?
- [ ] WebSocket `maxPayload` set (≤64KB default)?
- [ ] Connection rate limiting configured per IP/user?
- [ ] WebSocket error messages sanitized (no internal details)?
- [ ] `perMessageDeflate` disabled unless specifically needed?

**Fix pattern:**
```ts
// next.config.ts security headers
const securityHeaders = [
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains' },
]
```

## A06: Vulnerable and Outdated Components

**In our stack:**
- Outdated npm packages with known CVEs
- Unaudited dependencies in `package.json`
- Missing `npm audit` in CI pipeline (GitHub Actions)
- No lock file (`package-lock.json`) committed
- Using deprecated Supabase auth helpers instead of `@supabase/ssr`

**Review checklist:**
- [ ] `npm audit` shows no high/critical vulnerabilities?
- [ ] Lock file committed and up to date?
- [ ] Using `@supabase/ssr` (not deprecated `@supabase/auth-helpers-nextjs`)?
- [ ] No packages with known CVEs?
- [ ] Dependabot or similar configured?

## A07: Identification and Authentication Failures

**In our stack:**
- Supabase `getSession()` used in server code (it doesn't validate JWT — use `getClaims()`)
- Missing session refresh in Next.js middleware
- No MFA enforcement for sensitive operations
- Weak password requirements (Supabase default: 6 chars)
- Session tokens not properly invalidated on logout
- Using `getSession()` instead of `getClaims()` in Proxy/middleware (JWT not validated)

**Review checklist:**
- [ ] Server-side code uses `getClaims()` not `getSession()`?
- [ ] Next.js Proxy refreshes auth tokens?
- [ ] Password policy enforced (minimum 8 chars with MFA, 15 without)?
- [ ] Logout properly clears session?
- [ ] Session cookies have HttpOnly, Secure, SameSite flags?

**Fix pattern:**
```ts
// BAD: getSession doesn't validate JWT on server
const { data: { session } } = await supabase.auth.getSession()

// GOOD: getClaims validates JWT signature
const { data: { claims }, error } = await supabase.auth.getClaims()
```

## A08: Software and Data Integrity Failures

**In our stack:**
- CI/CD pipeline (GitHub Actions) without integrity checks
- npm packages from untrusted sources
- Missing Subresource Integrity (SRI) for CDN scripts
- Supabase Edge Functions deployed without review gate
- Auto-merge without code review (Forge should be in the loop!)

**Review checklist:**
- [ ] All dependencies from trusted registries?
- [ ] CI pipeline includes security checks?
- [ ] No auto-merge without review?
- [ ] Edge Functions reviewed before deploy?

## A09: Security Logging and Monitoring Failures

**In our stack:**
- No structured logging in Next.js API routes
- No audit trail for sensitive operations (Supabase has `auth.audit_log_entries` but app-level logging often missing)
- No alerting on failed auth attempts
- Missing request logging in production
- No monitoring of Supabase RLS policy violations

**Review checklist:**
- [ ] Sensitive operations logged (auth, financial, admin actions)?
- [ ] Structured logging format (JSON) for log aggregation?
- [ ] Failed auth attempts tracked?
- [ ] No sensitive data in logs (passwords, tokens, PII)?

## A10: Server-Side Request Forgery (SSRF)

**In our stack:**
- Next.js API routes fetching user-supplied URLs
- Supabase Edge Functions making external requests based on user input
- Image URL processing (Next.js Image component with remote patterns)
- Webhook URLs provided by users

**Review checklist:**
- [ ] No user-supplied URLs used directly in server-side `fetch()`?
- [ ] `next.config.ts` `remotePatterns` restricted to known domains?
- [ ] Webhook URLs validated against allowlist?
- [ ] No internal network access possible via user-supplied URLs?

**Fix pattern:**
```ts
// next.config.ts - restrict image sources
images: {
  remotePatterns: [
    { protocol: 'https', hostname: 'specific-cdn.com' }, // explicit allowlist
    // NOT: { hostname: '**' }  ← allows ANY host
  ]
}
```

## Sources
- OWASP Top 10 (2025): https://owasp.org/Top10/
- OWASP Node.js Security Cheat Sheet
- OWASP REST Security Cheat Sheet
- OWASP Authentication Cheat Sheet
- OWASP Authorization Cheat Sheet
- OWASP Input Validation Cheat Sheet
- OWASP CSRF Prevention Cheat Sheet
- OWASP SQL Injection Prevention Cheat Sheet
- OWASP JWT Cheat Sheet
- Supabase RLS Documentation
- Supabase Server-Side Auth (Next.js)
- Next.js Authentication Guide
- Snyk React Security Best Practices

## Changelog
- 2026-03-20: Initial skill — all 10 categories mapped to our stack with review checklists
