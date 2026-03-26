# Capacity Planning — Real-Time Agent Workload Tracking

## Purpose
Track agent utilization in real-time. No agent should be idle for >2 hours during active projects. If an agent finishes early, assign prep work for the next phase or next project.

## How to Check Agent Status

### Via sessions_list
```
sessions_list(kinds=["agent"], activeMinutes=120, messageLimit=1)
```
This returns all agent sessions active in the last 2 hours with their most recent message.

### Via Workspace Files
| Agent | Workspace | Activity Log |
|-------|-----------|-------------|
| Scout | /data/.openclaw/workspace/agents/scout/ | Check latest output files |
| Forge | /data/.openclaw/workspace-forge/ | Check latest spec/review files |
| Pixel | /data/.openclaw/workspace-pixel/ | Check latest design specs |
| Maks | /data/.openclaw/workspace/ | /data/.openclaw/workspace/memory/YYYY-MM-DD.md |
| Launch | Check via sessions_list | Latest launch package files |
| ClawExpert | /data/.openclaw/workspace-expert/ | Check latest audit/gate files |

### Via Direct Check (sessions_send)
Send a quick status ping:
```
"Status check — what are you currently working on? Reply with: current task, % complete, ETA, any blockers."
```

## Agent Utilization Dashboard Template

Update this at every heartbeat and phase transition:

```markdown
## Agent Utilization — [Date Time GMT+8]

| Agent | Status | Current Task | Project | Started | ETA | Queue | Hours Idle |
|-------|--------|-------------|---------|---------|-----|-------|------------|
| Scout 🔍 | 🟢 Active / 🟡 Idle / 🔴 Blocked | | | | | 0 | 0 |
| Forge 🔥 | 🟢 Active / 🟡 Idle / 🔴 Blocked | | | | | 0 | 0 |
| Pixel 🎨 | 🟢 Active / 🟡 Idle / 🔴 Blocked | | | | | 0 | 0 |
| Maks ⚡ | 🟢 Active / 🟡 Idle / 🔴 Blocked | | | | | 0 | 0 |
| Launch 🚀 | 🟢 Active / 🟡 Idle / 🔴 Blocked | | | | | 0 | 0 |
| ClawExpert 🧠 | 🟢 Active / 🟡 Idle / 🔴 Blocked | | | | | 0 | 0 |

**Active Projects**: [count]
**Agents Utilized**: [count]/6
**Utilization Rate**: [%]
```

## Status Definitions
- 🟢 **Active**: Currently executing a task
- 🟡 **Idle**: No current task, available for assignment
- 🔴 **Blocked**: Has a task but waiting on a dependency
- ⚪ **Offline**: Not responding or session expired

## Capacity Rules

### Rule 1: No Idle Agents During Active Projects
If any agent is 🟡 Idle and there are active projects:
1. Check dependency-management skill for parallel work opportunities
2. Assign prep work for the next phase of the current project
3. If no prep available, assign work on the next queued project
4. If truly nothing to assign, note in dashboard and move on

### Rule 2: Queue Management
Each agent has a task queue. When assigning work:
1. Primary task: the current pipeline phase they own
2. Queue: prep work for upcoming phases or other projects
3. Never queue more than 2 tasks per agent (cognitive overload)

### Rule 3: Completion Monitoring
When an agent's ETA passes:
- **+5 min**: Check status via sessions_list
- **+15 min**: Send status ping via sessions_send
- **+30 min**: Escalate — check workspace for output, send follow-up
- **+60 min**: Alert Nick with options

### Rule 4: Agent Response Times (Expected)
| Agent | Typical Response | Max Before Escalation |
|-------|-----------------|----------------------|
| Scout | 3-8 min | 15 min |
| Forge | 3-10 min | 20 min |
| Pixel | 5-15 min per screen | 30 min per screen |
| Maks | 15-60 min (varies by complexity) | 90 min |
| Launch | 5-15 min | 30 min |
| ClawExpert | 3-10 min | 15 min |

## Utilization Tracking Over Time

At project completion, record:
```markdown
## Utilization Summary — [Project Name]
| Agent | Total Active Time | Total Idle Time | Utilization % |
|-------|------------------|-----------------|---------------|
| Scout | | | |
| Forge | | | |
| Pixel | | | |
| Maks | | | |
| Launch | | | |
| ClawExpert | | | |
```

Use this data to improve future capacity planning and parallel work assignments.
