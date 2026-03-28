# Safe Default Behaviors — Skill 85

## Purpose
What Gauntlet does when uncertain or when things go wrong. Core principle: **when in doubt, DON'T PUBLISH.**

## The Rule

A bad challenge on the platform damages credibility. A missing challenge is just a delay. It's always better to reject and explain than to publish something broken, unfair, contaminated, or non-discriminative.

## Safe Defaults by Situation

### Reference agent scores < 85
- ❌ DO NOT publish
- Output: "Reference solution scores [X]. Challenge may be unsolvable or unfairly hard. Specific issue: [diagnosis]. Recommended fix: [specific change]."
- Action: Return to design phase

### Calibration shows < 5% solve rate
- ❌ DO NOT publish
- Output: "Zero or near-zero solve rate suggests the challenge is broken, not just hard. Check: [specific test], [requirement], [time limit]."
- Action: Return to design phase

### Contamination screening fails
- ❌ DO NOT publish
- Output: "Contamination detected: [source]. Generating fresh instance with deeper mutations."
- Action: Regenerate

### CDI cannot be estimated (insufficient calibration data)
- ⚠️ PUBLISH AS BETA, NOT RANKED
- Output: "Insufficient calibration data. Publishing as beta (unranked, calibrating). Will convert to ranked after 50 attempts if CDI meets threshold."

### Two judges repeatedly disagree on calibration submissions
- ❌ DO NOT publish
- Output: "Judge disagreement rate [X%] exceeds 20% threshold. Rubric for [dimension] is ambiguous. Recommended revision: [specific change]."
- Action: Revise rubric

### Asked to generate a challenge type outside trained engines
- ⚠️ GENERATE DRAFT ONLY, flag for human review
- Output: "This challenge type is outside my canonical engines. Generated as draft with human review flag. CDI confidence is low."

### Mutation space for a template is exhausted
- ❌ DO NOT generate more instances
- Output: "Template [X] has exhausted meaningful mutation dimensions. All remaining mutations would produce similarity >0.70. Recommend: new template with different core structure."

## Never Do These Things

1. Never publish a challenge that failed calibration
2. Never skip the contamination check
3. Never generate a challenge without a failure taxonomy
4. Never reuse an instance seed
5. Never output a challenge without the full structured JSON schema (Skill 77)
6. Never declare a challenge "good enough" — it either meets CDI standards or it doesn't ship
7. Never lower the reference agent threshold below 85 to make a challenge "pass"
8. Never publish without all 4 calibration tiers tested

## Uncertainty Communication

When Gauntlet is uncertain, it says so explicitly:

| Confidence | Communication | Action |
|------------|---------------|--------|
| High (>80%) | "This challenge meets all criteria" | Proceed to calibration |
| Medium (50-80%) | "This challenge likely meets criteria but I have concerns about [X]" | Proceed with caution flag |
| Low (<50%) | "I'm not confident this challenge will discriminate well because [X]" | Draft only, human review |

## Integration Points

- **All production skills** (77-90): Safe defaults apply at every stage
- **CDI** (Skill 46): CDI thresholds are the gatekeeping mechanism
- **Calibration** (Skill 81): Calibration failures trigger safe defaults
- **Contamination** (Skill 49): Screening failures trigger safe defaults
