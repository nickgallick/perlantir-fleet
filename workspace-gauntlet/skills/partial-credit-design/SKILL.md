# Partial Credit Design — Skill 78

## Purpose
Design graduated scoring that rewards incremental progress. Binary pass/fail destroys score spread. Partial credit creates the gradient that makes the leaderboard meaningful.

## Why Partial Credit Matters

If 60% of agents score 0 and 40% score 100, the challenge doesn't discriminate in the middle. The CDI depends on a smooth distribution — partial credit is how you get it.

## Partial Credit Structures by Challenge Type

### Debug Challenges — Bug-Weighted Scoring

```json
{
  "bugs": [
    {"id": "bug-1", "severity": "critical", "points": 30},
    {"id": "bug-2", "severity": "high", "points": 20},
    {"id": "bug-3", "severity": "high", "points": 20},
    {"id": "bug-4", "severity": "medium", "points": 15},
    {"id": "bug-5", "severity": "low", "points": 5}
  ],
  "interconnection_bonus": 10,
  "total": 100,
  "partial_credit_per_bug": {
    "identified_not_fixed": 0.4,
    "fixed_but_no_test": 0.7,
    "fixed_with_test": 1.0,
    "fixed_but_broke_something_else": 0.3
  }
}
```

**Examples:**
- Finding bug-1 but not fixing it = 30 × 0.4 = **12 points**
- Fixing bug-1 without a regression test = 30 × 0.7 = **21 points**
- Fixing bug-1 with a test = 30 × 1.0 = **30 points**
- Fixing bug-1 but introducing a new bug = 30 × 0.3 = **9 points**
- Finding ALL interconnected bugs = **+10 bonus**

### Greenfield Challenges — Milestone Scoring

```json
{
  "milestones": [
    {"id": "builds", "points": 10, "description": "Code compiles and runs"},
    {"id": "basic_functionality", "points": 25, "description": "Core feature works for happy path"},
    {"id": "edge_cases", "points": 20, "description": "Handles specified edge cases"},
    {"id": "adversarial", "points": 15, "description": "Survives adversarial inputs"},
    {"id": "code_quality", "points": 15, "description": "Clean, idiomatic, well-structured"},
    {"id": "documentation", "points": 10, "description": "Clear README and comments"},
    {"id": "implicit_requirements", "points": 5, "description": "Security, error handling, logging"}
  ],
  "total": 100
}
```

### Refactoring Challenges — Regression-Protected Scoring

```json
{
  "scoring": {
    "existing_tests_still_pass": 30,
    "improvement_metrics": {
      "performance_improvement": 20,
      "complexity_reduction": 15,
      "test_coverage_increase": 15
    },
    "no_new_bugs_introduced": 10,
    "documentation_of_changes": 10
  },
  "regression_penalty": {
    "per_broken_test": -5,
    "max_penalty": -30
  }
}
```

### Forensic Challenges — Evidence-Based Scoring

```json
{
  "scoring": {
    "correct_root_cause_identified": 30,
    "evidence_chain_quality": 20,
    "hypotheses_formed_and_tested": 15,
    "red_herrings_correctly_dismissed": 15,
    "postmortem_quality": 10,
    "prevention_recommendations": 10
  },
  "partial_credit": {
    "root_cause_close_but_not_exact": 0.5,
    "correct_area_wrong_specifics": 0.3,
    "completely_wrong_root_cause": 0.0
  }
}
```

## Design Principles

1. **First 30–40% achievable by any functional agent** — prevents all-zero scores
2. **Last 10–20% only achievable by elite agents** — creates ceiling separation
3. **Regression penalties** prevent "improving" code by breaking existing functionality
4. **Interconnection bonuses** reward systematic thinking over one-at-a-time fixing
5. **Never award points for things not delivered** — empty deliverable = 0, not partial credit
6. **Score ranges between tiers should not overlap by more than 10 points**

## Integration Points

- **Structured Output** (Skill 77): Partial credit structure is embedded in deliverables scoring_weight
- **CDI** (Skill 46): Partial credit is the primary tool for achieving score spread 15–30
- **Per-Challenge Failure Taxonomy** (Skill 80): Predicted score ranges depend on partial credit structure
- **Post-Match Breakdown** (Skill 86): Shows which partial credit milestones were hit
