---
name: competitive-product-psychology
description: What users actually need after losing or winning a competitive AI evaluation — emotional state design for winners, close misses, and clear losses, with TSX layout and copy patterns that make feedback feel fair rather than algorithmic.
---

# Competitive Product Psychology

## Review Checklist

- [ ] **Losing users see acknowledgment of effort before they see the gap** — the sequence matters: what they did well → what cost them → gap to top → next step
- [ ] **Close-miss users (ranked N+1 where N = prize cutoff) get specific handling** — not the same template as 10th place
- [ ] **Winning users get validation first, then growth signal** — never lead with "what you could improve" for a winner
- [ ] **Feedback copy is written for the emotional state, not just the ranking** — test with a real user who just lost; does it feel condescending, dismissive, or fair?
- [ ] **No score is shown without context** — "72.4" means nothing; "72.4 — above median, 8 points from the prize line" means something
- [ ] **The word "unfortunately" never appears in feedback copy** — it signals pity, not respect
- [ ] **Generic phrases are eliminated**: no "good job", no "room for improvement", no "keep trying" — all copy is specific
- [ ] **The one concrete next step is framed as an upgrade, not a correction** — "strengthen X" not "fix X"
- [ ] **Close-miss copy acknowledges the specific number of points** between their score and the prize cutoff
- [ ] **Winner copy mentions the specific competitive advantage** that put them on top — not just "you won"
- [ ] **All emotional state copy is AB-testable** — the text strings are in config/constants, not hardcoded in JSX
- [ ] **The fair-feeling sequence component is reusable** — can be used with any submission result

---

## The Emotional States: What Users Actually Feel

Competition results trigger one of four emotional states. Each demands different UX.

### State 1: Winner (Rank 1 or prize-winning)
**Emotional state**: Pride + validation + mild anxiety (will I be able to repeat this?)
**What they need first**: Explicit acknowledgment that this is a real achievement, not luck
**What they need second**: Specific evidence of what made them win (so they can repeat it)
**What they do NOT need**: Immediate critique or "areas for growth" — this dilutes the win

**Trigger words to avoid**: "Even though you won…", "You could improve…" (before celebrating)

### State 2: Close Miss (Rank = prize_positions + 1 or prize_positions + 2)
**Emotional state**: Acute frustration — "I was SO CLOSE"
**What makes it uniquely painful**: They can see exactly how many points they needed. The prize was tangible.
**What they need**: Acknowledgment of the specific gap, not a generic "so close!" — quantify it
**What they do NOT need**: Platitudes. "You almost got it!" triggers rage in close-miss users.

**The close-miss user is your most valuable user**: they are highly motivated to improve and re-enter. If you handle this wrong, they churn. If you handle it right, they become regulars.

### State 3: Middle-field loss (Rank > prize_positions + 2, but not bottom 20%)
**Emotional state**: Disappointment, mixed with genuine curiosity about what went wrong
**What they need**: A clear, specific explanation of the gap, with at least one thing they did well
**What they do NOT need**: "Sorry you didn't win" — this is condescending; they know

### State 4: Bottom-field (Bottom 20% of field)
**Emotional state**: Embarrassment + possible question of whether the evaluation was fair
**What they need**: Dignity first — acknowledge the attempt; then one specific, actionable insight
**What they do NOT need**: Comparisons to how far above them the median was — this crushes motivation

---

## The Fair-Feeling Sequence

Research in feedback psychology shows that the ORDER of information determines whether feedback feels fair, regardless of content. This is the sequence that consistently produces the "fair" response:

```
1. Acknowledge what they did well (specific, not generic)
2. Explain what cost them (the exact thing, with evidence)
3. Show the gap to top (quantified, contextual)
4. Give one concrete next step (upgrade framing, not correction)
```

Reversing this sequence (starting with the gap) triggers defensive rejection. The feedback is identical — the order is what makes it land.

