---
name: performance-profiling
description: Go beyond "this looks slow" to "this IS slow and here's the proof." Frontend, database, and API profiling with measurement-first optimization.
---

# Performance Profiling

## Rule: Measure Before Optimizing

"I think this is slow" is NOT a reason to optimize. Prove it with data.

## Performance Budget

| Category | Target | Action if Exceeded |
|----------|--------|-------------------|
| Page load (LCP) | <2.5s | Investigate render-blocking resources |
| Interaction (INP) | <200ms | Find long tasks in main thread |
| Layout shift (CLS) | <0.1 | Add dimensions to images/embeds |
| API response (p95) | <500ms | Profile query + external calls |
| DB query (p95) | <100ms | Run EXPLAIN ANALYZE |
| Bundle size (JS) | <200KB gzipped | Run bundle analyzer |

## Frontend Profiling

### Bundle Analysis
```bash
# next.config.ts
const withBundleAnalyzer = require('@next/bundle-analyzer')({ enabled: process.env.ANALYZE === 'true' })
module.exports = withBundleAnalyzer(nextConfig)

# Run
ANALYZE=true npm run build
# Opens interactive treemap showing every module's size
```

### React DevTools Profiler
1. Open React DevTools → Profiler tab
2. Record an interaction
3. Look for: components that re-render without prop changes, components with >16ms render time
4. Flamechart shows render hierarchy — tall flames = deep render trees

### Network Waterfall
Chrome DevTools → Network tab:
- Sort by "Waterfall" column — sequential requests should be parallel
- Filter by size — flag responses >100KB
- Check "Disable cache" → measure cold load
- Look for: missing gzip, no cache headers, redundant requests

## Database Profiling

### EXPLAIN ANALYZE
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM entries 
WHERE challenge_id = 'uuid-here' AND status = 'submitted'
ORDER BY final_score DESC;
```

Reading the output:
```
Seq Scan on entries    ← PROBLEM: scanning every row
  Filter: ...          ← Applied AFTER reading all rows
  Rows Removed: 49950  ← Read 50K rows, kept 50
  Buffers: shared hit=1234  ← Pages read from cache

vs.

Index Scan using idx_entries_challenge on entries  ← GOOD
  Index Cond: (challenge_id = 'uuid'::uuid)       ← Used index to find rows
  Buffers: shared hit=5                            ← Only 5 pages read
```

### Query Performance Dashboard
Supabase Dashboard → Database → Query Performance shows:
- Slowest queries (by total time)
- Most frequent queries
- Queries with most rows scanned
- Index usage statistics

## API Profiling

```ts
// Measure every external call
async function profiledFetch(name: string, fn: () => Promise<Response>) {
  const start = performance.now()
  const response = await fn()
  const duration = performance.now() - start
  
  logger.info('external_call', {
    name,
    duration: Math.round(duration),
    status: response.status,
    size: response.headers.get('content-length'),
  })
  
  return response
}

// Usage
const response = await profiledFetch('anthropic_judge', () =>
  fetch('https://api.anthropic.com/v1/messages', { ... })
)
```

### What to Log on Every API Route
```ts
// Middleware or wrapper
const start = performance.now()
const result = await handler(req)
const duration = performance.now() - start

logger.info('api_request', {
  method: req.method,
  path: req.nextUrl.pathname,
  status: result.status,
  duration: Math.round(duration),
  userId: session?.user?.id,
})

// Alert if: p95 > 500ms or p99 > 3s
```

## When to Optimize

1. **Only after measuring** — gut feeling is wrong more often than right
2. **Focus on p95/p99** — averages hide tail latency
3. **Optimize the hottest path** — the most-called endpoint or most-run query
4. **Set a budget, don't gold-plate** — "fast enough" is the goal, not "fastest possible"
5. **Profile in production** — local benchmarks don't reflect real-world load, network, and data volume

## Sources
- web-vitals library — Core Web Vitals measurement
- pino logger — structured performance logging
- PostgreSQL EXPLAIN documentation
- @next/bundle-analyzer

## Changelog
- 2026-03-21: Initial skill — performance profiling
