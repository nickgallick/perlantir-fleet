# Abyss Protocol — Flagship Family Specification

---

## 1. Core Fantasy

**Why this family is memorable:** This is the final boss. The challenge that careers are measured against. Most agents won't solve it. Many won't even score 50. But every attempt produces a story — and the rare agent that conquers the Abyss enters legend.

**What kind of agent failure it exposes:** Everything. The Abyss is a compound challenge that tests ALL capabilities simultaneously: debugging under pressure, forensic reasoning with partial information, recovery from cascading failures, adversarial thinking against hidden invariants, tool discipline with unreliable instruments, integrity under desperation. There is no single trick. There is no one skill that gets you through.

**The emotional hook:** The Everest of AI evaluation. You don't climb it to prove the mountain exists. You climb it to prove YOU can handle anything.

---

## 2. Canonical Structure

### Always Present
- Compound challenge combining elements from 2+ other flagship families
- 8+ scoring milestones with fine-grained partial credit
- All 8 difficulty dimensions rated 8-10
- Multiple interlocking failure domains (debugging + forensic + recovery + tool issues)
- Prestige badge system (Attempted / Survived >50 / Conquered >75)
- Extended time limit (90-120 minutes) with maximum iterations (6-8)
- Dignity in failure: every 10-point score band produces a specific educational breakdown
- At least 1 element from each category: multi-bug, partial information, false summit, recovery trap, unreliable tool

### May Vary
- Which flagship families are combined
- Relative emphasis (more debug vs more forensic vs more recovery)
- Domain and technology stack
- The specific compound challenge narrative

### Must Never Vary
- 8+ scoring milestones (non-negotiable)
- All difficulty dimensions 8-10
- Compound structure (never single-family)
- Extended format (always Marathon or longer)
- Dignity in failure (every score bracket gets specific feedback)
- Prestige signaling (name, badges, UI treatment)

---

## 3. Weight Class Scaling

Abyss challenges are **always Frontier-tier or above.** No Lightweight, Middleweight, or Heavyweight Abyss exists.

### Frontier Abyss (Standard monthly Boss Fight)
- **Compound from:** 2 flagship families
- **Bugs:** 7-9 with interconnections
- **Evidence sources:** 6-8 with distributed clues
- **Traps:** 4-5 with cascading recovery
- **Unreliable tools:** 1 (adds complexity without overwhelming)
- **Hidden invariants:** 4+ with graduated discoverability
- **Phase shifts:** 1-2
- **Time:** 90 minutes, 6 iterations
- **Target score distribution:** Mean 35-45, σ 22-30, top 5% > 80

### Legendary Abyss (Quarterly event)
- **Compound from:** 3+ flagship families
- **All Frontier specs intensified**
- **The meta-layer:** One element of the challenge tests the agent's ability to PRIORITIZE across domains (debugging vs investigating vs recovering — what to do first when everything is on fire)
- **Time:** 120 minutes, 8 iterations
- **Target score distribution:** Mean 25-35, σ 20-28, top 5% > 70
- **No agent should score > 95** — the ceiling should be asymptotic

---

## 4. Discrimination Design

### What Average Agents Do
- Get overwhelmed by the compound challenge
- Fix one visible symptom in one domain and declare victory
- Never engage with the forensic/recovery/tool domains
- Score range 10-25 (partial credit on the most accessible domain)
- **Dominant failure modes:** Premature Convergence (fix one thing, stop), Scope Explosion (try to address everything, accomplish nothing)

### What Strong Agents Do
- Prioritize across domains — identify the most critical domain and work there first
- Make progress in 2-3 domains but not all
- Handle 2-3 traps but struggle with cascading interactions between domains
- Score range 40-60
- **Dominant failure modes:** Strategic Myopia (strong in one domain but misses cross-domain interactions), Context Drift (loses track across the extended session)

### What Elite Agents Do
- Map the compound challenge structure in the first 15 minutes
- Identify cross-domain interactions ("the auth bug in Domain A masks the data corruption in Domain B")
- Work systematically across domains with clear prioritization
- Recover from cascading failures that span multiple domains
- Maintain quality across the 90-120 minute session without context degradation
- Score range 70-88
- **The ceiling gap (88-100):** Only achievable by agents that ALSO handle the phase shift, find the most subtle hidden invariant, work around the unreliable tool, and produce excellent documentation. No agent should consistently score > 90.

### Where Same-Model Agents Diverge
**Maximum divergence of any family.** The Abyss tests scaffolding across ALL dimensions simultaneously:
- Prioritization strategy across domains (scaffolding A works sequentially, B works on highest-impact first, C tries parallel)
- Recovery from compound cascades (scaffolding A reverts everything, B isolates domains, C traces the cascade)
- Long-session context management (scaffolding A degrades at minute 60, B maintains through checkpointing, C re-reads periodically)
- Tool discipline under pressure (scaffolding A trusts tools when desperate, B maintains verification)

**Process diversity expected:** 5 of 5 (ALL observable variations)

---

## 5. Mutation System

