---
name: confidence-layer-design
description: Expose when a judgment is high-confidence vs thin-evidence without undermining the platform's authority — covering the confidence trilemma, per-tier UI patterns, data model, copy patterns, and hard rules on when NOT to show confidence indicators.
---

# Confidence Layer Design

## Review Checklist

- [ ] Confidence badges are NEVER shown on aggregate scores or final rankings — check every location that renders `composite_score` or rank position
- [ ] `ConfidenceTier` type is defined centrally in `types/confidence.ts` and imported everywhere — no inline string literals `'high' | 'medium' | 'low'` scattered in components
- [ ] `low` confidence always renders an explicit caveat explaining WHY evidence was limited — not just a badge color
- [ ] `medium` confidence uses a subtle indicator only (icon or muted text) — not a prominent badge that draws attention
- [ ] `high` confidence renders NO badge — the absence of a badge implies confidence; confirm this is tested not assumed
- [ ] SQL confidence storage uses `JSONB` per-claim (not a single float for the whole output) — verify schema stores per-lane confidence
- [ ] Copy for `low` confidence caveats has been reviewed for tone: "Based on limited evidence" not "We're not sure" — no language that undermines the entire platform
- [ ] Confidence indicators are only shown at the lane/claim level, never at the overall submission level in list views or leaderboards
- [ ] The `ConfidenceCaveat` component is tested with very long caveat text (wraps gracefully) and empty string (renders nothing)
- [ ] When all lanes are high confidence, the confidence UI layer renders nothing — confirmed by snapshot test
- [ ] Confidence data survives judge retries — if a lane is reprocessed, the old confidence value is replaced, not appended
- [ ] Copy pattern library is co-located with the component in a `copy.ts` file — not hardcoded in JSX where it can't be reviewed in isolation

---

## The Confidence Trilemma — Why This Is Hard

Three approaches all fail in different ways:

**Show confidence everywhere:**
Users see a `medium` badge on a 7.5 score and immediately ask "why is this medium confidence? Is the 7.5 wrong?" The badge creates doubt about the score itself, not just the evidence. Users start gaming the system — submitting longer text to get `high` confidence badges rather than solving the actual challenge better.

**Hide confidence entirely:**
Platform feels like a black box. Sophisticated users (enterprise buyers, serious competitors) want to know the basis for scores. When a judge scores 3.0 on a lane where they had one thin sentence of evidence, hiding that feels dishonest. Trust erosion is slower but deeper.

**Fake high confidence uniformly:**
Catastrophic. Users will eventually submit something and see a confident 8.0 score on a lane where the submission had zero relevant content. One visible wrong high-confidence assessment destroys trust permanently. Don't do this.

**The resolution:**
Show confidence ONLY where it adds information — specifically, only when confidence is `medium` or `low`. High confidence is the baseline state. Showing a badge for `high` adds no information ("the platform is working normally"). Showing an indicator for `medium` or `low` says "something is different here, pay attention."

This is the same principle as error/warning UI: you don't show a green "success" indicator on every form field that has valid input. You only show a red indicator when something needs attention.

**When NOT to show confidence indicators (enforced by code, not just guidelines):**
- Aggregate/composite scores
- Final rankings and leaderboard positions
- List/card views of bouts (only show in detail view)
- When ALL lanes are high confidence (suppress the entire layer)
- For the final prize pool determination — the system acts on the score; confidence is informational only

---

## TypeScript Confidence Tier Types

