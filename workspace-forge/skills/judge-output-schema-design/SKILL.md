---
name: judge-output-schema-design
description: Define the raw output contract for Bouts AI judges — lane scores, dimension breakdowns, evidence refs, confidence, flags, and integrity adjustments — with Zod validation, SQL storage, and multi-judge reconciliation logic.
---

# Judge Output Schema Design

## Review Checklist

1. **Schema version in every output**: Every judge output record must include `schema_version` (e.g., `"2.1"`). Query: `SELECT COUNT(*) FROM judge_outputs WHERE schema_version IS NULL` — must be 0 in production.
2. **Evidence refs are structured, not text blobs**: `evidence_refs` must store `{type, id, location}` objects, not strings like "line 45 shows..." — verify Zod schema rejects plain string evidence.
3. **Partial output handling**: When a judge times out or errors mid-run, the system must store what was computed plus a `failure_reason`. Verify: simulate a judge that returns 3/5 lane scores and confirm the partial result is stored and flagged.
4. **Confidence reasoning is required when confidence is low**: If `confidence === 'low'`, `confidence_reasoning` must be non-empty. Add `.refine()` on the Zod schema enforcing this.
5. **Multi-judge reconciliation stores all raw outputs**: The reconciled/aggregated score must never overwrite raw judge outputs. Verify: `SELECT COUNT(*) FROM judge_outputs WHERE evaluation_run_id = $1` returns N rows for N judges.
6. **Integrity adjustments are bounded**: Each `integrity_adjustment.deduction` must be between -50 and 0. Unbounded deductions allow a judge bug to wipe a score to negative. Add constraint.
7. **Lane score vs computed weighted score consistency check**: After loading a judge output, recompute `sum(dimension_score * dimension_weight)` and verify it's within 1 point of `lane_score`. Log a warning if divergent.
8. **Telemetry summaries are present for all evaluation runs**: `tool_call_count`, `step_count`, and `error_rate` must be non-null for any run that had telemetry available. Verify: runs without telemetry store explicit `null` with a `telemetry_unavailable_reason` field.
9. **Flags have machine-readable codes, not just prose**: Each flag must include a `flag_code` (e.g., `COPY_PASTE_DETECTED`) so downstream logic can filter/gate on it. Prose-only flags can't be processed programmatically.
10. **Failed judge doesn't block display**: When one judge fails, the UI must show results from the N-1 judges with a "One judge unavailable" notice. Verify this path in the reconciliation logic.
11. **Schema migration is additive-only**: When adding fields to the judge output schema, new fields must be optional with defaults. Verify: loading a v1.0 record with a v2.0 schema returns a valid object, not a parse error.
12. **positive_signal and primary_weakness are not duplicates of lane score text**: These fields must contain specific observations (a concrete thing the submission did), not summaries of scores. Add a minimum-specificity check at storage time.

---

## Complete Zod Schema: Full Judge Output Contract

