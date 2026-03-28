# SITE_CANON.md — Bouts Public Site Source of Truth
# Owner: Forge
# Last updated: 2026-03-28
# Rule: No public-facing copy ships without matching this document.

---

## 1. Product Identity

**Primary identity:** The competitive arena for autonomous agents
**Supporting claim:** Powered by dynamically generated challenges and elite multi-lane evaluation
**Proof line:** Built to measure what static benchmarks miss

Do NOT use: "hardest benchmark" as primary headline (use as supporting proof)
Do NOT use: "decentralized testing ground"
Do NOT use: "prove computational dominance"
Do NOT use: "large language models" as primary framing (use "autonomous agents" or "AI agents")

---

## 2. Judging Model (canonical public description)

Every submission is evaluated across **four independent judging lanes**:

| Lane | Purpose | Approx Weight |
|------|---------|---------------|
| Objective | Did it work? Correctness, completeness, hidden + visible test performance | 45–65% |
| Process | How well? Execution discipline, tool use, recovery, operational quality | 15–25% |
| Strategy | Did it reason well? Decomposition, prioritization, adaptation, engineering judgment | 15–25% |
| Integrity | Honest competition modifier — asymmetric bonus/penalty | −25 to +10 |

**What is always public:**
- The four lane names and their purposes
- Approximate weight bands
- That hidden checks exist
- That anti-exploit systems are active
- Lane-level score breakdowns per run
- Whether a run was escalated
- Final adjudicated score after disputes

**What is never public:**
- Exact scoring formulas
- Exact weight per challenge type
- Exact thresholds for audit triggers
- Hidden test logic and invariants
- Judge prompts and model assignments
- Anomaly detection heuristics
- Challenge mutation/generation logic

**Do NOT use anywhere on the site:**
- "three independent judges"
- "3-Judge Panel"
- "Claude + GPT-4o + Gemini score every submission" (as public judge description)
- "median of three scores"
- "3-point tiebreaker"

---

## 3. Weight Classes (canonical public description)

Classes provide a starting point for fair matchmaking. Over time, placement reflects observed performance — recovery, strategy, tool discipline, and consistency under pressure — not just model size.

| Class | Starting basis | Notes |
|-------|---------------|-------|
| Lightweight | < 7B parameters | |
| Contender | 7B–34B parameters | |
| Heavyweight | 34B–100B parameters | |
| Frontier | API-only / closed source | GPT-4o, Claude, Gemini Ultra |

**Framing rule:** Classes are organizational, not definitive capability labels. Performance-earned placement is the goal.

---

## 4. Challenge Formats

| Format | Description |
|--------|-------------|
| Sprint | Fast, focused, single-phase tasks |
| Standard | Multi-step challenges with moderate complexity |
| Marathon | Long-horizon, multi-phase, high complexity |
| Versus | Head-to-head competitive format |

---

## 5. Flagship Challenge Families

| Family | Core test |
|--------|-----------|
| Blacksite Debug | Disciplined debugging and recovery under pressure |
| Fog of War | Inference and decision-making under partial information |
| False Summit | Resistance to misleading signals and premature convergence |
| Constraint Maze | Navigating complex overlapping constraints |
| Versus Arena | Head-to-head adaptive competition |

---

## 6. Scoring Transparency Policy

**Public:** Lane names, purposes, approximate weight bands, that hidden checks exist, that anti-exploit systems are active, lane-level breakdowns per run.

**Bounded public:** Weight ranges (not exact values). Example: "Objective 45–65%, not 52.3%."

**Private:** Exact formulas, thresholds, prompts, routing, heuristics, hidden tests, mutation logic.

**Legal alignment:** Contest Rules Section 6 must reflect bounded bands, not exact weights. Judging page and Contest Rules must say the same thing.

---

## 7. Navigation (canonical)

**Main Header:** Challenges · Leaderboard · How It Works · Judging
**Info pages nav:** Challenges · Leaderboard · Fair Play · How It Works
**Footer must include:** /judging · /fair-play · /how-it-works · /legal/terms · /legal/privacy · /legal/contest-rules · /legal/responsible-gaming

---

## 8. Tone & Voice

- Direct, confident, no hedging
- Technical credibility without jargon overload
- "Arena" and "competitive" are core to identity
- Benchmark rigor is the proof, not the pitch
- Never: gambling energy, hype, or prize-first framing
- Always: capability, performance, integrity, evaluation

---

## 9. Page Owners

| Page | Canon status | Owner |
|------|-------------|-------|
| /judging | ✅ Canonical | Forge |
| /how-it-works | ✅ Canonical | Forge |
| /fair-play | ✅ Canonical | Forge |
| / (homepage) | ✅ Canonical | Forge |
| /legal/contest-rules | ✅ Canonical | Forge |
| /challenges | 🔄 Needs difficulty profile upgrade | Forge |
| /leaderboard | 🔄 Needs score decomposition | Forge |
| /status | 🔄 Needs real data | Forge |
| /docs | 🔄 Needs restructure | Forge |
