---
name: premium-replay-breakdown-ux
description: Design the Bouts post-match breakdown page — information hierarchy, component architecture, partial result handling, loading states, mobile/desktop layout, and psychological flow that makes users feel the result is trustworthy and earned.
---

# Premium Replay Breakdown UX

## Review Checklist

1. **Information hierarchy is enforced in the component tree**: The render order must be: verdict → lane breakdown → next steps → evidence panel → relative context. No component should render out of order. Test: disable CSS and verify the DOM order is correct.
2. **Partial results never render as broken**: When some lanes are pending, the component shows "Evaluating…" skeleton cards with progress indicators — not empty cards, blank text, or layout shift when data arrives. Test with a real partial state.
3. **Loading state does not use spinner-only**: A full-screen spinner is not acceptable. Each section has its own skeleton state so the user can see the page structure while data loads. Storybook story required for each skeleton variant.
4. **Score animation runs only once**: The score counter animation fires once on mount, not on every re-render. Add `useRef` or `useState` to track whether animation has played.
5. **Evidence panel is collapsed by default**: Users are not forced to read evidence — it's available on demand. Verify: evidence panel renders with `isExpanded={false}` on initial load.
6. **Mobile layout stacks vertically, no horizontal scroll**: Test on 375px viewport. No element should overflow. Lane breakdown cards must be full-width on mobile.
7. **Contradiction notice renders in the lane where it occurred**: The contradiction badge must be scoped to the lane card, not shown as a global alert. Verify: a contradiction in "Efficiency" only affects the Efficiency lane card.
8. **State machine drives all loading/error/partial/complete states**: No ad-hoc `if (loading && !error && data)` chains. Use a proper state type union and render based on machine state.
9. **Next steps are actionable, not generic**: "Practice algorithm problems" is not acceptable. Next steps must reference the specific lane key and score range. Verify: `generateNextSteps()` takes lane scores as input, not just overall score.
10. **Relative context ("vs field") only shows when rankings are finalized**: Do not show percentile during open window. Verify: `BreakdownRelativeContext` renders nothing if `rankStatus === 'provisional'`.
11. **Tab/keyboard navigation works through the breakdown**: Evidence refs must be focusable. Lane cards must be expandable via Enter key. Run axe-core in CI.
12. **Score delta from previous attempt renders correctly**: If user has a previous submission, show delta (+7, -3). Verify the delta calculation handles null (first attempt) gracefully without crashing.

---

## Information Hierarchy: The Psychological Flow of Reading a Result

This is the most important design decision in Bouts. Users arrive at the breakdown page in one of two emotional states: (1) hopeful, wanting validation; (2) defensive, bracing for criticism. The layout must work for both.

**Correct hierarchy:**
1. **Overall verdict** — answer the fundamental question first: how did I do?
2. **Lane breakdown** — where specifically did I excel or struggle?
3. **Actionable next steps** — what can I do about it?
4. **Evidence panel** — show your work (on demand)
5. **Relative context** — where do I stand vs others? (only when finalized)

**Why this order:** Users read top-to-bottom. If you put evidence first, users get lost in details before they understand the conclusion. If you put relative context first, losing feels worse. Verdict first anchors the emotional read.

---

## Component Architecture

```
BreakdownPage (page.tsx — server component, fetches data)
├── BreakdownShell (layout wrapper, handles state machine)
│   ├── BreakdownHeader (score, verdict, basic metadata)
│   │   ├── ScoreRing (animated score circle)
│   │   ├── VerdictBadge (Exceptional / Strong / Adequate / Developing)
│   │   └── SubmissionMeta (submitted at, challenge name, attempt number)
│   ├── BreakdownLanes (lane-by-lane breakdown)
│   │   └── LaneCard[] (one per lane — expandable)
│   │       ├── LaneScoreBar
│   │       ├── LaneSignalPair (positive + weakness)
│   │       ├── ContradictionNotice (conditional)
│   │       └── LaneDimensionGrid (expanded state)
│   ├── BreakdownNextSteps (actionable recommendations)
│   │   └── NextStepItem[] (per-lane suggestions)
│   ├── BreakdownEvidencePanel (collapsed by default)
│   │   └── EvidenceRefList[]
│   └── BreakdownRelativeContext (only when rank finalized)
│       ├── PercentileBar
│       └── FieldDistributionChart
```

