# CLAWTEAM-ARCHITECTURE-ASSESSMENT.md

Author: Forge  
Date: 2026-03-23  
Repo reviewed: `/data/shared-repos/clawteam`  
Scope: architecture, code quality, security, extensibility, and OpenClaw bridge design  

---

## Executive Verdict

**Recommendation: pursue a wrapper-based integration, not a direct fork-first integration.**

ClawTeam is **real code, not vaporware**. The codebase is small, readable, and more disciplined than most early-stage agent orchestration repos. It has useful primitives we do not currently have: worktree isolation, task dependency tracking, mailbox-style coordination, and launch templates.

But it is also clearly **alpha infrastructure**:
- file-based state,
- shell-driven process launch,
- weak trust boundaries between spawned agents,
- no real sandboxing,
- no durable transactional state,
- and limited safety around command execution and workspace isolation.

If the goal is:
- **“Can we use ClawTeam ideas to unlock dynamic parallel capacity for OpenClaw?”** → **Yes.**
- **“Should we deeply couple production OpenClaw to ClawTeam internals right away?”** → **No.**

### Bottom line
- **ClawTeam code quality grade:** **B**
- **Production-readiness as-is:** **No**
- **Good enough to build on:** **Yes, with containment**
- **Best path:** **Wrap it first, fork only if the MVP proves value**

---

## What I Reviewed

Primary files reviewed:
- `README.md`
- `pyproject.toml`
- `docs/transport-architecture.md`
- `clawteam/cli/commands.py`
- `clawteam/spawn/prompt.py`
- `clawteam/spawn/subprocess_backend.py`
- `clawteam/spawn/tmux_backend.py`
- `clawteam/spawn/command_validation.py`
- `clawteam/spawn/adapters.py`
- `clawteam/spawn/registry.py`
- `clawteam/team/models.py`
- `clawteam/team/manager.py`
- `clawteam/team/tasks.py`
- `clawteam/team/mailbox.py`
- `clawteam/team/lifecycle.py`
- `clawteam/transport/file.py`
- `clawteam/transport/p2p.py`
- `clawteam/workspace/manager.py`
- `clawteam/workspace/git.py`
- `clawteam/workspace/context.py`
- `clawteam/templates/__init__.py`
- `clawteam/templates/software-dev.toml`

---

## A. Code Quality Grade

## Grade: **B**

### What’s good

#### 1. The architecture is understandable
The codebase has clear module boundaries:
- `spawn/*` for process launch
- `team/*` for state, tasks, lifecycle, mailbox
- `transport/*` for message delivery
- `workspace/*` for git worktrees
- `templates/*` for launch definitions

That is a strong sign. This repo is not random scripts glued together.

#### 2. Atomic-write discipline appears in multiple places
They consistently use **tmp + rename** patterns for:
- config writes
- registry writes
- peer files
- mailbox delivery
- event logs

That is good operational hygiene for a filesystem-backed system.

#### 3. Pydantic models are used for core structures
Important records are modeled, not left as shapeless dicts:
- `TeamConfig`
- `TeamMessage`
- `TaskItem`
- template models
- profile models

That reduces schema drift.

#### 4. Worktree-based isolation is a strong design choice
The `WorkspaceManager` + `git worktree` approach is practical and valuable. It gives each spawned agent a real branch and real filesystem isolation at the repo level without needing full containers.

#### 5. There are tests
This matters. The repo has meaningful test coverage across:
- lifecycle
- tasks
- mailbox
- templates
- spawn backends
- CLI commands

That alone puts it above most agent orchestration repos.

### What’s concerning

#### 1. `commands.py` is far too large
`clawteam/cli/commands.py` is a giant file. It is doing too much. That raises maintenance cost and makes future integration riskier.

#### 2. Spawn is shell-driven in risky ways
`SubprocessBackend.spawn()` builds a shell string and launches with:
- `shell=True`
- concatenated command string
- concatenated exit hook

They do quote command parts with `shlex.quote`, which helps, but architecturally this is still a high-risk area.

#### 3. Error handling is often best-effort, not robust
There are many places where they catch `Exception` and continue or silently degrade. That improves resilience for demos, but hurts diagnosability and correctness in production.

#### 4. Trust boundaries are weak
Agents are assumed to be cooperative. The system is built for coordination, not adversarial safety.

