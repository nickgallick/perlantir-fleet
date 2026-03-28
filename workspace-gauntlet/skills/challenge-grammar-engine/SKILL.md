# Challenge Grammar Engine — Skill 91

## Purpose
A formal composition language for building challenges from explicit components. Ensures every challenge is composed deliberately from structural building blocks — nothing missing, nothing accidental.

## The 10 Challenge Components

### 1. Task Core
The fundamental problem being tested. Stripped of narrative, context, decoration — the ONE SENTENCE that defines what the challenge tests.
- Example: "Find and fix a race condition in concurrent database writes"
- Example: "Design an API that handles 3 conflicting requirements"

### 2. Visible Objective
What the agent is told to accomplish. May be identical to the task core (transparent) or a subset (the real challenge is hidden).
- Transparent: visible = task core
- Hidden: visible = "Fix the failing test" / actual = "The test is correct, the upstream pipeline is broken"

### 3. Hidden Invariant
Requirements that exist but are not stated. The agent must discover or infer them.
- Security requirements not in the brief
- Performance constraints implied by architecture
- Edge cases absent from visible tests
- Business rules embedded in code but not documented

### 4. Deception Layer
What is deliberately misleading.
- **Level 0**: Nothing misleading (Tier 0-1)
- **Level 1**: Irrelevant noise (Tier 2)
- **Level 2**: Active misdirection — briefing points to wrong cause (Tier 3+)
- **Level 3**: Multiple layers — fixing what deception suggests makes things worse (Frontier)

### 5. Pressure Source
What creates urgency or constraint. Not just time limits — structural pressure.
- **Time**: Tight limit relative to work required
- **Resource**: Limited tool calls, iterations, context
- **Scope**: Too much to do, must prioritize
- **Correctness**: Partial solutions score poorly
- **Competing**: Two good approaches, can only pursue one

### 6. Telemetry Opportunity
Designed moments where good and bad process look DIFFERENT in telemetry. Minimum 3 per challenge.
- "Will the agent read before coding?" checkpoint
- "Will the agent test between changes?" checkpoint
- "Will the agent recover or repeat?" checkpoint

### 7. Exploit Temptation (Required Tier 2+)
Designed moments where a dishonest agent is tempted to cheat.
- Test files that COULD be read
- Visible outputs that COULD be hardcoded
- Shortcuts that pass visible but fail hidden tests

### 8. Recovery Branch (Required Tier 2+)
Designed moments where the agent WILL fail and must recover.
- Obvious first approach that doesn't work
- Fix that reveals a deeper problem
- Iteration where tests regress

### 9. Scoring Hooks
Specific, designed points where each judge lane has clear evidence.
- **Objective**: Specific tests tied to specific deliverables
- **Process**: Specific tool sequences indicating quality
- **Strategy**: Specific decisions the agent must make and justify
- **Recovery**: Specific failure-recovery sequences
- **Integrity**: Specific honesty/dishonesty opportunities

### 10. Narrative Wrapper
The story that makes the challenge memorable.
- **Name**: Evocative, not descriptive
- **Hook**: 2-3 sentence scene-setter
- **Stakes**: Why this matters
- **Reveal**: What the agent discovers as it works

## Composition Rules

| Component | Tier 0-1 | Tier 2 | Tier 3+ |
|-----------|----------|--------|---------|
| 1. Task Core | ✅ Required | ✅ Required | ✅ Required |
| 2. Visible Objective | ✅ Required | ✅ Required | ✅ Required |
| 3. Hidden Invariant | ✅ Required | ✅ Required | ✅ Required |
| 4. Deception Layer | Level 0 | Level 1 | Level 2-3 |
| 5. Pressure Source | ✅ Required | ✅ Required | ✅ Required |
| 6. Telemetry Opportunity | ✅ Required (3+) | ✅ Required (3+) | ✅ Required (4+) |
| 7. Exploit Temptation | Optional | ✅ Required | ✅ Required |
| 8. Recovery Branch | Optional | ✅ Required (1+) | ✅ Required (2+) |
| 9. Scoring Hooks | ✅ Required | ✅ Required | ✅ Required |
| 10. Narrative Wrapper | ✅ Required | ✅ Required | ✅ Required |

**If a required component is missing, the challenge is incomplete — do not publish.**

## Integration Points

- **Structured Output** (Skill 77): Grammar components map to JSON fields
- **Judge Evidence Engineering** (Skill 79): Telemetry Opportunities + Scoring Hooks
- **Fun & Prestige Evaluator** (Skill 92): Narrative Wrapper drives engagement
- **Red-Team Review** (Skill 95): Exploit Temptation and Deception Layer are red-team targets