```typescript
// lib/judges/judge-output-schema.ts
import { z } from 'zod';

// ---- Sub-schemas ----

const EvidenceRefSchema = z.object({
  type: z.enum([
    'transcript_line',    // line number in the AI's conversation transcript
    'tool_call',          // tool call ID from agent trace
    'diff_hunk',          // git diff hunk reference (file:line-start:line-end)
    'test_result',        // test case ID + pass/fail
    'code_artifact',      // file path + line range
    'error_event',        // error type + timestamp offset
  ]),
  id: z.string().min(1),           // the primary identifier (line number, tool call ID, etc.)
  location: z.string().optional(), // secondary locator (file path, timestamp, etc.)
  excerpt: z.string().max(300).optional(), // short quoted text, max 300 chars
});

const IntegrityAdjustmentSchema = z.object({
  flag_code: z.string().regex(/^[A-Z_]+$/, 'flag_code must be SCREAMING_SNAKE_CASE'),
  description: z.string().min(10),
  deduction: z.number().min(-50).max(0),  // always negative or zero
  evidence_refs: z.array(EvidenceRefSchema).min(1, 'Integrity adjustment must cite evidence'),
});

const FlagSchema = z.object({
  flag_code: z.string().regex(/^[A-Z_]+$/),  // e.g. COPY_PASTE_DETECTED, PROMPT_INJECTION_ATTEMPT
  severity: z.enum(['info', 'warning', 'critical']),
  description: z.string().min(5),
  evidence_refs: z.array(EvidenceRefSchema).optional(),
  auto_disqualify: z.boolean().default(false),
});

const DimensionScoreSchema = z.object({
  dimension_key: z.string().regex(/^[a-z_]+$/),
  score: z.number().int().min(0).max(100),
  reasoning: z.string().min(20, 'Dimension reasoning must be substantive (>20 chars)'),
  evidence_refs: z.array(EvidenceRefSchema).min(0).max(10),
  band_label: z.string(), // which scoring band this falls into (e.g. "Strong")
});

const LaneScoreSchema = z.object({
  lane_key: z.string().regex(/^[a-z_]+$/),
  lane_score: z.number().int().min(0).max(100),
  dimension_scores: z.array(DimensionScoreSchema).min(1),
  // lane_score must be roughly consistent with weighted dimension average
}).refine(
  (lane) => {
    // We can't validate weights here (not in schema), but we flag obvious divergence
    // Full consistency check done in loadAndValidateJudgeOutput()
    return lane.lane_score >= 0 && lane.lane_score <= 100;
  }
);

const TelemetrySummarySchema = z.object({
  tool_call_count: z.number().int().min(0).nullable(),
  step_count: z.number().int().min(0).nullable(),
  error_count: z.number().int().min(0).nullable(),
  error_rate: z.number().min(0).max(1).nullable(),  // errors / steps
  total_tokens_used: z.number().int().min(0).nullable(),
  wall_time_seconds: z.number().min(0).nullable(),
  telemetry_unavailable_reason: z.string().nullable(),
});

// ---- Main Judge Output Schema ----

export const JudgeOutputSchema = z.object({
  schema_version: z.string().regex(/^\d+\.\d+$/, 'Must be semver minor: "2.1"'),
  judge_model: z.string().min(3),  // e.g. "claude-opus-4-6", "gpt-4o", "gemini-1.5-pro"
  judge_run_id: z.string().uuid(),
  evaluation_run_id: z.string().uuid(),
  submission_id: z.string().uuid(),
  rubric_version_id: z.string().uuid(),

  // Top-level scores
  overall_score: z.number().int().min(0).max(100),
  lane_scores: z.array(LaneScoreSchema).min(1),

  // Qualitative signals — these must be specific, not generic
  positive_signal: z.string().min(20).max(500),
  primary_weakness: z.string().min(20).max(500),

  // Confidence
  confidence: z.enum(['high', 'medium', 'low']),
  confidence_reasoning: z.string(),

  // Integrity
  flags: z.array(FlagSchema).default([]),
  integrity_adjustments: z.array(IntegrityAdjustmentSchema).default([]),
  integrity_adjusted_score: z.number().int().min(0).max(100),

  // Telemetry
  telemetry_summary: TelemetrySummarySchema,

  // Status
  status: z.enum(['complete', 'partial', 'failed']),
  failure_reason: z.string().nullable(),
  completed_lane_keys: z.array(z.string()),  // which lanes were actually scored

  // Timestamps
  judge_started_at: z.string().datetime(),
  judge_completed_at: z.string().datetime().nullable(),

}).refine(
  (output) => {
    // If confidence is low, reasoning must be substantive
    if (output.confidence === 'low' && output.confidence_reasoning.length < 20) {
      return false;
    }
    return true;
  },
  { message: 'confidence_reasoning must be substantive when confidence is low', path: ['confidence_reasoning'] }
).refine(
  (output) => {
    // Integrity adjusted score can only be <= overall_score (deductions only)
    return output.integrity_adjusted_score <= output.overall_score;
  },
  { message: 'integrity_adjusted_score cannot exceed overall_score', path: ['integrity_adjusted_score'] }
).refine(
  (output) => {
    // If status is 'failed', failure_reason must be present
    if (output.status === 'failed' && !output.failure_reason) return false;
    return true;
  },
  { message: 'failed outputs must include failure_reason', path: ['failure_reason'] }
);

export type JudgeOutput = z.infer<typeof JudgeOutputSchema>;
export type LaneScore = z.infer<typeof LaneScoreSchema>;
export type DimensionScore = z.infer<typeof DimensionScoreSchema>;
export type EvidenceRef = z.infer<typeof EvidenceRefSchema>;
export type IntegrityAdjustment = z.infer<typeof IntegrityAdjustmentSchema>;
export type TelemetrySummary = z.infer<typeof TelemetrySummarySchema>;
```

