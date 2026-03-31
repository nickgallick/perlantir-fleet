---
name: explainable-data-modeling
description: Schema design for Bouts feedback data — model for future questions not just current queries, normalize evidence refs, build audit trails, know when to use JSONB vs columns, and evolve schemas safely without breaking existing records.
---

# Explainable Data Modeling

## Review Checklist

1. **Every JSONB column has a documented evolution contract**: If a JSONB column exists, there must be a comment or migration note explaining what keys are allowed and what triggers a migration to proper columns. Verify: `\d+ table_name` in psql shows column comments.
2. **No raw text is stored where a structured ref would serve**: Any field storing a reference to a specific event (line number, tool call, timestamp) must be a structured object or FK, not a string. Verify: `grep -r "evidence\|ref" --include="*.sql"` — no TEXT columns for refs.
3. **Audit trail tables exist for every mutable domain object**: Rubrics, submissions, scores, and ranks must each have a corresponding `*_change_log` or `*_history` table. Verify each exists.
4. **Operational data and analytical data live in separate tables**: The primary `judge_outputs` table is not the source for analytics queries. Verify: analytical queries run against `*_history` or `*_snapshots` tables, not the live operational tables.
5. **JSONB `scoring_bands` has a max depth of 1**: JSONB blobs that are arrays of flat objects are acceptable. JSONB blobs that contain nested objects within objects are a modeling failure — query time becomes a nightmare.
6. **Every FK has an explicit ON DELETE behavior**: Default (RESTRICT) is sometimes correct, but it must be intentional. Verify: every FK in the schema has either `ON DELETE CASCADE`, `ON DELETE SET NULL`, or is documented as intentionally RESTRICT.
7. **Adding a nullable column to an existing table is a valid migration**: Test: write a migration that adds a `NULLABLE` column to `judge_outputs` and verify no existing rows are affected. The migration must complete in < 1s on 100k rows.
8. **Non-nullable column additions use a two-step migration**: First add nullable with default, backfill, then add NOT NULL constraint. Verify this pattern is used in any migration that adds a required field to a table with existing rows.
9. **Index strategy is documented per table**: Every table with > 10k expected rows must have its index strategy documented. Common access patterns (by bout_id, by user_id, by status) must have covering indexes.
10. **No SELECT * in production queries**: All queries must list columns explicitly. `SELECT *` breaks when columns are added. Verify: grep the codebase for `from('table').select('*')` — each must be reviewed.
11. **Evidence ref normalization is consistent across all tables**: `judge_evidence_refs`, `integrity_adjustment_refs`, and any future ref table must use the same `ref_type`, `ref_id`, `ref_location` schema. Verify no divergence.
12. **Schema change log exists**: The `migrations/` directory is the canonical schema change log. Every migration file is named `YYYYMMDD_description.sql`. Verify: no two files share a date prefix without a numeric disambiguator.

---

## Principle: Model for Future Questions, Not Just Current Queries

The most expensive schema migrations happen when an analytical question emerges that the schema was never designed to answer.

**Examples of future questions Bouts will need to answer:**
- "Which judge model has the highest score variance across dimensions?" (Need: per-dimension scores normalized, with judge_model FK, not buried in JSONB)
- "Do users who score high on correctness but low on efficiency improve on retry?" (Need: per-lane scores across attempts, linkable via user_id and attempt_number)
- "Which rubric version produces the widest score distribution?" (Need: rubric_version_id on every evaluation_run)
- "What % of contradictions occur in the efficiency lane?" (Need: contradiction records with lane_key, not just a boolean flag)

**Design rule**: Before finalizing any table, write 5 hypothetical analytics queries against it. If any require JOIN-explosions through JSONB fields or string parsing, the schema needs to be more normalized.

---

## SQL: Core Feedback Data Model (Full Normalized Schema)

