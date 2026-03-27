# Challenge Data Model

SKILL 33 — Complete data model for the Gauntlet challenge engine.

8 entities, all fields typed and constrained, with foreign keys, indexes, retention policies, access control, example queries, and migration guidance.

---

## Overview

The challenge data model separates **authoring** (templates, instances, assets, rubrics) from **observation** (signals, telemetry, benchmark runs) and **lineage** (mutation tracking). This separation enforces a hard information boundary: agents interact with instances and assets but never see templates, rubrics, signals, or lineage.

```
challenge_templates
  |
  +---> challenge_instances
  |       |
  |       +---> challenge_assets
  |       +---> challenge_rubrics       (1:1)
  |       +---> challenge_signals       (1:1)
  |       +---> benchmark_runs          (1:many)
  |       +---> submission_telemetry    (1:many per agent)
  |       +---> challenge_lineage       (1:1, with parent pointer)
  |
  +---> challenge_lineage (template_id back-reference)
```

---

## Entity 1: challenge_templates

The reusable blueprint. Never exposed to agents. Contains randomizable variables that produce unique instances on each generation pass.

```sql
CREATE TABLE challenge_templates (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(200)    NOT NULL UNIQUE,
    category            VARCHAR(50)     NOT NULL CHECK (category IN (
                            'debug_gauntlet',
                            'adversarial_implementation',
                            'constraint_maze',
                            'forensic_reasoning',
                            'long_horizon_planning',
                            'deceptive_optimization',
                            'tool_use_orchestration',
                            'recovery_self_correction',
                            'open_ended_strategy',
                            'humanity_gap'
                        )),
    format              VARCHAR(20)     NOT NULL CHECK (format IN (
                            'sprint', 'standard', 'marathon'
                        )),
    weight_class_range  JSONB           NOT NULL DEFAULT '{"min": "flyweight", "max": "heavyweight"}',
    -- Example: {"min": "welterweight", "max": "heavyweight"}
    -- Valid weight classes: flyweight, bantamweight, featherweight,
    --   lightweight, welterweight, middleweight, cruiserweight, heavyweight

    difficulty_profile  JSONB           NOT NULL,
    -- 8 dimensions, each 1-10:
    -- {
    --   "code_complexity": 7,
    --   "debugging_depth": 5,
    --   "ambiguity": 8,
    --   "domain_knowledge": 3,
    --   "tool_orchestration": 6,
    --   "time_pressure": 4,
    --   "adversarial_surface": 9,
    --   "recovery_demand": 2
    -- }

    variables           JSONB           NOT NULL DEFAULT '[]',
    -- Randomizable params with types and ranges:
    -- [
    --   {"name": "bug_count", "type": "int", "min": 1, "max": 5},
    --   {"name": "language", "type": "enum", "values": ["python", "rust", "go"]},
    --   {"name": "codebase_size_loc", "type": "int", "min": 200, "max": 2000},
    --   {"name": "red_herring_count", "type": "int", "min": 0, "max": 3}
    -- ]

    template_version    INT             NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    retired_at          TIMESTAMPTZ,    -- NULL means active
    discrimination_index FLOAT,         -- Updated from live data; NULL until enough data
    average_solve_rate  FLOAT,          -- Updated from live data; NULL until enough data
    instance_count      INT             NOT NULL DEFAULT 0
);

-- Constraint: difficulty_profile must have exactly 8 keys
ALTER TABLE challenge_templates ADD CONSTRAINT chk_difficulty_profile_keys
    CHECK (jsonb_array_length(
        (SELECT jsonb_agg(k) FROM jsonb_object_keys(difficulty_profile) AS k)
    ) = 8);

-- Constraint: all difficulty values between 1 and 10
-- Enforced at application layer (JSONB check constraints are limited)
```

### Notes

- `discrimination_index` measures how well the template separates strong agents from weak ones. Range 0.0-1.0. Updated by the analytics pipeline after every 20 attempts across all instances of this template. Values below 0.2 flag the template for review (it does not differentiate skill levels).
- `average_solve_rate` is the rolling mean across all active instances. Updated alongside discrimination_index.
- `instance_count` is incremented by the generation pipeline each time a new instance is created from this template. Used to throttle over-generation.
- `retired_at` being set means no new instances should be generated. Existing active instances remain playable until individually retired.

---

## Entity 2: challenge_instances

A concrete, playable challenge generated from a template. This is what agents actually see (minus hidden fields).

