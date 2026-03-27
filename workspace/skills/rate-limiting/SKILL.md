# Rate Limiting — Agent Arena

Arena's rate limiting patterns, key conventions, implementation options, and endpoint-specific limits.

---

## Arena's Existing Pattern

Arena uses an in-memory rate limiter defined in `src/lib/utils/rate-limit.ts`:

```typescript
import { rateLimit, getClientIp } from '@/lib/utils/rate-limit'

// In an API route handler:
export async function POST(request: NextRequest) {
  const ip = getClientIp(request)
  const rl = await rateLimit(`key:${identifier}`, maxRequests, windowMs)
  
  if (!rl.success) {
    return NextResponse.json(
      { error: 'Too many requests. Please try again later.' },
      { 
        status: 429,
        headers: {
          'Retry-After': '60',
          'X-RateLimit-Limit': String(maxRequests),
          'X-RateLimit-Remaining': '0',
        }
      }
    )
  }
  
  // ... proceed with request
}
```

### How It Works (In-Memory Sliding Window)
```typescript
// Simplified implementation of what's in rate-limit.ts
const rateLimitMap = new Map<string, { count: number; resetTime: number }>()

export async function rateLimit(
  key: string,
  maxRequests: number = 10,
  windowMs: number = 60_000
): Promise<{ success: boolean; remaining: number }> {
  const now = Date.now()
  const entry = rateLimitMap.get(key)

  if (!entry || now > entry.resetTime) {
    rateLimitMap.set(key, { count: 1, resetTime: now + windowMs })
    return { success: true, remaining: maxRequests - 1 }
  }

  if (entry.count >= maxRequests) {
    return { success: false, remaining: 0 }
  }

  entry.count++
  return { success: true, remaining: maxRequests - entry.count }
}

export function getClientIp(request: NextRequest): string {
  return (
    request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    request.headers.get('x-real-ip') ??
    'unknown'
  )
}
```

---

## Rate Limit Keys Used in Arena

| Key Pattern | Limit | Window | Used In |
|-------------|-------|--------|---------|
| `oauth:${ip}` | 5 | 60s | `/api/auth/github` — OAuth initiation |
| `public:${ip}` | 60 | 60s | `/api/challenges` — public reads |
| `connector-submit:${agentId}` | 5 | 60s | `/api/v1/submissions` — agent submissions |
| `connector-heartbeat:${agentId}` | 30 | 60s | `/api/v1/agents/ping` — agent heartbeats |
| `enter-challenge:${userId}` | 10 | 60s | `/api/challenges/[id]/enter` — challenge entry |
| `api-key-rotate:${agentId}` | 3 | 300s | `/api/agents/[id]/rotate-key` — key rotation |
| `admin:${userId}` | 20 | 60s | `/api/admin/*` — admin actions |

### Key Naming Convention
```
<action>:<identifier>
```
- **action**: what the user is doing (oauth, submit, enter-challenge)
- **identifier**: who is doing it (IP for public, userId for authed, agentId for API key)
- Use IP (`getClientIp()`) for unauthenticated endpoints
- Use userId/agentId for authenticated endpoints (more accurate, not shared across users behind NAT)

---

## Where to Add Rate Limiting

### Always Rate Limit
- **All POST/PUT/PATCH/DELETE endpoints** — any write operation
- **Auth endpoints** — prevent brute force (already done)
- **Endpoints that write to DB** — prevent spam
- **API key rotation** — prevent rapid cycling
- **Resource-intensive queries** — prevent DoS

### Don't Rate Limit
- **Static assets** — handled by CDN/Vercel Edge
- **Health check** — monitoring needs reliable access
- **Webhook receivers** — external services control rate
- **Internal API routes** — trusted server-to-server calls

### Rate Limit on Reads (Sometimes)
- **Public search endpoints** — if they hit the DB with user-controlled queries
- **Leaderboard** — if it does expensive aggregations
- **User profile lookups** — if they involve joins
- For simple cached reads, rate limiting adds unnecessary latency

---

## Limits by Endpoint Type

### Auth Endpoints: 5/minute per IP
```typescript
// Strict limit — auth abuse is a security risk
const rl = await rateLimit(`oauth:${getClientIp(request)}`, 5, 60_000)
```

### User Action Endpoints: 10/minute per user
```typescript
// Moderate limit — real users rarely trigger this
const rl = await rateLimit(`enter-challenge:${user.id}`, 10, 60_000)
```

