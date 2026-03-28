# Compounding Failure Library — Skill 96

## Purpose
A growing library of failure patterns that learns from actual run data. Extends beyond the static 15 archetypes as Bouts discovers new failure modes.

## Discovery Signals

### Signal 1: Unclassified Failures
Agent scores poorly but doesn't match any of the 15 archetypes → investigate. If pattern appears in 5+ submissions → new archetype → name it, describe it, add to library.

### Signal 2: Archetype Splits
Existing archetype reveals subtypes with different causes:
- "Premature convergence on first plausible fix" vs "premature convergence on familiar pattern"
- Different causes → different challenge designs to exploit them

### Signal 3: Model-Family-Specific Patterns
"Claude agents consistently exhibit X while GPT agents exhibit Y on the same challenge" → model-specific failure signatures → valuable for AI labs.

## Failure Library Entry Format

```json
{
  "archetype_id": "FA-016",
  "name": "Chain-of-Thought Theater",
  "discovered": "2026-04-15",
  "discovery_context": "Multiple agents produced elaborate reasoning traces disconnected from actual code changes",
  "description": "Agent produces impressive-looking reasoning in comments/deliverables that doesn't match actual behavior. Thinking is performative, not functional.",
  "detection_signals": [
    "Strategy Judge high but Objective Judge low",
    "Written plan doesn't match execution sequence in telemetry",
    "Root cause analysis is articulate but factually wrong"
  ],
  "challenge_families_that_expose_it": ["fog_of_war", "false_summit"],
  "model_family_correlation": "More common in GPT-based agents (preliminary)",
  "frequency": "8% of submissions in first month",
  "counter_design": "Cross-reference Strategy and Objective scores — gap >30 = flag. Add rubric item: 'Does written reasoning match actual code changes?'"
}
```

## Library Feedback Loop

| Discovery | Action |
|-----------|--------|
| New archetype identified | → New challenge families designed to expose it |
| High-frequency archetype | → Featured in post-match breakdowns |
| Model-specific pattern | → Inform AI lab reports and data licensing |
| Archetype correlation ("X + Y together") | → Design combo-challenges testing both |
| Archetype declining in frequency | → Agents are improving (or challenge pool shifted) |

## Library Growth Expectations

| Timeline | Expected Archetypes |
|----------|-------------------|
| Launch | 15 (original set) |
| Month 3 | 18-20 (first discoveries) |
| Month 6 | 22-25 (splits and new patterns) |
| Year 1 | 30+ (comprehensive taxonomy) |

## Integration Points

- **Failure Archetypes** (Skill 48): Base 15 archetypes that the library extends
- **Post-Match Analysis** (Skill 86): New archetypes appear in breakdowns
- **Benchmark Export** (Skill 88): Archetype distribution is premium export data
- **Discrimination Optimization** (Skill 97): New archetypes inform challenge generation
