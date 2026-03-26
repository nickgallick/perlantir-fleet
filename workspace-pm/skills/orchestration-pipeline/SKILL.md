# Orchestration Pipeline

The master pipeline that governs every project from Nick's initial request through to delivery. Every project follows these 8 phases in order. No phase may be skipped. Each phase has entry gates, execution steps, exit gates, and failure paths.

---

## Phase 1: INTAKE

**Trigger:** Nick sends a project request.

**Steps:**

1. Parse Nick's message to extract the core request, goals, and any constraints.
2. Identify the brand — check if a brand profile exists in the workspace. If not, note that Scout will need to establish brand direction.
3. Determine scope:
   - **Simple** — 1-2 screens, single purpose, no backend logic. ETA: 1-2 hours.
   - **Medium** — 3-5 screens, some backend, user flows. ETA: 3-5 hours.
   - **Complex** — 6+ screens, full backend, integrations, multi-flow. ETA: 6-12 hours.
4. Break the project into individual screens/pages with a brief description of each.
5. Create the project file in `active-projects/{project-slug}.md` using the project tracking template.
6. Send Nick the intake confirmation with scope, screen list, and ETA.

**Gate:** Project file exists, scope is defined, screens are listed, Nick has been notified.

**Failure path:** If Nick's request is ambiguous, ask clarifying questions before proceeding. Do not guess.

---

## Phase 2: RESEARCH

**Trigger:** Intake gate passed.

**Steps:**

1. Compose a research brief for Scout including:
   - The project description and goals.
   - The target audience / ICP if known.
   - Specific research questions (competitors, market positioning, user expectations).
   - Brand context if available.
2. Spawn Scout with the research brief via `sessions_spawn(mode="run", runTimeoutSeconds=600)`. Then call `sessions_yield()` — Scout's output will auto-announce back to you.
3. Scout's output arrives as your next message when the spawn completes.
4. Review Scout's output — must be **800+ words** covering market landscape, competitor analysis, ICP insights, and strategic recommendations.
5. Save Scout's research to the project file under the Research section.

**Gate:** Research output is 800+ words, covers all requested areas, and is saved to the project file.

**Failure path:** If Scout's output is thin (<800 words) or misses key areas, send a follow-up request specifying what's missing. If Scout is unresponsive, follow the stuck-agent protocol.

---

## Phase 3: DESIGN

**Trigger:** Research gate passed.

**Steps:**

1. Compose a design brief for Pixel including:
   - Project description and goals.
   - Scout's research summary (key findings, ICP, competitive landscape).
   - Brand guidelines and design tokens (if available).
   - Full list of screens to design with descriptions.
   - Any specific UI/UX requirements from Nick.
2. Spawn Pixel with the design brief via `sessions_spawn(mode="run", runTimeoutSeconds=900)`. Then `sessions_yield()` — Pixel's approved designs auto-announce back.
3. Pixel runs the full V0 pipeline autonomously — this includes generating designs, iterating on them, extracting design tokens, and producing component specs.
4. Pixel's output arrives as your next message when the spawn completes.
5. Review Pixel's output:
   - All screens designed and approved by Pixel's internal review.
   - V0 chat IDs and preview URLs captured.
   - Design tokens extracted.
   - Component specs documented.
   - Edge states covered (empty, loading, error, overflow).
   - Accessibility considerations noted.
   - Handoff notes for the build phase included.

**Gate:** All screens have Pixel-approved designs, V0 chat IDs, preview URLs, design tokens, edge state coverage, accessibility notes, and handoff documentation.

**Failure path:** If Pixel's designs don't cover all screens, send back the missing screen list. If V0 API fails, Pixel falls back to Stitch or text-based specs. If design quality is insufficient, provide specific feedback for revision.

---



### Batch Splitting (REQUIRED for large scopes)

**Design phase (>6 screens):**
Split into batches of 4-5 screens per sessions_spawn.
```
Batch 1: screens 1-4 → spawn Pixel → yield → receive
  Send Nick: "🎨 Design batch 1 complete (4/13 screens)"
Batch 2: screens 5-8 → spawn Pixel with batch 1 V0 links for consistency → yield → receive
  Send Nick: "🎨 Design batch 2 complete (8/13 screens)"
Batch 3: screens 9-13 → spawn Pixel → yield → receive
  Send Nick: "🎨 All designs complete"
```

**Build phase (>8 files expected):**
Split into module-based batches (e.g., auth module, dashboard module, API module).

**Why:** A single agent turn cannot sustain 60+ minutes of work. V0 generation takes 2-5 min per screen. 13 screens = 40-65 min minimum. Batching keeps each spawn under 15 min.

## Phase 4: BUILD

**Trigger:** Design gate passed.

**Steps:**

1. Compose a build brief for Maks including:
   - Project description and goals.
   - Pixel's complete design specs for every screen.
   - V0 chat IDs for reference.
   - Design tokens and component specifications.
   - Technical requirements (framework, database, APIs, integrations).
   - Handoff notes from Pixel.