---

## SQL Migration: Judge Output Storage

```sql
-- migrations/20260331_judge_outputs.sql

CREATE TABLE judge_outputs (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_run_id         UUID NOT NULL REFERENCES evaluation_runs(id),
  submission_id             UUID NOT NULL REFERENCES submissions(id),
  rubric_version_id         UUID NOT NULL REFERENCES rubrics(id),
  judge_run_id              UUID NOT NULL UNIQUE,

  -- Identity
  judge_model               TEXT NOT NULL,
  schema_version            TEXT NOT NULL,

  -- Scores
  overall_score             INTEGER CHECK (overall_score BETWEEN 0 AND 100),
  integrity_adjusted_score  INTEGER CHECK (integrity_adjusted_score BETWEEN 0 AND 100),

  -- Qualitative
  positive_signal           TEXT,
  primary_weakness          TEXT,

  -- Confidence
  confidence                TEXT CHECK (confidence IN ('high', 'medium', 'low')),
  confidence_reasoning      TEXT,

  -- Status
  status                    TEXT NOT NULL CHECK (status IN ('complete', 'partial', 'failed')),
  failure_reason            TEXT,
  completed_lane_keys       TEXT[] NOT NULL DEFAULT '{}',

  -- Timestamps
  judge_started_at          TIMESTAMPTZ NOT NULL,
  judge_completed_at        TIMESTAMPTZ,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Integrity check: adjusted_score <= overall_score
  CONSTRAINT adjusted_lte_overall CHECK (integrity_adjusted_score <= overall_score)
);

-- Store lane scores normalized (not in JSONB)
CREATE TABLE judge_lane_scores (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_output_id   UUID NOT NULL REFERENCES judge_outputs(id) ON DELETE CASCADE,
  lane_key          TEXT NOT NULL,
  lane_score        INTEGER NOT NULL CHECK (lane_score BETWEEN 0 AND 100),
  UNIQUE (judge_output_id, lane_key)
);

-- Store dimension scores normalized
CREATE TABLE judge_dimension_scores (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lane_score_id     UUID NOT NULL REFERENCES judge_lane_scores(id) ON DELETE CASCADE,
  dimension_key     TEXT NOT NULL,
  score             INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  reasoning         TEXT NOT NULL,
  band_label        TEXT NOT NULL,
  UNIQUE (lane_score_id, dimension_key)
);

-- Evidence refs — normalized, typed
CREATE TABLE judge_evidence_refs (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_output_id     UUID NOT NULL REFERENCES judge_outputs(id) ON DELETE CASCADE,
  parent_type         TEXT NOT NULL CHECK (parent_type IN ('dimension_score', 'integrity_adjustment', 'flag')),
  parent_id           UUID NOT NULL,  -- references judge_dimension_scores.id, etc.
  ref_type            TEXT NOT NULL,  -- transcript_line, tool_call, diff_hunk, etc.
  ref_id              TEXT NOT NULL,
  ref_location        TEXT,
  excerpt             TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Flags
CREATE TABLE judge_flags (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_output_id   UUID NOT NULL REFERENCES judge_outputs(id) ON DELETE CASCADE,
  flag_code         TEXT NOT NULL,
  severity          TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  description       TEXT NOT NULL,
  auto_disqualify   BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Integrity adjustments
CREATE TABLE judge_integrity_adjustments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_output_id   UUID NOT NULL REFERENCES judge_outputs(id) ON DELETE CASCADE,
  flag_code         TEXT NOT NULL,
  description       TEXT NOT NULL,
  deduction         INTEGER NOT NULL CHECK (deduction BETWEEN -50 AND 0),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Telemetry
CREATE TABLE judge_telemetry (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_output_id             UUID NOT NULL UNIQUE REFERENCES judge_outputs(id) ON DELETE CASCADE,
  tool_call_count             INTEGER,
  step_count                  INTEGER,
  error_count                 INTEGER,
  error_rate                  NUMERIC(5,4),
  total_tokens_used           INTEGER,
  wall_time_seconds           NUMERIC(10,2),
  telemetry_unavailable_reason TEXT
);

-- Reconciled scores (post-multi-judge aggregation)
CREATE TABLE evaluation_reconciled_scores (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_run_id         UUID NOT NULL UNIQUE REFERENCES evaluation_runs(id),
  submission_id             UUID NOT NULL REFERENCES submissions(id),
  judge_count               INTEGER NOT NULL,
  successful_judge_count    INTEGER NOT NULL,
  final_overall_score       NUMERIC(5,2),  -- weighted average across judges
  final_adjusted_score      NUMERIC(5,2),
  reconciliation_method     TEXT NOT NULL,  -- 'mean', 'median', 'weighted_judge_confidence'
  has_contradictions        BOOLEAN NOT NULL DEFAULT false,
  contradiction_details     JSONB,  -- which lanes had contradictions
  finalized_at              TIMESTAMPTZ,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_judge_outputs_eval_run ON judge_outputs(evaluation_run_id);
CREATE INDEX idx_judge_outputs_submission ON judge_outputs(submission_id);
CREATE INDEX idx_judge_outputs_status ON judge_outputs(status);
CREATE INDEX idx_judge_lane_scores_output ON judge_lane_scores(judge_output_id);
CREATE INDEX idx_judge_dimension_scores_lane ON judge_dimension_scores(lane_score_id);
CREATE INDEX idx_judge_evidence_refs_parent ON judge_evidence_refs(parent_id, parent_type);
CREATE INDEX idx_judge_flags_output ON judge_flags(judge_output_id);
CREATE INDEX idx_judge_flags_code ON judge_flags(flag_code);
CREATE INDEX idx_reconciled_scores_submission ON evaluation_reconciled_scores(submission_id);
```

