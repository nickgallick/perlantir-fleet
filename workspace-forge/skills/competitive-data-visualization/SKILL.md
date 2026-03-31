---
name: competitive-data-visualization
description: Evaluation-specific visualization patterns for Bouts — radar charts, multi-judge comparison bars, rank distribution dots, confidence overlays, and percentile bands using Recharts with full accessibility and missing-data handling.
---

# Competitive Data Visualization

## Review Checklist

- [ ] **Radar chart has at least 5 lanes to make the shape meaningful** — fewer than 4 data points on a radar produces an unintelligible shape; fall back to bar chart for <4 lanes
- [ ] **Multi-judge grouped bar chart uses consistent judge color mapping** — Claude: indigo, GPT-4o: emerald, Gemini: amber — never use default Recharts colors which are hard to distinguish
- [ ] **All charts are wrapped in `ResponsiveContainer width="100%" height={N}`** — fixed width breaks on mobile and narrow side panels
- [ ] **Null/undefined score values are explicitly filtered before passing to Recharts** — Recharts silently renders gaps with some chart types but crashes others
- [ ] **Rank distribution dot shows the user's position relative to the field, not just a number** — the visual of WHERE they fell in the distribution is the point
- [ ] **Confidence overlay uses `opacity-30` fill, not full-color fill** — heavy confidence regions obscure the actual score line
- [ ] **Percentile bands are labeled inline** — "Median", "75th", "90th" next to the band lines, not in a legend that requires eye travel
- [ ] **All charts have `role="img"` and `aria-label` describing what the chart shows** — screen reader accessible
- [ ] **Custom tooltips show formatted values** — never rely on Recharts default tooltip format for scores (it shows raw floats)
- [ ] **Missing judge data in grouped bar chart renders as a visually distinct empty bar** — not a gap that skews spacing
- [ ] **Radar chart domain is fixed (0 to maxScore) not auto-scaled** — auto-scaling makes a score of 6/10 look like 10/10
- [ ] **Charts are tested with real partial data** — all-null lane set, single-judge result, and full 3-judge result before ship

---

## Radar Chart: Multi-Lane Score Profile

The radar chart is the signature visualization for Bouts — it shows at a glance which lanes an agent excelled in and which were weak. The shape is the signal.

**Critical design decisions:**
- Domain MUST be fixed (0–100 or 0–maxScore), never auto-scaled
- Outer ring should show the "max possible" as a reference shape
- If a lane score is null (pending), exclude the data point and show a note
- Use `PolarAngleAxis` for lane names, trim long names

