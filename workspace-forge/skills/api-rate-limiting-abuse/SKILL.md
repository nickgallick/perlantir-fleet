---
name: api-rate-limiting-abuse
description: Rate limiting design, implementation review, and bypass detection for Next.js API routes and Supabase Edge Functions. Use when reviewing API endpoints for abuse resistance, checking authentication endpoints for brute force protection, reviewing data endpoints for scraping prevention, or auditing public endpoints for DoS resistance. Covers per-user, per-IP, per-endpoint strategies, sliding window vs fixed window vs token bucket algorithms, common bypass techniques (header spoofing, distributed attacks, account rotation), Vercel-specific rate limiting, and Supabase's built-in limits.
---

# API Rate Limiting & Abuse Prevention

## Why Rate Limiting Is Security-Critical

Without rate limiting, attackers can:
- **Brute force authentication** — try millions of passwords
- **Enumerate resources** — map all user IDs, emails, documents
- **Scrape data** — extract entire databases via API
- **Denial of Service** — exhaust server resources or API quotas
- **Cost attacks** — trigger expensive operations (AI inference, email sending) at scale
- **Abuse free tiers** — consume resources meant for many users

## What Needs Rate Limiting

| Endpoint Type | Why | Recommended Limit |
|---------------|-----|-------------------|
| Login/auth | Brute force prevention | 5-10 attempts per 15 min per IP |
| Signup | Spam account prevention | 3 per hour per IP |
| Password reset | Email bombing prevention | 3 per hour per email |
| API with auth | General abuse | 100-1000 per min per user |
| API without auth | Scraping/DoS | 20-60 per min per IP |
| Webhooks | Replay/forge prevention | Verify signatures instead |
| File upload | Storage abuse | 10 per hour per user, size limits |
| AI/LLM endpoints | Cost attack prevention | 10-50 per hour per user |
| Email/SMS sending | Spam prevention | 5 per hour per user |
| Data export | Scraping prevention | 5 per day per user |
| Search | Resource exhaustion | 30 per min per user |

## Implementation Patterns

### Pattern 1: In-Memory (Simple, Single Server)
```typescript
// Good for: development, single-instance deployments
// Bad for: multi-instance (Vercel serverless) — each function has its own memory

const rateLimitMap = new Map<string, { count: number; resetAt: number }>()

function rateLimit(key: string, limit: number, windowMs: number): boolean {
  const now = Date.now()
  const entry = rateLimitMap.get(key)
  
  if (!entry || now >= entry.resetAt) {
    rateLimitMap.set(key, { count: 1, resetAt: now + windowMs })
    return true
  }
  
  if (entry.count >= limit) return false
  entry.count++
  return true
}
```

**Problem on Vercel**: Serverless functions are stateless. Rate limit state is lost between invocations. You need external storage.

### Pattern 2: Upstash Redis (Serverless-Friendly)
```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '60 s'),  // 10 requests per 60 seconds
  analytics: true,
})

export async function POST(request: Request) {
  const ip = request.headers.get('x-forwarded-for') ?? '127.0.0.1'
  const { success, limit, remaining, reset } = await ratelimit.limit(ip)
  
  if (!success) {
    return new Response('Too Many Requests', {
      status: 429,
      headers: {
        'Retry-After': String(Math.ceil((reset - Date.now()) / 1000)),
        'X-RateLimit-Limit': String(limit),
        'X-RateLimit-Remaining': '0',
      }
    })
  }
  
  // Process request
}
```

### Pattern 3: Supabase RPC Rate Limiting
```sql
-- Rate limit at database level
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_key TEXT,
  p_limit INT,
  p_window_seconds INT
) RETURNS BOOLEAN AS $$
DECLARE
  v_count INT;
BEGIN
  -- Clean old entries
  DELETE FROM rate_limits 
  WHERE key = p_key AND created_at < NOW() - (p_window_seconds || ' seconds')::interval;
  
  -- Count recent entries
  SELECT COUNT(*) INTO v_count FROM rate_limits WHERE key = p_key;
  
  IF v_count >= p_limit THEN
    RETURN FALSE;
  END IF;
  
  -- Record this request
  INSERT INTO rate_limits (key, created_at) VALUES (p_key, NOW());
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
```

### Pattern 4: Middleware-Level Rate Limiting
```typescript
// middleware.ts — applies to all routes
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.fixedWindow(100, '60 s'),
})

export async function middleware(request: NextRequest) {
  // Only rate limit API routes
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next()
  }
  
  const ip = request.ip ?? request.headers.get('x-forwarded-for') ?? 'unknown'
  const { success } = await ratelimit.limit(`api:${ip}`)
  
  if (!success) {
    return new Response('Rate limit exceeded', { status: 429 })
  }
  
  return NextResponse.next()
}
```

## Rate Limit Bypass Techniques (What Attackers Try)

### Bypass 1: IP Rotation
Attacker uses VPN, Tor, or botnet to rotate IPs.

**Defense**: Combine IP-based AND user-based limits. Authenticated endpoints: rate limit by user ID, not just IP. Add CAPTCHA after suspicious patterns.

### Bypass 2: X-Forwarded-For Spoofing
```bash
# Attacker spoofs IP header
curl -H "X-Forwarded-For: 1.2.3.4" https://your-api.com/login
```

