---
name: admin-evaluation-tooling
description: Internal admin tools for inspecting, monitoring, and improving judge outputs — including raw output inspection, calibration drift detection, missing evidence detection, low-signal output flagging, and a feedback quality dashboard.
---

# Admin Evaluation Tooling

## Review Checklist

- [ ] Judge output inspector loads raw LLM response JSON for any submission_id without requiring page reload — verify via `/api/admin/judge-outputs?submission_id=X`
- [ ] Calibration drift query uses a rolling window (default 7 days) and computes per-judge Z-score deviation from 30-day baseline — not just a raw average comparison
- [ ] Missing evidence query returns submission IDs where `evidence_refs` array length = 0 AND score is non-null — confirm NULL scores are excluded (those are incomplete evaluations, not zero-evidence ones)
- [ ] Low-signal detection uses specificity_score < 0.4 threshold AND feedback_word_count < 50 — both conditions, not either
- [ ] Feedback quality dashboard aggregates by judge_id AND challenge_id to surface per-challenge quality regressions, not just global averages
- [ ] All admin routes are protected by `role = 'admin'` RLS policy AND middleware session check — test with non-admin JWT to confirm 403
- [ ] Calibration drift alert fires within 15 minutes of drift exceeding threshold — verify pg_cron or webhook trigger is active
- [ ] Judge output diff view normalizes score fields before comparison (e.g. 0-10 vs 0-100) — confirm scale normalization is applied
- [ ] Dashboard TSX components handle empty states (no submissions yet, no drift detected) without crashing — test with empty arrays
- [ ] All SQL queries for detection cases are indexed — confirm `EXPLAIN ANALYZE` shows index scans not seq scans on large tables
- [ ] Admin API routes paginate results (default limit 50) — unbounded queries on `judge_outputs` will OOM on large datasets
- [ ] Drift alert stores last-alerted timestamp to prevent alert storm on persistent drift — check deduplication logic

---

## Judge Output Inspector — Raw LLM Output Retrieval and Cross-Judge Diff

The inspector is the ground truth view for debugging judge behavior. It loads the raw LLM response (before any parsing or normalization), the parsed structured output, and enables side-by-side comparison across judges for the same submission.

**Schema: `judge_outputs` table**

```sql
CREATE TABLE judge_outputs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  judge_id TEXT NOT NULL, -- 'claude-3-5-sonnet', 'gpt-4o', 'gemini-1.5-pro'
  raw_response JSONB NOT NULL, -- full LLM API response, unmodified
  parsed_output JSONB, -- structured extraction result
  lane_scores JSONB, -- { "planning": 7.5, "execution": 8.0, ... }
  evidence_refs JSONB DEFAULT '[]'::jsonb, -- array of evidence objects
  feedback_text TEXT,
  specificity_score FLOAT, -- 0.0 - 1.0, computed at write time
  confidence_scores JSONB, -- { "planning": "high", "execution": "medium" }
  tokens_used INTEGER,
  latency_ms INTEGER,
  error TEXT, -- null if successful
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_judge_outputs_submission_id ON judge_outputs(submission_id);
CREATE INDEX idx_judge_outputs_judge_id_created ON judge_outputs(judge_id, created_at);
CREATE INDEX idx_judge_outputs_created_at ON judge_outputs(created_at DESC);
```

**API Route: `/app/api/admin/judge-outputs/route.ts`**

```typescript
import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const QuerySchema = z.object({
  submission_id: z.string().uuid().optional(),
  judge_id: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
  include_raw: z.coerce.boolean().default(false),
});

export async function GET(request: NextRequest) {
  const supabase = createRouteHandlerClient({ cookies });

  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', session.user.id)
    .single();

  if (profile?.role !== 'admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const params = QuerySchema.safeParse(Object.fromEntries(request.nextUrl.searchParams));
  if (!params.success) {
    return NextResponse.json({ error: params.error.flatten() }, { status: 400 });
  }

  const { submission_id, judge_id, limit, offset, include_raw } = params.data;

  let query = supabase
    .from('judge_outputs')
    .select(include_raw
      ? `id, submission_id, judge_id, raw_response, parsed_output, lane_scores, evidence_refs, feedback_text, specificity_score, confidence_scores, tokens_used, latency_ms, error, created_at`
      : `id, submission_id, judge_id, parsed_output, lane_scores, evidence_refs, feedback_text, specificity_score, confidence_scores, tokens_used, latency_ms, error, created_at`
    )
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (submission_id) query = query.eq('submission_id', submission_id);
  if (judge_id) query = query.eq('judge_id', judge_id);

  const { data, error, count } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({ outputs: data, total: count, limit, offset });
}
```