```typescript
// types/confidence.ts

export type ConfidenceTier = 'high' | 'medium' | 'low';

export interface LaneConfidence {
  tier: ConfidenceTier;
  evidenceCount: number;
  caveatText: string | null; // null when tier is 'high' — no caveat needed
  suppressDisplay: boolean; // true when tier is 'high' — don't render anything
}

export interface JudgeOutputConfidence {
  laneConfidences: Record<string, LaneConfidence>;
  hasAnyLowOrMedium: boolean; // pre-computed — used to decide whether to render confidence layer at all
}

// Compute confidence tier from evidence count and other signals
export function computeConfidenceTier(params: {
  evidenceCount: number;
  feedbackWordCount: number;
  specificityScore: number;
  hasDirectQuotes: boolean;
}): ConfidenceTier {
  const { evidenceCount, feedbackWordCount, specificityScore, hasDirectQuotes } = params;

  // Low confidence: very thin evidence
  if (evidenceCount === 0) return 'low';
  if (feedbackWordCount < 30 && evidenceCount <= 1) return 'low';
  if (specificityScore < 0.25) return 'low';

  // High confidence: strong, grounded evidence
  if (evidenceCount >= 3 && specificityScore >= 0.7 && hasDirectQuotes) return 'high';
  if (evidenceCount >= 5 && specificityScore >= 0.6) return 'high';
  if (evidenceCount >= 4 && feedbackWordCount >= 100 && specificityScore >= 0.6) return 'high';

  // Medium: everything else
  return 'medium';
}

export function buildJudgeOutputConfidence(
  laneData: Record<string, {
    evidenceCount: number;
    feedbackWordCount: number;
    specificityScore: number;
    hasDirectQuotes: boolean;
  }>,
  getCopyForLane: (lane: string, tier: ConfidenceTier) => string | null
): JudgeOutputConfidence {
  const laneConfidences: Record<string, LaneConfidence> = {};
  let hasAnyLowOrMedium = false;

  for (const [lane, signals] of Object.entries(laneData)) {
    const tier = computeConfidenceTier(signals);
    if (tier !== 'high') hasAnyLowOrMedium = true;

    laneConfidences[lane] = {
      tier,
      evidenceCount: signals.evidenceCount,
      caveatText: tier === 'high' ? null : getCopyForLane(lane, tier),
      suppressDisplay: tier === 'high',
    };
  }

  return { laneConfidences, hasAnyLowOrMedium };
}
```

**Copy Pattern Library**

```typescript
// components/confidence/copy.ts

import type { ConfidenceTier } from '@/types/confidence';

// Tone principles:
// - Never say "we're not sure" — implies uncertainty about the score itself
// - Say "based on limited evidence in this lane" — scopes the uncertainty to evidence availability
// - Never apologize — "Unfortunately, the submission didn't..." is weak
// - Frame as informational, not as apology: "The score reflects what was present in the submission"

const LANE_DISPLAY_NAMES: Record<string, string> = {
  planning: 'Planning',
  execution: 'Execution',
  reasoning: 'Reasoning',
  communication: 'Communication',
  adaptability: 'Adaptability',
};

export function getConfidenceCopy(lane: string, tier: ConfidenceTier): string | null {
  const laneName = LANE_DISPLAY_NAMES[lane] ?? lane;

  if (tier === 'high') return null;

  if (tier === 'medium') {
    // Subtle acknowledgment — used as tooltip/subtext, not a prominent warning
    return `Score is based on moderate evidence in this lane.`;
  }

  if (tier === 'low') {
    // Explicit caveat — rendered as a visible callout below the score
    return `Based on limited evidence in the ${laneName} lane. The submission had few clear examples for this dimension — the score reflects what was present.`;
  }

  return null;
}

// For UI with dynamic lane name substitution
export function getLowConfidenceExplainer(lane: string, evidenceCount: number): string {
  const laneName = LANE_DISPLAY_NAMES[lane] ?? lane;

  if (evidenceCount === 0) {
    return `The ${laneName} score is based on inferred signals only — no direct evidence was identified in the submission for this dimension.`;
  }

  return `Based on ${evidenceCount === 1 ? 'a single evidence point' : `${evidenceCount} evidence points`} in the ${laneName} lane. Limited visibility means this score has lower precision than other lanes.`;
}
```

---

## SQL Confidence Storage Schema

Confidence is stored per-claim (per-lane per-judge output) in the `judge_outputs.confidence_scores` JSONB column AND materialized in a queryable table for analytics.

```sql
-- Confidence stored inline in judge_outputs (already in the schema)
-- confidence_scores: { "planning": "high", "execution": "medium", "reasoning": "low" }
-- This is fast to read per-submission but not queryable for aggregate analysis

-- Separate queryable table for confidence analytics
CREATE TABLE judge_lane_confidence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_output_id UUID NOT NULL REFERENCES judge_outputs(id) ON DELETE CASCADE,
  submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  judge_id TEXT NOT NULL,
  lane TEXT NOT NULL,
  confidence_tier TEXT NOT NULL CHECK (confidence_tier IN ('high', 'medium', 'low')),
  evidence_count INTEGER NOT NULL DEFAULT 0,
  specificity_score FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lane_confidence_submission ON judge_lane_confidence(submission_id);
CREATE INDEX idx_lane_confidence_tier ON judge_lane_confidence(judge_id, lane, confidence_tier);
CREATE INDEX idx_lane_confidence_created ON judge_lane_confidence(created_at DESC);

-- Query: What % of outputs have low-confidence lanes per judge?
SELECT
  judge_id,
  lane,
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE confidence_tier = 'low') AS low_count,
  COUNT(*) FILTER (WHERE confidence_tier = 'medium') AS medium_count,
  COUNT(*) FILTER (WHERE confidence_tier = 'high') AS high_count,
  ROUND(
    COUNT(*) FILTER (WHERE confidence_tier = 'low')::FLOAT / COUNT(*) * 100,
    1
  ) AS pct_low
FROM judge_lane_confidence
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY judge_id, lane
ORDER BY judge_id, pct_low DESC;
```

