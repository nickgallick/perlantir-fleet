---
name: evaluation-rubric-design
description: Design lane structure, scoring dimensions, weighting logic, calibration rules, and anchor-based criteria so Bouts produces defensible, consistent AI judgments instead of vibes.
---

# Evaluation Rubric Design

## Review Checklist

1. **Lane decomposition test**: Each lane in the rubric maps to exactly one axis of performance (e.g., "code correctness" ≠ "code quality" — they can overlap, which means they're not properly decomposed). Run: count lanes where two different judges might score them using overlapping evidence. If > 0, redesign.
2. **Dimension weight sum check**: For every lane, verify that `sum(dimension_weights) === 1.0` in code — not in docs. Add a Zod `.refine()` that enforces this on load.
3. **Anchor coverage check**: Every scoring band (0-20, 20-40, 40-60, 60-80, 80-100) must have at least one anchor submission stored in `rubric_anchors`. Query: `SELECT band, COUNT(*) FROM rubric_anchors WHERE rubric_id = $1 GROUP BY band` — any band with 0 rows is a calibration gap.
4. **Criteria LLM-applicability test**: For each scoring criterion, ask: "Can an LLM apply this without human context?" If the criterion says "shows good judgment", it's handwave — replace with "selects the minimum-complexity solution when multiple correct solutions exist."
5. **Rubric version pinning**: Every evaluation run must record `rubric_version_id` at scoring time, not at display time. Verify this is in the `evaluation_runs` table FK.
6. **Drift detection baseline**: After each calibration run, store the mean and std deviation of scores per lane in `rubric_calibration_snapshots`. Verify this table exists and is populated.
7. **Rubric active/inactive gate**: No evaluation run should be able to reference a `rubric` row where `is_active = false`. Verify this constraint exists as a DB trigger or API-layer guard.
8. **Dimension score range validation**: Dimension scores must be 0–100 integers. Verify Zod schema rejects floats and out-of-range values with a test case.
9. **Lane weight normalization**: Lane weights across a challenge must sum to 1.0. If a challenge adds a new lane, verify that re-normalization is enforced before the challenge goes live.
10. **No prose-only criteria**: Every criterion must have a numeric band definition (e.g., "90-100: solution handles all edge cases listed in the problem spec without prompting"). Prose descriptions without band anchors produce inconsistent LLM scores.
11. **Rubric display round-trip**: Load a rubric from DB → validate with Zod → render with `RubricViewer` component → confirm all dimensions appear. Test with a rubric that has 5 lanes × 4 dimensions each.
12. **Rubric change audit**: Any modification to a rubric row (including weight changes) must insert a row in `rubric_change_log`. Verify with: `UPDATE rubrics SET updated_at = NOW() WHERE id = $1` triggers the audit log.

---

## Lane Decomposition: From Challenge to Measurable Axes

A lane is a **single, independently scorable dimension of performance**. The test: two judges scoring the same submission should draw from non-overlapping evidence pools when scoring different lanes.

**Bad decomposition** (lanes overlap):
- Lane A: "Code Quality" (correctness, style, efficiency)
- Lane B: "Technical Depth" (correctness, architecture, efficiency)

A judge scoring "correctness" has to decide whether it belongs in A or B — so both lanes become unreliable.

**Good decomposition** (each lane owns its evidence):
- Lane A: "Correctness" — does the solution produce right outputs for all test inputs?
- Lane B: "Efficiency" — does the solution meet the time/space complexity target?
- Lane C: "Code Clarity" — is the implementation readable and maintainable without needing to run it?
- Lane D: "Problem Decomposition" — did the approach break the problem into logical subproblems?

### SQL: Rubric Storage Schema

```sql
-- migrations/20260331_rubrics.sql

CREATE TABLE rubrics (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id  UUID NOT NULL REFERENCES challenges(id),
  version       INTEGER NOT NULL DEFAULT 1,
  name          TEXT NOT NULL,
  description   TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_by    UUID REFERENCES users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (challenge_id, version)
);

CREATE TABLE rubric_lanes (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_id     UUID NOT NULL REFERENCES rubrics(id) ON DELETE CASCADE,
  lane_key      TEXT NOT NULL,  -- e.g. 'correctness', 'efficiency'
  display_name  TEXT NOT NULL,
  weight        NUMERIC(4,3) NOT NULL CHECK (weight > 0 AND weight <= 1),
  sort_order    INTEGER NOT NULL DEFAULT 0,
  UNIQUE (rubric_id, lane_key)
);

-- Enforce lane weights sum to 1.0 per rubric
CREATE OR REPLACE FUNCTION check_lane_weights_sum()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  total NUMERIC;
BEGIN
  SELECT COALESCE(SUM(weight), 0)
  INTO total
  FROM rubric_lanes
  WHERE rubric_id = NEW.rubric_id;

  -- Allow up to 0.001 floating point tolerance
  IF ABS(total - 1.0) > 0.001 THEN
    RAISE EXCEPTION 'Lane weights for rubric % sum to %, must equal 1.0', NEW.rubric_id, total;
  END IF;
  RETURN NEW;
END;
$$;

-- Note: trigger fires AFTER all lanes inserted via deferred constraint or batch upsert
-- For MVP: validate at API layer with Zod before any insert

CREATE TABLE rubric_dimensions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lane_id         UUID NOT NULL REFERENCES rubric_lanes(id) ON DELETE CASCADE,
  dimension_key   TEXT NOT NULL,
  display_name    TEXT NOT NULL,
  weight          NUMERIC(4,3) NOT NULL CHECK (weight > 0 AND weight <= 1),
  -- Scoring bands: stored as JSONB array of {min, max, description}
  scoring_bands   JSONB NOT NULL,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  UNIQUE (lane_id, dimension_key)
);

-- Example scoring_bands value:
-- [
--   {"min": 0, "max": 20, "label": "Failing", "description": "Solution produces incorrect output on > 2 test cases"},
--   {"min": 20, "max": 40, "label": "Partial", "description": "Solution correct on happy path but fails edge cases"},
--   {"min": 40, "max": 60, "label": "Adequate", "description": "Solution correct on all provided test cases"},
--   {"min": 60, "max": 80, "label": "Strong", "description": "Solution correct and handles undocumented edge cases"},
--   {"min": 80, "max": 100, "label": "Exceptional", "description": "Solution correct, handles edge cases, includes error recovery"}
-- ]

CREATE TABLE rubric_anchors (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_id       UUID NOT NULL REFERENCES rubrics(id),
  lane_id         UUID NOT NULL REFERENCES rubric_lanes(id),
  band            INT NOT NULL CHECK (band BETWEEN 1 AND 5),  -- 1=0-20, 2=20-40, etc.
  submission_id   UUID REFERENCES submissions(id),
  synthetic_text  TEXT,  -- if no real submission, store synthetic anchor example
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rubric_change_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_id   UUID NOT NULL REFERENCES rubrics(id),
  changed_by  UUID REFERENCES users(id),
  change_type TEXT NOT NULL,  -- 'weight_update', 'criterion_update', 'lane_add', 'lane_remove'
  before_json JSONB,
  after_json  JSONB,
  reason      TEXT,
  changed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rubric_calibration_snapshots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_id       UUID NOT NULL REFERENCES rubrics(id),
  lane_id         UUID NOT NULL REFERENCES rubric_lanes(id),
  snapshot_date   DATE NOT NULL,
  mean_score      NUMERIC(5,2),
  std_deviation   NUMERIC(5,2),
  sample_size     INTEGER,
  judge_model     TEXT,  -- which judge model was calibrated
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index strategy
CREATE INDEX idx_rubric_lanes_rubric_id ON rubric_lanes(rubric_id);
CREATE INDEX idx_rubric_dimensions_lane_id ON rubric_dimensions(lane_id);
CREATE INDEX idx_rubric_anchors_rubric_lane ON rubric_anchors(rubric_id, lane_id);
CREATE INDEX idx_rubric_change_log_rubric_id ON rubric_change_log(rubric_id, changed_at DESC);
```

---

## TypeScript: Rubric Loading, Validation, and Calibration

```typescript
// lib/rubrics/rubric-loader.ts
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';

// ---- Zod Schemas ----

const ScoringBandSchema = z.object({
  min: z.number().int().min(0).max(100),
  max: z.number().int().min(0).max(100),
  label: z.string().min(1),
  description: z.string().min(10, 'Scoring band description must be specific (>10 chars)'),
});

const DimensionSchema = z.object({
  id: z.string().uuid(),
  dimension_key: z.string().regex(/^[a-z_]+$/, 'dimension_key must be snake_case'),
  display_name: z.string().min(2),
  weight: z.number().min(0.01).max(1),
  scoring_bands: z.array(ScoringBandSchema).min(3).max(7),
  sort_order: z.number().int(),
});

const LaneSchema = z.object({
  id: z.string().uuid(),
  lane_key: z.string().regex(/^[a-z_]+$/, 'lane_key must be snake_case'),
  display_name: z.string().min(2),
  weight: z.number().min(0.01).max(1),
  sort_order: z.number().int(),
  dimensions: z.array(DimensionSchema).min(1),
}).refine(
  (lane) => {
    const sum = lane.dimensions.reduce((acc, d) => acc + d.weight, 0);
    return Math.abs(sum - 1.0) <= 0.001;
  },
  { message: 'Dimension weights within a lane must sum to 1.0' }
);

export const RubricSchema = z.object({
  id: z.string().uuid(),
  challenge_id: z.string().uuid(),
  version: z.number().int().min(1),
  name: z.string().min(3),
  description: z.string().nullable(),
  is_active: z.boolean(),
  lanes: z.array(LaneSchema).min(1).max(10),
}).refine(
  (rubric) => {
    const sum = rubric.lanes.reduce((acc, l) => acc + l.weight, 0);
    return Math.abs(sum - 1.0) <= 0.001;
  },
  { message: 'Lane weights across rubric must sum to 1.0' }
);

export type Rubric = z.infer<typeof RubricSchema>;
export type RubricLane = z.infer<typeof LaneSchema>;
export type RubricDimension = z.infer<typeof DimensionSchema>;

// ---- Loader ----

export async function loadRubricForChallenge(challengeId: string): Promise<Rubric> {
  const supabase = createClient();

  const { data: rubricRow, error: rubricError } = await supabase
    .from('rubrics')
    .select('*')
    .eq('challenge_id', challengeId)
    .eq('is_active', true)
    .order('version', { ascending: false })
    .limit(1)
    .single();

  if (rubricError || !rubricRow) {
    throw new Error(`No active rubric found for challenge ${challengeId}: ${rubricError?.message}`);
  }

  const { data: lanes, error: laneError } = await supabase
    .from('rubric_lanes')
    .select(`
      *,
      dimensions:rubric_dimensions(*)
    `)
    .eq('rubric_id', rubricRow.id)
    .order('sort_order', { ascending: true });

  if (laneError) {
    throw new Error(`Failed to load lanes for rubric ${rubricRow.id}: ${laneError.message}`);
  }

  const raw = { ...rubricRow, lanes: lanes ?? [] };
  const result = RubricSchema.safeParse(raw);

  if (!result.success) {
    throw new Error(`Rubric validation failed: ${JSON.stringify(result.error.issues, null, 2)}`);
  }

  return result.data;
}

// ---- Drift Detection ----

export interface CalibrationDrift {
  laneKey: string;
  currentMean: number;
  baselineMean: number;
  drift: number;
  isDrifted: boolean;
}

export async function detectRubricDrift(
  rubricId: string,
  laneId: string,
  judgeModel: string,
  currentScores: number[]
): Promise<CalibrationDrift> {
  const supabase = createClient();

  // Get the most recent baseline snapshot for this lane
  const { data: snapshot } = await supabase
    .from('rubric_calibration_snapshots')
    .select('mean_score, std_deviation')
    .eq('rubric_id', rubricId)
    .eq('lane_id', laneId)
    .eq('judge_model', judgeModel)
    .order('snapshot_date', { ascending: false })
    .limit(1)
    .single();

  if (!snapshot || currentScores.length < 5) {
    // Not enough data for drift detection
    return {
      laneKey: laneId,
      currentMean: 0,
      baselineMean: 0,
      drift: 0,
      isDrifted: false,
    };
  }

  const currentMean = currentScores.reduce((a, b) => a + b, 0) / currentScores.length;
  const drift = Math.abs(currentMean - snapshot.mean_score);

  // Drift threshold: 1.5 standard deviations from baseline
  const threshold = (snapshot.std_deviation ?? 10) * 1.5;

  return {
    laneKey: laneId,
    currentMean,
    baselineMean: snapshot.mean_score,
    drift,
    isDrifted: drift > threshold,
  };
}

// ---- Rubric to Judge Prompt Serializer ----
// Converts a rubric lane into a structured prompt fragment the judge LLM can use

export function serializeLaneForJudge(lane: RubricLane): string {
  const lines: string[] = [
    `## Lane: ${lane.display_name} (weight: ${Math.round(lane.weight * 100)}%)`,
    '',
    'Score this lane by evaluating each dimension separately, then computing the weighted average.',
    '',
  ];

  for (const dim of lane.dimensions) {
    lines.push(`### Dimension: ${dim.display_name} (weight: ${Math.round(dim.weight * 100)}%)`);

    const sortedBands = [...dim.scoring_bands].sort((a, b) => a.min - b.min);
    for (const band of sortedBands) {
      lines.push(`- **${band.min}–${band.max} (${band.label})**: ${band.description}`);
    }
    lines.push('');
  }

  return lines.join('\n');
}
```

---

## TSX: Rubric Viewer Component

```tsx
// components/rubrics/RubricViewer.tsx
'use client';

