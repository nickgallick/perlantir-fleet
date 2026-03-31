---
name: longitudinal-competitor-coaching-surfaces
description: Surface structured coaching insights across multiple bouts for the same competitor — repeated failures, recurring strengths, trendline improvement, and same-lane persistence — grounded in real data with suppression rules that prevent surfacing patterns too early.
---

# Longitudinal Competitor Coaching Surfaces

## Review Checklist

- [ ] All longitudinal insights have a minimum bout threshold of 3 (not 1 or 2) before any pattern is surfaced — check every query for `HAVING COUNT(*) >= 3`
- [ ] "Persistent pattern" requires failure code appearing in >= 40% of eligible submissions AND N >= 5 occurrences — both conditions required; confirm both guards in TypeScript aggregator
- [ ] Recurring strength detection requires lane score in top 25th percentile for the challenge AND appearing in >= 3 bouts — single-bout outlier performance must not surface as "strength"
- [ ] Trendline computation uses `REGR_SLOPE` (linear regression) not just first-vs-last comparison — first/last comparison is extremely sensitive to single-bout outliers
- [ ] Same-lane persistence threshold is >= 3 consecutive bouts in the weak category before surfacing the pattern — 2 bouts with a gap in between must not trigger persistence alert
- [ ] "Consecutive" bouts are ordered by `created_at`, not by `bout_id` or `submission_id` — these may not be sequential
- [ ] Coaching surface component shows N (number of bouts that informed this insight) in small text — users must be able to trust or question the pattern
- [ ] Suppression rules are applied at the data layer (in TypeScript aggregator), not the UI layer — suppressed insights must never reach the component as null-rendered data
- [ ] Trendline is shown only as direction (improving/plateauing/regressing) + magnitude category (slightly/significantly) — never show raw regression coefficient to users
- [ ] Pattern data is keyed to `(agent_id, challenge_id)` — patterns across different challenges must never be merged into one "this agent always fails at X" insight
- [ ] Longitudinal insights have a staleness TTL — if an agent hasn't competed for 30+ days, their longitudinal data is marked stale and insights are suppressed until they return
- [ ] When multiple patterns are detected (persistent weakness in Planning AND Execution), they are ranked by impact score (counterfactual rank improvement) — most impactful shown first

---

## Minimum Bout Threshold Architecture — The Suppression Foundation

Longitudinal patterns need sufficient data before they're meaningful. The hard minimums:

| Insight Type | Min Bouts | Additional Requirement |
|---|---|---|
| Any longitudinal insight shown | 3 | On same challenge |
| "Persistent failure pattern" | 5 | Failure appears in >= 40% of bouts |
| "Recurring strength" | 3 | Lane in top 25th percentile in each of those bouts |
| Trendline direction | 4 | Regression R² >= 0.3 (not random noise) |
| "Same-lane weakness persisting" | 3 consecutive | No improvement since first flag |
| "You're improving" insight | 4 | Slope positive AND last 2 bouts above median |

These thresholds live in a shared config:

```typescript
// lib/longitudinal-config.ts
export const LONGITUDINAL_THRESHOLDS = {
  // Minimum bouts before ANY longitudinal insight is shown
  MIN_BOUTS_FOR_ANY_INSIGHT: 3,
  // Minimum bouts before failure pattern is surfaced
  MIN_BOUTS_FOR_FAILURE_PATTERN: 5,
  // Failure code must appear in this fraction of bouts to be "persistent"
  FAILURE_PATTERN_RATE_THRESHOLD: 0.40,
  // Minimum occurrences of a failure code (even at 100% rate, 2/2 bouts is not meaningful)
  MIN_FAILURE_OCCURRENCES: 3,
  // Minimum bouts for recurring strength detection
  MIN_BOUTS_FOR_STRENGTH: 3,
  // Lane must be in top percentile to count as strength
  STRENGTH_PERCENTILE_THRESHOLD: 75,
  // Minimum bouts for trendline computation
  MIN_BOUTS_FOR_TRENDLINE: 4,
  // Minimum R² for trendline to be shown (not noise)
  MIN_TRENDLINE_R_SQUARED: 0.30,
  // Minimum consecutive bouts below threshold for persistence warning
  MIN_CONSECUTIVE_BOUTS_FOR_PERSISTENCE: 3,
  // Days since last bout before longitudinal data is considered stale
  STALENESS_DAYS: 30,
} as const;
```

---

