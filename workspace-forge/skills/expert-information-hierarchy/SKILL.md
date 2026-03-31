---
name: expert-information-hierarchy
description: How to make dense evaluation output readable fast — the 3-second rule, progressive disclosure architecture, scan-first layout, expandable evidence panels, and concrete before/after redesign for Bouts result pages.
---

# Expert Information Hierarchy

## Review Checklist

- [ ] **The verdict badge and top score number are visible without scrolling on every viewport** — test at 375px, 768px, 1280px; if they're below the fold at 375px, the hierarchy is broken
- [ ] **The page communicates pass/fail or rank in under 3 seconds** — have someone unfamiliar look for 3 seconds and ask what they learned
- [ ] **Evidence panels are collapsed by default** — no evidence is surfaced inline unless it's the single most important signal
- [ ] **Lane ordering is intentional**: worst-performing lane shown first, or highest-weight lane first — never alphabetical or insertion order
- [ ] **Progressive disclosure has exactly 3 tiers**: summary → detail → evidence; a 4th tier means you've split detail wrong
- [ ] **Expandable panels are keyboard-navigable** — Tab to reach, Enter/Space to expand, Escape to collapse; test with keyboard only
- [ ] **The page does not show "null" or empty boxes for pending data** — pending lanes show "scoring" state, not blank
- [ ] **On mobile, the scan-first summary fills the screen above fold** — the detail section starts at or below the fold on 375px
- [ ] **Lane priority logic is extractable** — a function `sortLanes(lanes, strategy)` exists and is testable in isolation
- [ ] **No content repeats between tiers** — if the score is in the summary, it's not restated identically in the detail section
- [ ] **Expand/collapse state is persisted during the session** — if a user opens a panel and scrolls, it stays open on scroll back
- [ ] **Typography establishes hierarchy without color alone** — size + weight carry hierarchy; color reinforces but doesn't define it

---

## The 3-Second Rule: Designing for Instant Signal

The 3-second rule is not a guideline — it's a test. Sit a user in front of your result page, give them 3 seconds, then cover the screen and ask: "What was the outcome? What was the score? Did they win or lose?"

If they can't answer all three, your hierarchy is broken.

**What must be visible in 3 seconds on every viewport:**
1. Agent name (who is this result for?)
2. Overall verdict: pass/fail, win/lose, or numeric rank
3. Top-line score or primary metric
4. Whether scoring is final or still in progress

**What must NOT be visible in 3 seconds:**
- Evidence quotes
- Individual judge breakdowns
- Lane-level scores (these belong in tier 2)
- Methodology explanations

The scan-first layout puts #1–4 in the first 80px of vertical space.

```tsx
// components/results/ResultPageHeader.tsx
// This is the ONLY content above the fold on mobile
'use client';

import React from 'react';
import { cn } from '@/lib/utils';

type VerdictType = 'winner' | 'prize' | 'placed' | 'completed' | 'pending';

interface ResultPageHeaderProps {
  agentName: string;
  overallScore: number | null;
  rank: number | null;
  totalParticipants: number;
  prizePositions: number;
  isFullyScored: boolean;
  boutName: string;
}

function getVerdict(
  rank: number | null,
  prizePositions: number,
  isFullyScored: boolean
): { type: VerdictType; label: string; description: string } {
  if (!isFullyScored) {
    return { type: 'pending', label: 'Scoring', description: 'Results are being finalized' };
  }
  if (rank === null) {
    return { type: 'completed', label: 'Submitted', description: 'Awaiting final ranking' };
  }
  if (rank === 1) {
    return { type: 'winner', label: '1st Place', description: 'Top of the field' };
  }
  if (rank <= prizePositions) {
    return { type: 'prize', label: `#${rank} — Prize`, description: `Top ${prizePositions} — prize awarded` };
  }
  if (rank <= prizePositions + 2) {
    // Close miss — needs special handling (see competitive-product-psychology skill)
    return { type: 'placed', label: `#${rank}`, description: `Just outside the top ${prizePositions}` };
  }
  return { type: 'completed', label: `#${rank}`, description: `of ${0} participants` };
}

const verdictStyles: Record<VerdictType, { badge: string; text: string }> = {
  winner: { badge: 'bg-amber-100 text-amber-800 border border-amber-200', text: 'text-amber-700' },
  prize: { badge: 'bg-indigo-100 text-indigo-800 border border-indigo-200', text: 'text-indigo-700' },
  placed: { badge: 'bg-gray-100 text-gray-700 border border-gray-200', text: 'text-gray-500' },
  completed: { badge: 'bg-gray-100 text-gray-600 border border-gray-200', text: 'text-gray-400' },
  pending: { badge: 'bg-amber-50 text-amber-600 border border-amber-100', text: 'text-amber-500' },
};

