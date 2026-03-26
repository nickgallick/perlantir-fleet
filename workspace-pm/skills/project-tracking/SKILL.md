# Project Tracking — Structured Active Project Files

## Purpose
Standardized tracking for every project in active-projects/. This is the single source of truth for project status. No freeform files — every project uses this template.

## Rules (Non-Negotiable)
1. Every project gets a tracking file at intake — before ANY work is assigned
2. Every phase transition updates the file with timestamp and outcome
3. The active-projects/ file is the ONLY source of truth for project status
4. Never report project status without reading the tracking file first
5. COO gate results are recorded immediately upon receipt
6. Move to completed-projects/ only after Launch phase completes or project is explicitly killed

## Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| Project Name | Official project name | Agent Arena |
| Status | Current high-level status | 🔨 Building / ⏳ In Review / ✅ Complete / ❌ Blocked / 🔄 On Hold |
| Current Pipeline Phase | Which of the 12 phases we're in | Phase 5: Build |
| Phase History | Every completed phase with timestamp | See template below |
| COO Gate Results | Pass/Fail + date + reviewer for each gate | Gate 1: PASSED 2026-03-20 (ClawExpert) |
| Blockers | Current blockers, if any | Apple Developer account pending |
| Agent Assignments | Which agent owns each phase | Forge: Architecture, Pixel: Design, Maks: Build |
| Deliverable File Paths | Exact paths to all deliverables | /data/.openclaw/workspace-forge/architecture-spec-project.md |
| ETA Per Phase | Estimated duration for upcoming phases | Build: 45min, Review: 15min, QA: 20min |
| Cumulative Cost Estimate | Running token/cost estimate | ~$4.20 (Research $0.80 + Architecture $1.40 + Design $2.00) |

## Blank Template

Copy this for every new project:

```markdown
# [PROJECT NAME] — Active Project Tracker

## Status
**Phase**: [current phase]
**Status**: [emoji + status]
**Owner**: MaksPM (orchestrating)
**Created**: [date GMT+8]
**Last Updated**: [date GMT+8]

## Pipeline
[Mark completed phases with ✅, current with **, upcoming unmarked]
```
Nick → Scout → Forge → COO Gate 1 → Pixel → COO Gate 2 → Maks → Forge Review → COO Gate 3 → QA → Launch → Complete
```

## Phase History
| # | Phase | Agent | Started | Completed | Duration | Outcome |
|---|-------|-------|---------|-----------|----------|---------|
| 1 | Intake | MaksPM | | | | |
| 2 | Research | Scout | | | | |
| 3 | Architecture | Forge | | | | |
| 4 | COO Gate 1 | ClawExpert | | | | |
| 5 | Design | Pixel | | | | |
| 6 | COO Gate 2 | ClawExpert | | | | |
| 7 | Build | Maks | | | | |
| 8 | Code Review | Forge | | | | |
| 9 | COO Gate 3 | ClawExpert | | | | |
| 10 | QA | MaksPM | | | | |
| 11 | Launch | Launch | | | | |
| 12 | Complete | MaksPM | | | | |

## COO Gate Results
| Gate | Result | Date | Reviewer | Notes |
|------|--------|------|----------|-------|
| Gate 1 (Post-Architecture) | | | | |
| Gate 2 (Post-Design) | | | | |
| Gate 3 (Post-Code Review) | | | | |

## Agent Assignments
| Phase | Agent | Status |
|-------|-------|--------|
| Research | Scout | |
| Architecture | Forge | |
| Design | Pixel | |
| Build | Maks | |
| Code Review | Forge | |
| QA | MaksPM | |
| Launch | Launch | |

## Deliverables
| Phase | Deliverable | Path | Size |
|-------|-------------|------|------|
| Research | Research brief | | |
| Architecture | Architecture spec | | |
| Design | Design specs | | |
| Build | Deployed app | | |
| Code Review | Review report | | |
| QA | QA report | | |
| Launch | Launch package | | |

## Blockers
| Blocker | Raised | Owner | Status | Resolved |
|---------|--------|-------|--------|----------|
| None | | | | |

## ETA
| Phase | Estimated Duration | Actual Duration | Variance |
|-------|-------------------|-----------------|----------|
| Research | | | |
| Architecture | | | |
| Design | | | |
| Build | | | |
| Code Review | | | |
| QA | | | |
| Launch | | | |

## Cost Estimate
| Phase | Estimated Cost | Actual Cost |
|-------|---------------|-------------|
| Research | | |
| Architecture | | |
| Design | | |
| Build | | |
| Code Review | | |
| QA | | |
| Launch | | |
| **Total** | | |

## Notes
[Project-specific notes, decisions, pivots]
```

## Agent Task Board (2026-03-22 — MANDATORY)

You are the orchestrator. You MUST know what every agent is working on at all times. Maintain a live task board at `active-projects/agent-task-board.md`. This is the single source of truth for "who is doing what right now."

**Update this file EVERY TIME:**
- You assign work to an agent
- An agent completes a task
- An agent reports a blocker
- A phase transition happens
- At every heartbeat (verify board matches reality via sessions_list)

### Task Board Format
```markdown
# Agent Task Board
**Last Updated:** [YYYY-MM-DD HH:MM GMT+8]

| Agent | Status | Current Task | Project | Assigned At | ETA | Queued Next |
|-------|--------|-------------|---------|-------------|-----|-------------|
| Maks ⚡ | 🟢 Active | Build Phase 7 | Agent Arena | 2026-03-22 10:00 | 45min | — |
| Forge 🔥 | 🟡 Idle | — | — | — | — | — |
| Pixel 🎨 | 🟢 Active | Design screens | OUTBOUND | 2026-03-22 09:30 | 2h | — |
| Scout 🔍 | 🟢 Active | Market research | UberKiwi | 2026-03-22 11:00 | 30min | — |
| Launch 🚀 | 🟡 Idle | — | — | — | — | — |
| ClawExpert 🧠 | 🟢 Active | COO audit | Ops | Always | — | — |
| MaksPM 📋 | 🟢 Active | Orchestrating | All | Always | — | — |
```

### Task Ownership Lock
Before assigning work to any agent:
1. Check the task board for their current assignment
2. If the agent is currently working a task → **QUEUE** it in the "Queued Next" column, don't interrupt
3. One agent, one task, one deliverable at a time (unless explicitly marked as parallel work by Nick or COO)
4. Record every assignment with timestamp

**If an agent receives a new task while busy:**
- P0/URGENT from Nick or ClawExpert → interrupt current task, switch immediately
- Everything else → queue it, finish current task first
- Never silently drop a task — always acknowledge receipt and give ETA

### Board Accuracy Rule
If Nick asks "what is [agent] working on?" you MUST be able to answer instantly from this board. If the board is stale or you're unsure, check sessions_list FIRST, update the board, THEN answer. Never guess from old context.

## When to Update
- **Phase start**: Update current phase, agent assignment, start timestamp
- **Phase complete**: Update completion timestamp, duration, outcome, deliverable path
- **COO gate**: Update gate result immediately (pass/fail + date + reviewer + notes)
- **Blocker raised**: Add to blockers table with date and owner
- **Blocker resolved**: Update blocker status and resolution date
- **Scope change**: Note in Notes section with date and reason
- **Project killed/paused**: Update status, note reason, move to completed-projects/ if killed
