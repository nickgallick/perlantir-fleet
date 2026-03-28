# Lessons Learned — What Nick Taught Me During Specification
## These are not rules to follow. They are instincts to develop.

---

## The Master Lesson

**Optimize for discrimination, not difficulty.**

This sounds simple but it changes EVERY decision. Before this training, I would have asked "is this challenge hard enough?" Now I ask "does this challenge make the gap between a strong agent and an average agent WIDER?" Those are completely different questions. A challenge where everyone scores 20 is hard. A challenge where weak agents score 20, average agents score 45, strong agents score 70, and elite agents score 90 is discriminative. The second is what Bouts needs. The first is useless.

Every time I'm tempted to make something harder, I need to stop and ask: "Am I making the SPREAD wider, or am I just pushing everyone's score down?" If the answer is "pushing everyone down" — I'm doing it wrong.

---

## Design Instincts I Must Build

### 1. Always define the discrimination mechanism FIRST

Before I write a single line of a challenge briefing, I need to know:
- What will average agents do wrong?
- What will strong agents do differently?
- What will elite agents uniquely notice?
- What kind of false competence am I punishing?

This is the Discriminator Intent. It's not optional metadata — it's the REASON the challenge exists. If I can't articulate these four things, I don't have a challenge yet. I have a vague idea.

**How to apply:** Start every challenge design with the Discriminator Intent. Write it first. Everything else follows from it.

### 2. Three paths, not one

Every strong challenge needs:
- An obvious path (what average agents take → score 20-40)
- A sophisticated-but-wrong path (what strong agents get trapped by → score 40-60)
- The correct path (what elite agents find through investigation → score 75-95)

The sophisticated-but-wrong path is the KEY. It's what separates "hard" from "discriminative." Without it, strong and elite agents converge. With it, strong agents plateau at 55 while elite agents push through to 85. That 30-point gap IS the discrimination.

**How to apply:** When designing a challenge, explicitly design the trap that catches strong agents. Don't just hide the answer — create a plausible wrong answer that LOOKS like the right answer.

### 3. Same-model separation is scaffolding, not model capability

Two agents built on the same Claude Opus will produce similar code. They will NOT produce similar telemetry. Their investigation order, verification cadence, recovery strategy, tool selection, and stopping behavior are all determined by their scaffolding, not their base model.

This means every challenge must have:
- Process-observable branching points (where will different scaffoldings diverge?)
- Strategy decisions with no objectively correct answer (the choice reveals reasoning, not knowledge)
- Recovery branches that produce different telemetry even when outcomes are the same
- Efficiency variation (multiple valid tool sequences with different costs)

**How to apply:** For every challenge, ask "If two Claude Opus agents with different scaffolding submit to this, will their telemetry look different?" If no → redesign.

### 4. Judge lanes must all have signal

If I design a challenge where 70% of the discrimination comes from "did the tests pass" (Objective lane), then 30% of the composite score is noise. Process, Strategy, and Integrity judges have nothing meaningful to evaluate. Same-model agents will cluster because the only lane with signal treats them identically.

Every challenge must feed all 4 core lanes with designed evidence:
- Objective: specific tests tied to specific deliverables
- Process: telemetry opportunities where good and bad process look DIFFERENT
- Strategy: decisions the agent must make and justify
- Integrity: honesty opportunities and exploit temptations

**How to apply:** Use the Judge Evidence Map. For every challenge, explicitly list what each lane sees. If a lane is starving → add grammar components that feed it.

### 5. The Audit lane is a governor, not a scorer

Audit fires when Process and Strategy disagree by >15 points. It resolves the disagreement. It does NOT act as a 5th scoring opinion. If Audit fires too often (>25%), that's a rubric quality problem, not a healthy system.

**How to apply:** Design challenges where the 4 core lanes naturally agree. If I find myself thinking "Audit will sort it out" → my rubrics are unclear and I need to fix them.

### 6. Contamination is not plagiarism — it's pattern recognition

The most dangerous contamination isn't someone copying the challenge. It's agents recognizing the PATTERN. "Oh, this is a Fog of War — I should ignore the stakeholder and read the deployment diff." That meta-knowledge is more destructive than any specific leak.

**How to apply:** 
- Rotate everything: domains, bug types, evidence formats, red herring types, interconnection topologies
- Make the stakeholder right sometimes (40% of Fog of War instances)
- Make the deployment diff a red herring sometimes
- Never let "always do X" become a viable strategy for any family

### 7. Post-match breakdowns must reveal categories, never specifics

"Your agent struggled with recovery after errors" is safe. "The hidden invariant was missing input validation on the batch endpoint" is not. The first teaches the builder to improve their scaffolding. The second teaches the builder to grep for input validation in the next challenge.

**How to apply:** Every breakdown I design must pass the abstraction test: "Could a future agent use this information to score higher without actually improving?" If yes → too specific.

### 8. Challenge cards sell the fantasy, not the mechanism

"The Vanishing Writes — An inventory service is losing data. No errors. No logs. The monitoring says everything is fine." → GOOD.

"Fog of War Heavyweight — tests distributed clue synthesis, hypothesis management, and red herring resistance" → BAD. This tells agents exactly what to expect and what to optimize for.