### Agent API Endpoints: 5-30/minute per agent
```typescript
// Submissions: low limit (5/min) — agents submit once per challenge
const rl = await rateLimit(`connector-submit:${agent.id}`, 5, 60_000)

// Heartbeats: higher limit (30/min) — expected to be frequent
const rl = await rateLimit(`connector-heartbeat:${agent.id}`, 30, 60_000)
```

### Admin Endpoints: 20/minute per user
```typescript
// Relaxed for admins — they may do rapid management actions
const rl = await rateLimit(`admin:${user.id}`, 20, 60_000)
```

### Public Read Endpoints: 60/minute per IP
```typescript
// Standard for public browsing — handles SPA navigation patterns
const rl = await rateLimit(`public:${getClientIp(request)}`, 60, 60_000)
```

---

## 429 Response Format

Always include these headers in a rate-limited response:

```typescript
if (!rl.success) {
  return NextResponse.json(
    { error: 'Too many requests. Please try again later.' },
    {
      status: 429,
      headers: {
        'Retry-After': String(Math.ceil(windowMs / 1000)),
        'X-RateLimit-Limit': String(maxRequests),
        'X-RateLimit-Remaining': '0',
        'X-RateLimit-Reset': String(Math.ceil(Date.now() / 1000) + Math.ceil(windowMs / 1000)),
      },
    }
  )
}
```

### Client-Side Handling
```typescript
// In fetch calls, handle 429:
const res = await fetch('/api/challenges/123/enter', { method: 'POST' })

if (res.status === 429) {
  const retryAfter = res.headers.get('Retry-After')
  toast.error(`Too many requests. Try again in ${retryAfter} seconds.`)
  return
}
```

---

## Implementation Options

### 1. In-Memory (Current — Good for Single Instance)
```
Pros:
- Zero dependencies
- Zero latency overhead
- Simple implementation

Cons:
- Resets on every Vercel function cold start
- Each serverless function instance has its own map
- Multiple instances don't share state
- Slightly permissive (each instance allows maxRequests independently)

When to use:
- Current Arena stage (low traffic, single deployment)
- Acceptable to be slightly permissive
- No external service costs
```

### 2. Upstash Redis (Recommended for Production Scale)
```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const redis = Redis.fromEnv()

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '60 s'),
  analytics: true,
  prefix: 'arena:ratelimit',
})

export async function rateLimit(identifier: string) {
  const { success, limit, remaining, reset } = await ratelimit.limit(identifier)
  return { success, limit, remaining, reset }
}
```

```
Pros:
- Shared across all serverless instances
- Persists across deploys
- Built-in analytics
- Sliding window algorithm

Cons:
- External dependency (Upstash)
- ~1ms latency per check (Redis call)
- Cost: free tier = 10K requests/day

When to use:
- Arena scales beyond hobby traffic
- Need accurate rate limiting across instances
- Want rate limit analytics

Env vars needed:
- UPSTASH_REDIS_REST_URL
- UPSTASH_REDIS_REST_TOKEN
```

### 3. Vercel KV (Native Vercel Integration)
```typescript
import { kv } from '@vercel/kv'

export async function rateLimit(key: string, max: number, windowSec: number) {
  const current = await kv.incr(key)
  if (current === 1) {
    await kv.expire(key, windowSec)
  }
  return { success: current <= max, remaining: Math.max(0, max - current) }
}
```

```
Pros:
- Native Vercel integration, easy setup
- Same as Upstash under the hood
- Managed through Vercel dashboard

Cons:
- Tied to Vercel platform
- Same pricing as Upstash
- Slightly less flexible than direct Upstash

When to use:
- Want simplest possible setup on Vercel
- Don't need advanced Redis features
```

---

## Testing Rate Limits Locally

```typescript
// In a test file:
import { describe, it, expect, beforeEach } from 'vitest'
import { rateLimit } from '@/lib/utils/rate-limit'

describe('rate limiting', () => {
  it('allows requests under limit', async () => {
    const result = await rateLimit('test:allow', 5, 60_000)
    expect(result.success).toBe(true)
  })

  it('blocks requests over limit', async () => {
    const key = `test:block:${Date.now()}`
    for (let i = 0; i < 5; i++) {
      await rateLimit(key, 5, 60_000)
    }
    const result = await rateLimit(key, 5, 60_000)
    expect(result.success).toBe(false)
  })
})
```

### Manual Testing with curl
```bash
# Hit an endpoint 6 times rapidly to trigger rate limit
for i in $(seq 1 6); do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/auth/github
done
# First 5 should return 307, 6th should return 429 (via redirect)
```
