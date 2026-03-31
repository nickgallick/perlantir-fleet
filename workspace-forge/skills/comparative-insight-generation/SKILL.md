---
name: comparative-insight-generation
description: Generate insights comparing an agent's performance to top performers, peers, and their own history — only from real data with minimum sample guards, including percentile comparisons, counterfactual rank calculation, and "surprisingly strong" lane detection.
---

# Comparative Insight Generation

## Review Checklist

- [ ] Every comparison query has a `HAVING COUNT(*) >= minimum_sample` guard — never surface comparisons with N < 10 submissions
- [ ] Top-10% comparison uses `PERCENTILE_CONT(0.90)` window function, not hand-computed averages — verify the SQL uses proper window aggregation
- [ ] Counterfactual rank calculator receives actual rank distribution data, not just the agent's scores — confirm the function takes the full leaderboard as input
- [ ] Peer comparison data is anonymized: no agent names, only positional labels (e.g., "Top 10%", "Median competitor") — review all API response payloads
- [ ] "Surprisingly strong" detection requires the agent's lane score to be in the top 25th percentile AND their overall rank to be below the top 25% — both conditions, not just one
- [ ] Counterfactual rank calculation uses the actual rank distribution at the time of the bout — not the current live distribution which may have changed
- [ ] Minimum sample constant is defined once in a shared config, not hardcoded in multiple query files — check for magic number `10` scattered in SQL
- [ ] Insights are suppressed entirely (not shown as null/empty) when sample threshold is not met — confirm UI shows "Not enough data yet" not a blank widget
- [ ] Failure code frequency comparison uses only failures from submissions on the same challenge — cross-challenge failure comparisons are meaningless
- [ ] All percentile comparisons show the sample size (N) alongside the comparison — "You scored higher than 80% of competitors (N=42)" not just "80th percentile"
- [ ] TypeScript counterfactual calculator has unit tests — this is mathematically tricky enough to break silently
- [ ] Lane comparison insights are regenerated when new submissions come in, not cached indefinitely — check cache TTL or revalidation trigger

---

## Safe Comparison Rules — When and What You Can Compare

The most dangerous thing in comparative analytics is showing insights computed from insufficient data. A user who scored 9.2 on a challenge where only 2 other people competed is "top performer" by the math but that comparison means nothing.

**Minimum sample thresholds (hardcode in `lib/insights-config.ts`):**

```typescript
// lib/insights-config.ts
export const INSIGHT_THRESHOLDS = {
  // Minimum submissions on this challenge to show any comparison
  MIN_SAMPLE_FOR_COMPARISON: 10,
  // Minimum submissions to show "top 10%" bucket (need enough to make 10% meaningful)
  MIN_SAMPLE_FOR_DECILE: 30,
  // Minimum submissions to show per-lane failure code analysis
  MIN_SAMPLE_FOR_FAILURE_CODES: 15,
  // Minimum unique agents to show peer anonymized comparison
  MIN_AGENTS_FOR_PEER_COMPARISON: 5,
  // Counterfactual rank requires this many ranked agents to be meaningful
  MIN_AGENTS_FOR_COUNTERFACTUAL: 8,
} as const;
```

**What comparisons are safe:**
- Agent vs. overall score distribution on the SAME challenge (when N >= 10)
- Agent vs. top-10% average scores per lane (when N >= 30)
- Which failure codes appear most in top-10% vs. bottom-50% (when N >= 15)
- Counterfactual: "if your worst lane had scored at median, what rank would you have been?" (when N >= 8)
- Agent's own history: this challenge vs. previous attempts (when agent has >= 2 attempts)
- "Surprisingly strong" lane detection: lanes where agent outperformed overall rank (requires N >= 10)

**What comparisons are NEVER safe:**
- "Agent X did Y" — never name other agents
- Comparing scores across different challenges (apples to oranges)
- Showing another agent's raw scores even anonymized (shows too little = one user reverse-engineers identity)
- Future performance predictions without historical data

---

## SQL Window Functions — Percentile Comparisons

**Lane Score Distribution with Percentile Bands**

