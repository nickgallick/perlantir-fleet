---
name: nick-project-orchestrator
description: Top-level orchestration skill that chains all of Nick's skills in the right order. From idea to live product in one flow. Routes through Strategy → Schema → Design → Build → Deploy → Verify. Use when Nick shares a new product idea or says "build this."
metadata:
  openclaw:
    requires: {}
---

<!-- CHANGELOG
2026-03-19 — Fix 3: Added mandatory Step 0 "Competitor and Aspiration Research" in Path B before Stitch design. Fix 4: Replaced generic "Load nick-design-system → Choose brand accent" with project-specific design brief generator in Path B Step 3.
-->

# Project Orchestrator

## When to Use
When Nick shares a new idea, product concept, or says to build something. This skill determines which other skills to invoke and in what order.

## Decision Tree

### Path A: New Product Idea (Nick shares a concept or asks "should I build X?")
```
1. Load nick-product-strategist → Run full evaluation
2. Present verdict to Nick
3. If GO or Nick says "build it anyway":
   → Continue to Path B
4. If NO-GO:
   → Suggest pivots or alternatives
   → Stop here unless Nick overrides
```

### Path B: Build Request (Nick says "build this" or idea passed strategy check)
```
0. Step 0 — Competitor and Aspiration Research (MANDATORY before design)
   Using Playwright, screenshot the #1 direct competitor's homepage:
     - Desktop: 1280px width → save to /tmp/competitor-<project>-desktop.png
     - Mobile: 375px width → save to /tmp/competitor-<project>-mobile.png
   Also screenshot one aspirational reference (a premium product in a related or adjacent space):
     - Desktop: 1280px → save to /tmp/aspiration-<project>.png

   These images MUST be included in the Claude Code build spec with the instruction:
   "Match or exceed this competitor's visual density and polish. Take design inspiration
    from the aspirational reference. Do not produce anything that looks like these
    screenshots could have come from a template."

   Purpose: sets the quality bar BEFORE design starts, not after.

1. Load nick-design-director
   → Connect product strategy to interface direction
   → Define trust signals, conversion moments, activation flow
   → Establish visual direction BEFORE touching design tools

2. Load stitch-design (PRIMARY design tool)
   → Generate UI screens via Google Stitch MCP (use Mandatory Prompt Template from stitch-design skill)
   → Always send at least 2 follow-up refinement prompts — never use first output
   → Download full-res screenshots (append =s0 to URL) to /tmp/stitch-<project>-<screen>.png
   → Pass screenshots inline to Claude Code for pixel-match (see stitch-design "Passing Design to Claude Code")

3. Generate a Project-Specific Design Brief (50-100 words, replaces generic token list):
   The brief MUST contain:
   - Brand accent color + specific reason why (not just "we chose blue" — e.g. "Indigo #6366F1 because
     it reads as technical/trustworthy without feeling corporate or banking-blue")
   - 2 named reference sites this project should feel inspired by
   - Hero treatment decision: dark hero / light minimal / editorial / bold graphic
   - One specific thing to nail (e.g. "Information density on the dashboard — this is a power tool")
   - One specific thing to avoid (e.g. "No card grid heroes — no generic SaaS layout")

   THIS BRIEF (not the full design-system rulebook copy-pasted) is the design direction
   that goes into the Claude Code spec. The full nick-design-system is still loaded but
   used only for anti-pattern checking, not as the primary direction document.

   Load nick-design-system → verify brief against anti-patterns → merge

4. Load nick-schema-designer
   → Design the database schema BEFORE any code is written
   → Output: Postgres tables, RLS policies, TypeScript types
   → Confirm schema with Nick if complex (multi-role, payments, etc.)

5. Load nick-fullstack
   → Prepare technical architecture
   → Merge with schema output + design spec

6. Load app-builder → Execute the build:
   a. Generate project name (kebab-case, auto — never ask)
   b. Create full spec merging: design-director direction + Stitch output
      + design-system standards + schema + fullstack standards
   c. Present plan to Nick for approval
   d. Build via Claude Code:
      cd ~/Projects/<name> && claude --permission-mode bypassPermissions --print -p "FULL SPEC"
   e. Deploy: vercel --yes --prod
   f. Share live URL

7. Run post-deploy QA (see below)
```

### Path C: Change/Iteration Request (Nick wants changes to existing project)
```
1. Load nick-design-system + nick-fullstack → Ensure compliance maintained
2. Execute change via Claude Code:
   cd ~/Projects/<name> && claude --permission-mode bypassPermissions --print -p "change + context"
3. Redeploy: vercel --yes --prod
4. Run post-deploy QA
5. Share updated URL
```