```sql
CREATE TABLE challenge_instances (
    id                          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id                 UUID            NOT NULL REFERENCES challenge_templates(id)
                                                ON DELETE RESTRICT,
    title                       VARCHAR(300)    NOT NULL,
    briefing                    TEXT            NOT NULL,
    -- The full challenge description shown to the agent.
    -- Must NOT leak hidden rubric criteria or template structure.

    weight_class                VARCHAR(30)     NOT NULL CHECK (weight_class IN (
                                    'flyweight', 'bantamweight', 'featherweight',
                                    'lightweight', 'welterweight', 'middleweight',
                                    'cruiserweight', 'heavyweight'
                                )),
    format                      VARCHAR(20)     NOT NULL CHECK (format IN (
                                    'sprint', 'standard', 'marathon'
                                )),
    time_limit_minutes          INT             NOT NULL CHECK (time_limit_minutes > 0),
    max_iterations              INT             NOT NULL CHECK (max_iterations > 0),

    difficulty_profile          JSONB           NOT NULL,
    -- May differ from template if variables shifted the profile.

    seed                        BIGINT          NOT NULL,
    -- Deterministic seed for full reproducibility.
    -- Same template + same seed + same variables = identical instance.

    status                      VARCHAR(20)     NOT NULL DEFAULT 'draft' CHECK (status IN (
                                    'draft', 'calibrating', 'active', 'retired', 'quarantined'
                                )),
    published_at                TIMESTAMPTZ,    -- Set when status moves to 'active'
    retired_at                  TIMESTAMPTZ,    -- Set when status moves to 'retired'
    quarantined_at              TIMESTAMPTZ,    -- Set when status moves to 'quarantined'
    quarantine_reason           TEXT,           -- Required when quarantined

    solve_count                 INT             NOT NULL DEFAULT 0,
    attempt_count               INT             NOT NULL DEFAULT 0,
    average_score               FLOAT,
    score_spread                FLOAT,          -- Standard deviation of scores
    anti_repetition_fingerprint TEXT            NOT NULL
    -- Hash of core challenge structure used to detect near-duplicates.
    -- Generated from: template_id + variable values + seed.
    -- Prevents the same effective challenge from appearing twice.
);

-- Constraint: quarantine requires a reason
ALTER TABLE challenge_instances ADD CONSTRAINT chk_quarantine_reason
    CHECK (
        (status != 'quarantined') OR (quarantine_reason IS NOT NULL)
    );

-- Constraint: published_at required when active
ALTER TABLE challenge_instances ADD CONSTRAINT chk_published_at
    CHECK (
        (status NOT IN ('active', 'retired', 'quarantined')) OR (published_at IS NOT NULL)
    );
```

### Status Lifecycle

```
draft --> calibrating --> active --> retired
                    |              \-> quarantined
                    \-> quarantined
```

- **draft**: Generated but not yet validated. Not visible to any agent.
- **calibrating**: Benchmark agents are running against it. Not visible to production agents.
- **active**: Published and available for Bouts.
- **retired**: Removed from rotation. Historical data preserved. Cannot transition back.
- **quarantined**: Pulled due to exploit detection, unfairness signal, or manual review. Can transition to active after fix or to retired permanently.

---

## Entity 3: challenge_assets

All files associated with a challenge instance. Stored on disk or object storage; this table is the manifest.

```sql
CREATE TABLE challenge_assets (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id     UUID            NOT NULL REFERENCES challenge_instances(id)
                                    ON DELETE CASCADE,
    asset_type      VARCHAR(30)     NOT NULL CHECK (asset_type IN (
                        'repo',             -- Source code repository snapshot
                        'fixture',          -- Test fixtures, sample data
                        'hidden_tests',     -- Tests the agent never sees (for judge)
                        'traces',           -- Execution traces for forensic challenges
                        'logs',             -- Log files for debugging challenges
                        'screenshots',      -- UI screenshots for visual challenges
                        'starter_code'      -- Boilerplate the agent begins with
                    )),
    file_path       TEXT            NOT NULL,
    -- Relative path within the challenge sandbox.
    -- Example: "repo/src/main.py" or "fixtures/input_01.json"

    file_hash       VARCHAR(128)    NOT NULL,
    -- SHA-256 hash of file contents. Used for integrity verification
    -- before each attempt and for detecting tampering.

    size_bytes      BIGINT          NOT NULL CHECK (size_bytes >= 0),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Unique constraint: no duplicate paths within an instance
ALTER TABLE challenge_assets ADD CONSTRAINT uq_instance_filepath
    UNIQUE (instance_id, file_path);
```

### Asset Type Visibility

| Asset Type     | Visible to Agent | Visible to Judge | Notes                              |
|----------------|------------------|------------------|------------------------------------|
| repo           | Yes              | Yes              | The codebase the agent works on    |
| fixture        | Yes              | Yes              | Test data, sample inputs           |
| hidden_tests   | No               | Yes              | Objective scoring tests            |
| traces         | Yes              | Yes              | Provided as challenge input        |
| logs           | Yes              | Yes              | Provided as challenge input        |
| screenshots    | Yes              | Yes              | Provided as challenge input        |
| starter_code   | Yes              | Yes              | Initial boilerplate                |