```sql
-- For a given challenge, compute lane score percentiles
-- Used to position an agent's score within the distribution
WITH lane_scores AS (
  SELECT
    s.agent_id,
    s.id AS submission_id,
    lane_key,
    (lane_value::TEXT)::FLOAT AS score
  FROM submissions s,
    LATERAL jsonb_each(s.final_lane_scores) AS ls(lane_key, lane_value)
  WHERE s.challenge_id = $1
    AND s.status = 'scored'
    AND s.final_lane_scores IS NOT NULL
),
percentiles AS (
  SELECT
    lane_key,
    COUNT(*) AS n,
    ROUND(AVG(score)::NUMERIC, 2) AS mean_score,
    ROUND(PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY score)::NUMERIC, 2) AS p10,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY score)::NUMERIC, 2) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY score)::NUMERIC, 2) AS p50,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY score)::NUMERIC, 2) AS p75,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY score)::NUMERIC, 2) AS p90
  FROM lane_scores
  GROUP BY lane_key
  HAVING COUNT(*) >= 10  -- NEVER skip this guard
),
agent_scores AS (
  SELECT
    lane_key,
    score AS agent_score
  FROM lane_scores
  WHERE agent_id = $2
)
SELECT
  p.lane_key,
  p.n,
  p.mean_score,
  p.p10, p.p25, p.p50, p.p75, p.p90,
  a.agent_score,
  -- Agent's percentile rank within the distribution
  ROUND(
    (
      SELECT COUNT(*)::FLOAT / p.n * 100
      FROM lane_scores ls2
      WHERE ls2.lane_key = p.lane_key
        AND ls2.score <= a.agent_score
    )::NUMERIC,
    1
  ) AS agent_percentile_rank
FROM percentiles p
JOIN agent_scores a ON p.lane_key = a.lane_key
ORDER BY p.lane_key;
```

**What Top-10% Did Differently — Failure Code Frequency Analysis**

```sql
-- Compare failure code distribution between top-10% and bottom-50%
WITH scored_submissions AS (
  SELECT
    s.id,
    s.agent_id,
    s.challenge_id,
    s.composite_score,
    NTILE(10) OVER (
      PARTITION BY s.challenge_id
      ORDER BY s.composite_score DESC
    ) AS decile -- 1 = top 10%, 10 = bottom 10%
  FROM submissions s
  WHERE s.challenge_id = $1
    AND s.status = 'scored'
),
failure_counts AS (
  SELECT
    ss.decile,
    fc.failure_code,
    COUNT(*) AS occurrence_count,
    COUNT(DISTINCT ss.id) AS submission_count,
    -- How many submissions in this decile have this failure?
    COUNT(DISTINCT ss.id)::FLOAT / (
      SELECT COUNT(*) FROM scored_submissions WHERE decile = ss.decile
    ) AS occurrence_rate
  FROM scored_submissions ss
  JOIN submission_failure_codes sfc ON ss.id = sfc.submission_id
  JOIN failure_codes fc ON sfc.failure_code_id = fc.id
  WHERE ss.decile IN (1, 5, 6, 7, 8, 9, 10) -- top decile vs bottom half
  GROUP BY ss.decile, fc.failure_code
)
SELECT
  fc_top.failure_code,
  fc_top.occurrence_rate AS top10_rate,
  COALESCE(fc_bottom.occurrence_rate, 0) AS bottom50_rate,
  -- Ratio: how much more common is this in bottom vs top?
  ROUND(
    COALESCE(fc_bottom.occurrence_rate, 0) /
    NULLIF(fc_top.occurrence_rate, 0),
    2
  ) AS bottom_to_top_ratio
FROM failure_counts fc_top
LEFT JOIN (
  SELECT failure_code, AVG(occurrence_rate) AS occurrence_rate
  FROM failure_counts
  WHERE decile >= 5
  GROUP BY failure_code
) fc_bottom ON fc_top.failure_code = fc_bottom.failure_code
WHERE fc_top.decile = 1
  AND (
    SELECT COUNT(DISTINCT id)
    FROM scored_submissions
    WHERE challenge_id = $1
  ) >= 15  -- minimum sample guard for failure analysis
ORDER BY bottom_to_top_ratio DESC NULLS LAST
LIMIT 10;
```

---

## TypeScript Counterfactual Rank Calculator

The counterfactual question: "If this agent had scored median on their worst lane instead of what they actually scored, where would they have ranked overall?"

This reveals which single lane improvement would have the most rank impact. It requires:
1. The agent's actual lane scores
2. The median lane scores for the challenge
3. The composite scoring formula
4. The full ranked list of all agents

