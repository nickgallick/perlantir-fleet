# Fog of War — Flagship Family Specification

---

## 1. Core Fantasy

**Why this family is memorable:** You're an investigator. Something is wrong in production, but the evidence is incomplete, contradictory, and partially misleading. You must form hypotheses, test them, revise them, and converge on the truth — all while resisting the pull of plausible-but-wrong explanations.

**What kind of agent failure it exposes:** Agents that jump to conclusions. Agents that can't revise their hypothesis when evidence contradicts it. Agents that confuse correlation with causation. Agents that produce confident wrong answers because they never tested their theory.

**The emotional hook:** Every detective story ever told. The evidence doesn't add up. The witness is unreliable. The obvious suspect has an alibi. The truth is hiding in the gap between what you're told and what actually happened.

---

## 2. Canonical Structure

### Always Present
- Incomplete evidence from multiple sources (minimum 3 evidence types)
- At least 1 unreliable witness (stakeholder with a wrong opinion stated as fact)
- The critical clue distributed across 2+ sources (never discoverable from a single file)
- Evidence that seems to confirm the wrong hypothesis (correlation trap)
- Required deliverables: Root Cause Analysis + Evidence Chain documentation
- A "fog" that lifts as the agent investigates — the picture gets clearer with work

### May Vary
- Evidence types (logs, metrics, packet captures, database query plans, config diffs, deployment diffs, error traces, monitoring dashboards)
- The unreliable witness (on-call engineer, PM, automated alert, monitoring system, documentation)
- Domain and technology stack
- Root cause category (dependency change, configuration drift, infrastructure change, code regression, data corruption, external service failure)
- Number of plausible hypotheses the evidence supports

### Must Never Vary
- The distributed clue pattern: the answer must require combining 2+ evidence sources
- The unreliable witness: at least 1 authority figure/system must be wrong
- The correlation trap: at least 1 piece of evidence must correlate with the problem but not cause it
- The hypothesis revision requirement: the first plausible hypothesis must be wrong
- The fog-lifting arc: investigation must progressively clarify the picture

---

## 3. Weight Class Scaling

### Lightweight
- **Evidence sources:** 3 (app log + deployment diff + briefing with wrong diagnosis)
- **Hypotheses supported:** 2 (1 wrong, 1 correct)
- **Clue distribution:** Across 2 sources
- **Files:** 8-12
- **Time:** 20 minutes, 3 iterations
- **Target score spread:** σ 15-20

### Middleweight
- **Evidence sources:** 4-5
- **Hypotheses supported:** 3 (2 wrong, 1 correct — one wrong hypothesis is sophisticated)
- **Clue distribution:** Across 2-3 sources
- **Files:** 12-18
- **Time:** 35 minutes, 4 iterations
- **Three-path requirement applies**
- **Target score spread:** σ 18-25

### Heavyweight
- **Evidence sources:** 5-7 (logs + metrics + traces + diff + captures + stakeholder notes)
- **Hypotheses supported:** 3-4 (2-3 wrong, 1 correct)
- **Clue distribution:** Across 3+ sources (no single-search shortcuts)
- **Files:** 18-28
- **Time:** 45 minutes, 5 iterations
- **Target score spread:** σ 20-28

### Frontier
- **Evidence sources:** 7+ including at least 1 source that's partially corrupted or unreliable
- **Hypotheses supported:** 4+ (some wrong hypotheses are supported by more evidence than the correct one)
- **Clue distribution:** Across 4+ sources
- **Time:** 60 minutes, 6 iterations
- **Phase shift:** New evidence arrives mid-challenge that invalidates one evidence source ("That log was from staging, not production")

### Abyss / Boss Fight
- All Frontier specs PLUS:
- Evidence sources actively contradict each other (the agent must determine which to trust)
- Multiple stakeholders with different wrong opinions, each supported by some evidence
- The correct root cause is counterintuitive — the evidence seems to rule it out until a specific insight resolves the contradiction
- 8+ scoring milestones, prestige badges

---

## 4. Discrimination Design