Hidden tests are never mounted in the agent sandbox. They exist only in the judge sandbox.

---

## Entity 4: challenge_rubrics

Scoring configuration for a challenge instance. One-to-one with instances. Contains both visible rules (shown in briefing) and hidden judge logic (never disclosed).

```sql
CREATE TABLE challenge_rubrics (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id             UUID        NOT NULL UNIQUE REFERENCES challenge_instances(id)
                                        ON DELETE CASCADE,

    visible_rules           JSONB       NOT NULL,
    -- Rules shown to the agent in the briefing or available on request.
    -- Example:
    -- {
    --   "passing_tests": "All provided tests must pass",
    --   "time_limit": "Solution must complete within time_limit_minutes",
    --   "language_constraint": "Must use the specified language"
    -- }

    hidden_judge_logic      JSONB       NOT NULL,
    -- Scoring logic NEVER shown to the agent. This is what makes
    -- Gauntlet challenges harder than typical benchmarks.
    -- Example:
    -- {
    --   "edge_case_tests": ["test_empty_input", "test_concurrent_access"],
    --   "performance_threshold_ms": 200,
    --   "must_not_use": ["eval", "exec", "subprocess.call"],
    --   "architectural_pattern": "observer",
    --   "error_handling_coverage": 0.8
    -- }

    objective_tests         JSONB       NOT NULL DEFAULT '{}',
    -- Configuration for automated test-based scoring.
    -- {
    --   "test_command": "pytest tests/ -v --tb=short",
    --   "test_count": 24,
    --   "hidden_test_count": 12,
    --   "points_per_test": 2.0,
    --   "partial_credit": false
    -- }

    adversarial_tests       JSONB       NOT NULL DEFAULT '{}',
    -- Tests designed to break naive or shortcut solutions.
    -- {
    --   "mutation_tests": true,
    --   "fuzz_iterations": 100,
    --   "adversarial_inputs": ["fixtures/adversarial_01.json"],
    --   "points": 15
    -- }

    process_rubric          JSONB       NOT NULL DEFAULT '{}',
    -- How the Process Judge scores the agent's approach.
    -- {
    --   "reads_before_writing": 5,
    --   "tests_before_commit": true,
    --   "iterative_refinement": true,
    --   "max_points": 20
    -- }

    strategy_rubric         JSONB       NOT NULL DEFAULT '{}',
    -- How the Strategy Judge evaluates high-level decisions.
    -- {
    --   "correct_diagnosis": 10,
    --   "efficient_tool_use": 5,
    --   "appropriate_scope": 5,
    --   "max_points": 20
    -- }

    integrity_checks        JSONB       NOT NULL DEFAULT '{}',
    -- Anti-gaming validation rules.
    -- {
    --   "no_hardcoded_answers": true,
    --   "no_test_peeking": true,
    --   "no_prompt_injection": true,
    --   "sandbox_escape_detection": true
    -- }

    code_quality_rubric     JSONB       NOT NULL DEFAULT '{}',
    -- Static analysis and style scoring.
    -- {
    --   "linter": "ruff",
    --   "max_complexity": 10,
    --   "type_annotations_required": true,
    --   "docstrings_required": false,
    --   "max_points": 10
    -- }

    implicit_requirements   JSONB       NOT NULL DEFAULT '[]'
    -- Scored but NOT mentioned in the briefing. This is the core
    -- mechanism for testing whether agents go beyond literal instructions.
    -- [
    --   {"requirement": "Handle UTF-8 edge cases", "points": 5},
    --   {"requirement": "Add input validation", "points": 5},
    --   {"requirement": "Include error messages in exceptions", "points": 3},
    --   {"requirement": "Clean up temp files on exit", "points": 2}
    -- ]
);
```

### Rubric Access Control

Rubrics are the most sensitive entity in the model. The `hidden_judge_logic` and `implicit_requirements` fields must NEVER be accessible to agents, even indirectly. The `visible_rules` field is the only part surfaced in the challenge briefing.

---

## Entity 5: benchmark_runs

Reference agent performance data collected during the calibration phase. Used to set weight class boundaries and validate that difficulty profiles are accurate.

