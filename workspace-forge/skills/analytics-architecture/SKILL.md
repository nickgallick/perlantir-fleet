---
name: analytics-architecture
description: Product analytics — self-hosted privacy-friendly tracking, event architecture, funnel/cohort analysis, and key metrics per product.
---

# Analytics Architecture

## Self-Hosted Analytics (No Cookie Consent Needed)

Use **Umami** or **Plausible** — lightweight, privacy-focused, no cookies.
- Track: page views, referrers, countries, devices, custom events
- No GDPR cookie banner needed (no cookies = no consent required)
- Deploy on same VPS or separate instance

## Event Tracking Schema

```sql
CREATE TABLE analytics_events (
  id uuid DEFAULT gen_random_uuid(),
  user_id uuid,
  event_type text NOT NULL,
  properties jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
) PARTITION BY RANGE (created_at);

CREATE TABLE analytics_events_2026_03 PARTITION OF analytics_events
  FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

-- Index for common queries
CREATE INDEX idx_events_type_date ON analytics_events (event_type, created_at);
CREATE INDEX idx_events_user ON analytics_events (user_id, created_at);
```

## Key Metrics Per Product

### Arena
| Metric | Query Approach | Target |
|--------|---------------|--------|
| Weekly Active Agents (WAA) | DISTINCT agent_id in entries last 7 days | Growth |
| Challenges completed/week | COUNT entries with status='complete' | Engagement |
| Spectators/challenge | MAX Realtime connections per challenge | Virality |
| Retry rate | % users who enter 2+ challenges | Retention |
| Weight class distribution | GROUP BY weight_class | Balance |

### OUTBOUND
| Metric | Target |
|--------|--------|
| Emails sent/day | Volume |
| Reply rate | >2% for cold |
| Meeting rate | Conversion |
| Revenue per lead | Unit economics |

### MathMind
| Metric | Target |
|--------|--------|
| Daily active students | Growth |
| Session length | >10 min |
| Problems solved/session | Engagement |
| Streak length | Retention |
| Grade progression speed | Learning outcomes |

## Funnel Analysis

```sql
-- Arena conversion funnel
WITH funnel AS (
  SELECT
    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'page_view' AND properties->>'page' = '/') as visited,
    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'signup') as signed_up,
    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'agent_connected') as connected,
    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'challenge_entered') as entered,
    COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'challenge_completed') as completed
  FROM analytics_events
  WHERE created_at > now() - interval '30 days'
)
SELECT
  visited,
  signed_up, ROUND(signed_up::numeric / visited * 100, 1) as signup_rate,
  connected, ROUND(connected::numeric / signed_up * 100, 1) as connect_rate,
  entered, ROUND(entered::numeric / connected * 100, 1) as entry_rate,
  completed, ROUND(completed::numeric / entered * 100, 1) as completion_rate
FROM funnel;
```

## Cohort Analysis

```sql
-- Week-over-week retention by signup cohort
WITH cohorts AS (
  SELECT user_id, date_trunc('week', created_at) as cohort_week
  FROM auth.users
),
activity AS (
  SELECT user_id, date_trunc('week', created_at) as active_week
  FROM analytics_events WHERE event_type = 'challenge_entered'
)
SELECT
  c.cohort_week,
  COUNT(DISTINCT c.user_id) as cohort_size,
  COUNT(DISTINCT a1.user_id) FILTER (WHERE a1.active_week = c.cohort_week + interval '1 week') as week_1,
  COUNT(DISTINCT a1.user_id) FILTER (WHERE a1.active_week = c.cohort_week + interval '4 weeks') as week_4
FROM cohorts c
LEFT JOIN activity a1 ON c.user_id = a1.user_id
GROUP BY c.cohort_week ORDER BY c.cohort_week;
```

## Sources
- Umami analytics documentation
- PostHog product analytics patterns
- Amplitude cohort analysis methodology

## Changelog
- 2026-03-21: Initial skill — analytics architecture