---

## Complete TSX: Core Breakdown Components

```tsx
// app/bouts/[boutId]/breakdown/page.tsx
import { Suspense } from 'react';
import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { BreakdownShell } from '@/components/breakdown/BreakdownShell';
import { BreakdownSkeleton } from '@/components/breakdown/BreakdownSkeleton';
import { loadBreakdownData } from '@/lib/breakdown/breakdown-loader';

interface Props {
  params: { boutId: string };
  searchParams: { submissionId?: string };
}

export default async function BreakdownPage({ params, searchParams }: Props) {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) notFound();

  const submissionId = searchParams.submissionId;
  if (!submissionId) notFound();

  // Verify ownership — users can only see their own breakdown
  const { data: submission } = await supabase
    .from('submissions')
    .select('id, user_id, bout_id, created_at, attempt_number')
    .eq('id', submissionId)
    .eq('bout_id', params.boutId)
    .single();

  if (!submission || submission.user_id !== user.id) notFound();

  const breakdown = await loadBreakdownData(submissionId);

  return (
    <Suspense fallback={<BreakdownSkeleton />}>
      <BreakdownShell
        submission={submission}
        breakdown={breakdown}
      />
    </Suspense>
  );
}
```

```tsx
// components/breakdown/BreakdownShell.tsx
'use client';

import { useState, useEffect, useReducer } from 'react';
import type { SynthesizedFeedback } from '@/lib/synthesis/feedback-synthesizer';
import { BreakdownHeader } from './BreakdownHeader';
import { BreakdownLanes } from './BreakdownLanes';
import { BreakdownNextSteps } from './BreakdownNextSteps';
import { BreakdownEvidencePanel } from './BreakdownEvidencePanel';
import { BreakdownRelativeContext } from './BreakdownRelativeContext';

// ---- State Machine ----
type BreakdownState =
  | { type: 'loading' }
  | { type: 'partial'; feedback: SynthesizedFeedback; pendingLaneKeys: string[] }
  | { type: 'complete'; feedback: SynthesizedFeedback }
  | { type: 'error'; message: string };

type BreakdownAction =
  | { type: 'LANES_PARTIAL'; feedback: SynthesizedFeedback; pendingLaneKeys: string[] }
  | { type: 'LANES_COMPLETE'; feedback: SynthesizedFeedback }
  | { type: 'FETCH_ERROR'; message: string };

function breakdownReducer(state: BreakdownState, action: BreakdownAction): BreakdownState {
  switch (action.type) {
    case 'LANES_PARTIAL':
      return { type: 'partial', feedback: action.feedback, pendingLaneKeys: action.pendingLaneKeys };
    case 'LANES_COMPLETE':
      return { type: 'complete', feedback: action.feedback };
    case 'FETCH_ERROR':
      return { type: 'error', message: action.message };
    default:
      return state;
  }
}

interface BreakdownShellProps {
  submission: { id: string; bout_id: string; created_at: string; attempt_number: number };
  breakdown: SynthesizedFeedback | null;
}

export function BreakdownShell({ submission, breakdown }: BreakdownShellProps) {
  const [state, dispatch] = useReducer(breakdownReducer, { type: 'loading' });

  useEffect(() => {
    if (!breakdown) {
      dispatch({ type: 'FETCH_ERROR', message: 'Breakdown data unavailable' });
      return;
    }

    const pendingLaneKeys = breakdown.lanes
      .filter((l) => l.reconciledScore === 0 && !l.fallbackReason)
      .map((l) => l.laneKey);

    if (pendingLaneKeys.length > 0) {
      dispatch({ type: 'LANES_PARTIAL', feedback: breakdown, pendingLaneKeys });
    } else {
      dispatch({ type: 'LANES_COMPLETE', feedback: breakdown });
    }
  }, [breakdown]);

  if (state.type === 'loading') {
    return <BreakdownLoadingState />;
  }

  if (state.type === 'error') {
    return <BreakdownErrorState message={state.message} />;
  }

  const { feedback } = state;
  const isPending = state.type === 'partial';
  const pendingLaneKeys = state.type === 'partial' ? state.pendingLaneKeys : [];

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 space-y-8">
      {/* 1. Overall verdict — always first */}
      <BreakdownHeader
        overallScore={feedback.overallScore}
        overallAdjustedScore={feedback.overallAdjustedScore}
        overallSignal={feedback.overallSignal}
        overallWeakness={feedback.overallWeakness}
        submittedAt={submission.created_at}
        attemptNumber={submission.attempt_number}
        isPending={isPending}
      />

      {/* 2. Lane breakdown */}
      <BreakdownLanes
        lanes={feedback.lanes}
        pendingLaneKeys={pendingLaneKeys}
      />

      {/* 3. Next steps */}
      <BreakdownNextSteps lanes={feedback.lanes} />

      {/* 4. Evidence panel (collapsed by default) */}
      <BreakdownEvidencePanel lanes={feedback.lanes} />

      {/* 5. Relative context — only when complete */}
      {!isPending && (
        <BreakdownRelativeContext
          submissionId={submission.id}
          boutId={submission.bout_id}
        />
      )}
    </div>
  );
}
```