```typescript
// lib/counterfactual-rank.ts

export interface AgentLaneScores {
  agentId: string;
  compositeScore: number;
  laneScores: Record<string, number>;
}

export interface CounterfactualResult {
  worstLane: string;
  actualScore: number;
  medianScore: number;
  actualRank: number;
  counterfactualCompositeScore: number;
  counterfactualRank: number;
  rankImprovement: number;
  rankImprovementPct: number;
  sampleSize: number;
  isMeaningful: boolean; // false if sample too small
}

export interface ChallengeScoreDistribution {
  laneWeights: Record<string, number>; // sum must = 1.0
  laneMedians: Record<string, number>;
  allAgentScores: AgentLaneScores[];
}

function computeCompositeScore(
  laneScores: Record<string, number>,
  laneWeights: Record<string, number>
): number {
  return Object.entries(laneWeights).reduce((total, [lane, weight]) => {
    return total + (laneScores[lane] ?? 0) * weight;
  }, 0);
}

function getRank(compositeScore: number, allComposites: number[]): number {
  // Rank = number of agents with higher composite + 1
  const sorted = [...allComposites].sort((a, b) => b - a);
  return sorted.findIndex(score => score <= compositeScore) + 1;
}

export function computeCounterfactualRank(
  agentId: string,
  distribution: ChallengeScoreDistribution,
  minSampleSize: number = 8
): CounterfactualResult | null {
  const agent = distribution.allAgentScores.find(a => a.agentId === agentId);
  if (!agent) return null;

  const sampleSize = distribution.allAgentScores.length;
  const isMeaningful = sampleSize >= minSampleSize;

  const allComposites = distribution.allAgentScores.map(a => a.compositeScore);
  const actualRank = getRank(agent.compositeScore, allComposites);

  // Find the agent's worst lane (biggest negative delta from median)
  let worstLane = '';
  let worstDelta = 0;

  for (const [lane, agentScore] of Object.entries(agent.laneScores)) {
    const median = distribution.laneMedians[lane];
    if (median === undefined) continue;
    const delta = agentScore - median; // negative = below median
    if (delta < worstDelta) {
      worstDelta = delta;
      worstLane = lane;
    }
  }

  if (!worstLane) return null;

  // Compute counterfactual: replace worst lane score with median
  const counterfactualLaneScores = {
    ...agent.laneScores,
    [worstLane]: distribution.laneMedians[worstLane],
  };

  const counterfactualCompositeScore = computeCompositeScore(
    counterfactualLaneScores,
    distribution.laneWeights
  );

  // Recompute rank with counterfactual composite
  const counterfactualComposites = distribution.allAgentScores.map(a =>
    a.agentId === agentId ? counterfactualCompositeScore : a.compositeScore
  );
  const counterfactualRank = getRank(counterfactualCompositeScore, counterfactualComposites);

  const rankImprovement = actualRank - counterfactualRank; // positive = moved up

  return {
    worstLane,
    actualScore: agent.laneScores[worstLane],
    medianScore: distribution.laneMedians[worstLane],
    actualRank,
    counterfactualCompositeScore: Math.round(counterfactualCompositeScore * 100) / 100,
    counterfactualRank,
    rankImprovement,
    rankImprovementPct: Math.round((rankImprovement / sampleSize) * 100),
    sampleSize,
    isMeaningful,
  };
}
```

**"Surprisingly Strong" Lane Detection**

```typescript
// lib/surprisingly-strong.ts
import { INSIGHT_THRESHOLDS } from './insights-config';

export interface SurprisinglyStrongLane {
  lane: string;
  agentLanePercentile: number;
  agentOverallPercentile: number;
  delta: number; // how many percentile points above overall rank
}

export function detectSurprisinglyStrongLanes(
  agentLanePercentiles: Record<string, number>,
  agentOverallPercentile: number,
  sampleSize: number
): SurprisinglyStrongLane[] {
  if (sampleSize < INSIGHT_THRESHOLDS.MIN_SAMPLE_FOR_COMPARISON) return [];

  const surprising: SurprisinglyStrongLane[] = [];

  for (const [lane, lanePercentile] of Object.entries(agentLanePercentiles)) {
    const delta = lanePercentile - agentOverallPercentile;
    // "Surprisingly strong" = lane percentile is 20+ points above overall percentile
    // AND lane percentile is in top 25% (≥75th)
    if (delta >= 20 && lanePercentile >= 75) {
      surprising.push({
        lane,
        agentLanePercentile: lanePercentile,
        agentOverallPercentile,
        delta,
      });
    }
  }

  return surprising.sort((a, b) => b.delta - a.delta);
}
```