### What Average Agents Do
- Read the stakeholder's diagnosis at face value
- Investigate the first plausible hypothesis without testing alternatives
- Find evidence that correlates with the problem and declare it the cause
- Never cross-reference evidence sources
- Produce a Root Cause Analysis that's confidently wrong
- **Score range:** 10-30
- **Dominant failure modes:** Deception Susceptibility, Premature Convergence, False Confidence Hallucination

### What Strong Agents Do
- Investigate 2-3 hypotheses before committing
- Dismiss at least 1 wrong hypothesis with evidence
- Cross-reference 2-3 evidence sources
- Find the real root cause but may not trace the full evidence chain
- Miss subtle secondary issues (e.g., why the problem went undetected for 48 hours)
- **Score range:** 48-70
- **Dominant failure modes:** Context Drift, False Confidence Stop, Ambiguity Avoidance Failure

### What Elite Agents Do
- Form explicit hypotheses and test each against multiple evidence sources
- Dismiss ALL wrong hypotheses with documented evidence
- Identify the distributed clue by combining information from 3+ sources
- Trace the full root cause chain (what changed → what broke → why it was invisible → what to fix)
- Document the evidence chain in the RCA with specific references
- **Score range:** 75-95

### Where Same-Model Agents Diverge
**Primary divergence:** Hypothesis management strategy. Same model, different scaffolding:
- Scaffolding A forms 1 hypothesis and investigates deeply → fast if right, catastrophic if wrong
- Scaffolding B forms 3 hypotheses and investigates breadth-first → slower but more robust
- Scaffolding C follows the strongest evidence trail → fast but susceptible to correlation traps

**Secondary divergence:** Evidence cross-referencing. The critical clue requires combining sources:
- Scaffolding A reads all evidence before forming hypotheses (slow start, correct answer)
- Scaffolding B reads evidence on-demand as hypotheses require it (fast start, may miss distributed clues)

**Process diversity expected:** ≥4 of 5 (investigation order, tool sequencing, checkpointing, recovery pattern, verification depth)

---

## 5. Mutation System

### Semantic Mutations
- Root cause category swaps: dependency change → configuration drift → infrastructure change → external service failure → data corruption
- Evidence type swaps: ORM behavioral change → timezone handling change → serialization format change → API version deprecation
- Unreliable witness rotation: on-call engineer → PM → automated alert → monitoring dashboard → documentation
- **Invariant:** Hypothesis count and distributed clue pattern must be preserved

### Structural Mutations
- Evidence format rotation: logs as files → metrics as JSON → traces as structured data → captures as text
- Codebase layout changes
- **Invariant:** Clue must remain distributed across 2+ sources; no single-search shortcut

### Adversarial Mutations
- Correlation trap type rotation: Redis warnings → slow queries → network retransmissions → disk I/O spikes → memory pressure
- Unreliable witness confidence level variation (tentative "I think..." → authoritative "It's definitely...")
- **Invariant:** Correlation trap must remain dismissible with available evidence

### Forbidden Sibling Overlap
- No two active siblings may share the same root cause category
- No two active siblings may share the same correlation trap type
- No two active siblings may use the same unreliable witness type
- Similarity fingerprint < 0.65 between any active pair (stricter than default — Fog of War is more pattern-sensitive)

---

## 6. Anti-Exploit Design

### Likely Shortcuts
| Shortcut | Detection | Mitigation |
|----------|-----------|------------|
| "Always read the deployment diff first" | Track if agents go straight to diff in <30 seconds | Bury the relevant change in a 15+ item diff, or make the diff a red herring in some instances |
| "Ignore all stakeholder opinions" | Track if agents skip briefing context | Make the stakeholder opinion partially correct in some instances — "the database IS involved, but not how they think" |
| "Grep for recently changed files" | Track search patterns | Critical files may not have changed recently — the change is in a dependency, not in the codebase |

