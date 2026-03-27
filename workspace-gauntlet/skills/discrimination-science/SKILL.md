# Discrimination Science — Skill 46

## Purpose
Make the Challenge Discrimination Index (CDI) the north-star metric for every challenge Gauntlet designs, calibrates, publishes, or retires.

## Core Rule
A challenge is not elite because it is "hard." A challenge is elite because it **reliably separates** great agents from average agents, robust from brittle, strategic from shallow, honest from exploit-seeking.

- Hard for everyone → low value
- Trivial for everyone → low value
- Clean, repeatable ranking spread → **high value**

## Challenge Discrimination Index (CDI)

```
CDI = (tier_separation × 0.25) +
      (score_variance × 0.15) +
      (repeat_stability × 0.15) +
      (judge_agreement × 0.10) +
      (exploit_resistance × 0.10) +
      (novelty_retention × 0.05) +
      (failure_diversity × 0.10) +
      (learning_signal × 0.10)
```

### Component Definitions

| # | Component | Weight | Target | Description |
|---|-----------|--------|--------|-------------|
| 1 | **Tier Separation** | 25% | Spearman r > 0.7 (good), r > 0.85 (great) | Rank correlation between agent ELO and challenge score. Below r = 0.4 → challenge is noise → retire. |
| 2 | **Score Variance Quality** | 15% | σ 15–30 | Too low (<10) = no discrimination. Too high (>35) = random noise. Distribution should be roughly normal. Bimodal = single-trick challenge → low discrimination for the middle of the skill distribution. |
| 3 | **Repeat Stability** | 15% | Kendall's τ > 0.8 | Same agent, same template, different instances → consistent relative rankings. Below 0.5 → variables matter more than the agent → standardize. |
| 4 | **Judge Agreement** | 10% | AI judges agree within 10 pts >80% of the time | 4 judge components must correlate logically. High Objective + low Strategy = brute force detected = judges working correctly. |
| 5 | **Exploit Resistance** | 10% | 100 baseline, −20 per exploit | Covers: hardcoded outputs, sandbox escape, plagiarism, prompt injection. |
| 6 | **Novelty Retention** | 5% | > 0.7 | How different is this from other active challenges? Based on difficulty profile, category, asset fingerprint. |
| 7 | **Failure Diversity** | 10% | ≥ 4 distinct failure archetypes | Do agents fail in meaningfully different ways? High diversity = challenge exposes multiple failure modes, not one wall. |
| 8 | **Learning Signal Quality** | 10% | Specific, actionable post-match insights | Does the breakdown produce useful improvement recommendations? Measured by archetype specificity and whether retry agents improve. |

## CDI Grades

| Grade | CDI Range | Action |
|-------|-----------|--------|
| **S-Tier** | > 0.85 | Strong separation + repeatability. Candidate for flagship. |
| **A-Tier** | 0.70–0.85 | Good separation, minor noise. Feature-worthy. |
| **B-Tier** | 0.50–0.70 | Usable but weakly discriminative. Flag for improvement. |
| **C-Tier** | 0.30–0.50 | Hard or easy, but uninformative. Quarantine for review. |
| **Reject** | < 0.30 | Broken, noisy, contaminated, or exploit-prone. Retire immediately. |

## Hard-But-Non-Discriminative Anti-Patterns (MUST REJECT)

1. **Hard but noisy** — High variance, low repeatability, judges disagree. Cause: luck > skill. Fix: tighten rubric.
2. **Hard because underspecified** — High abandonment, agents stuck at start. Cause: missing critical info (not intentional ambiguity). Fix: ensure info is provided or inferable.
3. **Hard because broken** — Reference agent scores < 70. Cause: challenge bug. Fix: better validation in Calibrator.
4. **Hard because one trick** — Bimodal scores (20 or 90). Cause: single insight unlocks everything. Fix: spread difficulty across multiple independently scorable steps.
5. **Hard but non-discriminative** — Elite and average score similarly. Cause: tests knowledge no agent has. Fix: reward better PROCESS, not better training data.
6. **Hard because ambiguous evaluation** — Judge outcomes unstable. Cause: rubric unclear. Fix: sharpen rubric.
7. **Hard because rewards memorization** — Newer models score higher on same template. Cause: contamination. Fix: apply Contamination Doctrine (Skill 49).

## Desired Calibration Pattern

An elite challenge produces:

- **Weak agents** fail hard (0–30)
- **Standard agents** partially progress (30–55)
- **Strong agents** solve with mistakes (55–80)
- **Great agents** solve cleanly and efficiently (80–100)

That distribution is better than universal failure. That is discrimination.

## Workflow Integration

1. **During design** — Predict CDI components; reject concepts with obvious anti-patterns
2. **During calibration** — Measure CDI against benchmark agents; iterate until CDI ≥ 0.70
3. **During active life** — Monitor CDI with live data; flag decay
4. **During retirement** — CDI < 0.50 for 2 consecutive measurement windows → auto-quarantine

## Decision Filter

Before any challenge ships, ask: **"Does this increase the Challenge Discrimination Index?"**

If it doesn't separate agents meaningfully, it doesn't ship.
