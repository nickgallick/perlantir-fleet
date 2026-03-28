# Calibration Packaging — Skill 81

## Purpose
Package a challenge so reference agents can run it. Self-contained calibration packages that the runner ingests without any manual translation.

## Package Structure

```
/calibration/BOUTS-2026-XXXX/
├── challenge.json              # Full structured output (Skill 77)
├── workspace/                  # The codebase the agent receives
│   ├── src/
│   ├── tests/
│   ├── package.json
│   └── ...
├── evaluation/
│   ├── static-tests/           # Tests run by Objective Judge
│   ├── adversarial-tests/      # Adversarial test templates
│   ├── invariants/             # Hidden invariant checks
│   └── security-rules/         # Semgrep/ESLint security rules
├── rubrics/
│   ├── process-rubric.json     # Process Judge rubric
│   ├── strategy-rubric.json    # Strategy Judge rubric
│   ├── recovery-rubric.json    # Recovery Judge rubric
│   └── integrity-checks.json   # Integrity positive/negative triggers
├── reference/
│   ├── solution-approach.md    # How the reference agent should approach it
│   ├── expected-scores.json    # Per-tier expected scores
│   └── failure-taxonomy.json   # From Skill 80
└── meta/
    ├── mutation-strategy.json  # What can/cannot change
    ├── contamination-check.json # Screening results
    └── lineage.json            # Template + seed + generation metadata
```

## Responsibility Split

| Gauntlet Provides | Runner Provides |
|-------------------|-----------------|
| The full package above | The agents (naive, standard, elite, reference) |
| Challenge content + tests + rubrics | The sandbox execution environment |
| Expected scores per tier | The judge stack |
| Failure taxonomy predictions | The telemetry collector |

Gauntlet does NOT need to know how the runner works internally — just the package format.

## Calibration Agents

| Agent | Config | Purpose |
|-------|--------|---------|
| **Naive** | Basic system prompt, no iteration, 1 attempt | Floor — should score 5-25 |
| **Standard** | Good system prompt, basic tools, 2 iterations | Middle — should score 25-55 |
| **Elite** | Advanced system prompt, full tools, max iterations | Near ceiling — should score 55-85 |
| **Reference** | Given solution approach, validates ceiling | Ceiling — must score >85 |

## Calibration Pass/Fail Criteria

| Criterion | Pass | Fail |
|-----------|------|------|
| Reference agent score | > 85 | ≤ 85 (challenge may be unsolvable) |
| Elite agent score | 55-85 | Outside range |
| Standard agent score | 25-55 | Outside range |
| Naive agent score | 5-25 | Outside range (>25 = too easy) |
| Score spread (σ) | > 15 | ≤ 15 (not discriminative) |
| Tier ordering | Naive < Standard < Elite < Reference | Any inversion |

**If ANY criterion fails → Gauntlet receives specific feedback → adjust and repackage.**

## Package Validation Checklist

Before submitting for calibration:

- [ ] challenge.json passes schema validation (Skill 77)
- [ ] workspace/ contains all files referenced in provided_assets
- [ ] evaluation/ tests run without errors in a clean environment
- [ ] rubrics/ contain all key_signals from challenge.json
- [ ] reference/solution-approach.md is specific enough for the reference agent
- [ ] reference/expected-scores.json has all 4 tiers
- [ ] reference/failure-taxonomy.json has all 4 tiers with specific predictions
- [ ] meta/contamination-check.json shows freshness > 70
- [ ] Content hash computed and stored in meta/lineage.json

## Integration Points

- **Structured Output** (Skill 77): challenge.json is the schema
- **Per-Challenge Failure Taxonomy** (Skill 80): failure-taxonomy.json
- **Variant Pack Generation** (Skill 82): Each variant gets its own package
- **Deterministic Packaging** (Skill 90): Lineage enables reproducibility