## SQL Queries — Longitudinal Pattern Detection

**Per-agent lane history (foundation for all longitudinal queries)**

```sql
-- Foundation query: agent's lane scores in chronological order per challenge
SELECT
  s.agent_id,
  s.challenge_id,
  s.id AS submission_id,
  s.created_at,
  -- Row number within this agent-challenge pair, chronological
  ROW_NUMBER() OVER (
    PARTITION BY s.agent_id, s.challenge_id
    ORDER BY s.created_at ASC
  ) AS bout_seq,
  lane_key,
  (lane_value::TEXT)::FLOAT AS lane_score,
  s.composite_score
FROM submissions s,
  LATERAL jsonb_each(s.final_lane_scores) AS ls(lane_key, lane_value)
WHERE s.status = 'scored'
  AND s.final_lane_scores IS NOT NULL
ORDER BY s.agent_id, s.challenge_id, s.created_at;
```

**Repeated failure detection query**

```sql
-- Find failure codes that persistently appear for an agent across bouts
WITH agent_bout_count AS (
  SELECT
    agent_id,
    challenge_id,
    COUNT(DISTINCT submission_id) AS total_bouts,
    MAX(created_at) AS last_bout_at
  FROM submissions
  WHERE status = 'scored'
    AND agent_id = $1
    AND challenge_id = $2
  GROUP BY agent_id, challenge_id
  HAVING COUNT(DISTINCT submission_id) >= 5  -- Minimum for failure pattern
),
failure_frequencies AS (
  SELECT
    sfc.failure_code_id,
    fc.failure_code,
    fc.display_name,
    COUNT(DISTINCT s.id) AS bouts_with_failure,
    COUNT(*) AS total_occurrences
  FROM submissions s
  JOIN submission_failure_codes sfc ON s.id = sfc.submission_id
  JOIN failure_codes fc ON sfc.failure_code_id = fc.id
  WHERE s.agent_id = $1
    AND s.challenge_id = $2
    AND s.status = 'scored'
  GROUP BY sfc.failure_code_id, fc.failure_code, fc.display_name
)
SELECT
  ff.failure_code,
  ff.display_name,
  ff.bouts_with_failure,
  ff.total_occurrences,
  abc.total_bouts,
  ROUND(ff.bouts_with_failure::FLOAT / abc.total_bouts * 100, 1) AS occurrence_rate_pct,
  -- Only surface if both rate AND minimum occurrences thresholds are met
  (ff.bouts_with_failure::FLOAT / abc.total_bouts >= 0.40
   AND ff.total_occurrences >= 3) AS is_persistent_pattern,
  abc.last_bout_at
FROM failure_frequencies ff
CROSS JOIN agent_bout_count abc
WHERE ff.bouts_with_failure >= 2  -- Don't surface single-occurrence failures
ORDER BY occurrence_rate_pct DESC;
```

**Trendline computation per lane**

```sql
-- Compute regression slope for each lane over the agent's bout history
WITH lane_history AS (
  SELECT
    s.agent_id,
    s.challenge_id,
    lane_key,
    (lane_value::TEXT)::FLOAT AS lane_score,
    EXTRACT(EPOCH FROM s.created_at) AS epoch_time,
    ROW_NUMBER() OVER (
      PARTITION BY s.agent_id, s.challenge_id, lane_key
      ORDER BY s.created_at
    ) AS seq_num
  FROM submissions s,
    LATERAL jsonb_each(s.final_lane_scores) AS ls(lane_key, lane_value)
  WHERE s.agent_id = $1
    AND s.challenge_id = $2
    AND s.status = 'scored'
)
SELECT
  lane_key,
  COUNT(*) AS data_points,
  ROUND(AVG(lane_score)::NUMERIC, 3) AS mean_score,
  ROUND(REGR_SLOPE(lane_score, seq_num)::NUMERIC, 4) AS slope_per_bout,
  ROUND(REGR_R2(lane_score, seq_num)::NUMERIC, 3) AS r_squared,
  -- Direction classification (only meaningful when r² is sufficient)
  CASE
    WHEN REGR_R2(lane_score, seq_num) < 0.30 THEN 'insufficient_signal'
    WHEN REGR_SLOPE(lane_score, seq_num) > 0.3 THEN 'improving_significantly'
    WHEN REGR_SLOPE(lane_score, seq_num) > 0.1 THEN 'improving_slightly'
    WHEN REGR_SLOPE(lane_score, seq_num) < -0.3 THEN 'regressing_significantly'
    WHEN REGR_SLOPE(lane_score, seq_num) < -0.1 THEN 'regressing_slightly'
    ELSE 'plateauing'
  END AS trend_direction
FROM lane_history
GROUP BY lane_key
HAVING COUNT(*) >= 4  -- Minimum for trendline
ORDER BY ABS(REGR_SLOPE(lane_score, seq_num)) DESC NULLS LAST;
```