```tsx
// components/charts/LaneRadarChart.tsx
'use client';

import React, { useMemo } from 'react';
import {
  RadarChart,
  Radar,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  ResponsiveContainer,
  Tooltip,
  Legend,
} from 'recharts';

export interface RadarLaneScore {
  laneId: string;
  laneName: string;
  score: number | null;
  maxScore: number;
  // Optional: show benchmark (e.g., competition average)
  benchmarkScore?: number | null;
}

interface LaneRadarChartProps {
  lanes: RadarLaneScore[];
  agentName: string;
  showBenchmark?: boolean;
  height?: number;
}

interface RadarDataPoint {
  lane: string;
  score: number;
  benchmark?: number;
  fullMark: number;
}

// Trim long lane names to avoid overflow on radar axes
function trimLaneName(name: string, maxLen = 16): string {
  return name.length > maxLen ? name.slice(0, maxLen - 1) + '…' : name;
}

export function LaneRadarChart({
  lanes,
  agentName,
  showBenchmark = false,
  height = 320,
}: LaneRadarChartProps) {
  // Filter to only scored lanes — null scores would distort the shape
  const scoredLanes = lanes.filter(l => l.score !== null);
  const unscoredCount = lanes.length - scoredLanes.length;

  const data: RadarDataPoint[] = useMemo(
    () =>
      scoredLanes.map(l => ({
        lane: trimLaneName(l.laneName),
        // score cannot be null here — filtered above
        score: Math.round(l.score! * (100 / l.maxScore)),
        benchmark:
          l.benchmarkScore !== undefined && l.benchmarkScore !== null
            ? Math.round(l.benchmarkScore * (100 / l.maxScore))
            : undefined,
        fullMark: 100,
      })),
    [scoredLanes]
  );

  // Need at least 3 points for a radar to be meaningful
  if (data.length < 3) {
    return (
      <div
        className="flex items-center justify-center rounded-lg bg-gray-50 border border-gray-200 text-sm text-gray-400"
        style={{ height }}
        role="img"
        aria-label="Insufficient data for radar chart"
      >
        {data.length === 0
          ? 'Scoring in progress'
          : `${data.length} lane${data.length === 1 ? '' : 's'} scored — radar requires 3+`}
      </div>
    );
  }

  return (
    <div
      role="img"
      aria-label={`Lane score radar chart for ${agentName}. ${scoredLanes.map(l => `${l.laneName}: ${l.score}`).join(', ')}.`}
    >
      {unscoredCount > 0 && (
        <p className="text-xs text-amber-600 mb-2 text-center">
          {unscoredCount} lane{unscoredCount !== 1 ? 's' : ''} still being scored
        </p>
      )}
      <ResponsiveContainer width="100%" height={height}>
        <RadarChart data={data} margin={{ top: 10, right: 30, bottom: 10, left: 30 }}>
          <PolarGrid stroke="#e5e7eb" />
          <PolarAngleAxis
            dataKey="lane"
            tick={{ fontSize: 11, fill: '#6b7280' }}
          />
          {/* Fixed domain 0-100 — never auto-scale */}
          <PolarRadiusAxis
            angle={90}
            domain={[0, 100]}
            tickCount={5}
            tick={{ fontSize: 10, fill: '#9ca3af' }}
            axisLine={false}
          />
          {/* Benchmark shape (competition average) */}
          {showBenchmark && (
            <Radar
              name="Field Avg"
              dataKey="benchmark"
              stroke="#d1d5db"
              fill="#d1d5db"
              fillOpacity={0.2}
              strokeDasharray="4 2"
            />
          )}
          {/* Agent score shape */}
          <Radar
            name={agentName}
            dataKey="score"
            stroke="#6366f1"
            fill="#6366f1"
            fillOpacity={0.25}
            strokeWidth={2}
            dot={{ fill: '#6366f1', r: 3 }}
          />
          <Tooltip
            content={({ active, payload }) => {
              if (!active || !payload?.length) return null;
              return (
                <div className="rounded-lg bg-white border border-gray-200 shadow-lg px-3 py-2">
                  <p className="text-xs font-semibold text-gray-900">{payload[0]?.payload?.lane}</p>
                  {payload.map(entry => (
                    <p key={entry.name} className="text-xs text-gray-600">
                      {entry.name}: <span className="font-medium">{entry.value}/100</span>
                    </p>
                  ))}
                </div>
              );
            }}
          />
          {showBenchmark && <Legend wrapperStyle={{ fontSize: 11 }} />}
        </RadarChart>
      </ResponsiveContainer>
    </div>
  );
}
```

---

## Multi-Judge Score Comparison: Grouped Bar Chart

Shows Claude vs GPT-4o vs Gemini scores per lane side-by-side. This is the most information-dense chart in Bouts — it reveals judge disagreement, which is often the most interesting signal.

**Critical rules:**
- Use semantic, consistent judge colors across all charts and the app
- Handle missing judge (pending or failed) with a placeholder bar, not a missing bar
- Show lane names on X axis, judge scores as grouped bars
- Score range fixed 0–100