```tsx
// components/feedback/FairFeedbackLayout.tsx
'use client';

import React from 'react';
import { cn } from '@/lib/utils';

export interface FairFeedbackProps {
  // Step 1: What they did well
  strength: {
    headline: string;       // e.g., "Strong execution in the planning phase"
    detail: string;         // e.g., "Your agent correctly identified all 4 constraints before attempting a solution."
    laneId?: string;        // link to the lane this came from
    score?: number;
    maxScore?: number;
  };
  // Step 2: What cost them
  primaryGap: {
    headline: string;       // e.g., "Verification was the deciding factor"
    detail: string;         // specific explanation
    evidenceQuote?: string; // direct quote from judge
    laneId?: string;
    scoreActual?: number;
    scorePossible?: number;
  };
  // Step 3: Gap to top
  fieldContext: {
    userScore: number;
    topScore: number;
    prizeThreshold: number | null;
    userRank: number;
    totalParticipants: number;
    pointsFromPrize: number | null;
  };
  // Step 4: Next step
  nextStep: {
    action: string;   // "Focus your next submission on explicit verification steps"
    rationale: string; // "Verification was the differentiating factor for 3 of the top 5 finishers"
  };
  // Context
  outcomeType: 'winner' | 'close-miss' | 'loss' | 'bottom';
}

export function FairFeedbackLayout({
  strength,
  primaryGap,
  fieldContext,
  nextStep,
  outcomeType,
}: FairFeedbackProps) {
  return (
    <div className="space-y-4">
      {/* Step 1: Strength — always first */}
      <StrengthCard strength={strength} outcomeType={outcomeType} />

      {/* Step 2: Primary gap — only for non-winners */}
      {outcomeType !== 'winner' && (
        <GapCard gap={primaryGap} />
      )}

      {/* Step 3: Field context */}
      <FieldContextCard context={fieldContext} outcomeType={outcomeType} />

      {/* Step 4: Next step */}
      <NextStepCard step={nextStep} outcomeType={outcomeType} />
    </div>
  );
}

// ─── Step 1: Strength Card ────────────────────────────────────────────────────

function StrengthCard({
  strength,
  outcomeType,
}: {
  strength: FairFeedbackProps['strength'];
  outcomeType: FairFeedbackProps['outcomeType'];
}) {
  // Winners get a more prominent treatment — green border, larger text
  const isWinner = outcomeType === 'winner';

  return (
    <div className={cn(
      'rounded-xl p-5 border',
      isWinner
        ? 'bg-emerald-50 border-emerald-200'
        : 'bg-white border-gray-200'
    )}>
      <div className="flex items-start gap-3">
        <div className={cn(
          'mt-0.5 h-8 w-8 shrink-0 rounded-lg flex items-center justify-center text-lg',
          isWinner ? 'bg-emerald-100' : 'bg-gray-100'
        )}>
          {isWinner ? '🏆' : '✓'}
        </div>
        <div className="min-w-0">
          <p className={cn(
            'font-semibold',
            isWinner ? 'text-emerald-900 text-base' : 'text-gray-900 text-sm'
          )}>
            {strength.headline}
          </p>
          <p className={cn(
            'mt-1 leading-relaxed',
            isWinner ? 'text-sm text-emerald-800' : 'text-sm text-gray-600'
          )}>
            {strength.detail}
          </p>
          {strength.score !== undefined && strength.maxScore !== undefined && (
            <p className={cn('text-xs mt-2', isWinner ? 'text-emerald-600' : 'text-gray-400')}>
              {strength.score}/{strength.maxScore} in this lane
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Step 2: Gap Card ──────────────────────────────────────────────────────────

function GapCard({ gap }: { gap: FairFeedbackProps['primaryGap'] }) {
  return (
    <div className="rounded-xl p-5 bg-white border border-gray-200">
      <div className="flex items-start gap-3">
        <div className="mt-0.5 h-8 w-8 shrink-0 rounded-lg bg-amber-50 flex items-center justify-center text-lg">
          ↑
        </div>
        <div className="min-w-0">
          <p className="text-sm font-semibold text-gray-900">{gap.headline}</p>
          <p className="text-sm text-gray-600 mt-1 leading-relaxed">{gap.detail}</p>
          {gap.evidenceQuote && (
            <blockquote className="mt-3 text-xs text-gray-500 italic pl-3 border-l-2 border-amber-200">
              "{gap.evidenceQuote}"
            </blockquote>
          )}
          {gap.scoreActual !== undefined && gap.scorePossible !== undefined && (
            <p className="text-xs text-gray-400 mt-2">
              Scored {gap.scoreActual}/{gap.scorePossible} here
              {gap.scorePossible - gap.scoreActual > 0 && (
                <span className="text-amber-600">
                  {' '}— {gap.scorePossible - gap.scoreActual} points available
                </span>
              )}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Step 3: Field Context Card ───────────────────────────────────────────────

function FieldContextCard({
  context,
  outcomeType,
}: {
  context: FairFeedbackProps['fieldContext'];
  outcomeType: FairFeedbackProps['outcomeType'];
}) {
  const isCloseMiss = outcomeType === 'close-miss';
  const isWinner = outcomeType === 'winner';

  return (
    <div className={cn(
      'rounded-xl p-5 border',
      isCloseMiss ? 'bg-amber-50 border-amber-200' : 'bg-gray-50 border-gray-200'
    )}>
      <p className={cn(
        'text-xs font-semibold uppercase tracking-wide mb-3',
        isCloseMiss ? 'text-amber-600' : 'text-gray-400'
      )}>
        Where you stood
      </p>
      <div className="flex items-end gap-4">
        <div>
          <span className={cn(
            'text-2xl font-bold tabular-nums',
            isWinner ? 'text-emerald-700' : isCloseMiss ? 'text-amber-700' : 'text-gray-900'
          )}>
            {context.userScore.toFixed(1)}
          </span>
          <span className="text-sm text-gray-400 ml-1">your score</span>
        </div>
        {context.pointsFromPrize !== null && context.pointsFromPrize > 0 && (
          <div className="text-sm">
            <span className={cn('font-semibold', isCloseMiss ? 'text-amber-700' : 'text-gray-600')}>
              {context.pointsFromPrize.toFixed(1)} points
            </span>
            <span className="text-gray-400"> from the prize line</span>
          </div>
        )}
      </div>

      {/* Close-miss specific copy */}
      {isCloseMiss && context.pointsFromPrize !== null && (
        <p className="text-sm text-amber-700 mt-3 font-medium">
          You needed {context.pointsFromPrize.toFixed(1)} more points.
          That's a meaningful gap — but it's a focused one.
        </p>
      )}

      {/* Winner specific copy */}
      {isWinner && (
        <p className="text-sm text-emerald-700 mt-3 font-medium">
          You led the field by {(context.userScore - context.prizeThreshold!).toFixed(1)} points.
          Rank #{context.userRank} of {context.totalParticipants}.
        </p>
      )}

      {!isCloseMiss && !isWinner && (
        <p className="text-xs text-gray-500 mt-2">
          Rank #{context.userRank} of {context.totalParticipants} ·{' '}
          Top score: {context.topScore.toFixed(1)}
        </p>
      )}
    </div>
  );
}

// ─── Step 4: Next Step Card ───────────────────────────────────────────────────

function NextStepCard({
  step,
  outcomeType,
}: {
  step: FairFeedbackProps['nextStep'];
  outcomeType: FairFeedbackProps['outcomeType'];
}) {
  const isWinner = outcomeType === 'winner';

  return (
    <div className="rounded-xl p-5 bg-indigo-50 border border-indigo-200">
      <p className="text-xs font-semibold uppercase tracking-wide text-indigo-400 mb-2">
        {isWinner ? 'Stay sharp' : 'Next move'}
      </p>
      <p className="text-sm font-semibold text-indigo-900">{step.action}</p>
      <p className="text-sm text-indigo-700 mt-1 leading-relaxed">{step.rationale}</p>
    </div>
  );
}
```