**Cross-Judge Diff Query**

```sql
-- Compare lane scores across all judges for a single submission
SELECT
  jo.judge_id,
  jo.lane_scores,
  jo.specificity_score,
  jsonb_array_length(jo.evidence_refs) AS evidence_count,
  jo.tokens_used,
  jo.latency_ms,
  jo.error IS NOT NULL AS has_error,
  -- Compute per-lane deviation from mean across judges
  (
    SELECT jsonb_object_agg(
      lane_key,
      ROUND(
        (lane_score::FLOAT - AVG(lane_score::FLOAT) OVER ())::NUMERIC,
        2
      )
    )
    FROM (
      SELECT key AS lane_key, value::TEXT AS lane_score
      FROM jsonb_each(jo.lane_scores)
    ) sub
  ) AS score_deviation_from_mean
FROM judge_outputs jo
WHERE jo.submission_id = $1
  AND jo.error IS NULL
ORDER BY jo.judge_id;
```

---

## Calibration Drift Detection — Rolling Window Z-Score Alerting

Calibration drift means a judge's average scores are systematically drifting away from its own historical baseline. This isn't about absolute score levels — it's about detecting when a judge that historically scored 7.2 average is now scoring 8.9 average without a corresponding change in submission quality.

**Detection Query: Per-Judge Rolling Baseline vs. Recent Window**

```sql
-- Detect calibration drift: judge scores in last 24h vs 30-day baseline
WITH baseline AS (
  SELECT
    judge_id,
    AVG((value::TEXT)::FLOAT) AS baseline_avg,
    STDDEV((value::TEXT)::FLOAT) AS baseline_stddev,
    COUNT(*) AS baseline_sample_count
  FROM judge_outputs jo,
    LATERAL jsonb_each(jo.lane_scores)
  WHERE jo.created_at >= NOW() - INTERVAL '30 days'
    AND jo.created_at < NOW() - INTERVAL '1 day'
    AND jo.error IS NULL
  GROUP BY judge_id
),
recent AS (
  SELECT
    judge_id,
    AVG((value::TEXT)::FLOAT) AS recent_avg,
    COUNT(*) AS recent_sample_count
  FROM judge_outputs jo,
    LATERAL jsonb_each(jo.lane_scores)
  WHERE jo.created_at >= NOW() - INTERVAL '1 day'
    AND jo.error IS NULL
  GROUP BY judge_id
)
SELECT
  r.judge_id,
  b.baseline_avg,
  b.baseline_stddev,
  r.recent_avg,
  r.recent_sample_count,
  b.baseline_sample_count,
  -- Z-score: how many standard deviations has the mean shifted?
  CASE
    WHEN b.baseline_stddev > 0
    THEN (r.recent_avg - b.baseline_avg) / b.baseline_stddev
    ELSE 0
  END AS z_score,
  -- Flag if shift > 1.5 stddev AND we have enough samples
  CASE
    WHEN b.baseline_stddev > 0
      AND ABS((r.recent_avg - b.baseline_avg) / b.baseline_stddev) > 1.5
      AND r.recent_sample_count >= 10
    THEN TRUE
    ELSE FALSE
  END AS drift_flagged
FROM recent r
JOIN baseline b ON r.judge_id = b.judge_id
ORDER BY ABS(
  CASE WHEN b.baseline_stddev > 0
    THEN (r.recent_avg - b.baseline_avg) / b.baseline_stddev
    ELSE 0
  END
) DESC;
```

**Drift Alert Table and Deduplication**

```sql
CREATE TABLE calibration_drift_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_id TEXT NOT NULL,
  z_score FLOAT NOT NULL,
  baseline_avg FLOAT NOT NULL,
  recent_avg FLOAT NOT NULL,
  recent_sample_count INTEGER NOT NULL,
  alerted_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  notes TEXT
);

CREATE INDEX idx_drift_alerts_judge_unresolved
  ON calibration_drift_alerts(judge_id)
  WHERE resolved_at IS NULL;
```

**TypeScript Drift Checker (runs via cron or webhook)**

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

interface DriftResult {
  judge_id: string;
  baseline_avg: number;
  baseline_stddev: number;
  recent_avg: number;
  recent_sample_count: number;
  baseline_sample_count: number;
  z_score: number;
  drift_flagged: boolean;
}

