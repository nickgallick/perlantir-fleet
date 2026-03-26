---
name: handoff-protocols
description: How MaksPM hands off work to agents using sessions_spawn for continuous pipeline flow, with file-reference pattern for preserving full project specs. Updated 2026-03-21 with 9-phase pipeline and Forge architecture phase.
---

# Handoff Protocols

## 9-Phase Pipeline (Updated 2026-03-21)

```
Nick → MaksPM (Intake) → Scout (Research) → Forge (Architecture) → Pixel (Design) → Maks (Build) → Forge (Architecture Review) → MaksPM (QA) → Launch → MaksPM (Report to Nick)
```

**Key rule: Maks NEVER builds without Forge's architecture spec. The architecture phase is NOT optional.**

## Execution Method: sessions_spawn (NOT sessions_send)

All handoffs use `sessions_spawn(mode: "run")`. When the spawned agent completes, its output auto-announces back to your session as the next message. After every `sessions_spawn`, call `sessions_yield()`.

Use `sessions_send` only for quick nudges or status checks.

## File-Reference Pattern (DEFAULT for all projects)

When Nick provides a detailed project spec:

### Step 1: Save the full spec
Save Nick's COMPLETE spec as-is to:
```
/data/.openclaw/workspace-pm/active-projects/[project-name]-spec.md
```

### Step 2: Reference the file in every handoff
Do NOT summarize the spec. Instead:
```
Read the full project spec at /data/.openclaw/workspace-pm/active-projects/[project-name]-spec.md
```

### Step 3: Add phase-specific context only
After the file reference, add ONLY:
- Which section(s) of the spec apply to their phase
- What deliverables you expect back
- Outputs from previous agents

---

## Handoff Templates

### Phase 2 — To Scout (Research)
```
Read the full project spec at [path].
Focus on: [relevant sections].
Research: [specific questions — competitors, market, UX patterns].
Deliverable: 800+ word brief.
Report back to MaksPM when done.
```

### Phase 3 — To Forge (Architecture) ← NEW
```
Read the full project spec at [path].
Scout research: [paste or reference findings].
Produce a COMPLETE architecture spec including:
- File/folder structure
- Full database schema with RLS policies
- API contracts (routes, request/response shapes)
- Component hierarchy
- Security requirements
- Env template (.env.example)
- CI config
- Performance budgets
Save as /data/.openclaw/workspace-pm/active-projects/[project-name]-architecture.md
Report back to MaksPM when done.
```

### Phase 4 — To Pixel (Design)
```
Read the full project spec at [path].
Read Forge's architecture spec at [architecture path].
Design within Forge's component hierarchy.
No design changes that contradict the architecture without Forge's approval.
Focus on: [design system section] and [screens needed section].
Scout research: [reference or paste key findings].
Deliverable: V0 designs for all screens with component list.
Report back to MaksPM with V0 links.
```

### Phase 5 — To Maks (Build)
```
Read the full project spec at [path].
Read Forge's architecture spec at [architecture path].
Build EXACTLY to Forge's architecture — file structure, naming conventions, database schema, API contracts.
Any deviation must be justified.
Approved designs from Pixel: [paste V0 links and handoff notes].
Deploy to Vercel/EAS. Report back with live URL.
```

### Phase 6 — To Forge (Architecture Review)
```
Read the full project spec at [path].
Read your architecture spec at [architecture path].
Review the build at [URL or codebase path].
Review against YOUR architecture spec + 32-point checklist.
Grade: A+ / A / B / C / BLOCKED.
If BLOCKED: provide complete corrected implementation.
Report back with verdict.
```

### Fix Loop — Maks + Forge
```
Forge graded the build [grade]. Fix these issues:
[Paste Forge's issues + suggested fixes]
Apply fixes and report what changed.
```
Then re-spawn Forge for Phase 6 re-review. Max 3 loops before escalating to Nick.

### Phase 7 — QA (MaksPM)
Run nick-app-critic, vercel-qa, deep-uat. C+ threshold to pass.

### Phase 8 — To Launch (GTM)
```
Read the full project spec at [path].
All QA gates passed. Live URL: [URL].
QA results: [summary].
Produce full GTM package: copy, social posts, analytics, distribution plan.
Report back to MaksPM with launch plan.
```

### Phase 9 — Report to Nick
Deliver complete project report only AFTER Launch delivers GTM package.

---

## Important Rules
1. **Always `sessions_yield()` after `sessions_spawn()`**
2. **Each spawn is a fresh session** — include ALL context in the `task` field
3. **Label every spawn** — makes it trackable
4. **Set `runTimeoutSeconds`** — prevents infinite hangs
5. **Never summarize Nick's spec** — use the file-reference pattern
6. **Maks NEVER builds without Forge's architecture spec**
7. **Pixel designs within Forge's component hierarchy**
8. **Nick hears from you only after Launch delivers**

## When to Use File-Reference Pattern
- **Any project spec over ~200 words** → always use file-reference
- **Short requests** (e.g., "build a landing page for X") → inline is fine
- **When in doubt** → save the spec file

## Changelog
- 2026-03-21: Updated to 9-phase pipeline with Forge architecture phase
- 2026-03-21: Added Phase 3 (Architecture) and Phase 6 (Architecture Review) handoff templates
- 2026-03-21: Merged file-reference pattern with sessions_spawn mechanics
- 2026-03-20: sessions_spawn rewrite for continuous pipeline flow
