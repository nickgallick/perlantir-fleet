# Adaptive Mid-Run Phases — Skill 53

## Purpose
Controlled mid-run challenge evolution that tests agent resilience, re-planning, and adaptation — mirroring production reality where requirements shift, dependencies break, and assumptions fail.

## Core Principle
Great agents are not just good at static tasks. They stay good when the environment changes.

## Six Adaptation Event Types

### 1. Dependency Shift
A library version changes mid-challenge. Agent must detect breakage and adapt.
- **Signal**: Build/test failure after phase shift
- **Tests**: Dependency awareness, version compatibility reasoning
- **Good response**: Identify the version change, understand impact, adapt code
- **Bad response**: Flail at symptoms without checking what changed

### 2. Test Assumption Break
A test is updated to reflect a corrected requirement. Agent must recognize it's a legitimate change, not their bug.
- **Signal**: Previously passing test now fails
- **Tests**: Test interpretation, requirement tracking
- **Good response**: Read the updated test, understand the new requirement, update code
- **Bad response**: Try to make the old behavior pass the new test

### 3. New Constraint Appears
"Update: response time must be < 3 seconds." Agent must evaluate if current solution meets it.
- **Signal**: New requirement in system message
- **Tests**: Constraint awareness, performance reasoning
- **Good response**: Profile current solution, identify bottlenecks, optimize if needed
- **Bad response**: Ignore the constraint or over-optimize everything

### 4. Tool Failure
Test runner returns unreliable results. Agent must detect flakiness and factor it in.
- **Signal**: Inconsistent test results across runs
- **Tests**: Flakiness detection, statistical reasoning
- **Good response**: Run multiple times, identify flaky tests, reason despite noise
- **Bad response**: Trust every test result at face value

### 5. Requirement Correction
"The schema in the original briefing was wrong." Agent must surgically update affected code.
- **Signal**: Corrected requirement in system message
- **Tests**: Impact analysis, surgical modification
- **Good response**: Trace all affected code paths, update precisely, verify
- **Bad response**: Rewrite large sections or miss affected paths

### 6. Evidence Revealed as Misleading
"The log file was from staging, not production." Agent must re-examine conclusions.
- **Signal**: Invalidation of previous evidence
- **Tests**: Hypothesis revision, intellectual humility
- **Good response**: Identify which conclusions depended on that evidence, re-evaluate, adjust
- **Bad response**: Ignore the correction, or panic and restart from scratch

## Scoring Impact

Adaptation events create three scoring opportunities:
1. **Detection**: Did the agent notice the change? (binary)
2. **Understanding**: Did the agent correctly understand the implications? (0–100)
3. **Response quality**: Did the agent adapt effectively? (0–100)

Agents who **fail to detect** the change lose points on both Objective and Process. Agents who detect but respond poorly lose mainly on Strategy. Agents who adapt cleanly gain a Strategy bonus.

## Application Rules

| Format | Phase Shift Frequency | Rationale |
|--------|----------------------|-----------|
| Sprint | 0% | Sprints test raw speed; phase shifts add noise |
| Standard | 30% of challenges | Enough to test adaptation, not so much it dominates |
| Marathon | 60% of challenges | Multi-stage formats reward adaptation heavily |

### Timing Rules
- Phase shifts occur **between iterations**, never during
- Clear system message: `⚠️ Challenge Update: [description]`
- Minimum 1 full iteration before first phase shift
- Maximum 2 phase shifts per Standard challenge, 4 per Marathon

### Fairness Rules
- Phase shifts must be **internally justified** (not pure sabotage)
- Phase shifts must be **auditable** (clear record of what changed and when)
- Phase shifts must **improve discrimination**, not add randomness
- Reference solution must handle all phase shifts (verified during calibration)

## Integration Points

- **CDI** (Skill 46): Phase shifts that increase CDI are retained; those that add noise are removed
- **Failure Archetypes** (Skill 48): Phase shifts expose Recovery Collapse, Context Drift, Ambiguity Avoidance
- **Strategic Tempo** (Skill 54): Phase shifts test re-planning tempo quality
- **Process Legibility** (Skill 55): How the agent reasons about the change is scored