---

## TypeScript: Judge Runner Types and Multi-Judge Reconciliation

```typescript
// lib/judges/judge-runner.ts
import { z } from 'zod';
import { JudgeOutputSchema, type JudgeOutput } from './judge-output-schema';
import { createClient } from '@/lib/supabase/server';

// ---- Judge Runner Interface ----

export interface JudgeRunConfig {
  judgeModel: 'claude-opus-4-6' | 'gpt-4o' | 'gemini-1.5-pro';
  evaluationRunId: string;
  submissionId: string;
  rubricVersionId: string;
  submissionTranscript: string;    // raw agent transcript
  telemetryTrace: TelemetryTrace | null;
  timeoutMs: number;               // hard timeout per judge
}

export interface TelemetryTrace {
  toolCalls: Array<{ id: string; name: string; timestamp: number; success: boolean }>;
  steps: Array<{ stepNumber: number; type: string; timestamp: number }>;
  errors: Array<{ type: string; message: string; timestamp: number }>;
  totalTokens: number;
  wallTimeSeconds: number;
}

// ---- Store Judge Output ----

export async function storeJudgeOutput(output: JudgeOutput): Promise<string> {
  const supabase = createClient();

  // 1. Insert top-level judge_output record
  const { data: outputRow, error: outputError } = await supabase
    .from('judge_outputs')
    .insert({
      evaluation_run_id: output.evaluation_run_id,
      submission_id: output.submission_id,
      rubric_version_id: output.rubric_version_id,
      judge_run_id: output.judge_run_id,
      judge_model: output.judge_model,
      schema_version: output.schema_version,
      overall_score: output.overall_score,
      integrity_adjusted_score: output.integrity_adjusted_score,
      positive_signal: output.positive_signal,
      primary_weakness: output.primary_weakness,
      confidence: output.confidence,
      confidence_reasoning: output.confidence_reasoning,
      status: output.status,
      failure_reason: output.failure_reason,
      completed_lane_keys: output.completed_lane_keys,
      judge_started_at: output.judge_started_at,
      judge_completed_at: output.judge_completed_at,
    })
    .select('id')
    .single();

  if (outputError || !outputRow) {
    throw new Error(`Failed to store judge output: ${outputError?.message}`);
  }

  const judgeOutputId = outputRow.id;

  // 2. Insert lane scores + dimension scores
  for (const laneScore of output.lane_scores) {
    const { data: laneRow } = await supabase
      .from('judge_lane_scores')
      .insert({
        judge_output_id: judgeOutputId,
        lane_key: laneScore.lane_key,
        lane_score: laneScore.lane_score,
      })
      .select('id')
      .single();

    if (!laneRow) continue;

    for (const dim of laneScore.dimension_scores) {
      const { data: dimRow } = await supabase
        .from('judge_dimension_scores')
        .insert({
          lane_score_id: laneRow.id,
          dimension_key: dim.dimension_key,
          score: dim.score,
          reasoning: dim.reasoning,
          band_label: dim.band_label,
        })
        .select('id')
        .single();

      if (!dimRow) continue;

      // 3. Insert evidence refs for this dimension
      if (dim.evidence_refs.length > 0) {
        await supabase.from('judge_evidence_refs').insert(
          dim.evidence_refs.map((ref) => ({
            judge_output_id: judgeOutputId,
            parent_type: 'dimension_score',
            parent_id: dimRow.id,
            ref_type: ref.type,
            ref_id: ref.id,
            ref_location: ref.location ?? null,
            excerpt: ref.excerpt ?? null,
          }))
        );
      }
    }
  }

  // 4. Insert flags
  if (output.flags.length > 0) {
    await supabase.from('judge_flags').insert(
      output.flags.map((flag) => ({
        judge_output_id: judgeOutputId,
        flag_code: flag.flag_code,
        severity: flag.severity,
        description: flag.description,
        auto_disqualify: flag.auto_disqualify,
      }))
    );
  }

  // 5. Insert integrity adjustments
  if (output.integrity_adjustments.length > 0) {
    await supabase.from('judge_integrity_adjustments').insert(
      output.integrity_adjustments.map((adj) => ({
        judge_output_id: judgeOutputId,
        flag_code: adj.flag_code,
        description: adj.description,
        deduction: adj.deduction,
      }))
    );
  }

  // 6. Insert telemetry
  await supabase.from('judge_telemetry').insert({
    judge_output_id: judgeOutputId,
    tool_call_count: output.telemetry_summary.tool_call_count,
    step_count: output.telemetry_summary.step_count,
    error_count: output.telemetry_summary.error_count,
    error_rate: output.telemetry_summary.error_rate,
    total_tokens_used: output.telemetry_summary.total_tokens_used,
    wall_time_seconds: output.telemetry_summary.wall_time_seconds,
    telemetry_unavailable_reason: output.telemetry_summary.telemetry_unavailable_reason,
  });

  return judgeOutputId;
}

// ---- Multi-Judge Reconciliation ----

export interface ReconciliationResult {
  finalOverallScore: number;
  finalAdjustedScore: number;
  judgeCount: number;
  successfulJudgeCount: number;
  hasContradictions: boolean;
  contradictionDetails: ContradictionDetail[];
  laneScoresByJudge: Record<string, Record<string, number>>; // judgeModel -> laneKey -> score
  reconciledLaneScores: Record<string, number>;
  method: 'mean' | 'median' | 'weighted_judge_confidence';
}

export interface ContradictionDetail {
  laneKey: string;
  scores: Array<{ judgeModel: string; score: number }>;
  spread: number;  // max - min
}

export function reconcileJudgeOutputs(
  outputs: JudgeOutput[],
  method: 'mean' | 'median' | 'weighted_judge_confidence' = 'mean'
): ReconciliationResult {
  const successfulOutputs = outputs.filter((o) => o.status !== 'failed');

  if (successfulOutputs.length === 0) {
    throw new Error('Cannot reconcile: no successful judge outputs');
  }

  // Build lane score map per judge
  const laneScoresByJudge: Record<string, Record<string, number>> = {};
  for (const output of successfulOutputs) {
    laneScoresByJudge[output.judge_model] = {};
    for (const lane of output.lane_scores) {
      laneScoresByJudge[output.judge_model][lane.lane_key] = lane.lane_score;
    }
  }

  // Find all lane keys that appear in at least one successful output
  const allLaneKeys = Array.from(
    new Set(successfulOutputs.flatMap((o) => o.lane_scores.map((l) => l.lane_key)))
  );

  // Detect contradictions (spread > 25 points on a lane)
  const contradictionDetails: ContradictionDetail[] = [];
  const reconciledLaneScores: Record<string, number> = {};

  for (const laneKey of allLaneKeys) {
    const scores = successfulOutputs
      .filter((o) => laneScoresByJudge[o.judge_model][laneKey] !== undefined)
      .map((o) => ({
        judgeModel: o.judge_model,
        score: laneScoresByJudge[o.judge_model][laneKey],
      }));

    if (scores.length === 0) continue;

    const scoreValues = scores.map((s) => s.score);
    const spread = Math.max(...scoreValues) - Math.min(...scoreValues);

    if (spread > 25) {
      contradictionDetails.push({ laneKey, scores, spread });
    }

    // Reconcile by method
    if (method === 'mean') {
      reconciledLaneScores[laneKey] = Math.round(
        scoreValues.reduce((a, b) => a + b, 0) / scoreValues.length
      );
    } else if (method === 'median') {
      const sorted = [...scoreValues].sort((a, b) => a - b);
      const mid = Math.floor(sorted.length / 2);
      reconciledLaneScores[laneKey] = sorted.length % 2 !== 0
        ? sorted[mid]
        : Math.round((sorted[mid - 1] + sorted[mid]) / 2);
    } else {
      // weighted by confidence: high=1.0, medium=0.7, low=0.4
      const confidenceWeights: Record<string, number> = { high: 1.0, medium: 0.7, low: 0.4 };
      const judgeConfidence: Record<string, number> = {};
      for (const o of successfulOutputs) {
        judgeConfidence[o.judge_model] = confidenceWeights[o.confidence] ?? 0.7;
      }

      let weightedSum = 0;
      let totalWeight = 0;
      for (const { judgeModel, score } of scores) {
        const w = judgeConfidence[judgeModel] ?? 0.7;
        weightedSum += score * w;
        totalWeight += w;
      }
      reconciledLaneScores[laneKey] = Math.round(weightedSum / totalWeight);
    }
  }

  // Compute final overall score (simple mean across lanes — caller applies rubric weights separately)
  const laneValues = Object.values(reconciledLaneScores);
  const finalOverallScore = Math.round(
    laneValues.reduce((a, b) => a + b, 0) / laneValues.length
  );

  // Compute adjusted score: apply worst-case integrity adjustments across judges
  const worstTotalDeduction = successfulOutputs.reduce((worst, o) => {
    const totalDeduction = o.integrity_adjustments.reduce((sum, adj) => sum + adj.deduction, 0);
    return Math.min(worst, totalDeduction);
  }, 0);

  const finalAdjustedScore = Math.max(0, finalOverallScore + worstTotalDeduction);

  return {
    finalOverallScore,
    finalAdjustedScore,
    judgeCount: outputs.length,
    successfulJudgeCount: successfulOutputs.length,
    hasContradictions: contradictionDetails.length > 0,
    contradictionDetails,
    laneScoresByJudge,
    reconciledLaneScores,
    method,
  };
}

// ---- Validate and Load from DB ----

export async function loadAndValidateJudgeOutput(
  judgeRunId: string
): Promise<{ output: JudgeOutput; warnings: string[] }> {
  const supabase = createClient();
  const warnings: string[] = [];

  const { data: row, error } = await supabase
    .from('judge_outputs')
    .select(`
      *,
      lane_scores:judge_lane_scores(
        *,
        dimension_scores:judge_dimension_scores(*),
        evidence_refs:judge_evidence_refs(*)
      ),
      flags:judge_flags(*),
      integrity_adjustments:judge_integrity_adjustments(*),
      telemetry:judge_telemetry(*)
    `)
    .eq('judge_run_id', judgeRunId)
    .single();

  if (error || !row) {
    throw new Error(`Judge output not found: ${judgeRunId}`);
  }

  // Reconstruct the JudgeOutput shape for validation
  const raw = {
    schema_version: row.schema_version,
    judge_model: row.judge_model,
    judge_run_id: row.judge_run_id,
    evaluation_run_id: row.evaluation_run_id,
    submission_id: row.submission_id,
    rubric_version_id: row.rubric_version_id,
    overall_score: row.overall_score,
    integrity_adjusted_score: row.integrity_adjusted_score,
    positive_signal: row.positive_signal,
    primary_weakness: row.primary_weakness,
    confidence: row.confidence,
    confidence_reasoning: row.confidence_reasoning,
    status: row.status,
    failure_reason: row.failure_reason,
    completed_lane_keys: row.completed_lane_keys,
    judge_started_at: row.judge_started_at,
    judge_completed_at: row.judge_completed_at,
    lane_scores: (row.lane_scores ?? []).map((lane: any) => ({
      lane_key: lane.lane_key,
      lane_score: lane.lane_score,
      dimension_scores: (lane.dimension_scores ?? []).map((dim: any) => ({
        dimension_key: dim.dimension_key,
        score: dim.score,
        reasoning: dim.reasoning,
        band_label: dim.band_label,
        evidence_refs: (lane.evidence_refs ?? [])
          .filter((ref: any) => ref.parent_id === dim.id)
          .map((ref: any) => ({
            type: ref.ref_type,
            id: ref.ref_id,
            location: ref.ref_location,
            excerpt: ref.excerpt,
          })),
      })),
    })),
    flags: (row.flags ?? []).map((f: any) => ({
      flag_code: f.flag_code,
      severity: f.severity,
      description: f.description,
      auto_disqualify: f.auto_disqualify,
    })),
    integrity_adjustments: (row.integrity_adjustments ?? []).map((adj: any) => ({
      flag_code: adj.flag_code,
      description: adj.description,
      deduction: adj.deduction,
      evidence_refs: [],
    })),
    telemetry_summary: row.telemetry
      ? {
          tool_call_count: row.telemetry.tool_call_count,
          step_count: row.telemetry.step_count,
          error_count: row.telemetry.error_count,
          error_rate: row.telemetry.error_rate,
          total_tokens_used: row.telemetry.total_tokens_used,
          wall_time_seconds: row.telemetry.wall_time_seconds,
          telemetry_unavailable_reason: row.telemetry.telemetry_unavailable_reason,
        }
      : {
          tool_call_count: null, step_count: null, error_count: null,
          error_rate: null, total_tokens_used: null, wall_time_seconds: null,
          telemetry_unavailable_reason: 'Telemetry record missing',
        },
  };

  const result = JudgeOutputSchema.safeParse(raw);
  if (!result.success) {
    throw new Error(`Judge output validation failed: ${JSON.stringify(result.error.issues)}`);
  }

  // Post-parse consistency check: lane_score vs weighted dimension average
  for (const lane of result.data.lane_scores) {
    if (lane.dimension_scores.length > 1) {
      const dimAvg = lane.dimension_scores.reduce((s, d) => s + d.score, 0) / lane.dimension_scores.length;
      if (Math.abs(dimAvg - lane.lane_score) > 10) {
        warnings.push(
          `Lane ${lane.lane_key}: lane_score (${lane.lane_score}) diverges >10pts from dimension average (${Math.round(dimAvg)})`
        );
      }
    }
  }

  return { output: result.data, warnings };
}
```

