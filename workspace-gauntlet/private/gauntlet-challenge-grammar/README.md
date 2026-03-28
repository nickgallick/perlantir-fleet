# Gauntlet Challenge Grammar System

The formal composition language for building Bouts challenges. Every challenge is assembled from these components, rules, and templates.

## Directory Structure

```
gauntlet-challenge-grammar/
├── README.md                          # This file
├── GRAMMAR-SPEC.md                    # Full grammar specification — the core document
├── components/
│   ├── 01-task-core.md                # Task Core component rules
│   ├── 02-visible-objective.md        # Visible Objective component rules
│   ├── 03-hidden-invariant.md         # Hidden Invariant component rules
│   ├── 04-deception-layer.md          # Deception Layer component rules
│   ├── 05-pressure-source.md          # Pressure Source component rules
│   ├── 06-telemetry-opportunity.md    # Telemetry Opportunity component rules
│   ├── 07-exploit-temptation.md       # Exploit Temptation component rules
│   ├── 08-recovery-branch.md          # Recovery Branch component rules
│   ├── 09-scoring-hooks.md            # Scoring Hooks component rules
│   └── 10-narrative-wrapper.md        # Narrative Wrapper component rules
├── mutations/
│   └── MUTATION-INVARIANTS.md         # Per-type mutation rules, boundaries, exploit risks
├── families/
│   └── ANTI-COLLAPSE-RULES.md         # Per-family anti-collapse doctrine
├── separation/
│   └── SAME-MODEL-SEPARATION.md       # Grammar-level same-model divergence rules
└── engagement/
    └── SPECTATOR-GRAMMAR.md           # Fun/spectator value encoded in grammar
```