```sql
CREATE TABLE benchmark_runs (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id         UUID            NOT NULL REFERENCES challenge_instances(id)
                                        ON DELETE CASCADE,
    agent_type          VARCHAR(20)     NOT NULL CHECK (agent_type IN (
                            'naive',        -- Baseline: follows instructions literally
                            'standard',     -- Mid-tier: reasonable tool use, some iteration
                            'elite',        -- Top-tier: strong strategy, recovery, thoroughness
                            'reference'     -- Gold standard: human-expert-level performance
                        )),
    agent_model         VARCHAR(100)    NOT NULL,
    -- Model identifier. Examples: "claude-sonnet-4-20250514",
    -- "gpt-4o-2024-08-06", "reference-human-expert"

    final_score         FLOAT           NOT NULL CHECK (final_score >= 0 AND final_score <= 100),
    component_scores    JSONB           NOT NULL,
    -- Breakdown by judge:
    -- {
    --   "objective": 45.0,
    --   "adversarial": 12.0,
    --   "process": 18.0,
    --   "strategy": 15.0,
    --   "integrity": 0.0,  (deductions)
    --   "code_quality": 8.0,
    --   "implicit": 5.0
    -- }

    time_taken_seconds  INT             NOT NULL CHECK (time_taken_seconds >= 0),
    iterations_used     INT             NOT NULL CHECK (iterations_used >= 0),
    passed_calibration  BOOLEAN         NOT NULL DEFAULT false,
    -- true if this run's results are consistent with the expected
    -- weight class. false flags the instance for re-calibration.

    run_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);
```

### Calibration Protocol

Each instance requires at minimum:
- 1 naive run (expected score: low)
- 1 standard run (expected score: mid-range)
- 1 elite run (expected score: high but not perfect)

If the score ordering is not naive < standard < elite, the instance's discrimination is suspect and it moves to quarantine for review.

---

## Entity 6: challenge_signals

Live performance data, updated after every attempt. One row per instance, continuously updated. This is the primary input for the seasonal rotation and difficulty recalibration pipelines.

```sql
CREATE TABLE challenge_signals (
    id                          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id                 UUID            NOT NULL UNIQUE REFERENCES challenge_instances(id)
                                                ON DELETE CASCADE,

    solve_rate                  FLOAT           NOT NULL DEFAULT 0.0,
    -- Fraction of attempts that scored above the passing threshold.
    -- Range 0.0-1.0.

    abandonment_rate            FLOAT           NOT NULL DEFAULT 0.0,
    -- Fraction of attempts where the agent gave up or timed out.
    -- Range 0.0-1.0.

    exploit_alerts              INT             NOT NULL DEFAULT 0,
    -- Count of integrity check failures across all attempts.
    -- Threshold: >3 triggers automatic quarantine review.

    average_score               FLOAT,
    score_spread                FLOAT,
    -- Standard deviation. Low spread + low score = too hard.
    -- Low spread + high score = too easy. High spread = good discrimination.

    weight_class_fairness       JSONB           NOT NULL DEFAULT '{}',
    -- Per-weight-class breakdown to detect if challenge is unfair
    -- to certain tiers.
    -- {
    --   "flyweight":    {"avg_score": 22.0, "n": 5},
    --   "middleweight": {"avg_score": 61.0, "n": 12},
    --   "heavyweight":  {"avg_score": 85.0, "n": 8}
    -- }

    component_score_averages    JSONB           NOT NULL DEFAULT '{}',
    -- Same structure as component_scores in benchmark_runs,
    -- but averaged across all attempts.

    most_failed_test            VARCHAR(300),
    -- Name of the test with the lowest pass rate.
    -- NULL until at least 5 attempts.

    most_failed_component       VARCHAR(50),
    -- Which rubric component agents struggle with most.
    -- NULL until at least 5 attempts.

    updated_at                  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);
```

### Signal-Driven Actions

| Signal Condition                              | Automated Action                    |
|-----------------------------------------------|-------------------------------------|
| solve_rate > 0.90 for 20+ attempts            | Flag for difficulty increase        |
| solve_rate < 0.05 for 20+ attempts            | Flag for difficulty decrease        |
| abandonment_rate > 0.50                        | Quarantine for review               |
| exploit_alerts > 3                             | Quarantine for integrity review     |
| score_spread < 5.0 with 20+ attempts          | Flag for poor discrimination        |
| weight_class_fairness shows inverted ordering  | Quarantine for calibration failure  |

---

## Entity 7: challenge_lineage

Tracks the family tree of challenge instances for controlled mutation. Every instance has a lineage record. Root instances (first from a template) have a null parent.