---

## Anti-Patterns

### Anti-Pattern 1: Storing evidence as text blobs

```typescript
// ❌ BAD: Cannot be processed, linked, or verified
const badOutput = {
  lane_scores: [{
    lane_key: 'correctness',
    evidence: 'Line 45 shows the solution fails to handle null inputs. Also the tool call at step 3 crashed.',
  }],
};
// You can't click to line 45. You can't link to step 3. You can't filter by evidence type.

// ✅ GOOD: Structured refs that can be rendered and linked
const goodOutput = {
  lane_scores: [{
    lane_key: 'correctness',
    dimension_scores: [{
      dimension_key: 'edge_case_handling',
      score: 35,
      reasoning: 'Solution crashes on null input at line 45 and does not recover from the tool error at step 3',
      evidence_refs: [
        { type: 'transcript_line', id: '45', excerpt: 'TypeError: Cannot read property of null' },
        { type: 'tool_call', id: 'tc_abc123', location: 'step:3', excerpt: 'Error: connection timeout' },
      ],
    }],
  }],
};
```

### Anti-Pattern 2: Overwriting raw judge outputs with reconciled data

```typescript
// ❌ BAD: Loses individual judge signal; can't audit later
async function saveReconciled(evalRunId: string, reconciledScore: number) {
  await supabase
    .from('judge_outputs')
    .update({ overall_score: reconciledScore })  // DESTROYS individual judge data
    .eq('evaluation_run_id', evalRunId);
}

// ✅ GOOD: Store reconciliation in separate table; preserve all raw outputs
async function saveReconciled(evalRunId: string, result: ReconciliationResult) {
  // Raw judge_outputs rows are never modified after creation
  await supabase.from('evaluation_reconciled_scores').insert({
    evaluation_run_id: evalRunId,
    judge_count: result.judgeCount,
    successful_judge_count: result.successfulJudgeCount,
    final_overall_score: result.finalOverallScore,
    final_adjusted_score: result.finalAdjustedScore,
    reconciliation_method: result.method,
    has_contradictions: result.hasContradictions,
    contradiction_details: result.contradictionDetails,
    finalized_at: new Date().toISOString(),
  });
}
```