#### 5. File-based persistence is simple but fragile at scale
The design is elegant for small teams. It will get noisy and harder to reason about under higher concurrency, remote execution, and partial failure.

### Checklist-based summary

- Security: **C+**
- Type safety / modeling: **B+**
- Architecture: **B**
- Database/state strategy: **C** (filesystem state only)
- API/CLI design: **B**
- Performance/concurrency: **C+**
- Testing: **B**
- Production hardening: **C**

---

## B. Architecture Assessment

## Is the file-based state model robust enough for production use?

**For small, trusted, single-host teams: mostly yes.**  
**For production-grade orchestration across many agents: no.**

### Current state model
ClawTeam stores state roughly under `~/.clawteam/`:
- `teams/<team>/config.json`
- `teams/<team>/inboxes/...`
- `teams/<team>/events/...`
- `teams/<team>/peers/...`
- `teams/<team>/spawn_registry.json`
- `tasks/<team>/task-*.json`
- `workspaces/<team>/workspace-registry.json`

### What works well
- Human-inspectable state
- Easy debugging
- No DB dependency
- Good for local-first workflows
- Recoverable enough for low scale

### What breaks under load

#### 1. Directory scan amplification
Inboxes, tasks, and event logs rely on filesystem enumeration and sorted globs. At larger message volumes or longer-lived teams, this gets slower and more operationally messy.

#### 2. Cross-file consistency gaps
There is no true transaction across:
- task state
- spawn registry
- mailbox events
- workspace registry

If a process dies mid-flow, one file may update while another does not.

#### 3. Partial lifecycle recovery
They do some crash recovery:
- stale worktree cleanup
- dead agent lock release
- file quarantine for bad messages

That is good. But there is no durable recovery coordinator. After a crash, the system reconstructs from scattered files with best-effort heuristics.

#### 4. Event log growth
Mailbox event logging is append-only. No retention policy, compaction, or archiving strategy is obvious in the reviewed code.

#### 5. Multi-host correctness depends on assumptions
P2P peer discovery plus file fallback is clever, but correctness depends on:
- peer lease freshness,
- shared filesystem semantics,
- local PID meaning only on local host,
- ZMQ availability.

That is workable, but not something I would call production-grade distributed systems engineering.

### If an agent crashes mid-task
What likely happens:
- task may remain locked until stale lock release runs,
- worktree remains on disk,
- spawn registry still has stale process info,
- leader may or may not get a useful completion/failure signal,
- task dependencies may stay blocked if completion never gets marked.

The system has some mitigations, but not strong crash semantics.

### My verdict on the state model
**Good for MVP orchestration. Not sufficient as the long-term backbone of a mission-critical OpenClaw swarm control plane.**

If we use ClawTeam, it should be as:
- a coordination shell,
- not our source of truth for durable agent memory, policy, or audit logs.

---

## C. Security Review — 5 Persona Threat Model

ClawTeam is designed for cooperative agents. If we integrate it with stronger agents and valuable credentials, security becomes the main concern.

---

### Persona 1: Outsider

#### Attack surface
- shared filesystem state in `~/.clawteam`
- peer discovery files
- tmux session names / command execution pathways
- any wrapper scripts we add around OpenClaw

#### Risks
- If host access is gained, ClawTeam state is easy to enumerate and manipulate.
- Peer files and inbox files are plain JSON. No integrity signing.
- No encryption or message authenticity in the reviewed transport layer.

#### Assessment
ClawTeam assumes host trust. That is acceptable for local orchestration, but means **host compromise = total ClawTeam compromise**.

---

### Persona 2: Insider Agent

This is the biggest one.

#### Can a spawned agent manipulate another agent’s workspace?
**Yes, potentially.**

Not by ClawTeam API design alone, but by host-level access model.
If spawned agents share the same user and same filesystem permissions, any agent with shell ability can:
- inspect `~/.clawteam`
- read or write inbox files,
- inspect worktrees,
- read peer files,
- alter task files,
- interfere with another worktree or branch.

The worktree model gives repo isolation from `main`, but **not isolation from each other at the OS permission layer**.

#### Risk
This is the single largest security weakness for an OpenClaw integration.

---

### Persona 3: Race Condition Exploiter

#### Risks
- task file lock release races
- message claim vs consume races
- stale peer file windows
- registry/workspace mismatch after abrupt exits