```tsx
// components/charts/MultiJudgeBarChart.tsx
'use client';

import React, { useMemo } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  Cell,
  ResponsiveContainer,
  ReferenceLine,
} from 'recharts';

// Consistent judge color palette — use these everywhere in the app
export const JUDGE_COLORS = {
  claude: '#6366f1',   // indigo
  gpt4o: '#10b981',    // emerald
  gemini: '#f59e0b',   // amber
} as const;

export const JUDGE_LABELS = {
  claude: 'Claude',
  gpt4o: 'GPT-4o',
  gemini: 'Gemini',
} as const;

export type JudgeId = keyof typeof JUDGE_COLORS;

export interface JudgeLaneScore {
  judgeId: JudgeId;
  laneId: string;
  score: number | null;  // null = pending/failed
  status: 'complete' | 'pending' | 'failed';
}

export interface BarChartLane {
  laneId: string;
  laneName: string;
  scores: JudgeLaneScore[];
}

interface MultiJudgeBarChartProps {
  lanes: BarChartLane[];
  height?: number;
  showAverage?: boolean;
}

interface BarDataPoint {
  lane: string;
  claude: number | null;
  gpt4o: number | null;
  gemini: number | null;
  claudeStatus: JudgeLaneScore['status'];
  gpt4oStatus: JudgeLaneScore['status'];
  geminiStatus: JudgeLaneScore['status'];
}

function trimLane(name: string, max = 12) {
  return name.length > max ? name.slice(0, max - 1) + '…' : name;
}

export function MultiJudgeBarChart({
  lanes,
  height = 300,
  showAverage = true,
}: MultiJudgeBarChartProps) {
  const data: BarDataPoint[] = useMemo(
    () =>
      lanes.map(lane => {
        const byJudge = Object.fromEntries(
          lane.scores.map(s => [s.judgeId, s])
        ) as Record<JudgeId, JudgeLaneScore | undefined>;

        return {
          lane: trimLane(lane.laneName),
          claude: byJudge.claude?.score ?? null,
          gpt4o: byJudge.gpt4o?.score ?? null,
          gemini: byJudge.gemini?.score ?? null,
          claudeStatus: byJudge.claude?.status ?? 'pending',
          gpt4oStatus: byJudge.gpt4o?.status ?? 'pending',
          geminiStatus: byJudge.gemini?.status ?? 'pending',
        };
      }),
    [lanes]
  );

  // Compute cross-lane average for reference line
  const allScores = data.flatMap(d => [d.claude, d.gpt4o, d.gemini].filter((s): s is number => s !== null));
  const overallAvg = allScores.length > 0
    ? allScores.reduce((sum, s) => sum + s, 0) / allScores.length
    : null;

  if (lanes.length === 0) {
    return (
      <div
        className="flex items-center justify-center rounded-lg bg-gray-50 border border-gray-200 text-sm text-gray-400"
        style={{ height }}
        role="img"
        aria-label="No lanes to compare"
      >
        No lane data available
      </div>
    );
  }

  return (
    <div
      role="img"
      aria-label={`Multi-judge score comparison. ${lanes.map(l => l.laneName).join(', ')} lanes shown.`}
    >
      <ResponsiveContainer width="100%" height={height}>
        <BarChart data={data} margin={{ top: 8, right: 16, left: 0, bottom: 8 }} barGap={2} barCategoryGap="20%">
          <CartesianGrid vertical={false} stroke="#f3f4f6" />
          <XAxis
            dataKey="lane"
            tick={{ fontSize: 11, fill: '#6b7280' }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            domain={[0, 100]}
            tick={{ fontSize: 10, fill: '#9ca3af' }}
            axisLine={false}
            tickLine={false}
            tickCount={6}
          />
          {showAverage && overallAvg !== null && (
            <ReferenceLine
              y={overallAvg}
              stroke="#e5e7eb"
              strokeDasharray="4 2"
              label={{
                value: `avg ${overallAvg.toFixed(0)}`,
                fontSize: 10,
                fill: '#9ca3af',
                position: 'insideTopRight',
              }}
            />
          )}
          <Tooltip
            content={({ active, payload, label }) => {
              if (!active || !payload?.length) return null;
              return (
                <div className="rounded-lg bg-white border border-gray-200 shadow-lg px-3 py-2 space-y-1">
                  <p className="text-xs font-semibold text-gray-900 mb-1">{label}</p>
                  {payload.map(entry => {
                    const judgeId = entry.dataKey as JudgeId;
                    const dataPoint = payload[0]?.payload as BarDataPoint;
                    const statusKey = `${judgeId}Status` as keyof BarDataPoint;
                    const status = dataPoint[statusKey] as string;
                    return (
                      <div key={judgeId} className="flex items-center gap-2">
                        <div
                          className="h-2 w-2 rounded-sm shrink-0"
                          style={{ backgroundColor: entry.fill as string }}
                        />
                        <span className="text-xs text-gray-600">
                          {JUDGE_LABELS[judgeId]}:{' '}
                          {entry.value !== null
                            ? <span className="font-medium">{entry.value}/100</span>
                            : <span className="text-gray-400 italic">{status}</span>
                          }
                        </span>
                      </div>
                    );
                  })}
                </div>
              );
            }}
          />
          <Legend
            iconType="square"
            iconSize={8}
            formatter={(value) => (
              <span style={{ fontSize: 11, color: '#6b7280' }}>
                {JUDGE_LABELS[value as JudgeId] ?? value}
              </span>
            )}
          />
          {/* Render each judge's bar — null values show as 0-height placeholder with dashed border */}
          {(['claude', 'gpt4o', 'gemini'] as JudgeId[]).map(judgeId => (
            <Bar
              key={judgeId}
              dataKey={judgeId}
              name={judgeId}
              fill={JUDGE_COLORS[judgeId]}
              radius={[3, 3, 0, 0]}
              minPointSize={2} // ensures pending bars are visible as tiny stub
            >
              {data.map((entry, index) => {
                const score = entry[judgeId];
                const isPending = score === null;
                return (
                  <Cell
                    key={`${judgeId}-${index}`}
                    fill={isPending ? '#f3f4f6' : JUDGE_COLORS[judgeId]}
                    stroke={isPending ? '#d1d5db' : 'none'}
                    strokeDasharray={isPending ? '3 2' : undefined}
                    fillOpacity={isPending ? 0.5 : 1}
                  />
                );
              })}
            </Bar>
          ))}
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
```

