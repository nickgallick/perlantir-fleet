---
name: evaluation-analytics-pipeline
description: Design and implement the analytics pipeline powering lane score distributions, repeated weakness patterns, agent progress over time, and challenge-level learning analytics — using materialized views, pg_cron refresh, and a clean separation between operational and analytical tables.
---

# Evaluation Analytics Pipeline

## Review Checklist

- [ ] Every materialized view has a `CONCURRENTLY` refresh option configured — non-concurrent refresh locks the view and blocks reads for up to 30 seconds on large data
- [ ] Materialized views have a UNIQUE index defined — `REFRESH MATERIALIZED VIEW CONCURRENTLY` requires a unique index or it silently falls back to blocking refresh
- [ ] pg_cron extension is installed and the refresh cron job has a schedule that matches data freshness requirements (5-15 min for active competition; hourly for historical analytics)
- [ ] Operational tables (submissions, judge_outputs) are never altered when adding a new analytics view — new views read from existing operational tables
- [ ] The analytics data model uses separate `analytics_*` or `mv_*` prefixed tables — never mixing analytical columns into operational tables
- [ ] Backfill script exists and is idempotent — running it twice must not create duplicate rows or corrupt existing analytics
- [ ] TypeScript analytics query layer returns typed results with Zod schemas — no `any` return types from analytics queries
- [ ] New analytics view addition documented with: the business question it answers, the source table(s), the refresh cadence, and the query cost estimate from `EXPLAIN ANALYZE`
- [ ] `pg_cron` schedule errors are captured — failed refresh jobs must alert, not silently fail for hours
- [ ] The event-driven trigger for new submission completion fires the materialized view refresh asynchronously — never synchronously in the submission completion transaction
- [ ] Analytical queries never JOIN against operational tables in the hot path — analytics reads only from materialized views and analytics tables
- [ ] Lane distribution materialized view includes `challenge_id` partition — percentile queries without this partition will mix distributions across incomparable challenges

---

## Operational vs. Analytical Queries — The Core Distinction

**Operational queries** power the live UI. They need to be fast (< 100ms), return per-submission data, and are called on every page load. They read from: `submissions`, `judge_outputs`, `bout_results`. They must be indexed perfectly.

**Analytical queries** answer questions about patterns across the system. They are expensive (can take 1-30 seconds), aggregate across thousands of rows, and should NEVER run on page load. They power: admin dashboards, coach insights, platform health monitors, progress reports.

**The rule:** If an analytical query runs in a hot request path (user-facing page load, API route called per submission), it will eventually cause a timeout or OOM. Materialized views solve this by pre-computing expensive aggregates on a schedule.

**The data flow:**

```
Operational Tables (real-time writes)
  ↓
pg_cron / webhook trigger (every N minutes)
  ↓
REFRESH MATERIALIZED VIEW CONCURRENTLY
  ↓
Analytical Views (pre-computed, fast reads)
  ↓
Analytics API routes (read-only, fast)
  ↓
Analytics UI components
```

The analytical views are always slightly stale. That's acceptable — a leaderboard distribution showing 5-minute-old percentiles is fine. A per-submission score showing 5-minute-old data is not.

---

## Materialized Views — Lane Distributions and Weakness Patterns

**Setup: Ensure the views have unique indexes for CONCURRENT refresh**

```sql
-- Materialized view: lane score percentiles per challenge
CREATE MATERIALIZED VIEW mv_lane_score_distribution AS
SELECT
  s.challenge_id,
  lane_key,
  COUNT(*) AS sample_count,
  ROUND(AVG(lane_score)::NUMERIC, 3) AS mean_score,
  ROUND(STDDEV(lane_score)::NUMERIC, 3) AS stddev_score,
  ROUND(MIN(lane_score)::NUMERIC, 3) AS min_score,
  ROUND(MAX(lane_score)::NUMERIC, 3) AS max_score,
  ROUND(PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY lane_score)::NUMERIC, 3) AS p10,
  ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY lane_score)::NUMERIC, 3) AS p25,
  ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY lane_score)::NUMERIC, 3) AS p50,
  ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY lane_score)::NUMERIC, 3) AS p75,
  ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY lane_score)::NUMERIC, 3) AS p90,
  MAX(s.created_at) AS last_submission_at
FROM submissions s,
  LATERAL jsonb_each(s.final_lane_scores) AS ls(lane_key, lane_value),
  LATERAL (SELECT (lane_value::TEXT)::FLOAT AS lane_score) computed
WHERE s.status = 'scored'
  AND s.final_lane_scores IS NOT NULL
GROUP BY s.challenge_id, lane_key
WITH DATA;

-- Required unique index for CONCURRENT refresh
CREATE UNIQUE INDEX idx_mv_lane_dist_pk
  ON mv_lane_score_distribution(challenge_id, lane_key);
```