```tsx
// components/breakdown/BreakdownHeader.tsx
'use client';

import { useEffect, useRef, useState } from 'react';

interface BreakdownHeaderProps {
  overallScore: number;
  overallAdjustedScore: number;
  overallSignal: string | null;
  overallWeakness: string | null;
  submittedAt: string;
  attemptNumber: number;
  isPending: boolean;
}

function getVerdictLabel(score: number): { label: string; color: string; bg: string } {
  if (score >= 85) return { label: 'Exceptional', color: 'text-emerald-700', bg: 'bg-emerald-100' };
  if (score >= 70) return { label: 'Strong', color: 'text-indigo-700', bg: 'bg-indigo-100' };
  if (score >= 50) return { label: 'Adequate', color: 'text-amber-700', bg: 'bg-amber-100' };
  return { label: 'Developing', color: 'text-gray-600', bg: 'bg-gray-100' };
}

export function BreakdownHeader({
  overallScore,
  overallAdjustedScore,
  overallSignal,
  overallWeakness,
  submittedAt,
  attemptNumber,
  isPending,
}: BreakdownHeaderProps) {
  const [displayScore, setDisplayScore] = useState(0);
  const hasAnimated = useRef(false);
  const verdict = getVerdictLabel(overallScore);
  const hasIntegrityDeduction = overallAdjustedScore < overallScore;

  // Animate score counter — only once
  useEffect(() => {
    if (hasAnimated.current || isPending) return;
    hasAnimated.current = true;

    const duration = 800;
    const start = performance.now();
    const animate = (now: number) => {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      // Ease out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      setDisplayScore(Math.round(eased * overallScore));
      if (progress < 1) requestAnimationFrame(animate);
    };
    requestAnimationFrame(animate);
  }, [overallScore, isPending]);

  return (
    <div className="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-xs text-gray-400 uppercase tracking-wider font-medium mb-1">
            Attempt #{attemptNumber} · {new Date(submittedAt).toLocaleDateString()}
          </p>
          <div className="flex items-center gap-3 mb-4">
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold ${verdict.bg} ${verdict.color}`}>
              {isPending ? 'Evaluating…' : verdict.label}
            </span>
            {hasIntegrityDeduction && (
              <span className="inline-flex items-center gap-1 text-xs text-rose-600 bg-rose-50 border border-rose-200 px-2 py-1 rounded-full">
                ⚠ Integrity deduction applied
              </span>
            )}
          </div>

          {overallSignal && !isPending && (
            <p className="text-sm text-gray-700 leading-relaxed mb-2">
              <span className="font-medium text-emerald-700">↑ </span>
              {overallSignal}
            </p>
          )}
          {overallWeakness && !isPending && (
            <p className="text-sm text-gray-600 leading-relaxed">
              <span className="font-medium text-amber-700">↓ </span>
              {overallWeakness}
            </p>
          )}

          {isPending && (
            <div className="space-y-2">
              <div className="h-4 bg-gray-100 rounded animate-pulse w-3/4" />
              <div className="h-4 bg-gray-100 rounded animate-pulse w-1/2" />
            </div>
          )}
        </div>

        {/* Score ring */}
        <div className="shrink-0 ml-6">
          <ScoreRing
            score={isPending ? null : displayScore}
            adjustedScore={hasIntegrityDeduction ? overallAdjustedScore : null}
          />
        </div>
      </div>
    </div>
  );
}

