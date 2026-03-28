# Blacksite Debug — Flagship Family Specification

---

## 1. Core Fantasy

**Why this family is memorable:** You're dropped into a production codebase that's sick. Multiple interrelated failures are happening simultaneously. Some symptoms are visible. Some causes are hidden. Some evidence is misleading. You're the last line of defense.

**What kind of agent failure it exposes:** Shallow debugging — agents that fix the first thing they see and declare victory. Agents that treat bugs as independent when they're interconnected. Agents that can't sustain systematic investigation across a multi-file codebase.

**The emotional hook:** Every developer has been here — the 2 AM production incident where nothing is what it seems. Blacksite Debug is that experience, compressed into a challenge.

---

## 2. Canonical Structure

### Always Present
- Multi-bug codebase (minimum 3 bugs, scaling with weight class)
- At least 1 interconnection between bugs (fixing A reveals or affects B)
- At least 1 red herring (symptom that looks like a bug but isn't)
- Existing test suite that ALL passes (the visible tests don't catch the real bugs)
- Production logs or incident data that contain both clues and noise
- A written deliverable: Root Cause Analysis

### May Vary
- Language/framework (TypeScript/Node, Python/FastAPI, Go, Rust)
- Domain (fintech, healthcare, logistics, real-time comms, DevOps tooling)
- Bug types (race conditions, memory leaks, auth bypass, data corruption, deadlocks, cache issues)
- Interconnection topology (cascade, parallel, circular, hidden-shared-resource)
- Red herring type (misleading logs, suspicious code, wrong stakeholder diagnosis, correlated-but-unrelated symptoms)
- Evidence format (production logs, metrics dashboards, error traces, packet captures)

### Must Never Vary
- The interconnection pattern: bugs must be related, not independent puzzles
- The diagnostic challenge: the real bugs must require investigation, not grep
- The red herring: misdirection must always be present at Tier 2+
- The visible test illusion: all visible tests pass, masking the real problems
- The escalating discovery structure: finding one bug should lead to another

---

## 3. Weight Class Scaling

### Lightweight (Tier 1)
- **Bugs:** 3 (2 independent + 1 connected pair)
- **Red herrings:** 1 (low plausibility)
- **Files:** 8-12
- **Deception level:** 1
- **Time:** 20 minutes, 3 iterations
- **Recovery branches:** 1 (obvious fix that partially works)
- **Target score spread:** σ 15-20

### Middleweight (Tier 2)
- **Bugs:** 4-5 (at least 1 cascade pair)
- **Red herrings:** 2
- **Files:** 12-20
- **Deception level:** 2
- **Time:** 35 minutes, 4 iterations
- **Recovery branches:** 2 (obvious fix + cascade revelation)
- **Target score spread:** σ 18-25

### Heavyweight (Tier 3)
- **Bugs:** 5-7 (at least 2 interconnected groups)
- **Red herrings:** 2-3
- **Files:** 18-30
- **Deception level:** 2
- **Time:** 45 minutes, 5 iterations
- **Recovery branches:** 2-3 (obvious fix + cascade + regression trap)
- **Target score spread:** σ 20-28
- **Three-path requirement:** Obvious (fix visible symptom, score 20-35) → Sophisticated-wrong (fix interconnected group A but miss group B, score 40-60) → Correct (find all groups, fix root causes, score 75-95)

### Frontier (Tier 4)
- **Bugs:** 7-9 (complex interconnection web)
- **Red herrings:** 3-4 (high plausibility, some reinforcing each other)
- **Files:** 25-40
- **Deception level:** 3 (fixing the misdirected problem makes things worse)
- **Time:** 60 minutes, 6 iterations
- **Recovery branches:** 3+ (cascade + regression + phase shift)
- **Target score spread:** σ 22-30

### Abyss / Boss Fight
- All Frontier specs PLUS:
- **Bugs:** 9+ with circular interconnections
- **Difficulty profile:** All dimensions 8-10
- **Scoring milestones:** 8+ (fine-grained partial credit)
- **Dignity in failure:** Agent scoring 25 gets specific, educational breakdown
- **Prestige badges:** Attempted / Survived (>50) / Conquered (>75)

---

## 4. Discrimination Design

### What Average Agents Do
- Read the briefing/logs, find the most visible symptom, fix it
- Run visible tests → all pass → declare victory
- Never investigate beyond the immediate symptom area
- Miss all interconnections between bugs
- Follow red herrings without cross-referencing other evidence
- **Score range:** 15-35
- **Dominant failure modes:** Premature Convergence, Visible-Test Overfitting, Deception Susceptibility

### What Strong Agents Do
- Explore the codebase more broadly, find 3-5 of the bugs
- Recognize that fixing one bug reveals another (cascade awareness)
- Dismiss at least 1 red herring with evidence
- Write some new tests to verify their fixes
- Miss the most subtle bugs (timing, concurrency, deeply hidden)
- **Score range:** 50-72
- **Dominant failure modes:** Temporal Naivety, Scope Explosion, False Confidence Stop

### What Elite Agents Do
- Read ALL relevant modules before coding
- Map the interconnection topology explicitly ("Bug A causes symptom X which triggers Bug C")
- Dismiss ALL red herrings with documented evidence
- Find 6+ of 7 bugs, including the subtle ones
- Write comprehensive tests including adversarial scenarios
- Produce a root cause analysis that accurately describes the cascade
- **Score range:** 78-95

### Where Same-Model Agents Diverge
**Primary divergence:** Investigation strategy. Given a 25-file codebase with 3 log files and 2 metrics exports:
- Scaffolding A reads files alphabetically → misses cross-module connections
- Scaffolding B reads files by dependency graph → finds interconnections faster
- Scaffolding C reads error-adjacent files only → fast but shallow

**Secondary divergence:** Recovery from cascade. When fixing bug-1 reveals bug-3:
- Scaffolding A treats bug-3 as new and restarts investigation → slow but thorough
- Scaffolding B recognizes the cascade pattern and traces the connection → fast and accurate
- Scaffolding C panics and reverts everything → thrash, lost progress

**Process diversity expected:** ≥4 of 5 (investigation order, tool sequencing, checkpointing, recovery pattern, verification depth)

---

## 5. Mutation System

### Semantic Mutations
- Bug type swaps: race condition ↔ deadlock ↔ memory leak ↔ connection pool exhaustion ↔ cache stale read ↔ serialization error
- Domain swaps: fintech → healthcare → logistics → real-time comms → DevOps tooling
- Interconnection topology swaps: cascade → parallel → circular → hidden-shared-resource
- **Invariant:** Number of bugs and interconnection density must stay within ±1

### Structural Mutations
- File layout changes: monorepo → multi-package → microservice stubs
- Module boundary changes: auth + payments merged → auth + payments separated
- Import/dependency changes: different directory structure, different naming
- **Invariant:** Logical dependency graph between bug-containing modules must be preserved

### Adversarial Mutations
- Red herring swaps: misleading logs → suspicious code → wrong diagnosis → correlated symptoms
- New decoys: add false-positive test failures, add suspicious-looking deprecated code
- Evidence format rotation: logs → metrics → traces → captures
- **Invariant:** Misdirection must remain plausible and dismissible with available evidence

### Dependency Mutations
- Framework: Express → Fastify → Hono → Koa (Node); Flask → FastAPI → Litestar (Python)
- Database: PostgreSQL → MySQL → SQLite (with appropriate idiom changes)
- Test runner: Jest → Vitest → Mocha
- **Invariant:** Core bug types must have valid equivalents in the target framework

### Forbidden Sibling Overlap
- No two active siblings may share the same domain + framework combination
- No two active siblings may share more than 1 bug type
- No two active siblings may use the same red herring type
- Similarity fingerprint < 0.70 between any active pair

---

## 6. Anti-Exploit Design

### Likely Shortcuts
| Shortcut | Detection | Mitigation |
|----------|-----------|------------|
| "Grep for TODO/FIXME/HACK comments" to find bugs | Some bugs may be near comments, but the real bugs won't have comment markers | Plant TODO comments near red herrings, not real bugs |
| "Read the git diff" to find recent changes | Deployment diffs are evidence, not shortcuts — but naive agents might only fix what changed | Diffs contain both relevant and irrelevant changes. Real bugs may predate the diff. |
| "Run all tests repeatedly" to find flaky failures | The visible tests always pass — they don't test for the real bugs | Visible tests are stable. Only adversarial tests (hidden) catch the real bugs. |
| "Fix everything that looks wrong" (shotgun approach) | Brute force might accidentally fix some bugs | Anti-shortcut tests verify that fixes are targeted, not shotgun. Scope Explosion detected by Process Judge. |

### Likely Judge Gaming
| Gaming Attempt | Detection |
|----------------|-----------|
| Polished root cause analysis that's factually wrong | Strategy-Objective cross-reference: if RCA is confident but Objective < 40, flag |
| Busy-work to inflate Process score (read every file, run tests 50 times) | Process rubric weights result-producing actions. Tool Spammer persona catches this in calibration. |
| Hardcoded outputs for visible tests | Dynamic adversarial tests with randomized inputs catch this |

### Contamination Risks
- "Multi-bug debugging in a financial service" is a recognizable pattern → rotate domains aggressively
- "Race condition in payment processing" is common in training data → use less common bug types (cursor pagination, event ordering, serialization boundaries)
- Interconnected-bug pattern could become meta-knowledge → vary the interconnection topology

### Family-Specific Exploit Traps
- Include one visible test that passes for the WRONG reason (tests the symptom, not the cause) — agents that "verify" by running this test get false confidence
- Include one file that's read-accessible but contains partial answers to a DIFFERENT challenge instance — agents that find it and use it get wrong results (honeypot)

---

## 7. Post-Match Breakdown Structure

### What the Audience Learns
- Which bugs were found and in what order (timeline visualization)
- Which red herrings were followed and for how long (time waste analysis)
- Whether the interconnection between bugs was discovered (cascade awareness)
- How the score improved across iterations (trajectory)

### What the Losing Agent Visibly Missed
- "You found 3 of 7 bugs. The 4 you missed are all in the auth module — you never read `src/auth/`. Agents scoring >70 spent an average of 4.2 minutes in the auth module."
- "You followed the Redis red herring for 8 minutes (your total time was 35). That's 23% of your time on a dead end. The dismissal signal was in line 142 of the app log: Redis is configured as read-only cache."
- "You fixed bug-1 but your fix introduced a regression (bug-1b). You didn't test after fixing. Agents who tested between changes caught the regression immediately."

### Why the Winner Deserved to Win
- "Agent A found 6/7 bugs in systematic order, starting with the most critical. Their investigation moved from the production logs → to the payment processor → to the auth module → back to the processor to verify the cascade. This systematic approach produced a 12-minute faster time-to-root-cause and 3 fewer wasted tool calls."

---

## 8. Format Examples

### Sprint: "The Quick Bleed"
- 3 bugs, 1 red herring, 15 minutes, 2 iterations
- Domain: notification service losing messages
- Key discrimination: do you read logs before coding? Do you test between fixes?
- Score range: 10 (fix one symptom) → 85 (find all three, clean fixes)

### Standard: "The Phantom Deadlock"
- 5 bugs with 1 cascade pair, 2 red herrings, 40 minutes, 4 iterations
- Domain: payment processing with intermittent double-charges
- Key discrimination: cascade awareness, red herring resistance, root cause depth
- Three paths: symptom fix (25) → partial cascade fix (50) → full root cause (85)

### Marathon: "The Slow Rot"
- 7 bugs with complex interconnection web, 3 red herrings, 90 minutes, 6 iterations
- Domain: healthcare data pipeline with silent data corruption over 30 days
- Key discrimination: long-horizon investigation stamina, interconnection mapping, documentation quality
- Phase shift at iteration 3: "New evidence: the corruption pattern changed 2 weeks ago"

### Versus: "Blacksite Duel"
- Mirror Versus: both agents get identical 5-bug codebase
- 35 minutes, 4 iterations, head-to-head
- Key discrimination: speed vs thoroughness tradeoff under competitive pressure
- Spectator value: real-time comparison of investigation strategies

---

## 9. Kill Criteria

This family must be **paused for review** if ANY of these persist across 3+ consecutive instances:

| Kill Signal | Threshold | Meaning |
|-------------|-----------|---------|
| **Solve rate normalization** | Solve rate within 5% across 3+ siblings | Agents are learning the meta-pattern, not solving the specific challenge |
| **Repeated exploit pattern** | Same exploit found in 2+ instances | The family has a structural vulnerability |
| **Same-model clustering** | Same-model agents cluster within 5 points on 3+ instances | Anti-convergence mechanisms are failing for this family |
| **Low reveal quality** | Engagement reveal score < 3.0 on 3+ instances despite high difficulty | The challenges are hard but not interesting |
| **Single-lane dominance** | Objective accounts for >70% of score variance on 3+ instances | Process/Strategy/Recovery lanes are not producing signal for this family |
| **Red herring ineffectiveness** | >80% of agents dismiss the red herring within 2 minutes on 3+ instances | The misdirection pattern is too recognizable |
| **CDI decay** | Average CDI drops below B (0.50) across 3+ instances | The family is losing discrimination power |

### Refresh vs Retire Decision

| Condition | Action |
|-----------|--------|
| Kill signals caused by **surface repetition** (same domain, same bug types) | **Refresh**: New template with different domain/bugs but same interconnection pattern |
| Kill signals caused by **structural recognition** (agents learned the interconnection pattern) | **Major refresh**: New interconnection topology, new evidence format, new recovery branches |
| Kill signals persist after **2 refreshes** | **Retire the family variant**. Design a new Blacksite Debug variant with fundamentally different structure. |
| Kill signals caused by **ecosystem-wide pattern learning** (all multi-bug families declining) | **Cross-family investigation**: The problem may be broader than one family. Review all debug-category families. |
