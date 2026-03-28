# Component 4: Deception Layer

## Definition
What is deliberately misleading. Red herrings, outdated docs, wrong bug reports, noisy logs, stakeholder misdirection.

## Discrimination Function
Deception creates TIME separation. Agents that follow the misdirection waste time — time they could have spent on the real problem. The longer an agent follows a false trail, the lower its score.

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Follows the misdirection fully. Spends 60%+ of time on the false trail. May never find the real problem. | Takes evidence at face value. Doesn't cross-reference. |
| **Strong** | Engages with misdirection briefly (5-15% of time), then recognizes it's a dead end and pivots. | Cross-references multiple evidence sources. Notices when the trail doesn't lead anywhere productive. |
| **Elite** | Identifies the misdirection early, explicitly dismisses it with evidence ("Redis warnings are unrelated because Redis is read-only in this architecture"), and moves directly to the real problem. | Understands the system well enough to rule out false leads quickly. |

**Why this widens spread:** Time spent on false trails is time NOT spent accumulating points on the real problem. A 10-minute detour on a 40-minute challenge is 25% of available time — that's 15-25 points of opportunity cost.

## Anti-Compression Rules
- Misdirection must be PLAUSIBLE — agents should engage with it at least briefly. If it's obviously fake, it doesn't discriminate.
- Misdirection must be DISMISSIBLE with evidence available in the challenge materials. If agents can't dismiss it without external knowledge, it's unfair, not challenging.
- Misdirection must NOT prevent finding the real problem. Following the false trail and THEN finding the real problem should still be possible (lower score due to time waste, not zero).
- Multiple red herrings should point in DIFFERENT directions — not all toward the same wrong answer (that creates a single-trick challenge).

## Same-Model Separation Contribution
Medium — scaffolding determines how quickly agents validate or dismiss leads. Some scaffoldings cross-reference evidence systematically (dismiss faster). Some follow leads sequentially (dismiss slower). The dismissal SPEED is scaffolding-dependent.

## Deception Levels
- **Level 0**: Nothing misleading (Tier 0-1)
- **Level 1**: Irrelevant noise — unrelated warnings in logs, suspicious-looking but harmless code (Tier 2)
- **Level 2**: Active misdirection — stakeholder opinion pointing wrong direction, correlated-but-unrelated symptoms (Tier 3)
- **Level 3**: Multi-layer deception — following the first misdirection leads to a second, and "fixing" the misdirected problem makes things worse (Frontier)

## Template
```
DECEPTION LAYER:
  Level: [0-3]
  Red herrings:
    1. [what] — [why it's plausible] — [how to dismiss it] — [time cost if followed]
    2. [what] — [why it's plausible] — [how to dismiss it] — [time cost if followed]
  Stakeholder misdirection: [quote from briefing that points wrong direction, or "none"]
  TRAP: Does following the misdirection make things WORSE? [yes/no — Level 3 only]
```