**Same-lane consecutive weakness persistence**

```sql
-- Detect lanes where agent has been below challenge p25 for N consecutive bouts
WITH agent_lane_bouts AS (
  SELECT
    s.agent_id,
    s.challenge_id,
    s.id AS submission_id,
    s.created_at,
    lane_key,
    (lane_value::TEXT)::FLOAT AS lane_score,
    ROW_NUMBER() OVER (
      PARTITION BY s.agent_id, s.challenge_id, lane_key
      ORDER BY s.created_at ASC
    ) AS bout_seq
  FROM submissions s,
    LATERAL jsonb_each(s.final_lane_scores) AS ls(lane_key, lane_value)
  WHERE s.agent_id = $1
    AND s.challenge_id = $2
    AND s.status = 'scored'
),
with_percentile AS (
  SELECT
    alb.*,
    dist.p25,
    dist.p50,
    (alb.lane_score < dist.p25) AS is_weak
  FROM agent_lane_bouts alb
  JOIN mv_lane_score_distribution dist
    ON alb.challenge_id = dist.challenge_id AND alb.lane_key = dist.lane_key
),
-- Detect consecutive streaks of weakness using gap-and-island technique
streaks AS (
  SELECT
    *,
    bout_seq - ROW_NUMBER() OVER (
      PARTITION BY agent_id, challenge_id, lane_key, is_weak
      ORDER BY bout_seq
    ) AS streak_group
  FROM with_percentile
)
SELECT
  lane_key,
  COUNT(*) AS consecutive_weak_bouts,
  MIN(created_at) AS streak_started_at,
  MAX(created_at) AS most_recent_weak_bout,
  ROUND(AVG(lane_score)::NUMERIC, 3) AS avg_score_during_streak,
  ROUND(AVG(p25)::NUMERIC, 3) AS challenge_p25
FROM streaks
WHERE is_weak = true
GROUP BY lane_key, streak_group, agent_id, challenge_id
HAVING COUNT(*) >= 3  -- Only surface streaks of 3+ consecutive weak bouts
ORDER BY consecutive_weak_bouts DESC;
```

---

## TypeScript Pattern Aggregator

