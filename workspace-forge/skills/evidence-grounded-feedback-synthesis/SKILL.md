---
name: evidence-grounded-feedback-synthesis
description: Convert raw judge outputs into premium, evidence-anchored user feedback — with suppression rules, fallback logic, contradiction handling, and zero generic filler.
---

# Evidence-Grounded Feedback Synthesis

## Review Checklist

1. **Suppression gate is applied before any text is surfaced**: Every claim in the final feedback must pass through `SuppressorEngine.shouldSuppress()`. Test: inject a `confidence: 'low'` judge output and verify its `primary_weakness` is NOT in the rendered feedback.
2. **Corroboration check for negatives**: Any negative claim surfaced to the user must appear in at least 2 of N judges (or flagged as single-judge with a confidence caveat). Test: give Judge A a negative and Judges B/C positives on the same dimension — confirm the negative is suppressed or flagged.
3. **Contradiction handling renders visibly, not silently**: When two judges disagree on a lane by >25 points, the UI must show a "Judges disagreed" signal, not silently average. Query: `SELECT * FROM evaluation_reconciled_scores WHERE has_contradictions = true` — pick one and verify the UI shows the contradiction notice.
4. **Fallback copy is present for every lane**: If a lane has evidence_refs.length === 0 across all judges, the synthesis must return a fallback string (not empty, not `undefined`). Test: pass a judge output with empty evidence_refs to `synthesizeLaneFeedback()` and assert non-empty output.
5. **Generic phrase detector runs before text is committed**: Run `detectGenericPhrases()` on every synthesized string before storing. Test: pass "demonstrates a solid understanding of the problem" — expect at least one banned phrase match.
6. **Evidence refs are linked, not quoted in bulk**: Feedback text must reference evidence by ID/link, not paste the raw transcript. Verify: `synthesizeLaneFeedback()` returns `<EvidenceLink ref={ref} />` components, not raw excerpt strings.
7. **Positive signal is distinct from lane score text**: `positive_signal` must not be a restatement of "score was high on X". Add an assertion: `if (positiveSignal.toLowerCase().includes('score')) throw error`.
8. **Synthesis is idempotent**: Calling `synthesizeLaneFeedback()` twice with the same inputs returns identical output. Test this explicitly — synthesis must not make LLM calls (it's deterministic from stored data).
9. **Fallback does not leak raw judge IDs or model names to users**: The fallback copy must say "our evaluation system" not "Claude Opus scored you 45". Grep all fallback strings for model name patterns.
10. **Synthesis timing is measured**: Log `synthesis_duration_ms` for each feedback generation. If synthesis takes >500ms for a single lane, something is wrong (likely an accidental LLM call in synthesis path).
11. **Low-evidence lanes display "Limited data" notice**: When a lane has < 2 evidence_refs across all judges, show the notice. Verify this component renders in Storybook.
12. **Contradiction details stored for analytics, not just suppressed**: When a contradiction is detected, insert a row in `feedback_contradictions` — don't just hide it. This is future training data.

---

## Suppression Rules: What NEVER Gets Surfaced

Suppression is the most important concept in synthesis. The default is to show nothing. Evidence earns the right to be surfaced.

### The Four Suppression Gates

**Gate 1: Confidence gate** — if the source judge has `confidence: 'low'`, nothing from that judge's qualitative output is surfaced (scores may still be used for averaging, but no text).

**Gate 2: Corroboration gate** — any negative claim must appear in ≥ 2 judges' outputs OR be accompanied by a critical flag (`severity: 'critical'`). A single judge's `primary_weakness` is not surfaced unless corroborated.

**Gate 3: Evidence gate** — any claim that has 0 `evidence_refs` is suppressed from the main feedback section. It may appear in a "Limited evaluation data" notice but never as a substantive claim.

**Gate 4: Generic gate** — any claim that matches the banned phrase list is suppressed and flagged for logging. See anti-generic skill for the full list.

```typescript
// lib/synthesis/suppressor.ts
import { detectGenericPhrases } from './generic-detector';
import type { JudgeOutput, DimensionScore } from '@/lib/judges/judge-output-schema';

export interface SuppressedClaim {
  text: string;
  reason: 'low_confidence' | 'not_corroborated' | 'no_evidence' | 'generic_phrase';
  judgeModel: string;
  laneKey?: string;
  dimensionKey?: string;
}

export interface SuppressionResult {
  shouldSuppress: boolean;
  reason?: SuppressedClaim['reason'];
}

export class SuppressorEngine {
  constructor(
    private readonly allJudgeOutputs: JudgeOutput[],
    private readonly requiredCorroborationCount: number = 2
  ) {}

  shouldSuppressWeakness(
    claim: string,
    sourceJudge: JudgeOutput,
    dimensionKey: string
  ): SuppressionResult {
    // Gate 1: confidence
    if (sourceJudge.confidence === 'low') {
      return { shouldSuppress: true, reason: 'low_confidence' };
    }

    // Gate 3: evidence
    const sourceDimScore = this.findDimensionScore(sourceJudge, dimensionKey);
    if (!sourceDimScore || sourceDimScore.evidence_refs.length === 0) {
      return { shouldSuppress: true, reason: 'no_evidence' };
    }

    // Gate 4: generic
    const genericMatches = detectGenericPhrases(claim);
    if (genericMatches.length > 0) {
      return { shouldSuppress: true, reason: 'generic_phrase' };
    }

    // Gate 2: corroboration for negatives
    // A "negative" claim is one where the dimension score is below 50
    if (sourceDimScore.score < 50) {
      const corroboratingJudges = this.allJudgeOutputs.filter((judge) => {
        if (judge.judge_model === sourceJudge.judge_model) return false;
        if (judge.confidence === 'low') return false;
        const theirDim = this.findDimensionScore(judge, dimensionKey);
        return theirDim && theirDim.score < 60; // within the "negative zone"
      });

      if (corroboratingJudges.length < this.requiredCorroborationCount - 1) {
        return { shouldSuppress: true, reason: 'not_corroborated' };
      }
    }

    return { shouldSuppress: false };
  }

  shouldSuppressPositive(
    claim: string,
    sourceJudge: JudgeOutput,
    dimensionKey: string
  ): SuppressionResult {
    // Positives have lower bar — still need evidence and non-generic text
    if (sourceJudge.confidence === 'low') {
      return { shouldSuppress: true, reason: 'low_confidence' };
    }

    const sourceDimScore = this.findDimensionScore(sourceJudge, dimensionKey);
    if (!sourceDimScore || sourceDimScore.evidence_refs.length === 0) {
      return { shouldSuppress: true, reason: 'no_evidence' };
    }

    const genericMatches = detectGenericPhrases(claim);
    if (genericMatches.length > 0) {
      return { shouldSuppress: true, reason: 'generic_phrase' };
    }

    return { shouldSuppress: false };
  }

  private findDimensionScore(
    judge: JudgeOutput,
    dimensionKey: string
  ): DimensionScore | undefined {
    for (const lane of judge.lane_scores) {
      for (const dim of lane.dimension_scores) {
        if (dim.dimension_key === dimensionKey) return dim;
      }
    }
    return undefined;
  }
}
```

---

## Synthesis Engine: Building Evidence-Grounded Feedback Text

The synthesis engine is **deterministic**. It does not call an LLM. It takes structured judge outputs and produces structured feedback using rule-based logic. LLMs generate the raw text in judge outputs — synthesis just curates and formats it.

```typescript
// lib/synthesis/feedback-synthesizer.ts
import { SuppressorEngine, type SuppressedClaim } from './suppressor';
import { detectGenericPhrases } from './generic-detector';
import type { JudgeOutput } from '@/lib/judges/judge-output-schema';
import type { Rubric, RubricLane } from '@/lib/rubrics/rubric-loader';

export interface SynthesizedLaneFeedback {
  laneKey: string;
  displayName: string;
  reconciledScore: number;
  positiveSignal: string | null;          // null if suppressed/unavailable
  primaryWeakness: string | null;         // null if suppressed/unavailable
  evidenceRefs: SynthesizedEvidenceRef[];
  hasContradiction: boolean;
  contradictionSummary: string | null;
  isLowEvidence: boolean;                 // true if < 2 refs across all judges
  fallbackReason: string | null;          // set when showing fallback copy
  suppressedClaims: SuppressedClaim[];    // for internal logging only
}

export interface SynthesizedEvidenceRef {
  type: string;
  id: string;
  location: string | null;
  excerpt: string | null;
  sourceJudge: string;
}

export interface SynthesizedFeedback {
  submissionId: string;
  overallScore: number;
  overallAdjustedScore: number;
  overallSignal: string | null;
  overallWeakness: string | null;
  lanes: SynthesizedLaneFeedback[];
  hasAnyContradiction: boolean;
  synthesizedAt: string;
  suppressedCount: number;
}

export function synthesizeFeedback(
  judgeOutputs: JudgeOutput[],
  rubric: Rubric,
  reconciledLaneScores: Record<string, number>,
  overallScore: number,
  overallAdjustedScore: number
): SynthesizedFeedback {
  const suppressor = new SuppressorEngine(judgeOutputs, 2);
  const allSuppressedClaims: SuppressedClaim[] = [];

  const successfulOutputs = judgeOutputs.filter((o) => o.status !== 'failed');

  const lanes: SynthesizedLaneFeedback[] = rubric.lanes.map((lane) => {
    return synthesizeLane(
      lane,
      successfulOutputs,
      suppressor,
      reconciledLaneScores[lane.lane_key] ?? 0,
      allSuppressedClaims
    );
  });

  // Synthesize overall signal: pick the positive_signal from the highest-confidence judge
  const overallSignal = synthesizeOverallSignal(successfulOutputs, suppressor);
  const overallWeakness = synthesizeOverallWeakness(successfulOutputs, suppressor);

  return {
    submissionId: judgeOutputs[0]?.submission_id ?? '',
    overallScore,
    overallAdjustedScore,
    overallSignal,
    overallWeakness,
    lanes,
    hasAnyContradiction: lanes.some((l) => l.hasContradiction),
    synthesizedAt: new Date().toISOString(),
    suppressedCount: allSuppressedClaims.length,
  };
}

function synthesizeLane(
  lane: RubricLane,
  outputs: JudgeOutput[],
  suppressor: SuppressorEngine,
  reconciledScore: number,
  suppressedClaims: SuppressedClaim[]
): SynthesizedLaneFeedback {
  const laneOutputs = outputs.flatMap((o) =>
    o.lane_scores.filter((ls) => ls.lane_key === lane.lane_key)
  );

  // Collect all evidence refs across judges for this lane
  const allEvidenceRefs: SynthesizedEvidenceRef[] = [];
  for (const output of outputs) {
    for (const ls of output.lane_scores) {
      if (ls.lane_key !== lane.lane_key) continue;
      for (const dim of ls.dimension_scores) {
        for (const ref of dim.evidence_refs) {
          allEvidenceRefs.push({
            type: ref.type,
            id: ref.id,
            location: ref.location ?? null,
            excerpt: ref.excerpt ?? null,
            sourceJudge: output.judge_model,
          });
        }
      }
    }
  }

  const isLowEvidence = allEvidenceRefs.length < 2;

  // Detect contradiction
  const laneScores = laneOutputs.map((lo) => lo.lane_score);
  const spread = laneScores.length > 1
    ? Math.max(...laneScores) - Math.min(...laneScores)
    : 0;
  const hasContradiction = spread > 25;

  let contradictionSummary: string | null = null;
  if (hasContradiction) {
    const min = Math.min(...laneScores);
    const max = Math.max(...laneScores);
    contradictionSummary = `Evaluators disagreed on this area (${min}–${max} range). The score reflects the average assessment.`;
  }

  // Find best positive signal for this lane
  let positiveSignal: string | null = null;
  for (const output of outputs) {
    const highDim = findHighestScoringDimInLane(output, lane.lane_key);
    if (!highDim) continue;
    const candidate = highDim.reasoning;
    const result = suppressor.shouldSuppressPositive(candidate, output, highDim.dimension_key);
    if (!result.shouldSuppress) {
      positiveSignal = candidate;
      break;
    } else {
      suppressedClaims.push({
        text: candidate,
        reason: result.reason!,
        judgeModel: output.judge_model,
        laneKey: lane.lane_key,
        dimensionKey: highDim.dimension_key,
      });
    }
  }

  // Find best primary weakness
  let primaryWeakness: string | null = null;
  for (const output of outputs) {
    const lowDim = findLowestScoringDimInLane(output, lane.lane_key);
    if (!lowDim) continue;
    const candidate = lowDim.reasoning;
    const result = suppressor.shouldSuppressWeakness(candidate, output, lowDim.dimension_key);
    if (!result.shouldSuppress) {
      primaryWeakness = candidate;
      break;
    } else {
      suppressedClaims.push({
        text: candidate,
        reason: result.reason!,
        judgeModel: output.judge_model,
        laneKey: lane.lane_key,
        dimensionKey: lowDim.dimension_key,
      });
    }
  }

  // Apply fallback logic
  let fallbackReason: string | null = null;
  if (!positiveSignal && !primaryWeakness) {
    fallbackReason = isLowEvidence
      ? 'Insufficient evaluation evidence for detailed breakdown'
      : 'Evaluation data available — no specific observations met surfacing criteria';
  }

  return {
    laneKey: lane.lane_key,
    displayName: lane.display_name,
    reconciledScore,
    positiveSignal,
    primaryWeakness,
    evidenceRefs: allEvidenceRefs.slice(0, 5), // Surface top 5 refs max
    hasContradiction,
    contradictionSummary,
    isLowEvidence,
    fallbackReason,
    suppressedClaims: suppressedClaims.filter((c) => c.laneKey === lane.lane_key),
  };
}

function findHighestScoringDimInLane(output: JudgeOutput, laneKey: string) {
  const lane = output.lane_scores.find((ls) => ls.lane_key === laneKey);
  if (!lane) return null;
  return [...lane.dimension_scores].sort((a, b) => b.score - a.score)[0] ?? null;
}

function findLowestScoringDimInLane(output: JudgeOutput, laneKey: string) {
  const lane = output.lane_scores.find((ls) => ls.lane_key === laneKey);
  if (!lane) return null;
  return [...lane.dimension_scores].sort((a, b) => a.score - b.score)[0] ?? null;
}

function synthesizeOverallSignal(
  outputs: JudgeOutput[],
  suppressor: SuppressorEngine
): string | null {
  // Pick from highest-confidence non-generic judge
  const confidenceOrder: Array<'high' | 'medium' | 'low'> = ['high', 'medium', 'low'];
  for (const conf of confidenceOrder) {
    const judge = outputs.find((o) => o.confidence === conf);
    if (!judge) continue;
    const genericMatches = detectGenericPhrases(judge.positive_signal);
    if (genericMatches.length === 0) {
      return judge.positive_signal;
    }
  }
  return null;
}

function synthesizeOverallWeakness(
  outputs: JudgeOutput[],
  suppressor: SuppressorEngine
): string | null {
  // Require corroboration: weakness must appear in N-1 of N judges (within theme)
  // For MVP: require >= 2 judges where confidence !== 'low' AND their primary_weakness is non-generic
  const qualifyingWeaknesses = outputs
    .filter((o) => o.confidence !== 'low')
    .map((o) => o.primary_weakness)
    .filter((w) => detectGenericPhrases(w).length === 0);

  if (qualifyingWeaknesses.length >= 2) {
    // Return the one from the highest confidence judge
    const highConf = outputs.find(
      (o) => o.confidence === 'high' && detectGenericPhrases(o.primary_weakness).length === 0
    );
    return highConf?.primary_weakness ?? qualifyingWeaknesses[0];
  }

  return null; // Suppressed — not enough corroboration
}
```

---

## Contradiction Handling: Two Judges Disagree

Contradictions happen. They are information, not errors. The synthesis layer must:
1. Detect them (done in reconciliation)
2. Log them for analytics
3. Render them honestly for users — without undermining trust

```typescript
// lib/synthesis/contradiction-handler.ts
import { createClient } from '@/lib/supabase/server';
import type { ContradictionDetail } from '@/lib/judges/judge-runner';

export interface FeedbackContradiction {
  evaluationRunId: string;
  submissionId: string;
  laneKey: string;
  scores: Array<{ judgeModel: string; score: number }>;
  spread: number;
  userFacingExplanation: string;
  storedAt: string;
}

// Contradiction copy rules:
// - Never name the judge models
// - Acknowledge the disagreement explicitly
// - Show the range, not individual scores
// - Reassure the user the score reflects balanced judgment
export function buildContradictionExplanation(
  laneDisplayName: string,
  contradiction: ContradictionDetail
): string {
  const min = Math.min(...contradiction.scores.map((s) => s.score));
  const max = Math.max(...contradiction.scores.map((s) => s.score));

  if (contradiction.spread >= 40) {
    return (
      `Our evaluators had notably different assessments of your ${laneDisplayName} ` +
      `(${min}–${max} range). This typically means the approach had clear strengths in some ` +
      `dimensions that one evaluator weighted heavily, while another weighted different aspects more. ` +
      `The score shown is a calibrated average.`
    );
  }

  return (
    `Evaluators had slightly different reads on ${laneDisplayName} (${min}–${max} range). ` +
    `The score reflects their combined assessment.`
  );
}

export async function logContradictionForAnalytics(
  evaluationRunId: string,
  submissionId: string,
  contradiction: ContradictionDetail
): Promise<void> {
  const supabase = createClient();

  await supabase.from('feedback_contradictions').insert({
    evaluation_run_id: evaluationRunId,
    submission_id: submissionId,
    lane_key: contradiction.laneKey,
    score_spread: contradiction.spread,
    judge_scores: contradiction.scores,
    created_at: new Date().toISOString(),
  });
}

// Fallback copy patterns — used when evidence is too thin to surface real content
export const FALLBACK_COPY: Record<string, { title: string; body: string }> = {
  insufficient_evidence: {
    title: 'Limited Evaluation Data',
    body: 'Our evaluation system had limited visibility into this aspect of your submission. This score is based on aggregate signals rather than specific evidence.',
  },
  all_claims_suppressed: {
    title: 'Score Available — Breakdown Pending',
    body: 'We\'ve scored this area but the specific observations from our evaluation system didn\'t meet our quality bar for display. Check back if you\'re in an open window — additional analysis may be queued.',
  },
  judge_failure: {
    title: 'Partial Evaluation',
    body: 'One of our evaluators was unavailable. The score shown reflects the assessments we could complete.',
  },
};
```

---

## Anti-Patterns

### Anti-Pattern 1: Surfacing unfiltered judge text directly

```typescript
// ❌ BAD: judge text goes straight to user with no suppression
async function getFeedback(judgeOutputId: string) {
  const output = await loadJudgeOutput(judgeOutputId);
  return {
    strength: output.positive_signal,   // could be generic, low-confidence, evidence-free
    weakness: output.primary_weakness,  // could be uncorroborated, generic
  };
}

// ✅ GOOD: everything passes through the suppressor
async function getFeedback(evaluationRunId: string) {
  const outputs = await loadAllJudgeOutputs(evaluationRunId);
  const rubric = await loadRubricForEval(evaluationRunId);
  const reconciled = await loadReconciledScores(evaluationRunId);

  return synthesizeFeedback(
    outputs,
    rubric,
    reconciled.reconciledLaneScores,
    reconciled.finalOverallScore,
    reconciled.finalAdjustedScore
  );
}
```

### Anti-Pattern 2: Hiding contradictions via silent averaging

```tsx
// ❌ BAD: user sees "Correctness: 62" with no idea two judges disagreed by 45 points
function LaneScore({ lane }: { lane: SynthesizedLaneFeedback }) {
  return <div>Score: {lane.reconciledScore}</div>;
}

// ✅ GOOD: contradiction is surfaced with honest explanation
function LaneScore({ lane }: { lane: SynthesizedLaneFeedback }) {
  return (
    <div>
      <div>Score: {lane.reconciledScore}</div>
      {lane.hasContradiction && lane.contradictionSummary && (
        <div className="mt-1 flex items-start gap-1.5 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded px-2 py-1.5">
          <span>⚡</span>
          <span>{lane.contradictionSummary}</span>
        </div>
      )}
    </div>
  );
}
```

### Anti-Pattern 3: Calling LLM during synthesis

```typescript
// ❌ BAD: synthesis is non-deterministic and slow
async function synthesizeFeedback(outputs: JudgeOutput[]) {
  const response = await anthropic.messages.create({
    model: 'claude-opus-4-6',
    messages: [{ role: 'user', content: `Summarize these judge outputs: ${JSON.stringify(outputs)}` }],
  });
  return response.content[0].text;
}
// This adds latency, cost, and another layer of generic-text risk

// ✅ GOOD: synthesis is pure rule-based curation — no LLM calls
function synthesizeFeedback(outputs: JudgeOutput[], rubric: Rubric, ...): SynthesizedFeedback {
  // Deterministic. Fast. Auditable. No token cost.
  const suppressor = new SuppressorEngine(outputs, 2);
  return {
    lanes: rubric.lanes.map((lane) => synthesizeLane(lane, outputs, suppressor, ...)),
    ...
  };
}
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Suppressor not applied to `positive_signal` | Generic praise like "demonstrates strong problem-solving skills" shown to user | Route all qualitative fields through `shouldSuppressPositive()` before render |
| Corroboration check skipped when N=1 judge | One failed judge leaves 1 judge, and their uncorroborated weakness is surfaced | Add guard: if `successfulJudgeCount === 1`, lower the corroboration bar OR add explicit single-judge caveat notice |
| Contradiction logged but not shown to user | User sees conflicting scores with no explanation; trusts results less | Check `hasContradiction` on every lane card render; always show `contradictionSummary` when true |
| Fallback string is empty string or `undefined` | Lane card renders blank body text; looks broken | Every code path in `synthesizeLane()` must return a non-null string via `fallbackReason` or actual content |
| Synthesis makes an LLM call | Latency spikes; cost increases; output becomes non-deterministic | No async calls in synthesis functions; grep for `await` inside synthesis engine |
| Evidence refs from failed judges included | Low-quality or hallucinated refs surface to users | Filter `judgeOutputs` to `status !== 'failed'` before any evidence extraction |
| `suppressedClaims` logged at same verbosity as regular logs | Debugging noise; can't find real suppression events | Use `logger.debug()` for suppressed claims; `logger.warn()` only when suppression rate > 50% |
| `primary_weakness` for high scores (>75) surfaced without context | User gets a weakness despite a strong score; feels punishing | Add score guard: if `laneScore > 75`, surface weakness with "Even at this level..." framing, or soft-suppress |
| Contradiction detected but not stored in analytics table | No training data for future calibration; contradiction patterns invisible | Every `hasContradiction === true` path must call `logContradictionForAnalytics()` |
| Positive and negative from the same dimension | Contradictory feedback in same lane: "your approach was clear" and "your approach was unclear" | Enforce: `positiveSignal` and `primaryWeakness` must not reference the same `dimension_key` |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