---

## Rank Distribution + Confidence Overlay

Two patterns combined:

1. **Rank position visualization**: a dot plot showing where the user landed in the field distribution
2. **Confidence overlay**: a shaded band around the score line showing confidence bounds

```tsx
// components/charts/RankDistributionChart.tsx
'use client';

import React, { useMemo } from 'react';
import {
  ScatterChart,
  Scatter,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
  Area,
  AreaChart,
  ComposedChart,
  Line,
} from 'recharts';

// ─── Rank Distribution Dot Plot ───────────────────────────────────────────────

export interface FieldParticipant {
  submissionId: string;
  agentName: string;
  score: number;
  isCurrentUser: boolean;
  rank: number;
}

interface RankDistributionChartProps {
  participants: FieldParticipant[];
  prizePositions?: number; // top N win prizes
  height?: number;
}

export function RankDistributionChart({
  participants,
  prizePositions = 3,
  height = 140,
}: RankDistributionChartProps) {
  // Sort by score for distribution display
  const sorted = useMemo(
    () => [...participants].sort((a, b) => a.score - b.score),
    [participants]
  );

  const currentUser = participants.find(p => p.isCurrentUser);
  const prizeThreshold = [...participants]
    .sort((a, b) => b.score - a.score)
    .slice(prizePositions - 1, prizePositions)[0]?.score ?? null;

  // Convert to scatter data — use rank as X axis, score as Y
  const scatterData = sorted.map((p, i) => ({
    x: i + 1, // position in sorted field (1 = lowest)
    y: p.score,
    isUser: p.isCurrentUser,
    name: p.agentName,
    rank: p.rank,
    submissionId: p.submissionId,
  }));

  if (participants.length === 0) {
    return (
      <div
        className="flex items-center justify-center rounded-lg bg-gray-50 border border-gray-200 text-sm text-gray-400"
        style={{ height }}
        role="img"
        aria-label="No field data available"
      >
        No field data yet
      </div>
    );
  }

  const allScores = participants.map(p => p.score);
  const minScore = Math.min(...allScores);
  const maxScore = Math.max(...allScores);
  const scorePadding = (maxScore - minScore) * 0.1 || 5;

  return (
    <div
      role="img"
      aria-label={
        currentUser
          ? `Rank distribution. ${currentUser.agentName} scored ${currentUser.score}, ranked ${currentUser.rank} of ${participants.length}.`
          : `Rank distribution across ${participants.length} participants.`
      }
    >
      <ResponsiveContainer width="100%" height={height}>
        <ScatterChart margin={{ top: 16, right: 16, bottom: 8, left: 8 }}>
          <CartesianGrid stroke="#f3f4f6" vertical={false} />
          <XAxis
            dataKey="x"
            type="number"
            domain={[0, participants.length + 1]}
            tick={false}
            axisLine={false}
            tickLine={false}
            label={{ value: 'Field (low → high score)', position: 'insideBottom', fontSize: 10, fill: '#9ca3af', offset: -2 }}
          />
          <YAxis
            dataKey="y"
            domain={[minScore - scorePadding, maxScore + scorePadding]}
            tick={{ fontSize: 10, fill: '#9ca3af' }}
            axisLine={false}
            tickLine={false}
          />
          {/* Prize threshold line */}
          {prizeThreshold !== null && (
            <ReferenceLine
              y={prizeThreshold}
              stroke="#f59e0b"
              strokeDasharray="4 2"
              label={{
                value: `Prize line (top ${prizePositions})`,
                fontSize: 10,
                fill: '#b45309',
                position: 'insideTopRight',
              }}
            />
          )}
          <Tooltip
            content={({ active, payload }) => {
              if (!active || !payload?.length) return null;
              const point = payload[0]?.payload;
              if (!point) return null;
              return (
                <div className="rounded-lg bg-white border border-gray-200 shadow-lg px-3 py-2">
                  <p className="text-xs font-semibold text-gray-900">{point.name}</p>
                  <p className="text-xs text-gray-500">
                    Score: <span className="font-medium text-gray-800">{point.y.toFixed(1)}</span>
                  </p>
                  <p className="text-xs text-gray-500">
                    Rank: <span className="font-medium text-gray-800">#{point.rank}</span>
                  </p>
                </div>
              );
            }}
          />
          {/* Other participants — render as one scatter */}
          <Scatter
            name="Field"
            data={scatterData.filter(d => !d.isUser)}
            fill="#d1d5db"
            opacity={0.7}
            shape={(props: any) => {
              const { cx, cy } = props;
              return <circle cx={cx} cy={cy} r={4} fill="#d1d5db" />;
            }}
          />
          {/* Current user — highlighted dot */}
          <Scatter
            name="You"
            data={scatterData.filter(d => d.isUser)}
            fill="#6366f1"
            shape={(props: any) => {
              const { cx, cy } = props;
              return (
                <g>
                  {/* Halo */}
                  <circle cx={cx} cy={cy} r={9} fill="#6366f1" fillOpacity={0.15} />
                  <circle cx={cx} cy={cy} r={5} fill="#6366f1" />
                </g>
              );
            }}
          />
        </ScatterChart>
      </ResponsiveContainer>
    </div>
  );
}

// ─── Score + Confidence Overlay Chart ─────────────────────────────────────────

export interface ConfidenceDataPoint {
  label: string;           // e.g., lane name or time step
  score: number | null;
  confidenceLow: number | null;   // score - margin
  confidenceHigh: number | null;  // score + margin
}

interface ConfidenceOverlayChartProps {
  data: ConfidenceDataPoint[];
  height?: number;
  scoreColor?: string;
}

export function ConfidenceOverlayChart({
  data,
  height = 200,
  scoreColor = '#6366f1',
}: ConfidenceOverlayChartProps) {
  // Filter out null score points for the line, but keep structure for confidence band
  const chartData = data.map(d => ({
    label: d.label,
    score: d.score,
    confidenceLow: d.confidenceLow,
    confidenceHigh: d.confidenceHigh,
    // For Area chart: need a single "confidence band" encoded as [low, high]
    // Recharts Area doesn't natively support error bars; we use two Areas
    bandLow: d.confidenceLow,
    bandHigh: d.confidenceHigh,
  }));

  const hasConfidenceData = data.some(d => d.confidenceLow !== null && d.confidenceHigh !== null);

  return (
    <div
      role="img"
      aria-label={`Score chart with confidence overlay. ${data.map(d => `${d.label}: ${d.score ?? 'N/A'}`).join(', ')}.`}
    >
      <ResponsiveContainer width="100%" height={height}>
        <ComposedChart data={chartData} margin={{ top: 8, right: 16, bottom: 8, left: 8 }}>
          <CartesianGrid stroke="#f3f4f6" vertical={false} />
          <XAxis
            dataKey="label"
            tick={{ fontSize: 11, fill: '#6b7280' }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            domain={[0, 100]}
            tick={{ fontSize: 10, fill: '#9ca3af' }}
            axisLine={false}
            tickLine={false}
            tickCount={5}
          />
          {/* Confidence band — upper bound (transparent fill, fills to lower) */}
          {hasConfidenceData && (
            <Area
              type="monotone"
              dataKey="bandHigh"
              stroke="none"
              fill={scoreColor}
              fillOpacity={0.08}
              connectNulls={false}
            />
          )}
          {/* Lower confidence bound — fills "down" from upper */}
          {hasConfidenceData && (
            <Area
              type="monotone"
              dataKey="bandLow"
              stroke="none"
              fill="white"
              fillOpacity={1}
              connectNulls={false}
            />
          )}
          {/* Actual score line */}
          <Line
            type="monotone"
            dataKey="score"
            stroke={scoreColor}
            strokeWidth={2}
            dot={{ fill: scoreColor, r: 3 }}
            connectNulls={false}
          />
          <Tooltip
            content={({ active, payload, label }) => {
              if (!active || !payload?.length) return null;
              const point = payload[0]?.payload;
              const score = point?.score;
              const low = point?.confidenceLow;
              const high = point?.confidenceHigh;
              return (
                <div className="rounded-lg bg-white border border-gray-200 shadow-lg px-3 py-2 space-y-0.5">
                  <p className="text-xs font-semibold text-gray-900">{label}</p>
                  <p className="text-xs text-gray-600">
                    Score: <span className="font-medium">{score !== null && score !== undefined ? score.toFixed(1) : 'N/A'}</span>
                  </p>
                  {low !== null && high !== null && low !== undefined && high !== undefined && (
                    <p className="text-xs text-gray-400">
                      Confidence: {low.toFixed(1)} – {high.toFixed(1)}
                    </p>
                  )}
                </div>
              );
            }}
          />
        </ComposedChart>
      </ResponsiveContainer>
    </div>
  );
}
```