export async function checkCalibrationDrift(): Promise<void> {
  const { data: driftResults, error } = await supabase.rpc('detect_calibration_drift');
  if (error) {
    console.error('[calibration-drift] RPC error:', error.message);
    return;
  }

  const flagged = (driftResults as DriftResult[]).filter(r => r.drift_flagged);

  for (const result of flagged) {
    // Check if we already have an unresolved alert for this judge
    const { data: existing } = await supabase
      .from('calibration_drift_alerts')
      .select('id, alerted_at')
      .eq('judge_id', result.judge_id)
      .is('resolved_at', null)
      .order('alerted_at', { ascending: false })
      .limit(1)
      .single();

    if (existing) {
      const hoursSinceLastAlert =
        (Date.now() - new Date(existing.alerted_at).getTime()) / 3600000;
      // Re-alert only if > 4 hours since last alert (prevent storm)
      if (hoursSinceLastAlert < 4) continue;
    }

    await supabase.from('calibration_drift_alerts').insert({
      judge_id: result.judge_id,
      z_score: result.z_score,
      baseline_avg: result.baseline_avg,
      recent_avg: result.recent_avg,
      recent_sample_count: result.recent_sample_count,
    });

    console.warn(
      `[calibration-drift] ALERT: ${result.judge_id} drifted ${result.z_score.toFixed(2)} stddev ` +
      `(baseline: ${result.baseline_avg.toFixed(2)}, recent: ${result.recent_avg.toFixed(2)})`
    );

    // TODO: send to Slack/webhook here
  }
}
```

---

## Missing Evidence & Low-Signal Detection — SQL Queries and Admin Dashboard

**Missing Evidence Detection**

```sql
-- Submissions where judge returned a score but zero evidence refs
SELECT
  jo.submission_id,
  jo.judge_id,
  jo.lane_scores,
  jsonb_array_length(jo.evidence_refs) AS evidence_count,
  jo.created_at,
  s.challenge_id,
  s.agent_id
FROM judge_outputs jo
JOIN submissions s ON jo.submission_id = s.id
WHERE jo.error IS NULL
  AND jo.lane_scores IS NOT NULL
  AND jsonb_array_length(jo.evidence_refs) = 0
ORDER BY jo.created_at DESC
LIMIT 100;
```

**Low-Signal Detection (specificity below threshold)**

```sql
-- Feedback text that is too vague: low specificity score AND short word count
SELECT
  jo.submission_id,
  jo.judge_id,
  jo.specificity_score,
  LENGTH(jo.feedback_text) - LENGTH(REPLACE(jo.feedback_text, ' ', '')) + 1 AS word_count,
  SUBSTRING(jo.feedback_text, 1, 200) AS feedback_preview,
  jo.created_at
FROM judge_outputs jo
WHERE jo.error IS NULL
  AND jo.specificity_score < 0.4
  AND LENGTH(jo.feedback_text) - LENGTH(REPLACE(jo.feedback_text, ' ', '')) + 1 < 50
ORDER BY jo.specificity_score ASC, jo.created_at DESC
LIMIT 100;
```

**Feedback Quality Dashboard API**

```typescript
// /app/api/admin/feedback-quality/route.ts
import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

export async function GET() {
  const supabase = createRouteHandlerClient({ cookies });

  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: profile } = await supabase
    .from('profiles').select('role').eq('id', session.user.id).single();
  if (profile?.role !== 'admin') return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  // Aggregate metrics by judge_id
  const { data: metrics, error } = await supabase.rpc('feedback_quality_metrics');
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({ metrics });
}
```

**Postgres Function for Quality Metrics**

```sql
CREATE OR REPLACE FUNCTION feedback_quality_metrics()
RETURNS TABLE (
  judge_id TEXT,
  total_outputs BIGINT,
  avg_evidence_refs FLOAT,
  pct_zero_evidence FLOAT,
  avg_specificity_score FLOAT,
  pct_low_signal FLOAT,
  avg_tokens_used FLOAT,
  avg_latency_ms FLOAT,
  pct_errors FLOAT
) LANGUAGE sql STABLE AS $$
  SELECT
    jo.judge_id,
    COUNT(*) AS total_outputs,
    AVG(jsonb_array_length(jo.evidence_refs))::FLOAT AS avg_evidence_refs,
    (COUNT(*) FILTER (WHERE jsonb_array_length(jo.evidence_refs) = 0)::FLOAT / COUNT(*)) * 100 AS pct_zero_evidence,
    AVG(jo.specificity_score) AS avg_specificity_score,
    (COUNT(*) FILTER (
      WHERE jo.specificity_score < 0.4
        AND LENGTH(jo.feedback_text) - LENGTH(REPLACE(jo.feedback_text, ' ', '')) + 1 < 50
    )::FLOAT / NULLIF(COUNT(*) FILTER (WHERE jo.error IS NULL), 0)) * 100 AS pct_low_signal,
    AVG(jo.tokens_used) AS avg_tokens_used,
    AVG(jo.latency_ms) AS avg_latency_ms,
    (COUNT(*) FILTER (WHERE jo.error IS NOT NULL)::FLOAT / COUNT(*)) * 100 AS pct_errors
  FROM judge_outputs jo
  WHERE jo.created_at >= NOW() - INTERVAL '7 days'
  GROUP BY jo.judge_id
  ORDER BY total_outputs DESC;
