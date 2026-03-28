# Component 8: Recovery Branch

## Definition
Designed moments where the agent WILL fail and must recover. The trap should be natural — something a reasonable developer would try first — and the recovery path should be observable in telemetry.

## Discrimination Function
Recovery is the **#1 differentiator between same-model agents.** The base model's capability is similar. How the scaffolding handles failure is where the real quality shows.

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Hits the trap, tries the same approach again (maybe with minor tweaks), gets stuck in a loop, never truly recovers. Score trajectory: [20, 22, 25, 24]. | No error analysis. No strategic pivot. Repeats until timeout. |
| **Strong** | Hits the trap, recognizes the approach isn't working, pivots to a different strategy. May lose one iteration but recovers. Trajectory: [20, 45, 38, 65]. | Can detect failure and change direction. Dip-then-recovery pattern. |
| **Elite** | Hits the trap, diagnoses WHY the approach failed (not just THAT it failed), uses the failure information to inform a better approach. Trajectory: [20, 55, 72, 85]. Monotonic improvement. | Failure is information. Each iteration builds on what was learned. |

**Why this widens spread:** Recovery branches produce the richest telemetry data in the entire challenge. The Recovery Judge (10-35% weight depending on family) scores based on: detection speed, diagnosis quality, strategy change, and trajectory improvement. Two agents with the same final score but different trajectories get very different Recovery scores.

## Anti-Compression Rules
- The trap must catch MOST agents on first attempt — if only weak agents fall for it, there's no recovery signal from strong/elite agents.
- The trap must be recoverable — an unrecoverable trap just penalizes everyone equally.
- Recovery must be OBSERVABLE in telemetry — the agent must DO something visibly different after the failure (re-read, run new tests, revert, try different approach).
- The recovery path must lead to meaningfully higher scores — otherwise agents have no incentive to recover.

## Recovery Branch Types

| Type | Description | Best For |
|------|-------------|----------|
| **Obvious-but-wrong first fix** | The most natural first attempt doesn't work | Debug challenges |
| **Cascade revelation** | Fixing A reveals B is also broken | Multi-bug challenges |
| **Regression trap** | A fix breaks something else | Integration challenges |
| **False completion** | Agent thinks it's done but adversarial tests fail | False Summit family |
| **Phase shift** | Mid-challenge update changes assumptions | Adaptive challenges |

## Same-Model Separation Contribution
**Very High** — recovery behavior is almost entirely scaffolding-driven:
- Detection speed: How quickly the scaffolding recognizes failure
- Diagnosis quality: Whether the scaffolding analyzes the failure or just retries
- Strategy selection: Whether the scaffolding can generate genuinely new approaches
- Rollback discipline: Whether the scaffolding reverts cleanly or piles changes
- Information extraction: Whether the scaffolding treats failures as data

## Required for Tier 2+ (minimum 1 branch), Tier 3+ (minimum 2 branches)

## Template
```
RECOVERY BRANCHES:
  1. [Trap type] — [What the obvious first attempt is] — [Why it fails] — [What the recovery path looks like]
     Detection signal: [How telemetry shows the agent noticed]
     Recovery signal: [How telemetry shows the agent adapted]
     Trajectory target: [Expected score pattern across iterations]
  2. [Trap type] — ...
```
