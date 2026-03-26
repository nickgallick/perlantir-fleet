---
name: load-testing-and-capacity
description: k6 load testing, capacity planning, bottleneck identification, and performance budgets for production systems.
---

# Load Testing & Capacity Planning

## k6 Load Test Template

```js
import http from 'k6/http'
import { check, sleep } from 'k6'

export const options = {
  stages: [
    { duration: '30s', target: 50 },   // Ramp to 50 users
    { duration: '1m', target: 50 },    // Hold at 50
    { duration: '30s', target: 200 },  // Spike to 200
    { duration: '1m', target: 200 },   // Hold at 200
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% under 500ms
    http_req_failed: ['rate<0.01'],    // <1% error rate
  },
}

export default function () {
  const res = http.get('https://agentarena.com/api/challenges')
  check(res, {
    'status 200': (r) => r.status === 200,
    'fast response': (r) => r.timings.duration < 500,
  })
  sleep(1)
}
```

## What to Test (Arena)

| Endpoint | Load | Threshold | Why |
|----------|------|-----------|-----|
| GET /api/challenges | 200 concurrent | p95 < 300ms | Most-hit endpoint |
| POST /api/entries | 50 concurrent | p95 < 1s | Challenge start spike |
| GET /api/leaderboard/:class | 500 concurrent | p95 < 200ms | Spectator load |
| POST /api/votes | 100 concurrent | p95 < 500ms | Voting period spike |
| WebSocket spectator | 1000 connections | Connect < 2s | Championship events |
| Supabase Realtime | 500 subscriptions | Event delivery < 200ms | Live leaderboard |
| Edge Function (judge) | 20 concurrent | Complete < 60s | Parallel judging |

## Capacity Planning Process

1. **Measure baseline:** Run k6 at current expected load. Record p50, p95, p99, error rate.
2. **Identify bottleneck:** What breaks first?
   - DB connections maxed → add connection pooling
   - p99 spikes → specific slow query → add index or cache
   - Error rate rises → rate limiting hit → batch or queue
   - Memory grows → leak or unbounded cache → add limits
3. **Extrapolate:** If 50 users → 200ms p95, what about 500 users?
   - IO-bound (DB queries): roughly linear → 500 users ≈ 2000ms unless cached
   - CPU-bound (computation): may plateau or spike
4. **Fix the bottleneck** before scaling further.

## Performance Budgets

| Category | Target | Alert If |
|----------|--------|----------|
| Page load (LCP) | < 2.5s | > 4s |
| API read response | < 500ms p95 | > 1s |
| API write response | < 1s p95 | > 3s |
| Database query | < 100ms p95 | > 500ms |
| Realtime delivery | < 200ms | > 1s |
| AI judge response | < 30s | > 60s |
| WebSocket connect | < 2s | > 5s |

## Running Tests

```bash
# Install k6
brew install k6  # or download from grafana/k6

# Run test
k6 run tests/load/challenges.js

# Run with custom VUs and duration
k6 run --vus 100 --duration 2m tests/load/challenges.js

# Output to JSON for analysis
k6 run --out json=results.json tests/load/challenges.js
```

## When to Load Test

- **Before launch:** establish baseline, find breaking points
- **Before major events:** championship weekends, sponsored challenges
- **After architecture changes:** new caching layer, database migration, new index
- **Monthly:** verify performance hasn't regressed

## Sources
- grafana/k6 documentation and examples
- Vercel serverless performance characteristics
- Supabase connection limits and performance docs

## Changelog
- 2026-03-21: Initial skill — load testing and capacity planning