**Defense**: Trust `X-Forwarded-For` only from your reverse proxy. On Vercel: use `request.ip` (Vercel sets this from the actual client IP). Don't trust raw `X-Forwarded-For` from the client.

### Bypass 3: Account Rotation
Create many accounts → distribute requests across accounts.

**Defense**: Also rate limit by IP for authenticated endpoints. Monitor for account creation patterns (same IP creating many accounts).

### Bypass 4: Endpoint Variation
```
/api/login
/api/Login
/api/login/
/api/login?dummy=1
```

**Defense**: Normalize paths before rate limiting. Strip query params, lowercase, remove trailing slashes.

### Bypass 5: HTTP Method Variation
If rate limit only applies to POST but the endpoint also accepts GET.

**Defense**: Rate limit applies to the endpoint regardless of method.

### Bypass 6: Slow and Low
Stay just under the rate limit — 99 requests per minute when limit is 100.

**Defense**: Use sliding windows (not fixed windows). Monitor for sustained near-limit activity. Consider progressive penalties (each offense doubles the cooldown).

### Bypass 7: Distributed Attack
Many IPs, each sending few requests, in aggregate overwhelming.

**Defense**: Rate limit globally (total requests to endpoint), not just per-IP. Set absolute capacity limits. Use WAF for DDoS protection.

## Algorithm Comparison

| Algorithm | Pros | Cons | Best For |
|-----------|------|------|----------|
| **Fixed Window** | Simple, predictable | Burst at window boundary (2x limit) | General API limiting |
| **Sliding Window** | Smooth, no boundary burst | More memory/compute | Auth endpoints |
| **Token Bucket** | Allows short bursts, smooth long-term | Complex | APIs with burst needs |
| **Leaky Bucket** | Perfectly smooth output | No burst tolerance | Background job queues |

### The Window Boundary Problem
Fixed window: Limit 100/minute. At 0:59 user sends 100 requests. At 1:00 (new window) sends 100 more. = 200 requests in 2 seconds.

Sliding window prevents this by looking at the actual window around each request.

## Response Headers (Be a Good API Citizen)
```typescript
return new Response(body, {
  status: success ? 200 : 429,
  headers: {
    'X-RateLimit-Limit': String(limit),
    'X-RateLimit-Remaining': String(remaining),
    'X-RateLimit-Reset': String(reset),
    ...(success ? {} : { 'Retry-After': String(retryAfterSeconds) })
  }
})
```

## Auth-Specific Rate Limiting

### Login: Progressive Delays
```typescript
async function handleLogin(email: string, password: string, ip: string) {
  // Layer 1: Per-IP rate limit (prevent distributed brute force on one account)
  const ipOk = await rateLimit(`login:ip:${ip}`, 20, 900_000)  // 20/15min
  if (!ipOk) return { error: 'Too many attempts. Try again later.' }
  
  // Layer 2: Per-account rate limit (prevent distributed brute force)
  const accountOk = await rateLimit(`login:acct:${email}`, 5, 900_000)  // 5/15min
  if (!accountOk) return { error: 'Account temporarily locked.' }
  
  // Layer 3: Global rate limit (prevent DoS on auth service)
  const globalOk = await rateLimit('login:global', 1000, 60_000)  // 1000/min
  if (!globalOk) return { error: 'Service temporarily unavailable.' }
  
  // Actual auth check
  const user = await authenticate(email, password)
  if (!user) {
    // Layer 4: After N failures, require CAPTCHA
    const failCount = await incrementFailureCount(email)
    if (failCount >= 3) return { error: 'CAPTCHA required', requireCaptcha: true }
    return { error: 'Invalid credentials' }
  }
  
  await resetFailureCount(email)
  return { user }
}
```

## Cost Attack Prevention (AI/LLM Endpoints)

For any endpoint that triggers expensive operations:
```typescript
// Per-user daily cost limit
const dailyCost = await getUserDailyCost(userId)
if (dailyCost >= user.plan.dailyLimit) {
  return Response.json({ error: 'Daily usage limit reached' }, { status: 429 })
}

// Per-request complexity limit
const estimatedTokens = estimateTokenCount(input)
if (estimatedTokens > 10000) {
  return Response.json({ error: 'Request too large' }, { status: 400 })
}
```

## Review Checklist

- [ ] All public endpoints have rate limiting
- [ ] Auth endpoints have aggressive limits (5-10 per 15 min)
- [ ] Rate limiting uses external storage on serverless (not in-memory)
- [ ] Rate limit key combines IP + user where possible
- [ ] `X-Forwarded-For` not blindly trusted — use platform-provided IP
- [ ] Rate limit paths are normalized (lowercase, no trailing slash, no query params)
- [ ] 429 responses include `Retry-After` header
- [ ] Expensive operations (AI, email, export) have per-user cost limits
- [ ] Progressive penalties on repeated abuse (CAPTCHA, lockout)
- [ ] Global rate limits exist as DoS backstop

## References

For authentication-specific patterns, see `jwt-session-attacks` skill.
For DoS patterns beyond rate limiting, see `redos-and-dos-patterns` skill.