---

## Percentile Context Bands

Shows where the user's score falls relative to the field's distribution with labeled percentile bands. This is the chart that makes a score feel meaningful — "you're above the 75th percentile" is far more motivating than "you scored 73.2".

```tsx
// components/charts/PercentileBandsChart.tsx
'use client';

import React from 'react';
import {
  ComposedChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
} from 'recharts';

export interface PercentileData {
  laneId: string;
  laneName: string;
  userScore: number | null;
  p25: number;   // 25th percentile (bottom quartile)
  p50: number;   // median
  p75: number;   // 75th percentile
  p90: number;   // 90th percentile
  max: number;
}

interface PercentileBandsChartProps {
  data: PercentileData[];
  height?: number;
}

export function PercentileBandsChart({ data, height = 280 }: PercentileBandsChartProps) {
  // Transform into chart-friendly format — stacked area approach
  // Each band covers p25→p50, p50→p75, p75→p90, p90→max
  const chartData = data.map(d => ({
    lane: d.laneName.length > 14 ? d.laneName.slice(0, 13) + '…' : d.laneName,
    // For stacked bands, each segment is the DELTA above the previous
    band1: d.p25,               // bottom: 0–p25
    band2: d.p50 - d.p25,       // p25–p50
    band3: d.p75 - d.p50,       // p50–p75
    band4: d.p90 - d.p75,       // p75–p90
    band5: d.max - d.p90,       // p90–max
    userScore: d.userScore,
    // Raw values for tooltip
    rawP25: d.p25,
    rawP50: d.p50,
    rawP75: d.p75,
    rawP90: d.p90,
    rawMax: d.max,
  }));

  const bandColors = {
    band1: '#f3f4f6', // bottom quartile — neutral
    band2: '#e0e7ff', // p25–p50 — light indigo
    band3: '#c7d2fe', // p50–p75 — medium indigo
    band4: '#a5b4fc', // p75–p90 — stronger indigo
    band5: '#818cf8', // top 10% — bright indigo
  };

  return (
    <div
      role="img"
      aria-label={`Percentile context bands. ${data.filter(d => d.userScore !== null).map(d => `${d.laneName}: score ${d.userScore}, median ${d.p50}`).join('. ')}`}
    >
      <ResponsiveContainer width="100%" height={height}>
        <ComposedChart data={chartData} margin={{ top: 16, right: 16, bottom: 8, left: 8 }}>
          <CartesianGrid stroke="#f9fafb" vertical={false} />
          <XAxis
            dataKey="lane"
            tick={{ fontSize: 11, fill: '#6b7280' }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            domain={[0, 100]}
            tick={{ fontSize: 10, fill: '#9ca3af' }}
            axisLine={false}
            tickLine={false}
            tickCount={5}
          />
          {/* Stacked band areas */}
          {(['band1', 'band2', 'band3', 'band4', 'band5'] as const).map(band => (
            <Area
              key={band}
              type="step"
              dataKey={band}
              stackId="bands"
              stroke="none"
              fill={bandColors[band]}
              fillOpacity={1}
            />
          ))}
          {/* User score dots */}
          {data.map((d, i) => {
            if (d.userScore === null) return null;
            return (
              <ReferenceLine
                key={d.laneId}
                x={chartData[i]?.lane}
                stroke="transparent"
              />
            );
          })}
          <Tooltip
            content={({ active, payload, label }) => {
              if (!active || !payload?.length) return null;
              const d = payload[0]?.payload;
              if (!d) return null;
              const userScore = d.userScore;
              const percentile = userScore !== null
                ? userScore <= d.rawP25 ? '<25th'
                : userScore <= d.rawP50 ? '25–50th'
                : userScore <= d.rawP75 ? '50–75th'
                : userScore <= d.rawP90 ? '75–90th'
                : 'top 10%'
                : null;
              return (
                <div className="rounded-lg bg-white border border-gray-200 shadow-lg px-3 py-2 space-y-1">
                  <p className="text-xs font-semibold text-gray-900">{label}</p>
                  {userScore !== null && (
                    <p className="text-xs text-indigo-700 font-medium">
                      Your score: {userScore.toFixed(1)} ({percentile})
                    </p>
                  )}
                  <div className="text-xs text-gray-400 space-y-0.5">
                    <p>90th pct: {d.rawP90.toFixed(0)}</p>
                    <p>Median: {d.rawP50.toFixed(0)}</p>
                    <p>25th pct: {d.rawP25.toFixed(0)}</p>
                  </div>
                </div>
              );
            }}
          />
        </ComposedChart>
      </ResponsiveContainer>
      {/* Inline band legend */}
      <div className="flex items-center justify-end gap-4 mt-2 flex-wrap">
        {[
          { color: bandColors.band5, label: 'Top 10%' },
          { color: bandColors.band4, label: '75–90th' },
          { color: bandColors.band3, label: '50–75th' },
          { color: bandColors.band2, label: '25–50th' },
          { color: bandColors.band1, label: 'Bottom 25%' },
        ].map(({ color, label }) => (
          <div key={label} className="flex items-center gap-1">
            <div className="h-2.5 w-4 rounded-sm border border-gray-200" style={{ backgroundColor: color }} />
            <span className="text-xs text-gray-400">{label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Auto-scaled radar domain

```tsx
// BAD — auto domain makes 60/100 look like 100/100
<PolarRadiusAxis />  // no domain prop = auto-scale

