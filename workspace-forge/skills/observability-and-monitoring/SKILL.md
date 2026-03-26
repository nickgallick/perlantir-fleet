---
name: observability-and-monitoring
description: The three pillars of observability — structured logging, metrics, traces. Alerting without fatigue, incident response, and runbook-driven operations.
---

# Observability & Monitoring

## The Three Pillars

### 1. Logs (Structured JSON with pino)
```ts
import pino from 'pino'

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  redact: ['req.headers.authorization', 'password', 'token', '*.secret'],
})

// Middleware: generate requestId, thread through lifecycle
function withRequestId(handler) {
  return (req, res) => {
    const requestId = crypto.randomUUID()
    const childLogger = logger.child({ requestId, userId: req.user?.id })
    req.log = childLogger
    req.log.info({ method: req.method, path: req.url }, 'request_start')
    const start = performance.now()
    const result = handler(req, res)
    req.log.info({ durationMs: Math.round(performance.now() - start) }, 'request_end')
    return result
  }
}
```

**Required fields:** `timestamp`, `level`, `message`, `requestId`, `userId`, `action`, `durationMs`
**NEVER log:** tokens, passwords, PII, full request bodies, credit card numbers

### 2. Metrics
| Category | Metric | Alert Threshold |
|----------|--------|-----------------|
| Request rate | req/s per endpoint | Sudden drop >50% = incident |
| Error rate | 5xx / total requests | >1% = urgent, >5% = page |
| Latency | p50, p95, p99 per endpoint | p99 >5s = urgent |
| Saturation | DB connections, memory, CPU | >80% = urgent |
| Business | challenges/hour, entries/day, coins/day | Anomaly detection |

### 3. Traces
For our scale, structured logs with `requestId` achieve 90% of tracing benefits:
```
[requestId=abc-123] request_start POST /api/entries
[requestId=abc-123] supabase_query entries.insert 12ms
[requestId=abc-123] gateway_connect agent-42 234ms
[requestId=abc-123] request_end 250ms status=201
```
Full OpenTelemetry when past 100K requests/day.

---

## Alerting Without Fatigue

| Severity | Criteria | Action | Example |
|----------|----------|--------|---------|
| **Page** | Error rate >5% for 5min, health checks failing, payments down | Wake on-call | Judge API returning 500s |
| **Urgent** | Error rate >1%, p99 >5s, DB connections >80% | Fix today | Slow leaderboard queries |
| **Warning** | p95 >2s, error rate >0.5%, new error type | Fix this week | New error in transcript parser |

**Rule:** Every alert MUST have a runbook with specific steps. "Something is wrong" is not actionable.

### Runbook Template
```markdown
## Alert: Error Rate >5%

### Triage (2 min)
1. Check which endpoints are failing: dashboard → error breakdown
2. Check recent deploys: did we ship in the last 30 min?
3. Check external services: is Anthropic/Supabase having an outage?

### Mitigate (5 min)
- If recent deploy: ROLLBACK FIRST, investigate second
- If external service: enable circuit breaker / return cached data
- If unknown: increase logging level to debug, capture next error

### Resolve
- Fix root cause
- Add test to prevent recurrence
- Update this runbook if steps were wrong
```

---

## Incident Response

```
Detect → Triage → Mitigate → Resolve → Postmortem
  ↑                   ↑
  │              ROLLBACK FIRST
  │              then root cause
  └── Alerting + Health checks
```

### Postmortem (Blameless)
```markdown
## Incident: [Title] — [Date]

**Duration:** 45 minutes
**Impact:** 200 users saw error pages on challenge results
**Severity:** P1

**Timeline:**
- 14:00 — Deploy v2.3.1
- 14:05 — Error rate alert fires
- 14:10 — Triage: new deploy identified
- 14:15 — Rollback to v2.3.0
- 14:20 — Error rate returns to normal

**Root cause:** Migration added NOT NULL column without DEFAULT, breaking existing rows.

**Action items:**
- [ ] Add migration safety check to CI (check for NOT NULL without DEFAULT)
- [ ] Update migration-and-schema-evolution skill with this pattern
- [ ] Test all migrations against production-like data before deploy
```

## Sources
- pinojs/pino structured logging
- opentelemetry-js for distributed tracing
- Google SRE Book (alerting, incident response)
- PagerDuty incident response documentation

## Changelog
- 2026-03-21: Initial skill — observability and monitoring
