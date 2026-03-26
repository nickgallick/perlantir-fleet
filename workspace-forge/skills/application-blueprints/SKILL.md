---
name: application-blueprints
description: Complete production starter architecture for Next.js + Supabase + Vercel. Given a product spec, produce the full file tree, schema, middleware, error handling, logging, auth pattern, and env template in one shot.
---

# Application Blueprints

## The Blueprint Deliverables

For any new product, produce ALL of these:

1. **File tree** — complete directory structure (feature-based, bulletproof-react pattern)
2. **Database schema** — all tables, indexes, RLS, functions (see database-schema-design skill)
3. **env.example** — every required variable with description
4. **middleware.ts** — auth refresh, rate limiting, request ID, tenant context
5. **lib/utils/env.ts** — Zod validation of all env vars at startup
6. **lib/utils/errors.ts** — custom error hierarchy
7. **lib/utils/logger.ts** — pino structured logging
8. **lib/supabase/server.ts** — correct SSR client with getClaims()
9. **CI pipeline** — GitHub Actions (lint → typecheck → test → build → deploy)
10. **seed.sql** — development data

## Standard File Tree

```
project/
├── src/
│   ├── app/
│   │   ├── (auth)/                 # Auth-required routes
│   │   │   ├── layout.tsx          # Auth check wrapper
│   │   │   ├── dashboard/page.tsx
│   │   │   └── settings/page.tsx
│   │   ├── (public)/               # No auth required
│   │   │   ├── page.tsx            # Landing
│   │   │   └── pricing/page.tsx
│   │   ├── api/
│   │   │   ├── webhooks/stripe/route.ts
│   │   │   └── health/route.ts
│   │   ├── layout.tsx              # Root (providers, fonts, metadata)
│   │   ├── error.tsx               # Global error boundary
│   │   ├── not-found.tsx
│   │   └── loading.tsx
│   ├── features/                   # Feature-based (bulletproof-react)
│   │   └── {feature}/
│   │       ├── components/
│   │       ├── hooks/
│   │       ├── actions/            # Server Actions
│   │       ├── api/                # Data access (Supabase queries)
│   │       └── types.ts
│   ├── components/
│   │   ├── ui/                     # Shadcn
│   │   ├── layout/                 # Header, Footer, Sidebar
│   │   └── shared/
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts           # Browser (singleton)
│   │   │   ├── server.ts           # Server (per-request, getClaims)
│   │   │   ├── admin.ts            # Service role (webhooks)
│   │   │   └── types.ts            # Generated DB types
│   │   ├── stripe/client.ts
│   │   └── utils/
│   │       ├── errors.ts           # AppError hierarchy
│   │       ├── logger.ts           # Pino structured logging
│   │       ├── env.ts              # Zod env validation
│   │       └── constants.ts
│   ├── middleware.ts
│   └── styles/globals.css
├── supabase/
│   ├── migrations/
│   ├── functions/
│   ├── seed.sql
│   └── config.toml
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── .env.example
├── tsconfig.json                   # strict: true, noUncheckedIndexedAccess: true
└── package.json
```

## Critical Starter Files

### lib/utils/env.ts
```ts
import { z } from 'zod'

const EnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),
  ANTHROPIC_API_KEY: z.string().startsWith('sk-ant-'),
  ENCRYPTION_KEY: z.string().length(64),
})

export const env = EnvSchema.parse(process.env)
// App crashes at startup with clear error if ANY var is missing
```

### lib/utils/errors.ts
```ts
export class AppError extends Error {
  constructor(public code: string, message: string, public status: number, public details?: unknown) {
    super(message)
    this.name = 'AppError'
  }
}
export class NotFoundError extends AppError {
  constructor(resource: string) { super('NOT_FOUND', `${resource} not found`, 404) }
}
export class UnauthorizedError extends AppError {
  constructor() { super('UNAUTHORIZED', 'Authentication required', 401) }
}
export class ForbiddenError extends AppError {
  constructor() { super('FORBIDDEN', 'Insufficient permissions', 403) }
}
export class ValidationError extends AppError {
  constructor(details: unknown) { super('VALIDATION_ERROR', 'Invalid input', 422, details) }
}
```

### lib/supabase/server.ts
```ts
import 'server-only'
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

// Auth helper — ALWAYS use this, never getSession()
export async function getAuthUser() {
  const supabase = await createClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return null
  return user
}
```

### middleware.ts
```ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  const requestId = crypto.randomUUID()
  let response = NextResponse.next({ request })
  response.headers.set('x-request-id', requestId)

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) => {
            request.cookies.set(name, value)
            response.cookies.set(name, value, options)
          })
        }
      }
    }
  )

  // Refresh token (CRITICAL — prevents expired session issues)
  const { data: { user } } = await supabase.auth.getUser()

  // Protect auth-required routes
  if (request.nextUrl.pathname.startsWith('/(auth)') || 
      request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!user) return NextResponse.redirect(new URL('/login', request.url))
  }

  return response
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api/webhooks).*)']
}
```

## Sources
- bulletproof-react project structure
- cal.com production architecture
- Next.js App Router documentation
- @supabase/ssr documentation

## Changelog
- 2026-03-21: Initial skill — application blueprints