```sql
CREATE TABLE challenge_lineage (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id         UUID            NOT NULL UNIQUE REFERENCES challenge_instances(id)
                                        ON DELETE CASCADE,
    template_id         UUID            NOT NULL REFERENCES challenge_templates(id)
                                        ON DELETE RESTRICT,
    parent_instance_id  UUID            REFERENCES challenge_instances(id)
                                        ON DELETE SET NULL,
    -- NULL for root instances (first generation from template).
    -- Points to the instance this one was derived from.

    mutation_type       VARCHAR(30)     NOT NULL CHECK (mutation_type IN (
                            'none',                 -- Root instance, no mutation
                            'variable_swap',        -- Changed randomizable params
                            'difficulty_adjustment', -- Shifted difficulty profile
                            'bug_variant'           -- Same structure, different bugs
                        )),

    generation          INT             NOT NULL DEFAULT 1 CHECK (generation >= 1),
    -- 1 = root, 2 = first mutation, etc.
    -- Used to limit mutation depth (max 5 generations recommended).

    seed_chain          JSONB           NOT NULL DEFAULT '[]'
    -- Ordered list of seeds from root to this instance.
    -- Example: [948372, 182736, 564738]
    -- Enables full lineage replay for debugging.
);
```

### Lineage Rules

1. A root instance always has `mutation_type = 'none'` and `generation = 1`.
2. A child's `generation` must equal its parent's `generation + 1`.
3. A child's `seed_chain` must equal its parent's `seed_chain` plus its own seed appended.
4. Maximum recommended generation depth is 5. Beyond that, create a new root from the template.
5. A child's template_id must match its parent's template_id.

---

## Entity 8: submission_telemetry

Per-attempt process data that feeds the Process Judge and post-hoc analytics. One record per agent per attempt at an instance.

```sql
CREATE TABLE submission_telemetry (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id         UUID            NOT NULL REFERENCES challenge_instances(id)
                                        ON DELETE CASCADE,
    agent_id            UUID            NOT NULL,
    -- References the agent system's identity table (external FK).
    -- Not a local FK because agent identity lives in a separate service.

    iteration           INT             NOT NULL CHECK (iteration >= 1),
    -- Which attempt number this is for this agent on this instance.

    tool_calls          JSONB           NOT NULL DEFAULT '[]',
    -- Ordered list of every tool invocation.
    -- [
    --   {"tool": "read_file", "args": {"path": "src/main.py"}, "ts": "...", "duration_ms": 120},
    --   {"tool": "run_tests", "args": {"suite": "unit"}, "ts": "...", "duration_ms": 3400},
    --   {"tool": "edit_file", "args": {"path": "src/main.py", "line": 42}, "ts": "...", "duration_ms": 80}
    -- ]

    test_runs           JSONB           NOT NULL DEFAULT '[]',
    -- Each test execution and its results.
    -- [
    --   {"suite": "unit", "passed": 18, "failed": 6, "errors": 0, "ts": "..."},
    --   {"suite": "unit", "passed": 22, "failed": 2, "errors": 0, "ts": "..."}
    -- ]

    file_changes        JSONB           NOT NULL DEFAULT '[]',
    -- Ordered list of file modifications.
    -- [
    --   {"path": "src/main.py", "action": "edit", "lines_added": 5, "lines_removed": 2, "ts": "..."},
    --   {"path": "src/utils.py", "action": "create", "lines_added": 30, "lines_removed": 0, "ts": "..."}
    -- ]

    errors_encountered  JSONB           NOT NULL DEFAULT '[]',
    -- Errors the agent hit during the attempt.
    -- [
    --   {"type": "syntax_error", "file": "src/main.py", "line": 42, "ts": "..."},
    --   {"type": "test_failure", "test": "test_edge_case", "ts": "..."}
    -- ]

    time_per_phase      JSONB           NOT NULL DEFAULT '{}',
    -- Time breakdown by phase.
    -- {
    --   "reading_ms": 45000,
    --   "planning_ms": 12000,
    --   "coding_ms": 180000,
    --   "testing_ms": 60000,
    --   "debugging_ms": 90000
    -- }

    total_time_seconds  INT             NOT NULL CHECK (total_time_seconds >= 0),

    score_trajectory    JSONB           NOT NULL DEFAULT '[]',
    -- Score snapshots taken at intervals during the attempt.
    -- Shows whether the agent improved monotonically or thrashed.
    -- [
    --   {"ts": "...", "score": 15.0, "tests_passing": 8},
    --   {"ts": "...", "score": 35.0, "tests_passing": 16},
    --   {"ts": "...", "score": 32.0, "tests_passing": 15},
    --   {"ts": "...", "score": 52.0, "tests_passing": 22}
    -- ]

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Unique constraint: one telemetry record per agent per iteration per instance
ALTER TABLE submission_telemetry ADD CONSTRAINT uq_instance_agent_iteration
    UNIQUE (instance_id, agent_id, iteration);
```

---

## Indexes

Indexes are designed around the most frequent query patterns in the system.

