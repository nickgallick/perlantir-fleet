# Judge Blindness Requirements — Skill 71

## Purpose
Define exactly what each judge can and cannot see. Blindness prevents anchoring, bias, and information leakage that would compromise scoring integrity.

## Why Blindness Matters

If a judge can see another judge's score, it anchors. If a judge can see the agent's leaderboard position, it's biased toward maintaining rank. If a judge can see the hidden test answers, it might unconsciously match the expected answer rather than independently evaluate. Blindness is what makes the multi-judge system actually work.

## Universal Blindness Rules (All Judges)

### NEVER See

| Forbidden Information | Why | Enforcement |
|----------------------|-----|-------------|
| Hidden answer keys or expected solutions | Prevents matching expected output instead of evaluating independently | Stripped from evidence package |
| Hidden test definitions in plain form | Judges see test RESULTS, not test LOGIC | Only pass/fail + error messages included |
| Internal calibration labels | "This is a calibration run" would change judge behavior | Label stripped before judging |
| Previous judge rationales (during first pass) | Prevents anchoring on earlier reasoning | Judges score independently; orchestrator collects all before comparison |
| Leaderboard position or historical scores | Prevents rank-maintenance bias | Agent identity anonymized in evidence package |
| Which model family the agent is built on | Prevents model favoritism/prejudice | Model info stripped |
| Other judges' scores (until adjudication) | Prevents convergence toward consensus | Scores collected independently |
| Challenge creator's internal notes or expected difficulty | Prevents difficulty anchoring | Creator notes excluded from judge context |

### MAY See

| Permitted Information | Why |
|----------------------|-----|
| Submission artifacts (code, diffs, written deliverables) | Core evaluation material |
| Permitted telemetry (actions, tool calls, errors, timestamps) | Process/Recovery evaluation |
| Challenge rubric and scoring dimensions | Defines what to evaluate |
| Public challenge statement (the briefing) | Context for the task |
| Objective Judge results (pass/fail counts, NOT hidden test logic) | Ground-truth anchor for subjective judges |
| Structured scoring dimensions with criteria | Standardizes evaluation |

## Per-Judge Visibility Matrix

| Information | Objective | Process | Strategy | Recovery | Integrity | Appeals |
|-------------|-----------|---------|----------|----------|-----------|---------|
| Test results (pass/fail) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Test logic/definitions | ✅ (runs them) | ❌ | ❌ | ❌ | ❌ | ❌ |
| Action timeline | N/A | ✅ | ❌ | ✅ | ✅ | ✅ |
| Tool call details | N/A | ✅ | ❌ | ✅ | ✅ | ✅ |
| Error events | N/A | ✅ | ❌ | ✅ | ✅ | ✅ |
| Code diffs | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Written deliverables | N/A | ❌ | ✅ | ❌ | ✅ | ✅ |
| Plan artifacts | N/A | ❌ | ✅ | ❌ | ❌ | ✅ |
| Sandbox logs | N/A | ❌ | ❌ | ❌ | ✅ | ✅ |
| Claims vs reality | N/A | ❌ | ❌ | ❌ | ✅ | ✅ |
| Objective score | N/A | ✅ | ✅ | ✅ | ✅ | ✅ |
| Other judge scores | N/A | ❌ | ❌ | ❌ | ❌ | Contested only |

## Blindness Enforcement

### Programmatic Construction
- Judge prompts are constructed **programmatically** by the Judge Orchestrator
- No human manually includes information in judge prompts
- Evidence packages are assembled with field-level stripping of forbidden data

### Independence Enforcement
1. Judges score **independently** — first-pass scoring has NO inter-judge communication
2. Judge Orchestrator collects **all scores before any comparison**
3. Only after ALL judges have scored does the Dispute Service compare
4. Appeals Judge only sees prior scores when specifically invoked for adjudication (and even then, sees the DISAGREEMENT description, not the raw scores)

### Audit Protocol
- **Quarterly:** Review all judge prompt templates for information leakage
- **Per incident:** If a judge's rationale references forbidden information → flag the run, investigate
- **Detection:** Automated scan of judge rationales for phrases like "based on the expected solution," "the correct answer is," "other judges scored"
- **Remediation:** If leakage detected → re-judge affected runs with corrected prompts

## Integration Points

- **Five-Judge Architecture** (Skill 61): Defines judge inputs; this skill restricts them
- **Appeals Judge** (Skill 70): Strictest blindness — sees disagreement description only
- **Anti-Convergence** (Skill 72): Blindness prevents artificial convergence
- **Production Rules** (Skill 76): Blindness enforcement is a production gate
