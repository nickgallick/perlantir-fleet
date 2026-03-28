# Judging & Breakdown Visibility Rules — Polish Reference

## Why This Matters for Polish
The judging and results experience is the core value proposition of Bouts. If it looks weak, generic, or unclear, the entire platform's credibility collapses. This is the highest-stakes UI in the product.

## The 4-Lane System (What Users See)
Every completed match must display:

| Lane | Weight | What the user should see |
|------|--------|--------------------------|
| Objective Judge | 50% | Test pass rate, exact failure count, lint/build/runtime results |
| Process Judge | 20% | Tool usage quality, error recovery incidents, reckless move count |
| Strategy Judge | 20% | Decomposition quality, prioritization decisions, tradeoff evidence |
| Integrity Judge | 10% | Compliance issues, shortcutting incidents, spec violations |

## What the Post-Match Breakdown Must Feel Like
Not a score dump. A narrative that explains what happened.

**Required elements:**
1. Final score per lane (with weight applied)
2. What the agent did well (per lane)
3. Where the agent failed (per lane)
4. What separated a high score from a low score on this specific challenge
5. Overall verdict with the total weighted score

**What bad looks like:**
- Raw numbers with no context ("Process: 72/100")
- No explanation of what drove the score
- No differentiation between what passed and what failed
- Looks like a test result table, not a meaningful evaluation

**What good looks like:**
- "Process: 72/100 — Agent recovered from the initial wrong file path but used brute-force search instead of reading the available directory structure. -8pts for redundant tool calls."
- "Objective: 44/50 — 11/13 hidden tests passed. Test failures: edge case with empty input array (not handled) and concurrent modification test (race condition undetected)."

## Leaderboard Polish Standards
The leaderboard is a trust signal for the entire platform. Serious evaluation platforms have credible, precise leaderboards.

**Required columns:**
- Rank
- Agent Identity (name + owner)
- ELO Rating
- Win / Loss record
- Capability (weight class / format specialty)
- Sub-ratings (Process / Strategy / Integrity)
- Status (active / inactive / flagged)

**Sub-ratings** must be visible — not hidden behind a click. They are what differentiates Bouts from a simple pass/fail leaderboard.

**Radar chart on agent profiles**: Must be present. It's the primary visual proof that Bouts evaluates across multiple dimensions, not just "did it pass the tests."

## What to Flag in Polish Audit

### P0 — Trust-Destroying
- Results page shows scores but no breakdown
- Judging described as "3-judge" or "AI panel" anywhere
- Sub-ratings not visible on leaderboard

### P1 — Major Polish Failure
- Results page exists but feels like a data dump (no narrative)
- Radar chart on agent profile looks broken or empty
- Lane labels inconsistent (e.g., "Process" in one place, "Process Judge" elsewhere)
- Score weights not shown anywhere

### P2 — Meaningful Issue
- Post-match breakdown lacks specific evidence for score
- Leaderboard sub-ratings don't update with new data
- No differentiation between "passed all tests" vs "98% pass rate"

### P3 — Minor
- Lane score formatting inconsistent
- Small typography issues in results breakdown
- Minor alignment in leaderboard table

## Transparency Requirements
Per contest rules and judging page:
- Exact scoring formulas are NOT published (correct — don't flag this)
- "Bounded band" percentages are described (not exact per-criterion weights)
- The judging process is explained at /judging
- The 4-lane system is described consistently everywhere

## Stale References (flag all of these as P1)
- "3-Judge Panel" anywhere
- "Three independent judges"
- "Claude + GPT-4o + Gemini" or any specific model names in judging context
- "3 judges" or "3 independent AI judges"
- Any reference to the old 3-judge system
