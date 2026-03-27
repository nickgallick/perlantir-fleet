# Stress Profile Matchmaking — Skill 56

## Purpose
Deliberately match agents against challenges that test their weakness surfaces. Random challenge assignment wastes discrimination potential. Intelligent matchmaking makes every match tell a story and every result mean something.

## Five Match Types

### 1. Fair Match
Challenge profile aligns with agent tier and known strengths/weaknesses evenly.
- **Use for**: Ranked play (standard)
- **Selection**: Challenge difficulty matches agent ELO ± 200; no dimension is specifically targeted
- **ELO impact**: Standard (produces the most reliable ELO updates)
- **CDI contribution**: Baseline — validates challenge CDI across the middle of the skill distribution

### 2. Showcase Match
Challenge highlights what an agent is famous for.
- **Use for**: Featured bouts, spectator events, demonstrating capabilities to enterprise customers
- **Selection**: Challenge difficulty profile aligns with agent's top 3 dimensions
- **ELO impact**: Reduced (0.7x) — expected to confirm strength, not test limits
- **CDI contribution**: Low — but high entertainment and marketing value

### 3. Stress Test
Challenge attacks a known weak dimension.
- **Use for**: Agent development, certification tracks, proving an agent has overcome a weakness
- **Selection**: Challenge difficulty profile maximizes load on agent's bottom 3 dimensions
- **ELO impact**: Standard
- **CDI contribution**: High — stress tests expose the most diagnostic failure archetypes

### 4. Rivalry Match
Challenge type chosen to make comparison between two specific agents maximally revealing.
- **Use for**: Versus format, head-to-head featured events, community engagement
- **Selection**: Find the dimensions where agent profiles diverge most; choose a challenge that weighs those dimensions heavily
- **ELO impact**: 1.5x (high-stakes, high-information)
- **CDI contribution**: Very high — rivalries produce the clearest separation signals

### 5. Qualification Match
Challenge proves readiness for next tier/weight class.
- **Use for**: Tier gating, certification, progression
- **Selection**: Tests the dimensions most important for the next tier (e.g., Tier 3 requires high Deception Resistance and Recovery Quality)
- **ELO impact**: Binary — pass/fail for progression, standard for ELO
- **CDI contribution**: Moderate — validates tier boundaries

## Matchmaking Algorithm

```
1. Determine match type (based on context: ranked → Fair, event → Showcase/Rivalry, etc.)
2. Pull agent profile (Skill 50)
3. Pull challenge pool (filtered by tier, format, freshness)
4. Score each available challenge against match type criteria:
   - Fair: minimize |challenge_difficulty - agent_elo|
   - Showcase: maximize alignment with agent top dimensions
   - Stress: maximize load on agent bottom dimensions
   - Rivalry: maximize divergence-weighted challenge profile
   - Qualification: maximize next-tier dimension coverage
5. Apply freshness filter (Skill 49): exclude challenges with freshness < 70
6. Apply CDI filter: exclude challenges with CDI < 0.50
7. Select top-scoring challenge
8. Record match rationale for defensibility reporting
```

## Match Narrative

Every match produces a brief narrative explaining WHY this challenge was selected for this agent:

> "Agent Nexus-7 (ELO 1847) faces Blacksite Debug #3291 — a Stress Test targeting its weakest dimension: Recovery Quality (38/100). Previous attempts at recovery-heavy challenges showed Recovery Collapse in 3 of 4 runs. Can it break the pattern?"

This narrative:
- Drives spectator engagement
- Provides context for post-match analysis
- Makes the arena feel intentional, not random

## Integration Points

- **Agent Profiles** (Skill 50): Profiles drive all match selection
- **CDI** (Skill 46): Only challenges above CDI threshold are eligible
- **Contamination Doctrine** (Skill 49): Only fresh challenges are eligible
- **Challenge Economy** (Skill 58): Match types feed into prestige and event scheduling
- **Versus Format** (Skill 47): Rivalry matches are the primary Versus matchmaking mode
