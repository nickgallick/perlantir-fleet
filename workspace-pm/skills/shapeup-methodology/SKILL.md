---
name: shapeup-methodology
description: Shape Up methodology adapted for agent-orchestrated development. Fixed time, variable scope. Ship fast.
---

# Shape Up for Agent Development

## Core Principles

### 1. Appetite Over Estimates
Don't ask "how long will this take?" Ask "how much time is this WORTH?"
- **Small batch**: 1-2 hours → simple landing page, single component, quick fix
- **Medium batch**: 2-6 hours → multi-section page, simple feature, basic CRUD
- **Large batch**: 6-24 hours → full app, multi-screen, auth + database + API

Set the appetite at INTAKE. This is the time budget. The scope flexes to fit.

### 2. Fixed Time, Variable Scope
The deadline doesn't move. The scope DOES.
- If design is taking too long → reduce screens, simplify layouts
- If build is running over → cut nice-to-have features
- If review loops pile up → fix P0s only, log P1s for follow-up

### 3. Shaping Before Building
Shape the work during INTAKE:
- Rough solution (not detailed spec — leave room for agents to be creative)
- Boundaries (what's IN and what's explicitly OUT)
- Rabbit holes (what could go wrong, flag it early)

### 4. No Backlogs
If Nick doesn't ask for it now, don't track it. If it matters, it'll come back.
Active-projects/ only has CURRENT work. No "someday" list.

### 5. Circuit Breaker
If something is taking too long relative to appetite:
- At 60% of time budget → evaluate progress. On track? Keep going. Behind? Scope hammer.
- At 80% of time budget → if not nearly done, CUT to ship what you have.
- At 100% → ship or kill. Don't let it drag into 2x.

## Scope Hammering
When a project runs over appetite:
1. List all remaining work
2. Sort: must-ship / nice-to-have / cut
3. Cut everything that's not must-ship
4. Ask: "Can we ship with just the must-ship items?"
5. Yes → ship. No → escalate to Nick.

## Hill Chart Mental Model
Two dimensions of progress:
- **Uphill** (figuring it out): research, design, architecture — uncertainty is high
- **Downhill** (executing): building, reviewing, deploying — just grinding through known work

If stuck uphill too long → needs more shaping, not more building. Send back to research or design.

## Applying to Pipeline
| Phase | Shape Up Lens |
|-------|--------------|
| Intake | Shape the work — set appetite, boundaries, rabbit holes |
| Research | Uphill — reducing uncertainty about the market/product |
| Design | Uphill → Downhill — from exploration to concrete screens |
| Build | Downhill — executing against approved designs |
| Review | Quality gate — not progress, just pass/fail |
| QA | Quality gate |
| Launch | Downhill — executing launch playbook |

## Reference
See repos/pm-docs/shapeup-principles.md for full Shape Up principles from Basecamp.

## Changelog
- 2026-03-20: Initial Shape Up adaptation for agent orchestration
