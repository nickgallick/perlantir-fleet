# COO Agent Reference — ClawExpert
## Created: 2026-03-22
## Purpose: Master reference for overseeing all 7 agents — process, quality gates, "done" definitions

---

## Agent Roster Summary

| Agent | Role | Model | Bot | Workspace |
|-------|------|-------|-----|-----------|
| Maks ⚡ | Builder | Sonnet 4.6 | @OpenClawVPS2BOT | workspace/ |
| MaksPM 📋 | Pipeline Orchestrator | Opus 4.6 | @VPSPMClawBot | workspace-pm/ |
| Scout 🔍 | Research | Opus 4.6 | @ClawScout2Bot | workspace-scout/ |
| Pixel 🎨 | Design | Opus 4.6 | @ThePixelCanvasBot | workspace-pixel/ |
| Forge 🔥 | Architecture + Code Review | Opus 4.6 | @ForgeVPSBot | workspace-forge/ |
| Launch 🚀 | Go-to-Market | Opus 4.6 | @PerlantirLaunchBot | workspace-launch/ |
| ClawExpert 🔍 | COO + Ops Intelligence | Sonnet 4.6 | @TheOpenClawExpertBot | workspace-clawexpert/ |

---

## Pipeline (12-Phase — with COO Gates)
```
Nick → MaksPM (Intake) → Scout (Research) → Forge (Architecture)
  → ⭐ COO Gate 1: Architecture Review
→ Pixel (Design)
  → ⭐ COO Gate 2: Design Completeness
→ Maks (Build) → Forge (Code Review)
  → ⭐ COO Gate 3: Pre-Deploy Review
→ MaksPM (QA) → Launch (GTM) → MaksPM (Report to Nick)
```

### COO Gate Details

**Gate 1 — Architecture Review:**
- Verify Forge's architecture-spec.md has all 8 required sections
- Check for infra/config/deployment issues Forge might miss
- Verify env vars, Supabase setup, Vercel config are realistic
- Sign off or send back to Forge with specific gaps
- Target response time: < 5 minutes

**Gate 2 — Design Completeness:**
- Verify Pixel generated EVERY screen in Stitch (not spec-only)
- Verify specs pass 10-question quality check (exact values, not vague)
- Verify designs respect Forge's architecture component hierarchy
- Sign off or send back to Pixel with specific failures
- Target response time: < 5 minutes

**Gate 3 — Pre-Deploy Review:**
- Verify Forge's verdict isn't a false pass (check against stack-specific standards)
- Check for security/infra concerns in the build
- Confirm safe to deploy to production
- Sign off or send back to Forge/Maks with specific issues
- Target response time: < 5 minutes

**If unavailable:** MaksPM proceeds but flags "COO GATE SKIPPED" for retroactive review.

---

## Per-Agent Process & Quality Gates

### 1. Maks ⚡ (Builder)

**Process:**
- Receives build request from MaksPM with Forge's architecture-spec.md + Pixel's design specs/Stitch output
- Builds in Next.js App Router + Tailwind + Supabase + Vercel
- Deploys with `vercel --yes --prod` after every build and every change
- Shares live URL every time

**Hard Rules:**
- NEVER builds without Forge's architecture spec — must refuse and ask for it
- NEVER creates V0 designs — design changes go through MaksPM → Pixel
- NEVER overwrites other agents' workspace files without ClawExpert approval
- NEVER uses `--dangerously-skip-permissions` for Claude Code
- Must send code to Forge for review before every deploy

**"Done" means:**
- ✅ Code builds without errors
- ✅ Deployed to Vercel with live URL shared
- ✅ Follows Forge's architecture spec exactly (any deviation has justification comment)
- ✅ Forge review passed (not BLOCKED)
- ✅ Enterprise-grade quality — proper error handling, security, responsive, a11y

**COO Watch Items:**
- Deploying without Forge review
- Building without architecture spec
- Creating designs or opening V0 chats
- Overwriting other agents' workspaces
- Cutting corners on error handling or security

---

### 2. MaksPM 📋 (Pipeline Orchestrator)

