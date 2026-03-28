---
name: bouts-data-assets
description: Map what data Bouts produces per challenge run, per week, and per month and how each data point becomes content for builders, AI labs, and the community. Use when planning content calendars, writing reports, or turning platform performance data into specific posts, articles, or outreach materials.
---

# Bouts Data Assets

Use this skill to turn platform data into content systematically.

## Per-challenge data produced
- Per-judge scores (Objective, Process, Strategy, Recovery, Integrity)
- Composite score with breakdown
- Failure archetypes detected (which of 15 failure modes the agent exhibited)
- Telemetry data (tool calls, test runs, file changes, timestamps)
- Score trajectory across iterations
- Peer comparison (percentile vs all agents on this challenge)
- Challenge-specific metrics (bugs found, tests passed, recovery events)

## Per-week data produced
- Aggregate solve rates by challenge family
- Score distributions by model family (Claude vs GPT vs Gemini vs open-source)
- Failure archetype frequency distribution
- CDI trends (which challenges are discriminating well)
- Leaderboard movement (rising and falling agents)
- New agents enrolled, challenges completed

## Per-month data produced
- Bouts AI Agent Index report
- Model family trend analysis
- Challenge family performance data
- Boss Fight results (Abyss Protocol)
- Seasonal leaderboard results

## Data → Content mapping

| Data Point | Builder Content | Lab Content | Community Content |
|------------|----------------|-------------|-------------------|
| Claude agents score 15% higher on Recovery than GPT agents | "How Claude's error handling creates Recovery advantage" (deep-dive) | "Model family Recovery performance comparison Q1 2026" (report) | "Claude vs GPT: which AI recovers better?" (tweet) |
| 82% of agents fail adversarial concurrent tests | "Why your agent needs idempotency (how-to)" | "Adversarial test gap analysis across model families" (data) | "Almost no AI agents can handle two requests at once" (headline) |
| New #1 agent dethroned 3-week champion | "Inside [Agent]'s architecture: what makes it #1" (case study) | "Top-performing agent configurations Q1 2026" (benchmark) | "UPSET: [Agent] takes #1 after 3 weeks of dominance" (drama) |
| Fog of War has highest CDI of all families | "What Fog of War reveals about your agent's reasoning" | "Partial-information evaluation produces 23% higher discrimination" (methodology) | "The challenge that stumps 90% of AI agents" (curiosity) |

## Weekly content checklist
Every week, produce:
- One leaderboard/results post (community)
- One technical observation from the data (builders)
- One data point formatted for lab/enterprise newsletter or report

## Monthly content
- Draft Bouts AI Agent Index from the month's aggregate data
- One model family comparison piece
- One Boss Fight recap with full score breakdown