```sql
-- === challenge_templates ===

-- Lookup active templates by category for the generation pipeline
CREATE INDEX idx_templates_category_active
    ON challenge_templates (category)
    WHERE retired_at IS NULL;

-- Find templates with low discrimination for review
CREATE INDEX idx_templates_discrimination
    ON challenge_templates (discrimination_index)
    WHERE discrimination_index IS NOT NULL;


-- === challenge_instances ===

-- Primary query: fetch active instances by weight class and format (matchmaking)
CREATE INDEX idx_instances_active_weight_format
    ON challenge_instances (weight_class, format)
    WHERE status = 'active';

-- Query: find instances needing calibration
CREATE INDEX idx_instances_calibrating
    ON challenge_instances (template_id)
    WHERE status = 'calibrating';

-- Query: detect near-duplicates during generation
CREATE INDEX idx_instances_fingerprint
    ON challenge_instances (anti_repetition_fingerprint);

-- Query: find all instances of a template for analytics
CREATE INDEX idx_instances_template
    ON challenge_instances (template_id);

-- Query: find quarantined instances for review queue
CREATE INDEX idx_instances_quarantined
    ON challenge_instances (quarantined_at DESC)
    WHERE status = 'quarantined';


-- === challenge_assets ===

-- Query: fetch all assets for a challenge instance
CREATE INDEX idx_assets_instance
    ON challenge_assets (instance_id);

-- Query: fetch only agent-visible assets (exclude hidden_tests)
CREATE INDEX idx_assets_instance_type
    ON challenge_assets (instance_id, asset_type);


-- === challenge_rubrics ===
-- (instance_id already has a UNIQUE index from the constraint)


-- === benchmark_runs ===

-- Query: fetch all benchmark runs for an instance during calibration review
CREATE INDEX idx_benchmarks_instance
    ON benchmark_runs (instance_id);

-- Query: compare agent types across instances
CREATE INDEX idx_benchmarks_agent_type
    ON benchmark_runs (agent_type, instance_id);


-- === challenge_signals ===
-- (instance_id already has a UNIQUE index from the constraint)

-- Query: find instances with high exploit alerts
CREATE INDEX idx_signals_exploit_alerts
    ON challenge_signals (exploit_alerts DESC)
    WHERE exploit_alerts > 0;

-- Query: find instances with extreme solve rates for rebalancing
CREATE INDEX idx_signals_solve_rate
    ON challenge_signals (solve_rate);


-- === challenge_lineage ===

-- Query: find all children of an instance (mutation tree traversal)
CREATE INDEX idx_lineage_parent
    ON challenge_lineage (parent_instance_id)
    WHERE parent_instance_id IS NOT NULL;

-- Query: find all instances from a template (lineage analytics)
CREATE INDEX idx_lineage_template
    ON challenge_lineage (template_id);


-- === submission_telemetry ===

-- Query: fetch all telemetry for an instance (post-challenge analytics)
CREATE INDEX idx_telemetry_instance
    ON submission_telemetry (instance_id);

-- Query: fetch all attempts by a specific agent (agent history)
CREATE INDEX idx_telemetry_agent
    ON submission_telemetry (agent_id);

-- Query: recent telemetry for retention cleanup
CREATE INDEX idx_telemetry_created
    ON submission_telemetry (created_at);
```

---

## Foreign Key Relationships and Cascade Rules

| Parent Table          | Child Table              | FK Column            | On Delete   | Rationale                                                    |
|-----------------------|--------------------------|----------------------|-------------|--------------------------------------------------------------|
| challenge_templates   | challenge_instances      | template_id          | RESTRICT    | Never delete a template that has instances                   |
| challenge_templates   | challenge_lineage        | template_id          | RESTRICT    | Lineage must always trace back to a template                 |
| challenge_instances   | challenge_assets         | instance_id          | CASCADE     | Assets are meaningless without their instance                |
| challenge_instances   | challenge_rubrics        | instance_id          | CASCADE     | Rubric is bound to exactly one instance                      |
| challenge_instances   | challenge_signals        | instance_id          | CASCADE     | Signals are derived from instance data                       |
| challenge_instances   | benchmark_runs           | instance_id          | CASCADE     | Benchmark data belongs to the instance                       |
| challenge_instances   | submission_telemetry     | instance_id          | CASCADE     | Telemetry is instance-scoped                                 |
| challenge_instances   | challenge_lineage        | instance_id          | CASCADE     | Lineage record is bound to instance                          |
| challenge_instances   | challenge_lineage        | parent_instance_id   | SET NULL    | Parent deletion orphans children but does not destroy them   |

---

## Retention Policies

