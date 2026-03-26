# Dependency Management — Agent Blocking & Parallel Work

## Purpose
Track which agents are blocked by which, identify idle agents, and maximize parallel utilization across the pipeline. No agent should sit idle when there's prep work available.

## 12-Phase Pipeline Dependency Chain

```
Phase 1: Intake (MaksPM)
    ↓ blocks
Phase 2: Research (Scout)
    ↓ blocks
Phase 3: Architecture (Forge)
    ↓ blocks
Phase 4: COO Gate 1 (ClawExpert)
    ↓ blocks
Phase 5: Design (Pixel)
    ↓ blocks
Phase 6: COO Gate 2 (ClawExpert)
    ↓ blocks
Phase 7: Build (Maks)
    ↓ blocks
Phase 8: Code Review (Forge)
    ↓ blocks
Phase 9: COO Gate 3 (ClawExpert)
    ↓ blocks
Phase 10: QA (MaksPM)
    ↓ blocks
Phase 11: Launch (Launch)
    ↓ blocks
Phase 12: Complete (MaksPM)
```

## Dependency Matrix

| Phase Being Worked | Scout | Forge | Pixel | Maks | Launch | ClawExpert |
|-------------------|-------|-------|-------|------|--------|------------|
| 1. Intake | idle | idle | idle | idle | idle | idle |
| 2. Research | **BUSY** | idle | idle | idle | idle | idle |
| 3. Architecture | idle | **BUSY** | idle | idle | idle | idle |
| 4. COO Gate 1 | idle | idle | idle | idle | idle | **BUSY** |
| 5. Design | idle | idle | **BUSY** | idle | idle | idle |
| 6. COO Gate 2 | idle | idle | idle | idle | idle | **BUSY** |
| 7. Build | idle | idle | idle | **BUSY** | idle | idle |
| 8. Code Review | idle | **BUSY** | idle | idle | idle | idle |
| 9. COO Gate 3 | idle | idle | idle | idle | idle | **BUSY** |
| 10. QA | idle | idle | idle | idle | idle | idle |
| 11. Launch | idle | idle | idle | idle | **BUSY** | idle |

## Parallel Work Opportunities

When one project is in a given phase, idle agents can do prep or work on other projects:

| Current Phase | Idle Agent | Assignable Parallel Work |
|--------------|------------|--------------------------|
| Research (Scout) | Forge | Review architecture patterns for similar projects |
| Research (Scout) | Pixel | Prepare design system tokens, review reference screenshots |
| Research (Scout) | Launch | Research distribution channels, prep GTM templates |
| Architecture (Forge) | Scout | Start research on next queued project |
| Architecture (Forge) | Pixel | Collect design references, prep Stitch inputs |
| Architecture (Forge) | Launch | Draft launch timeline template |
| Design (Pixel) | Scout | Start next project research |
| Design (Pixel) | Forge | Review architecture spec for completeness |
| Design (Pixel) | Launch | Draft positioning copy, prep launch assets |
| Build (Maks) | Scout | Start next project research |
| Build (Maks) | Forge | Prep code review checklist from architecture spec |
| Build (Maks) | Pixel | QA design implementation fidelity (once deployed) |
| Build (Maks) | Launch | Write launch copy, set up analytics plan, prep distribution |
| Code Review (Forge) | Scout | Next project research |
| Code Review (Forge) | Pixel | Prep design QA checklist |
| Code Review (Forge) | Launch | Finalize launch package |
| QA (MaksPM) | All | Available for fix iterations or next project |

## Multi-Project Pipeline

When running 2+ projects simultaneously:

### Rules
1. No agent works on more than 1 task at a time
2. Priority order: current project phase > parallel prep > next project
3. If an agent is blocked waiting for a dependency, assign parallel prep immediately
4. Track which project each agent is currently serving

### Multi-Project Dependency Template

```markdown
## Agent Allocation — [Date]

| Agent | Current Task | Project | Blocked By | Available For |
|-------|-------------|---------|------------|---------------|
| Scout | Research | Project B | — | — |
| Forge | Idle | — | — | Architecture prep (Project B), Review prep (Project A) |
| Pixel | Design | Project A | — | — |
| Maks | Idle | — | Pixel (Project A) | — |
| Launch | Idle | — | — | GTM prep (Project A) |
| ClawExpert | Idle | — | — | Gate prep |
```

## Identifying Blocked Agents

Check for blocks at every phase transition:
1. Read active-projects/ files for all active projects
2. For each agent, determine: busy / blocked / idle
3. If idle and active projects exist → assign parallel work
4. If blocked → identify the blocking agent/phase and estimate unblock time

## Escalation Rules
- Agent blocked for >2× expected phase duration → nudge blocking agent
- Agent blocked for >3× expected phase duration → escalate to Nick
- Agent idle with no assignable work for >2 hours → flag in status report