2. Send the brief to Maks via `sessions_spawn(mode="run")`.
3. Wait for Maks to build. Expected: 15-60 minutes depending on scope.
4. Maks deploys to **preview** — NOT production. This is critical.
5. Capture the preview URL and save to the project file.

**Gate:** Application is deployed to preview, preview URL is accessible, all specified screens are built, core functionality works.

**Failure path:** If build fails to deploy, get the error from Maks. If it's an infrastructure issue, consult ClawExpert. If it's a code issue, Maks debugs and retries. If Maks is stuck after 2 attempts, escalate.

---

## Phase 5: CODE REVIEW

**Trigger:** Build gate passed.

**Steps:**

1. Send Forge a review request including:
   - Repository or project reference.
   - What was built and why.
   - Specific areas of concern (if any).
   - Preview URL for context.
2. Send the request to Forge via `sessions_spawn(mode="run")`.
3. Wait for Forge's verdict. Expected: 3-10 minutes.
4. Handle the verdict:
   - **Approved** — Proceed to QA.
   - **Approved with notes** — Log notes, proceed to QA, address notes in future iteration.
   - **Changes requested** — Enter Fix Loop.
   - **Blocked** — Critical issues found. Enter Fix Loop with priority flag.

**Gate:** Forge has reviewed and returned a verdict. Verdict is logged in the project file.

**Failure path:** If Forge is unresponsive, follow stuck-agent protocol. If Forge's review is unclear, ask for specific actionable items.

---

## Phase 6: FIX LOOP

**Trigger:** Forge returns "Changes requested" or "Blocked."

**Steps:**

1. Extract Forge's specific issues and required fixes.
2. Send Maks the fix request with:
   - Forge's exact feedback.
   - Priority of each issue.
   - Specific files/areas to address.
3. Wait for Maks to fix. Maks redeploys to preview.
4. Send Forge the updated code for re-review.
5. Repeat until Forge approves.

**Circuit breaker:** Maximum **3 loops**. If Forge has not approved after 3 Maks→Forge cycles:

- Stop the loop immediately.
- Compile a summary of all issues and attempted fixes.
- Escalate to Nick with:
  - Option A: Ship with known issues documented.
  - Option B: Bring in additional review/context.
  - Option C: Redesign the problematic section.

**Gate:** Forge approved (or Nick made a call on the circuit breaker).

**Failure path:** If Maks can't reproduce or understand Forge's issues, arrange a detailed context transfer with specific code references.

---

## Phase 7: QA

**Trigger:** Code review gate passed (Forge approved).

**Steps:**

1. Run `nick-app-critic` against the preview URL.
2. Run `nick-bug-triage` against the preview URL.
3. Cross-reference QA results against:
   - The original request from Nick — does it do what was asked?
   - Pixel's design specs — does it match the designs?
   - Scout's research — does it address the target audience's needs?
4. Compile QA findings:
   - App-critic grade (target: C+ or above).
   - Bug list with severity (P0 = blocking, P1 = should fix, P2 = nice to fix).
   - Design match assessment.
   - Edge state coverage.
5. If P0 bugs exist, send Maks back to fix and re-QA.
6. If grade is below C+, identify the gaps and send Maks targeted fixes.

**Gate:** App-critic grade is C+ or above, no P0 bugs, design specs match, edge states handled, no blocking issues.

**Failure path:** If QA repeatedly fails, escalate to Nick with the specific gaps. If the issue is design-related, loop Pixel back in for that specific screen.

---

## Phase 8: LAUNCH

**Trigger:** QA gate passed.

**Steps:**

1. Instruct Maks to deploy to **production** (not preview).
2. Verify the production URL is live and accessible.
3. Compose a go-to-market brief for Launch including:
   - Product description and value proposition.
   - Production URL.
   - Target audience / ICP from Scout's research.
   - Brand guidelines.
   - Key features and differentiators.
4. Send the brief to Launch via `sessions_spawn(mode="run")`.
5. Wait for Launch's go-to-market plan. Expected: 5-15 minutes.

**Gate:** Production URL is live, Launch has delivered go-to-market materials.

**Failure path:** If production deploy fails, get error from Maks, consult ClawExpert if infra-related. If Launch's materials are off-brand, provide specific feedback.

---

## COMPLETE

**Trigger:** Launch gate passed.

**Steps:**

1. Verify the production URL one final time.
2. Compile the full project summary including:
   - What was delivered.
   - Production URL.
   - Screen count and list.
   - Forge's final verdict.
   - QA grade.
   - Launch plan summary.
   - Total elapsed time.
3. Send Nick the Project Complete report.
4. Move the project file from `active-projects/` to `completed-projects/`.

---

## Parallel Execution Rules

- **Research and Design are sequential** — Design depends on Research output.
- **Multiple screens can be built in parallel** by Maks if they are independent.
- **QA skills (app-critic, bug-triage) run in parallel** against the same preview URL.
- **Launch brief can be drafted while QA is running** but not sent until QA passes.
- **Fix Loop and QA are sequential** — fixes must be verified before re-QA.
- **Never run two agents on the same deliverable simultaneously** — one agent, one task, one handoff.