The file transport’s claim-and-ack flow is better than naive file consumption. The task store also uses `fcntl` locks. That is good.

But these are advisory locks and filesystem coordination, not durable transactional concurrency.

#### Assessment
Moderate risk. Probably acceptable for a few agents on one Linux host. Not robust enough for larger or hostile environments.

---

### Persona 4: Data Poisoner

#### Risks
- malformed inbox messages
- hostile content inside task descriptions or coordination prompt context
- tampered peer files
- tampered template files

Mitigations present:
- Pydantic validation for `TeamMessage`
- dead-letter quarantine for malformed mailbox payloads

Missing:
- message signing
- origin authenticity
- sender authorization
- template integrity verification

#### Assessment
Schema validation exists, but trust validation does not.

---

### Persona 5: Reconnaissance Agent

#### Risks
A spawned agent can likely infer:
- team membership
- other agents’ names
- branches
- worktree paths
- tasks
- recent commits via context layer

That is intentional for coordination, but dangerous if one worker is untrusted or misprompted.

### Overall threat model conclusion
**ClawTeam is safe enough only inside a trusted-agent boundary.**
If we merge it with OpenClaw and start spawning agents carrying real skills, memory, and secrets, we must add stronger isolation than ClawTeam currently provides.

---

## Specific Security Findings

### 1. Shell command execution remains a high-risk zone
`SubprocessBackend` builds shell commands and uses `shell=True`.

Even with `shlex.quote`, this is still a risky architecture because:
- future modifications can accidentally break quoting,
- appended hooks increase complexity,
- shell semantics are harder to reason about than argv execution.

**Severity:** P1 if used with partially untrusted task/command sources.

### 2. Tmux command injection risk is reduced but not eliminated
The tmux backend constructs shell snippets and exported environment blocks. Again, lots of quoting exists, which is good. But the safety model is still “careful shell construction,” not “avoid shell interpretation.”

**Severity:** P2

### 3. No true sandbox between agents
This is the major architectural security gap.

**Severity:** P1

### 4. Path traversal risk appears low in reviewed paths, but naming should still be constrained
I did not see obvious raw path joins from arbitrary user path strings into sensitive locations in the reviewed core flows. But team names and agent names are embedded into paths, branch names, tmux targets, and commands. Those identifiers should be hard-validated to a safe character set.

I did not see a strong canonical sanitizer layer for identifiers in the reviewed code.

**Severity:** P2

### 5. Inbox authenticity is weak
Anyone with write access to the shared state can spoof messages from any agent.

**Severity:** P1 in a mixed-trust environment.

---

## D. Extensibility Assessment

## Can we add an OpenClaw integration without forking?
**Yes — for an MVP.**

ClawTeam already has the right insertion points:
- runtime command adaptation in `spawn/adapters.py`
- profile application in `spawn/profiles.py`
- template loading in `templates/__init__.py`
- prompt injection in `spawn/prompt.py`
- backend abstraction in `spawn/base.py`

It also already recognizes `openclaw` in `spawn/adapters.py`.

### What this means
We do **not** need to fork ClawTeam to prove the concept.
We can build an external bridge layer that:
- prepares a spawned OpenClaw workspace,
- copies selected SOUL/skills/tools files,
- launches OpenClaw via a profile/command wrapper,
- reports status back into ClawTeam.

### Where forking becomes likely later
If we want first-class support for:
- OpenClaw-native session lifecycle,
- policy-aware template inheritance,
- bi-directional OpenClaw session messaging,
- richer metadata on templates,
- stronger resource caps,
- non-shell-safe spawn,
then a fork or upstream contribution becomes more likely.

---

## E. Integration Architecture — ClawTeam × OpenClaw Bridge Spec

## Recommendation: build a **bridge wrapper**, not a deep code fork

### Core design principle
Use ClawTeam for:
- orchestration,
- task graph,
- worktree creation,
- coarse mailbox coordination.

Use OpenClaw for:
- agent intelligence,
- persona/soul,
- skills,
- memory,
- tool policy,
- session execution.

### Component diagram

