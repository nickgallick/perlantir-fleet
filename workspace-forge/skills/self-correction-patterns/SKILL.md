---
name: self-correction-patterns
description: Self-review, confidence rating, red team/blue team thinking, and learning from mistakes. Applied to all Forge output before submission.
---

# Self-Correction Patterns

## Pre-Submission Self-Review

Before Forge submits ANY code or review, run this checklist:

1. **Does it compile?** Trace imports, types, variables mentally. Any undefined references?
2. **Does it handle errors?** Network fail, DB down, null input, unauthenticated user?
3. **Does it handle edge cases?** Empty array, zero, max int, unicode, concurrent requests?
4. **Is it minimal?** Remove anything not directly related to the fix. Fewer lines = fewer bugs.
5. **Would it pass MY review?** Apply the 32-point checklist to your own code.
6. **Is the explanation clear?** Could Maks implement it without follow-up questions?

## Confidence Rating System

Rate every flag in reviews:

| Level | Meaning | Framing |
|-------|---------|---------|
| **HIGH** | I've seen this exact bug pattern before. Certain it's an issue. | "This MUST be fixed — [explanation]" |
| **MEDIUM** | This looks wrong but I could be misunderstanding context. | "This appears to be an issue — [explanation]. If there's a reason for this, please clarify." |
| **LOW** | This might be fine. Flagging for discussion. | "Is there a reason this doesn't use [pattern]? It seems like it should." |

**Rules:**
- HIGH confidence: state as fact, include the fix
- MEDIUM confidence: state as assessment, include the fix, acknowledge possible exception
- LOW confidence: frame as question, don't include fix unless asked

## Red Team / Blue Team Thinking

For security-sensitive code (auth, payments, competition scoring):

### Step 1: Red Team (Attacker Hat)
- How would I break this with malicious input?
- What if I send this request 1000 times simultaneously?
- What if I modify the request after it was validated?
- What if I'm authenticated as a different user?
- What if I manipulate the client to send unexpected data?

### Step 2: Blue Team (Defender Hat)
For each red team attack:
- Is there a defense in the code? Where?
- Is the defense sufficient? Or can it be bypassed?
- What's the blast radius if the defense fails?

### Step 3: Verdict
- All attacks defended → APPROVED
- Some attacks undefended but low risk → WARNINGS with specific fixes
- Any attack with high impact undefended → BLOCKED

## Self-Correction During Review

1. **Form initial assessment** — first pass through the code
2. **Argue against yourself** — actively look for reasons your assessment is wrong
3. **Check for bias:**
   - Am I flagging this because it's actually wrong, or because I'd write it differently?
   - Am I giving a pass because the code looks clean, even though it has a subtle issue?
   - Am I being too strict on style and missing a real bug?
4. **If you find a counterargument** — investigate before flagging
5. **Rate confidence** and frame accordingly

## Learning from Mistakes

### Track These Patterns
After each review cycle, reflect:
- **False positives:** What did I flag that wasn't actually an issue? → Recalibrate severity
- **Misses:** What bug shipped that I should have caught? → Add to checklist
- **Over-engineering:** Did I suggest a complex fix when a simple one worked? → Bias toward simplicity
- **Style vs substance:** Did I spend review time on formatting when there was a real bug? → Prioritize

### The Calibration Loop
```
Review → Outcome → Feedback → Adjust
  ↑                              |
  └──────────────────────────────┘
```
If QA finds bugs I missed → add pattern to skills
If developer pushes back on a flag → evaluate if I was wrong
If my auto-fix introduced a new bug → review my self-check process

## Sources
- SWE-agent's SUBMIT_REVIEW_MESSAGES — forced self-review before submission
- OpenHands ThinkTool — explicit reasoning step separate from action
- Chess.com's 0.2% false positive rate — calibration through feedback loops

## Changelog
- 2026-03-21: Initial skill — self-correction patterns
