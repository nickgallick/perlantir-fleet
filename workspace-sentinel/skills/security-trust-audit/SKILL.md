# Security & Trust Audit — Sentinel Standard

## Security Testing Mindset
Think like OWASP ASVS Level 2. You are not doing a full penetration test. You are verifying that the platform does not have obvious trust-destroying or exploitable issues that would surface in normal use or light probing.

## Critical Security Checks for Bouts

### Access Control (P0 if failed)
- `/qa-login` must return 404 in production (ENABLE_QA_LOGIN=false)
- `/admin/*` must redirect or 403 for unauthenticated users
- `/admin/*` must redirect or 403 for authenticated non-admin users
- `/dashboard/*` must redirect to `/login` for unauthenticated users
- `/api/me` must return 401 when unauthenticated
- `/api/admin/*` must return 401 or 403 when unauthenticated
- No Supabase service role key visible in client-side code or responses
- No raw DB errors in API responses (PostgresError, relation, syntax error)

### Data Exposure (P0 if failed)
- API responses don't include fields meant only for other roles
- Admin endpoints not accessible from public context
- No environment variables or secrets in page source / network responses
- Challenge judge configs not exposed before match completion
- Hidden test cases not accessible to competitors before judging

### Auth Security (P0 if failed)
- Session tokens not exposed in URLs
- Login doesn't reveal whether email exists (timing/content attack)
- Password reset flow works and doesn't leak user existence
- JWT/session expiry handled gracefully

### Legal Compliance as Security (P0 if failed)
- DOB field required and validated in onboarding
- State restriction enforcement: WA, AZ, LA, MT, ID must be blocked
- 6 compliance checkboxes all required
- Iowa disclaimer present everywhere required
- /legal/terms, /legal/privacy, /legal/contest-rules, /legal/responsible-gaming all return 200 with real content

### Input Validation (P1 if failed)
- Forms don't accept obviously invalid inputs silently
- API routes validate required fields and return proper errors
- File/asset upload paths validated if present
- Large inputs handled gracefully

## OWASP Top 10 Relevant Checks
A01 - Broken Access Control: role boundaries (see above)
A02 - Cryptographic Failures: no secrets in responses/source
A03 - Injection: no raw DB errors visible, no SQL in error messages
A05 - Security Misconfiguration: no debug endpoints, no /qa-login
A07 - Identification/Auth Failures: session handling, password reset
A09 - Security Logging/Monitoring: (not directly testable from outside)

## Trust Signals Audit
These are not security issues but are trust-destroying if wrong:
- Correct legal entity name throughout ("Perlantir AI Studio LLC")
- Real support contact (not placeholder)
- Iowa address not placeholder in /legal/contest-rules
- Correct copyright year
- No "BOUTS ELITE" placeholders remaining (brand is just "Bouts")
- No "Agent Arena" references remaining (rebranded to "Bouts")
- No test data visible in production (test agents, fake challenges)
- Stats not hardcoded/fake
- No lorem ipsum or placeholder copy

## Security Test Pattern

### Test unauthed access to protected routes
```javascript
// Test without any auth cookies
const protectedRoutes = ['/dashboard', '/admin', '/admin/challenges'];
for (const route of protectedRoutes) {
  const resp = await page.goto(BASE + route);
  const finalUrl = page.url();
  if (!finalUrl.includes('/login')) {
    errors.push(`SECURITY: ${route} accessible without auth (final URL: ${finalUrl})`);
  }
}
```

### Test API auth enforcement
```javascript
const { createServer } = require('https');
// Test /api/me returns 401
const resp = await page.request.get(BASE + '/api/me');
if (resp.status() !== 401) errors.push('SECURITY: /api/me should return 401 unauthed');

// Test /api/admin returns 401/403
const adminResp = await page.request.get(BASE + '/api/admin/challenges');
if (![401, 403].includes(adminResp.status())) {
  errors.push('SECURITY: /api/admin/challenges accessible unauthed');
}
```

### Check for DB errors in responses
```javascript
const body = await page.content();
const dbErrorPatterns = ['PostgresError', 'relation "', 'syntax error', 'ERROR: ', 'supabase error'];
for (const pattern of dbErrorPatterns) {
  if (body.includes(pattern)) {
    errors.push(`DB error visible: "${pattern}" found on ${page.url()}`);
  }
}
```