```text
Nick / MaksPM
    |
    v
ClawTeam Leader Agent
    |
    | clawteam spawn / launch
    v
OpenClaw Bridge Wrapper
    |
    +--> Template Resolver
    |      - loads maks-builder / forge-reviewer template
    |      - resolves SOUL.md, skill set, tools, repos, env policy
    |
    +--> Workspace Composer
    |      - creates isolated OpenClaw workspace overlay
    |      - copies SOUL.md / AGENTS.md / TOOLS.md / selected skills
    |      - writes bridge manifest
    |
    +--> ClawTeam Workspace Manager
    |      - creates git worktree per spawned worker when repo-backed
    |
    +--> OpenClaw Runtime Launcher
    |      - launches openclaw agent/session in that workspace
    |      - injects initial task + ClawTeam coordination commands
    |
    +--> Bridge Reporter
           - mirrors worker status to ClawTeam inbox
           - optionally mirrors status to OpenClaw sessions_send
```

---

## Agent template data model

Store templates outside ClawTeam core first:
- Path: `/data/.openclaw/templates/agent-templates.toml`
- Optional per-template support files under `/data/.openclaw/templates/<template-name>/`

### Template model fields

Each template should define:
- `template_id`
- `description`
- `base_agent` (e.g. `forge`, `maks`, `pixel`)
- `runtime` (`openclaw-local`, `openclaw-docker-exec`, later maybe `acp`)
- `model`
- `workspace_mode` (`overlay`, `copy`, `shared-readonly`)
- `soul_file`
- `tools_file`
- `agent_files[]` (AGENTS.md, USER.md, standards, etc.)
- `skills.include[]`
- `skills.exclude[]`
- `memory_mode` (`none`, `snapshot`, `readonly-link`)
- `repos.mount[]`
- `env.allow[]`
- `env.map[]`
- `resource_limits.max_parallel`
- `resource_limits.max_runtime_minutes`
- `resource_limits.max_cost_usd`
- `coordination.report_channel`
- `cleanup.keep_worktree`
- `cleanup.keep_workspace`

---

## Spawn flow: “MaksPM says spawn 3 builders”

### Step-by-step

1. **Leader decides to scale out**
   - Example: spawn 3 `maks-builder` workers for 3 modules.

2. **ClawTeam creates task records**
   - One task per workstream.
   - Dependencies encoded in ClawTeam task graph.

3. **Bridge resolves template**
   - `maks-builder` template selected.
   - Model, skill inheritance, SOUL source, tool files, repo mounts resolved.

4. **Git worktree created**
   - One worktree per worker if repo-backed.
   - Branch pattern should remain isolated, e.g. `clawteam/<team>/<worker>`.

5. **OpenClaw workspace overlay created**
   - New directory per spawned worker, e.g.:
     - `/data/.openclaw/spawned/<team>/<worker>/workspace/`
   - This directory contains:
     - copied `SOUL.md`
     - copied `AGENTS.md`
     - copied `TOOLS.md`
     - selected skills or symlinked readonly skills
     - bridge manifest JSON
     - pointers to worktree path and repo path

6. **Initial prompt composed**
   - Combine:
     - template persona,
     - assigned task,
     - worktree path,
     - ClawTeam coordination protocol,
     - OpenClaw-specific reporting rules.

7. **OpenClaw session launched**
   - Use wrapper script, not raw `openclaw` command embedded directly everywhere.
   - Example wrapper responsibilities:
     - chdir into overlay workspace or worktree,
     - inject env vars,
     - point OpenClaw at copied template files,
     - tag session metadata with team/worker/template IDs.

8. **Bridge registers worker**
   - Record session ID, worktree path, template ID, ClawTeam agent name.

9. **Status mirrored both ways**
   - Worker progress goes to:
     - ClawTeam inbox/event log
     - optional OpenClaw `sessions_send` update back to leader/orchestrator

10. **Completion / failure handling**
   - On normal exit:
     - checkpoint git worktree,
     - mark task completed or blocked,
     - write summary artifact,
     - clean up according to template policy.
   - On crash:
     - mark as failed,
     - release stale locks,
     - preserve workspace for forensic review.

---

## How skills / soul / tools get copied

### Recommended strategy
Use a **workspace overlay** with mostly readonly inheritance.

#### Do not do this
- Do not copy the entire Forge or Maks workspace wholesale.
- Do not let spawned workers share the same mutable memory files.
- Do not let spawned workers write directly into parent agent identity files.

#### Do this instead
For each template:
- copy `SOUL.md`
- copy `AGENTS.md` if needed
- copy `TOOLS.md` if needed
- copy a **curated subset** of skills
- optionally symlink shared reference repos as readonly
- optionally snapshot memory into `MEMORY-SNAPSHOT.md`