```typescript
// lib/longitudinal/pattern-aggregator.ts
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';
import { LONGITUDINAL_THRESHOLDS } from './longitudinal-config';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export type TrendDirection =
  | 'improving_significantly'
  | 'improving_slightly'
  | 'plateauing'
  | 'regressing_slightly'
  | 'regressing_significantly'
  | 'insufficient_signal';

export interface PersistentFailurePattern {
  failureCode: string;
  displayName: string;
  boutsWithFailure: number;
  totalBouts: number;
  occurrenceRatePct: number;
  isPersistent: true;
}

export interface RecurringStrength {
  lane: string;
  averageScore: number;
  boutsAboveThreshold: number;
  totalBouts: number;
}

export interface LaneTrendline {
  lane: string;
  dataPoints: number;
  meanScore: number;
  slopePerBout: number;
  rSquared: number;
  direction: TrendDirection;
}

export interface SameLanePersistence {
  lane: string;
  consecutiveWeakBouts: number;
  streakStartedAt: string;
  avgScoreDuringStreak: number;
  challengeP25: number;
}

export interface LongitudinalCoachingInsights {
  agentId: string;
  challengeId: string;
  totalBouts: number;
  isEligibleForInsights: boolean;
  suppressionReason: string | null;
  persistentFailures: PersistentFailurePattern[];
  recurringStrengths: RecurringStrength[];
  trendlines: LaneTrendline[];
  persistentWeaknesses: SameLanePersistence[];
  computedAt: string;
}

export async function computeLongitudinalInsights(
  agentId: string,
  challengeId: string
): Promise<LongitudinalCoachingInsights> {
  const base: LongitudinalCoachingInsights = {
    agentId,
    challengeId,
    totalBouts: 0,
    isEligibleForInsights: false,
    suppressionReason: null,
    persistentFailures: [],
    recurringStrengths: [],
    trendlines: [],
    persistentWeaknesses: [],
    computedAt: new Date().toISOString(),
  };

  // Step 1: Check total bout count and staleness
  const { data: boutCount } = await supabase
    .from('submissions')
    .select('id, created_at', { count: 'exact' })
    .eq('agent_id', agentId)
    .eq('challenge_id', challengeId)
    .eq('status', 'scored')
    .order('created_at', { ascending: false });

  const totalBouts = boutCount?.length ?? 0;
  base.totalBouts = totalBouts;

  if (totalBouts < LONGITUDINAL_THRESHOLDS.MIN_BOUTS_FOR_ANY_INSIGHT) {
    return {
      ...base,
      suppressionReason: `Only ${totalBouts} completed bout${totalBouts === 1 ? '' : 's'} — need ${LONGITUDINAL_THRESHOLDS.MIN_BOUTS_FOR_ANY_INSIGHT} before patterns are meaningful`,
    };
  }

  // Check staleness
  const mostRecentBout = boutCount?.[0];
  if (mostRecentBout) {
    const daysSinceLastBout =
      (Date.now() - new Date(mostRecentBout.created_at).getTime()) / (1000 * 86400);
    if (daysSinceLastBout > LONGITUDINAL_THRESHOLDS.STALENESS_DAYS) {
      return {
        ...base,
        suppressionReason: `Last bout was ${Math.round(daysSinceLastBout)} days ago — patterns may be outdated`,
      };
    }
  }

  base.isEligibleForInsights = true;

  // Step 2: Fetch failure patterns
  if (totalBouts >= LONGITUDINAL_THRESHOLDS.MIN_BOUTS_FOR_FAILURE_PATTERN) {
    const { data: failures } = await supabase.rpc('get_agent_failure_patterns', {
      p_agent_id: agentId,
      p_challenge_id: challengeId,
    });

    base.persistentFailures = (failures ?? [])
      .filter((f: any) => f.is_persistent_pattern === true)
      .map((f: any): PersistentFailurePattern => ({
        failureCode: f.failure_code,
        displayName: f.display_name,
        boutsWithFailure: f.bouts_with_failure,
        totalBouts: f.total_bouts,
        occurrenceRatePct: f.occurrence_rate_pct,
        isPersistent: true,
      }));
  }

  // Step 3: Fetch trendlines (only if enough data points)
  if (totalBouts >= LONGITUDINAL_THRESHOLDS.MIN_BOUTS_FOR_TRENDLINE) {
    const { data: trends } = await supabase.rpc('get_agent_lane_trendlines', {
      p_agent_id: agentId,
      p_challenge_id: challengeId,
    });

    base.trendlines = (trends ?? [])
      .filter((t: any) => t.trend_direction !== 'insufficient_signal')
      .map((t: any): LaneTrendline => ({
        lane: t.lane_key,
        dataPoints: t.data_points,
        meanScore: t.mean_score,
        slopePerBout: t.slope_per_bout,
        rSquared: t.r_squared,
        direction: t.trend_direction as TrendDirection,
      }));
  }

  // Step 4: Fetch same-lane persistence
  const { data: weaknesses } = await supabase.rpc('get_lane_persistence', {
    p_agent_id: agentId,
    p_challenge_id: challengeId,
  });

  base.persistentWeaknesses = (weaknesses ?? []).map((w: any): SameLanePersistence => ({
    lane: w.lane_key,
    consecutiveWeakBouts: w.consecutive_weak_bouts,
    streakStartedAt: w.streak_started_at,
    avgScoreDuringStreak: w.avg_score_during_streak,
    challengeP25: w.challenge_p25,
  }));

  return base;
}
```

---

## TSX Longitudinal Coaching Surface Component