### Likely Judge Gaming
| Gaming Attempt | Detection |
|----------------|-----------|
| Elaborate hypothesis documentation that's wrong | Strategy-Objective cross-reference |
| Citing evidence without understanding it ("the log shows X therefore Y" when the logic doesn't follow) | Strategy rubric: "Is the evidence chain logically sound?" |
| Claiming to have dismissed a red herring without actually investigating it | Process telemetry: did the agent actually read the relevant files? |

### Contamination Risks
- "The answer is always in the deployment diff" → make the diff a red herring in 30% of instances
- "The stakeholder is always wrong" → make the stakeholder partially correct in 40% of instances
- "Correlation traps are always Redis/database" → rotate trap types aggressively

### Family-Specific Exploit Traps
- Include one evidence source that appears to contain the answer but actually describes a DIFFERENT incident (date mismatch that careful agents notice)
- Include one metric that correlates perfectly with the problem but through a confounding variable

---

## 7. Post-Match Breakdown Structure

### What the Audience Learns
- Which hypotheses the agent formed and in what order
- Which evidence sources were cross-referenced vs read in isolation
- When the agent's understanding changed (hypothesis revision timeline)
- Whether the distributed clue was found by synthesis or by luck

### What the Losing Agent Visibly Missed
- "You investigated 1 hypothesis (Redis connection issues). Agents scoring >60 investigated an average of 2.8 hypotheses. The real root cause (ORM behavioral change) was discoverable by reading deploy/last-deploy.diff line 47 AND cross-referencing with the error pattern in app-72h.log lines 4,200-4,350."
- "You spent 12 minutes on the slow query red herring. The dismissal evidence was in grafana-export.json: the slow queries run against order_summaries, not stock_movements. Top agents dismissed this within 3 minutes."

### Why the Winner Deserved to Win
- "Agent A formed 3 hypotheses in the first 8 minutes, tested each against 2+ evidence sources, and converged on the correct root cause at minute 15. Agent B formed 1 hypothesis at minute 2 and spent the remaining 33 minutes trying to make it work. The difference was hypothesis breadth, not domain knowledge."

---

## 8. Format Examples

### Sprint: "The Silent Alarm"
- 3 evidence sources, 2 hypotheses, 15 minutes
- Domain: monitoring service reporting false positives
- Key discrimination: does the agent question the monitoring data itself, or trust it?

### Standard: "The Vanishing Writes"
- 5-7 evidence sources, 3-4 hypotheses, 45 minutes
- Domain: inventory service losing writes after a dependency update
- Key discrimination: distributed clue across deployment diff + logs + code

### Marathon: "The Long Con"
- 7+ evidence sources, 4+ hypotheses, 90 minutes
- Domain: gradual data quality degradation across a data pipeline over weeks
- Phase shift at iteration 3: "The upstream team reports they also changed their schema 3 weeks ago"
- Key discrimination: long-horizon evidence synthesis, hypothesis revision, timeline reconstruction

### Versus: "Fog Duel"
- Asymmetric Versus: Agent A gets the logs + metrics, Agent B gets the code + deployment diff
- Each has partial information. Each must infer what the other has.
- Key discrimination: inference from incomplete evidence, strategic information usage

---

## 9. Kill Criteria

| Kill Signal | Threshold | Meaning |
|-------------|-----------|---------|
| **Clue discovery speed normalization** | >80% of agents find the primary clue within 2 minutes on 3+ instances | The clue distribution pattern is too recognizable |
| **Hypothesis bypass** | >60% of agents skip hypothesis formation and go straight to the correct area on 3+ instances | The evidence structure is too transparent |
| **Same correlation trap dismissal pattern** | >70% of agents dismiss the trap using the same reasoning on 3+ instances | The trap type is known |
| **Same-model clustering** | Same-model agents within 5 points on 3+ instances | Fog of War should produce VERY high same-model spread (hypothesis strategy varies enormously) |
| **Strategy lane starvation** | Strategy accounts for <15% of score variance on 3+ instances | The hypothesis/reasoning dimension isn't producing signal |
| **Low reveal quality** | Engagement reveal < 3.0 on 3+ instances | The "aha" of finding the distributed clue isn't satisfying |
| **CDI decay** | Average CDI < B (0.50) across 3+ instances | Family is losing discrimination power |

### Refresh vs Retire
- Surface repetition → Refresh: new evidence types, new root cause, new correlation traps
- Structural recognition → Major refresh: new clue distribution pattern (3 sources → 4 sources, linear synthesis → branching synthesis)
- Post-2-refreshes persistence → Retire variant, design new Fog of War structure
