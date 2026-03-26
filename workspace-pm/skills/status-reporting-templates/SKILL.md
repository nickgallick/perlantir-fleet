# Status Reporting Templates — Standardized Pipeline Updates

## Purpose
No freeform status updates. Every update to Nick or agents uses a structured template with required fields. All templates are Telegram-optimized (under 4000 chars).

## Telegram Constraints
- Max message length: 4096 characters
- Keep updates under 4000 chars (buffer for formatting)
- Use emoji sparingly but consistently for scannability
- Bold (**) for headers, monospace (`) for file paths and commands
- No tables wider than ~60 chars (breaks on mobile)

---

## Template 1: Project Intake

Use when: Nick requests a new project or idea is approved for pipeline.

```
📋 **Project Intake — [Name]**
**Date**: [YYYY-MM-DD HH:MM GMT+8]
**Source**: [Nick direct / Scout recommendation / other]
**Description**: [1-2 sentences]
**Stack**: [Next.js / Expo / etc.]
**Appetite**: [Small: 1-2 days / Medium: 3-5 days / Large: 1-2 weeks]
**Pipeline**: Starting at Phase [#]
**First Agent**: [Scout/Forge/etc.]
**Tracking**: `active-projects/[name].md` created
**Next**: [what happens immediately]
```

---

## Template 2: Phase Transition

Use when: Any phase completes and the next begins.

```
📋 **Phase Update — [Project Name]**
**Completed**: Phase [#] [Name] ([Agent])
**Duration**: [time]
**Outcome**: ✅ Passed / ⚠️ Passed with notes / ❌ Failed
**Deliverable**: `[file path]`
**Starting**: Phase [#] [Name] ([Agent])
**ETA**: [estimated duration]
**Cumulative Time**: [total so far]
```

---

## Template 3: COO Gate Result

Use when: ClawExpert completes a gate review.

```
🚦 **Gate [#] — [Project Name]**
**Result**: ✅ PASSED / ❌ FAILED
**Reviewer**: ClawExpert (COO)
**Date**: [YYYY-MM-DD HH:MM GMT+8]
**Checked**: [what was reviewed]
**Issues Found**: [count] — [brief list or "None"]
**Verdict**: [1 sentence summary]
**Next**: [what happens now]
```

---

## Template 4: Blocker Alert

Use when: A phase is blocked and can't proceed.

```
🚨 **BLOCKED — [Project Name]**
**Phase**: [current phase]
**Agent**: [blocked agent]
**Blocker**: [clear description]
**Blocked Since**: [timestamp]
**Impact**: [what can't proceed]
**Options**:
1. [option A]
2. [option B]
3. [option C]
**Decision Needed By**: [deadline if applicable]
```

---

## Template 5: Project Complete

Use when: All phases done, project is live.

```
🚀 **Project Complete — [Name]**
**Live At**: [URL or "Pending app store"]
**Total Duration**: [time from intake to complete]
**Phase Breakdown**:
- Research: [duration]
- Architecture: [duration]
- Design: [duration]
- Build: [duration]
- Code Review: [duration]
- QA: [duration]
- Launch: [duration]
**Gate Results**: G1 ✅ | G2 ✅ | G3 ✅
**QA Grade**: [grade]
**Estimated Cost**: [cumulative]
**Launch Status**: [live / pending / scheduled]
```

---

## Template 6: Daily Project Summary

Use when: End of day or on request. Covers ALL active projects.

```
📊 **Daily Summary — [Date]**

**Active Projects**: [count]

[For each project:]
**[Project Name]** — Phase [#]: [Name]
Status: [emoji + status]
Agent: [current agent]
Progress: [brief]
Next: [what's coming]
Blockers: [any or "None"]

**Agent Utilization**:
- 🟢 Active: [list]
- 🟡 Idle: [list]
- 🔴 Blocked: [list]

**Decisions Needed**: [list or "None"]
**Tomorrow**: [what's planned]
```

---

## Template 7: Agent Work Order

Use when: Sending a task to an agent via sessions_spawn.

```
## Work Order — [Project Name]

**Phase**: [phase name]
**Priority**: P0 / P1 / P2
**Deadline**: [if applicable]

**Context**: [1-2 sentences on what this project is]

**Your Task**: [clear description of what to do]

**Inputs**:
- [deliverable 1]: `[file path]`
- [deliverable 2]: `[file path]`

**Output Expected**:
- [what they should produce]
- [where to save it]

**Quality Bar**: [specific requirements]

**Constraints**: [any limitations]
```

---

## Template 8: Fix Iteration

Use when: QA or review found issues that need fixing.

```
🔧 **Fix Required — [Project Name]**
**Source**: [QA / Forge Review / COO Gate]
**Iteration**: [#] of 3 max
**Issues** ([count]):
1. [severity] — [description]
2. [severity] — [description]
3. [severity] — [description]
**Fix Agent**: [Maks usually]
**Deadline**: [if applicable]
**Circuit Breaker**: [#/3 attempts used]
```

---

## Usage Rules
1. Always use the matching template — never freeform
2. Fill ALL required fields — leave nothing blank (use "N/A" or "TBD" if unknown)
3. Keep under 4000 chars — trim descriptions if needed
4. Phase transitions ALWAYS get reported to Nick
5. Blockers get reported immediately, not batched
6. Daily summary only if there are active projects
