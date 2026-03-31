---
name: data-visualization
description: Recharts-based data visualization in Next.js/React — percentile bars, trend lines, comparative charts, responsive containers, and accessibility standards.
---

# Data Visualization (Recharts)

## Review Checklist

1. [ ] All charts wrapped in `<ResponsiveContainer width="100%" height={...}>`
2. [ ] No hardcoded pixel widths on chart containers
3. [ ] Axes labeled with units (e.g., "Score (0–100)", "Submissions")
4. [ ] Tooltips formatted — no raw floats, use `toFixed(1)` or `Intl.NumberFormat`
5. [ ] Colors from design system tokens — never hardcoded hex
6. [ ] Empty/loading states handled (don't render chart with empty data array)
7. [ ] Trend lines use `<LineChart>` not `<AreaChart>` unless fill adds meaning
8. [ ] Percentile bars use `<BarChart layout="vertical">` for horizontal bar display
9. [ ] Charts are keyboard-accessible (title + description via `<text>` or aria-label)
10. [ ] Chart data memoized — no re-sorting/re-shaping on every render

---

## Percentile Bar Pattern (Lane Score vs. Field)

Used for showing where an agent's lane score sits vs. median, top quartile, winner.

```tsx
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ReferenceLine, ResponsiveContainer, Cell
} from 'recharts'

interface LanePercentileBarProps {
  laneScore: number        // agent's score (0-100)
  median: number
  topQuartile: number
  winner: number
  laneName: string
}

export function LanePercentileBar({
  laneScore, median, topQuartile, winner, laneName
}: LanePercentileBarProps) {
  const data = [
    { name: 'You', score: laneScore },
    { name: 'Median', score: median },
    { name: 'Top 25%', score: topQuartile },
    { name: 'Winner', score: winner },
  ]

  return (
    <div aria-label={`${laneName} score comparison`}>
      <ResponsiveContainer width="100%" height={120}>
        <BarChart data={data} layout="vertical" margin={{ left: 60 }}>
          <CartesianGrid strokeDasharray="3 3" horizontal={false} />
          <XAxis type="number" domain={[0, 100]} tickFormatter={(v) => `${v}`} />
          <YAxis type="category" dataKey="name" width={55} />
          <Tooltip formatter={(value: number) => [`${value.toFixed(1)}`, 'Score']} />
          <Bar dataKey="score" radius={[0, 4, 4, 0]}>
            {data.map((entry, index) => (
              <Cell
                key={entry.name}
                fill={index === 0 ? 'var(--color-primary)' : 'var(--color-muted)'}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
```

---

## Longitudinal Trend Line Pattern

Used for lane score progression across multiple bout submissions.

```tsx
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, ReferenceLine
} from 'recharts'

interface TrendPoint {
  boutIndex: number      // x-axis: submission #1, #2, #3
  score: number          // lane score 0-100
  boutId: string
}

interface LaneTrendChartProps {
  data: TrendPoint[]
  laneName: string
  median: number         // field median — reference line
}

export function LaneTrendChart({ data, laneName, median }: LaneTrendChartProps) {
  if (data.length < 2) {
    return <p className="text-sm text-muted-foreground">Not enough data for trend.</p>
  }

  return (
    <div aria-label={`${laneName} score trend`}>
      <ResponsiveContainer width="100%" height={200}>
        <LineChart data={data} margin={{ top: 8, right: 16, bottom: 0, left: 0 }}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis
            dataKey="boutIndex"
            tickFormatter={(v) => `#${v}`}
            label={{ value: 'Submission', position: 'insideBottom', offset: -4 }}
          />
          <YAxis domain={[0, 100]} tickFormatter={(v) => `${v}`} />
          <Tooltip
            formatter={(value: number) => [`${value.toFixed(1)}`, laneName]}
            labelFormatter={(label) => `Submission #${label}`}
          />
          <ReferenceLine
            y={median}
            stroke="var(--color-muted-foreground)"
            strokeDasharray="4 4"
            label={{ value: 'Field median', position: 'insideTopRight', fontSize: 11 }}
          />
          <Line
            type="monotone"
            dataKey="score"
            stroke="var(--color-primary)"
            strokeWidth={2}
            dot={{ r: 4 }}
            activeDot={{ r: 6 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}
```

---

## Empty/Loading State Guard

Always guard before rendering. Recharts throws on empty data.

```tsx
function ChartSection({ data }: { data: TrendPoint[] }) {
  if (!data || data.length === 0) {
    return (
      <div className="flex items-center justify-center h-[200px] text-sm text-muted-foreground">
        No data yet
      </div>
    )
  }
  return <LaneTrendChart data={data} ... />
}
```

---

## Common Bugs to Catch in Review

| Bug | Symptom | Fix |
|-----|---------|-----|
| No `ResponsiveContainer` | Chart is 0px wide on mobile | Wrap always |
| Raw float tooltips | "Score: 73.3333333" | `toFixed(1)` in formatter |
| Hardcoded colors | Breaks dark mode | Use CSS vars |
| Chart renders with `[]` | Recharts runtime error | Guard with length check |
| Re-sort on every render | Jank / performance | `useMemo` on data shape |
| Missing axis labels | Users don't know units | Always label axes |

---

## Installation

```bash
npm install recharts
# Types included — no @types package needed
```

---

## Changelog
- 2026-03-31: Created for Bouts feedback pipeline build