$$;
```

**TSX Admin Dashboard Component**

```tsx
// components/admin/FeedbackQualityDashboard.tsx
'use client';

import { useEffect, useState } from 'react';
import { cn } from '@/lib/utils';

interface JudgeMetrics {
  judge_id: string;
  total_outputs: number;
  avg_evidence_refs: number;
  pct_zero_evidence: number;
  avg_specificity_score: number;
  pct_low_signal: number;
  avg_tokens_used: number;
  avg_latency_ms: number;
  pct_errors: number;
}

function MetricBadge({ value, threshold, label, format = 'number' }: {
  value: number;
  threshold: { warn: number; bad: number };
  label: string;
  format?: 'number' | 'percent' | 'ms';
}) {
  const isWarn = value >= threshold.warn && value < threshold.bad;
  const isBad = value >= threshold.bad;
  const formatted = format === 'percent' ? `${value.toFixed(1)}%`
    : format === 'ms' ? `${Math.round(value)}ms`
    : value.toFixed(2);

  return (
    <div className={cn(
      'px-2 py-1 rounded text-xs font-mono',
      isBad ? 'bg-red-100 text-red-800 border border-red-300'
        : isWarn ? 'bg-yellow-100 text-yellow-800 border border-yellow-300'
        : 'bg-green-50 text-green-800 border border-green-200'
    )}>
      <span className="font-semibold">{formatted}</span>
      <span className="text-gray-500 ml-1">{label}</span>
    </div>
  );
}