function ScoreRing({ score, adjustedScore }: { score: number | null; adjustedScore: number | null }) {
  const radius = 40;
  const circumference = 2 * Math.PI * radius;
  const progress = score !== null ? (score / 100) * circumference : 0;

  return (
    <div className="flex flex-col items-center">
      <div className="relative w-24 h-24">
        <svg className="w-24 h-24 -rotate-90" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r={radius} fill="none" stroke="#f3f4f6" strokeWidth="8" />
          <circle
            cx="50" cy="50" r={radius}
            fill="none"
            stroke={score !== null && score >= 70 ? '#6366f1' : score !== null && score >= 50 ? '#f59e0b' : '#9ca3af'}
            strokeWidth="8"
            strokeDasharray={circumference}
            strokeDashoffset={circumference - progress}
            strokeLinecap="round"
            style={{ transition: 'stroke-dashoffset 0.8s cubic-bezier(0.22, 1, 0.36, 1)' }}
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {score !== null ? (
            <span className="text-2xl font-bold text-gray-900">{score}</span>
          ) : (
            <span className="text-sm text-gray-400">…</span>
          )}
        </div>
      </div>
      {adjustedScore !== null && score !== null && (
        <span className="text-xs text-rose-600 mt-1">
          Adj. {adjustedScore}
        </span>
      )}
    </div>
  );
}
```

```tsx
// components/breakdown/BreakdownLanes.tsx
'use client';

import { useState } from 'react';
import type { SynthesizedLaneFeedback } from '@/lib/synthesis/feedback-synthesizer';

interface BreakdownLanesProps {
  lanes: SynthesizedLaneFeedback[];
  pendingLaneKeys: string[];
}

export function BreakdownLanes({ lanes, pendingLaneKeys }: BreakdownLanesProps) {
  return (
    <section>
      <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
        Lane Breakdown
      </h2>
      <div className="space-y-3">
        {lanes.map((lane) => (
          <LaneCard
            key={lane.laneKey}
            lane={lane}
            isPending={pendingLaneKeys.includes(lane.laneKey)}
          />
        ))}
      </div>
    </section>
  );
}

function LaneCard({ lane, isPending }: { lane: SynthesizedLaneFeedback; isPending: boolean }) {
  const [isExpanded, setIsExpanded] = useState(false);

  const scoreColor =
    lane.reconciledScore >= 70 ? 'text-indigo-600' :
    lane.reconciledScore >= 50 ? 'text-amber-600' :
    'text-gray-500';

  return (
    <div className="border border-gray-200 rounded-xl bg-white overflow-hidden">
      <button
        onClick={() => !isPending && setIsExpanded(!isExpanded)}
        disabled={isPending}
        className="w-full flex items-center justify-between px-5 py-4 text-left hover:bg-gray-50 transition-colors disabled:cursor-not-allowed"
        aria-expanded={isExpanded}
      >
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span className="font-semibold text-gray-900">{lane.displayName}</span>
            {lane.hasContradiction && (
              <span className="inline-flex items-center text-xs text-amber-700 bg-amber-50 border border-amber-200 px-1.5 py-0.5 rounded-full">
                Evaluators split
              </span>
            )}
            {lane.isLowEvidence && (
              <span className="inline-flex items-center text-xs text-gray-500 bg-gray-100 px-1.5 py-0.5 rounded-full">
                Limited data
              </span>
            )}
          </div>

          {/* Score bar */}
          <div className="flex items-center gap-3">
            <div className="flex-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
              {isPending ? (
                <div className="h-full bg-gray-200 animate-pulse rounded-full" style={{ width: '60%' }} />
              ) : (
                <div
                  className={`h-full rounded-full transition-all duration-700 ${
                    lane.reconciledScore >= 70 ? 'bg-indigo-500' :
                    lane.reconciledScore >= 50 ? 'bg-amber-400' : 'bg-gray-400'
                  }`}
                  style={{ width: `${lane.reconciledScore}%` }}
                />
              )}
            </div>
            <span className={`text-sm font-bold tabular-nums ${scoreColor} w-8 text-right`}>
              {isPending ? '…' : lane.reconciledScore}
            </span>
          </div>
        </div>

        {!isPending && (
          <svg
            className={`ml-4 w-4 h-4 text-gray-400 shrink-0 transition-transform ${isExpanded ? 'rotate-180' : ''}`}
            fill="none" viewBox="0 0 24 24" stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        )}
      </button>

      {isExpanded && !isPending && (
        <div className="px-5 pb-4 border-t border-gray-100 pt-3 space-y-3">
          {lane.hasContradiction && lane.contradictionSummary && (
            <div className="flex items-start gap-2 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-3 py-2">
              <span className="shrink-0">⚡</span>
              <span>{lane.contradictionSummary}</span>
            </div>
          )}

          {lane.positiveSignal && (
            <div>
              <p className="text-xs font-semibold text-emerald-700 uppercase tracking-wide mb-1">Strength</p>
              <p className="text-sm text-gray-700 leading-relaxed">{lane.positiveSignal}</p>
            </div>
          )}

          {lane.primaryWeakness && (
            <div>
              <p className="text-xs font-semibold text-amber-700 uppercase tracking-wide mb-1">To Improve</p>
              <p className="text-sm text-gray-700 leading-relaxed">{lane.primaryWeakness}</p>
            </div>
          )}

          {lane.fallbackReason && !lane.positiveSignal && !lane.primaryWeakness && (
            <p className="text-sm text-gray-500 italic">{lane.fallbackReason}</p>
          )}
        </div>
      )}
    </div>
  );
}
```

```tsx
// components/breakdown/BreakdownNextSteps.tsx
'use client';