import { useState } from 'react';
import type { Rubric, RubricLane, RubricDimension } from '@/lib/rubrics/rubric-loader';

interface RubricViewerProps {
  rubric: Rubric;
  showWeights?: boolean;
  highlightLaneKey?: string;
}

export function RubricViewer({ rubric, showWeights = true, highlightLaneKey }: RubricViewerProps) {
  const [expandedLaneId, setExpandedLaneId] = useState<string | null>(null);

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">{rubric.name}</h2>
          {rubric.description && (
            <p className="text-sm text-gray-500 mt-0.5">{rubric.description}</p>
          )}
        </div>
        <span className="text-xs font-mono text-gray-400 bg-gray-100 px-2 py-1 rounded">
          v{rubric.version}
        </span>
      </div>

      {rubric.lanes.map((lane) => (
        <LaneCard
          key={lane.id}
          lane={lane}
          showWeights={showWeights}
          isHighlighted={lane.lane_key === highlightLaneKey}
          isExpanded={expandedLaneId === lane.id}
          onToggle={() => setExpandedLaneId(
            expandedLaneId === lane.id ? null : lane.id
          )}
        />
      ))}

      {showWeights && (
        <div className="mt-4 pt-3 border-t border-gray-100">
          <WeightBar lanes={rubric.lanes} />
        </div>
      )}
    </div>
  );
}

