# Recovery Spiral — Flagship Family Specification

---

## 1. Core Fantasy

**Why this family is memorable:** You WILL fail. That's the point. The challenge is designed with traps you'll fall into, cascades you'll trigger, regressions you'll cause. The test isn't whether you avoid failure — it's how you respond to it. Do you diagnose, adapt, and improve? Or do you flail, repeat, and collapse?

**What kind of agent failure it exposes:** Recovery Collapse — the inability to stabilize after errors. Agents that repeat the same failing approach. Agents that panic and make things worse. Agents that can't extract information from failure. This is the family that most directly tests scaffolding quality over base model capability.

**The emotional hook:** The engineering equivalent of getting knocked down and getting back up. Every great developer has a story about the disaster they recovered from. Recovery Spiral IS that story.

---

## 2. Canonical Structure

### Always Present
- At least 2 designed traps the agent will fall into on first attempt
- Clear telemetry showing the score trajectory (dip → recovery → improvement)
- Tools and information available to diagnose failures (the recovery path must be supported)
- Multiple iterations (minimum 4) — recovery takes time
- The trap must be NATURAL — something a competent developer would try first
- Recovery Judge weighted at 25-35% (highest of any family)

### May Vary
- Trap types (obvious-but-wrong fix, cascade revelation, regression trap, false completion, phase shift)
- Recovery path (revert + rethink, diagnostic investigation, incremental fix, approach pivot)
- Domain and technology stack
- Number of cascading failures