**Trigger to populate `judge_lane_confidence` when `judge_outputs` is inserted**

```sql
CREATE OR REPLACE FUNCTION sync_lane_confidence()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Delete existing confidence records for this output (handles retries/updates)
  DELETE FROM judge_lane_confidence WHERE judge_output_id = NEW.id;

  -- Re-insert from the JSONB confidence_scores column
  IF NEW.confidence_scores IS NOT NULL THEN
    INSERT INTO judge_lane_confidence (
      judge_output_id, submission_id, judge_id, lane, confidence_tier
    )
    SELECT
      NEW.id,
      NEW.submission_id,
      NEW.judge_id,
      key AS lane,
      value::TEXT AS confidence_tier
    FROM jsonb_each_text(NEW.confidence_scores);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_lane_confidence
  AFTER INSERT OR UPDATE OF confidence_scores ON judge_outputs
  FOR EACH ROW EXECUTE FUNCTION sync_lane_confidence();
```

---

## TSX Confidence Indicator Components

```tsx
// components/confidence/ConfidenceIndicator.tsx
'use client';

import { InformationCircleIcon } from '@heroicons/react/24/outline';
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip';
import type { LaneConfidence } from '@/types/confidence';

interface ConfidenceIndicatorProps {
  confidence: LaneConfidence;
  lane: string;
}

export function ConfidenceIndicator({ confidence, lane }: ConfidenceIndicatorProps) {
  // High confidence: render nothing — absence of badge implies confidence
  if (confidence.suppressDisplay || confidence.tier === 'high') return null;

  if (confidence.tier === 'medium') {
    return (
      <Tooltip>
        <TooltipTrigger asChild>
          <span className="inline-flex items-center gap-0.5 text-xs text-gray-400 cursor-help">
            <InformationCircleIcon className="h-3.5 w-3.5" />
            <span>Moderate evidence</span>
          </span>
        </TooltipTrigger>
        <TooltipContent side="top" className="max-w-xs text-xs">
          {confidence.caveatText}
        </TooltipContent>
      </Tooltip>
    );
  }

  // Low confidence: explicit visible caveat
  return (
    <div className="mt-2 px-3 py-2 bg-gray-50 border border-gray-200 rounded text-xs text-gray-600">
      <div className="flex items-start gap-2">
        <InformationCircleIcon className="h-4 w-4 text-gray-400 shrink-0 mt-0.5" />
        <span>{confidence.caveatText}</span>
      </div>
    </div>
  );
}
```

**LaneScoreWithConfidence — Full lane row component**

```tsx
// components/feedback/LaneScoreWithConfidence.tsx
'use client';

import { ConfidenceIndicator } from '@/components/confidence/ConfidenceIndicator';
import type { LaneConfidence } from '@/types/confidence';
import { cn } from '@/lib/utils';

interface LaneScoreWithConfidenceProps {
  lane: string;
  displayName: string;
  score: number;
  maxScore: number;
  confidence: LaneConfidence;
  feedbackText?: string;
}

export function LaneScoreWithConfidence({
  lane,
  displayName,
  score,
  maxScore,
  confidence,
  feedbackText,
}: LaneScoreWithConfidenceProps) {
  const scorePercent = (score / maxScore) * 100;
  const scoreColor = scorePercent >= 80 ? 'text-green-600'
    : scorePercent >= 60 ? 'text-yellow-600'
    : 'text-red-600';

  return (
    <div className="space-y-2 py-3 border-b border-gray-100 last:border-0">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-gray-800">{displayName}</span>
          {/* Confidence indicator for medium tier — subtle, inline */}
          {confidence.tier === 'medium' && (
            <ConfidenceIndicator confidence={confidence} lane={lane} />
          )}
        </div>
        <span className={cn('text-sm font-semibold font-mono', scoreColor)}>
          {score.toFixed(1)}/{maxScore}
        </span>
      </div>

      {/* Progress bar */}
      <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
        <div
          className={cn(
            'h-full rounded-full transition-all duration-700',
            scorePercent >= 80 ? 'bg-green-500'
              : scorePercent >= 60 ? 'bg-yellow-500'
              : 'bg-red-400'
          )}
          style={{ width: `${scorePercent}%` }}
        />
      </div>

      {/* Feedback text */}
      {feedbackText && (
        <p className="text-sm text-gray-600">{feedbackText}</p>
      )}

      {/* Low confidence caveat — explicit, below feedback */}
      {confidence.tier === 'low' && (
        <ConfidenceIndicator confidence={confidence} lane={lane} />
      )}
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Showing confidence badge on composite score

```tsx
// BAD — the composite score aggregates across lanes;
// showing a confidence badge on it is meaningless (which lane is uncertain?)
// and undermines the platform's credibility on the number users care most about
<div className="flex items-center gap-2">
  <span className="text-2xl font-bold">{compositeScore}</span>
  <ConfidenceBadge tier={overallConfidence} /> {/* NEVER do this */}