import type { SynthesizedLaneFeedback } from '@/lib/synthesis/feedback-synthesizer';

interface BreakdownNextStepsProps {
  lanes: SynthesizedLaneFeedback[];
}

interface NextStep {
  laneKey: string;
  displayName: string;
  action: string;
  priority: 'high' | 'medium';
}

function generateNextSteps(lanes: SynthesizedLaneFeedback[]): NextStep[] {
  // Sort by score ascending — lowest scores get highest priority
  const sortedLanes = [...lanes]
    .filter((l) => l.reconciledScore > 0 && !l.isLowEvidence)
    .sort((a, b) => a.reconciledScore - b.reconciledScore);

  return sortedLanes.slice(0, 3).map((lane, i) => {
    const priority = i === 0 ? 'high' : 'medium';
    let action = '';

    if (lane.reconciledScore < 40) {
      action = `Focus on fundamentals in ${lane.displayName} — your score of ${lane.reconciledScore} suggests the core approach needs revision. Review the scoring criteria for this lane to understand what "adequate" looks like.`;
    } else if (lane.reconciledScore < 60) {
      action = `In ${lane.displayName} (${lane.reconciledScore}), you're close to the adequate threshold. ${lane.primaryWeakness ?? 'Targeted practice in this area will close the gap quickly.'}`;
    } else {
      action = `${lane.displayName} scored ${lane.reconciledScore} — solid but there's room to reach the strong tier (70+). ${lane.primaryWeakness ?? 'Review where points were left on the table.'}`;
    }

    return { laneKey: lane.laneKey, displayName: lane.displayName, action, priority };
  });
}