```sql
-- migrations/20260331_core_feedback_model.sql
-- Core tables for Bouts feedback data — designed for explainability and analytics

-- ---- Evidence Reference Normalization ----
-- All evidence refs in the system use this same pattern.
-- Never store raw text — store structured refs.

-- Central ref taxonomy (single source of truth for ref types)
CREATE TYPE evidence_ref_type AS ENUM (
  'transcript_line',   -- Conversation transcript line number
  'tool_call',         -- Agent tool call ID
  'diff_hunk',         -- Git diff hunk (file:line_start:line_end)
  'test_result',       -- Test case ID + outcome
  'code_artifact',     -- File path + line range
  'error_event'        -- Error type + timestamp offset
);

-- Shared evidence_refs table — single table for all evidence in the system
-- Referenced by judge_dimension_scores, integrity_adjustments, and flags
CREATE TABLE evidence_refs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ref_type        evidence_ref_type NOT NULL,
  ref_id          TEXT NOT NULL,        -- The primary identifier
  ref_location    TEXT,                 -- Secondary locator (file path, step number)
  excerpt         TEXT,                 -- Short quoted text, max 300 chars
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (length(excerpt) <= 300)
);

-- Join table: dimension scores to evidence refs (many-to-many)
CREATE TABLE dimension_score_evidence (
  dimension_score_id  UUID NOT NULL REFERENCES judge_dimension_scores(id) ON DELETE CASCADE,
  evidence_ref_id     UUID NOT NULL REFERENCES evidence_refs(id) ON DELETE RESTRICT,
  PRIMARY KEY (dimension_score_id, evidence_ref_id)
);

-- Join table: integrity adjustments to evidence refs
CREATE TABLE integrity_adjustment_evidence (
  integrity_adjustment_id UUID NOT NULL REFERENCES judge_integrity_adjustments(id) ON DELETE CASCADE,
  evidence_ref_id         UUID NOT NULL REFERENCES evidence_refs(id) ON DELETE RESTRICT,
  PRIMARY KEY (integrity_adjustment_id, evidence_ref_id)
);

-- ---- Audit Trail: Mutable Domain Objects ----

-- Rubric changes (mutable domain: rubrics evolve between versions)
CREATE TABLE rubric_change_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_id     UUID NOT NULL REFERENCES rubrics(id),
  changed_by    UUID NOT NULL REFERENCES users(id),
  change_type   TEXT NOT NULL,  -- 'weight_update', 'criterion_update', 'lane_add', 'activation'
  field_name    TEXT,           -- which field changed (for column-level auditing)
  before_value  JSONB,          -- the value before the change
  after_value   JSONB,          -- the value after the change
  reason        TEXT,
  changed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Score changes (scores are initially provisional; may be adjusted post-integrity review)
CREATE TABLE score_adjustment_log (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id     UUID NOT NULL REFERENCES submissions(id),
  adjusted_by       UUID REFERENCES users(id),  -- NULL = system-automated
  adjustment_type   TEXT NOT NULL, -- 'integrity_deduction', 'admin_correction', 'judge_rerun'
  before_score      NUMERIC(5,2) NOT NULL,
  after_score       NUMERIC(5,2) NOT NULL,
  reason            TEXT NOT NULL,
  adjusted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---- Analytical Data: Separated from Operational Tables ----

-- Analytical snapshot: pre-aggregated per-dimension stats per rubric version
-- Populated by background job, not at query time
CREATE TABLE lane_score_analytics (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_version_id UUID NOT NULL REFERENCES rubrics(id),
  lane_key          TEXT NOT NULL,
  dimension_key     TEXT NOT NULL,
  judge_model       TEXT NOT NULL,
  bout_id           UUID NOT NULL REFERENCES bouts(id),
  computed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  sample_size       INTEGER NOT NULL,
  mean_score        NUMERIC(5,2),
  std_deviation     NUMERIC(5,2),
  p25_score         NUMERIC(5,2),   -- 25th percentile
  p50_score         NUMERIC(5,2),   -- median
  p75_score         NUMERIC(5,2),   -- 75th percentile
  UNIQUE (rubric_version_id, lane_key, dimension_key, judge_model, bout_id)
);

-- Contradiction analytics (for future training data and rubric calibration)
CREATE TABLE feedback_contradictions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_run_id UUID NOT NULL REFERENCES evaluation_runs(id),
  submission_id     UUID NOT NULL REFERENCES submissions(id),
  lane_key          TEXT NOT NULL,
  score_spread      NUMERIC(5,2) NOT NULL,  -- max_score - min_score across judges
  judge_scores      JSONB NOT NULL,         -- [{judge_model, score}]
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Suppression log (for monitoring how often content is suppressed)
CREATE TABLE synthesis_suppression_log (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_run_id UUID NOT NULL REFERENCES evaluation_runs(id),
  submission_id     UUID NOT NULL REFERENCES submissions(id),
  suppression_type  TEXT NOT NULL,  -- 'low_confidence', 'not_corroborated', 'no_evidence', 'generic_phrase'
  lane_key          TEXT,
  dimension_key     TEXT,
  judge_model       TEXT NOT NULL,
  suppressed_text_hash TEXT,        -- SHA256 of suppressed text (for pattern analysis without storing PII)
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---- Index Strategy ----

-- evidence_refs: looked up by type for analytics
CREATE INDEX idx_evidence_refs_type ON evidence_refs(ref_type);

-- dimension_score_evidence: looked up by both sides
CREATE INDEX idx_dse_dimension_score ON dimension_score_evidence(dimension_score_id);
CREATE INDEX idx_dse_evidence_ref ON dimension_score_evidence(evidence_ref_id);

-- audit log: looked up by rubric and time
CREATE INDEX idx_rubric_change_log_rubric_at ON rubric_change_log(rubric_id, changed_at DESC);

-- analytics: standard access pattern is by rubric version + lane + judge
CREATE INDEX idx_lane_score_analytics_rubric ON lane_score_analytics(rubric_version_id, lane_key, judge_model);

-- contradictions: looked up by bout for calibration analysis
CREATE INDEX idx_contradictions_bout ON feedback_contradictions(submission_id, lane_key);

-- suppression log: analyzed by type and date
CREATE INDEX idx_suppression_log_type_date ON synthesis_suppression_log(suppression_type, created_at DESC);
```

