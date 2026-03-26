---
name: jwt-session-attacks
description: JWT, OAuth 2.0, and session security attacks and defenses for Supabase Auth + Next.js applications. Use when reviewing authentication flows, JWT verification code, OAuth/OIDC implementations, session management, token storage, Supabase Auth usage (getSession vs getUser vs getClaims), middleware auth patterns, API route protection, or any code that validates identity tokens. Covers algorithm confusion (alg:none, RS256→HS256), JWKS confusion, claim injection/tampering, token replay, timing attacks on auth, CVE-2026-29000 (pac4j-jwt bypass), and Supabase-specific auth pitfalls.
---

# JWT & Session Attacks

## Why This Matters for Our Stack

Our entire auth layer is **Supabase Auth** which issues **JWTs**. Every auth decision in our apps ultimately trusts a JWT. If the JWT verification is wrong, everything downstream is compromised.

## Attack 1: Algorithm Confusion

### alg:none Attack
JWT header specifies `"alg": "none"`. If the verifier doesn't enforce algorithm, it accepts unsigned tokens.

```json
// Attacker forges token:
{"alg": "none", "typ": "JWT"}
.
{"sub": "admin-user-id", "role": "service_role"}
.
(empty signature)
```

**Detection in code review**:
- [ ] Does JWT verification explicitly specify allowed algorithms?
- [ ] Is there a `algorithms` parameter in the verify call?

```typescript
// VULNERABLE — no algorithm restriction
jwt.verify(token, secret)

// SAFE — algorithm explicitly specified
jwt.verify(token, secret, { algorithms: ['HS256'] })
```

### RS256 → HS256 Key Confusion
If the server uses RS256 (asymmetric), the attacker:
1. Obtains the public key (often available via JWKS endpoint)
2. Signs a token with HS256 using the public key as the HMAC secret
3. If the verifier doesn't enforce the algorithm, it verifies the HS256 signature using the public key (which it now treats as an HMAC secret)

**Detection**: Does the verifier enforce that RS256 tokens must be verified with RS256?

### JWKS Confusion / JKU Injection
JWT header can contain `jku` (JWK Set URL) or `jwk` (embedded key):
```json
{"alg": "RS256", "jku": "https://attacker.com/.well-known/jwks.json"}
```
If the verifier fetches keys from the JKU URL without validating it against a whitelist, the attacker provides their own signing key.

**Detection**:
- [ ] Does the verifier trust `jku`/`jwk` headers from the token itself?
- [ ] Is the JWKS URL hardcoded or configurable only via environment?
- [ ] Is there a JWKS URL whitelist?

## Attack 2: Claim Manipulation

### Supabase-Specific: getSession() vs getUser()

**This is the #1 auth bug in Supabase apps.**

```typescript
// VULNERABLE — reads JWT claims without verification
const { data: { session } } = await supabase.auth.getSession()
const userId = session?.user?.id  // Trusts unverified JWT

// SAFE — verifies token against Supabase Auth server
const { data: { user } } = await supabase.auth.getUser()
const userId = user?.id  // Server-verified identity
```

`getSession()` reads from the local JWT without hitting the auth server. An attacker who can tamper with the JWT cookie can forge claims.

`getUser()` makes an API call to verify the token against Supabase Auth.

**Rule**: ALWAYS use `getUser()` for server-side auth decisions. `getSession()` is acceptable only for client-side UI hints (showing username, etc.) where security isn't at stake.

### Custom Claims Injection
If the application stores role or permissions in JWT custom claims and doesn't re-verify them server-side:
```json
{
  "sub": "user-123",
  "role": "user",
  "custom_claims": {"is_admin": true}  // Attacker adds this
}
```

**Detection**:
- [ ] Are authorization decisions based on JWT claims alone?
- [ ] Are custom claims verified against the database on sensitive operations?
- [ ] Does the application trust `role` from the JWT for RLS policies?

### JWT ID (jti) and Expiration Bypass
- Missing `exp` check → token never expires
- Missing `jti` uniqueness → token replay
- Missing `nbf` (not-before) check → future-dated tokens accepted early
- Missing `iss` (issuer) check → tokens from other Supabase projects accepted

## Attack 3: Token Storage & Transmission

