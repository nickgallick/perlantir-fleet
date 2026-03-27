# Error Handling — Agent Arena

Consistent error handling across Arena's API routes, Supabase queries, Next.js error boundaries, client-side error handling, and logging standards.

---

## API Route Errors — Standard Response Format

Every API error response follows this shape:
```typescript
// Always: { error: string } with appropriate HTTP status
return NextResponse.json({ error: 'Human-readable error message' }, { status: <code> })
```

Never return:
- Raw error objects: `{ error: supabaseError }` — leaks internal details
- Stack traces: `{ error: error.stack }` — security risk
- Generic messages for known errors: `{ error: 'Something went wrong' }` when you know what happened

---

## Status Code Guide for Arena Routes

| Code | Meaning | Arena Usage |
|------|---------|-------------|
| `200` | OK | Successful GET, successful update |
| `201` | Created | `POST /api/agents` (agent registered), `POST /api/challenges/[id]/enter` (entry created) |
| `204` | No Content | Successful delete, no body needed |
| `400` | Bad Request | Zod validation failure, malformed JSON, missing required fields |
| `401` | Unauthorized | No session cookie, no API key, expired token |
| `403` | Forbidden | Authenticated but wrong role (non-admin on admin route), wrong agent owner |
| `404` | Not Found | Challenge doesn't exist, agent doesn't exist, entry not found |
| `409` | Conflict | Duplicate challenge entry, agent name already taken, submission already exists |
| `429` | Rate Limited | Too many requests (include Retry-After header) |
| `500` | Server Error | Unexpected error — log it, return generic message |

### Arena Route Examples

```typescript
// 201 — Resource created
export async function POST(request: NextRequest) {
  // ... validate and create
  const { data, error } = await supabase.from('agents').insert(agentData).select().single()
  if (error) {
    if (error.code === '23505') { // unique violation
      return NextResponse.json({ error: 'Agent name already taken' }, { status: 409 })
    }
    return NextResponse.json({ error: 'Failed to create agent' }, { status: 500 })
  }
  return NextResponse.json({ agent: data }, { status: 201 })
}

// 400 — Validation failure
const parsed = submissionSchema.safeParse(body)
if (!parsed.success) {
  return NextResponse.json(
    { error: parsed.error.issues[0].message },
    { status: 400 }
  )
}

// 401 — Not authenticated
const { data: { user } } = await supabase.auth.getUser()
if (!user) {
  return NextResponse.json({ error: 'Authentication required' }, { status: 401 })
}

// 403 — Not authorized
const { data: agent } = await supabase.from('agents').select('user_id').eq('id', agentId).single()
if (agent?.user_id !== user.id) {
  return NextResponse.json({ error: 'You do not own this agent' }, { status: 403 })
}

// 404 — Not found
const { data: challenge } = await supabase.from('challenges').select('*').eq('id', id).maybeSingle()
if (!challenge) {
  return NextResponse.json({ error: 'Challenge not found' }, { status: 404 })
}

// 409 — Conflict
const { data: existing } = await supabase
  .from('challenge_entries')
  .select('id')
  .eq('user_id', user.id)
  .eq('challenge_id', challengeId)
  .maybeSingle()
if (existing) {
  return NextResponse.json({ error: 'Already entered this challenge' }, { status: 409 })
}

// 429 — Rate limited
if (!rl.success) {
  return NextResponse.json(
    { error: 'Too many requests. Please try again later.' },
    { status: 429, headers: { 'Retry-After': '60' } }
  )
}
```

---

## Supabase Error Handling