### Memory policy
- For MVP: **readonly memory snapshot only**
- No live shared writable memory between spawned workers and canonical Forge/Maks memory

That avoids contamination, drift, and prompt-self-modification issues.

---

## How reporting should work

### Dual-channel reporting
A spawned OpenClaw worker should report through both:

#### 1. ClawTeam channel
For leader compatibility:
- task status updates
- inbox summary messages
- task completion / blocked states

#### 2. OpenClaw channel
For our internal agent ecosystem:
- `sessions_send` to MaksPM / ClawExpert / Forge parent context
- optional structured summary file in workspace

### Why dual channel matters
ClawTeam’s leader orchestration uses its own task/mailbox model. OpenClaw’s real value is its native multi-session ecosystem. We need both until/unless one replaces the other.

---

## How git worktree isolation should interact with OpenClaw

### Recommended model
Separate:
- **code worktree** from
- **agent overlay workspace**

#### Example
- Code worktree: `/data/.clawteam/workspaces/team-x/worker-a/`
- Agent overlay: `/data/.openclaw/spawned/team-x/worker-a/`

The overlay contains persona/skills/config. The worktree contains code.
The spawned OpenClaw agent can be launched with:
- working directory = code worktree
- template context files available from overlay

This avoids polluting code repos with agent identity files.

---

## Cleanup model

### On success
- persist summary
- checkpoint/commit
- optionally merge later via leader
- archive bridge manifest
- remove runtime session
- optionally remove overlay
- keep worktree until merge decision

### On failure
- preserve overlay + logs + worktree
- mark failure in bridge registry
- do not auto-delete evidence

### Cleanup policy should be template-driven
Example:
- `forge-reviewer`: keep logs, delete session, keep summary
- `maks-builder`: keep worktree until merge
- `research-scout`: delete ephemeral worktree if no code changes

---

## F. Template System Design

ClawTeam’s current template TOML is too shallow for our use case. It supports:
- command
- backend
- leader/agents/tasks

That is not enough to express:
- skill inheritance,
- soul inheritance,
- model policy,
- memory policy,
- repo mounts,
- cost/time caps,
- bridge runtime settings.

## Recommendation
Keep ClawTeam’s existing team template TOML for orchestration, but add an **OpenClaw agent-template TOML** layer.

### Proposed schema

```toml
[templates.maks-builder]
description = "Parallel code builder based on Maks"
base_agent = "maks"
runtime = "openclaw-local"
model = "anthropic/claude-opus-4-6"
workspace_mode = "overlay"
memory_mode = "snapshot"
startup_timeout_seconds = 45
max_runtime_minutes = 90
max_parallel = 3
max_cost_usd = 8.0
report_to = "agent:pm:telegram:direct:7474858103"

[templates.maks-builder.files]
soul = "/data/.openclaw/workspace-maks/SOUL.md"
tools = "/data/.openclaw/workspace-maks/TOOLS.md"
agent_manifest = "/data/.openclaw/workspace-maks/AGENTS.md"
user_context = "/data/.openclaw/workspace-maks/USER.md"

[templates.maks-builder.skills]
include = [
  "coding-agent",
  "agentic-planning",
  "application-blueprints",
  "auth-patterns",
  "api-design-mastery"
]
exclude = [
  "self-improving-agent"
]

[[templates.maks-builder.repos]]
path = "/data/.openclaw/workspace-forge/repos/nextjs"
mode = "readonly"
mount_as = "references/nextjs"

[[templates.maks-builder.repos]]
path = "/data/projects/current-app"
mode = "worktree"
mount_as = "project"

[templates.maks-builder.env]
allow = [
  "OPENAI_API_KEY",
  "ANTHROPIC_API_KEY",
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY"
]
map = { PROJECT_ID = "CURRENT_PROJECT_ID" }

[templates.maks-builder.resource_limits]
max_files_changed = 80
max_tokens_input = 800000
max_tokens_output = 400000
cpu_shares = 512
memory_mb = 2048

[templates.maks-builder.cleanup]
keep_worktree = true
keep_overlay = false
keep_logs = true
keep_memory_snapshot = true
```

### And for Forge

