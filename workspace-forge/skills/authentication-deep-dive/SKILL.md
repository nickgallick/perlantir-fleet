---
name: authentication-deep-dive
description: Auth security deep dive — OAuth PKCE, Supabase Auth internals (getSession vs getUser vs getClaims), social login edge cases, session management, MFA.
---

# Authentication Deep Dive

## Auth Review Checklist

1. [ ] Server-side uses `getClaims()` or `getUser()`, NEVER `getSession()`
2. [ ] Auth middleware on ALL protected routes
3. [ ] Token refresh via `onAuthStateChange` listener
4. [ ] Social login email conflict strategy is intentional
5. [ ] Logout invalidates server-side, not just client cookie
6. [ ] Protected routes verify auth BEFORE business logic
7. [ ] RLS policies use `(select auth.uid())` for performance
8. [ ] No auth tokens in logs, URLs, or client-accessible JS

---

## The Critical Distinction: getSession vs getUser vs getClaims

| Method | Where | Validates JWT? | Speed | Trust Level |
|--------|-------|---------------|-------|-------------|
| `getSession()` | Client or Server | ❌ NO — reads from cookie/storage | Instant | **NEVER trust on server** |
| `getUser()` | Server | ✅ Round-trip to Supabase | ~100ms | Trustworthy |
| `getClaims()` | Server | ✅ Validates JWT signature locally | ~1ms | **Trustworthy (preferred)** |

```ts
// ❌ P0 SECURITY BUG — user can forge session cookie
const { data: { session } } = await supabase.auth.getSession()
if (session) { /* UNSAFE — session could be forged */ }

// ✅ SAFE — validates JWT against Supabase public keys
const { data: { claims }, error } = await supabase.auth.getClaims()
if (error || !claims) return unauthorized()

// ✅ ALSO SAFE — round-trip verification (slower)
const { data: { user }, error } = await supabase.auth.getUser()
```

**Rule:** Every server-side auth check in middleware, Route Handlers, and Server Actions MUST use `getClaims()` or `getUser()`. Flag `getSession()` on the server as P0.

## OAuth 2.0 + PKCE Flow

```
1. Client generates code_verifier (random) + code_challenge (SHA256 hash)
2. Client redirects to: /authorize?code_challenge=XXX&response_type=code
3. User authenticates with provider (GitHub, Google)
4. Provider redirects back with: ?code=AUTH_CODE
5. Client exchanges: code + code_verifier → access_token + refresh_token
6. Server validates code_verifier matches code_challenge (proves same client)
```

**Why PKCE:** Without it, anyone who intercepts the auth code (via browser history, referrer, etc.) can exchange it for tokens. With PKCE, they also need the code_verifier which never leaves the client.

**Why NOT implicit flow:** Implicit flow returns tokens directly in the URL fragment. Tokens leak in browser history, referrer headers, and logs. Deprecated in OAuth 2.1.

## Social Login Edge Cases

### Email Conflicts
User A signs up with email `john@example.com`. Later, User B tries GitHub OAuth with the same email.

Supabase default: **auto-links** — same email = same account.
- **Good:** Convenient for legitimate users who use both methods
- **Bad:** If attacker controls a GitHub account with the victim's email, they get access

**Review check:** Is auto-linking appropriate for this app? For Arena (GitHub auth only): fine. For MathMind (email + Google): evaluate risk.

### Missing Email
Some providers don't return email (Twitter/X). Supabase creates the account without email.
**Handle:** Check for email after OAuth, prompt user to add one if missing.

### Token Revocation
User disconnects GitHub from Arena. What happens?
- Supabase session continues to work (it's independent of the social provider)
- User can still log in if they have a password
- To force logout: call `supabase.auth.admin.deleteUser()` or revoke all sessions

## Session Management

### Cookie Configuration (Supabase SSR handles this)
```
httpOnly: true      — JS can't read the cookie (XSS protection)
secure: true        — only sent over HTTPS
sameSite: 'lax'     — sent on top-level navigations, not cross-site requests
path: '/'           — available on all routes
```

### Logout (Complete)
```ts
// ❌ INCOMPLETE — only clears client state
await supabase.auth.signOut()

// ✅ COMPLETE — clears client + invalidates server-side
await supabase.auth.signOut({ scope: 'global' }) // invalidates ALL sessions
// For single-device logout:
await supabase.auth.signOut({ scope: 'local' })
```

## MFA (TOTP)

### When to Require
- Password changes
- Payment method changes  
- Admin actions
- Deleting account
- High-value operations (Arena: withdrawing coins, changing agent config during active challenge)

### RLS Check for MFA
```sql
-- Require MFA for sensitive operations
CREATE POLICY "MFA required for admin actions" ON admin_settings
AS RESTRICTIVE FOR ALL TO authenticated
USING ((select auth.jwt()->>'aal') = 'aal2');
```

## Next.js Auth Middleware Pattern

```ts
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })
  
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) => {
            request.cookies.set(name, value)
            supabaseResponse.cookies.set(name, value, options)
          })
        }
      }
    }
  )
  
  // IMPORTANT: getClaims() validates JWT + refreshes token
  const { data: { claims } } = await supabase.auth.getClaims()
  
  const isProtected = request.nextUrl.pathname.startsWith('/dashboard') ||
                      request.nextUrl.pathname.startsWith('/challenges')
  
  if (isProtected && !claims) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  
  return supabaseResponse
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api/webhooks).*)']
}
```

## Sources
- Supabase Auth documentation (getSession vs getUser vs getClaims)
- OAuth 2.0 + PKCE specification (RFC 7636)
- lucia-auth session management patterns
- OWASP Authentication Cheat Sheet

## Changelog
- 2026-03-21: Initial skill — authentication deep dive
