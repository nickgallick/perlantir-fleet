---
name: null-safe-results-rendering
description: Render partial, legacy, missing, and evolving evaluation result data without crashes — covering every null/undefined edge case in Bouts lane scores, evidence refs, confidence fields, and partial judge results.
---

# Null-Safe Results Rendering

## Review Checklist

- [ ] **Every lane score access uses optional chaining**: `result?.lanes?.[laneId]?.score` — never `result.lanes[laneId].score` on potentially-null data
- [ ] **Confidence fields use nullish coalescing with explicit fallback values**: `confidence ?? null` not `confidence || 0` (0 is a valid confidence, falsy check will corrupt it)
- [ ] **Evidence refs array is checked for existence AND emptiness separately**: `refs && refs.length > 0` before mapping — missing refs and empty refs render differently
- [ ] **Partial judge results show explicit "pending" state per judge, not just an average**: if 2/3 judges returned, display the 2 scores and a spinner for the 3rd — never average partial results
- [ ] **Legacy schema records (pre-confidence column) don't receive "0%" confidence display** — they should show "N/A" or nothing, not zero
- [ ] **All database queries use COALESCE for columns added after initial schema**: `COALESCE(confidence, NULL)` pattern prevents column-not-found crashes on old rows
- [ ] **The loading/partial/error states are visually distinct** — not the same grey box for all three
- [ ] **`undefined` vs `null` is handled consistently**: DB returns `null` for missing fields, JS can produce `undefined` — normalize at the boundary
- [ ] **Score display handles the full range including edge values**: 0 is a valid score and must not be treated as falsy; 100 is valid; never use `score || '—'`
- [ ] **Judge results keyed by judge ID, not array index**: if one judge is missing from the response, array index access will return wrong judge data
- [ ] **Component renders without crashing when `submission` prop is undefined** (route loads before data arrives) — use a skeleton, not a thrown error
- [ ] **COALESCE queries tested on actual legacy rows** — not just mocked — before ship

---

## TypeScript Utility Types for Nullable Result Shapes

The core challenge: the database schema has evolved. Submissions from 3 months ago lack `confidence`. Submissions currently being judged lack final scores. Submissions where a judge crashed lack evidence refs. **Every field at every level must be modeled as potentially absent.**