// GOOD — always fix the domain
<PolarRadiusAxis domain={[0, 100]} tickCount={5} />
```

### ❌ Default Recharts colors for judges

```tsx
// BAD — default colors are inconsistent and don't match brand
<Bar dataKey="claude" />  // gets default blue #8884d8
<Bar dataKey="gpt4o" />   // gets default green #82ca9d

// GOOD — always use the shared judge palette
import { JUDGE_COLORS } from '@/components/charts/MultiJudgeBarChart';
<Bar dataKey="claude" fill={JUDGE_COLORS.claude} />
<Bar dataKey="gpt4o" fill={JUDGE_COLORS.gpt4o} />
```

### ❌ Passing null values to Recharts without handling

```tsx
// BAD — null in data array silently breaks some chart types
const data = lanes.map(l => ({ name: l.laneName, score: l.score }));
// score may be null for pending lanes — crashes PolarRadiusAxis

// GOOD — filter nulls before charting OR map to explicit fallback
const data = lanes
  .filter(l => l.score !== null)
  .map(l => ({ name: l.laneName, score: l.score! }));
```

### ❌ Fixed pixel height in ResponsiveContainer

```tsx
// BAD — breaks on mobile
<ResponsiveContainer width={640} height={300}>

// GOOD — always 100% width
<ResponsiveContainer width="100%" height={300}>
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Radar with <3 lanes renders a line or point | Degenerate shape confuses users | Detect `scoredLanes.length < 3`, render fallback bar chart instead |
| Judge missing from bar chart creates gap in grouping | One group has 2 bars instead of 3, x-axis spacing skews | Always render all 3 judge bars; use placeholder styling for missing judges |
| Auto-scaling Y axis on grouped bar chart | 30/100 score fills the bar to top | Set `domain={[0, 100]}` on YAxis |
| Confidence band uses solid fill at full opacity | Score line invisible under the band | Set `fillOpacity={0.08}` to 0.15 max on confidence area |
| Score of 0 filtered out with `.filter(Boolean)` | Lane with 0 score disappears from chart | Filter on `score !== null`, not falsy |
| Recharts tooltip shows raw float (73.233...) | Ugly default formatting | Always provide custom `content` prop with `.toFixed(1)` |
| Percentile bands with stacked Area: wrong order | Top percentile renders below bottom | Verify stack order from lowest to highest band |
| Missing aria-label on chart div | Screen readers announce nothing | Always add `role="img"` and descriptive `aria-label` |
| ResponsiveContainer inside a flex child with no width | Chart renders at 0px wide | Ensure parent has `min-w-0` or explicit width |
| `data.map` on undefined when async data not ready | TypeError before loading skeleton renders | Guard: `if (!data) return <Skeleton />` before any mapping |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
