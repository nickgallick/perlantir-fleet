---
name: anti-generic-llm-output-control
description: Block filler, detect low-signal text, score specificity, and enforce evidence-anchored observations across all LLM-generated feedback in Bouts — with banned phrase detection, specificity scoring, retry-with-critique, and dimension name normalization.
---

# Anti-Generic LLM Output Control

## Review Checklist

1. **Generic detector runs on every judge output before storage**: `detectGenericPhrases()` is called in the judge output processing pipeline, not only at display time. Verify: add a judge output with "demonstrates strong problem-solving skills" — confirm it's flagged and logged.
2. **Specificity score is computed and stored on every judge output**: `specificity_score` column exists on `judge_outputs`. Verify: `SELECT COUNT(*) FROM judge_outputs WHERE specificity_score IS NULL AND created_at > NOW() - INTERVAL '1 day'` returns 0 in production.
3. **Retry-with-critique fires when specificity score < threshold**: When `specificity_score < 30`, the system automatically calls the retry-with-critique flow before storing the judge output. Verify: mock a low-specificity judge output and confirm the retry is invoked.
4. **Retry count is capped at 2**: `retryWithCritique()` must not loop indefinitely. If score is still below threshold after 2 retries, store the best attempt with a flag. Verify: force retry to always fail — confirm max 2 retries, then fallback.
5. **Banned phrase list is versioned and tested**: `BANNED_PHRASES` array is in a constant file, has version comments, and has at least one unit test asserting each phrase is correctly detected. Run: `pnpm test lib/synthesis/generic-detector`.
6. **Dimension keys are normalized before cross-judge comparison**: Before comparing dimension scores across judges, all dimension keys go through `normalizeDimensionKey()`. Verify: "code_quality" and "code quality" and "Code Quality" all normalize to `"code_quality"`.
7. **Specificity score penalizes for missing evidence refs**: An observation with 0 evidence_refs gets a maximum specificity score of 40 regardless of text quality. Verify: call `computeSpecificityScore()` with empty evidence_refs and confirm cap.
8. **Generic phrase detection is case-insensitive and punctuation-tolerant**: The regex patterns match "Strong understanding", "strong understanding.", "STRONG UNDERSTANDING" identically. Add test cases for each variant.
9. **`positive_signal` and `primary_weakness` are checked independently**: A field can have a generic `primary_weakness` but a specific `positive_signal`. Both are checked separately. Verify: mock a judge output where one field is generic and one is specific — confirm only the generic one is flagged.
10. **Suppression log captures what was generic**: When a field is suppressed for being generic, the `synthesis_suppression_log` captures `suppressed_text_hash` and `suppression_type = 'generic_phrase'` for pattern analysis.
11. **Critique prompt does not re-inject the original generic text**: The retry-with-critique prompt asks the LLM to identify generic phrases in its output and rewrite them. Verify the critique prompt doesn't seed the LLM with the original text as "correct".
12. **Normalization covers all current judge models**: `normalizeDimensionKey()` has test coverage for Claude, GPT-4o, and Gemini output variations. Each model has different tendencies (e.g., GPT-4o uses camelCase, Claude uses snake_case).

---

## The Banned Phrases List

This is the core detection asset. It is never complete — it grows as new generic patterns are discovered. Every new judge model prompt should be calibrated against this list.