```typescript
// types/results.ts

/**
 * Raw shape returned from Supabase query — every field that may be absent is nullable.
 * This mirrors what the DB actually returns, including legacy records.
 */
export interface RawLaneScore {
  lane_id: string;
  lane_name: string;
  score: number | null;            // null = judging in progress
  max_score: number;
  weight: number;
  confidence: number | null;       // null = legacy record (column added later)
  status: 'pending' | 'scoring' | 'complete' | 'failed';
}

export interface RawEvidenceRef {
  ref_id: string;
  judge_id: string;
  lane_id: string;
  type: 'quote' | 'annotation' | 'metric';
  content: string;
  source_event_id: string | null;  // null = judge didn't link to timeline event
  confidence: number | null;
}

export interface RawJudgeResult {
  judge_id: 'claude' | 'gpt4o' | 'gemini';
  judge_name: string;
  status: 'pending' | 'running' | 'complete' | 'failed' | 'timeout';
  lane_scores: RawLaneScore[] | null;    // null if judge hasn't started scoring lanes
  evidence_refs: RawEvidenceRef[] | null; // null if judge ran but produced no refs
  completed_at: string | null;
  error_message: string | null;
}

export interface RawSubmissionResult {
  submission_id: string;
  bout_id: string;
  agent_name: string;
  overall_score: number | null;          // null until all judges complete
  rank: number | null;                   // null until ranking runs
  judge_results: RawJudgeResult[] | null; // null for very old submissions
  created_at: string;
  schema_version: number | null;         // null for oldest records (pre-versioning)
}

/**
 * Normalized shape used in UI — guarantees safe access patterns.
 * Produced by normalizeSubmissionResult().
 */
export interface NormalizedLaneScore {
  laneId: string;
  laneName: string;
  score: number | null;
  maxScore: number;
  weight: number;
  confidence: number | null;
  hasConfidence: boolean;           // explicit: was this field present in source?
  status: RawLaneScore['status'];
  isScored: boolean;                // score !== null
}

export interface NormalizedEvidenceRef {
  refId: string;
  judgeId: string;
  laneId: string;
  type: RawEvidenceRef['type'];
  content: string;
  sourceEventId: string | null;
  confidence: number | null;
}

export interface NormalizedJudgeResult {
  judgeId: string;
  judgeName: string;
  status: RawJudgeResult['status'];
  laneScores: NormalizedLaneScore[];    // always an array, may be empty
  evidenceRefs: NormalizedEvidenceRef[]; // always an array, may be empty
  hasEvidenceRefs: boolean;             // explicit: did judge produce refs at all?
  completedAt: Date | null;
  errorMessage: string | null;
  isPending: boolean;
  isComplete: boolean;
  isFailed: boolean;
}

export interface NormalizedSubmissionResult {
  submissionId: string;
  boutId: string;
  agentName: string;
  overallScore: number | null;
  rank: number | null;
  judgeResults: NormalizedJudgeResult[];
  completeJudgeCount: number;
  totalJudgeCount: number;
  isFullyScored: boolean;
  isLegacyRecord: boolean;             // pre-confidence schema
  createdAt: Date;
}

/**
 * Normalize raw DB data to safe shape. All null/undefined coercion happens HERE,
 * not scattered across components.
 */
export function normalizeSubmissionResult(
  raw: RawSubmissionResult
): NormalizedSubmissionResult {
  const judgeResults = (raw.judge_results ?? []).map(normalizeJudgeResult);
  const completeJudges = judgeResults.filter(j => j.isComplete);
  const isLegacyRecord = raw.schema_version === null || raw.schema_version < 2;

  return {
    submissionId: raw.submission_id,
    boutId: raw.bout_id,
    agentName: raw.agent_name,
    overallScore: raw.overall_score ?? null,
    rank: raw.rank ?? null,
    judgeResults,
    completeJudgeCount: completeJudges.length,
    totalJudgeCount: judgeResults.length,
    isFullyScored: judgeResults.length > 0 && completeJudges.length === judgeResults.length,
    isLegacyRecord,
    createdAt: new Date(raw.created_at),
  };
}

function normalizeJudgeResult(raw: RawJudgeResult): NormalizedJudgeResult {
  const laneScores = (raw.lane_scores ?? []).map(normalizeLaneScore);
  const evidenceRefs = (raw.evidence_refs ?? []).map(normalizeEvidenceRef);

  return {
    judgeId: raw.judge_id,
    judgeName: raw.judge_name,
    status: raw.status,
    laneScores,
    evidenceRefs,
    hasEvidenceRefs: raw.evidence_refs !== null, // null = didn't run; [] = ran but found none
    completedAt: raw.completed_at ? new Date(raw.completed_at) : null,
    errorMessage: raw.error_message ?? null,
    isPending: raw.status === 'pending' || raw.status === 'running',
    isComplete: raw.status === 'complete',
    isFailed: raw.status === 'failed' || raw.status === 'timeout',
  };
}

function normalizeLaneScore(raw: RawLaneScore): NormalizedLaneScore {
  return {
    laneId: raw.lane_id,
    laneName: raw.lane_name,
    score: raw.score ?? null,
    maxScore: raw.max_score,
    weight: raw.weight,
    confidence: raw.confidence ?? null,
    hasConfidence: raw.confidence !== null && raw.confidence !== undefined,
    status: raw.status,
    isScored: raw.score !== null,
  };
}

function normalizeEvidenceRef(raw: RawEvidenceRef): NormalizedEvidenceRef {
  return {
    refId: raw.ref_id,
    judgeId: raw.judge_id,
    laneId: raw.lane_id,
    type: raw.type,
    content: raw.content,
    sourceEventId: raw.source_event_id ?? null,
    confidence: raw.confidence ?? null,
  };
}
```

---

## Migration-Safe Query Patterns with COALESCE

When your schema evolves, old rows won't have new columns. Supabase/Postgres handles this fine — the column exists, the old rows have NULL. But your query must handle this without crashing, and your frontend types must match.

