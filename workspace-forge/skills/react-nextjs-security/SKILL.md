---
name: react-nextjs-security
description: React and Next.js specific security patterns, XSS prevention, server/client boundary safety, and auth flow best practices for our stack.
---

# React & Next.js Security Patterns

## React XSS Prevention

### Default Protection
React auto-escapes values in JSX `{}` expressions — this is safe:
```tsx
<p>{userInput}</p>  // ✅ Safe - auto-escaped
```

### Danger Zones
```tsx
// ❌ NEVER with user content
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ❌ URL-based injection
<a href={userProvidedUrl}>Link</a>  // Could be javascript:alert(1)

// ❌ Dynamic attribute injection
<div {...userControlledProps} />  // Could inject event handlers
```

### Safe Patterns
```tsx
// ✅ Sanitize if you MUST use dangerouslySetInnerHTML
import DOMPurify from 'dompurify'
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(htmlContent) }} />

// ✅ Validate URLs
function SafeLink({ url }: { url: string }) {
  const parsed = new URL(url)
  if (!['http:', 'https:'].includes(parsed.protocol)) return null
  return <a href={url}>Link</a>
}
```

### Review Checklist — React XSS
- [ ] No `dangerouslySetInnerHTML` with unsanitized user content
- [ ] No `javascript:` protocol in href attributes
- [ ] No user-controlled spread props (`{...userInput}`)
- [ ] No direct DOM access via `ref.current.innerHTML`
- [ ] No `eval()` or `Function()` with user input
- [ ] SSR output not concatenated with unsanitized strings

## Next.js Server/Client Boundary Security

### Server Components (default)
- Run ONLY on server — safe for secrets, DB queries, auth checks
- Never leak to client bundle
- Can use `process.env.SECRET_KEY` (no `NEXT_PUBLIC_` needed)

### Client Components (`"use client"`)
- Run in browser — NEVER put secrets here
- Only `NEXT_PUBLIC_*` env vars available
- All data is visible in browser DevTools

### Server Actions
- Execute on server but are callable from client
- Must validate ALL inputs — client can send anything
- Must check auth — Server Actions are HTTP endpoints under the hood
- Use Zod `.safeParse()` at the top of every Server Action

### Review Checklist — Server/Client Boundary
- [ ] No secrets in Client Components?
- [ ] No `NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY` or similar?
- [ ] Server Actions validate all inputs with Zod?
- [ ] Server Actions check authentication before proceeding?
- [ ] `'use server'` only on files that should be server-callable?
- [ ] No sensitive logic in `layout.tsx` without auth checks?

## Next.js Authentication Patterns

### The Correct Pattern (with Supabase)
```ts
// lib/supabase/server.ts — Server client
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options))
          } catch {} // Ignored in Server Components
        }
      }
    }
  )
}
```

### Critical Auth Rules
1. **Server: use `getClaims()` not `getSession()`** — `getSession()` doesn't validate JWT
2. **Middleware must refresh tokens** — prevents expired session issues
3. **Every Route Handler checks auth** — no unprotected API routes
4. **Session cookies: HttpOnly + Secure + SameSite** — Supabase SSR handles this

### Common Auth Mistakes in Our Stack
| Mistake | Impact | Fix |
|---------|--------|-----|
| `getSession()` in middleware | JWT not validated, can be spoofed | Use `getClaims()` |
| Service role client for user ops | Bypasses ALL RLS | Use user-scoped client |
| Auth check in layout only | Parallel routes bypass it | Check in each page/action |
| No auth in Server Actions | Anyone can call them | Add `getClaims()` check first |
| Token not refreshed in middleware | Users get logged out | Call `getClaims()` in middleware |

## Next.js Security Headers

```ts
// next.config.ts
const nextConfig = {
  headers: async () => [{
    source: '/(.*)',
    headers: [
      { key: 'X-Frame-Options', value: 'DENY' },
      { key: 'X-Content-Type-Options', value: 'nosniff' },
      { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
      { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
      { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
      // CSP — adjust based on app needs
      { key: 'Content-Security-Policy', value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" },
    ]
  }]
}
```

## CSRF Protection

### Built-in (Next.js Server Actions)
- Server Actions use POST with a unique token — built-in CSRF protection
- Safe by default when using `<form action={serverAction}>`

### Custom API Routes
- Must implement CSRF protection manually for state-changing custom Route Handlers
- Options: SameSite cookies (default in Supabase SSR), custom headers, or Fetch Metadata (`Sec-Fetch-Site`)

### Review Checklist — CSRF
- [ ] State-changing operations use Server Actions (built-in CSRF) or have custom CSRF protection?
- [ ] SameSite cookie attribute set on auth cookies?
- [ ] No state-changing GET requests?

## JSON Injection Prevention

When embedding data in server-rendered HTML:
```tsx
// ❌ DANGEROUS — XSS via </script> in data
<script dangerouslySetInnerHTML={{
  __html: `window.__DATA__ = ${JSON.stringify(data)}`
}} />

// ✅ SAFE — escape < characters
<script dangerouslySetInnerHTML={{
  __html: `window.__DATA__ = ${JSON.stringify(data).replace(/</g, '\\u003c')}`
}} />
```

## Dependency Security

### Review Checklist
- [ ] `npm audit` clean (no high/critical)?
- [ ] No deprecated packages (`@supabase/auth-helpers-nextjs` → `@supabase/ssr`)?
- [ ] Lock file committed?
- [ ] No `dangerouslySetInnerHTML` in library code?
- [ ] ESLint security config installed (`eslint-config-react-security`)?

## Sources
- Next.js Authentication Guide (App Router)
- Snyk: 10 React Security Best Practices
- OWASP Node.js Security Cheat Sheet
- OWASP CSRF Prevention Cheat Sheet
- Supabase SSR Documentation (`@supabase/ssr`)

## Changelog
- 2026-03-20: Initial skill — React/Next.js security patterns mapped for code review