---

## Copy Patterns for Each Emotional State

These are the exact copy patterns. Import them from a constants file — never write outcome copy inline in JSX.

```typescript
// lib/feedback-copy.ts

export type OutcomeContext = {
  agentName: string;
  rank: number;
  totalParticipants: number;
  prizePositions: number;
  userScore: number;
  topScore: number;
  prizeThreshold: number | null;
  topLaneName: string;         // the lane they scored best in
  weakLaneName: string;        // the lane that cost them most
  pointsFromPrize: number | null;
};

export interface OutcomeCopy {
  pageTitle: string;
  strengthHeadline: string;
  strengthDetail: (ctx: OutcomeContext) => string;
  gapHeadline: string;
  gapDetail: (ctx: OutcomeContext) => string;
  nextStepAction: (ctx: OutcomeContext) => string;
  nextStepRationale: (ctx: OutcomeContext) => string;
}

export const OUTCOME_COPY: Record<'winner' | 'close-miss' | 'loss' | 'bottom', OutcomeCopy> = {
  winner: {
    pageTitle: 'You won.',
    strengthHeadline: 'What put you on top',
    strengthDetail: (ctx) =>
      `${ctx.agentName} outperformed ${ctx.totalParticipants - 1} other submissions in ${ctx.topLaneName}, ` +
      `which contributed more to your overall score than any other single lane.`,
    gapHeadline: '', // not used for winner
    gapDetail: () => '',
    nextStepAction: (ctx) =>
      `Study your ${ctx.topLaneName} approach — it was the differentiator.`,
    nextStepRationale: (ctx) =>
      `Your score in this area was ${(ctx.userScore - ctx.prizeThreshold!).toFixed(1)} points above the next competitor. ` +
      `Understanding why helps you repeat it.`,
  },

  'close-miss': {
    pageTitle: 'So close.',
    strengthHeadline: 'What worked',
    strengthDetail: (ctx) =>
      `${ctx.agentName} scored above the field average in ${ctx.topLaneName} and showed a clear strength ` +
      `in the areas the bout weighted most heavily.`,
    gapHeadline: `${ctx => ctx.weakLaneName} was the deciding factor`,
    gapDetail: (ctx) =>
      `The prize line was ${ctx.prizeThreshold?.toFixed(1) ?? '—'}. You scored ${ctx.userScore.toFixed(1)}. ` +
      `The ${ctx.pointsFromPrize?.toFixed(1) ?? '—'}-point gap came almost entirely from ${ctx.weakLaneName}.`,
    nextStepAction: (ctx) =>
      `Your next submission should target ${ctx.weakLaneName} specifically.`,
    nextStepRationale: (ctx) =>
      `If you close the gap in ${ctx.weakLaneName} by ${ctx.pointsFromPrize?.toFixed(1) ?? '—'} points, ` +
      `your overall score crosses the prize threshold.`,
  },

  loss: {
    pageTitle: 'Here's your breakdown.',
    strengthHeadline: 'What you got right',
    strengthDetail: (ctx) =>
      `${ctx.agentName} showed genuine competency in ${ctx.topLaneName}. ` +
      `This isn't a token observation — your score here ranked in the top half of the field.`,
    gapHeadline: 'What separated the top submissions',
    gapDetail: (ctx) =>
      `The submissions that placed in the top ${ctx.prizePositions} consistently excelled in ${ctx.weakLaneName}. ` +
      `Your score in this lane was the primary driver of the gap.`,
    nextStepAction: (ctx) =>
      `Rebuild your approach to ${ctx.weakLaneName} before your next submission.`,
    nextStepRationale: () =>
      `This is the single area where targeted effort will produce the largest score improvement.`,
  },

  bottom: {
    pageTitle: 'Your results.',
    strengthHeadline: 'Where you started',
    strengthDetail: (ctx) =>
      `Completing a Bouts submission puts ${ctx.agentName} in a tested group. ` +
      `Your strongest performance was in ${ctx.topLaneName} — there's a real foundation here.`,
    gapHeadline: 'The biggest opportunity',
    gapDetail: (ctx) =>
      `${ctx.weakLaneName} had the highest impact on your score. ` +
      `The top submissions handled this lane very differently.`,
    nextStepAction: (ctx) =>
      `Study how top submissions approached ${ctx.weakLaneName}.`,
    nextStepRationale: () =>
      `This single area accounts for more of the gap than everything else combined.`,
  },
};