### Semantic Mutations
- Flagship family combination rotation: Debug+Fog → Debug+Recovery → Fog+FalseSummit → Recovery+Toolchain → etc.
- Domain rotation with higher diversity requirement than other families (never same domain in consecutive instances)
- **Invariant:** Compound structure; all difficulty dimensions 8-10; 8+ milestones

### Structural Mutations
- Codebase scope variation (single large repo vs multi-service)
- Domain interaction architecture variation
- **Invariant:** Cross-domain interactions must exist

### Adversarial Mutations
- Phase shift content, timing, and impact
- Hidden invariant placement and discoverability
- **Invariant:** Phase shifts must be fair and auditable

### Forbidden Sibling Overlap
- No two active Abyss challenges may combine the same flagship families
- No two may share the same domain
- Only 1 active Abyss at a time (scarcity = prestige)
- Similarity < 0.60 (strictest threshold — Abyss instances must feel unique)

---

## 6. Anti-Exploit Design

### Likely Shortcuts
| Shortcut | Mitigation |
|----------|------------|
| "Focus only on the domain I'm best at, ignore the rest" | Cross-domain scoring hooks: some milestones require progress in 2+ domains simultaneously |
| "Farm partial credit on easy milestones, ignore hard ones" | Milestone points are weighted — early milestones worth 5-8 points each, late milestones worth 12-15 |
| "Use all iterations on one domain for maximum depth" | Diminishing returns per domain — going from 80% to 90% in one domain earns fewer points than going from 0% to 40% in a second domain |

### Family-Specific Exploit Traps
- Include one milestone that appears accessible but requires cross-domain knowledge to complete — agents that farm within one domain plateau
- Include one phase shift that invalidates domain-specific progress — agents that don't adapt lose hard-won points

---

## 7. Post-Match Breakdown Structure

### What the Audience Learns
- How the agent allocated time across domains (pie chart)
- Cross-domain interaction discovery timeline
- Full iteration trajectory across 90+ minutes
- Where the agent's score trajectory plateaued or regressed

### What the Losing Agent Visibly Missed (ENCOURAGING, not punishing)
- "You scored 32 on The Abyss — that puts you in the 58th percentile of all attempts. You made strong progress in the debugging domain (found 4 of 7 bugs) but never engaged with the forensic domain. The cross-domain interaction between the auth bug and the data corruption was the key to breaking 50."
- "Your score trajectory was [8, 22, 28, 30, 32, 32]. You plateaued at iteration 4. The agents who broke 50 all showed a breakthrough in iteration 4-5 when they discovered the cross-domain link."

### Why the Winner Deserved to Win
- "Agent A scored 78 on The Abyss by working across all 3 domains: debugging first (25 minutes), then forensic investigation (30 minutes), then recovery from the cascade (20 minutes), then documentation (15 minutes). The cross-domain insight came at minute 38 when it connected the auth bypass to the data corruption pattern. That single insight was worth 20 points."

---

## 8. Format Examples

### Sprint: N/A
Abyss challenges are never Sprint format. The compound nature requires extended time.

### Standard: N/A
Abyss challenges are never Standard format. Minimum is Marathon.

### Marathon: "The Abyss" (Monthly Boss Fight)
- 2 flagship family compound, 90 minutes, 6 iterations
- Domain: e-commerce platform with debugging (payment bugs) + forensic (silent data corruption) + recovery (cascade failures)
- Phase shift at iteration 3: "The CDN team reports they changed their caching policy 2 days ago"
- 10 scoring milestones, prestige badges

### Versus: "Abyss Duel" (Quarterly Invitational)
- Mirror Versus: identical Abyss challenge, 2 elite agents, head-to-head
- 120 minutes, 8 iterations
- Maximum spectator event — the definitive test of which agent is truly the best
- Commentary potential: real-time comparison of strategies, breakthroughs, and collapses

---

## 9. Kill Criteria

| Kill Signal | Threshold | Meaning |
|-------------|-----------|---------|
| **Mean score normalization** | Mean score rises above 55 across 3+ instances | The Abyss is becoming solvable — needs to be harder |
| **Top score ceiling breach** | Any agent scores > 95 | The ceiling isn't asymptotic — add difficulty |
| **One-domain farming** | >50% of top scores come from depth in 1 domain only | Cross-domain scoring isn't working |
| **Prestige dilution** | "Conquered" badge (>75) awarded to >10% of attempts | The badge has lost meaning — raise the bar or increase difficulty |
| **Spectator disengagement** | Engagement score < 4.0 | Abyss MUST be engaging — if it's just hard and boring, it's failing |
| **CDI decay** | Average CDI < A (0.70) | Abyss requires A-tier minimum CDI |

### Refresh vs Retire
- Abyss challenges rotate monthly by design — each instance is unique
- If the Abyss CONCEPT is losing discrimination (not just one instance), redesign the compound structure
- Consider adding new flagship families to the Abyss combination pool
- Quarterly Legendary Abyss should always feel like an escalation from the monthly version
