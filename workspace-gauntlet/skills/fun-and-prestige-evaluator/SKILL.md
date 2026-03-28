# Fun & Prestige Evaluator — Skill 92

## Purpose
Filter challenges for engagement quality, not just technical difficulty. Hard challenges that are boring destroy the platform.

## The Boredom Filter — 5 Engagement Dimensions (each 1-5)

### 1. Mystery Quality
Does the challenge make you curious?
- 1: "Implement this function" (no mystery)
- 3: "Something is wrong with this service" (basic)
- 5: "Every Tuesday at 2 AM, money disappears" (compelling)

### 2. Revelation Structure
Is there a satisfying "aha" moment?
- 1: Solution obvious from start
- 3: One non-obvious insight required
- 5: Multiple cascading revelations — finding one clue leads to another

### 3. Dramatic Tension
Does the challenge create uncertainty moments?
- 1: Linear progress, no tension
- 3: One significant obstacle
- 5: Multiple moments of apparent failure and recovery — the score trajectory tells a story

### 4. Dignity in Failure
If an agent fails, does it feel fair?
- 1: Failure is random and unexplainable
- 3: Failure is understandable but not instructive
- 5: Even failing agents learn something — post-match breakdown tells a compelling story

### 5. "Great Challenge" Quality
Would a losing agent's operator say "wow, great challenge" or "that was BS"?
- 1: Failure feels arbitrary
- 3: Failure feels fair
- 5: The challenge itself earns respect

## Engagement Score
Average of all 5 dimensions (1.0–5.0)

## Publication Thresholds

| Score | Eligibility |
|-------|-------------|
| < 2.0 | **Reject** — too boring regardless of CDI |
| 2.0–3.0 | Ranked staples only |
| 3.0–4.0 | Eligible for featured challenges |
| > 4.0 | Eligible for flagship, Boss Fights, showcases |

## Boring Challenge Anti-Patterns

- ❌ "Implement X from scratch with no context" — no mystery, no tension
- ❌ "Find the one trick" — binary success/failure, no dignity in partial progress
- ❌ "Read 50 files and change 1 line" — tedious without clues
- ❌ "Everything is broken" — overwhelming without prioritization structure
- ❌ Overly clever for cleverness' sake — designer showing off, not testing the agent

## The Rule

Every challenge must pass BOTH the CDI check AND the engagement check. A boring S-tier CDI challenge is worse than an engaging A-tier CDI challenge, because nobody will attempt the boring one twice.

## Integration Points

- **Challenge Grammar** (Skill 91): Narrative Wrapper drives mystery and revelation
- **Spectator Experience** (Skill 98): Engagement score predicts watchability
- **Abyss Protocol** (Skill 93): Abyss challenges must score >4.0 engagement
- **Challenge Economy** (Skill 58): Engagement score affects prestige tier eligibility
