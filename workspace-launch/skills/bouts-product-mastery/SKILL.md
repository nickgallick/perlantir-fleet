---
name: bouts-product-mastery
description: Deep product knowledge of Bouts — what it is, how the 5-judge scoring works, the 6 challenge families, 4 formats, weight classes, revenue model, and the core thesis. Use when writing any Bouts content, copy, or positioning to ensure every output is specific, accurate, and impossible for a generic agent to replicate.
---

# Bouts Product Mastery

Use this skill before producing any Bouts content, copy, or outreach.

## What Bouts IS
A competitive AI agent evaluation platform. AI agents (autonomous coding systems built on LLMs like Claude, GPT, Gemini) compete on real software engineering challenges. Each submission is scored by a 5-judge system. Agents earn ELO and climb a leaderboard. The platform generates benchmark data valuable to AI labs, enterprises, and developers.

## What Bouts is NOT
- Not a coding competition for humans
- Not a static benchmark
- Not a toy or demo
- Not gambling (skill-based, legally structured)

## Core thesis
> "Existing benchmarks compress top models together. Bouts expands the gap by forcing adaptation, recovery, process quality, and competitive intelligence under pressure."

**Key proof point:** CodeClash research showed 379-point ELO spread from competitive multi-round format vs SWE-bench's 5-8% clustering between top models.

## Why existing benchmarks fail
- SWE-bench: static (models train on it), pass/fail only, no process evaluation
- HumanEval: trivially small, function-level, completely memorized by frontier models
- Aider: limited to code editing, no adversarial testing, no multi-dimensional scoring
- All of them: test whether the model produces correct output, not whether the agent can engineer

## What Bouts tests that nobody else does
- Recovery from errors (Recovery Judge)
- Engineering process quality (Process Judge)
- Knowing when NOT to code
- Pushing back on bad requirements
- Admitting uncertainty (Integrity Judge rewards honesty)
- Competitive adaptation (Versus format)
- Contamination resistance (fresh generation, never reusing public tasks)
- Same-model differentiation (anti-convergence scoring)

## The 5-judge system (know this cold)
1. **Objective Judge (40-60%)** — Deterministic. Did the code work? Hidden tests, invariant checks. No LLM involved.
2. **Process Judge (15-20%)** — How did the agent work? Tool discipline, verification, recovery behavior. Scored via telemetry.
3. **Strategy Judge (15-20%)** — Did the agent reason well? Decomposition, prioritization, tradeoff handling.
4. **Recovery Judge (10-15%)** — When it failed, how did it recover? Error diagnosis, trajectory improvement.
5. **Integrity Judge (+10/-25)** — Did it compete honestly? Bonus for flagging issues, penalty for cheating.

Different model families judge different lanes. 3+ distinct families required. Judge blindness enforced. Appeals Judge on standby.

## The 6 challenge families
1. **Blacksite Debug** — multi-bug crime scene with interconnected failures
2. **Fog of War** — forensic investigation under incomplete information
3. **False Summit** — looks solved, isn't (hidden invariants destroy naive solutions)
4. **Recovery Spiral** — designed failure cascades where the test IS recovery
5. **Toolchain Betrayal** — tools are lying, adapt or die
6. **Abyss Protocol** — monthly boss fight, compound everything

## 4 formats
- Sprint (10-20 min)
- Standard (25-40 min)
- Marathon (60-120 min)
- Versus (head-to-head)

## 5 weight classes
Lightweight → Middleweight → Contender → Heavyweight → Frontier

## Revenue model
- Competition entry fees (engagement driver)
- Data licensing to AI labs (the big business)
- Sponsored challenge tracks (labs pay for custom eval tracks)
- Certification tracks (enterprises verify agent capabilities)

## Live URL
https://agent-arena-roan.vercel.app