---

## TSX Comparative Insight Display

```tsx
// components/feedback/ComparativeInsightDisplay.tsx
'use client';

import { ArrowUpIcon, ArrowDownIcon, SparklesIcon } from '@heroicons/react/24/outline';
import type { CounterfactualResult } from '@/lib/counterfactual-rank';
import type { SurprisinglyStrongLane } from '@/lib/surprisingly-strong';
import { INSIGHT_THRESHOLDS } from '@/lib/insights-config';

interface ComparativeInsightDisplayProps {
  counterfactual: CounterfactualResult | null;
  surprisinglyStrong: SurprisinglyStrongLane[];
  agentPercentileRank: number;
  sampleSize: number;
  challengeName: string;
}

function PercentileBar({ value, label }: { value: number; label: string }) {
  return (
    <div className="space-y-1">
      <div className="flex justify-between text-xs text-gray-500">
        <span>{label}</span>
        <span className="font-mono font-medium text-gray-700">{value}th pct</span>
      </div>
      <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
        <div
          className="h-full bg-blue-500 rounded-full transition-all duration-500"
          style={{ width: `${value}%` }}
        />
      </div>
    </div>
  );
}

export function ComparativeInsightDisplay({
  counterfactual,
  surprisinglyStrong,
  agentPercentileRank,
  sampleSize,
  challengeName,
}: ComparativeInsightDisplayProps) {
  const hasEnoughData = sampleSize >= INSIGHT_THRESHOLDS.MIN_SAMPLE_FOR_COMPARISON;

  if (!hasEnoughData) {
    return (
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 text-center">
        <p className="text-sm text-gray-500">
          Comparative insights available once {INSIGHT_THRESHOLDS.MIN_SAMPLE_FOR_COMPARISON}+ submissions
          are scored for this challenge.
        </p>
        <p className="text-xs text-gray-400 mt-1">Currently: {sampleSize} submissions</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Overall position */}
      <div className="bg-white border border-gray-200 rounded-lg p-4">
        <h3 className="text-sm font-semibold text-gray-700 mb-3">
          Your Position — {challengeName}
          <span className="ml-2 text-xs font-normal text-gray-400">(N={sampleSize})</span>
        </h3>
        <PercentileBar value={agentPercentileRank} label="Overall rank" />
      </div>

      {/* Counterfactual rank insight */}
      {counterfactual && counterfactual.isMeaningful && counterfactual.rankImprovement > 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <ArrowUpIcon className="h-5 w-5 text-blue-600 shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-blue-900">
                Your{' '}
                <span className="font-semibold capitalize">{counterfactual.worstLane}</span>{' '}
                lane cost you the most rank points
              </p>
              <p className="text-sm text-blue-700 mt-1">
                If you'd scored at the median in {counterfactual.worstLane} (
                {counterfactual.medianScore.toFixed(1)} vs your {counterfactual.actualScore.toFixed(1)}),
                you would have ranked{' '}
                <span className="font-semibold">
                  #{counterfactual.counterfactualRank}
                </span>{' '}
                instead of #{counterfactual.actualRank} — a{' '}
                <span className="font-semibold text-blue-900">
                  {counterfactual.rankImprovement} position improvement
                </span>.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Surprisingly strong lanes */}
      {surprisinglyStrong.length > 0 && (
        <div className="bg-amber-50 border border-amber-200 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <SparklesIcon className="h-5 w-5 text-amber-600 shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-amber-900">
                Unexpectedly strong {surprisinglyStrong.length > 1 ? 'lanes' : 'lane'}
              </p>
              {surprisinglyStrong.map(lane => (
                <p key={lane.lane} className="text-sm text-amber-700 mt-1">
                  <span className="font-semibold capitalize">{lane.lane}</span>: you ranked in the{' '}
                  <span className="font-semibold">{lane.agentLanePercentile}th percentile</span> on
                  this lane — {lane.delta} points above your overall rank. This is a genuine strength.
                </p>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Generating comparisons with no minimum sample guard

```typescript
// BAD — "top performer" on a challenge with 2 submissions is meaningless
const topScore = await supabase
  .from('submissions')
  .select('composite_score')
  .eq('challenge_id', challengeId)
  .order('composite_score', { ascending: false })
  .limit(1)
  .single();

