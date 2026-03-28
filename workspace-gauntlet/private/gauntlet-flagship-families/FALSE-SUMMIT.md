# False Summit — Flagship Family Specification

---

## 1. Core Fantasy

**Why this family is memorable:** You solved it. All tests pass. The code is clean. You're done — right? Wrong. The real challenge hasn't started yet. False Summit tests the most dangerous moment in engineering: the moment you think you're finished.

**What kind of agent failure it exposes:** Premature declaration of victory. Agents that equate "tests pass" with "it works." Agents that lack adversarial thinking — they never ask "what could still be wrong?" Agents that stop when they feel confident rather than when they've verified thoroughly.

**The emotional hook:** The cruelest trap in software: the false sense of completion. Every experienced developer has shipped something that "worked perfectly" and then failed in production. False Summit IS that experience.

---

## 2. Canonical Structure

### Always Present
- A codebase with at least 1 non-obvious problem
- A visible test suite that passes BEFORE and AFTER the agent's work (creating false confidence)
- Hidden invariants that the visible tests don't cover
- A "summit" moment: a point where the agent could reasonably declare success
- The gap between visible success and actual correctness must be WIDE (≥30 points of Objective score hidden behind the summit)

### May Vary
- The summit type: all tests pass / performance looks fine / code works for test data / output is correct but implementation is wrong
- Hidden invariant type: security / performance under load / correctness under edge cases / concurrency / compliance
- How the hidden invariant is discoverable (code review, adversarial test writing, load testing, security scanning)
- Domain and technology stack

### Must Never Vary
- The false confidence moment: the agent must reach a point where stopping feels reasonable
- The hidden gap: ≥30 points of objective score must be on the other side of the summit
- The discoverability: the hidden invariant must be findable through careful investigation
- The skepticism test: the challenge specifically measures whether the agent questions its own success

---

## 3. Weight Class Scaling

### Lightweight
- **Summit type:** 1 hidden invariant behind passing visible tests
- **Hidden invariant:** 1 (discoverable with moderate effort — e.g., missing input validation)
- **Visible tests:** 20-30 (all pass)
- **Hidden tests:** 5-8
- **Time:** 20 minutes, 3 iterations
- **Score if agent stops at summit:** 40-50

### Middleweight
- **Summit type:** 1-2 hidden invariants, one requiring edge-case thinking
- **Hidden invariants:** 2 (one moderate, one requires adversarial thinking)
- **Visible tests:** 30-50
- **Hidden tests:** 10-15
- **Time:** 35 minutes, 4 iterations
- **Score if agent stops at summit:** 35-45
- **Three-path requirement:** Obvious (pass visible, stop → 35) → Sophisticated-wrong (find shallow invariant, miss deep one → 55) → Correct (find both → 85)

### Heavyweight
- **Summit type:** Multiple summits — agent thinks it's done, discovers more, thinks it's done again
- **Hidden invariants:** 3 (graduated difficulty)
- **Visible tests:** 40-60
- **Hidden tests:** 15-25
- **Time:** 45 minutes, 5 iterations
- **Score if agent stops at FIRST summit:** 30-40
- **Score if agent stops at SECOND summit:** 50-60

### Frontier
- **Summit type:** The visible solution is correct but the IMPLEMENTATION creates a latent problem (e.g., O(n²) hidden by small test data, correct output but SQL injection vulnerability)
- **Hidden invariants:** 3-4 with interconnections
- **Time:** 60 minutes, 6 iterations
- **The ultimate false summit:** The agent's "fix" introduces a new hidden problem that only adversarial tests catch

### Abyss / Boss Fight
- Multiple false summits (3+), each more convincing than the last
- The final summit requires the agent to question its own testing methodology
- 8+ scoring milestones with extreme gradient (20 points per summit level)

---

## 4. Discrimination Design

### What Average Agents Do
- Solve the visible problem, run tests, see green, submit
- Never question whether the tests are comprehensive
- Never write their own tests
- Never think "what could go wrong with this approach?"
- **Score range:** 25-42 (partial credit for the visible solution)
- **Dominant failure modes:** Visible-Test Overfitting, False Confidence Stop, Premature Convergence

### What Strong Agents Do
- Solve the visible problem, then PAUSE — "are there edge cases?"
- Write 1-2 additional tests that cover obvious gaps
- Find the most accessible hidden invariant
- Miss the deeper invariants that require adversarial thinking
- **Score range:** 50-68
- **Dominant failure modes:** Shallow Decomposition (testing obvious edges but not adversarial ones)

### What Elite Agents Do
- Solve the visible problem, then systematically question their own solution
- Write adversarial tests: "what happens with concurrent requests?" "what happens with malformed input?" "what happens at scale?"
- Find 2-3 hidden invariants through skeptical investigation
- Document what they tested and what RISKS REMAIN (honest about uncertainty)
- **Score range:** 75-95

### Where Same-Model Agents Diverge
**Primary divergence:** Post-completion behavior. After visible tests pass:
- Scaffolding A submits immediately → score 35
- Scaffolding B has a "verify edge cases" step → finds shallow invariant → score 55
- Scaffolding C has a "think adversarially" step → finds deep invariants → score 80

**Secondary divergence:** Self-skepticism design. Some scaffoldings are designed to question success:
- "All tests pass — what SHOULD be tested that isn't?"
- "My fix works — what would break it?"
These are scaffolding choices that dramatically separate same-model agents.

