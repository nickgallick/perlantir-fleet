---
name: agentic-planning
description: Structured planning methodology from SWE-agent and OpenHands — localize, understand, reproduce, plan, implement, verify, reflect. Applied to both code review and code generation.
---

# Agentic Planning

## The SWE-Agent Methodology (from Princeton's config and trajectories)

SWE-agent's default config reveals a rigid 5-step loop that solves real GitHub issues:

1. **Find and read relevant code** — before touching anything
2. **Create a reproduction script** — confirm the error exists
3. **Edit source code** — minimal changes to non-test files
4. **Rerun reproduction** — confirm the fix works
5. **Think about edge cases** — ensure the fix is robust

Their `SUBMIT_REVIEW_MESSAGES` config adds a self-review gate: before submitting, the agent must re-run repro, remove temp files, and verify the diff is clean. This is enforced by the tooling, not left to the agent's judgment.

**Key insight from SWE-agent:** The `USE_FILEMAP` setting gives the agent a complete file tree upfront. Agents that see structure before code make better decisions about WHERE to edit. Most failed attempts start by editing the wrong file.

## The OpenHands Decomposition (from CodeActAgent)

OpenHands' CodeActAgent architecture reveals a modular approach:
- **Tool separation:** bash, browser, file edit, IPython, think, finish — each as a distinct tool
- **Task tracker tool:** explicit tracking of sub-tasks during long operations
- **Think tool:** a dedicated "pause and reason" step that doesn't execute code
- **Condensation:** for long conversations, summarize history to stay within context limits
- **Memory management:** `ConversationMemory` + `Condenser` manage what the agent remembers

**Key insight:** The `ThinkTool` is separate from coding tools. This forces a planning step that doesn't produce code. Many agents jump straight to editing — OpenHands forces "think first."

---

## Forge's Planning Protocol

### When REVIEWING Code (Maks submits a PR)

Before writing a single review comment:

1. **Read the entire diff** — understand the full scope of changes
2. **Identify the intent** — what is this PR trying to accomplish? (read PR description, commit messages)
3. **Check what DIDN'T change** — are there files that should have been modified but weren't? (missing migration, missing test, missing type update)
4. **Trace the data flow** — for each changed function, trace inputs → processing → outputs
5. **Run the 32-point checklist** — systematically, not by gut feel
6. **Draft review** → then **argue against your review** → then finalize

### When WRITING Code (auto-fix, alternative implementations)

Before writing a single line:

1. **State the problem** in one sentence
2. **List every file** that needs to change
3. **Describe the change** for each file in natural language
4. **Predict side effects** — what could break? What other code calls this?
5. **Write the code** — minimal changes only
6. **Self-review** — apply your own 32-point checklist
7. **Provide verification steps** — what should someone run to confirm the fix?

### When DEBUGGING (complex multi-system issues)

1. **Observe** — What exactly is the symptom? Be precise.
2. **Hypothesize** — Top 3 most likely causes, ranked
3. **Test** — Simplest test first that confirms or eliminates the top hypothesis
4. **Isolate** — Binary search: does the error happen before or after this point?
5. **Root cause** — Don't stop at "this line throws." Ask WHY.
6. **Fix + verify** — Fix the root cause, not the symptom
7. **Prevent** — Should a type check, test, or linter rule prevent this class of bug?

---

## Planning Templates

### Template: Bug Fix
```
## Problem
[One sentence describing the symptom]

## Root Cause
[Why this happens — the underlying issue, not the symptom]

## Files to Change
1. [file path] — [what changes and why]
2. [file path] — [what changes and why]

## Side Effects
- [What could break]
- [Why it won't break, or how to handle it]

## Verification
1. [How to confirm the fix works]
2. [How to confirm nothing else broke]
```

### Template: Feature Implementation
```
## Goal
[What this feature does from the user's perspective]

## Architecture
[Which components are involved, data flow]

## Implementation Order (each step is a working state)
1. [Database migration] — can be deployed independently
2. [Backend service/action] — works with existing UI
3. [UI components] — works with new backend
4. [Tests] — covers new logic

## Rollback Plan
[How to undo each step if something goes wrong]
```

## Anti-Patterns to Flag in Reviews

| Anti-Pattern | What to Look For | Better Approach |
|-------------|-----------------|-----------------|
| **Shotgun surgery** | PR changes 15 files across 5 features | Each feature change should be a separate PR |
| **Big bang** | Entire feature in one massive commit | Incremental commits, each a working state |
| **Wrong file** | Changes to a file that doesn't affect the stated goal | Verify the localization step was done |
| **No repro** | Bug fix with no reproduction evidence | Ask: "How did you verify this fixes the issue?" |
| **Mixed concerns** | Bug fix + refactor + feature in one PR | Split into separate PRs |

## Sources
- princeton-nlp/SWE-agent config/default.yaml — planning loop and ACI definition
- OpenHands CodeActAgent — tool decomposition and task tracking
- OpenHands ThinkTool — explicit reasoning step
- SWE-bench representative issues — what correct fixes look like

## Changelog
- 2026-03-21: Initial skill — agentic planning from SWE-agent and OpenHands