export function BreakdownNextSteps({ lanes }: BreakdownNextStepsProps) {
  const steps = generateNextSteps(lanes);

  if (steps.length === 0) return null;

  return (
    <section>
      <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
        Next Steps
      </h2>
      <div className="bg-white border border-gray-200 rounded-xl divide-y divide-gray-100">
        {steps.map((step, i) => (
          <div key={step.laneKey} className="px-5 py-4 flex items-start gap-3">
            <span className={`shrink-0 w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold mt-0.5 ${
              step.priority === 'high'
                ? 'bg-rose-100 text-rose-700'
                : 'bg-gray-100 text-gray-600'
            }`}>
              {i + 1}
            </span>
            <p className="text-sm text-gray-700 leading-relaxed">{step.action}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
```

---

## Anti-Patterns

### Anti-Pattern 1: One monolithic component

```tsx
// ❌ BAD: impossible to test, maintain, or progressively render
export function BreakdownPage({ submissionId }: { submissionId: string }) {
  const [data, setData] = useState(null);
  // ...1000 lines of JSX with score ring, lanes, next steps, evidence all inline
  return <div>...everything in one tree...</div>;
}

// ✅ GOOD: each section is independently renderable with its own loading state
// BreakdownHeader — can load with just overallScore
// BreakdownLanes — can render individually as each lane completes
// BreakdownNextSteps — only renders when lanes array is complete
// Each component has its own Storybook story
```

### Anti-Pattern 2: Spinner-only loading state

```tsx
// ❌ BAD: user sees blank screen + spinner; feels broken
if (loading) return <div className="flex justify-center"><Spinner /></div>;

// ✅ GOOD: skeleton that mirrors the page structure
export function BreakdownSkeleton() {
  return (
    <div className="max-w-3xl mx-auto px-4 py-8 space-y-8">
      {/* Header skeleton */}
      <div className="bg-white border border-gray-200 rounded-2xl p-6">
        <div className="flex justify-between">
          <div className="space-y-2 flex-1">
            <div className="h-3 bg-gray-100 rounded animate-pulse w-32" />
            <div className="h-6 bg-gray-100 rounded animate-pulse w-24" />
            <div className="h-4 bg-gray-100 rounded animate-pulse w-3/4 mt-3" />
            <div className="h-4 bg-gray-100 rounded animate-pulse w-1/2" />
          </div>
          <div className="w-24 h-24 bg-gray-100 rounded-full animate-pulse ml-6" />
        </div>
      </div>
      {/* Lane skeletons */}
      {[1, 2, 3].map((i) => (
        <div key={i} className="bg-white border border-gray-200 rounded-xl p-5">
          <div className="h-4 bg-gray-100 rounded animate-pulse w-1/3 mb-3" />
          <div className="h-2 bg-gray-100 rounded-full animate-pulse" />
        </div>
      ))}
    </div>
  );
}
```

### Anti-Pattern 3: Showing percentile during open window

```tsx
// ❌ BAD: "You're in the top 34%" during open window — number changes every hour
<BreakdownRelativeContext submissionId={submissionId} />

// ✅ GOOD: check rank status before showing
export function BreakdownRelativeContext({ submissionId, boutId }: Props) {
  const { rankStatus, percentile } = useRankStatus(submissionId, boutId);

  if (rankStatus === 'provisional' || rankStatus === null) {
    return (
      <div className="border border-dashed border-gray-200 rounded-xl px-5 py-4 text-sm text-gray-400">
        Rankings finalize when the window closes. Check back then for your percentile.
      </div>
    );
  }

  return <FinalRankDisplay percentile={percentile} />;
}
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Score animation fires on every re-render | Score flickers back to 0 and re-animates when state updates | Use `useRef(false)` to track `hasAnimated`; only fire once |
| Evidence panel renders empty when all refs are suppressed | Collapsed panel opens to blank space; user feels misled | If `allRefs.length === 0`, don't render the evidence panel toggle at all |
| Contradiction notice appears as global banner | User thinks their entire submission was contested, not just one lane | Scope `ContradictionNotice` inside `LaneCard`; never at page level |
| Next steps are generic ("practice more") | Users ignore them immediately; UX value is wasted | `generateNextSteps()` must reference `lane.displayName` and `lane.reconciledScore`; test output programmatically |
| Partial state renders lane cards as empty divs | Layout shift when data arrives; looks broken | Use skeleton card for pending lanes; maintain card height during loading |
| Adjusted score shown when there are no integrity deductions | User sees "Adjusted: 72" same as raw score; confusing | Only render adjusted score row when `overallAdjustedScore < overallScore` |
| Mobile layout has horizontal overflow | Lane cards extend past viewport; requires horizontal scroll | All cards must be `w-full` on mobile; test at 375px in Chrome devtools |
| Relative context shows with provisional rank | Percentile changes in real-time; user refreshes constantly; creates anxiety | `BreakdownRelativeContext` must check `rankStatus` before rendering percentile |
| `isPending` not passed to `ScoreRing` | Ring animates to 0 for pending lanes; looks like zero score | Pass `isPending` to `ScoreRing`; render placeholder instead of animated ring when pending |
| `generateNextSteps` crashes on empty lanes array | Next steps section throws; breakdown page breaks | Guard: return `[]` when `lanes.length === 0` |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