**Materialized view: repeated weakness patterns**

```sql
CREATE MATERIALIZED VIEW mv_weakness_patterns AS
WITH agent_lane_history AS (
  SELECT
    s.agent_id,
    s.challenge_id,
    lane_key,
    (lane_value::TEXT)::FLOAT AS lane_score,
    s.created_at
  FROM submissions s,
    LATERAL jsonb_each(s.final_lane_scores) AS ls(lane_key, lane_value)
  WHERE s.status = 'scored'
    AND s.final_lane_scores IS NOT NULL
),
agent_lane_stats AS (
  SELECT
    agent_id,
    challenge_id,
    lane_key,
    COUNT(*) AS attempt_count,
    ROUND(AVG(lane_score)::NUMERIC, 3) AS avg_score,
    ROUND(MIN(lane_score)::NUMERIC, 3) AS min_score,
    ROUND(MAX(lane_score)::NUMERIC, 3) AS max_score,
    -- Trend: positive = improving, negative = regressing
    ROUND(
      REGR_SLOPE(lane_score, EXTRACT(EPOCH FROM created_at))::NUMERIC,
      8
    ) AS score_trend_slope
  FROM agent_lane_history
  GROUP BY agent_id, challenge_id, lane_key
  HAVING COUNT(*) >= 2  -- Need at least 2 data points for trend
)
SELECT
  als.*,
  -- Categorize the lane performance
  CASE
    WHEN als.avg_score < dist.p25 THEN 'persistent_weakness'
    WHEN als.avg_score < dist.p50 THEN 'below_median'
    WHEN als.avg_score > dist.p75 THEN 'consistent_strength'
    ELSE 'average'
  END AS performance_category,
  dist.p25 AS challenge_p25,
  dist.p50 AS challenge_p50,
  dist.p75 AS challenge_p75
FROM agent_lane_stats als
JOIN mv_lane_score_distribution dist
  ON als.challenge_id = dist.challenge_id AND als.lane_key = dist.lane_key
WITH DATA;

CREATE UNIQUE INDEX idx_mv_weakness_pk
  ON mv_weakness_patterns(agent_id, challenge_id, lane_key);

CREATE INDEX idx_mv_weakness_category
  ON mv_weakness_patterns(performance_category, challenge_id);
```

**Materialized view: agent progress over time**

```sql
CREATE MATERIALIZED VIEW mv_agent_progress AS
SELECT
  s.agent_id,
  s.challenge_id,
  DATE_TRUNC('week', s.created_at) AS week,
  COUNT(*) AS submission_count,
  ROUND(AVG(s.composite_score)::NUMERIC, 3) AS avg_composite_score,
  ROUND(MAX(s.composite_score)::NUMERIC, 3) AS best_composite_score,
  ROUND(MIN(s.composite_score)::NUMERIC, 3) AS worst_composite_score,
  -- Week-over-week improvement
  ROUND((
    AVG(s.composite_score) -
    LAG(AVG(s.composite_score)) OVER (
      PARTITION BY s.agent_id, s.challenge_id
      ORDER BY DATE_TRUNC('week', s.created_at)
    )
  )::NUMERIC, 3) AS wow_composite_delta
FROM submissions s
WHERE s.status = 'scored'
  AND s.composite_score IS NOT NULL
GROUP BY s.agent_id, s.challenge_id, DATE_TRUNC('week', s.created_at)
WITH DATA;

CREATE UNIQUE INDEX idx_mv_progress_pk
  ON mv_agent_progress(agent_id, challenge_id, week);
```

---

## pg_cron Setup — Scheduled Refresh