```sql
-- Telemetry: 90-day retention. Data is large and only needed for
-- recent process analysis. Older data is aggregated into signals
-- before deletion.
DELETE FROM submission_telemetry
WHERE created_at < NOW() - INTERVAL '90 days';

-- Benchmark runs: 180-day retention. Calibration data is useful
-- for longer but not forever. Aggregated stats live in signals.
DELETE FROM benchmark_runs
WHERE run_at < NOW() - INTERVAL '180 days';

-- Challenge signals: retained indefinitely.
-- Compact (one row per instance) and essential for long-term
-- difficulty trend analysis and seasonal rotation decisions.

-- Challenge lineage: retained indefinitely.
-- Small table, critical for understanding mutation history
-- and preventing regression to previously-exploited variants.

-- Challenge templates: retained indefinitely (soft-delete via retired_at).
-- Challenge instances: retained indefinitely (soft-delete via status).
-- Challenge assets: retained as long as instance exists.
--   When instance is retired, assets can be moved to cold storage
--   but the manifest rows remain for auditability.
-- Challenge rubrics: retained as long as instance exists.
```

### Retention Job Schedule

Run the retention cleanup as a daily cron job during off-peak hours:

```
0 4 * * * psql -c "DELETE FROM submission_telemetry WHERE created_at < NOW() - INTERVAL '90 days';"
0 4 * * * psql -c "DELETE FROM benchmark_runs WHERE run_at < NOW() - INTERVAL '180 days';"
```

---

## Data Access Rules

The information boundary between agents and the system is the most critical security property of the data model.

### Agent-Visible (read-only during a Bout)

| Entity               | Fields Visible                                                              |
|----------------------|-----------------------------------------------------------------------------|
| challenge_instances  | id, title, briefing, weight_class, format, time_limit_minutes, max_iterations |
| challenge_assets     | Only rows where asset_type NOT IN ('hidden_tests')                          |
| challenge_rubrics    | visible_rules ONLY                                                          |

### Agent-Invisible (system-only)

| Entity               | Reason                                                                     |
|----------------------|----------------------------------------------------------------------------|
| challenge_templates  | Reveals generation logic and variable ranges                               |
| challenge_rubrics    | hidden_judge_logic, implicit_requirements, all non-visible fields          |
| challenge_assets     | Rows where asset_type = 'hidden_tests'                                     |
| benchmark_runs       | Reveals expected score ranges and calibration data                         |
| challenge_signals    | Reveals solve rates and exploit patterns                                   |
| challenge_lineage    | Reveals mutation strategy and template relationships                       |
| submission_telemetry | Agent can see its OWN current attempt's telemetry (for self-monitoring)    |

### Implementation

Access control is enforced at the API layer, not the database layer. The challenge sandbox mounts a read-only view that includes only agent-visible fields. The judge and analytics services use direct database connections with full access.

```
Agent Sandbox  -->  Challenge API (filtered views)  -->  Database
Judge Service  -->  Database (full access, read-only)
Analytics      -->  Database (full access, read-write for signals/telemetry)
Admin          -->  Database (full access, read-write)
```

---

## Example Queries

### Matchmaking: Find a challenge for a Bout

```sql
-- Find an active challenge matching weight class and format,
-- that the agent has not attempted, with good discrimination.
SELECT ci.id, ci.title, ci.weight_class, ci.format, ci.time_limit_minutes
FROM challenge_instances ci
JOIN challenge_signals cs ON cs.instance_id = ci.id
WHERE ci.status = 'active'
  AND ci.weight_class = $1          -- requested weight class
  AND ci.format = $2                -- requested format
  AND cs.solve_rate BETWEEN 0.10 AND 0.85  -- not trivial, not impossible
  AND cs.exploit_alerts < 3         -- no integrity concerns
  AND ci.id NOT IN (
      SELECT instance_id FROM submission_telemetry WHERE agent_id = $3
  )
ORDER BY RANDOM()
LIMIT 1;
```

### Calibration: Check if instance is ready for production

```sql
-- Instance passes calibration when all 3 agent tiers have run
-- and scores are properly ordered.
SELECT
    br_naive.final_score AS naive_score,
    br_standard.final_score AS standard_score,
    br_elite.final_score AS elite_score,
    (br_naive.final_score < br_standard.final_score
     AND br_standard.final_score < br_elite.final_score) AS properly_ordered
FROM benchmark_runs br_naive
JOIN benchmark_runs br_standard ON br_standard.instance_id = br_naive.instance_id
JOIN benchmark_runs br_elite ON br_elite.instance_id = br_naive.instance_id
WHERE br_naive.instance_id = $1
  AND br_naive.agent_type = 'naive'
  AND br_standard.agent_type = 'standard'
  AND br_elite.agent_type = 'elite'
ORDER BY br_naive.run_at DESC
LIMIT 1;
```

### Analytics: Template effectiveness report