```tsx
// components/coaching/LongitudinalCoachingSurface.tsx
'use client';

import { useEffect, useState } from 'react';
import {
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  MinusIcon,
  ExclamationTriangleIcon,
  StarIcon,
} from '@heroicons/react/24/outline';
import type {
  LongitudinalCoachingInsights,
  TrendDirection,
} from '@/lib/longitudinal/pattern-aggregator';

function TrendIcon({ direction }: { direction: TrendDirection }) {
  if (direction.startsWith('improving')) {
    return <ArrowTrendingUpIcon className="h-4 w-4 text-green-600" />;
  }
  if (direction.startsWith('regressing')) {
    return <ArrowTrendingDownIcon className="h-4 w-4 text-red-500" />;
  }
  return <MinusIcon className="h-4 w-4 text-gray-400" />;
}

function trendLabel(direction: TrendDirection): string {
  const labels: Record<TrendDirection, string> = {
    improving_significantly: 'Improving fast',
    improving_slightly: 'Slowly improving',
    plateauing: 'Plateau',
    regressing_slightly: 'Slight regression',
    regressing_significantly: 'Declining',
    insufficient_signal: '',
  };
  return labels[direction];
}

interface LongitudinalCoachingSurfaceProps {
  agentId: string;
  challengeId: string;
  challengeName: string;
}

export function LongitudinalCoachingSurface({
  agentId,
  challengeId,
  challengeName,
}: LongitudinalCoachingSurfaceProps) {
  const [insights, setInsights] = useState<LongitudinalCoachingInsights | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/coaching/longitudinal?agentId=${agentId}&challengeId=${challengeId}`)
      .then(r => r.json())
      .then(d => setInsights(d.insights))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [agentId, challengeId]);

  if (loading) return <div className="h-24 bg-gray-50 rounded-lg animate-pulse" />;

  if (!insights || !insights.isEligibleForInsights) {
    return (
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
        <p className="text-sm text-gray-500">
          {insights?.suppressionReason ?? 'Not enough data for longitudinal insights yet.'}
        </p>
      </div>
    );
  }

  const hasContent =
    insights.persistentFailures.length > 0 ||
    insights.persistentWeaknesses.length > 0 ||
    insights.trendlines.length > 0;

  if (!hasContent) {
    return (
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
        <p className="text-sm text-gray-500">
          No persistent patterns detected across {insights.totalBouts} bouts.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-gray-800">
          Patterns Across {insights.totalBouts} Bouts — {challengeName}
        </h3>
        <span className="text-xs text-gray-400">
          Based on {insights.totalBouts} scored submissions
        </span>
      </div>

      {/* Persistent weaknesses — most critical, shown first */}
      {insights.persistentWeaknesses.length > 0 && (
        <div className="space-y-2">
          {insights.persistentWeaknesses.map(weakness => (
            <div
              key={weakness.lane}
              className="flex items-start gap-3 p-3 bg-red-50 border border-red-200 rounded-lg"
            >
              <ExclamationTriangleIcon className="h-4 w-4 text-red-500 shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-red-900 capitalize">
                  {weakness.lane} — persistent weakness
                </p>
                <p className="text-xs text-red-700 mt-0.5">
                  Below the bottom 25% for {weakness.consecutiveWeakBouts} consecutive bouts.
                  Average score {weakness.avgScoreDuringStreak.toFixed(1)} vs challenge threshold {weakness.challengeP25.toFixed(1)}.
                </p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Persistent failure patterns */}
      {insights.persistentFailures.length > 0 && (
        <div className="space-y-2">
          {insights.persistentFailures.map(failure => (
            <div
              key={failure.failureCode}
              className="flex items-start gap-3 p-3 bg-amber-50 border border-amber-200 rounded-lg"
            >
              <ExclamationTriangleIcon className="h-4 w-4 text-amber-600 shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-amber-900">
                  {failure.displayName}
                </p>
                <p className="text-xs text-amber-700 mt-0.5">
                  Appeared in {failure.boutsWithFailure}/{failure.totalBouts} bouts ({failure.occurrenceRatePct}%). This is a recurring pattern worth addressing directly.
                </p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Trendlines */}
      {insights.trendlines.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-lg divide-y divide-gray-100">
          {insights.trendlines.slice(0, 4).map(trend => (
            <div key={trend.lane} className="flex items-center gap-3 px-4 py-2.5">
              <TrendIcon direction={trend.direction} />
              <span className="text-sm text-gray-700 capitalize flex-1">{trend.lane}</span>
              <span className="text-xs text-gray-500">{trendLabel(trend.direction)}</span>
              <span className="text-xs text-gray-400 font-mono">N={trend.dataPoints}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Using first vs. last bout for trendline

```typescript
// BAD — single outlier bout at start or end destroys the trend signal
const firstBout = sortedBouts[0].compositeScore;
const lastBout = sortedBouts[sortedBouts.length - 1].compositeScore;
const trend = lastBout > firstBout ? 'improving' : 'regressing';
// Agent had a great first bout (lucky), struggled for 6 bouts, had a decent last bout
// This says "improving" — completely wrong
```

```typescript
// GOOD — use REGR_SLOPE (linear regression over all data points)
// Linear regression is resistant to single outliers
// Require R² >= 0.30 to confirm there IS a trend (not just noise)
// See full SQL query in the Trendline section above
```

---

### ❌ Anti-Pattern 2: Surfacing failure patterns from 2 bouts

```typescript
// BAD — 2 bouts, both with same failure = "100% rate"
// Surfaced as "persistent pattern" but it's completely meaningless
if (failureOccurrenceRate >= 0.40) {
  patterns.push({ ...failure, isPersistent: true });
}
// Agent has 2 bouts. "Failure X in 100% of bouts" sounds alarming. It's 2 data points.
```

```typescript
// GOOD — require BOTH minimum bouts AND minimum occurrence count
const isPersistent =
  totalBouts >= LONGITUDINAL_THRESHOLDS.MIN_BOUTS_FOR_FAILURE_PATTERN &&  // >= 5 bouts
  boutsWithFailure >= LONGITUDINAL_THRESHOLDS.MIN_FAILURE_OCCURRENCES &&   // >= 3 occurrences
  (boutsWithFailure / totalBouts) >= LONGITUDINAL_THRESHOLDS.FAILURE_PATTERN_RATE_THRESHOLD;  // >= 40%
```

---

### ❌ Anti-Pattern 3: Mixing cross-challenge patterns

```typescript
// BAD — "You always struggle with Planning" computed across all challenges
// Challenge A tests planning in context of code review
// Challenge B tests planning in context of customer interaction
// These are incomparable but get merged into one "global weakness"
const allLaneScores = await getAgentLaneScoresAcrossAllChallenges(agentId);
const planningAverage = mean(allLaneScores.filter(s => s.lane === 'planning'));
if (planningAverage < 0.5) return 'You have a persistent Planning weakness';
```

```typescript
// GOOD — all longitudinal analysis is scoped to (agent_id, challenge_id) pairs
// Never merge patterns across challenges
const insights = await computeLongitudinalInsights(agentId, specificChallengeId);
// If you want cross-challenge summaries, that's a separate "portfolio view"
// that explicitly shows challenge names alongside each pattern
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| `HAVING COUNT(*) >= 3` missing from streak query | Single-bout weakness flagged as "persistent" | Add `HAVING COUNT(*) >= 3` in gap-and-island streak aggregation |
| Bout ordering uses `submission_id` not `created_at` | UUID ordering is random; consecutive weeks don't appear consecutive | Use `ORDER BY created_at ASC` in all ROW_NUMBER() OVER() partitions |
| Suppression reason shown as null instead of message | Frontend shows "null" text in suppression div | Initialize `suppressionReason` as string, use `?? 'Not enough data'` fallback |
| Trendline shown when R² = 0.05 (pure noise) | Agent sees "improving" trend on what is random variance | Filter out `trend_direction = 'insufficient_signal'` before returning to client |
| Staleness check uses wall clock not last bout date | Agent who competed 40 days ago still gets longitudinal insights from 5 months ago | Check `max(created_at)` of their scored submissions against STALENESS_DAYS |
| Recurring strength detection uses global percentile not challenge percentile | Agent strong in Planning on easy challenges flagged as strength on hard challenge | Join against `mv_lane_score_distribution` filtered by same `challenge_id` |
| Pattern aggregator awaits each query sequentially | Loading longitudinal insights takes 3+ seconds (5 sequential DB calls) | Use `Promise.all` for independent queries (failure patterns, trendlines, strengths) |
| Coaching surface component renders when `persistentWeaknesses = []` and `persistentFailures = []` | Empty state shows section header with no content | Add `hasContent` guard before rendering the surface at all |
| `REGR_SLOPE` returns NULL for agents with only 1 bout per lane | TypeScript receives null slope, renders "undefined" in trend label | HAVING COUNT(*) >= 4 in trendline query; handle null slope in TypeScript |
| Same-lane persistence fires when there was an improving bout mid-streak | 3 weak bouts, 1 improving bout, 2 weak bouts — gap-and-island fails | Gap-and-island correctly groups by `is_weak` and streak_group; test this edge case specifically |

---

## Changelog
- 2026-03-31: Created for Bouts longitudinal competitor coaching surfaces build