function LaneCard({
  lane,
  showWeights,
  isHighlighted,
  isExpanded,
  onToggle,
}: {
  lane: RubricLane;
  showWeights: boolean;
  isHighlighted: boolean;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  return (
    <div
      className={`border rounded-lg overflow-hidden transition-all ${
        isHighlighted
          ? 'border-indigo-300 bg-indigo-50/50 shadow-sm'
          : 'border-gray-200 bg-white'
      }`}
    >
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-gray-50 transition-colors"
      >
        <div className="flex items-center gap-3">
          <span className="font-medium text-gray-900">{lane.display_name}</span>
          {showWeights && (
            <span className="text-xs font-medium text-indigo-600 bg-indigo-100 px-2 py-0.5 rounded-full">
              {Math.round(lane.weight * 100)}%
            </span>
          )}
        </div>
        <ChevronIcon isOpen={isExpanded} />
      </button>

      {isExpanded && (
        <div className="px-4 pb-4 space-y-3 border-t border-gray-100">
          {lane.dimensions.map((dim) => (
            <DimensionRow key={dim.id} dimension={dim} showWeights={showWeights} />
          ))}
        </div>
      )}
    </div>
  );
}

function DimensionRow({
  dimension,
  showWeights,
}: {
  dimension: RubricDimension;
  showWeights: boolean;
}) {
  const [showBands, setShowBands] = useState(false);

  return (
    <div className="mt-3">
      <div className="flex items-center justify-between">
        <span className="text-sm font-medium text-gray-700">{dimension.display_name}</span>
        {showWeights && (
          <span className="text-xs text-gray-500">{Math.round(dimension.weight * 100)}% of lane</span>
        )}
      </div>

      <button
        onClick={() => setShowBands(!showBands)}
        className="text-xs text-indigo-600 hover:text-indigo-800 mt-1 underline decoration-dotted"
      >
        {showBands ? 'Hide scoring bands' : 'Show scoring bands'}
      </button>

      {showBands && (
        <div className="mt-2 space-y-1.5">
          {[...dimension.scoring_bands]
            .sort((a, b) => b.min - a.min)
            .map((band) => (
              <div key={band.min} className="flex gap-2 text-xs">
                <span className="w-20 shrink-0 font-mono text-gray-500 pt-0.5">
                  {band.min}–{band.max}
                </span>
                <div>
                  <span className="font-semibold text-gray-700">{band.label}: </span>
                  <span className="text-gray-600">{band.description}</span>
                </div>
              </div>
            ))}
        </div>
      )}
    </div>
  );
}

function WeightBar({ lanes }: { lanes: RubricLane[] }) {
  const colors = [
    'bg-indigo-500', 'bg-violet-500', 'bg-sky-500',
    'bg-emerald-500', 'bg-amber-500', 'bg-rose-500',
    'bg-teal-500', 'bg-orange-500',
  ];

  return (
    <div>
      <p className="text-xs text-gray-500 mb-2">Lane weight distribution</p>
      <div className="flex h-3 rounded-full overflow-hidden gap-px">
        {lanes.map((lane, i) => (
          <div
            key={lane.id}
            className={`${colors[i % colors.length]} transition-all`}
            style={{ width: `${lane.weight * 100}%` }}
            title={`${lane.display_name}: ${Math.round(lane.weight * 100)}%`}
          />
        ))}
      </div>
      <div className="flex flex-wrap gap-3 mt-2">
        {lanes.map((lane, i) => (
          <div key={lane.id} className="flex items-center gap-1.5 text-xs text-gray-600">
            <span className={`inline-block w-2.5 h-2.5 rounded-sm ${colors[i % colors.length]}`} />
            {lane.display_name}
          </div>
        ))}
      </div>
    </div>
  );
}

function ChevronIcon({ isOpen }: { isOpen: boolean }) {
  return (
    <svg
      className={`w-4 h-4 text-gray-400 transition-transform ${isOpen ? 'rotate-180' : ''}`}
      fill="none" viewBox="0 0 24 24" stroke="currentColor"
    >
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
    </svg>
  );
}
```

---

## Anti-Patterns

### Anti-Pattern 1: Prose-only scoring criteria (unenforceable)

```typescript
// ❌ BAD: LLM cannot apply this consistently
const badDimension = {
  dimension_key: 'code_quality',
  scoring_bands: [
    { min: 80, max: 100, description: 'Excellent code quality with best practices' },
    { min: 60, max: 80, description: 'Good code quality with minor issues' },
    { min: 0, max: 60, description: 'Poor code quality' },
  ]
};

// ✅ GOOD: Operationally defined — LLM can check each condition
const goodDimension = {
  dimension_key: 'code_clarity',
  scoring_bands: [
    {
      min: 80, max: 100, label: 'Exceptional',
      description: 'All functions < 20 lines, all variables named for purpose not type, no inline comments required to understand control flow'
    },
    {
      min: 60, max: 80, label: 'Strong',
      description: 'Most functions < 30 lines, variable names are purposeful, one or fewer magic numbers without named constants'
    },
    {
      min: 40, max: 60, label: 'Adequate',
      description: 'Functions may reach 50 lines, some unclear variable names present, logic is followable without running the code'
    },
    {
      min: 0, max: 40, label: 'Weak',
      description: 'Functions > 50 lines, variable names like x/tmp/data, requires execution to understand behavior'
    },
  ]
};
```

### Anti-Pattern 2: Rubric mutation without versioning

```typescript
// ❌ BAD: Modifying an active rubric in place
async function updateRubricWeight(laneId: string, newWeight: number) {
  await supabase
    .from('rubric_lanes')
    .update({ weight: newWeight })
    .eq('id', laneId);
}
// Now historical evaluation scores are no longer interpretable against current weights

// ✅ GOOD: Always version — create new rubric with incremented version
async function updateRubricWithVersion(
  rubricId: string,
  changes: Partial<Rubric>,
  changedBy: string,
  reason: string
): Promise<string> {
  const supabase = createClient();

  // 1. Load current rubric
  const { data: current } = await supabase
    .from('rubrics')
    .select('*, lanes:rubric_lanes(*)')
    .eq('id', rubricId)
    .single();

  // 2. Deactivate current
  await supabase.from('rubrics').update({ is_active: false }).eq('id', rubricId);

  // 3. Insert new version
  const { data: newRubric } = await supabase
    .from('rubrics')
    .insert({
      challenge_id: current.challenge_id,
      version: current.version + 1,
      name: current.name,
      description: current.description,
      is_active: true,
    })
    .select()
    .single();

  // 4. Log the change
  await supabase.from('rubric_change_log').insert({
    rubric_id: rubricId,
    changed_by: changedBy,
    change_type: 'version_bump',
    before_json: current,
    after_json: { ...current, ...changes },
    reason,
  });

  return newRubric.id;
}
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Lane weights don't sum to 1.0 but no validation exists | Final scores silently miscalculate; a 3-lane rubric with weights 0.4+0.4+0.4=1.2 inflates all scores | Add `.refine()` on RubricSchema and a DB constraint; test with intentionally invalid weights |
| Scoring bands have gaps between them | A score of 39.5 doesn't fit any band; judge returns null for that dimension | Ensure bands are contiguous: each band.max === next band.min; add validator function |
| Dimension key changes break historical records | Old evaluation_scores reference `code_quality`; new rubric uses `code_clarity`; join produces NULLs | Never rename dimension keys — add new, deprecate old; include migration script |
| Anchor submissions not covering all bands | Judge always scores mid-range (40-60) because no calibration anchors exist for 0-20 or 80-100 | Enforce anchor coverage check: each band must have at least one anchor before rubric activation |
| Rubric loaded at display time not at evaluation time | User sees v3 rubric but their score was computed against v1; breakdown is misleading | Store `rubric_version_id` in evaluation_runs at scoring time; load that specific version for display |
| Calibration drift undetected | Judge model update causes mean scores to shift +15 points; comparisons across window periods are invalid | Run drift detection after every judge model update; snapshot calibration before and after |
| Lane overlap creates double-counting | "Technical depth" and "problem solving" both reward algorithmic sophistication; high scores in both inflate total | Audit: for each pair of lanes, verify a judge would draw from different evidence; rewrite overlapping criteria |
| Handwave criteria like "shows initiative" | LLM-judges give this criterion high scores universally; it adds noise, not signal | Ban non-observable criteria; every criterion must reference an artifact (code, decision, tool call, transcript line) |
| Weights stored as floats causing 0.1+0.1+0.1 ≠ 0.3 | Validation passes but sum check fails spuriously | Store as `NUMERIC(4,3)` in DB; use tolerance check (`Math.abs(sum - 1.0) < 0.001`) in JS |
| New lane added to active challenge mid-window | Historical submissions missing the new lane; comparisons break | Gate: no lane additions while challenge window is open; require admin confirmation and new rubric version |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
