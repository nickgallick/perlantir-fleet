# Next.js Security Configuration Reference

## Security Headers

### Recommended next.config.js headers
```javascript
const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
]

module.exports = {
  async headers() {
    return [{ source: '/(.*)', headers: securityHeaders }]
  },
}
```

### Content Security Policy for RSC Apps
```javascript
const csp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval'", // unsafe-eval needed for dev only
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob: https:",
  "font-src 'self'",
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join('; ')
```

**Production**: Remove `'unsafe-eval'` from `script-src`. Use nonces for inline scripts.

## Environment Variable Security

### Client vs Server Variables
```
# Server-only (NOT prefixed) — never exposed to client
DATABASE_URL=postgres://...
SUPABASE_SERVICE_ROLE_KEY=...
STRIPE_SECRET_KEY=...
API_SECRET=...

# Client-exposed (NEXT_PUBLIC_ prefix) — visible in browser
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=...
```

**Rule**: NEVER prefix a secret with `NEXT_PUBLIC_`. This is the #1 cause of credential leaks in Next.js apps.

### Validation at Startup
```typescript
// lib/env.ts
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(20),
})

// Validate at build/startup — fail fast
export const env = envSchema.parse(process.env)
```

## Middleware Auth Pattern

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  const response = NextResponse.next({ request })
  
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookies) => {
          cookies.forEach(({ name, value, options }) => {
            response.cookies.set(name, value, options)
          })
        },
      },
    }
  )
  
  // IMPORTANT: Use getUser() not getSession() for server-side auth verification
  // getSession() reads from JWT without verifying — vulnerable to JWT tampering
  const { data: { user } } = await supabase.auth.getUser()
  
  // Protected routes
  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  
  return response
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
}
```

## Server Action Security Pattern

```typescript
// lib/safe-action.ts
import { z } from 'zod'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

type ActionResult<T> = { success: true; data: T } | { success: false; error: string }

export function createSafeAction<TInput, TOutput>(
  schema: z.Schema<TInput>,
  handler: (input: TInput, userId: string) => Promise<TOutput>
) {
  return async (rawInput: TInput): Promise<ActionResult<TOutput>> => {
    // 1. Auth check
    const cookieStore = await cookies()
    const supabase = createServerClient(/* ... */)
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { success: false, error: 'Unauthorized' }
    
    // 2. Input validation
    const parsed = schema.safeParse(rawInput)
    if (!parsed.success) return { success: false, error: 'Invalid input' }
    
    // 3. Execute handler
    try {
      const result = await handler(parsed.data, user.id)
      return { success: true, data: result }
    } catch (e) {
      // 4. Never expose internal errors
      console.error('Action error:', e)
      return { success: false, error: 'An error occurred' }
    }
  }
}
```

## Rate Limiting for Server Actions

```typescript
// lib/rate-limit.ts
const rateLimitMap = new Map<string, { count: number; resetTime: number }>()

export function rateLimit(key: string, limit: number = 10, windowMs: number = 60000): boolean {
  const now = Date.now()
  const entry = rateLimitMap.get(key)
  
  if (!entry || now > entry.resetTime) {
    rateLimitMap.set(key, { count: 1, resetTime: now + windowMs })
    return true
  }
  
  if (entry.count >= limit) return false
  
  entry.count++
  return true
}
```

## Dangerous Patterns to Block in Reviews

| Pattern | Risk | Alternative |
|---------|------|-------------|
| `getSession()` on server | JWT not verified against Supabase | `getUser()` or `getClaims()` |
| `NEXT_PUBLIC_` on secrets | Client-side exposure | Remove prefix, use server-only |
| `dangerouslySetInnerHTML` in RSC | XSS via SSR | Sanitize with DOMPurify or avoid |
| Server action without auth | Unauthenticated RPC | Auth check as first line |
| `redirect(userInput)` | Open redirect | Validate against allowlist |
| `eval()` in API routes | RCE | Never use eval with user input |
| Returning raw DB errors | Info leakage | Generic error messages |
| Missing CSRF on mutations | Cross-site action invocation | Next.js CSRF is default, verify not disabled |
