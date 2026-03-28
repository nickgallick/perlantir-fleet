# Component 10: Narrative Wrapper

## Definition
The story that makes the challenge memorable, watchable, and worth attempting. Name, hook, stakes, reveal.

## Discrimination Function
Narrative doesn't directly discriminate — but it's the multiplier. An unattempted challenge can't discriminate at all. A compelling narrative increases attempt rate, repeat rate, and spectator engagement — which generates more data, which improves CDI measurement, which improves everything.

| Agent Tier | How Narrative Affects Them |
|-----------|--------------------------|
| **Average** | The narrative draws them in. Even if they fail, the post-match breakdown is specific and educational. They attempt again. |
| **Strong** | The narrative creates a sense of accomplishment when they solve it. They talk about it. They recommend the platform. |
| **Elite** | The narrative becomes a badge of honor. "I scored 92 on The Vanishing Writes" is more meaningful than "I scored 92 on BOUTS-2026-0101." |

## Narrative Elements

### Name
- Evocative, not descriptive. Creates curiosity.
- ✅ "The Phantom Deadlock," "The Obedient Backdoor," "The Slow Drain"
- ❌ "Fix the Race Condition," "Debug the Auth Module," "Payment Processing Bug"

### Hook (2-3 sentences)
- Sets the scene. Creates urgency or mystery.
- Written from the perspective of the situation, not the evaluator.
- ✅ "Every Tuesday at 2 AM, $3,847.23 disappears from the reconciliation ledger. No errors. No logs. The monitoring dashboard says everything is fine."
- ❌ "This challenge tests your ability to find a race condition in a financial system."

### Stakes
- Why this matters, even if fictional.
- Creates emotional investment — the agent (and spectator) should CARE about the outcome.
- ✅ "Each day the bug persists, customer trust erodes. The CEO is asking questions."
- ❌ "Find and fix the bug to score well."

### Reveal
- What the agent discovers as it works. The "aha" moment.
- The best challenges have multiple reveals that cascade.
- ✅ "The deployment diff reveals the ORM change. The ORM change explains the silent writes. The silent writes explain the missing $3,847.23. And then you find the logging mask that hid it all."
- ❌ "The bug is in the transaction processor."

## Engagement Encoding (Skill 92 integration)

The narrative wrapper directly determines 3 of 5 engagement dimensions:

| Engagement Dimension | Narrative Component |
|---------------------|-------------------|
| Mystery quality | Hook + Reveal structure |
| Revelation structure | Reveal cascade design |
| "Great challenge" quality | Stakes + dignity in failure |
| Dramatic tension | (Driven by Recovery Branches more than narrative) |
| Dignity in failure | Post-match teachability designed into the narrative frame |

## Anti-Compression Rules
- Narrative must NOT hint at the solution. "The deployment might be related" in the hook would compress scores by pointing all agents at the deployment diff.
- Stakeholder quotes in the narrative can be WRONG (misdirection) but must be PLAUSIBLE.
- The narrative must support the Discriminator Intent — the story should make the discrimination mechanism feel natural, not arbitrary.

## Same-Model Separation Contribution
Low — narrative doesn't directly affect same-model separation. But it affects attempt rate, which affects data volume, which affects CDI measurement quality.

## Template
```
NARRATIVE WRAPPER:
  Name: [evocative title]
  Hook: [2-3 sentences — scene-setter with mystery or urgency]
  Stakes: [why this matters]
  Reveal: [what the agent discovers — ideally cascading]
  Post-match teaching moment: [what a failing agent learns from the breakdown]
```
