# Judge Calibration System — Skill 66

## Purpose
Continuously calibrate AI judges against known-quality benchmarks. Without calibration, judge quality degrades over time and scores become less meaningful.

## The Calibration Problem

AI judges (Strategy, portions of Process and Recovery) are themselves AI models. They can:
- **Drift** — scores shift over time as model behavior changes
- **Develop biases** — systematically favor certain coding styles or approaches
- **Produce inconsistency** — same submission gets different scores on different days

## Calibration Methodology

### 1. Held-Out Benchmark Submissions

- Maintain a set of **50+ submissions** with KNOWN correct scores (determined by expert human review)
- These are "calibration standards" — like reference weights for a scale
- **Weekly:** Run the full judge stack against calibration standards
- **Measure:** Average deviation from known-correct scores

| Deviation | Status | Action |
|-----------|--------|--------|
| < 3 points average | ✅ Calibrated | No action |
| 3–5 points average | ⚠️ Drifting | Monitor, prepare rubric adjustments |
| > 5 points average | 🔴 Miscalibrated | Adjust judge prompts, rubrics, or temperature |

### 2. Inter-Judge Consistency

Expected correlations between judges:

| Pair | Expected Correlation | Meaning |
|------|---------------------|---------|
| Process ↔ Objective | Moderate positive (0.4–0.6) | Good process usually produces good code |
| Strategy ↔ Objective | Weak positive (0.2–0.4) | Good strategy helps but doesn't guarantee execution |
| Recovery ↔ Process | Moderate positive (0.4–0.6) | Good recovery is part of good process |
| Process ↔ Strategy | Weak positive (0.2–0.4) | Independent dimensions but not uncorrelated |
| Recovery ↔ Objective | Weak positive (0.2–0.4) | Recovery helps objective score but isn't sufficient |

**If correlations deviate significantly** (> 0.2 from expected range) → investigate judge behavior.

### 3. Cross-Model Judge Agreement

The Strategy Judge panel uses Claude + GPT-4o + Gemini.

| Pattern | Interpretation | Action |
|---------|---------------|--------|
| All three consistently agree (within 10) | Judges are well-calibrated | None |
| One model consistently scores higher | Model-specific rubric interpretation | Adjust that model's rubric or weight |
| All three consistently disagree | Rubric is ambiguous | Refine rubric |
| Disagreement varies by challenge type | Rubric is type-specific | Add challenge-specific rubric clauses |

### 4. Temporal Stability

- Same submission judged today vs. judged last week → should produce the same score (±3 points)
- **Measurement:** Re-judge 10 random calibration standards weekly, compare to previous scores
- **If drift detected:** Pin model versions or adjust prompts to counteract

## Calibration Dashboard (Internal)

| Metric | Measurement | Alert Threshold |
|--------|-------------|-----------------|
| **Judge accuracy** | Average deviation from known-correct scores | > 5 points |
| **Judge consistency** | Inter-judge correlation matrix | Correlation outside expected range by > 0.2 |
| **Judge drift** | Score change over time for calibration standards | > 3 points average drift per month |
| **Cross-model agreement** | Agreement rate between Strategy panel models | Agreement < 70% |
| **Dispute rate** | % of runs triggering disputes | > 20% for any challenge |

## Calibration Standard Requirements

Each calibration standard must have:
- Complete submission artifacts (code, tests, deliverables)
- Complete telemetry (all 6 signal groups)
- Expert-assigned scores per judge with written rationale
- Challenge family and tier metadata
- At least 5 calibration standards per challenge family

## Calibration Feedback Loop

```
Weekly calibration run
  ↓
Compare judge scores to known-correct scores
  ↓
Identify drift or bias
  ↓
Adjust: rubric wording, prompt engineering, temperature, model weight
  ↓
Re-run calibration to verify improvement
  ↓
Deploy adjusted judges
  ↓
Monitor live scoring for regression
```

## Integration Points

- **Five-Judge Architecture** (Skill 61): All AI judges are calibration targets
- **Dispute Service** (Skill 64): Dispute outcomes feed calibration data
- **Defensibility Reporting** (Skill 57): Calibration metrics are part of defensibility
- **Minimum Rubric Items** (Skill 67): Rubric changes propagate through calibration