```typescript
// lib/synthesis/banned-phrases.ts

export const BANNED_PHRASE_VERSION = '1.4';
export const BANNED_PHRASE_UPDATED = '2026-03-31';

// Pattern format: regex string (case-insensitive flag applied at runtime)
// Organized by category for easier maintenance and expansion

export const BANNED_PHRASES: Array<{ pattern: string; category: string; reason: string }> = [
  // ---- Vague Competence Claims ----
  { pattern: 'demonstrates? (?:a )?(?:strong|solid|good|excellent|great) understanding',
    category: 'vague_competence', reason: 'Non-specific — what was understood? of what?' },
  { pattern: 'shows? (?:a )?(?:strong|solid|good|excellent|great) grasp',
    category: 'vague_competence', reason: 'No evidence of what was grasped' },
  { pattern: 'displays? (?:a )?(?:strong|solid|clear|good) understanding',
    category: 'vague_competence', reason: 'No specific artifact cited' },
  { pattern: 'clearly understands? the (?:problem|challenge|task|requirements?)',
    category: 'vague_competence', reason: 'Generic positive — must cite specific decision that evidences understanding' },
  { pattern: 'demonstrates? (?:strong|solid|good|excellent) (?:technical )?(?:skills?|knowledge|expertise|proficiency)',
    category: 'vague_competence', reason: 'Skill category without artifact reference' },

  // ---- Initiative / Effort Praise ----
  { pattern: 'shows? (?:good|great|impressive|notable) initiative',
    category: 'effort_praise', reason: 'Initiative is not observable without citing the specific unrequested action' },
  { pattern: 'goes? (?:above and )?beyond (?:the )?(?:requirements?|expectations?|scope)',
    category: 'effort_praise', reason: 'Must cite what specifically was beyond scope' },
  { pattern: 'puts? in (?:a lot of|significant|considerable) effort',
    category: 'effort_praise', reason: 'Effort is not an observable artifact' },
  { pattern: 'demonstrates? (?:a )?(?:strong|solid|clear) (?:work ethic|commitment|dedication)',
    category: 'effort_praise', reason: 'Unobservable from a submission artifact' },

  // ---- Generic Approach Descriptions ----
  { pattern: '(?:takes?|uses?) (?:a|an) (?:structured|systematic|methodical|logical) approach',
    category: 'generic_approach', reason: 'Must cite what structure/system was used (e.g., BFS vs DFS, specific algorithm)' },
  { pattern: '(?:organizes?|structures?) (?:(?:the|their) )?(?:code|solution|work) (?:well|effectively|clearly)',
    category: 'generic_approach', reason: 'Must reference specific structural decision (e.g., "separates I/O from logic at line 23")' },
  { pattern: 'well[- ]organized',
    category: 'generic_approach', reason: 'Observable only if specific organization pattern cited' },
  { pattern: 'follows? (?:best|good) practices',
    category: 'generic_approach', reason: 'Which practice? Cite it specifically' },
  { pattern: 'adheres? to (?:best|good|coding|software) practices',
    category: 'generic_approach', reason: 'Must name the practice and where it appears' },

  // ---- Vague Weakness Claims ----
  { pattern: 'could (?:be|have been) (?:more )?(?:improved|better|more efficient|cleaner)',
    category: 'vague_weakness', reason: 'What specifically? Where? How much?' },
  { pattern: 'there is (?:some|room for) (?:room for|improvement)',
    category: 'vague_weakness', reason: 'Always true — must be specific about what and where' },
  { pattern: 'could have (?:handled|addressed|considered) (?:edge cases?|error handling) (?:better|more)?',
    category: 'vague_weakness', reason: 'Must cite which edge case was missed and at which step' },
  { pattern: 'lacks? (?:some|a bit of) (?:depth|detail|thoroughness)',
    category: 'vague_weakness', reason: 'Depth in what dimension? Cite the missing thing' },
  { pattern: 'not (?:fully|completely|entirely) (?:complete|finished|implemented)',
    category: 'vague_weakness', reason: 'Must cite what was missing (e.g., "test cases for input > 10^6 not present")' },

  // ---- Hollow Summary Statements ----
  { pattern: 'overall[,]? (?:a )?(?:good|strong|solid|decent|adequate) (?:submission|attempt|performance|effort)',
    category: 'hollow_summary', reason: 'Restates the score in prose — adds zero signal' },
  { pattern: 'all things considered',
    category: 'hollow_summary', reason: 'Filler phrase; remove entirely' },
  { pattern: 'in (?:general|summary|conclusion)',
    category: 'hollow_summary', reason: 'Filler — the statement after this is usually the actual content' },
  { pattern: 'demonstrates? (?:a )?(?:good|solid|strong) (?:overall )?performance',
    category: 'hollow_summary', reason: 'Restates numerical score without adding observational content' },

  // ---- Judge Self-Reference (should never appear in user-facing output) ----
  { pattern: 'as (?:an|the) (?:AI|LLM|judge|evaluator|language model)',
    category: 'self_reference', reason: 'Judge must not self-reference in user-facing feedback' },
  { pattern: 'based on (?:my|the) (?:analysis|evaluation|assessment)',
    category: 'self_reference', reason: 'Implicit — remove the meta-commentary, state the finding' },
  { pattern: 'i (?:noticed|observed|found|detected) that',
    category: 'self_reference', reason: 'First-person judge voice must be removed before surfacing' },
];

// Quick lookup set for O(1) pre-filter (coarse check before regex)
export const BANNED_KEYWORD_SEEDS = new Set([
  'demonstrates', 'shows', 'displays', 'initiative', 'approach', 'organized',
  'practices', 'improved', 'improvement', 'depth', 'overall', 'generally',
  'conclusion', 'performance', 'solid', 'strong', 'good', 'excellent', 'grasp',
  'understanding', 'expertise', 'proficiency', 'effort', 'commitment',
]);
```