// Shows "You scored above 100% of competitors" when N = 1
const insight = `You scored above ${percentile}% of competitors`;
```

```typescript
// GOOD — suppress insight entirely if below threshold
const { count } = await supabase
  .from('submissions')
  .select('*', { count: 'exact', head: true })
  .eq('challenge_id', challengeId)
  .eq('status', 'scored');

if (!count || count < INSIGHT_THRESHOLDS.MIN_SAMPLE_FOR_COMPARISON) {
  return null; // No insight rendered
}
```

---

### ❌ Anti-Pattern 2: Showing "what top 10% did" when N < 30

```sql
-- BAD — "top 10%" of 11 submissions is just 1 submission
-- That one submission's data is shown as "what top performers do"
SELECT failure_code, COUNT(*) 
FROM failure_codes fc
JOIN submissions s ON fc.submission_id = s.id
WHERE s.challenge_id = $1
  AND s.composite_score > (SELECT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY composite_score) FROM submissions WHERE challenge_id = $1)
GROUP BY failure_code;
-- Returns failure codes for 1 submission presented as "top 10% insight"
```

```sql
-- GOOD — add HAVING guard for minimum decile sample
-- Only show this analysis when the challenge has >= 30 submissions
SELECT failure_code, COUNT(*) FROM ... 
WHERE challenge_id = $1
  AND (SELECT COUNT(*) FROM submissions WHERE challenge_id = $1) >= 30
-- And use NTILE(10) in a CTE to only run when there are enough for a meaningful decile
```

---

### ❌ Anti-Pattern 3: Counterfactual computed against current live distribution

```typescript
// BAD — distribution at query time is different from when bout was scored
// Agent ranked #5 at time of bout; 100 more submissions since then, now they're #60
// Counterfactual computed against current data says "if you improved Planning, you'd be #58"
// This is misleading — they can't go back in time to change that bout's ranking
const currentDistribution = await fetchCurrentChallengeDistribution(challengeId);
const result = computeCounterfactualRank(agentId, currentDistribution);
```

```typescript
// GOOD — snapshot the distribution at bout completion time
// Store score snapshot in the bout_results table at scoring time
const { data: boutSnapshot } = await supabase
  .from('bout_score_snapshots')
  .select('score_distribution')
  .eq('bout_id', boutId)
  .single();
const result = computeCounterfactualRank(agentId, boutSnapshot.score_distribution);
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| `NTILE(10)` used when N < 10 | Postgres assigns all rows to decile 1; top-10% = all submissions | Add `HAVING COUNT(*) >= 30` before running decile analysis |
| Lane percentile query uses cross-challenge data | Agent ranked as "top 10% in planning" using data from all challenges mixed | Always filter `WHERE challenge_id = $1` in distribution queries |
| Counterfactual assumes equal lane weights | Some challenges weight execution 40% and planning 20%; equal-weight counterfactual gives wrong answer | Pass `laneWeights` from challenge config into `computeCounterfactualRank` |
| Anonymized peer comparison shows N=2 aggregates | With 2 agents, aggregate IS effectively deanonymized | Never show aggregates with fewer than `MIN_AGENTS_FOR_PEER_COMPARISON = 5` unique agents |
| "Surprisingly strong" fires when agent has median score on lane AND overall | Delta condition passes because both are ~50th percentile and delta ≈ 0 | Require BOTH: delta >= 20 AND lane percentile >= 75 |
| Counterfactual rank uses current live composite scores | Scores change as judges reprocess — rank shifts after the fact | Read from `bout_results` snapshot table, not live `submissions` |
| Missing `NULL` handling on `jsonb_each(lane_scores)` | Submissions with NULL `final_lane_scores` cause query errors | Add `WHERE s.final_lane_scores IS NOT NULL` guard |
| Failure code comparison runs on different challenge types | Multi-step challenges and single-turn challenges have incomparable failure codes | Scope failure analysis to `challenge_type = $challenge_type` |
| `agentPercentileRank` computed as ratio (0.75) not percentage (75) | "You scored higher than 0.75% of competitors" shown to user | Multiply by 100 in the SQL query, document the unit |
| Insight shown when agent has only attempted the challenge once | "Your Planning lane has been weak across attempts" from 1 attempt | Require N >= 2 attempts for any cross-attempt comparison |

---

## Changelog
- 2026-03-31: Created for Bouts comparative insight generation build
