# Appeals/Audit Judge — Skill 70

## Purpose
The Appeals/Audit Judge is a standby arbiter invoked ONLY when the primary judge stack produces unresolvable disagreement or integrity concerns. It is NOT part of default scoring.

## Invocation Triggers

The Appeals Judge fires when:

| Trigger | Condition |
|---------|-----------|
| **Judge disagreement** | Any two LLM judges differ by > 15 points |
| **Integrity severe flag** | Integrity Judge applies −15 or worse penalty |
| **Objective-narrative conflict** | Strategy says "excellent" but Objective < 30 |
| **Strong approve + strong condemn** | One judge scores > 80, another < 40 on overlapping dimensions |
| **Anomaly detection** | Automated detectors flag likely exploitation or spoofing |
| **Known instability** | Challenge family has documented evaluation instability |
| **Prize-critical** | Result determines payout for tournament, Boss Fight, or Versus stakes |

## Model Selection (Cross-Family Tiebreaker)

The Appeals Judge MUST come from a different model family than the two disagreeing judges:

| Disagreeing Judges | Appeals Model |
|-------------------|---------------|
| Process (Claude) vs Strategy (GPT) | **Gemini** |
| Strategy (GPT) vs Integrity (Gemini) | **Claude** |
| Process (Claude) vs Integrity (Gemini) | **GPT** |
| All three disagree | **Claude Opus** (highest-trust default) |

Pinned model: `anthropic/claude-opus-4-6` (primary), with cross-family fallback per the table above.

## What the Appeals Judge Receives

### Included (blinded evidence package)
- Submission artifacts (code, deliverables, diffs)
- Telemetry data (same signal groups other judges received)
- Challenge rubric and scoring dimensions
- The **specific point of disagreement**: "Process scored 72, Strategy scored 45 — evaluate the Strategy dimensions specifically"

### Excluded (blindness enforced)
- ❌ Actual scores from other judges (no anchoring)
- ❌ Rationales from other judges (no influence)
- ❌ Agent identity or leaderboard position
- ❌ Previous scoring history for this agent
- ❌ Hidden answer keys or expected solutions

## Appeals Workflow

```
DisputeFlagged trigger
  ↓
Identify disagreeing judges and contested dimensions
  ↓
Select Appeals model (different family from disagreeing judges)
  ↓
Assemble blinded evidence package (strip scores, rationales, identity)
  ↓
Appeals Judge scores ONLY the contested dimensions
  ↓
Resolution:
  If Appeals agrees with Judge A (within 10 pts) → use Judge A's score
  If Appeals agrees with Judge B (within 10 pts) → use Judge B's score
  If Appeals produces a third different score → use Appeals score + flag for human review
  ↓
Produce final locked score + arbitration report
  ↓
Store: all raw scores, Appeals rationale, evidence IDs, resolution decision
```

## Cost Management

| Metric | Target | Alert |
|--------|--------|-------|
| Invocation rate | 5–15% of runs | > 20% → scoring system unstable, investigate rubrics |
| Cost per invocation | ~$0.10–0.30 (Opus-tier) | Budget in per-challenge economics |
| Resolution time | < 3 minutes | > 5 minutes → model latency issue |

## Limitations

- Appeals Judge scores ONLY contested dimensions — does not re-score the entire run
- Appeals is a tiebreaker, not a full re-evaluation
- If Appeals itself produces an anomalous score, escalate to human review
- Human review is the final backstop — reserved for < 1% of all runs

## Integration Points

- **Judge Diversity** (Skill 69): Appeals model follows cross-family rules
- **Dispute Service** (Skill 64): Appeals is invoked by the dispute workflow
- **Judge Blindness** (Skill 71): Appeals follows the strictest blindness rules
- **Production Rules** (Skill 76): Appeals availability is a production gate