### Common Error Codes
| Code | Meaning | Handle As |
|------|---------|-----------|
| `PGRST116` | Row not found (`.single()` returned 0 rows) | 404 |
| `23505` | Unique constraint violation | 409 |
| `23503` | Foreign key violation | 400 (reference doesn't exist) |
| `42501` | RLS permission denied | 403 |
| `42P01` | Table doesn't exist | 500 (schema issue) |
| `PGRST301` | Too many rows for `.single()` | 500 (data integrity issue) |

### Safe Query Patterns

```typescript
// ❌ DANGEROUS — .single() throws on 0 or 2+ rows
const { data } = await supabase.from('agents').select('*').eq('id', id).single()
// If no agent with that ID → PGRST116 error thrown

// ✅ SAFE — .maybeSingle() returns null for 0 rows
const { data, error } = await supabase.from('agents').select('*').eq('id', id).maybeSingle()
if (error) {
  console.error('[api/agents] Query error:', error.message)
  return NextResponse.json({ error: 'Failed to fetch agent' }, { status: 500 })
}
if (!data) {
  return NextResponse.json({ error: 'Agent not found' }, { status: 404 })
}

// ✅ SAFE — .single() only when you're certain exactly 1 row exists
// (e.g., querying by primary key after confirming existence)
const { data: profile } = await supabase
  .from('profiles')
  .select('*')
  .eq('id', user.id) // user.id is guaranteed to exist (just authenticated)
  .single()
```

### RLS Error Detection
```typescript
// RLS denials can look like empty results OR permission errors
const { data, error } = await supabase.from('challenges').select('*')

// If RLS blocks the query, data might be [] (no error), OR:
if (error?.code === '42501') {
  // Explicit permission denied — likely RLS misconfiguration
  console.error('[api/challenges] RLS denied:', error.message)
  return NextResponse.json({ error: 'Access denied' }, { status: 403 })
}

// If data is empty but you expect rows → check RLS policies
if (data && data.length === 0) {
  // Could be legitimate (no challenges) or RLS blocking
  // Log a warning if you expect data to exist
  console.warn('[api/challenges] Empty result — check RLS if unexpected')
}
```

### Insert/Update Error Handling
```typescript
const { data, error } = await supabase
  .from('challenge_entries')
  .insert({ user_id: user.id, challenge_id: challengeId })
  .select()
  .single()

if (error) {
  // Unique constraint violation
  if (error.code === '23505') {
    return NextResponse.json({ error: 'Already entered this challenge' }, { status: 409 })
  }
  // Foreign key violation (challenge doesn't exist)
  if (error.code === '23503') {
    return NextResponse.json({ error: 'Challenge not found' }, { status: 404 })
  }
  // Check constraint violation (invalid status value)
  if (error.code === '23514') {
    return NextResponse.json({ error: 'Invalid data' }, { status: 400 })
  }
  // Generic database error
  console.error('[api/enter] Insert error:', error.code, error.message)
  return NextResponse.json({ error: 'Failed to enter challenge' }, { status: 500 })
}
```

---

## Next.js Error Boundaries

### Route-Level Error UI (`error.tsx`)
```typescript
// src/app/error.tsx — catches errors in any page
'use client' // error.tsx must be a client component

import { useEffect } from 'react'
import { AlertTriangle } from 'lucide-react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error('[error boundary]', error)
  }, [error])

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 p-6 text-center">
      <AlertTriangle className="size-12 text-amber-400" />
      <h2 className="text-xl font-bold text-zinc-50">Something went wrong</h2>
      <p className="text-zinc-400 max-w-md">
        An unexpected error occurred. Please try again.
      </p>
      <button
        onClick={reset}
        className="px-4 py-2 rounded-lg bg-blue-500 text-white hover:bg-blue-600"
      >
        Try again
      </button>
    </div>
  )
}
```

### Not Found Page (`not-found.tsx`)
```typescript
// src/app/not-found.tsx — shown when notFound() is called or route doesn't exist
import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="flex min-h-[60vh] items-center justify-center">
      <div className="text-center">
        <div className="font-mono text-6xl font-bold text-zinc-700">404</div>
        <h1 className="mt-4 text-2xl font-bold text-zinc-50">Page not found</h1>
        <Link href="/" className="mt-4 inline-block px-4 py-2 bg-blue-500 rounded-lg text-white">
          Go home
        </Link>
      </div>
    </div>
  )
}
```

### Using `notFound()` and `redirect()`
```typescript
import { notFound, redirect } from 'next/navigation'

// In a server component or route handler:
export default async function ChallengePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const challenge = await getChallenge(id)
  
  if (!challenge) notFound() // Renders not-found.tsx
  
  if (challenge.status === 'draft') {
    redirect('/challenges') // Server-side redirect
  }
  
  return <ChallengeDetail challenge={challenge} />
}
```

---

## Client-Side Error Handling

### TanStack Query Error Handling
```typescript
'use client'
import { useQuery, useMutation } from '@tanstack/react-query'
import { toast } from 'sonner'

// Query with error handling
function useChallenges() {
  return useQuery({
    queryKey: ['challenges'],
    queryFn: async () => {
      const res = await fetch('/api/challenges')
      if (!res.ok) {
        const body = await res.json().catch(() => ({}))
        throw new Error(body.error || `HTTP ${res.status}`)
      }
      return res.json()
    },
    retry: (failureCount, error) => {
      // Don't retry on 4xx errors (client problem, not transient)
      if (error.message.includes('HTTP 4')) return false
      return failureCount < 3
    },
  })
}

// Mutation with toast notifications
function useEnterChallenge() {
  return useMutation({
    mutationFn: async (challengeId: string) => {
      const res = await fetch(`/api/challenges/${challengeId}/enter`, { method: 'POST' })
      if (!res.ok) {
        const body = await res.json().catch(() => ({}))
        throw new Error(body.error || 'Failed to enter challenge')
      }
      return res.json()
    },
    onSuccess: () => {
      toast.success('Entered challenge!')
    },
    onError: (error: Error) => {
      if (error.message.includes('Already entered')) {
        toast.info('You already entered this challenge')
      } else if (error.message.includes('Rate limited')) {
        toast.warning('Slow down — try again in a minute')
      } else {
        toast.error(error.message)
      }
    },
  })
}
```

### Fetch Wrapper with Error Handling
```typescript
// src/lib/utils/api.ts
export async function apiFetch<T>(url: string, options?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  })

  if (!res.ok) {
    const body = await res.json().catch(() => ({ error: `HTTP ${res.status}` }))
    
    // Handle specific status codes
    if (res.status === 401) {
      window.location.href = '/login'
      throw new Error('Session expired')
    }
    if (res.status === 429) {
      const retryAfter = res.headers.get('Retry-After') ?? '60'
      throw new Error(`Rate limited. Try again in ${retryAfter}s.`)
    }
    
    throw new Error(body.error || `Request failed: ${res.status}`)
  }

  return res.json()
}
```

---

## Logging Standard

### Log Format
```
[module/action] Description: details
```

### Examples
```typescript
// API routes
console.error('[api/auth/github] OAuth error:', error.message)
console.error('[api/challenges/enter] Insert error:', error.code, error.message)
console.warn('[api/challenges] Empty result — check RLS if unexpected')
console.log('[api/v1/submissions] Submission received for entry:', entryId)

// Middleware
console.warn('[middleware] Unauthenticated access to', pathname)

// Client hooks
console.error('[useRealtime] Channel error:', channelName, status)

// Background jobs
console.log('[judge] Starting judging for challenge:', challengeId)
console.error('[judge] AI evaluation failed:', error.message)
```

### Never Log
```typescript
// ❌ Never log API keys or tokens
console.log('API Key:', apiKey)

// ❌ Never log full user objects (contains email, metadata)
console.log('User:', user)

// ❌ Never log request bodies that might contain secrets
console.log('Body:', await request.json())

// ❌ Never log passwords or secrets
console.log('Service key:', process.env.SUPABASE_SERVICE_ROLE_KEY)

// ✅ Log only what's needed for debugging
console.log('[api/agents] Agent registered:', agent.id, agent.name)
console.error('[api/submit] Failed for entry:', entryId, 'error:', error.message)
```

---

## Error Handling Checklist for New Routes

When building a new API route, verify:

```
□ All Supabase queries have error handling (check { error })
□ .single() only used when exactly 1 row guaranteed — otherwise use .maybeSingle()
□ Zod validation on all request bodies
□ 401 returned for unauthenticated requests (if route requires auth)
□ 403 returned for wrong role/ownership
□ 404 returned for missing resources
□ 409 returned for duplicates/conflicts
□ 429 returned for rate-limited requests (with Retry-After header)
□ 500 catches unexpected errors with generic user message + console.error with details
□ No sensitive data in error responses (no stack traces, no internal error objects)
□ Logging follows [module/action] format
□ Try/catch wraps the entire handler to prevent unhandled rejections
```

### Route Handler Template
```typescript
export async function POST(request: NextRequest) {
  try {
    // 1. Rate limit
    const ip = getClientIp(request)
    const rl = await rateLimit(`action:${ip}`, 10, 60_000)
    if (!rl.success) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429, headers: { 'Retry-After': '60' } })
    }

    // 2. Auth check
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Authentication required' }, { status: 401 })
    }

    // 3. Parse and validate body
    const body = await request.json().catch(() => null)
    if (!body) {
      return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 })
    }
    const parsed = mySchema.safeParse(body)
    if (!parsed.success) {
      return NextResponse.json({ error: parsed.error.issues[0].message }, { status: 400 })
    }

    // 4. Business logic with error handling
    const { data, error } = await supabase.from('table').insert(parsed.data).select().single()
    if (error) {
      if (error.code === '23505') return NextResponse.json({ error: 'Already exists' }, { status: 409 })
      console.error('[api/route] Insert error:', error.code, error.message)
      return NextResponse.json({ error: 'Operation failed' }, { status: 500 })
    }

    // 5. Success
    return NextResponse.json({ data }, { status: 201 })
  } catch (err) {
    console.error('[api/route] Unexpected error:', err instanceof Error ? err.message : err)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
```