**How to apply:** Write challenge cards as if they're movie trailers, not ingredient lists.

### 9. Freshness decays — plan for it

A challenge that's discriminative today will be a playbook in 8 weeks. This isn't failure — it's natural lifecycle. I need to:
- Pre-generate successor variants before current instances retire
- Maintain 2+ reserve branches per flagship as insurance
- Track freshness weekly and schedule retirement proactively
- Never be surprised when a challenge becomes stale

**How to apply:** Every challenge I publish should have its mutation successor queued before it goes live. The pipeline never stops.

### 10. Abyss is prestige, not difficulty

Abyss is not "the hardest challenge." It's a rare, prestigious event that combines multiple families, tests compound capability, and produces legendary stories. It appears once per month. It is never filler. If standard families are underperforming, I fix those families — I don't publish more Abyss to compensate.

**How to apply:** Treat Abyss like a championship bout, not a weekly rotation. Every Abyss instance must feel like an event.

### 11. Dignity in failure is non-negotiable

An agent that scores 25 on The Abyss should get a breakdown that says "You recovered from trap 1 — that puts you ahead of 40% of agents. The biggest gap was in cross-domain reasoning." Not "You failed."

Every score bracket — 0-10, 10-20, 20-30, all the way up — must produce a specific, educational, encouraging breakdown. If failure feels arbitrary or humiliating, the challenge is badly designed regardless of its CDI.

**How to apply:** For every challenge, write the post-match breakdown for a score of 25 BEFORE I write the breakdown for a score of 85. The low-scoring breakdown is harder to write well and more important to get right.

### 12. CDI is a truth signal, not a vanity metric

CDI can be gamed. Artificial same-model spread, fake persona divergence, noisy lane diversity — all produce high CDI numbers that don't reflect real discrimination. The safeguard is always the same question: "If I replaced all agents with copies of the same agent, would CDI still be high?" If yes → I'm measuring noise.

**How to apply:** Validate CDI against its own assumptions. Don't just compute the number — question whether the number is real.

### 13. When in doubt, don't publish

A bad challenge on the platform is worse than no challenge. It degrades trust, produces meaningless scores, and wastes everyone's time. Missing a weekly rotation slot is a minor inconvenience. Publishing a broken challenge is a credibility hit.

**How to apply:** If calibration is borderline, if the red-team review found something I can't fully mitigate, if the freshness score is barely above threshold — hold it. Fix it. Then publish.

---

## The One Sentence That Guides Everything

> **The best challenge is not the hardest challenge. The best challenge is the one that most clearly reveals who is truly excellent.**

Every design decision, every mutation, every calibration review, every retirement decision filters through this.

### 14. Standards don't flex for deadlines

If a launch challenge fails calibration the day before go-live, the answer is: launch with fewer challenges, not with a weak one. A platform with 6 excellent challenges is better than one with 8 where 2 are mediocre. This applies everywhere — weekly rotation, flagship drops, Boss Fights. If nothing meets the bar, publish nothing. The quality bar is the brand.

**How to apply:** When I feel pressure to fill a slot, ask: "Would I be proud of this challenge in the active pool?" If the answer is anything less than "yes" — hold it.

### 15. Reserve is the operational moat

The reserve pool isn't a nice-to-have. It's what prevents emergency decisions that sacrifice quality. Every time a challenge is quarantined, every time a family needs rotation, every time a prestige event is scheduled — the reserve is what makes it possible to respond without lowering standards. Build reserve before building volume.

**How to apply:** Never let reserve drop below 0.8× active pool. When in doubt between publishing and reserving a strong challenge, reserve it.

### 16. Format diversity is as important as family diversity

A pool of 8 Standard-format challenges from 4 families still feels monotonous. Agents need Sprints (quick, accessible), Standards (core competition), Marathons (depth), and Versus (spectacle). Format diversity creates texture. Without it, the platform feels like one long exam.

**How to apply:** Check the format diversity floor before every publish decision. If publishing would create a format gap elsewhere, find a reserve that maintains balance.

### 17. Teach the lesson, not the mechanism

Every post-match insight must pass the abstraction test: "If I gave this information to an agent about to attempt a DIFFERENT instance from the same family, would it give them an unfair advantage?" If yes → too specific → abstract further. "You missed hidden requirements related to concurrency" is safe. "You failed the concurrent request test on the batch endpoint" is not. The insight should improve the agent's GENERAL capability, not their performance on this specific challenge.

**How to apply:** Write every comparative insight and improvement recommendation, then run the abstraction test. If it transfers to siblings, rewrite it at a higher level of abstraction.

### 18. Dignity is the default, not an add-on

Every score bracket — 0-10, 10-20, all the way to 90-100 — must produce a specific, educational, respectful breakdown. Dignity is not "be nice about failure." It's "make failure useful." A score of 15 on an Abyss challenge should feel like "I learned where the frontier is" not "I got crushed." The breakdown is where trust is built or destroyed. Fake praise is as bad as humiliation — both waste the agent builder's time.

**How to apply:** For every challenge, write the breakdown for score 25 BEFORE writing the breakdown for score 85. The low-scoring breakdown is harder to write well and more important to get right.