export function ResultPageHeader({
  agentName,
  overallScore,
  rank,
  totalParticipants,
  prizePositions,
  isFullyScored,
  boutName,
}: ResultPageHeaderProps) {
  const verdict = getVerdict(rank, prizePositions, isFullyScored);
  const styles = verdictStyles[verdict.type];

  return (
    // This entire block is max 80px tall — nothing below the fold on mobile
    <div className="flex items-start justify-between gap-4 py-5 px-6 bg-white border-b border-gray-100">
      {/* Left: identity */}
      <div className="min-w-0">
        <p className="text-xs text-gray-400 font-medium uppercase tracking-wide truncate">
          {boutName}
        </p>
        <h1 className="text-xl font-bold text-gray-900 truncate mt-0.5">
          {agentName}
        </h1>
        <p className={cn('text-xs mt-1', styles.text)}>
          {verdict.description.replace('of 0', `of ${totalParticipants}`)}
        </p>
      </div>

      {/* Right: score + verdict — the visual anchor */}
      <div className="flex flex-col items-end shrink-0 gap-2">
        <span className={cn('inline-flex items-center rounded-full px-3 py-1 text-sm font-semibold', styles.badge)}>
          {verdict.type === 'pending' && (
            <span className="mr-1.5 h-1.5 w-1.5 rounded-full bg-amber-400 animate-pulse" />
          )}
          {verdict.label}
        </span>
        {overallScore !== null ? (
          <div className="text-right">
            <span className="text-3xl font-bold text-gray-900 tabular-nums">
              {overallScore.toFixed(1)}
            </span>
            <span className="text-sm text-gray-400 ml-1">/ 100</span>
          </div>
        ) : (
          <div className="h-9 w-20 rounded bg-gray-100 animate-pulse" />
        )}
      </div>
    </div>
  );
}
```

---

## Progressive Disclosure Architecture

Three tiers, strict separation. Every piece of content lives in exactly one tier.

| Tier | Content | Default state | Scroll position |
|------|---------|---------------|-----------------|
| **Summary** | Verdict, rank, top score, completion status | Always visible | Above fold |
| **Detail** | Lane scores, judge comparison, score breakdown | Visible by default | First scroll |
| **Evidence** | Quotes, annotations, per-judge reasoning | Collapsed | Expanded on demand |

The architecture is a component composition pattern: `<ResultPage>` renders a `<SummaryTier>`, then a `<DetailTier>`, then one `<EvidenceTier>` per lane.

```tsx
// components/results/ResultPageLayout.tsx
'use client';

import React, { useState, useCallback } from 'react';
import type { NormalizedSubmissionResult } from '@/types/results';
import { ResultPageHeader } from './ResultPageHeader';
import { LaneDetailSection } from './LaneDetailSection';
import { EvidencePanel } from './EvidencePanel';
import { sortLanes, type LaneSortStrategy } from '@/lib/lane-sort';

interface ResultPageLayoutProps {
  result: NormalizedSubmissionResult;
  boutName: string;
  prizePositions: number;
  totalParticipants: number;
}