```sql
-- Install extension (once per database)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Refresh lane distributions every 10 minutes (active competition window)
SELECT cron.schedule(
  'refresh-lane-distributions',
  '*/10 * * * *',
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY mv_lane_score_distribution$$
);

-- Refresh weakness patterns every 30 minutes
SELECT cron.schedule(
  'refresh-weakness-patterns',
  '*/30 * * * *',
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY mv_weakness_patterns$$
);

-- Refresh agent progress hourly (weekly aggregates don't need frequent refresh)
SELECT cron.schedule(
  'refresh-agent-progress',
  '0 * * * *',
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY mv_agent_progress$$
);

-- Check cron job status
SELECT jobid, jobname, schedule, active, lastruntime
FROM cron.job
ORDER BY jobname;

-- Check recent run history (last 10 runs per job)
SELECT jobid, job_pid, database, username, command,
       status, return_message, start_time, end_time
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 50;
```

**Event-driven trigger: refresh on submission completion**

```sql
-- When a submission moves to 'scored' status, trigger async refresh
-- Uses pg_notify so the refresh doesn't block the transaction
CREATE OR REPLACE FUNCTION notify_submission_scored()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'scored' AND (OLD.status IS DISTINCT FROM 'scored') THEN
    -- Async notification — the listener handles the actual refresh
    PERFORM pg_notify('submission_scored', json_build_object(
      'submission_id', NEW.id,
      'challenge_id', NEW.challenge_id,
      'agent_id', NEW.agent_id
    )::text);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_submission_scored
  AFTER UPDATE OF status ON submissions
  FOR EACH ROW EXECUTE FUNCTION notify_submission_scored();
```

**TypeScript pg_notify listener (runs as a long-lived process)**

```typescript
// workers/analytics-refresh-worker.ts
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

let refreshDebounceTimer: NodeJS.Timeout | null = null;

async function refreshAnalyticsViews(challengeId: string): Promise<void> {
  const client = await pool.connect();
  try {
    console.log(`[analytics-refresh] Refreshing views for challenge ${challengeId}`);
    // Refresh in dependency order: distribution first, then weakness patterns
    await client.query('REFRESH MATERIALIZED VIEW CONCURRENTLY mv_lane_score_distribution');
    await client.query('REFRESH MATERIALIZED VIEW CONCURRENTLY mv_weakness_patterns');
    console.log('[analytics-refresh] Done');
  } catch (err) {
    console.error('[analytics-refresh] Refresh failed:', err);
    // TODO: send alert
  } finally {
    client.release();
  }
}

async function startListener(): Promise<void> {
  const client = await pool.connect();
  await client.query('LISTEN submission_scored');

  client.on('notification', (msg) => {
    if (msg.channel !== 'submission_scored') return;
    const payload = JSON.parse(msg.payload ?? '{}');

    // Debounce: batch rapid completions into a single refresh
    if (refreshDebounceTimer) clearTimeout(refreshDebounceTimer);
    refreshDebounceTimer = setTimeout(() => {
      refreshAnalyticsViews(payload.challenge_id).catch(console.error);
    }, 5000); // Wait 5 seconds for burst of completions to settle
  });

  console.log('[analytics-refresh] Listener ready');
}

startListener().catch(console.error);
```

---

## TypeScript Analytics Query Layer

