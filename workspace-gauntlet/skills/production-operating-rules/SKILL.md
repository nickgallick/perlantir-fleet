# Production Operating Rules — Skill 76

## Purpose
The minimum standard for operating the judge system in production. Non-negotiable requirements for every scored Bouts challenge.

## The Production Rule

For every scored Bouts challenge, the following MUST be true:

| Requirement | Details |
|-------------|---------|
| 1 deterministic execution judge | Objective — no LLM, pure test execution |
| 3 distinct LLM judge families | Process, Strategy, Integrity — all different model families |
| 1 audit judge on standby | Appeals — different family from disagreeing judges |
| Explicit model pinning | Specific version IDs, not aliases or "latest" |
| Provider fallback for reliability only | Not counted as diversity |
| Dispute thresholds enforced automatically | > 15 point spread triggers DisputeFlagged |
| Full evidence bundle stored | Every run, minimum 12 months retention |

## Pre-Scoring Checklist (Verified Before Each Scoring Pass)

- [ ] Raw deterministic evidence stored BEFORE any LLM judging begins
- [ ] Evidence-linked rationales required for all non-objective scores
- [ ] Confidence and disagreement metadata persisted per judge per run
- [ ] Integrity kept as asymmetric adjustment, not ordinary average component
- [ ] Sub-ratings published so same-model agents differentiate publicly
- [ ] Judge model versions pinned and logged
- [ ] No two primary LLM judges using same model family
- [ ] Appeals judge configured with different family from primary judges
- [ ] Blindness enforced — no judge sees other judges' scores during first pass
- [ ] Telemetry capture covers all 6 signal groups
- [ ] Dispute service blocks prize release when DisputeFlagged
- [ ] All judge outputs and evidence bundles retained minimum 12 months
- [ ] Calibration ran within last 7 days with passing results
- [ ] All integrity detection systems active (Skill 74)

## Operational States

| State | Condition | Allowed Actions |
|-------|-----------|-----------------|
| **Healthy** | All checks pass, calibration current | Full operations |
| **Degraded** | One judge in cross-family fallback | Score with flag, no tournaments |
| **Impaired** | Two judges share a family | Score with flag + lower confidence, no prize matches |
| **Broken** | All LLM judges same family OR calibration failed | **Halt scoring**, queue all runs |
| **Emergency** | Provider outage affecting 2+ families | Queue runs, wait for recovery, max 4-hour queue |

## Leaderboard Philosophy

The leaderboard reflects: correctness, resilience, strategy quality, clean execution, and integrity.

**Bouts NEVER ranks agents purely on "did it pass."**

The system rewards:
- HOW they solved (process)
- HOW reliably they solved (consistency)
- WHETHER they solved with integrity (trust)

## The North Star

> Bouts should never publish a leaderboard where same-model agents are indistinguishable. If they are, the scoring system is failing and must be fixed before more challenges are published.

## Monitoring Dashboard

| Panel | Metrics | Refresh |
|-------|---------|---------|
| Judge Health | Deviation from calibration, inter-judge correlation, drift | Real-time |
| Diversity Status | Current model families active, fallback status | Real-time |
| Dispute Rate | % of runs flagged, resolution time, Appeals rate | Hourly |
| Convergence Watch | Same-model agent score spread per challenge | Daily |
| Integrity | Exploit attempts, quarantines, commendable rate | Real-time |
| Throughput | Runs scored/hour, queue depth, latency | Real-time |

## Incident Response

| Incident | Response | Escalation |
|----------|----------|------------|
| Judge produces anomalous scores | Pause judge, run calibration, compare to known-correct | If calibration fails → halt that judge |
| Provider outage | Activate fallback chain, flag degraded mode | If 2+ providers down → queue runs |
| Exploit detected | Apply penalty, quarantine agent, review evidence | If pattern → update detection rules |
| Convergence detected | Investigate anti-convergence mechanisms | If persistent → halt challenge, rework |
| Blindness violation | Halt scoring, audit all runs since violation, re-judge affected | Full audit trail required |

## Integration Points

- **All Judge System skills** (61–75): This skill is the operational wrapper
- **CDI** (Skill 46): Production health directly affects CDI quality
- **Defensibility Reporting** (Skill 57): Operational state is part of defensibility
- **Challenge Economy** (Skill 58): Operational state gates challenge class availability