export function ResultPageLayout({
  result,
  boutName,
  prizePositions,
  totalParticipants,
}: ResultPageLayoutProps) {
  // Track which evidence panels are open — persisted for session duration
  const [openEvidencePanels, setOpenEvidencePanels] = useState<Set<string>>(new Set());

  const toggleEvidence = useCallback((laneId: string) => {
    setOpenEvidencePanels(prev => {
      const next = new Set(prev);
      if (next.has(laneId)) {
        next.delete(laneId);
      } else {
        next.add(laneId);
      }
      return next;
    });
  }, []);

  // Sort lanes: worst-performing first (most actionable signal leads)
  const sortedLanes = sortLanes(result, 'worst-first');

  return (
    <div className="min-h-screen bg-gray-50">
      {/* TIER 1: Summary — always visible, above fold */}
      <ResultPageHeader
        agentName={result.agentName}
        overallScore={result.overallScore}
        rank={result.rank}
        totalParticipants={totalParticipants}
        prizePositions={prizePositions}
        isFullyScored={result.isFullyScored}
        boutName={boutName}
      />

      <div className="max-w-3xl mx-auto px-4 py-6 space-y-4">
        {/* TIER 2: Detail — lane scores, visible immediately below fold */}
        <section aria-labelledby="lane-breakdown-heading">
          <h2 id="lane-breakdown-heading" className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
            Lane Breakdown
          </h2>
          <div className="space-y-3">
            {sortedLanes.map(lane => (
              <LaneDetailSection
                key={lane.laneId}
                lane={lane}
                judgeResults={result.judgeResults}
                evidenceOpen={openEvidencePanels.has(lane.laneId)}
                onToggleEvidence={() => toggleEvidence(lane.laneId)}
              />
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
```

---

## Lane Priority Logic and Expandable Evidence Panels

The order lanes appear in the breakdown is a product decision, not a display accident. "Worst first" surfaces the most actionable feedback. "Highest weight first" surfaces what mattered most. "Custom order" lets the bout designer control the narrative.

```typescript
// lib/lane-sort.ts
import type { NormalizedSubmissionResult, NormalizedLaneScore } from '@/types/results';

export type LaneSortStrategy = 'worst-first' | 'best-first' | 'weight-desc' | 'weight-asc' | 'alpha';

/**
 * Get the aggregate score for a lane across all complete judges.
 * Returns null if no judges have scored this lane yet.
 */
function getLaneAggregateScore(
  laneId: string,
  result: NormalizedSubmissionResult
): number | null {
  const scores: number[] = [];

  for (const judge of result.judgeResults) {
    if (!judge.isComplete) continue;
    const laneScore = judge.laneScores.find(ls => ls.laneId === laneId);
    if (laneScore?.isScored) {
      scores.push(laneScore.score!);
    }
  }

  if (scores.length === 0) return null;
  return scores.reduce((sum, s) => sum + s, 0) / scores.length;
}

/**
 * Get all unique lanes from judge results, with aggregate scores.
 */
export interface LaneSummary {
  laneId: string;
  laneName: string;
  aggregateScore: number | null;
  maxScore: number;
  weight: number;
  percentScore: number | null;
}

export function getLaneSummaries(result: NormalizedSubmissionResult): LaneSummary[] {
  // Build unique lane list from first complete judge
  const completeJudge = result.judgeResults.find(j => j.isComplete);
  if (!completeJudge) {
    // Fall back to pending judge's lane structure
    const anyJudge = result.judgeResults[0];
    if (!anyJudge) return [];
    return anyJudge.laneScores.map(ls => ({
      laneId: ls.laneId,
      laneName: ls.laneName,
      aggregateScore: null,
      maxScore: ls.maxScore,
      weight: ls.weight,
      percentScore: null,
    }));
  }

  return completeJudge.laneScores.map(ls => {
    const agg = getLaneAggregateScore(ls.laneId, result);
    return {
      laneId: ls.laneId,
      laneName: ls.laneName,
      aggregateScore: agg,
      maxScore: ls.maxScore,
      weight: ls.weight,
      percentScore: agg !== null && ls.maxScore > 0 ? (agg / ls.maxScore) * 100 : null,
    };
  });
}

export function sortLanes(
  result: NormalizedSubmissionResult,
  strategy: LaneSortStrategy
): LaneSummary[] {
  const lanes = getLaneSummaries(result);

  switch (strategy) {
    case 'worst-first':
      return [...lanes].sort((a, b) => {
        if (a.percentScore === null && b.percentScore === null) return 0;
        if (a.percentScore === null) return 1;  // pending lanes go last
        if (b.percentScore === null) return -1;
        return a.percentScore - b.percentScore;  // lowest first
      });

    case 'best-first':
      return [...lanes].sort((a, b) => {
        if (a.percentScore === null && b.percentScore === null) return 0;
        if (a.percentScore === null) return 1;
        if (b.percentScore === null) return -1;
        return b.percentScore - a.percentScore;
      });

    case 'weight-desc':
      return [...lanes].sort((a, b) => b.weight - a.weight);

    case 'weight-asc':
      return [...lanes].sort((a, b) => a.weight - b.weight);

    case 'alpha':
      return [...lanes].sort((a, b) => a.laneName.localeCompare(b.laneName));

    default:
      return lanes;
  }
}
```

```tsx
// components/results/LaneDetailSection.tsx
'use client';

import React, { useRef, useEffect } from 'react';
import { cn } from '@/lib/utils';
import type { LaneSummary } from '@/lib/lane-sort';
import type { NormalizedJudgeResult } from '@/types/results';

interface LaneDetailSectionProps {
  lane: LaneSummary;
  judgeResults: NormalizedJudgeResult[];
  evidenceOpen: boolean;
  onToggleEvidence: () => void;
}

export function LaneDetailSection({
  lane,
  judgeResults,
  evidenceOpen,
  onToggleEvidence,
}: LaneDetailSectionProps) {
  const evidenceRefs = judgeResults.flatMap(j =>
    j.evidenceRefs.filter(r => r.laneId === lane.laneId)
  );
  const hasEvidence = evidenceRefs.length > 0;

  const scoreColor =
    lane.percentScore === null ? 'bg-gray-200'
    : lane.percentScore >= 75 ? 'bg-emerald-500'
    : lane.percentScore >= 50 ? 'bg-amber-400'
    : 'bg-red-400';

  return (
    <div className="rounded-lg bg-white border border-gray-200 overflow-hidden">
      {/* Tier 2: Lane summary row */}
      <div className="px-5 py-4">
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <h3 className="text-sm font-semibold text-gray-900 truncate">{lane.laneName}</h3>
              <span className="text-xs text-gray-400">×{lane.weight.toFixed(1)}</span>
            </div>
            {/* Score bar */}
            <div className="mt-2 flex items-center gap-3">
              <div className="flex-1 h-1.5 rounded-full bg-gray-100">
                <div
                  className={cn('h-full rounded-full transition-all duration-500', scoreColor)}
                  style={{ width: lane.percentScore !== null ? `${lane.percentScore}%` : '0%' }}
                />
              </div>
              <span className="text-sm font-bold text-gray-900 tabular-nums w-12 text-right shrink-0">
                {lane.aggregateScore !== null
                  ? `${lane.aggregateScore.toFixed(1)}`
                  : '—'
                }
              </span>
            </div>
          </div>
        </div>

        {/* Evidence toggle — only shown if evidence exists */}
        {hasEvidence && (
          <button
            type="button"
            onClick={onToggleEvidence}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                onToggleEvidence();
              }
            }}
            className="mt-3 flex items-center gap-1.5 text-xs text-indigo-600 hover:text-indigo-800 transition-colors"
            aria-expanded={evidenceOpen}
            aria-controls={`evidence-${lane.laneId}`}
          >
            <svg
              className={cn('h-3.5 w-3.5 transition-transform', evidenceOpen && 'rotate-90')}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              aria-hidden="true"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
            {evidenceOpen ? 'Hide' : 'Show'} evidence ({evidenceRefs.length})
          </button>
        )}
      </div>

      {/* Tier 3: Evidence panel — collapsed by default */}
      <div
        id={`evidence-${lane.laneId}`}
        role="region"
        aria-label={`Evidence for ${lane.laneName}`}
        className={cn(
          'border-t border-gray-100 bg-gray-50 transition-all duration-200 overflow-hidden',
          evidenceOpen ? 'max-h-screen' : 'max-h-0'
        )}
      >
        <div className="px-5 py-4 space-y-3">
          {evidenceRefs.map(ref => (
            <div key={ref.refId} className="space-y-1">
              <div className="flex items-center gap-2">
                <span className="text-xs font-medium text-gray-500">{ref.judgeId}</span>
                <span className="text-xs text-gray-300">·</span>
                <span className="text-xs text-gray-400 capitalize">{ref.type}</span>
              </div>
              <blockquote className="text-sm text-gray-700 leading-relaxed pl-3 border-l-2 border-indigo-200">
                {ref.content}
              </blockquote>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
```

---

## Before/After: Dense Page Redesigned for Hierarchy

This is a concrete example of what "information hierarchy broken" looks like, and how to fix it.

### ❌ BEFORE: Dense, no hierarchy

```tsx
// BAD — everything at the same visual weight, in order of schema fields
function ResultPageOld({ result }: { result: any }) {
  return (
    <div className="p-6 space-y-4">
      {/* Score buried in the middle */}
      <p>Submission ID: {result.submission_id}</p>
      <p>Created: {result.created_at}</p>
      <p>Bout: {result.bout_id}</p>

      {result.judge_results?.map((j: any) => (
        <div key={j.judge_id} className="border p-4 space-y-2">
          <p className="font-bold">{j.judge_id}</p>
          {j.lane_scores?.map((ls: any) => (
            <div key={ls.lane_id}>
              {ls.lane_name}: {ls.score} / {ls.max_score}
              {ls.confidence && <span> (confidence: {ls.confidence})</span>}
            </div>
          ))}
          {j.evidence_refs?.map((ref: any) => (
            <div key={ref.ref_id} className="text-sm bg-gray-50 p-2">
              {ref.content}
            </div>
          ))}
        </div>
      ))}

      {/* Rank hidden at the bottom */}
      <p>Rank: {result.rank}</p>
      <p>Overall score: {result.overall_score}</p>
    </div>
  );
}
// PROBLEMS:
// 1. Rank and score are at the BOTTOM — user has to scroll to find the answer
// 2. Evidence is inline with scores — no hierarchy, everything is noise
// 3. Judge data repeated per judge without aggregation
// 4. Schema fields in raw order, not user order
// 5. Font size and weight uniform — nothing stands out
```

### ✅ AFTER: 3-tier hierarchy

```tsx
// GOOD — scan-first, 3 tiers, correct visual weight
function ResultPageNew({ result }: { result: NormalizedSubmissionResult }) {
  // Summary tier: rank + score IN THE HEADER — visible in 1 second
  // Detail tier: lane breakdown below fold — readable with one scroll
  // Evidence tier: collapsed — available on demand, not distracting

  return (
    <div className="min-h-screen bg-gray-50">
      {/* TIER 1 — always above fold, 80px tall */}
      <header className="bg-white border-b border-gray-100 px-6 py-5">
        <div className="flex items-start justify-between max-w-3xl mx-auto">
          <div>
            <p className="text-xs text-gray-400 uppercase tracking-wide">Code Challenge #4</p>
            <h1 className="text-xl font-bold text-gray-900 mt-0.5">{result.agentName}</h1>
          </div>
          <div className="text-right">
            <span className="inline-block rounded-full bg-indigo-100 text-indigo-800 text-sm font-semibold px-3 py-1">
              #{result.rank ?? '—'}
            </span>
            <div className="mt-1.5">
              <span className="text-3xl font-bold text-gray-900">
                {result.overallScore?.toFixed(1) ?? '—'}
              </span>
              <span className="text-sm text-gray-400 ml-1">/ 100</span>
            </div>
          </div>
        </div>
      </header>

      {/* TIER 2 — detail, requires first scroll */}
      <main className="max-w-3xl mx-auto px-4 py-6 space-y-3">
        {sortLanes(result, 'worst-first').map(lane => (
          <LaneDetailSection key={lane.laneId} lane={lane} judgeResults={result.judgeResults} evidenceOpen={false} onToggleEvidence={() => {}} />
        ))}
        {/* TIER 3 — evidence panels are inside each LaneDetailSection, collapsed */}
      </main>
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ All tiers visible simultaneously

```tsx
// BAD — evidence inline with scores, same visual weight
<div>
  <p>Score: {lane.score}</p>
  <p>Confidence: {lane.confidence}</p>
  {/* Evidence immediately below score — no hierarchy */}
  {evidenceRefs.map(r => <p key={r.refId}>{r.content}</p>)}
</div>

// GOOD — evidence behind disclosure
<div>
  <p className="text-sm font-bold">{lane.score}</p>
  <button onClick={toggleEvidence} aria-expanded={open}>Show evidence</button>
  {open && <EvidencePanel refs={evidenceRefs} />}
</div>
```

### ❌ Lane order by insertion/alphabetical

```tsx
// BAD — lanes in DB insertion order = arbitrary
result.judgeResults[0].laneScores.map(lane => <LaneRow key={lane.laneId} lane={lane} />)

// GOOD — explicit sort, worst first for maximum actionability
sortLanes(result, 'worst-first').map(lane => <LaneDetailSection key={lane.laneId} ... />)
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Rank/score below fold on mobile | 3-second test fails — users scroll for the answer | Move verdict + score to page header, always above fold |
| Evidence panels open by default | Page feels overwhelming, user can't find scores | Set `evidenceOpen={false}` as default; user opens on demand |
| Lane order is alphabetical | "Analysis" lane is first even though it scored 95% | Use `sortLanes(result, 'worst-first')` |
| Expand/collapse not keyboard accessible | Tab reaches button but Enter/Space doesn't work | Add `onKeyDown` handler for Enter and Space |
| `max-h-0` / `max-h-screen` transition clips content | Evidence panel appears to cut off at weird height | Use `max-h-0` → `max-h-[1000px]` not `max-h-screen`; test with 20+ evidence items |
| Score of 0 in the header looks like "no score" | Users think scoring failed | Display `0.0 / 100` explicitly — never show `— / 100` for a scored 0 |
| Summary tier repeats in detail tier | Users see score twice at same size — noise | Summary shows top-line, detail shows per-lane; no content duplication |
| Open panel state lost on parent re-render | User opens evidence, scroll triggers re-render, panel closes | Lift `openEvidencePanels` state to page level, not lane component |
| No skeleton for pending lanes | Blank space where lanes will appear | Render placeholder lane rows with "scoring in progress" state |
| Accessibility: no `aria-expanded` on toggle button | Screen reader doesn't announce open/closed state | Add `aria-expanded={evidenceOpen}` and `aria-controls={panelId}` |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
