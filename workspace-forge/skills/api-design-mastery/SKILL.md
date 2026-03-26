---
name: api-design-mastery
description: API design patterns — RESTful conventions, Next.js Route Handlers, webhook security, rate limiting implementation, pagination, and error formats.
---

# API Design Mastery

## Quick Reference — API Review Checklist

1. [ ] Every route validates input with Zod before processing
2. [ ] Every route checks auth first, returns 401/403 early
3. [ ] Error responses use consistent `{ error: { code, message } }` shape
4. [ ] List endpoints have pagination (cursor-based preferred)
5. [ ] Mutations are idempotent (idempotency key or upsert pattern)
6. [ ] Webhook handlers verify HMAC signature
7. [ ] Rate limiting on all public endpoints
8. [ ] Correct HTTP status codes (not 200 for everything)

---

## RESTful Design

### The 15 HTTP Status Codes That Matter

| Code | When to Use | Example |
|------|-------------|---------|
| 200 | Success (GET, PUT, PATCH) | Get challenge, update profile |
| 201 | Created (POST) | New entry created |
| 204 | No content (DELETE) | Entry deleted |
| 400 | Bad request (validation failed) | Invalid Zod parse |
| 401 | Unauthenticated | No session/token |
| 403 | Forbidden (authenticated but not authorized) | Not your resource |
| 404 | Not found | Challenge doesn't exist |
| 409 | Conflict | Duplicate entry, idempotency hit |
| 422 | Unprocessable (semantic error) | Business rule violation |
| 429 | Rate limited | Too many requests |
| 500 | Internal server error | Unexpected crash |

### Pagination: Cursor-Based (preferred for real-time data)
```ts
// Request: GET /api/challenges?cursor=abc123&limit=20
// Response:
{
  data: Challenge[],
  pagination: {
    nextCursor: "def456" | null, // null = no more pages
    hasMore: boolean,
  }
}

// Implementation:
const { data, error } = await supabase
  .from('challenges')
  .select('*')
  .order('created_at', { ascending: false })
  .lt('created_at', decodeCursor(cursor)) // cursor = base64-encoded timestamp
  .limit(limit + 1) // fetch one extra to determine hasMore

const hasMore = data.length > limit
const items = hasMore ? data.slice(0, -1) : data
const nextCursor = hasMore ? encodeCursor(items[items.length - 1].created_at) : null
```

---

## Next.js Route Handler Patterns

### Standard Route Handler Template
```ts
// app/api/challenges/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { z } from 'zod'

const QuerySchema = z.object({
  weightClass: z.enum(['Frontier', 'Contender', 'Scrapper', 'Underdog']).optional(),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
})

export async function GET(req: NextRequest) {
  // 1. Auth
  const supabase = await createClient()
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return NextResponse.json({ error: { code: 'UNAUTHORIZED', message: 'Authentication required' } }, { status: 401 })
  }
  
  // 2. Validate input
  const params = Object.fromEntries(req.nextUrl.searchParams)
  const parsed = QuerySchema.safeParse(params)
  if (!parsed.success) {
    return NextResponse.json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid parameters', details: parsed.error.flatten() } }, { status: 400 })
  }
  
  // 3. Business logic (delegated to service)
  const result = await getChallenges(supabase, parsed.data)
  
  // 4. Response
  return NextResponse.json(result)
}
```

---

## Webhook Security

```ts
// HMAC-SHA256 signature verification (e.g., Stripe webhooks)
import { createHmac, timingSafeEqual } from 'crypto'

async function verifyWebhookSignature(req: NextRequest, secret: string): Promise<boolean> {
  const signature = req.headers.get('x-webhook-signature')
  const timestamp = req.headers.get('x-webhook-timestamp')
  if (!signature || !timestamp) return false
  
  // Reject old webhooks (replay protection)
  const age = Date.now() - parseInt(timestamp) * 1000
  if (age > 5 * 60 * 1000) return false // older than 5 minutes
  
  const body = await req.text()
  const expected = createHmac('sha256', secret)
    .update(`${timestamp}.${body}`)
    .digest('hex')
  
  // Timing-safe comparison prevents timing attacks
  return timingSafeEqual(Buffer.from(signature), Buffer.from(expected))
}

export async function POST(req: NextRequest) {
  if (!await verifyWebhookSignature(req, process.env.WEBHOOK_SECRET!)) {
    return NextResponse.json({ error: { code: 'INVALID_SIGNATURE' } }, { status: 401 })
  }
  
  // Process webhook idempotently
  const body = await req.json()
  await withIdempotency(body.event_id, () => processWebhook(body))
  
  return NextResponse.json({ received: true }) // Return 200 immediately
}
```

---

## Rate Limiting

```ts
// Token bucket with response headers
export async function rateLimit(req: NextRequest, config: {
  key: string, limit: number, windowMs: number
}): Promise<NextResponse | null> {
  const result = await checkRateLimit(config.key, config.limit, config.windowMs)
  
  if (!result.allowed) {
    return NextResponse.json(
      { error: { code: 'RATE_LIMITED', message: 'Too many requests' } },
      { 
        status: 429,
        headers: {
          'X-RateLimit-Limit': String(config.limit),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': result.resetAt.toISOString(),
          'Retry-After': String(Math.ceil((result.resetAt.getTime() - Date.now()) / 1000)),
        }
      }
    )
  }
  return null // Allowed — continue processing
}
```

## Sources
- cal.com API patterns (webhook handling, rate limiting)
- infisical API design (RBAC, audit logging)
- Next.js Route Handler documentation
- Stripe webhook verification patterns

## Changelog
- 2026-03-21: Initial skill — API design mastery