// Utility to select outcome type from result data
export function getOutcomeType(
  rank: number,
  prizePositions: number,
  totalParticipants: number
): 'winner' | 'close-miss' | 'loss' | 'bottom' {
  if (rank <= prizePositions) return 'winner';
  if (rank <= prizePositions + 2) return 'close-miss';
  if (rank > totalParticipants * 0.8) return 'bottom';
  return 'loss';
}
```

---

## Anti-Patterns That Trigger Distrust

### ❌ Leading with the score for a losing user

```tsx
// BAD — the number is a gut punch before the context
<h1 className="text-4xl font-bold text-gray-900">
  Score: {result.overallScore}
</h1>
<p className="text-sm text-gray-500 mt-2">
  You scored in the bottom 30% of this bout.
</p>
// Only after this does the page show any positive feedback.
// Users stop reading after the gut punch.

// GOOD — strength first, always
<StrengthCard strength={derivedStrength} outcomeType="loss" />
// Score appears in the field context card AFTER strength
```

### ❌ Generic close-miss copy

```tsx
// BAD — "so close!" is perceived as condescending
<p>So close! You were just outside the prize positions.</p>

// GOOD — specific, quantified
<p>
  You needed {pointsFromPrize.toFixed(1)} more points.
  That's a meaningful gap — but it's a focused one.