```sql
-- Migration: add confidence column to lane_scores (existing rows get NULL)
ALTER TABLE lane_scores ADD COLUMN IF NOT EXISTS confidence NUMERIC(4,3);
ALTER TABLE lane_scores ADD COLUMN IF NOT EXISTS schema_version INTEGER;

-- Migration: add evidence_refs (old judge_results rows won't have this)
ALTER TABLE judge_results ADD COLUMN IF NOT EXISTS evidence_refs JSONB;
ALTER TABLE judge_results ADD COLUMN IF NOT EXISTS schema_version INTEGER DEFAULT 1;

-- Update existing rows to mark them as legacy
UPDATE judge_results SET schema_version = 1 WHERE schema_version IS NULL;
UPDATE submissions SET schema_version = 1 WHERE schema_version IS NULL;
```

```typescript
// lib/queries/submission-result.ts
import { createClient } from '@/lib/supabase/server';
import type { RawSubmissionResult } from '@/types/results';

/**
 * Fetch submission result with COALESCE guards for legacy columns.
 * COALESCE ensures consistent shape regardless of when the row was created.
 */
export async function fetchSubmissionResult(
  submissionId: string
): Promise<RawSubmissionResult | null> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('submissions')
    .select(`
      submission_id,
      bout_id,
      agent_name,
      overall_score,
      rank,
      created_at,
      schema_version,
      judge_results (
        judge_id,
        judge_name,
        status,
        completed_at,
        error_message,
        schema_version,
        lane_scores (
          lane_id,
          lane_name,
          score,
          max_score,
          weight,
          status,
          confidence,
          schema_version
        ),
        evidence_refs
      )
    `)
    .eq('submission_id', submissionId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null; // not found
    throw error;
  }

  // Supabase returns null for missing columns on old rows — that's correct.
  // The normalization layer handles the null → typed null conversion.
  return data as RawSubmissionResult;
}

/**
 * For cases where you need raw SQL (e.g., complex aggregations), use COALESCE explicitly.
 * This is the safe pattern when joining across tables with mismatched schemas.
 */
export async function fetchSubmissionResultRaw(submissionId: string) {
  const supabase = createClient();

  const { data, error } = await supabase.rpc('get_submission_result_safe', {
    p_submission_id: submissionId,
  });

  if (error) throw error;
  return data;
}
```

```sql
-- Postgres function: get_submission_result_safe
-- Uses COALESCE to handle columns that may not exist in old rows
CREATE OR REPLACE FUNCTION get_submission_result_safe(p_submission_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'submission_id', s.submission_id,
    'bout_id', s.bout_id,
    'agent_name', s.agent_name,
    'overall_score', s.overall_score,
    'rank', s.rank,
    'schema_version', COALESCE(s.schema_version, 1),
    'created_at', s.created_at,
    'judge_results', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'judge_id', jr.judge_id,
            'judge_name', jr.judge_name,
            'status', jr.status,
            'completed_at', jr.completed_at,
            'error_message', jr.error_message,
            -- evidence_refs may be NULL on legacy rows (column added later)
            'evidence_refs', jr.evidence_refs,
            'lane_scores', COALESCE(
              (
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'lane_id', ls.lane_id,
                    'lane_name', ls.lane_name,
                    'score', ls.score,
                    'max_score', ls.max_score,
                    'weight', ls.weight,
                    'status', ls.status,
                    -- confidence is NULL on pre-v2 rows — preserve that NULL
                    'confidence', ls.confidence
                  )
                )
                FROM lane_scores ls
                WHERE ls.judge_result_id = jr.id
              ),
              '[]'::jsonb
            )
          )
        )
        FROM judge_results jr
        WHERE jr.submission_id = s.submission_id
      ),
      '[]'::jsonb
    )
  )
  INTO result
  FROM submissions s
  WHERE s.submission_id = p_submission_id;

  RETURN result;
END;
$$;
```

---

## Graceful Degradation Component: Full → Partial → Loading → Error

The component must never crash regardless of data state. It degrades gracefully through four tiers.

