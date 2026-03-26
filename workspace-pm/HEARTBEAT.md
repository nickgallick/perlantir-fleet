# Heartbeat — MaksPM Mission Control

## Every Cycle: Active Project Check

### 1. Check active projects
```bash
ls /data/.openclaw/workspace-pm/active-projects/
```
For each active project file:
- What phase is it in?
- Is any agent stuck or unresponsive?
- Has any phase exceeded expected duration?
- Are there pending decisions waiting on Nick?

**Expected phase durations:**
- RESEARCH: 3-8 min
- DESIGN (per screen): 5-15 min
- BUILD (simple): 15-30 min | (complex): 30-60 min
- REVIEW: 3-10 min
- QA: 5-10 min
- LAUNCH: 5-15 min

### 2. Stuck Agent Protocol (Escalation Ladder)

**Detection:** Agent hasn't delivered within 2× expected duration, OR reported BLOCKED, OR idle when they should be active.

**Step 1 — Diagnose (0-5 min):**
Check sessions_history for the agent. Read last 3-5 messages. Determine:
- Are they actually stuck or just slow?
- Is it a technical blocker (API error, tool failure, missing input)?
- Is it a context problem (unclear spec, missing deliverable from upstream)?
- Is it a capacity problem (task too complex for their model)?

**Step 2 — Unblock directly (5-15 min):**
Based on diagnosis, act:
- **Missing input?** → Get it yourself. Read the file, pull the data, send it to them.
- **Unclear spec?** → Clarify it. Rewrite the task with more detail.
- **Tool failure?** → Route to ClawExpert for infra fix.
- **Wrong agent?** → Reassign. If Maks is stuck on a design decision, route to Pixel. If Forge is stuck on product context, provide it.
- **Task too big?** → Break it down. Split into 2-3 subtasks the agent can handle.

**Step 3 — Reassign (15-30 min):**
If the agent can't complete it after direct help:
- Reassign to another capable agent (e.g. Forge can build if Maks is stuck, Maks can research if Scout is stuck)
- Update the task board immediately
- Log why the reassignment happened

**Step 4 — Escalate to COO (30+ min):**
If you can't resolve it yourself, escalate to ClawExpert (COO) — NOT Nick:
`sessions_send(sessionKey="agent:clawexpert:telegram:direct:7474858103", message="...")`

Escalation format:
```
🚨 **Stuck — [Project]**
**Agent:** [who]
**Task:** [what]
**Stuck since:** [time]
**Root cause:** [specific]
**What I tried:** [list]
**Decision needed:** [specific question]
**Options:** 1. [option] 2. [option]
```

**Step 5 — Escalate to Nick (45+ min / COO can't resolve):**
Only if ClawExpert can't resolve within 15 minutes OR the blocker requires Nick's decision (budget, product direction, external dependency, one-way door per Governance Tier 1).

ClawExpert escalates to Nick — not MaksPM. Chain of command: Agent → MaksPM → ClawExpert → Nick.

**NEVER escalate with just "agent is stuck" — always include what you tried and what decision you need.**

### 3. Check deployments
For each active project with a live URL:
```bash
curl -s -o /dev/null -w "%{http_code}" [url]
```
- 200 = healthy
- Non-200 = report immediately to Nick

### 4. Report idle projects
If any active project has been idle > 1 hour with pending work → send Nick status update

### 5. Agent Task Board Sync (EVERY CYCLE — NON-NEGOTIABLE)
Scan all 6 agents and update `active-projects/agent-task-board.md`:

```
1. sessions_list(kinds=["agent"], activeMinutes=120, messageLimit=2)
2. For each active agent: read last 2 messages to determine WHAT they're working on
3. Update the task board with: agent, status, current task description, project name
4. Flag any agent that's been active >2h on the same task (potential stuck)
5. Flag any agent that shows idle but has assigned work in the board (dropped task?)
```

The board must answer: "What is every agent doing RIGHT NOW?" If you can't answer that from the board, it's stale and you've failed.

### 6. Clean up
Move completed projects from active-projects/ to completed-projects/

## Only message Nick if:
- 🚨 Agent unresponsive and blocking a project
- 🚨 Deployment down
- 🚨 Fix loop hit circuit breaker (3 attempts)
- 🚨 Nick's decision required to unblock
- 📋 Phase transition update (always)
- 📋 Project complete (always)

Silence = all projects flowing normally.

### 6. PM Knowledge (every cycle)
- Review completed-projects/ for estimation accuracy
- Update estimation skill if actual times consistently differ from estimates
- Check risk-management skill for lessons learned that should apply to active projects

Reply HEARTBEAT_OK if nothing needs attention.

## Blocked Task Dedup Rule
Before re-engaging any blocked/stalled item, check if new context exists since your last action on it (new message from another agent, status change, new file, or explicit directive). If nothing changed → skip it entirely. Do not re-comment, do not re-alert, do not re-attempt. Only re-engage when new information arrives. This prevents wasting tokens on unchanged blockers.