```toml
[templates.forge-reviewer]
description = "Parallel reviewer based on Forge"
base_agent = "forge"
runtime = "openclaw-local"
model = "anthropic/claude-opus-4-6"
workspace_mode = "overlay"
memory_mode = "snapshot"
startup_timeout_seconds = 45
max_runtime_minutes = 60
max_parallel = 2
max_cost_usd = 6.0
report_to = "agent:pm:telegram:direct:7474858103"

[templates.forge-reviewer.files]
soul = "/data/.openclaw/workspace-forge/SOUL.md"
tools = "/data/.openclaw/workspace-forge/TOOLS.md"
agent_manifest = "/data/.openclaw/workspace-forge/AGENTS.md"
user_context = "/data/.openclaw/workspace-forge/USER.md"

[templates.forge-reviewer.skills]
include = [
  "code-review-protocol",
  "architecture-review",
  "advanced-postgres",
  "auth-patterns",
  "accessibility-review",
  "code-generation-review"
]
exclude = []

[templates.forge-reviewer.resource_limits]
max_parallel = 2
memory_mb = 2048
max_runtime_minutes = 60

[templates.forge-reviewer.cleanup]
keep_worktree = true
keep_overlay = true
keep_logs = true
keep_memory_snapshot = true
```

---

## G. What I Would Build First (MVP)

## Smallest useful integration
**One feature only:**
> From a ClawTeam leader, spawn **one OpenClaw worker** with:
> - a git worktree,
> - a copied SOUL.md,
> - a curated skill subset,
> - and status reporting back into ClawTeam inbox.

### Why this is the MVP
It proves all the hard parts:
- template resolution
- workspace composition
- OpenClaw launch
- ClawTeam coordination compatibility
- worktree isolation
- cleanup path

### MVP scope

#### In scope
- one wrapper script: `openclaw-bridge-spawn`
- one template type: `maks-builder`
- one runtime mode: local OpenClaw session
- one repo-backed worktree
- one-way report back to ClawTeam inbox
- readonly memory snapshot

#### Out of scope
- dynamic multi-host P2P
- shared live memory
- automatic merge
- admin dashboard
- full upstream ClawTeam modifications
- security hardening beyond baseline containment

### Success criteria
If the MVP can let a leader spawn 1–2 OpenClaw builders reliably and get useful summaries back, we have proof this idea is real.

---

## H. Honest Recommendation

## Should we fork it, wrap it, or steal the ideas and build our own?

### My recommendation
**Phase 1: Wrap it**  
**Phase 2: Decide whether to fork**  
**Do not rebuild from scratch yet.**

### Why not build our own immediately?
Because ClawTeam already solved several non-trivial pieces:
- worktree lifecycle
- task graph basics
- mailbox flow
- launch templates
- tmux monitoring

Rebuilding all of that now would be slower and higher-risk than proving the concept on top of their code.

### Why not fork immediately?
Because we do not yet know whether the orchestration UX is good enough to deserve deep investment. Forking too early means inheriting maintenance burden before we validate product fit.

### Why wrapping is best
A wrapper gives us:
- fast validation,
- isolation from ClawTeam churn,
- freedom to swap ClawTeam out later,
- protection for production OpenClaw config.

---

## Final Recommendation

### GO / NO-GO
**Recommendation: GO for MVP evaluation, NO-GO for deep production integration today.**

### Build approach
1. **Do not modify production OpenClaw config**
2. **Do not let ClawTeam write into canonical agent workspaces**
3. **Build an external bridge wrapper**
4. **Use readonly snapshots for soul/skills/memory**
5. **Run only 1–2 spawned OpenClaw workers at first**
6. **Treat ClawTeam as orchestration scaffolding, not trusted control plane**

### Biggest technical risk
**The biggest risk is not code quality. It is trust boundary failure.**

If we spawn “trained” agents with real skills, memory, and secrets into a system where workers share filesystem-level access and shell execution surfaces, one bad prompt or compromised worker can become a lateral-movement problem.

That means this project is worth pursuing **only if the bridge layer enforces isolation by design**.

---

## Short Answer Version

- **Is ClawTeam good enough to learn from?** Yes.
- **Is it good enough to directly become our production orchestration core?** No.
- **Can we integrate OpenClaw without forking?** Yes, for an MVP.
- **Should we?** Yes, carefully.
- **Best path?** Wrapper first, fork later only if proven.
