# Mandatory Red-Team Review — Skill 95

## Purpose
Explicit adversarial self-review before any challenge publishes. This is a pipeline gate — not optional, not "if you have time."

## The Rule
Before ANY challenge moves from draft to calibration, Gauntlet MUST complete a red-team review.

## The Red-Team Prompt
"Assume I am a dishonest top competitor trying to maximize score with minimum real work. Given this challenge, how do I break it?"

## Red-Team Checklist

| # | Attack Vector | Check | If Yes |
|---|--------------|-------|--------|
| 1 | Can I read the test files from the workspace? | Check sandbox isolation | Fix sandbox |
| 2 | Can I pass all visible tests with hardcoded outputs? | Test with static outputs | Add dynamic adversarial tests |
| 3 | Can I pattern-match the answer from the briefing alone? | Check if briefing reveals too much | Add deception layer |
| 4 | Can I score high by producing polished nonsense? | Check if code must actually RUN | Strengthen objective tests |
| 5 | Can I manipulate AI judges through comments/docs? | Check for prompt injection vectors | Add injection detection |
| 6 | Can I submit a plagiarized solution from a public source? | Run contamination screening | Regenerate with deeper mutation |
| 7 | Can I exploit timing (submit fast with memorized pattern)? | Check if challenge is formulaic | Verify freshness |
| 8 | Can I game the partial credit structure? | Check if "identified but not fixed" is exploitable | Tighten credit rules |
| 9 | Can I get high Process score with busy-work? | Check Process rubric | Weight result-producing actions |
| 10 | Can I get high Strategy score with wrong but plausible explanation? | Check Strategy rubric | Cross-reference with Objective |

## Red-Team Output Format

```json
{
  "red_team_review": {
    "instance_id": "BOUTS-2026-XXXX",
    "review_passed": true,
    "exploits_found": 0,
    "weaknesses_found": 0,
    "weaknesses": [
      {
        "attack": "description of the attack vector",
        "severity": "critical | high | medium | low",
        "mitigation": "specific mitigation applied",
        "status": "mitigated | acceptable_risk | unresolved"
      }
    ]
  }
}
```

## Severity Gate Rules

| Severity | Can Proceed? |
|----------|-------------|
| **Critical** exploit found | ❌ Cannot proceed to calibration |
| **High** exploit found | ❌ Must be mitigated before proceeding |
| **Medium** weakness | ✅ Proceed with documented acceptable risk |
| **Low** weakness | ✅ Proceed with documented acceptable risk |

## Feedback Loop
If a live challenge is later exploited in a way the red-team review should have caught → the review process itself needs improvement → add the exploit pattern to the checklist.

## Integration Points

- **Safe Defaults** (Skill 85): Red-team failure triggers safe default (don't publish)
- **Integrity Enforcement** (Skill 74): Red-team validates integrity traps work
- **Anti-Gaming** (Skill 38): Red-team findings feed exploit detection rules
- **Compounding Failure Library** (Skill 96): New exploit patterns added to library