```typescript
// lib/analytics/lane-distribution.ts
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const LaneDistributionSchema = z.object({
  challenge_id: z.string().uuid(),
  lane_key: z.string(),
  sample_count: z.number(),
  mean_score: z.number(),
  stddev_score: z.number().nullable(),
  min_score: z.number(),
  max_score: z.number(),
  p10: z.number(),
  p25: z.number(),
  p50: z.number(),
  p75: z.number(),
  p90: z.number(),
  last_submission_at: z.string().datetime(),
});

export type LaneDistribution = z.infer<typeof LaneDistributionSchema>;

export async function getLaneDistributions(
  challengeId: string
): Promise<LaneDistribution[]> {
  const { data, error } = await supabase
    .from('mv_lane_score_distribution')
    .select('*')
    .eq('challenge_id', challengeId)
    .gte('sample_count', 5); // Don't return distributions with too few samples

  if (error) throw new Error(`Analytics query failed: ${error.message}`);

  return z.array(LaneDistributionSchema).parse(data ?? []);
}

const WeaknessPatternSchema = z.object({
  agent_id: z.string().uuid(),
  challenge_id: z.string().uuid(),
  lane_key: z.string(),
  attempt_count: z.number(),
  avg_score: z.number(),
  min_score: z.number(),
  max_score: z.number(),
  score_trend_slope: z.number().nullable(),
  performance_category: z.enum(['persistent_weakness', 'below_median', 'consistent_strength', 'average']),
  challenge_p25: z.number(),
  challenge_p50: z.number(),
  challenge_p75: z.number(),
});

export type WeaknessPattern = z.infer<typeof WeaknessPatternSchema>;

export async function getAgentWeaknessPatterns(
  agentId: string,
  challengeId?: string
): Promise<WeaknessPattern[]> {
  let query = supabase
    .from('mv_weakness_patterns')
    .select('*')
    .eq('agent_id', agentId)
    .in('performance_category', ['persistent_weakness', 'below_median']);

  if (challengeId) {
    query = query.eq('challenge_id', challengeId);
  }

  const { data, error } = await query.order('avg_score', { ascending: true }).limit(20);
  if (error) throw new Error(`Weakness pattern query failed: ${error.message}`);

  return z.array(WeaknessPatternSchema).parse(data ?? []);
}

const AgentProgressSchema = z.object({
  agent_id: z.string().uuid(),
  challenge_id: z.string().uuid(),
  week: z.string(),
  submission_count: z.number(),
  avg_composite_score: z.number(),
  best_composite_score: z.number(),
  worst_composite_score: z.number(),
  wow_composite_delta: z.number().nullable(),
});

export type AgentProgress = z.infer<typeof AgentProgressSchema>;

export async function getAgentProgressTimeline(
  agentId: string,
  challengeId: string,
  weeks: number = 12
): Promise<AgentProgress[]> {
  const { data, error } = await supabase
    .from('mv_agent_progress')
    .select('*')
    .eq('agent_id', agentId)
    .eq('challenge_id', challengeId)
    .order('week', { ascending: true })
    .limit(weeks);

  if (error) throw new Error(`Progress query failed: ${error.message}`);
  return z.array(AgentProgressSchema).parse(data ?? []);
}
```

---

## Worked Example — Adding a New Analytics View Without Touching Operational Tables

**Business question:** "What's the average time between first submission and first win for agents on each challenge?"

**Step 1: Write the query against operational tables to validate it**

```sql
-- Validate query first (runs against live data; don't use in production API)
WITH first_submissions AS (
  SELECT agent_id, challenge_id, MIN(created_at) AS first_at
  FROM submissions
  WHERE status = 'scored'
  GROUP BY agent_id, challenge_id
),
first_wins AS (
  SELECT s.agent_id, s.challenge_id, MIN(s.created_at) AS first_win_at
  FROM submissions s
  JOIN bout_results br ON s.bout_id = br.bout_id AND s.agent_id = br.winner_agent_id
  WHERE s.status = 'scored'
  GROUP BY s.agent_id, s.challenge_id
)
SELECT
  fs.challenge_id,
  COUNT(*) AS agents_with_win,
  ROUND(AVG(
    EXTRACT(EPOCH FROM fw.first_win_at - fs.first_at) / 86400
  )::NUMERIC, 1) AS avg_days_to_first_win
FROM first_submissions fs
JOIN first_wins fw ON fs.agent_id = fw.agent_id AND fs.challenge_id = fw.challenge_id
GROUP BY fs.challenge_id
HAVING COUNT(*) >= 5;
```

**Step 2: Wrap it in a materialized view**

```sql
CREATE MATERIALIZED VIEW mv_time_to_first_win AS
WITH first_submissions AS (
  SELECT agent_id, challenge_id, MIN(created_at) AS first_at
  FROM submissions WHERE status = 'scored' GROUP BY agent_id, challenge_id
),
first_wins AS (
  SELECT s.agent_id, s.challenge_id, MIN(s.created_at) AS first_win_at
  FROM submissions s
  JOIN bout_results br ON s.bout_id = br.bout_id AND s.agent_id = br.winner_agent_id
  WHERE s.status = 'scored' GROUP BY s.agent_id, s.challenge_id
)
SELECT
  fs.challenge_id,
  COUNT(*) AS agents_with_win,
  ROUND(AVG(EXTRACT(EPOCH FROM fw.first_win_at - fs.first_at) / 86400)::NUMERIC, 1) AS avg_days_to_first_win
FROM first_submissions fs
JOIN first_wins fw ON fs.agent_id = fw.agent_id AND fs.challenge_id = fw.challenge_id
GROUP BY fs.challenge_id
HAVING COUNT(*) >= 5
WITH DATA;

CREATE UNIQUE INDEX idx_mv_ttfw_pk ON mv_time_to_first_win(challenge_id);
```

**Step 3: Add to pg_cron refresh schedule**

