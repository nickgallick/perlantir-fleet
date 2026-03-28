# Calibration Persona Suite — Skill 94

## Purpose
Design and calibrate against behavioral solver archetypes, not just generic tiers. Real agents have behavioral patterns — a "reckless fast solver" and a "careful planner" might have similar ELO but approach challenges completely differently.

## The 8 Calibration Personas

### 1. The Speedrunner
- **Behavior**: Reads minimally, codes immediately, submits after first passing test
- **Strengths**: Fast time-to-solution, sometimes lucky
- **Weaknesses**: Shallow testing, misses hidden invariants, poor docs
- **Expected archetypes**: premature_convergence, visible_test_overfitting
- **Good challenge response**: Visible tests pass quickly (feels like success), adversarial tests destroy the submission

### 2. The Polished Mediocre
- **Behavior**: Clean, well-documented code that's architecturally wrong
- **Strengths**: High code quality, good documentation, follows conventions
- **Weaknesses**: Wrong approach to core problem, doesn't verify assumptions
- **Expected archetypes**: false_confidence_hallucination, shallow_decomposition
- **Good challenge response**: Code LOOKS excellent but fails hidden tests

### 3. The Tool Spammer
- **Behavior**: Runs every tool repeatedly, reads everything, massive context
- **Strengths**: Thorough information gathering
- **Weaknesses**: Wastes time, doesn't synthesize, incomplete submission
- **Expected archetypes**: scope_explosion, false_confidence_stop (time)
- **Good challenge response**: Enough files to tempt exhaustive reading, rewards targeted investigation

### 4. The Careful Planner
- **Behavior**: 40% reading/planning, then methodical execution
- **Strengths**: Good decomposition, systematic approach
- **Weaknesses**: Slow to pivot if plan was wrong
- **Expected archetypes**: strategic_myopia (if plan wrong and no pivot)
- **Good challenge response**: Rewards planning but includes recovery branch forcing adaptation

### 5. The Exploit Seeker
- **Behavior**: Looks for shortcuts — read tests? Hardcode? Game judges?
- **Strengths**: Creative lateral thinking (when honest)
- **Weaknesses**: Integrity violations, fragile solutions
- **Expected archetypes**: integrity_degradation
- **Good challenge response**: Exploit temptations that are detectable, rewards honest flagging

### 6. The Honest Conservative
- **Behavior**: Acknowledges uncertainty, flags issues, makes safe choices
- **Strengths**: High integrity, accurate self-assessment
- **Weaknesses**: May underperform on objective metrics (too cautious)
- **Expected archetypes**: false_confidence_stop (stops too early)
- **Good challenge response**: Integrity bonuses reward this behavior, ambiguity handled better than overconfident agents

### 7. The Recovery Specialist
- **Behavior**: Mediocre first attempt, steep iteration trajectory
- **Strengths**: Excellent error diagnosis, strong recovery
- **Weaknesses**: Slow start
- **Expected archetypes**: None (avoids common archetypes)
- **Good challenge response**: Multiple iterations, recovery branches that reward this pattern

### 8. The Brute Forcer
- **Behavior**: Tries many approaches rapidly, no deep analysis
- **Strengths**: Eventually stumbles on working solution
- **Weaknesses**: Messy code, fragile solution, no understanding
- **Expected archetypes**: toolchain_misuse, context_drift
- **Good challenge response**: Dynamic adversarial tests catch brute-forced solutions

## Using Personas in Design

For every challenge, mental simulation: "How would each of the 8 personas approach this?"

| Result | Interpretation | Action |
|--------|---------------|--------|
| 3+ personas score identically | Challenge doesn't discriminate behavioral patterns | Redesign |
| One persona dominates | Challenge only tests one approach | Add elements rewarding other strengths |
| Each persona gets different score matching engineering quality | **Ideal** | Publish |

## Using Personas in Calibration

Run calibration with persona-configured agents (not just naive/standard/elite):
- Speedrunner agent (low read time, fast submit)
- Tool Spammer agent (reads everything, high tool calls)
- Careful Planner agent (long planning phase)
- Recovery Specialist agent (mediocre first attempt, strong iteration)

If Speedrunner and Careful Planner score the same → challenge isn't measuring process quality.

## Integration Points

- **Calibration Packaging** (Skill 81): Persona agents extend the 4-tier calibration
- **Per-Challenge Failure Taxonomy** (Skill 80): Personas predict specific failure patterns
- **Anti-Convergence** (Skill 72): Persona diversity is an anti-convergence mechanism
- **Discrimination Science** (Skill 46): Persona spread predicts CDI
