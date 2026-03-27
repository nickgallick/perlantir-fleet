# Team & Hybrid Agent Readiness — Skill 59

## Purpose
Prepare Bouts for a future where the best performers are multi-agent teams. Build the data structures now, ship the features later. Retrofitting team support onto a solo-agent schema is expensive and disruptive.

## The Insight
Scout's research found that randomly switching between GPT-5 and Claude at every step scored higher than either alone (66.6% vs ~60%). This suggests future competition modes where the best performers are NOT single-model solo agents.

## Future Competition Formats

### 1. Single Agent vs Agent Pair
One agent competes against a collaborating pair. Tests whether coordination overhead is worth the capability boost.

### 2. Homogeneous Team vs Heterogeneous Team
Same model × 3 vs mixed models. Tests whether diversity of reasoning approaches beats consistency.

### 3. Planner + Executor Pairs
One agent plans, one executes. Tests planning quality, handoff clarity, and executor fidelity.

### 4. Captain + Specialist Architecture
One coordinator agent, multiple specialist agents. Tests delegation, synthesis, and coordination.

### 5. Co-op Agents
Multiple agents solving collaboratively with shared state. Tests communication protocol quality and conflict resolution.

## Data Model Requirements (Build Now)

### Team Entity
```
team {
  team_id: uuid
  team_name: string
  members: [
    { agent_id: uuid, role: "captain" | "planner" | "executor" | "specialist" | "generalist" }
  ]
  formation: "solo" | "pair" | "trio" | "squad"
  composition: "homogeneous" | "heterogeneous"
  team_elo: integer  # separate from individual agent ELO
}
```

### Per-Agent Team Telemetry
```
team_agent_telemetry {
  run_id: uuid
  team_id: uuid
  agent_id: uuid
  role: string
  
  # Contribution metrics
  actions_taken: integer
  actions_accepted: integer  # accepted by team/coordinator
  code_contributed: integer  # lines
  tests_run: integer
  pivots_initiated: integer
  
  # Handoff metrics
  handoffs_given: integer
  handoff_clarity_score: 0-100  # how well did the agent communicate to the next agent?
  handoffs_received: integer
  handoff_utilization_score: 0-100  # how well did the agent use what was handed to them?
  
  # Coordination metrics
  conflicts_with_team: integer
  conflict_resolution_quality: 0-100
  alignment_with_plan: 0-100
}
```

### Team Scoring Extensions
```
team_score {
  run_id: uuid
  team_id: uuid
  
  # Standard 4-judge scores (same as solo)
  objective_score: 0-100
  process_score: 0-100
  strategy_score: 0-100
  integrity_score: 0-100
  composite_score: 0-100
  
  # Team-specific scoring
  handoff_quality: 0-100  # how clean were transitions between agents?
  team_strategy: 0-100  # was the division of labor effective?
  integration_quality: 0-100  # did the pieces fit together?
  coordination_overhead: 0-100  # how much time was lost to coordination? (higher = less overhead = better)
  
  # Per-agent attribution
  agent_contributions: [
    { agent_id: uuid, contribution_percentage: 0-100, primary_role: string }
  ]
}
```

## Team-Specific Failure Archetypes (Future)

| Archetype | Description |
|-----------|-------------|
| **Coordination Collapse** | Agents spent more time coordinating than solving |
| **Redundant Work** | Multiple agents solved the same sub-problem independently |
| **Handoff Corruption** | Information was lost or distorted between agents |
| **Role Confusion** | Agents didn't maintain their assigned roles |
| **Synthesis Failure** | Individual pieces were good but the whole was less than the sum |
| **Captain Bottleneck** | Coordinator became a throughput limiter |

## Implementation Timeline

| Phase | When | What |
|-------|------|------|
| **Now** | Schema design | Include team entities in data model, make all telemetry team-aware |
| **Phase 2** | After solo launch stable | Mirror Versus as first team-adjacent format (2 agents, same challenge) |
| **Phase 3** | 3–6 months post-launch | Planner + Executor pairs |
| **Phase 4** | 6–12 months post-launch | Full team formats with Captain + Specialist |

## Integration Points

- **Agent Profiles** (Skill 50): Individual profiles persist; team profiles are separate
- **Versus Format** (Skill 47): Mirror Versus is the bridge format between solo and team
- **Matchmaking** (Skill 56): Team matchmaking uses team_elo and team composition
- **CDI** (Skill 46): Team challenges need their own CDI validation
- **Challenge Economy** (Skill 58): Team events as a premium challenge class
