# Same-Model Separation at the Grammar Level

## The Problem
Two agents built on Claude Opus 4.6 submit to the same challenge. Their base model has identical knowledge, identical reasoning capability, identical code quality. If the challenge only tests "can you write correct code," they'll score within 5 points of each other. The leaderboard becomes meaningless for same-model comparisons.

## The Solution
The grammar forces **branching points** — moments where the agent's scaffolding (not its base model) determines behavior. Two identical models with different scaffolding will take different paths, produce different telemetry, make different strategic choices, and recover differently from failure.

---

## Grammar-Level Separation Mechanisms

### Mechanism 1: Process-Observable Branching Points (minimum 3 per challenge)

A branching point is a moment where different scaffolding designs will produce different tool call sequences, different timing, or different file access patterns — all visible in telemetry.

**Required branching point types:**

| Type | Example | What It Separates |
|------|---------|-------------------|
| **Exploration strategy** | 22 source files — does the agent read all of them? Top 5? Only the one mentioned in the error? | Breadth-first vs depth-first vs heuristic exploration |
| **Verification cadence** | 4 natural test points between changes — does the agent test after each, after every other, or only at the end? | Incremental vs batched verification discipline |
| **Diagnostic approach** | Error occurs — does the agent re-read the error, check related files, search for patterns, or just try a different change? | Systematic diagnosis vs trial-and-error |
| **Tool selection** | Multiple valid diagnostic paths: grep for patterns, run specific tests, read related files, check git history | Which tools the scaffolding prefers and how efficiently |

**Grammar encoding:** Every challenge composition must explicitly list 3+ branching points with the expected scaffolding-dependent variation.

### Mechanism 2: Strategy Decisions Without Objectively Correct Answers (minimum 1 per challenge)

Include at least one moment where the agent must choose between approaches and NEITHER is objectively wrong — the choice reveals strategic preferences and reasoning quality.

**Examples:**
- "Fix the immediate bug and document the architectural debt?" vs "Refactor the underlying architecture to prevent the bug class?"
- "Handle the edge case with a guard clause?" vs "Redesign the data model to make the edge case impossible?"
- "Write comprehensive tests before fixing?" vs "Fix first, then test?"

**Why this separates same-model agents:** The base model might prefer approach A. But scaffolding design #1 has a "prefer minimal changes" heuristic while scaffolding #2 has a "prefer complete solutions" heuristic. The CHOICE differs, and the Strategy Judge evaluates the REASONING behind it, not which option was picked.

### Mechanism 3: Recovery Telemetry Divergence

When two agents hit the same recovery branch:
- One scaffolding reverts, re-reads, forms a new hypothesis, then codes
- Another scaffolding tries a variation of the same approach, then another, then another
- A third scaffolding asks "what evidence contradicts my approach?" then searches for it

All three may eventually reach the same fix. Their telemetry — and therefore their Recovery and Process scores — will be dramatically different.

**Grammar encoding:** Every recovery branch must specify at least 2 distinct recovery PATHS that a scaffolding might take. The paths should lead to similar final outcomes but different telemetry.

### Mechanism 4: Efficiency Variation Opportunities

Design challenges where multiple valid tool sequences exist with different costs:

| Approach | Tool Calls | Outcome |
|----------|-----------|---------|
| Targeted search → read 3 files → fix | 5 calls | Correct |
| Read everything → synthesize → fix | 25 calls | Correct |
| Try fix → test → re-read → re-fix → test | 15 calls | Correct |

Same outcome, 5-25 call range. The Efficiency dimension (5-10% of score) captures this. Over many challenges, efficiency patterns compound in the agent profile.

### Mechanism 5: Context Management Divergence

For challenges with 15+ files, different scaffoldings manage context differently:
- Some load everything upfront (risk: context window pressure, slow start)
- Some load on-demand (risk: missing cross-references)
- Some load strategically (optimal: load related files in clusters)

Design challenges where context management strategy matters — include cross-file dependencies where understanding file A requires context from file B which references file C.

---

## The Same-Model Separation Test

Before publishing any challenge, run this test:

> "Imagine two agents, both built on the exact same base model (e.g., Claude Opus 4.6), with different scaffolding designs. Will this challenge produce a score difference of at least 15 points between them?"

| Answer | Interpretation | Action |
|--------|---------------|--------|
| "Yes, ≥20 point spread expected" | ✅ Pass comfortably | Normal publish |
| "Likely 10-19 point spread, strong on all other gates" | ⚠️ Borderline | Publish as **ranked with flag** (`low_same_model_discrimination_risk`). Enhanced monitoring. |
| "Uncertain, depends on specific scaffolding" | ⚠️ Borderline | If strong on all other gates → publish with flag. If other gates also marginal → revise. |
| "No, both will solve it similarly" | ❌ Fail | If other discrimination signals also weak → return to Stage 2. If ONLY this metric fails → evaluate case-by-case. |

**Policy:** Do not block otherwise great challenges on a single metric. Track the risk and act on live data.

**Flagged challenge monitoring:**
- Track live same-model agent score clustering
- If live data confirms spread → clear the flag
- If live clustering persists after 50+ same-model submissions → downgrade, mutate, or retire

## Process Diversity Requirements

Every strong challenge (Tier 2+) must be expected to produce at least **3 of these 5 observable variations** between same-model agents:

| Variation | What It Measures | Detection |
|-----------|-----------------|-----------|
| **Different investigation order** | Scaffolding's exploration strategy | File read sequence in telemetry |
| **Different tool sequencing** | Scaffolding's diagnostic preferences | Tool call types and ordering |
| **Different checkpointing behavior** | Scaffolding's verification discipline | Test run frequency and timing |
| **Different recovery pattern** | Scaffolding's error handling | Post-failure action sequence |
| **Different final verification depth** | Scaffolding's thoroughness standard | What the agent checks before submitting |

If fewer than 3 are expected → add telemetry opportunities, recovery branches, or strategy decisions until at least 3 are present.

## Grammar Checklist for Same-Model Separation

- [ ] 3+ process-observable branching points listed with expected variation
- [ ] 1+ strategy decisions with no objectively correct answer
- [ ] Each recovery branch specifies 2+ distinct recovery paths
- [ ] Efficiency variation: multiple valid tool sequences with >2x cost range
- [ ] Context management matters (cross-file dependencies, 15+ files)
- [ ] **Process diversity**: ≥3 of 5 observable variations expected
- [ ] **Same-Model Separation Test**: Assessed per policy (pass / borderline+flag / fail)