---

## TypeScript: Generic Detector and Specificity Scorer

```typescript
// lib/synthesis/generic-detector.ts
import { BANNED_PHRASES, BANNED_KEYWORD_SEEDS } from './banned-phrases';

export interface GenericMatch {
  pattern: string;
  category: string;
  reason: string;
  matchedText: string;
  position: number;
}

/**
 * Detect generic phrases in a text string.
 * Returns an array of matches — empty array means text passed the detector.
 */
export function detectGenericPhrases(text: string): GenericMatch[] {
  if (!text || text.trim().length === 0) return [];

  const lowerText = text.toLowerCase();

  // Pre-filter: quick check for any banned keyword seed
  const hasAnySeed = Array.from(BANNED_KEYWORD_SEEDS).some((seed) =>
    lowerText.includes(seed)
  );
  if (!hasAnySeed) return []; // Fast path — no seeds present

  const matches: GenericMatch[] = [];

  for (const { pattern, category, reason } of BANNED_PHRASES) {
    const regex = new RegExp(pattern, 'gi');
    let match: RegExpExecArray | null;

    while ((match = regex.exec(text)) !== null) {
      matches.push({
        pattern,
        category,
        reason,
        matchedText: match[0],
        position: match.index,
      });
    }
  }

  return matches;
}

/**
 * Compute a specificity score for a feedback string.
 * Score 0-100:
 *  - 0-30: Generic / filler — should be suppressed
 *  - 30-60: Partially specific — may surface with caveat
 *  - 60-80: Specific — safe to surface
 *  - 80-100: Highly specific — cite as exemplary feedback
 */
export interface SpecificityScoreResult {
  score: number;
  genericPenalty: number;
  evidencePenalty: number;
  lengthBonus: number;
  specificitySignals: string[];
}

export function computeSpecificityScore(
  text: string,
  evidenceRefCount: number = 0
): SpecificityScoreResult {
  let score = 60; // baseline
  const signals: string[] = [];

  // ---- Deductions ----

  // Generic phrase penalty
  const genericMatches = detectGenericPhrases(text);
  const genericPenalty = Math.min(genericMatches.length * 15, 60);
  score -= genericPenalty;

  if (genericMatches.length > 0) {
    signals.push(`${genericMatches.length} generic phrase(s) detected`);
  }

  // Evidence penalty: 0 refs = cap at 40
  const evidencePenalty = evidenceRefCount === 0 ? Math.max(0, score - 40) : 0;
  score -= evidencePenalty;

  if (evidenceRefCount === 0) {
    signals.push('No evidence refs — capped at 40');
  }

  // ---- Bonuses ----

  // Specificity signals: numbers, line references, function names, specific terms
  const specificityPatterns = [
    { pattern: /\bline\s+\d+/i, signal: 'cites specific line number', bonus: 10 },
    { pattern: /\bstep\s+\d+/i, signal: 'cites specific step', bonus: 8 },
    { pattern: /\btool call\b/i, signal: 'references tool call', bonus: 8 },
    { pattern: /\b\d+(?:\.\d+)?%/i, signal: 'contains percentage', bonus: 5 },
    { pattern: /\bO\([^)]+\)/i, signal: 'cites complexity notation', bonus: 10 },
    { pattern: /`[^`]+`/, signal: 'references code artifact', bonus: 12 },
    { pattern: /\b(?:function|class|method|variable|parameter|argument)\s+\w+/i,
      signal: 'names specific code element', bonus: 10 },
    { pattern: /\b(?:instead|rather than|compared to|versus|vs\.?)\b/i,
      signal: 'makes comparative claim', bonus: 5 },
    { pattern: /\b(?:because|since|due to|as a result|which means)\b/i,
      signal: 'provides causal reasoning', bonus: 5 },
  ];

  let lengthBonus = 0;
  for (const { pattern, signal, bonus } of specificityPatterns) {
    if (pattern.test(text)) {
      lengthBonus += bonus;
      signals.push(signal);
    }
  }

  score += Math.min(lengthBonus, 40); // Cap bonus at 40

  // Evidence ref bonus (up to +15)
  if (evidenceRefCount > 0) {
    const refBonus = Math.min(evidenceRefCount * 5, 15);
    score += refBonus;
    signals.push(`${evidenceRefCount} evidence ref(s) — +${refBonus} points`);
  }

  // Clamp to 0-100
  score = Math.max(0, Math.min(100, Math.round(score)));

  return { score, genericPenalty, evidencePenalty, lengthBonus, specificitySignals: signals };
}

