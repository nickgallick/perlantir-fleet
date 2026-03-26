---
name: production-hardening
description: Production readiness patterns — observability, resilience, graceful degradation, deployment safety, and security headers for Next.js + Supabase + Vercel.
---

# Production Hardening

## Quick Reference — Production Readiness Checklist

1. [ ] Structured JSON logging with requestId, userId, action, duration
2. [ ] Error tracking configured (Sentry with source maps)
3. [ ] Health check endpoint with dependency status
4. [ ] All external API calls have timeouts (10s default)
5. [ ] Retry logic with exponential backoff + jitter on transient failures
6. [ ] Graceful degradation for non-critical features
7. [ ] Security headers configured in next.config.ts
8. [ ] Zero-downtime deployment strategy verified
9. [ ] Feature flags for risky changes
10. [ ] Rollback plan documented and tested

---

## Observability

### Structured Logging
```ts
// lib/logger.ts — consistent logging across all routes
type LogLevel = 'debug' | 'info' | 'warn' | 'error'

function log(level: LogLevel, message: string, context: Record<string, unknown> = {}) {
  const entry = {
    level,
    message,
    timestamp: new Date().toISOString(),
    requestId: context.requestId || 'unknown',
    ...context,
  }
  
  // Never log these fields
  delete entry.password
  delete entry.token
  delete entry.authorization
  
  console[level === 'error' ? 'error' : level === 'warn' ? 'warn' : 'log'](
    JSON.stringify(entry)
  )
}

export const logger = {
  debug: (msg: string, ctx?: Record<string, unknown>) => log('debug', msg, ctx),
  info: (msg: string, ctx?: Record<string, unknown>) => log('info', msg, ctx),
  warn: (msg: string, ctx?: Record<string, unknown>) => log('warn', msg, ctx),
  error: (msg: string, ctx?: Record<string, unknown>) => log('error', msg, ctx),
}
```

### Performance Monitoring
```ts
// Measure endpoint latency
async function withTiming<T>(name: string, fn: () => Promise<T>): Promise<T> {
  const start = performance.now()
  try {
    const result = await fn()
    const duration = performance.now() - start
    logger.info(`${name} completed`, { duration: Math.round(duration), status: 'ok' })
    return result
  } catch (error) {
    const duration = performance.now() - start
    logger.error(`${name} failed`, { duration: Math.round(duration), error: String(error) })
    throw error
  }
}
```

### Alerting Rules (to configure in monitoring tool)
| Condition | Severity | Action |
|-----------|----------|--------|
| Error rate > 5% over 5 min | Critical | Page on-call |
| p99 latency > 3s | High | Alert Slack |
| DB connection pool > 80% | High | Alert + auto-scale |
| Edge Function timeout rate > 2% | Medium | Investigate |
| Auth failure rate spike > 10x baseline | Critical | Possible attack |

---

## Resilience Patterns

### Retry with Jitter
```ts
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelayMs: number = 1000
): Promise<T> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (error) {
      if (attempt === maxRetries) throw error
      
      // Don't retry non-transient errors
      if (error instanceof ValidationError) throw error
      if (error instanceof AuthError) throw error
      
      // Exponential backoff + random jitter
      const delay = baseDelayMs * Math.pow(2, attempt) + Math.random() * 1000
      await new Promise(resolve => setTimeout(resolve, delay))
    }
  }
  throw new Error('Unreachable')
}
```

### Timeout Everything
```ts
async function withTimeout<T>(fn: () => Promise<T>, ms: number, label: string): Promise<T> {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), ms)
  
  try {
    const result = await fn()
    clearTimeout(timer)
    return result
  } catch (error) {
    clearTimeout(timer)
    if (controller.signal.aborted) {
      throw new Error(`${label} timed out after ${ms}ms`)
    }
    throw error
  }
}

// Standard timeouts
const TIMEOUTS = {
  database: 10_000,    // 10s for DB queries
  externalApi: 30_000, // 30s for AI judge calls
  gateway: 15_000,     // 15s for gateway connections
  healthCheck: 5_000,  // 5s for health checks
} as const
```

### Graceful Degradation
```ts
// Non-critical features shouldn't block critical paths
async function getLeaderboardWithFallback(weightClass: string) {
  try {
    // Try: live leaderboard from materialized view
    return await fetchLiveLeaderboard(weightClass)
  } catch (error) {
    logger.warn('Live leaderboard failed, using cached', { error: String(error) })
    try {
      // Fallback 1: cached leaderboard
      return await fetchCachedLeaderboard(weightClass)
    } catch {
      // Fallback 2: static message
      return { data: [], stale: true, message: 'Leaderboard temporarily unavailable' }
    }
  }
}
```

### Health Check Endpoint
```ts
// app/api/health/route.ts
export async function GET() {
  const checks = await Promise.allSettled([
    withTimeout(() => supabase.from('_health').select('1'), 5000, 'database'),
    withTimeout(() => fetch('https://api.anthropic.com/v1/models'), 5000, 'anthropic'),
  ])
  
  const status = {
    status: checks.every(c => c.status === 'fulfilled') ? 'healthy' : 'degraded',
    checks: {
      database: checks[0].status === 'fulfilled' ? 'ok' : 'down',
      anthropic: checks[1].status === 'fulfilled' ? 'ok' : 'down',
    },
    timestamp: new Date().toISOString(),
  }
  
  return NextResponse.json(status, { 
    status: status.status === 'healthy' ? 200 : 503 
  })
}
```

---

## Deployment Safety

### Migration Ordering
```
1. Deploy code that handles BOTH old and new schema ← backward compatible
2. Run database migration
3. Deploy code that uses only new schema
4. (Optional) Run cleanup migration to remove old columns
```
**Never:** Deploy new code that requires new schema before the migration runs.

### Feature Flags
```ts
// Simple feature flags via environment variables or database
const FEATURES = {
  ARENA_COINS: process.env.FEATURE_ARENA_COINS === 'true',
  TOURNAMENTS: process.env.FEATURE_TOURNAMENTS === 'true',
  SPECTATOR_CHAT: process.env.FEATURE_SPECTATOR_CHAT === 'true',
} as const

// Usage
if (FEATURES.TOURNAMENTS) {
  // Show tournament UI
}
```

### Security Headers (next.config.ts)
```ts
const securityHeaders = [
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
  { key: 'Content-Security-Policy', value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com;" },
]

export default {
  async headers() {
    return [{ source: '/(.*)', headers: securityHeaders }]
  }
}
```

## Sources
- infisical — production security patterns (encryption, audit logging)
- sentry-javascript SDK — error tracking integration
- cal.com — deployment pipeline, feature flags
- Vercel deployment documentation

## Changelog
- 2026-03-21: Initial skill — production hardening for Arena