```tsx
// components/results/SubmissionResultCard.tsx
'use client';

import React from 'react';
import { normalizeSubmissionResult } from '@/types/results';
import type { RawSubmissionResult, NormalizedJudgeResult, NormalizedLaneScore } from '@/types/results';

interface SubmissionResultCardProps {
  raw: RawSubmissionResult | null | undefined;
  isLoading?: boolean;
  error?: Error | null;
}

export function SubmissionResultCard({
  raw,
  isLoading = false,
  error = null,
}: SubmissionResultCardProps) {
  // Tier 4: Error state
  if (error) {
    return <ResultErrorState message={error.message} />;
  }

  // Tier 3: Loading state (data not arrived yet)
  if (isLoading || raw === undefined) {
    return <ResultSkeletonState />;
  }

  // Tier 3b: Not found
  if (raw === null) {
    return <ResultNotFoundState />;
  }

  const result = normalizeSubmissionResult(raw);

  // Tier 2: Partial state (some judges pending)
  if (!result.isFullyScored) {
    return <ResultPartialState result={result} />;
  }

  // Tier 1: Full state
  return <ResultFullState result={result} />;
}

// ─── Error State ───────────────────────────────────────────────────────────────

function ResultErrorState({ message }: { message: string }) {
  return (
    <div className="rounded-lg border border-red-200 bg-red-50 p-6">
      <div className="flex items-start gap-3">
        <div className="mt-0.5 h-5 w-5 shrink-0 rounded-full bg-red-100 flex items-center justify-center">
          <span className="text-red-600 text-xs font-bold">!</span>
        </div>
        <div>
          <p className="text-sm font-semibold text-red-800">Unable to load results</p>
          <p className="mt-1 text-xs text-red-600">{message}</p>
        </div>
      </div>
    </div>
  );
}

// ─── Skeleton State ────────────────────────────────────────────────────────────

function ResultSkeletonState() {
  return (
    <div className="animate-pulse rounded-lg border border-gray-200 bg-white p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div className="h-5 w-32 rounded bg-gray-200" />
        <div className="h-8 w-16 rounded bg-gray-200" />
      </div>
      <div className="grid grid-cols-3 gap-4">
        {[0, 1, 2].map(i => (
          <div key={i} className="h-20 rounded-lg bg-gray-100" />
        ))}
      </div>
      <div className="h-4 w-3/4 rounded bg-gray-100" />
    </div>
  );
}

// ─── Not Found State ───────────────────────────────────────────────────────────

function ResultNotFoundState() {
  return (
    <div className="rounded-lg border border-gray-200 bg-gray-50 p-6 text-center">
      <p className="text-sm text-gray-500">Submission not found</p>
    </div>
  );
}

// ─── Partial State ─────────────────────────────────────────────────────────────

import { NormalizedSubmissionResult } from '@/types/results';

function ResultPartialState({ result }: { result: NormalizedSubmissionResult }) {
  const pendingCount = result.totalJudgeCount - result.completeJudgeCount;

  return (
    <div className="rounded-lg border border-amber-200 bg-white p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="font-semibold text-gray-900">{result.agentName}</h3>
          <p className="text-xs text-amber-600 mt-0.5">
            Scoring in progress — {result.completeJudgeCount}/{result.totalJudgeCount} judges complete
          </p>
        </div>
        <PartialScoreBadge score={result.overallScore} />
      </div>

      {/* Show each judge with their individual status */}
      <div className="space-y-2">
        {result.judgeResults.map(judge => (
          <JudgeStatusRow key={judge.judgeId} judge={judge} />
        ))}
      </div>

      {/* Pending score hint */}
      {pendingCount > 0 && (
        <p className="text-xs text-gray-400">
          Final score will be available when all judges complete.
          {pendingCount === 1 ? ' 1 judge remaining.' : ` ${pendingCount} judges remaining.`}
        </p>
      )}
    </div>
  );
}

function PartialScoreBadge({ score }: { score: number | null }) {
  if (score === null) {
    return (
      <div className="flex items-center gap-1.5 rounded-full bg-amber-100 px-3 py-1">
        <div className="h-2 w-2 rounded-full bg-amber-400 animate-pulse" />
        <span className="text-xs font-medium text-amber-700">Scoring…</span>
      </div>
    );
  }
  return (
    <div className="rounded-full bg-amber-100 px-3 py-1">
      <span className="text-sm font-bold text-amber-800">{score.toFixed(1)}</span>
      <span className="text-xs text-amber-600 ml-0.5">/ 100</span>
    </div>
  );
}

function JudgeStatusRow({ judge }: { judge: NormalizedJudgeResult }) {
  const statusConfig = {
    pending: { color: 'text-gray-400', label: 'Queued', dot: 'bg-gray-300' },
    running: { color: 'text-amber-600', label: 'Scoring…', dot: 'bg-amber-400 animate-pulse' },
    complete: { color: 'text-green-600', label: 'Complete', dot: 'bg-green-500' },
    failed: { color: 'text-red-500', label: 'Failed', dot: 'bg-red-400' },
    timeout: { color: 'text-red-500', label: 'Timed out', dot: 'bg-red-400' },
  };
  const cfg = statusConfig[judge.status];

  // For complete judges, show a brief score summary
  const completedLaneCount = judge.laneScores.filter(ls => ls.isScored).length;

  return (
    <div className="flex items-center justify-between py-1.5 border-b border-gray-100 last:border-0">
      <div className="flex items-center gap-2">
        <div className={`h-2 w-2 rounded-full ${cfg.dot}`} />
        <span className="text-sm text-gray-700">{judge.judgeName}</span>
      </div>
      <div className="flex items-center gap-3">
        {judge.isComplete && (
          <span className="text-xs text-gray-400">
            {completedLaneCount} lane{completedLaneCount !== 1 ? 's' : ''} scored
          </span>
        )}
        <span className={`text-xs font-medium ${cfg.color}`}>{cfg.label}</span>
      </div>
    </div>
  );
}

// ─── Full State ────────────────────────────────────────────────────────────────

function ResultFullState({ result }: { result: NormalizedSubmissionResult }) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="font-semibold text-gray-900">{result.agentName}</h3>
          {result.isLegacyRecord && (
            <span className="text-xs text-gray-400">Legacy submission</span>
          )}
        </div>
        <div className="text-right">
          {result.overallScore !== null ? (
            <>
              <span className="text-3xl font-bold text-gray-900">
                {result.overallScore.toFixed(1)}
              </span>
              <span className="text-sm text-gray-400 ml-1">/ 100</span>
            </>
          ) : (
            <span className="text-sm text-gray-400">Score unavailable</span>
          )}
          {result.rank !== null && (
            <p className="text-xs text-gray-500 mt-0.5">Rank #{result.rank}</p>
          )}
        </div>
      </div>

      {/* Judge breakdown */}
      <div className="space-y-4">
        {result.judgeResults.map(judge => (
          <JudgeBreakdown key={judge.judgeId} judge={judge} isLegacy={result.isLegacyRecord} />
        ))}
      </div>
    </div>
  );
}

function JudgeBreakdown({
  judge,
  isLegacy,
}: {
  judge: NormalizedJudgeResult;
  isLegacy: boolean;
}) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="text-sm font-medium text-gray-700">{judge.judgeName}</span>
        {/* Only show evidence count if refs were actually generated (not null) */}
        {judge.hasEvidenceRefs ? (
          <span className="text-xs text-gray-400">
            {judge.evidenceRefs.length} evidence ref{judge.evidenceRefs.length !== 1 ? 's' : ''}
          </span>
        ) : isLegacy ? (
          <span className="text-xs text-gray-300">No evidence data (legacy)</span>
        ) : null}
      </div>

      <div className="grid gap-2">
        {judge.laneScores.map(lane => (
          <LaneScoreRow key={lane.laneId} lane={lane} isLegacy={isLegacy} />
        ))}
      </div>
    </div>
  );
}

function LaneScoreRow({
  lane,
  isLegacy,
}: {
  lane: NormalizedLaneScore;
  isLegacy: boolean;
}) {
  const scorePercent = lane.isScored && lane.maxScore > 0
    ? (lane.score! / lane.maxScore) * 100
    : null;

  return (
    <div className="flex items-center gap-3">
      <span className="w-32 shrink-0 text-xs text-gray-500 truncate">{lane.laneName}</span>

      {/* Score display — 0 is valid, never use falsy check */}
      <div className="flex-1">
        {lane.isScored && scorePercent !== null ? (
          <div className="flex items-center gap-2">
            <div className="flex-1 h-1.5 rounded-full bg-gray-100">
              <div
                className="h-full rounded-full bg-indigo-500"
                style={{ width: `${scorePercent}%` }}
              />
            </div>
            <span className="text-xs font-medium text-gray-700 w-8 text-right">
              {lane.score}
            </span>
          </div>
        ) : (
          <span className="text-xs text-gray-300">
            {lane.status === 'scoring' ? 'Scoring…' : 'Pending'}
          </span>
        )}
      </div>

      {/* Confidence — only show if field was present (not legacy null) */}
      {lane.hasConfidence ? (
        <span className="text-xs text-gray-400 w-10 text-right">
          {((lane.confidence ?? 0) * 100).toFixed(0)}%
        </span>
      ) : isLegacy ? (
        <span className="text-xs text-gray-300 w-10 text-right">N/A</span>
      ) : (
        <span className="text-xs text-gray-300 w-10 text-right">—</span>
      )}
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Falsy checks on zero-valid fields

```tsx
// BAD — score of 0 shows "No score" which is wrong
{score || 'No score'}