---

## When to Use JSONB vs Proper Columns

This is the highest-leverage modeling decision. Getting it wrong creates unmaintainable queries and invisible data quality issues.

**Use JSONB when:**
- The structure is genuinely variable and you can't enumerate the keys at schema design time
- The data is always read/written as a unit (never queried field-by-field)
- The maximum nesting depth is 1 (array of flat objects is OK)
- You don't need to filter, sort, or aggregate on individual fields

**Use proper columns when:**
- You need to filter, sort, or aggregate on the field (`WHERE status = 'high'`)
- The field is part of a unique constraint or foreign key
- The field is included in an index
- Multiple tables need to reference the same data
- You need SQL-level constraints (CHECK, NOT NULL, range bounds)

```sql
-- ✅ GOOD JSONB: scoring_bands — variable count, always read as unit, max depth 1
-- judge_dimensions.scoring_bands: JSONB array of {min, max, label, description}
-- Never queried field-by-field; always rendered as a complete set

-- ❌ BAD JSONB: storing structured judge output in a single blob
-- judge_outputs.raw_output: JSONB containing lane_scores, dimension_scores, flags, etc.
-- You can't query "all dimension scores for lane 'correctness'" without jsonb_array_elements
-- You can't join evidence_refs to dimension scores
-- You can't enforce score ranges with CHECK constraints
-- Every query becomes a multi-level JSONB extraction nightmare

-- ✅ GOOD: break judge output into normalized tables (as designed above)
-- judge_outputs → judge_lane_scores → judge_dimension_scores → evidence_refs
```

**The JSONB depth test**: If you ever write `data->'key1'->'key2'->'key3'` in a query, you've gone too deep. Normalize one level up.

---

## Schema Evolution: Adding Fields Without Breaking Existing Records

### The Two-Step Migration Pattern

```sql
-- Step 1: Add nullable column with default (non-blocking on large tables)
-- This completes instantly even on 1M row tables
ALTER TABLE judge_outputs
  ADD COLUMN specificity_score NUMERIC(4,2) DEFAULT NULL;

COMMENT ON COLUMN judge_outputs.specificity_score IS
  'Added 2026-04-01: computed by anti-generic detector. NULL for records pre-dating this feature.';

-- Step 2: Backfill existing rows (run as a background job, not in migration)
-- Never backfill in the migration file itself — it blocks deploys
-- scripts/backfill_specificity_scores.ts does this async

-- Step 3 (weeks later, after backfill complete): Add NOT NULL if required
-- Only do this if the column truly should never be NULL going forward
-- ALTER TABLE judge_outputs ALTER COLUMN specificity_score SET NOT NULL;
-- (Optional: only when all rows are populated)
```

### Worked Example: Adding `specificity_score` to judge_outputs

```typescript
// migrations/20260401_add_specificity_score.sql
// Content:
// ALTER TABLE judge_outputs ADD COLUMN specificity_score NUMERIC(4,2) DEFAULT NULL;

// After migration, update your TypeScript types to handle null:
// lib/judges/judge-output-schema.ts
const JudgeOutputSchema = z.object({
  // ... existing fields ...
  specificity_score: z.number().min(0).max(100).nullable(),  // nullable for backward compat
});

// The loader handles null correctly:
// records pre-dating this feature return null — the UI shows "N/A" not an error
```