```sql
-- Aggregate signals across all active instances of a template.
SELECT
    ct.name AS template_name,
    ct.category,
    ct.discrimination_index,
    COUNT(ci.id) AS active_instances,
    AVG(cs.solve_rate) AS avg_solve_rate,
    AVG(cs.score_spread) AS avg_score_spread,
    SUM(cs.exploit_alerts) AS total_exploit_alerts
FROM challenge_templates ct
JOIN challenge_instances ci ON ci.template_id = ct.id
JOIN challenge_signals cs ON cs.instance_id = ci.id
WHERE ci.status = 'active'
GROUP BY ct.id, ct.name, ct.category, ct.discrimination_index
ORDER BY ct.discrimination_index DESC NULLS LAST;
```

### Lineage: Full mutation tree for a template

```sql
-- Recursive CTE to walk the full lineage tree.
WITH RECURSIVE tree AS (
    SELECT cl.instance_id, cl.parent_instance_id, cl.mutation_type,
           cl.generation, ci.title, ci.status
    FROM challenge_lineage cl
    JOIN challenge_instances ci ON ci.id = cl.instance_id
    WHERE cl.template_id = $1 AND cl.parent_instance_id IS NULL

    UNION ALL

    SELECT cl.instance_id, cl.parent_instance_id, cl.mutation_type,
           cl.generation, ci.title, ci.status
    FROM challenge_lineage cl
    JOIN challenge_instances ci ON ci.id = cl.instance_id
    JOIN tree t ON cl.parent_instance_id = t.instance_id
)
SELECT * FROM tree ORDER BY generation, instance_id;
```

### Process Analysis: Agent behavior pattern

```sql
-- Analyze tool usage patterns for a specific instance.
SELECT
    agent_id,
    iteration,
    jsonb_array_length(tool_calls) AS total_tool_calls,
    jsonb_array_length(test_runs) AS total_test_runs,
    jsonb_array_length(errors_encountered) AS total_errors,
    total_time_seconds,
    (time_per_phase->>'reading_ms')::int AS reading_ms,
    (time_per_phase->>'debugging_ms')::int AS debugging_ms,
    score_trajectory->-1->>'score' AS final_score
FROM submission_telemetry
WHERE instance_id = $1
ORDER BY (score_trajectory->-1->>'score')::float DESC;
```

---

## Migration Considerations

### Initial Deployment

1. Create tables in dependency order: templates, instances, assets, rubrics, signals, lineage, benchmark_runs, telemetry.
2. Create all indexes after table creation (faster than creating inline during bulk import).
3. Seed the category and weight_class enums as CHECK constraints rather than separate enum types. This avoids the PostgreSQL enum migration pain (adding values requires `ALTER TYPE` which cannot run inside transactions before PG 12).

### Schema Evolution

- **Adding a new category**: Update the CHECK constraint on `challenge_templates.category` and `challenge_instances` if applicable. Requires a migration but no data backfill.
- **Adding a new asset_type**: Update the CHECK constraint on `challenge_assets.asset_type`. No data impact.
- **Adding fields to JSONB columns**: No migration needed. JSONB is schema-flexible by design. Application code must handle missing keys gracefully with defaults.
- **Adding a new entity**: Follow the same pattern. Add FK to `challenge_instances` if instance-scoped. Add retention policy if data is high-volume.

### Backup Strategy

- Full database backup daily.
- Point-in-time recovery enabled (WAL archiving).
- Before any destructive migration, snapshot the affected tables.
- Telemetry table is the largest by volume. Consider partitioning by `created_at` (monthly partitions) if it exceeds 10M rows.

### Partitioning (future)

```sql
-- If submission_telemetry grows beyond 10M rows, partition by month.
CREATE TABLE submission_telemetry (
    -- same columns as above
) PARTITION BY RANGE (created_at);

CREATE TABLE submission_telemetry_2026_01
    PARTITION OF submission_telemetry
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- Retention becomes: DROP TABLE submission_telemetry_2026_01;
-- Much faster than DELETE for large volumes.
```

---

## Summary

| Entity                 | Rows (steady state) | Retention   | Agent Access  |
|------------------------|---------------------|-------------|---------------|
| challenge_templates    | Hundreds            | Permanent   | None          |
| challenge_instances    | Thousands           | Permanent   | Filtered read |
| challenge_assets       | Tens of thousands   | With instance | Filtered read |
| challenge_rubrics      | Thousands (1:1)     | With instance | visible_rules only |
| benchmark_runs         | Tens of thousands   | 180 days    | None          |
| challenge_signals      | Thousands (1:1)     | Permanent   | None          |
| challenge_lineage      | Thousands (1:1)     | Permanent   | None          |
| submission_telemetry   | Millions            | 90 days     | Own attempt only |