// BAD — confidence of 0 shows "—" which implies missing data
{confidence ? `${(confidence * 100).toFixed(0)}%` : '—'}

// GOOD — explicit null check
{score !== null ? score : 'No score'}

// GOOD — explicit null check for confidence
{confidence !== null ? `${(confidence * 100).toFixed(0)}%` : '—'}
```

### ❌ Array index access for judge results

```tsx
// BAD — if Gemini is missing, this shows GPT-4o data for Gemini slot
const geminiResult = judgeResults[2]; // WRONG

// GOOD — key by judge ID
const judgeById = Object.fromEntries(judgeResults.map(j => [j.judgeId, j]));
const geminiResult = judgeById['gemini'] ?? null;
```

### ❌ Treating null evidence_refs as empty array without distinction

```tsx
// BAD — null (judge didn't produce refs) shows same as [] (judge produced no refs)
const refs = evidence_refs ?? [];
// Then: {refs.length === 0 && <p>No evidence</p>}
// This shows "No evidence" for both "judge crashed" and "judge found nothing"

// GOOD — distinguish the two cases
const hasEvidenceRefs = evidence_refs !== null;
const refs = evidence_refs ?? [];
{!hasEvidenceRefs && <p className="text-gray-300">Evidence not available</p>}
{hasEvidenceRefs && refs.length === 0 && <p className="text-gray-400">No evidence found by this judge</p>}
{hasEvidenceRefs && refs.length > 0 && <EvidenceList refs={refs} />}
```

### ❌ Crashing on legacy records without confidence column

```tsx
// BAD — shows "0%" for legacy records that never had confidence scored
<span>{((lane.confidence ?? 0) * 100).toFixed(0)}%</span>