```typescript
// scripts/backfill_specificity_scores.ts
// Run manually after migration, not in CI
import { createAdminClient } from '@/lib/supabase/admin';
import { computeSpecificityScore } from '@/lib/synthesis/generic-detector';

async function backfillSpecificityScores() {
  const supabase = createAdminClient();
  const BATCH_SIZE = 100;
  let offset = 0;
  let processed = 0;

  while (true) {
    const { data: rows } = await supabase
      .from('judge_outputs')
      .select('id, positive_signal, primary_weakness')
      .is('specificity_score', null)
      .limit(BATCH_SIZE)
      .range(offset, offset + BATCH_SIZE - 1);

    if (!rows || rows.length === 0) break;

    for (const row of rows) {
      const score = computeSpecificityScore(
        `${row.positive_signal} ${row.primary_weakness}`
      );

      await supabase
        .from('judge_outputs')
        .update({ specificity_score: score })
        .eq('id', row.id);

      processed++;
    }

    offset += BATCH_SIZE;
    console.log(`Backfilled ${processed} rows...`);
    await new Promise((r) => setTimeout(r, 50)); // Rate-limit the backfill
  }

  console.log(`Backfill complete: ${processed} rows updated`);
}

backfillSpecificityScores().catch(console.error);
```

---

## Anti-Patterns

### Anti-Pattern 1: Growing JSONB blob that replaces proper columns

```sql
-- ❌ BAD: JSONB blob that grows over time with no schema discipline
CREATE TABLE judge_outputs (
  id      UUID PRIMARY KEY,
  data    JSONB NOT NULL  -- starts as {lane_score: 45}, grows to 500 keys
);

-- 3 months later you have:
-- data->>'lane_score'::int
-- data->'dimension_scores'->0->>'correctness'::int
-- data->'meta'->'telemetry'->>'tool_calls'::int
-- No constraints, no indexes, no joins possible, query takes 800ms

-- ✅ GOOD: separate tables for each concept; JSONB only for genuinely variable config
CREATE TABLE judge_outputs (id UUID PRIMARY KEY, overall_score INTEGER, ...);
CREATE TABLE judge_lane_scores (id UUID, judge_output_id UUID REFERENCES judge_outputs(id), ...);
CREATE TABLE judge_dimension_scores (id UUID, lane_score_id UUID REFERENCES judge_lane_scores(id), ...);
-- JSONB only for scoring_bands (variable count, always read as unit)
```

### Anti-Pattern 2: Storing computed values without the source data

```sql
-- ❌ BAD: storing only the final score — can't re-derive or explain it
CREATE TABLE evaluation_results (
  submission_id UUID,
  final_score   INTEGER,  -- how was this computed? which lanes? which weights?
  created_at    TIMESTAMPTZ
);

-- ✅ GOOD: store all source data; compute final score from it
-- final_score is computed from judge_lane_scores × rubric_lanes.weight
-- If weight changes, we can recompute. If judge is audited, we have the inputs.
-- evaluation_reconciled_scores stores the derived score + the method
```

### Anti-Pattern 3: Adding NOT NULL column to existing table in one step

```sql
-- ❌ BAD: this locks the table during backfill; breaks production on large tables
ALTER TABLE judge_outputs
  ADD COLUMN specificity_score NUMERIC(4,2) NOT NULL DEFAULT 0;
-- 'DEFAULT 0' also wrong — existing rows get a fake 0, not null, hiding the fact they weren't computed

-- ✅ GOOD: two-step
-- Step 1 (in migration): ADD COLUMN specificity_score NUMERIC(4,2) DEFAULT NULL;
-- Step 2 (background job): backfill real values
-- Step 3 (optional, later): SET NOT NULL after all rows populated
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Evidence stored as plain TEXT instead of structured ref | Can't render "click to line 45" link; can't filter by ref type | Convert all evidence TEXT fields to proper `evidence_refs` table rows; use typed `evidence_ref_type` |
| JSONB blob with 3+ nesting levels | Query requires `data->'a'->'b'->'c'`; no index possible; slow and fragile | Flatten to 1 level max; move repeated nested structures to proper columns or child tables |
| Analytical query runs against operational table | `judge_outputs` table has 2M rows; analytics query scans full table every page load | Pre-aggregate into `lane_score_analytics`; run analytics queries against snapshot tables |
| Mutable object has no audit log | Score was changed; no record of before/after; can't investigate a user complaint | Add `score_adjustment_log` insert whenever `submission.adjusted_score` changes |
| FK with no ON DELETE behavior specified | Deleting a rubric cascades silently or leaves orphaned lane_scores | Every FK must declare: CASCADE for child records, RESTRICT for important parent refs, SET NULL for optional links |
| NOT NULL column added to existing table in single migration | Migration blocks table for full backfill duration; production outage during deploy | Two-step: nullable first, backfill async, NOT NULL later |
| Suppression events logged at `logger.debug` level only | Can't audit what content was suppressed; support can't explain why a user's feedback is thin | Write to `synthesis_suppression_log` table, not just logs |
| `scoring_bands` JSONB array grows to contain nested objects | `bands[0].criteria.positive_indicators[0].weight` — unqueryable depth | Enforce max depth 1 on all JSONB; JSONB should contain only scalar values or flat object arrays |
| Column added without comment | New field with no documentation; next developer doesn't know what null means | Every new column must have a `COMMENT ON COLUMN` explaining nullability and when it was added |
| Analytics snapshots not refreshed after rubric version change | Analytics shows data from rubric v1 after v3 is active; misleading comparisons | Trigger analytics snapshot refresh after every rubric version activation |

---

## Query Design Patterns: Explainable Retrieval

Modeling for explainability isn't just about schema structure — it's about how you query. These patterns ensure the data you surface is always traceable.

```typescript
// lib/data/explainable-queries.ts
// All queries list columns explicitly — never SELECT *