</p>
```

### ❌ Sending winners straight to "improvements"

```tsx
// BAD — undermines the win immediately
function WinnerFeedback({ result }) {
  return (
    <div>
      <h2>Congratulations on winning!</h2>
      {/* Immediately jumps to critique */}
      <h3>Areas for improvement:</h3>
      <p>Even top submissions can improve in {weakLane}...</p>
    </div>
  );
}

// GOOD — validate fully first, growth comes last
function WinnerFeedback({ result }) {
  return (
    <FairFeedbackLayout
      // strength is rich and specific
      strength={{ headline: 'What put you on top', detail: specificWinDetail }}
      primaryGap={null} // no gap for winners
      fieldContext={context}
      // growth comes LAST, framed as staying sharp not fixing a problem
      nextStep={{ action: 'Study what made this work', rationale: specificRationale }}
      outcomeType="winner"
    />
  );
}
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| "Unfortunately" appears in any feedback copy | Triggers pity response, feels condescending | Ban the word; audit all copy with grep |
| Score shown before strength for losing users | Users close the page after seeing the number | Enforce FairFeedbackLayout sequence in all outcome pages |
| Same template for close-miss and 10th place | Close-miss users feel their situation isn't understood | `getOutcomeType()` must return `'close-miss'` for rank = prizePositions + 1 or +2 |
| Winner feedback shows "areas to improve" before "why you won" | Win feels hollow; users don't trust the platform's judgment | Winner page: strength section must be 100% positive; growth comes in nextStep only |
| Next step is vague: "improve your approach" | Users have nothing actionable | Next step must name a specific lane and explain why that lane |
| Gap shown in absolute points without context | "You needed 8.3 more points" — means nothing | Always add: "That's X% of the maximum available in that lane" |
| Bottom-quartile users compared to median | Doubles the humiliation without helping | Bottom users should compare to their own best, not the field |
| Copy hardcoded in JSX | Can't AB test or iterate copy without code deploys | Move all outcome copy to `lib/feedback-copy.ts` constants |
| No close-miss re-entry CTA | Your most motivated users leave without converting | Close-miss page must include a clear "Enter next bout" CTA |
| Feedback copy uses plural "judges say..." when only 1 judge ran | Factual error destroys trust in the whole page | Check `completeJudgeCount` before using plural; "The evaluation found…" is always safe |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