// GOOD — check schema version to distinguish "0% confidence" from "no data"
<span>
  {lane.hasConfidence
    ? `${((lane.confidence ?? 0) * 100).toFixed(0)}%`
    : 'N/A'}
</span>
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| `result.judge_results.map(...)` on null judge_results | Runtime crash: "Cannot read properties of null (reading 'map')" | Normalize to empty array: `(raw.judge_results ?? []).map(...)` |
| `confidence || 0` coercion | Agent with 0% confidence shown as missing; 0.8 confidence shown correctly | Use `confidence ?? null` — preserve 0 as valid |
| `judgeResults[2]` index assumption | Shows wrong judge data when a judge is absent from response | Key results by `judge_id`, never by array position |
| Legacy row displayed with "0% confidence" | Misleads users that judge had no confidence in the score | Check `schema_version < 2` or `confidence === null` — show "N/A" |
| Partial average displayed as final score | Shows interim average as if scoring is complete | Never compute average until `isFullyScored === true` |
| Empty and null evidence_refs shown identically | Users can't tell if judge failed vs found no evidence | Track `hasEvidenceRefs` (was the field present?) separately from refs content |
| Missing COALESCE on new columns in old rows | Query returns error or null where app expects number | Add `COALESCE(new_column, null)` in SQL, handle null in normalization layer |
| `score || '—'` in render | Score of 0 displays as "—" — valid scores suppressed | Always `score !== null ? score : '—'` |
| No loading skeleton — only "not found" | Page flashes empty state during SSR hydration | Add explicit `isLoading` prop, render skeleton before data arrives |
| `new Date(null)` called on unset `completed_at` | Invalid Date object propagates into display, shows "NaN" | Guard: `completed_at ? new Date(completed_at) : null` |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