import { createClient } from '@/lib/supabase/server';

// ---- Load full breakdown for a submission (explainable join chain) ----
export async function loadSubmissionBreakdown(submissionId: string) {
  const supabase = createClient();

  // Each join is intentional and documented in a comment
  const { data, error } = await supabase
    .from('judge_outputs')
    .select(`
      id,
      overall_score,
      integrity_adjusted_score,
      positive_signal,
      primary_weakness,
      confidence,
      status,
      judge_model,
      schema_version,
      lane_scores:judge_lane_scores(
        id,
        lane_key,
        lane_score,
        dimension_scores:judge_dimension_scores(
          id,
          dimension_key,
          score,
          reasoning,
          band_label,
          evidence:dimension_score_evidence(
            evidence_refs(
              id,
              ref_type,
              ref_id,
              ref_location,
              excerpt
            )
          )
        )
      ),
      flags:judge_flags(flag_code, severity, description, auto_disqualify),
      adjustments:judge_integrity_adjustments(flag_code, description, deduction),
      telemetry:judge_telemetry(tool_call_count, step_count, error_rate, wall_time_seconds)
    `)
    .eq('submission_id', submissionId)
    .neq('status', 'failed')
    .order('judge_model', { ascending: true });

  if (error) throw new Error(`loadSubmissionBreakdown failed: ${error.message}`);

  return data ?? [];
}

// ---- Load rank history for analytics (never hits operational tables) ----
export async function loadRankHistoryForUser(
  userId: string,
  boutId: string
): Promise<Array<{
  rankPosition: number;
  totalParticipants: number;
  score: number;
  snapshotAt: string;
  isFinal: boolean;
}>> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('rank_history')
    .select(`
      rank_position,
      total_participants,
      score,
      snapshot_at,
      is_final,
      snapshots:rank_snapshots(snapshot_type, trigger_type)
    `)
    .eq('user_id', userId)
    .eq('bout_id', boutId)
    .order('snapshot_at', { ascending: true });

  if (error) throw new Error(`loadRankHistoryForUser failed: ${error.message}`);

  return (data ?? []).map((row) => ({
    rankPosition: row.rank_position,
    totalParticipants: row.total_participants,
    score: row.score,
    snapshotAt: row.snapshot_at,
    isFinal: row.is_final,
  }));
}

// ---- Analytics: per-lane score distribution (reads from pre-aggregated table) ----
export async function getLaneScoreDistribution(
  rubricVersionId: string,
  laneKey: string,
  boutId: string
): Promise<{
  mean: number;
  p25: number;
  p50: number;
  p75: number;
  stdDev: number;
  sampleSize: number;
} | null> {
  const supabase = createClient();

  const { data } = await supabase
    .from('lane_score_analytics')
    .select('mean_score, std_deviation, p25_score, p50_score, p75_score, sample_size')
    .eq('rubric_version_id', rubricVersionId)
    .eq('lane_key', laneKey)
    .eq('bout_id', boutId)
    .order('computed_at', { ascending: false })
    .limit(1)
    .single();

  if (!data) return null;

  return {
    mean: data.mean_score ?? 0,
    p25: data.p25_score ?? 0,
    p50: data.p50_score ?? 0,
    p75: data.p75_score ?? 0,
    stdDev: data.std_deviation ?? 0,
    sampleSize: data.sample_size,
  };
}
```

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