export function FeedbackQualityDashboard() {
  const [metrics, setMetrics] = useState<JudgeMetrics[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch('/api/admin/feedback-quality')
      .then(r => r.json())
      .then(d => {
        if (d.error) throw new Error(d.error);
        setMetrics(d.metrics ?? []);
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="text-gray-400 text-sm">Loading judge metrics...</div>;
  if (error) return <div className="text-red-500 text-sm">Error: {error}</div>;
  if (metrics.length === 0) return <div className="text-gray-400 text-sm">No judge outputs in last 7 days.</div>;

  return (
    <div className="space-y-4">
      <h2 className="text-lg font-semibold text-gray-900">Feedback Quality — Last 7 Days</h2>
      <div className="overflow-x-auto">
        <table className="min-w-full text-sm border border-gray-200 rounded-lg overflow-hidden">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Judge</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Outputs</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Avg Evidence</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Zero Evidence</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Specificity</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Low Signal</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Avg Tokens</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Avg Latency</th>
              <th className="px-4 py-2 text-left font-medium text-gray-600">Error Rate</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {metrics.map(m => (
              <tr key={m.judge_id} className="hover:bg-gray-50">
                <td className="px-4 py-2 font-mono font-semibold text-gray-800">{m.judge_id}</td>
                <td className="px-4 py-2 text-gray-700">{m.total_outputs.toLocaleString()}</td>
                <td className="px-4 py-2">
                  <MetricBadge value={m.avg_evidence_refs} threshold={{ warn: 1, bad: 0.5 }} label="refs" />
                </td>
                <td className="px-4 py-2">
                  <MetricBadge value={m.pct_zero_evidence} threshold={{ warn: 10, bad: 25 }} label="%" format="percent" />
                </td>
                <td className="px-4 py-2">
                  <MetricBadge
                    value={1 - m.avg_specificity_score}
                    threshold={{ warn: 0.4, bad: 0.6 }}
                    label="gap"
                  />
                </td>
                <td className="px-4 py-2">
                  <MetricBadge value={m.pct_low_signal} threshold={{ warn: 10, bad: 20 }} label="%" format="percent" />
                </td>
                <td className="px-4 py-2 font-mono text-gray-600">{Math.round(m.avg_tokens_used).toLocaleString()}</td>
                <td className="px-4 py-2">
                  <MetricBadge value={m.avg_latency_ms} threshold={{ warn: 8000, bad: 15000 }} label="" format="ms" />
                </td>
                <td className="px-4 py-2">
                  <MetricBadge value={m.pct_errors} threshold={{ warn: 2, bad: 10 }} label="%" format="percent" />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Querying raw_response on every dashboard load

```typescript
// BAD — pulls megabytes of JSON for every row on every render
const { data } = await supabase
  .from('judge_outputs')
  .select('*') // includes raw_response which can be 50KB+
  .order('created_at', { ascending: false })
  .limit(100);
```

```typescript
// GOOD — raw_response only requested explicitly when needed
const { data } = await supabase
  .from('judge_outputs')
  .select('id, submission_id, judge_id, lane_scores, evidence_refs, specificity_score, created_at')
  .order('created_at', { ascending: false })
  .limit(50);
// raw_response fetched separately only when user clicks "View Raw"
```

---

### ❌ Anti-Pattern 2: Drift detection using simple average comparison

```sql
-- BAD — doesn't account for natural score variance; flags normal fluctuation
SELECT judge_id,
  AVG(score) AS recent_avg,
  (SELECT AVG(score) FROM scores WHERE created_at < NOW() - INTERVAL '1 day') AS baseline_avg
FROM scores WHERE created_at >= NOW() - INTERVAL '1 day'
GROUP BY judge_id
HAVING ABS(AVG(score) - (SELECT AVG(score) FROM scores WHERE created_at < NOW() - INTERVAL '1 day')) > 0.5;
```

```sql
-- GOOD — uses Z-score so threshold is calibrated to the judge's own variance
-- See full query in Calibration Drift Detection section above
-- Z-score > 1.5 means the shift is 1.5 standard deviations, not an arbitrary 0.5 point gap
```

---

### ❌ Anti-Pattern 3: No deduplication on drift alerts

```typescript
// BAD — fires a new alert on every cron tick while drift persists
if (result.drift_flagged) {
  await supabase.from('alerts').insert({ judge_id: result.judge_id, z_score: result.z_score });
  await sendSlackAlert(result); // Slack gets 96 messages in 8 hours
}
```

```typescript
// GOOD — check for unresolved alert within last 4 hours before inserting
const { data: existing } = await supabase
  .from('calibration_drift_alerts')
  .select('id, alerted_at')
  .eq('judge_id', result.judge_id)
  .is('resolved_at', null)
  .gte('alerted_at', new Date(Date.now() - 4 * 3600000).toISOString())
  .limit(1);
if (!existing || existing.length === 0) {
  await supabase.from('calibration_drift_alerts').insert({ ... });
}
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Admin route missing middleware role check | Non-admins can access judge outputs by knowing the URL | Add `profile?.role !== 'admin'` check in every admin route handler |
| Drift query uses `INTERVAL '1 day'` as both recent window and baseline cutoff | The same submission counted in both windows — double-counted | Use `created_at < NOW() - INTERVAL '1 day'` for baseline upper bound |
| `jsonb_array_length` called on NULL evidence_refs | Postgres throws error when evidence_refs is NULL instead of `[]` | Use `COALESCE(evidence_refs, '[]'::jsonb)` in all queries |
| Low-signal detection uses OR instead of AND | Flags submissions with short text OR low specificity — too noisy | Both conditions must be true: `specificity_score < 0.4 AND word_count < 50` |
| Dashboard shows % zero evidence as ratio (0.25) not percentage (25%) | 25% displays as 0.25% — makes platform look healthier than it is | Multiply by 100 in SQL or in rendering layer, not both |
| Missing index on `judge_outputs(created_at)` | Drift detection does full table scan — 30-second query on 1M rows | `CREATE INDEX idx_judge_outputs_created_at ON judge_outputs(created_at DESC)` |
| Raw response stored as TEXT instead of JSONB | Can't query into raw_response fields; no compression | Migrate to JSONB: `ALTER TABLE judge_outputs ALTER COLUMN raw_response TYPE JSONB USING raw_response::jsonb` |
| Calibration drift alert table missing partial index on unresolved | Deduplication query scans entire alert table | `CREATE INDEX idx_drift_alerts_unresolved ON calibration_drift_alerts(judge_id) WHERE resolved_at IS NULL` |
| Drift baseline uses ALL historical data including early bad data | Old bad data pulls baseline down; new good data looks like upward drift | Cap baseline lookback: `created_at >= NOW() - INTERVAL '90 days' AND created_at < NOW() - INTERVAL '1 day'` |
| Judge output inspector loads without pagination | 50,000 outputs loaded on first render; browser OOM | Always paginate: `range(offset, offset + limit - 1)` with explicit limit |

---

## Changelog
- 2026-03-31: Created for Bouts admin evaluation tooling build