### Client-Side Storage Risks
| Storage | XSS Accessible | CSRF Risk | Recommendation |
|---------|---------------|-----------|----------------|
| localStorage | ✅ Yes | ❌ No | ❌ Avoid for auth tokens |
| sessionStorage | ✅ Yes | ❌ No | ❌ Avoid for auth tokens |
| Cookie (no HttpOnly) | ✅ Yes | ✅ Yes | ❌ Worst option |
| Cookie (HttpOnly, Secure, SameSite=Lax) | ❌ No | ⚠️ Limited | ✅ Best option |
| Memory only | ❌ No (unless XSS dumps) | ❌ No | ✅ Most secure, worst UX |

Supabase Auth stores tokens in cookies by default with `@supabase/ssr`. Verify:
- [ ] `HttpOnly` flag set
- [ ] `Secure` flag set (HTTPS only)
- [ ] `SameSite=Lax` (minimum)
- [ ] Cookie path is specific, not `/`

### Token in URL
```
https://app.com/callback?access_token=eyJhbG...
```
Tokens in URLs leak via:
- Browser history
- Referrer headers
- Server logs
- Shared links

**Detection**: Any route that reads tokens from query parameters.

## Attack 4: OAuth Flow Vulnerabilities

### CSRF on OAuth Callback
If the `state` parameter is missing or not validated:
1. Attacker initiates OAuth flow
2. Gets callback URL with attacker's auth code
3. Tricks victim into visiting the callback URL
4. Victim's session is now linked to attacker's account

**Detection**: Is `state` parameter generated, stored, and verified on callback?

### Authorization Code Injection
Attacker intercepts or generates an authorization code and replays it to a different client.

**Mitigation**: PKCE (Proof Key for Code Exchange) — required for public clients.

**Detection**: Is PKCE used? Supabase Auth supports PKCE — verify it's enabled:
```typescript
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    queryParams: { access_type: 'offline', prompt: 'consent' },
    // PKCE should be default in @supabase/ssr
  }
})
```

### Open Redirect via OAuth
If the redirect URL after OAuth is user-controllable:
```
/auth/callback?redirect_to=https://evil.com
```

**Detection**:
- [ ] Is `redirect_to` / `next` parameter validated against an allowlist?
- [ ] Can an attacker control where the user lands after auth?

## Attack 5: Timing Attacks on Authentication

### String Comparison Timing
```typescript
// VULNERABLE — early exit on first byte mismatch
if (providedToken === storedToken) { /* grant access */ }

// SAFE — constant-time comparison
import { timingSafeEqual } from 'crypto'
const isValid = timingSafeEqual(
  Buffer.from(providedToken),
  Buffer.from(storedToken)
)
```

Standard `===` comparison returns faster when the first byte doesn't match. Attacker measures response times to brute-force tokens byte by byte.

### Username Enumeration via Timing
```typescript
// VULNERABLE — different code paths for existing vs non-existing users
if (!user) return { error: 'User not found' }  // Fast path
const valid = await bcrypt.compare(password, user.hash)  // Slow path
```

Timing difference reveals whether the username exists.

**Fix**:
```typescript
// Always run the same code path
const user = await getUser(email)
const hash = user?.hash || DUMMY_HASH  // Always compare against something
const valid = await bcrypt.compare(password, hash)
if (!user || !valid) return { error: 'Invalid credentials' }
```

### Bcrypt Truncation
bcrypt silently truncates passwords at 72 bytes. Two passwords sharing the same first 72 bytes hash identically.
- Most users won't hit this, but API keys and tokens can
- **Detection**: Is bcrypt used for hashing long secrets (>72 chars)? Use SHA-256 pre-hash.

## Supabase Auth Review Checklist

### Server-Side (API routes, Server Actions, middleware)
- [ ] Uses `getUser()` not `getSession()` for auth decisions
- [ ] Validates JWT claims against database for sensitive operations
- [ ] Rate limits login/signup endpoints
- [ ] Validates `redirect_to` URLs against allowlist
- [ ] Uses PKCE for OAuth flows
- [ ] Service role key never exposed to client

### Client-Side
- [ ] Tokens stored in HttpOnly cookies (via @supabase/ssr)
- [ ] No tokens in localStorage or URL parameters
- [ ] Token refresh handled correctly (not exposing refresh token)
- [ ] Logout clears all token storage

### RLS Integration
- [ ] RLS policies use `auth.uid()` not client-provided user IDs
- [ ] RLS policies don't trust JWT claims for authorization without verification
- [ ] Service role operations are server-only and never client-triggered

## References

For OAuth/OIDC vulnerability catalog, see `references/oauth-vulnerabilities.md`.
For Supabase-specific auth patterns, see the `auth-patterns` skill.