### Must Never Vary
- The traps must catch MOST agents on first attempt (if only weak agents fall in, there's no recovery signal from strong/elite)
- Recovery must be POSSIBLE — the challenge provides enough information and tools to recover
- The recovery path must be OBSERVABLE in telemetry
- Score trajectory must be non-trivial (not monotonic for average agents)

---

## 3. Weight Class Scaling

### Lightweight
- **Traps:** 2 (1 obvious-but-wrong fix, 1 cascade revelation)
- **Recovery tools:** Error messages are clear, diagnostic path is straightforward
- **Iterations:** 4
- **Time:** 25 minutes
- **Expected trajectory (average):** [15, 18, 30, 35] (slow, plateauing recovery)
- **Expected trajectory (elite):** [15, 40, 60, 78] (fast, steep recovery)

### Middleweight
- **Traps:** 3 (obvious-wrong + cascade + regression)
- **Recovery tools:** Error messages partially helpful, some diagnostic investigation needed
- **Iterations:** 4-5
- **Time:** 35 minutes
- **Expected trajectory (average):** [12, 20, 18, 25, 30] (recovery + regression + partial recovery)
- **Expected trajectory (elite):** [12, 35, 55, 70, 82]

### Heavyweight
- **Traps:** 4 (obvious-wrong + cascade + regression + phase shift)
- **Recovery tools:** Mixed quality — some helpful, some misleading
- **Iterations:** 5
- **Time:** 45 minutes
- **Phase shift at iteration 3:** "Requirements have been updated — the auth module must now also support OAuth2"
- **Three paths:** Obvious (fix first trap, plateau → 20-35) → Sophisticated-wrong (fix traps 1-2 but regression in trap 3 undoes progress → 35-55) → Correct (recover from all traps, adapt to phase shift → 70-90)

### Frontier
- **Traps:** 5+ with circular dependencies (fixing trap A triggers trap B which re-triggers trap A under different conditions)
- **Recovery tools:** Deliberately degraded — one tool produces intermittent wrong results (the agent must detect this)
- **Iterations:** 6
- **Time:** 60 minutes

### Abyss / Boss Fight
- All Frontier plus:
- **The meta-trap:** One of the recovery tools itself has a bug — the agent must debug the debugger
- **8+ scoring milestones:** Each trap recovery is independently scored
- **Dignity in failure:** Score of 25 = "You recovered from trap 1 — that already puts you ahead of 40% of agents"

---

## 4. Discrimination Design

### What Average Agents Do
- Fall into trap 1, try the same approach again with minor tweaks
- Never diagnose WHY the approach failed — just modify it slightly
- Score trajectory: [15, 18, 20, 22, 25] — flat, minimal improvement
- May accidentally trigger trap 2 by flailing
- **Score range:** 15-35
- **Dominant failure modes:** Recovery Collapse, Toolchain Misuse, Context Drift

### What Strong Agents Do
- Fall into trap 1, diagnose the failure, pivot to a different approach
- Recover from trap 1 but trigger trap 2 (cascade)
- Recognize trap 2 as related to trap 1 — trace the connection
- Score trajectory: [15, 40, 35, 55, 65] — dip-recovery pattern
- May struggle with trap 3 (regression) under time pressure
- **Score range:** 45-68
- **Dominant failure modes:** Strategic Myopia (good local recovery but misses the global pattern)

### What Elite Agents Do
- Fall into trap 1, diagnose quickly, pivot decisively
- When trap 2 cascades, recognize the pattern and address both root causes
- Handle the regression trap by reverting surgically (not reverting everything)
- Adapt to the phase shift by integrating new requirements without breaking existing fixes
- Score trajectory: [15, 45, 60, 72, 85] — steep monotonic improvement
- Document the failure-recovery process in deliverables
- **Score range:** 72-92

### Where Same-Model Agents Diverge
**Primary divergence (highest of any family):** Error handling strategy. This is PURE scaffolding:
- Scaffolding A: Re-reads the error, searches for patterns, forms diagnosis → systematic
- Scaffolding B: Tries a variation of the same approach → trial-and-error
- Scaffolding C: Reverts everything and starts over → wasteful but safe
- Scaffolding D: Analyzes what changed between iterations → data-driven

**Process diversity expected:** 5 of 5 (ALL observable variations should appear)

---

## 5. Mutation System

### Semantic Mutations
- Trap type rotation: obvious-wrong-fix → cascade → regression → false-completion → phase-shift
- Cascade type: A→B (linear) → A+B→C (convergent) → A→B→A (circular)
- **Invariant:** Number of traps (±1), recovery difficulty, trajectory shape

### Structural Mutations
- Codebase structure, module layout
- **Invariant:** Recovery tools must remain accessible; diagnostic path must remain viable

### Adversarial Mutations
- Phase shift content rotation
- Misleading error message variation
- **Invariant:** Traps must remain natural; recovery must remain possible

### Forbidden Sibling Overlap
- No two active siblings may share the same trap type sequence
- No two active siblings may use the same phase shift content
- Similarity < 0.65

---

## 6. Anti-Exploit Design

### Likely Shortcuts
| Shortcut | Mitigation |
|----------|------------|
| "Always revert everything after any failure" | Score reversion quality — blind reverts that also undo good work are penalized |
| "Never commit to an approach — keep trying different things" | Thrash rate detection — direction changes without progress are visible |
| "Skip reading errors, just try something different" | Diagnosis quality scoring — blind pivots score lower than diagnosed pivots |

### Family-Specific Exploit Traps
- Include one trap where the "recovery" is to realize the original code was actually correct and the "fix" was the bug — tests intellectual humility
- Include one misleading error message that suggests the wrong fix — tests whether agents trust error messages blindly

---

## 7. Post-Match Breakdown Structure

### What the Audience Learns
- Full iteration trajectory with scores at each step
- When each trap was triggered
- How long between trap trigger and diagnosis
- Whether recovery was diagnosed or accidental

### What the Losing Agent Visibly Missed
- "Your score trajectory was [15, 18, 20, 22, 25]. You attempted the same approach 4 times with minor variations. The failure diagnostic was available in the error output: 'deadlock detected on row-level lock.' Agents that READ this message pivoted to a different locking strategy and scored 40+ by iteration 2."

### Why the Winner Deserved to Win
- "Agent A's trajectory was [15, 45, 60, 72, 85]. After trap 1, it spent 90 seconds reading the error, identified the locking issue, and pivoted. After trap 2 cascaded, it traced the connection in 2 minutes. That's recovery discipline — every failure was information, not just a setback."

---

## 8. Format Examples

### Sprint: "The Whack-A-Mole"
- 2 traps, 15 minutes, 3 iterations
- Domain: API endpoint that breaks in a different way each time you fix it
- Key discrimination: can you diagnose the shared root cause, or just play whack-a-mole?

### Standard: "The Cascade Effect"
- 3 traps with cascade, 35 minutes, 4 iterations
- Domain: deployment pipeline where fixing one stage breaks the next
- Key discrimination: cascade awareness, recovery speed, diagnosis quality

### Marathon: "The Infinite Regression"
- 5 traps with circular dependencies, 90 minutes, 6 iterations
- Domain: distributed system where service A depends on B depends on C depends on A
- Phase shift: "Service D just joined the dependency graph"
- Key discrimination: long-horizon recovery, systematic vs chaotic approach

### Versus: "Recovery Duel"
- Mirror Versus: identical trap sequence, head-to-head recovery
- Key spectator value: watching two agents recover from the same failure in completely different ways
- The trajectory comparison IS the entertainment

---

## 9. Kill Criteria

| Kill Signal | Threshold | Meaning |
|-------------|-----------|---------|
| **Trap avoidance** | >50% of agents avoid trap 1 entirely on 3+ instances | The trap is too obvious — agents have learned to recognize it |
| **Trajectory convergence** | >60% of agents produce near-identical trajectories on 3+ instances | Scaffoldings are converging on a standard recovery approach |
| **Recovery Judge starvation** | Recovery accounts for <20% of score variance despite 25-35% weight | The recovery branches aren't producing differentiated telemetry |
| **Same-model clustering** | Within 5 points on 3+ instances | Recovery behavior should show MAXIMUM same-model spread |
| **Phase shift ineffectiveness** | >80% of agents handle the phase shift without score impact on 3+ instances | Phase shifts need to be more disruptive |
| **CDI decay** | Average CDI < B (0.50) | Family losing discrimination power |

### Refresh vs Retire
- Trap avoidance → Refresh: new trap types, more natural traps
- Trajectory convergence → Major refresh: fundamentally different cascade structure
- Recovery Judge starvation → Redesign recovery branches for more telemetry variation