// ---- Dimension Key Normalization ----

/**
 * Normalize dimension keys from different judge models to a canonical snake_case form.
 * Claude uses snake_case, GPT-4o uses camelCase, Gemini uses Title Case.
 * Without normalization, cross-judge comparison produces key-not-found errors.
 */
export function normalizeDimensionKey(raw: string): string {
  return raw
    .trim()
    // Handle camelCase: insert _ before uppercase letters
    .replace(/([a-z])([A-Z])/g, '$1_$2')
    // Replace spaces, hyphens, and multiple underscores with single underscore
    .replace(/[\s\-]+/g, '_')
    .replace(/_+/g, '_')
    // Lowercase everything
    .toLowerCase()
    // Remove any remaining non-alphanumeric (except underscore)
    .replace(/[^a-z0-9_]/g, '')
    // Trim leading/trailing underscores
    .replace(/^_+|_+$/g, '');
}

// Test cases (also serve as documentation of expected behavior)
// normalizeDimensionKey('codeQuality') → 'code_quality'
// normalizeDimensionKey('Code Quality') → 'code_quality'
// normalizeDimensionKey('CODE_QUALITY') → 'code_quality'
// normalizeDimensionKey('code-quality') → 'code_quality'
// normalizeDimensionKey('  Code  Quality  ') → 'code_quality'
// normalizeDimensionKey('problemDecomposition') → 'problem_decomposition'
```

---

## TypeScript: Retry-With-Critique Implementation

```typescript
// lib/synthesis/retry-with-critique.ts
import Anthropic from '@anthropic-ai/sdk';
import { computeSpecificityScore, detectGenericPhrases } from './generic-detector';
import type { JudgeOutput } from '@/lib/judges/judge-output-schema';

const anthropic = new Anthropic();

const SPECIFICITY_THRESHOLD = 35;
const MAX_RETRIES = 2;

export interface CritiqueResult {
  originalScore: number;
  finalScore: number;
  attempts: number;
  improved: boolean;
  finalText: string;
  critiqueSummary: string;
}

/**
 * Retry-with-critique: feed the LLM its own output and ask it to find and rewrite generic phrases.
 * This is NOT a re-run of the full evaluation — only the qualitative text fields are improved.
 */
export async function retryWithCritique(
  originalText: string,
  context: {
    laneKey: string;
    dimensionKey: string;
    score: number;
    evidenceExcerpts: string[]; // Specific evidence the judge has access to
  }
): Promise<CritiqueResult> {
  const originalSpecificity = computeSpecificityScore(originalText, 0).score;

  if (originalSpecificity >= SPECIFICITY_THRESHOLD) {
    // Already good enough — no retry needed
    return {
      originalScore: originalSpecificity,
      finalScore: originalSpecificity,
      attempts: 0,
      improved: false,
      finalText: originalText,
      critiqueSummary: 'No critique needed — met specificity threshold',
    };
  }

  let currentText = originalText;
  let currentScore = originalSpecificity;
  let attempt = 0;
  let critiqueSummary = '';

  while (attempt < MAX_RETRIES && currentScore < SPECIFICITY_THRESHOLD) {
    attempt++;

    const genericMatches = detectGenericPhrases(currentText);
    const genericPhraseList = genericMatches
      .map((m) => `- "${m.matchedText}" (${m.reason})`)
      .join('\n');

    const critiquePrompt = `You wrote the following evaluation observation:

"${currentText}"

This observation was flagged as too generic. Here are the specific phrases that are not acceptable:

${genericPhraseList || 'No specific phrases detected, but the observation lacks evidence anchoring.'}

Evidence available for this ${context.laneKey} / ${context.dimensionKey} evaluation:
${context.evidenceExcerpts.map((e, i) => `[${i + 1}] ${e}`).join('\n')}

Score being described: ${context.score}/100

Rewrite the observation. Requirements:
1. Remove all flagged generic phrases entirely — do not paraphrase them
2. Every claim must cite a specific evidence item (by [number]) or a specific decision/step/artifact
3. Be concrete about what happened, not what the submission "shows" or "demonstrates"
4. Keep it under 200 words
5. Do not start with "This submission" or "The solution"

Rewritten observation:`;

    const response = await anthropic.messages.create({
      model: 'claude-haiku-4-5',  // Use cheapest model for critique — it's a rewrite task
      max_tokens: 300,
      messages: [{ role: 'user', content: critiquePrompt }],
    });

    const rewritten = response.content[0].type === 'text'
      ? response.content[0].text.trim()
      : currentText;

    const newScore = computeSpecificityScore(rewritten, context.evidenceExcerpts.length).score;
    critiqueSummary = `Attempt ${attempt}: ${currentScore} → ${newScore}`;

    if (newScore > currentScore) {
      currentText = rewritten;
      currentScore = newScore;
    }
    // If the retry made things worse or equal, keep the previous version
  }

  return {
    originalScore: originalSpecificity,
    finalScore: currentScore,
    attempts: attempt,
    improved: currentScore > originalSpecificity,
    finalText: currentText,
    critiqueSummary,
  };
}