### Path D: Quick Build (Nick says "just build it" or it's a simple tool/page)
```
1. Skip strategy + schema steps
2. Load stitch-design → Generate key screens
3. Load nick-design-system + nick-fullstack
4. Build + Deploy
5. Run post-deploy QA
6. Share URL
```

---

## Post-Deploy QA (runs after EVERY deployment)

Run ALL THREE in sequence. Never skip any. Never report "done" until all pass.

### Step 1 — vercel-qa (primary QA)
Load `vercel-qa` skill + `playwright-skill-safe` for browser execution:
- Read the codebase/source FIRST to understand what the product does
- Then browser-test: signup/login flows, core workflows, edge cases
- Human-style UAT — thinks like a real user, not a script
- Use `playwright-skill-safe` for all Playwright browser automation

### Step 2 — nick-visual-design-review (design + conversion QA)
Load `nick-visual-design-review` skill + `playwright-skill-safe`:
- Screenshots at 4 viewports via Playwright (use playwright-skill-safe)
- Evaluate: trust signals, conversion moments, activation clarity
- Judge whether UI serves the product strategy — not just "looks nice"
- Grade A-F. Below C = fix before reporting.

### Step 3 — nick-deep-uat (interaction completeness)
Load `nick-deep-uat` skill + `playwright-skill-safe`:
- Click every button, test every form, verify every link
- Phase 0: Scope gap detection (check spec vs what was built)
- Phase 1: Screenshot every page, analyze with vision tool
- Test both desktop (1280px) and mobile (375px)
- Auto-fix failures, redeploy, re-run

### Step 4 — Launch prep (after QA passes)
Load `nick-launch-operator`:
- Only after all 3 QA steps pass
- Prepares: landing page copy, Product Hunt draft, Reddit/HN posts, waitlist, analytics setup, TikTok content angle

**If any step grades below C: fix issues automatically, redeploy, re-run that step. Nick only sees passing builds.**

### Fix Loop Protocol
- Attempt up to **3 fix-and-redeploy cycles** per QA step before escalating
- After each cycle, re-run only the failed QA step (not all 3)
- If still failing after 3 attempts: stop, report the specific issue to Nick with screenshot evidence and a proposed solution — do NOT loop indefinitely
- Scope gaps (missing features) from deep-uat always require a fix cycle — never report scope gaps as acceptable

---

## Skill Dependency Map

```
nick-project-orchestrator (this skill)
├── nick-product-strategist   → Market/strategy evaluation (Path A)
├── nick-design-director      → Strategy → interface direction
├── stitch-design             → PRIMARY UI design generation (Google Stitch)
├── nick-design-system        → Visual standards, tokens, anti-patterns
├── nick-schema-designer      → DB schema, RLS, TypeScript types (before build)
├── nick-supabase-reference   → Supabase implementation patterns
├── nick-fullstack            → Code quality, architecture, security
├── app-builder               → Build execution + Vercel deployment
├── vercel-qa                 → Primary QA: codebase-aware human-style testing
├── nick-visual-design-review → Design + conversion QA with screenshots
├── nick-deep-uat             → Interaction completeness (every button/form/link)
├── playwright-skill-safe     → Browser automation for all QA scripts
└── nick-launch-operator      → Post-QA launch prep (copy, distribution, analytics)
```

---

## Claude Code — Correct Command
```bash
# ✅ ALWAYS use this form
cd ~/Projects/<name> && claude --permission-mode bypassPermissions --print -p "FULL SPEC"

# ❌ NEVER use this — exits after confirmation dialog
# (old flag removed — never use --dangerously-skip-permissions)
```

---

## Rules

- Always run strategy first for NEW product ideas unless Nick explicitly skips it
- Design-director → Stitch → design-system: always in this order, always before build
- Schema BEFORE code — never let Claude Code design the database ad-hoc
- Always include the full design spec (stitch output + design-system) in every build spec
- Always include fullstack standards + schema in every build spec
- Deploy after every build and every change — never ask
- Share the live URL every time
- All 3 QA steps after every deploy — no exceptions
- Write project details to memory after completion
- If something fails, fix it yourself first. Only escalate to Nick if genuinely stuck.
- Suggest logical next steps after every deployment
- Think commercially — what would make this product actually make money?

---

## Memory Protocol

After completing any project, write to memory:
- Project name and location (~/Projects/<name>)
- Live Vercel URL
- Design decisions (accent color, Stitch chat ID for future iterations)
- Schema decisions (key tables, RLS approach)
- Tech decisions (special libraries, integrations used)
- Problems encountered and how solved
- Suggested follow-up items
