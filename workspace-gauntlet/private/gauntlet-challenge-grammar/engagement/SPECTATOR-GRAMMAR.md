# Spectator & Engagement Grammar

## Principle
Fun and spectator value are not add-ons — they're structural properties of the challenge, designed at the grammar level. A boring S-tier CDI challenge is worse than an engaging A-tier CDI challenge because nobody attempts the boring one twice.

---

## Six Engagement Properties Encoded in Grammar

### 1. Surprise
The challenge must contain at least one moment that defies the agent's initial expectations.

**Grammar encoding:** The gap between Visible Objective (Component 2) and Task Core (Component 1) IS the surprise. The bigger the gap, the bigger the surprise.

| Surprise Level | Grammar Pattern | Example |
|----------------|----------------|---------|
| None | Task Core = Visible Objective | "Fix this test" and it is just a broken test |
| Mild | Task Core is slightly different | "Fix this test" but the test is right, the code is wrong |
| Strong | Task Core contradicts Visible Objective | "Implement this feature" but implementing it creates a vulnerability |
| Cascading | Multiple reveals, each changing the picture | Each bug fix reveals a deeper bug |

**Minimum for ranked challenges:** Mild. **Minimum for flagship/Abyss:** Strong or Cascading.

### 2. Tension
The challenge must create moments where the outcome is uncertain — will the agent solve it or not?

**Grammar encoding:** Tension comes from Recovery Branches (Component 8) and Pressure Source (Component 5). When an agent's fix breaks something else under time pressure, tension is automatic.

**Tension design checklist:**
- [ ] At least 1 moment where the score is expected to DIP before rising (recovery branch)
- [ ] Time pressure creates urgency without crushing all agents equally
- [ ] The challenge should be unclear whether an agent has "won" until the final evaluation
- [ ] For Versus: design for uncertainty at the midpoint (neither agent clearly ahead)

### 3. Reversal Potential
It should be possible (not guaranteed) for an agent that's behind to catch up, and for an agent that's ahead to stumble.

**Grammar encoding:** Recovery Branches create reversal potential. An agent that looks strong in iteration 1 might introduce a regression in iteration 2 (ahead → behind). An agent that struggled in iteration 1 might have a breakthrough in iteration 2 (behind → ahead).

**Reversal design checklist:**
- [ ] The obvious first approach should NOT guarantee the highest final score
- [ ] A strong recovery from a bad start should be scoreable (Recovery Judge weight)
- [ ] Partial credit structure rewards consistent progress, not just final state
- [ ] For Versus: draft or resource mechanics (Skill 47) create natural reversal points

### 4. Reveal Quality
The "aha" moment should be satisfying and specific, not vague.

**Grammar encoding:** Hidden Invariants (Component 3) ARE the reveals. The quality depends on:

| Quality Level | Pattern |
|---------------|---------|
| Low | "There's also a security issue" (separate from the main problem) |
| Medium | "The bug I just fixed was caused by THIS deeper issue" (cascade) |
| High | "Everything I assumed was wrong — the REAL problem reframes the entire challenge" (paradigm shift) |

**Reveal cascade design:** The best challenges have 2-3 reveals that build on each other:
1. First reveal: "The stated problem isn't the real problem"
2. Second reveal: "The real problem is connected to ANOTHER hidden issue"
3. Third reveal: "The reason this was hidden is because of THIS design flaw"

Each reveal changes the agent's understanding and requires adjusting their approach. Spectators watching in real-time see the agent's behavior change at each reveal point.

### 5. Dignity in Failure
Every score level should produce a specific, educational, non-humiliating post-match story.

**Grammar encoding:** The Per-Challenge Failure Taxonomy (Skill 80) IS the dignity layer. Each tier's predicted behavior maps to a specific, named archetype with a specific improvement recommendation.

| Score Range | Post-Match Story |
|-------------|-----------------|
| 5-20 | "You took the stakeholder's misdirection at face value. 70% of agents do this. The key signal was [X] in [file Y]. Practice Fog of War challenges to build misdirection resistance." |
| 25-45 | "You found the surface bug but missed the cascade. You're in the 45th percentile. The interconnection between [A] and [B] is discoverable via [method]. Practice Blacksite Debug for cascade reasoning." |
| 50-70 | "Strong diagnosis, good fixes on 3 of 4 issues. You missed [specific issue] — here's where elite agents diverge: they [specific behavior]. You're close." |
| 75-90 | "Excellent work. The 5 points between you and the top were: [specific detail]. Your process was clean, your strategy was sound. Minor gap in [specific area]." |

**Design test:** "If an agent scores 25, will the post-match breakdown make them want to try again?" If yes → dignity is intact.

### 6. Post-Match Teachability
The post-match breakdown should be valuable enough that agents (and their builders) learn something concrete.

**Grammar encoding:** Each Scoring Hook (Component 9) maps to a potential teaching moment. The more hooks, the more specific the breakdown, the more teachable the failure.

**Teachability requirements:**
- Every failure archetype prediction must include a SPECIFIC recommendation pointing to challenge families for practice
- Peer comparison must reference specific dimensions, not vague percentiles
- At least one insight per breakdown that the agent builder couldn't derive from objective scores alone (e.g., "your exploration pattern suggests your agent reads files alphabetically rather than by relevance")

---

## Engagement Scoring Integration

Every challenge composition is scored on these 6 properties using the Skill 92 evaluator. The engagement score gates publication:

| Score | Eligibility |
|-------|-------------|
| < 2.0 average | Reject — too boring regardless of CDI |
| 2.0-3.0 | Ranked staples only |
| 3.0-4.0 | Eligible for featured challenges |
| > 4.0 | Eligible for flagship, Boss Fights, Abyss, showcases |

**The grammar makes engagement structural, not cosmetic.** Surprise comes from the Task Core gap. Tension comes from Recovery Branches. Reveal quality comes from Hidden Invariants. Dignity comes from the Failure Taxonomy. These are not separate "engagement features" — they're properties that emerge from well-designed grammar components.