// ---- Integration point: process a full judge output through quality control ----

export interface QualityControlResult {
  processedOutput: Partial<JudgeOutput>;
  specificityScores: Record<string, number>;
  retriesTriggered: number;
  flaggedFields: string[];
}

export async function applyOutputQualityControl(
  output: JudgeOutput
): Promise<QualityControlResult> {
  const specificityScores: Record<string, number> = {};
  let retriesTriggered = 0;
  const flaggedFields: string[] = [];
  const updatedOutput = { ...output };

  // Check and possibly retry positive_signal
  const posScore = computeSpecificityScore(output.positive_signal, 0).score;
  specificityScores['positive_signal'] = posScore;

  if (posScore < SPECIFICITY_THRESHOLD) {
    flaggedFields.push('positive_signal');
    const result = await retryWithCritique(output.positive_signal, {
      laneKey: 'overall',
      dimensionKey: 'positive_signal',
      score: output.overall_score,
      evidenceExcerpts: output.lane_scores
        .flatMap((ls) => ls.dimension_scores)
        .flatMap((ds) => ds.evidence_refs)
        .map((ref) => ref.excerpt ?? ref.id)
        .filter(Boolean)
        .slice(0, 5),
    });

    if (result.improved) {
      updatedOutput.positive_signal = result.finalText;
      specificityScores['positive_signal'] = result.finalScore;
      retriesTriggered++;
    }
  }

  // Check and possibly retry primary_weakness
  const weakScore = computeSpecificityScore(output.primary_weakness, 0).score;
  specificityScores['primary_weakness'] = weakScore;

  if (weakScore < SPECIFICITY_THRESHOLD) {
    flaggedFields.push('primary_weakness');
    const result = await retryWithCritique(output.primary_weakness, {
      laneKey: 'overall',
      dimensionKey: 'primary_weakness',
      score: output.overall_score,
      evidenceExcerpts: output.lane_scores
        .flatMap((ls) => ls.dimension_scores)
        .filter((ds) => ds.score < 55) // Low-scoring dimensions are most relevant for weaknesses
        .flatMap((ds) => ds.evidence_refs)
        .map((ref) => ref.excerpt ?? ref.id)
        .filter(Boolean)
        .slice(0, 5),
    });

    if (result.improved) {
      updatedOutput.primary_weakness = result.finalText;
      specificityScores['primary_weakness'] = result.finalScore;
      retriesTriggered++;
    }
  }

  return {
    processedOutput: updatedOutput,
    specificityScores,
    retriesTriggered,
    flaggedFields,
  };
}
```

---

## Anti-Patterns

### Anti-Pattern 1: Detecting generic phrases only at display time

```typescript
// ❌ BAD: generic text stored in DB; detection only at render time
// Now you have a database full of low-quality feedback
// If you change the detection rules, you can't retroactively fix stored content
async function saveJudgeOutput(output: JudgeOutput) {
  await supabase.from('judge_outputs').insert(output);
  // No quality check
}

// In the component:
function FeedbackText({ text }: { text: string }) {
  const matches = detectGenericPhrases(text); // Too late — it's already stored
  if (matches.length > 0) return <p>Feedback unavailable</p>;
  return <p>{text}</p>;
}