### Anti-Pattern 3: Failing fast when one judge fails

```typescript
// ❌ BAD: One judge timeout kills the entire evaluation
async function runAllJudges(configs: JudgeRunConfig[]) {
  const outputs = await Promise.all(configs.map(runSingleJudge));
  // If any throws, everything fails
  return reconcileJudgeOutputs(outputs);
}

// ✅ GOOD: Collect partial results, fail gracefully
async function runAllJudges(configs: JudgeRunConfig[]) {
  const results = await Promise.allSettled(configs.map(runSingleJudge));

  const outputs: JudgeOutput[] = results.map((r, i) => {
    if (r.status === 'fulfilled') return r.value;

    // Return a failed stub so storage and reconciliation still work
    return {
      schema_version: '2.1',
      judge_model: configs[i].judgeModel,
      judge_run_id: crypto.randomUUID(),
      evaluation_run_id: configs[i].evaluationRunId,
      submission_id: configs[i].submissionId,
      rubric_version_id: configs[i].rubricVersionId,
      overall_score: 0,
      lane_scores: [],
      positive_signal: 'N/A — judge failed',
      primary_weakness: 'N/A — judge failed',
      confidence: 'low' as const,
      confidence_reasoning: `Judge failed: ${r.reason?.message ?? 'unknown error'}`,
      flags: [],
      integrity_adjustments: [],
      integrity_adjusted_score: 0,
      telemetry_summary: {
        tool_call_count: null, step_count: null, error_count: null,
        error_rate: null, total_tokens_used: null, wall_time_seconds: null,
        telemetry_unavailable_reason: r.reason?.message ?? 'judge_failed',
      },
      status: 'failed' as const,
      failure_reason: r.reason?.message ?? 'unknown',
      completed_lane_keys: [],
      judge_started_at: new Date().toISOString(),
      judge_completed_at: new Date().toISOString(),
    };
  });

  // Store all (including failed stubs)
  await Promise.all(outputs.map(storeJudgeOutput));

  return reconcileJudgeOutputs(outputs);
}
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| `schema_version` not pinned at evaluation time | Judge prompt changes silently; old records can't be interpreted correctly against current schema | Store schema_version in the judge output row; load the correct validator version for display |
| Evidence refs are text, not structured objects | Can't render "click to line 45" links; can't filter by evidence type; can't build evidence panels | Enforce `EvidenceRefSchema` via Zod; reject plain string evidence in the judge prompt's output format |
| `integrity_adjusted_score` > `overall_score` | A judge applies a positive "adjustment" (bug in prompt); downstream score shows higher than raw | Add DB constraint `integrity_adjusted_score <= overall_score`; add Zod refine check |
| No lane scores stored for partial/failed outputs | `completed_lane_keys` is empty but not explained; UI can't show which lanes were completed | Store `completed_lane_keys` explicitly; insert lane rows for completed lanes even when status is 'partial' |
| Multi-judge reconciliation deletes raw outputs | Audit log shows reconciled score but no individual judge breakdown; can't investigate contradictions | Use `evaluation_reconciled_scores` table; never UPDATE `judge_outputs` rows |
| Confidence is 'low' but reasoning is empty | User sees "low confidence" with no explanation; trust is lost with no recovery | Add Zod `.refine()`: `confidence === 'low'` requires `confidence_reasoning.length >= 20` |
| `positive_signal` is generic ("Shows good understanding") | Premium feedback reads like AI-generated filler; users feel cheated | Add minimum-specificity check in synthesis layer (see anti-generic skill); store the raw signal without synthesis |
| Judge timeout leaves evaluation_run in 'running' state forever | User never sees results; no error surface | Set explicit judge timeout; always write a 'failed' stub on timeout; add heartbeat check for stale evaluation_runs |
| `deduction` field is positive (typo in judge prompt) | Integrity adjustment increases score instead of decreasing it | DB constraint `deduction BETWEEN -50 AND 0`; Zod `.max(0)` on the deduction field |
| Lane keys in judge output don't match rubric lane keys | Reconciliation can't match lanes; score is silently dropped | Validate `completed_lane_keys` against `rubric.lanes.map(l => l.lane_key)` before storing |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