```sql
SELECT cron.schedule(
  'refresh-time-to-first-win',
  '0 */4 * * *',  -- Every 4 hours (slow-moving metric)
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY mv_time_to_first_win$$
);
```

**Step 4: Add TypeScript query function (no operational tables touched)**

```typescript
// lib/analytics/time-to-first-win.ts
export async function getTimeToFirstWin(challengeId?: string) {
  const { data, error } = await supabase
    .from('mv_time_to_first_win')
    .select('challenge_id, agents_with_win, avg_days_to_first_win')
    .apply(q => challengeId ? q.eq('challenge_id', challengeId) : q);

  if (error) throw new Error(error.message);
  return data ?? [];
}
```

**Operational tables were never modified.** The entire feature is: 1 materialized view + 1 cron job + 1 TypeScript function.

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Running analytical queries in hot API routes

```typescript
// BAD — percentile computation on 100K submissions runs in every page load
export async function GET(request: NextRequest) {
  const { data } = await supabase.rpc('compute_lane_percentiles', {
    challenge_id: params.challengeId
  }); // This takes 2-8 seconds. Users experience it as a broken page.
  return NextResponse.json(data);
}
```

```typescript
// GOOD — read from materialized view (always < 10ms)
export async function GET(request: NextRequest) {
  const distributions = await getLaneDistributions(params.challengeId);
  return NextResponse.json(distributions); // pre-computed, instant
}
```

---

### ❌ Anti-Pattern 2: Materialized view refresh without CONCURRENTLY

```sql
-- BAD — this locks the view for the duration of the refresh
-- Users get 0 results while the view refreshes (can take 30s+ on large datasets)
REFRESH MATERIALIZED VIEW mv_lane_score_distribution;
```

```sql
-- GOOD — CONCURRENTLY replaces rows atomically; reads continue during refresh
-- REQUIRES a unique index on the view
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_lane_score_distribution;
```

---

### ❌ Anti-Pattern 3: Adding analytical columns to operational tables

```sql
-- BAD — adds aggregate percentile rank to the submissions table
-- Now every INSERT/UPDATE on submissions is slower
-- The percentile rank is stale the moment the next submission comes in
ALTER TABLE submissions
  ADD COLUMN percentile_rank FLOAT,
  ADD COLUMN weakness_category TEXT;
```

```sql
-- GOOD — analytical attributes live in materialized views or analytics tables
-- Operational tables stay fast; analytics tables are refreshed on schedule
-- Read percentile from mv_lane_score_distribution at query time, not stored on submission
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Materialized view refreshed without CONCURRENTLY | Page loads return empty results for up to 30s during refresh | Add unique index then use `REFRESH MATERIALIZED VIEW CONCURRENTLY` |
| pg_cron job silently failing due to permissions | Views go stale for hours; no error surfaced | Query `cron.job_run_details` for error; ensure cron role has EXECUTE on refresh functions |
| Lane distribution groups across all challenges | Percentile "top 10%" mixes easy and hard challenges | Add `WHERE challenge_id = $1` and `GROUP BY challenge_id, lane_key` in view definition |
| Analytics query reads directly from `judge_outputs` in hot path | 500ms query on page load → timeout under load | Route all analytics reads through materialized views |
| `pg_notify` refresh listener not reconnecting on disconnect | Long idle periods cause listener to disconnect; events missed; views go stale | Add reconnection logic with exponential backoff in the worker |
| Backfill script not idempotent | Running backfill twice creates duplicate weakness pattern rows | Add `ON CONFLICT (agent_id, challenge_id, lane_key) DO UPDATE` to backfill inserts |
| `LATERAL jsonb_each` on NULL `final_lane_scores` | Materialized view refresh fails with null pointer error | Add `WHERE s.final_lane_scores IS NOT NULL` before lateral join |
| No sample count guard on materialized view queries | API returns percentile data for challenge with 1 submission | Filter `WHERE sample_count >= 5` when querying from `mv_lane_score_distribution` |
| Week truncation in `mv_agent_progress` uses server timezone | Monday-based weeks shift based on server timezone; inconsistent historical data | Use `DATE_TRUNC('week', s.created_at AT TIME ZONE 'UTC')` explicitly |
| `REGR_SLOPE` called on single-point groups | Returns NULL for agents with 1 submission; downstream divides by NULL | HAVING clause `COUNT(*) >= 2` in weakness pattern view before slope computation |

---

## Changelog
- 2026-03-31: Created for Bouts evaluation analytics pipeline build