// ✅ GOOD: quality control is a processing step before storage
async function saveJudgeOutput(rawOutput: JudgeOutput) {
  const qcResult = await applyOutputQualityControl(rawOutput);
  const specificityScore = computeSpecificityScore(qcResult.processedOutput.positive_signal ?? '', 0).score;

  await supabase.from('judge_outputs').insert({
    ...qcResult.processedOutput,
    specificity_score: specificityScore,
    qc_flags: qcResult.flaggedFields,
    qc_retries: qcResult.retriesTriggered,
  });
}
```

### Anti-Pattern 2: Critique prompt seeds the original generic text as correct

```typescript
// ❌ BAD: telling the LLM to "improve" the text while showing it as the baseline
const badCritiquePrompt = `
Here is a good evaluation:
"${originalText}"

Please make it even better and more specific.
`;
// The LLM will anchor on the original phrasing, preserve its structure, and produce
// only superficial rewrites like "demonstrates a VERY strong understanding"

// ✅ GOOD: explicitly label what's wrong; don't present original as "good"
const goodCritiquePrompt = `
You wrote this observation (it has problems):
"${currentText}"

These specific phrases are unacceptable:
${genericPhraseList}

Rewrite it without any of those phrases. Every claim must cite a specific artifact.
`;
```

### Anti-Pattern 3: Running retry-with-critique on low-level dimension reasoning (cost explosion)

```typescript
// ❌ BAD: running critique on EVERY dimension score reasoning text
// A rubric with 5 lanes × 4 dimensions = 20 dimension reasonings per judge
// 3 judges × 20 = 60 potential retries × 2 max retries = 120 LLM calls per evaluation
for (const lane of output.lane_scores) {
  for (const dim of lane.dimension_scores) {
    const result = await retryWithCritique(dim.reasoning, ...); // 💸
  }
}

// ✅ GOOD: only retry the high-visibility surface fields
// positive_signal and primary_weakness are user-facing — these matter
// Dimension reasoning is judge-internal (shown on demand) — score it but don't retry
const qcResult = await applyOutputQualityControl(output); // only retries top-level fields
for (const lane of output.lane_scores) {
  for (const dim of lane.dimension_scores) {
    // Score only — no retry
    const specificity = computeSpecificityScore(dim.reasoning, dim.evidence_refs.length);
    await storeDimensionSpecificityScore(dim.id, specificity.score);
  }
}
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Specificity score not stored — only checked at display time | Can't run analytics on feedback quality; can't improve prompts based on data | Store `specificity_score` as a column on `judge_outputs`; populate in processing pipeline |
| Retry-with-critique has no max retry cap | A judge model that consistently outputs generic text causes infinite retry loop | Hard cap at `MAX_RETRIES = 2`; store best result with a `qc_flag` after hitting cap |
| Banned phrase list not version-tagged | Can't audit when a phrase was added; can't reproduce historical detection behavior | Add `BANNED_PHRASE_VERSION` constant; tag in logs when detection fires |
| Dimension key normalization not applied before cross-judge comparison | GPT-4o scores `codeQuality`, Claude scores `code_quality` — join returns nothing | Run `normalizeDimensionKey()` on all dimension keys before any comparison |
| Critique prompt shows only one evidence excerpt | LLM can't rewrite generically if it only has 1 evidence item | Pass top 5 evidence excerpts; if fewer than 2, skip critique (not enough source material) |
| Generic detection is case-sensitive | "Demonstrates" passes but "demonstrates" fails | All regex patterns must use `gi` flag; add test cases for mixed case |
| Retry improves score metric but output is worse | LLM produces a technically specific but incoherent sentence | Add a minimum coherence heuristic: rewritten text must be > 30 chars and contain at least one verb |
| Quality control runs on failed judge outputs | Retry triggered for a `status: 'failed'` output with no content | Guard: skip QC entirely for `output.status === 'failed'` |
| `BANNED_KEYWORD_SEEDS` fast-path prevents valid detections | "Shows" seed not present → full regex not run → generic phrase missed | Audit: every banned pattern's key words must appear in `BANNED_KEYWORD_SEEDS` |
| Specificity score used as a binary gate (pass/fail) | Score of 29 is stored as suppressed; score of 31 is surfaced unchanged | Use specificity score as a continuous signal: 0-30 = suppress, 30-60 = surface with caveat, 60+ = surface fully |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