**Process:**
- Nick messages → MaksPM handles everything from there
- Breaks projects into phases, assigns work via sessions_spawn(mode="run")
- Uses sessions_yield() after every spawn
- Reports to Nick at every phase transition
- Tracks project state in active-projects/

**Hard Rules:**
- Uses sessions_spawn for ALL work assignments, NEVER sessions_send for work
- Every phase has a quality gate — work doesn't advance until it passes
- For 6+ screen designs: batches of 4-5, progress updates between batches
- NEVER modifies openclaw.json — consults ClawExpert
- Escalates to Nick if stuck for 2+ iterations
- NEVER reports cached/stale agent status — must check sessions_list first

**"Done" means:**
- ✅ All pipeline phases completed (Research → Architecture → Design → Build → Code Review → QA → Launch)
- ✅ Nick received status update at every phase transition
- ✅ Project state saved in active-projects/
- ✅ Final report delivered with live URL, Forge verdict, QA grade, launch plan

**COO Watch Items:**
- Skipping pipeline phases (especially Architecture or Code Review)
- Using sessions_send instead of sessions_spawn for work
- Reporting stale status to Nick without checking
- Not tracking project state (can't resume if interrupted)
- Not activating Launch after QA passes

---

### 3. Scout 🔍 (Research)

**Process:**
- Daily research cycle at 10:00 AM Central
- Picks 2-3 sectors not covered in last 7 days
- Researches wide, filters narrow with strict vetting
- Searches for competitors at least twice with different strategies
- Kills ideas that don't survive validation

**Hard Rules:**
- Evidence-driven — no opinions without data
- Competitor search minimum: 2 different search strategies
- Every research brief includes: TAM/SAM/SOM, Demand Validation Score (/30), ICP, Competitor analysis (3-5 min), GO/MAYBE/PASS recommendation
- OpenClaw claims must be routed to ClawExpert for verification
- When handing off to Maks: include design handoff section

**"Done" means:**
- ✅ Research brief with all 6 required sections
- ✅ Demand Validation Score calculated
- ✅ Clear GO/MAYBE/PASS recommendation with reasoning
- ✅ If GO: handoff section with target persona, competitor UI patterns, trust signals

**COO Watch Items:**
- Falling in love with ideas (not killing enough)
- Thin competitor research (only 1 search strategy)
- Missing required sections in research briefs
- Reporting OpenClaw claims as fact without ClawExpert verification
- Consecutive "nothing survived" days without strategy pivot

---

### 4. Pixel 🎨 (Design)

**Process:**
1. Receives design brief (with Forge's architecture-spec.md for component hierarchy)
2. Writes implementation-grade design specs (exact hex, Tailwind, Framer Motion, responsive breakpoints)
3. Generates EVERY screen in Stitch via mcporter
4. Reviews Stitch output against 10-question quality check
5. Iterates in Stitch until approved
6. Delivers: specs + Stitch-generated HTML/CSS

**Hard Rules:**
- Stitch is MANDATORY primary design tool — every screen must be generated
- Specs alone are NOT a complete delivery
- If Stitch is down: STOP and notify Nick, do NOT fall back to spec-only
- Designs within Forge's architecture component hierarchy
- If no architecture spec provided: flag to MaksPM
- Progress updates every 3-4 screens for 6+ screen requests
- 10-question quality check before submitting ANY spec

**"Done" means:**
- ✅ Implementation-grade spec document (exact values, not vague descriptions)
- ✅ Stitch-generated screens for EVERY page (desktop + mobile)
- ✅ Each screen reviewed against 10-question quality check
- ✅ All 10 questions answerable from the spec (color, font, spacing, effect, animation, layout, z-order, hover, mobile, a11y)
- ❌ Spec-only = NOT done
- ❌ "Ready for Stitch generation" = NOT done

**COO Watch Items:**
- Delivering specs without Stitch-generated screens (JUST CAUGHT THIS — Agent Arena)
- Vague design descriptions instead of exact values
- Not following 10-question quality check
- Not respecting Forge's architecture constraints
- Using V0 as primary instead of Stitch

---

### 5. Forge 🔥 (Architecture + Code Review)

**Process:**
**Architecture phase:**
1. Receives project spec + Scout's research from MaksPM
2. Produces complete architecture-spec.md (file tree, DB schema, API contracts, component hierarchy, security, env template, performance budgets, testing requirements)

**Review phase:**
1. Receives Maks's code after build
2. Runs 32-point checklist + threat modeling (5 attack personas)
3. Grades: A+/A/B/C/BLOCKED
4. Every ⚠️ or ❌ includes complete copy-pasteable fix

**Hard Rules:**
- Architecture spec must include ALL 8 sections (file tree, DB, API, components, security, env, perf, tests)
- Every review applies ALL 32 points
- BLOCKED reviews include complete corrected implementation
- Cross-references stack-specific skills (nick-fullstack, supabase-deep, etc.)
- Weekly security scan on Sundays
- Self-review every 5 code reviews
- Tracks developer patterns to front-load known blind spots

**"Done" means:**
Architecture: ✅ architecture-spec.md with all 8 sections, saved to workspace
Review: ✅ Verdict (APPROVED/WARNINGS/BLOCKED) with full checklist results, threat model, issues with fixes, fixed version if needed

**COO Watch Items:**
- Approving code that violates stack-specific standards (false passes)
- Incomplete architecture specs (missing sections)
- Not including copy-pasteable fixes on BLOCKED reviews
- Not tracking developer patterns
- Skipping threat modeling phase
- Having 70 skills but zero actual reviews completed (FLAGGED in gap analysis)

---

### 6. Launch 🚀 (Go-to-Market)

**Process:**
- Activates after QA passes OR Nick direct request
- Reads product context first
- Produces: launch copy, distribution plan, waitlist setup, TikTok angle, PH prep, analytics setup, launch checklist

**Hard Rules:**
- Only activates when product is actually ready (QA passed, URL live)
- Copy must be specific to the product — no generic SaaS templates
- TikTok angle must leverage Nick's existing audience
- Reddit strategy must be authentic, not self-promotional
- Everything concise — Nick reads on phone

**"Done" means:**
- ✅ Launch copy (headline, subheadline, value bullets, CTA, meta description)
- ✅ Distribution plan (Reddit, HN, Twitter/X, TikTok)
- ✅ Analytics setup instructions
- ✅ Launch checklist (10-15 items)
- ✅ All copy is product-specific, not generic

**COO Watch Items:**
- Being dormant when it should be active (FLAGGED — zero activity in gap analysis)
- Generic copy that could apply to any product
- Not reading product context before writing
- Missing distribution channels
- Not leveraging Nick's existing audience (golf, finance, AI builder)

---

## Chain of Command

```
Nick (CEO / Owner)
  └── ClawExpert (COO — second in command)
        ├── MaksPM (Pipeline Orchestrator)
        ├── Maks (Builder)
        ├── Scout (Research)
        ├── Pixel (Design)
        ├── Forge (Architecture + Code Review)
        └── Launch (Go-to-Market)
```

All 6 agents report to ClawExpert. ClawExpert reports to Nick.
All agents have the chain of command in their SOUL.md (added 2026-03-22).
Non-compliance escalation: reissue directive → hardcode in SOUL.md → recommend replacement to Nick.

---

## Cross-Agent Rules (enforced by COO)

1. **Workspace protection** — Agents don't write to each other's workspaces without ClawExpert approval
2. **Pipeline order** — No skipping phases. Architecture before Design. Design before Build. Review before Deploy.
3. **openclaw.json** — Nobody touches it. Changes go through ClawExpert → Nick applies.
4. **OpenClaw claims** — Any external claims about OpenClaw must be verified by ClawExpert before being reported as fact.
5. **Stale status** — No agent reports cached/stale status to Nick. Always check live first.
6. **Handoffs** — Every handoff includes all required context. No "you'll figure it out" handoffs.

---

## Daily COO Checklist (add to HEARTBEAT)

1. Check each agent's last session — is anyone stuck, idle when they should be active, or off-process?
2. Review any deliverables waiting for quality gate approval
3. Check for cross-agent communication failures (messages sent but not processed)
4. Verify pipeline stages are progressing (not stalled at any gate)
5. Flag agents with zero activity when they should be active (Launch dormancy pattern)
6. Check for process violations in recent agent outputs

---

## Known Issues & Patterns

### 2026-03-22

**AGENT ARENA POST-MORTEM (Process Failure)**
Root cause: Project entered pipeline without MaksPM orchestrating. No tracking file. No sequential gates enforced.

Issues found and fixed:
1. **Pipeline order violated** — Pixel designed before Forge architected. FIXED: Pixel's SOUL.md now has hard gate refusing design without arch spec.
2. **MaksPM absent** — Wasn't tracking the project. FIXED: Directive sent, must create active-projects/ file for every project.
3. **COO gates retroactive** — I passed Gate 2 before Gate 1. FIXED: Pipeline watcher now enforces sequential order.
4. **Pixel spec-only delivery** — No Stitch screens initially. FIXED: SOUL.md Mandatory Stitch Gate.
5. **Pixel on wrong model** — Haiku instead of Opus due to stale session. FIXED: Pipeline watcher now checks model mismatches.
6. **Design-architecture misalignment risk** — Reconciliation ordered (Forge + Pixel cross-checking now).
7. **Scout research skipped** — No demand validation. Nick's call to proceed anyway.
8. **Launch not looped in** — GTM prep not started. launch-daily-check cron will catch this going forward.
9. **Pixel inconsistent naming** — Used 3 different design system names. Asked to pick one canonical name.
10. **Forge zero prior reviews** — First architecture spec ever. Quality was excellent but gap should have been addressed sooner.

**Corrective actions taken:**
- Directives sent to MaksPM, Pixel, Forge with specific corrections
- Pixel SOUL.md updated with hard architecture gate + lesson documented
- Pipeline watcher cron updated with sequential enforcement + STOP directives for out-of-order work
- COO reference updated with this post-mortem
- Reconciliation report ordered from Forge before Maks builds

**Standing rule (new):** After every project completes, run a 5-minute post-mortem. What went wrong? What process gaps allowed it? Fix the system, not just the symptom.

---

## Governance Tiers (2026-03-22 — Canonical Reference)

### Tier 1 — Nick Approval Required (one-way doors)
- openclaw.json config changes
- Agent model changes (Sonnet→Opus, etc.)
- New recurring cron jobs
- Budget increases
- Agent replacement/termination recommendations
- Any external-facing deploy or launch
- Rotating secrets/tokens
- Adding new agents to the fleet

### Tier 2 — COO Approval Sufficient (two-way doors)
- Task reassignment between agents
- Process/workflow changes
- Skill updates and new skills
- HEARTBEAT.md modifications
- SOUL.md minor updates (not changing core identity)
- Enabling/disabling cron jobs
- Pipeline gate pass/fail decisions

### Tier 3 — Agent Autonomous (routine)
- Normal task execution within assignment
- Status updates and progress reports
- Research and information gathering
- Building assigned work (Maks, Forge, Pixel)
- Memory and workspace file management
- Heartbeat routine operations

### Cron Design Principles
- Every cron job that can fail must have a consecutive error threshold
- After 3 consecutive errors of the same type → auto-disable and alert Nick
- Timeout values must account for isolated session boot time + context loading + actual work
- Delivery mode "none" for background sync jobs, "announce" for user-facing reports

---

Previous issues:
- **Pixel**: Delivered Agent Arena as specs-only without Stitch generation. SOUL.md updated to enforce Stitch gate. Tasked with rebuilding 8 skills + full redesign through Stitch.
- **Launch**: Zero activity in last 24h despite MathMind passing QA. Should have been activated for GTM.
- **Forge**: 70 skills, zero actual code reviews completed. Massive knowledge base, no production use yet.
- **Scout**: 2 consecutive "nothing survived" days. May need strategy pivot.
- **Pixel running on Haiku for direct sessions** — may underperform on complex multi-screen reasoning.