</div>
```

```tsx
// GOOD — confidence only shown at lane level, never at composite level
<div>
  <span className="text-2xl font-bold">{compositeScore}</span>
  {/* No confidence indicator here — composite score stands alone */}
</div>
{/* Individual lanes show confidence when needed */}
{lanes.map(lane => (
  <LaneScoreWithConfidence key={lane.id} {...lane} confidence={lane.confidence} />
))}
```

---

### ❌ Anti-Pattern 2: Using "we're not sure" copy language

```tsx
// BAD — "we're not sure" undermines the score itself, not just the evidence basis
const caveatText = confidence.tier === 'low'
  ? "We're not fully confident in this score due to limited submission content."
  : null;
// User reads this as: "The 4.5 score might be wrong"
// Trust destroyed.
```

```tsx
// GOOD — frames uncertainty as evidence availability, not score validity
const caveatText = confidence.tier === 'low'
  ? `Based on limited evidence in the ${laneName} lane. The submission had few clear examples for this dimension — the score reflects what was present.`
  : confidence.tier === 'medium'
  ? `Score is based on moderate evidence in this lane.`
  : null;
// User reads: "They scored what was there. The submission just didn't show much here."
// Score authority preserved.
```

---

### ❌ Anti-Pattern 3: Showing confidence indicator when all lanes are high confidence

```tsx
// BAD — renders a "Confidence" section header with no content
// User wonders "why did they have a confidence section with nothing in it?"
<section>
  <h3>Score Confidence</h3>
  {lanes.map(lane => (
    <ConfidenceIndicator key={lane.id} confidence={lane.confidence} />
    // All return null, section header is orphaned
  ))}
</section>
```

```tsx
// GOOD — suppress entire section when nothing needs display
const hasAnyConfidenceToShow = judgeConfidence.hasAnyLowOrMedium;

return hasAnyConfidenceToShow ? (
  <section>
    <h3>Score Notes</h3>
    {lanes.map(lane => (
      <ConfidenceIndicator key={lane.id} confidence={lane.confidence} />
    ))}
  </section>
) : null;
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Confidence badge shown on leaderboard rank position | "You ranked #3 (medium confidence)" — implies ranking itself is uncertain | Only show confidence in the detailed breakdown view, never in list/rank views |
| All three tiers rendered with visual badges | High confidence gets a green badge — wastes cognitive space, de-emphasizes real warnings | High = no render; medium = subtle icon only; low = explicit caveat |
| Copy says "uncertain" or "not sure" | Users question whether to trust the score value, not just the evidence | Use "limited evidence" framing; keep score authority intact |
| Confidence stored as a single float (0.0–1.0) per submission | Can't show per-lane confidence; must bucketize at render time which is lossy | Store as JSONB `{ "planning": "high", "execution": "low" }` per lane |
| `hasAnyLowOrMedium` computed in TSX render instead of server | Triggers re-render cascade; complex conditional logic in JSX | Pre-compute in TypeScript layer, pass as boolean prop |
| Trigger doesn't handle UPDATE — only INSERT | Judge retry updates `confidence_scores`; old `judge_lane_confidence` rows persist | Use `AFTER INSERT OR UPDATE OF confidence_scores` in trigger definition |
| `computeConfidenceTier` called with `specificityScore = undefined` | Falls through all conditions; returns 'medium' for everything by accident | Add `specificityScore ?? 0` default in function signature |
| Low confidence caveat shown with empty string | Renders as `<div>` with no text — confusing whitespace | Guard: `if (confidence.tier === 'low' && confidence.caveatText)` before rendering caveat |
| Confidence copy hardcoded in JSX string literals | 47 different places have slight copy variations; impossible to audit | Co-locate all copy in `components/confidence/copy.ts`, import everywhere |
| Medium confidence uses same red color as low | Users treat all non-high scores as warnings; expand rate spikes on low-value lanes | Medium = gray/muted; Low = amber border box (never red — red implies error, not thin evidence) |

---

## Changelog
- 2026-03-31: Created for Bouts confidence layer design build