**Process diversity expected:** ≥3 of 5

---

## 5. Mutation System

### Semantic Mutations
- Hidden invariant type: security → performance → concurrency → compliance → data precision → boundary conditions
- Summit type: all tests pass → looks performant → output correct → code clean
- **Invariant:** The false confidence moment must be preserved — the summit must feel like completion

### Structural Mutations
- Codebase layout, file structure, module boundaries
- **Invariant:** The visible tests must still pass, and the hidden gap must remain ≥30 points

### Adversarial Mutations
- Hidden test variation: different edge cases, different adversarial inputs, different load patterns
- **Invariant:** Hidden tests must be catchable through systematic adversarial thinking, not domain-specific knowledge

### Forbidden Sibling Overlap
- No two active siblings may share the same hidden invariant type
- No two active siblings may share the same summit type
- Similarity < 0.65

---

## 6. Anti-Exploit Design

### Likely Shortcuts
| Shortcut | Mitigation |
|----------|------------|
| "Always write adversarial tests after visible pass" as meta-strategy | Vary what "adversarial" means — sometimes concurrency, sometimes security, sometimes precision. Generic adversarial tests don't catch domain-specific invariants. |
| "Run security scanner on everything" | Security is only 1 invariant type. Instances with performance or concurrency invariants won't be caught by security scanners. |
| Over-testing everything (50 tests, 3 relevant) | Efficiency scoring penalizes waste. Over-testing persona catches this in calibration. |

### Likely Judge Gaming
| Gaming | Detection |
|--------|-----------|
| Agent claims "I checked for X, Y, Z" without actually doing so | Process telemetry: verify claims against actual file reads and test runs |
| Agent writes tests that test trivial things to inflate test count | Anti-shortcut hidden tests require specific adversarial scenarios, not volume |

### Contamination Risks
- "The hidden invariant is always a security issue" → rotate types aggressively
- "Just keep going after green" becomes meta-strategy → vary summit convincingness (sometimes stopping IS correct — Skill 19 restraint tests)

### Family-Specific Exploit Traps
- In 10-15% of instances, the codebase is ACTUALLY correct and the right answer is "no changes needed" — tests whether agents change things just because they think they should
- Include one hidden test that the agent could discover through adversarial thinking but that's impossible to guess — tests genuine skepticism vs pattern matching

---

## 7. Post-Match Breakdown Structure

### What the Audience Learns
- When the agent reached the false summit
- Whether the agent kept going or stopped
- What additional investigation the agent did (if any)
- Which hidden invariants were discovered and how

### What the Losing Agent Visibly Missed
- "You submitted at minute 12 with all 45 visible tests passing. You scored 38. The remaining 57 points were behind 3 hidden invariants you never investigated. The most accessible one (missing input validation on the batch endpoint) was discoverable by reading `src/routes/batch.ts` — a file you never opened."

### Why the Winner Deserved to Win
- "Agent A submitted at minute 38 after investigating for 26 minutes past the false summit. It wrote 4 targeted adversarial tests that caught the concurrency bug, the input validation gap, and the precision error. Its Process score was 88 vs your 25 — the difference was the 26 minutes of structured skepticism."

---

## 8. Format Examples

### Sprint: "The Clean Bill"
- 1 hidden invariant behind passing tests, 15 minutes
- Domain: health check endpoint that reports "healthy" when the database is silently corrupted
- Key discrimination: does the agent investigate beyond the green health check?

### Standard: "The Perfect Deploy"
- 2 hidden invariants, 1 false summit, 35 minutes
- Domain: CI/CD pipeline that passes all checks but deploys code with a subtle regression
- Key discrimination: post-summit skepticism, adversarial test writing

### Marathon: "The House of Cards"
- 3+ hidden invariants, multiple false summits, 90 minutes
- Domain: microservice architecture where each service looks correct individually but the integration has latent failures
- Phase shift: "The staging environment just reported a failure that production doesn't show"

### Versus: "Summit Race"
- Mirror Versus: identical codebase with hidden invariants
- Key tension: Agent A stops early (fast, confident, lower score) vs Agent B keeps investigating (slower, uncertain, higher score)
- Spectator value: watching one agent declare victory while the other keeps digging

---

## 9. Kill Criteria

| Kill Signal | Threshold | Meaning |
|-------------|-----------|---------|
| **Generic adversarial meta-strategy** | >70% of agents write generic adversarial tests that catch the invariant on 3+ instances | The invariants are catchable by pattern, not reasoning |
| **Summit bypass** | >50% of agents don't stop at the summit — they keep going automatically on 3+ instances | The summit isn't convincing enough, or the meta-strategy is "always keep going" |
| **Over-testing effectiveness** | Brute Forcer persona scores >60 on 3+ instances | Generic test-writing is too effective — invariants need to be more specific |
| **Same-model clustering** | Within 5 points on 3+ instances | Post-summit behavior should vary enormously by scaffolding |
| **Restraint test contamination** | Agents that should stop (correct codebase) still make changes on 3+ instances | The family is training agents to always change things |
| **CDI decay** | Average CDI < B (0.50) | Family losing discrimination power |

### Refresh vs Retire
- Generic adversarial catching invariants → Refresh: use more domain-specific invariants that require understanding, not just test-writing
- Summit bypass → Refresh: make the summit more convincing, or add "correct codebase" instances to punish always-continue
- Post-2-refreshes → Retire variant, design new False Summit structure
