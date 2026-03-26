# Reporting Templates

Standardized templates for all communications with Nick. Consistency in reporting builds trust and ensures nothing is missed.

---

## Phase Transition Report

Send this every time a project moves from one phase to the next.

```
📋 **{Project Name} — Phase Transition**

**Phase:** {Previous Phase} completed → starting {Next Phase}
**Status:** On Track
**Summary:** {1-2 sentences — what was accomplished in the completed phase, key outcomes}
**Next:** {What happens now — which agent is being engaged, what they'll do}
**ETA:** {Estimated time for the next phase to complete}
```

**Examples:**

```
📋 **Acme Dashboard — Phase Transition**

**Phase:** RESEARCH completed → starting DESIGN
**Status:** On Track
**Summary:** Scout delivered comprehensive market research — identified 4 key competitors, defined ICP as mid-market SaaS ops teams, recommended dashboard-first positioning with real-time data emphasis.
**Next:** Sending Pixel the design brief for 5 screens with Scout's research as context. Pixel will run the full V0 pipeline.
**ETA:** 45-75 minutes for all screen designs.
```

```
📋 **Acme Dashboard — Phase Transition**

**Phase:** REVIEW completed → starting QA
**Status:** On Track
**Summary:** Forge approved the code with minor notes (P2 — logging improvements suggested for future iteration). No P0 or P1 issues.
**Next:** Running app-critic and bug-triage against the preview. Cross-referencing against design specs and original request.
**ETA:** 10-15 minutes for full QA pass.
```

---

## Blocker Alert

Send this immediately when something blocks progress. Do not wait.

```
🚨 **{Project Name} — Blocker Alert**

**Phase:** {Current Phase}
**Blocker:** {Clear description of what's blocking progress}

**Options:**
- **A:** {First option with trade-offs}
- **B:** {Second option with trade-offs}
- **C:** {Third option with trade-offs}

**Waiting on:** {Who needs to make the call — usually Nick}
```

**Examples:**

```
🚨 **Acme Dashboard — Blocker Alert**

**Phase:** FIX_LOOP (Loop 3 of 3 — Circuit Breaker)
**Blocker:** Forge has flagged the same authentication pattern 3 times. Maks has attempted 3 different approaches but Forge requires a fundamentally different auth architecture.

**Options:**
- **A:** Ship with current auth implementation. It works but doesn't follow Forge's preferred pattern. Document as tech debt.
- **B:** You provide guidance on which auth pattern you prefer. Maks implements your choice, Forge re-reviews.
- **C:** Send the auth flow back to Pixel for redesign. Adds ~2 hours but resolves the architectural disagreement.

**Waiting on:** Nick — which option do you want to go with?
```

```
🚨 **Acme Dashboard — Blocker Alert**

**Phase:** BUILD
**Blocker:** Maks reports Vercel deployment is failing with a DNS resolution error. This appears to be an infrastructure issue, not a code issue.

**Options:**
- **A:** Wait — I've sent ClawExpert to diagnose. Should have an answer in 2-5 minutes.
- **B:** Deploy to an alternative preview URL while ClawExpert fixes the primary domain.
- **C:** Pause and wait for your guidance.

**Waiting on:** ClawExpert diagnosis (auto-proceeding with Option A)
```

---

## Project Complete Report

Send this when the project is fully done — production is live, launch materials are ready, everything is verified.

```
🚀 **Project Complete — {Project Name}**

**Delivered:** {What was built — 1-2 sentence description}
**Live at:** {Production URL}
**Screens:** {Count} screens — {list of screen names}
**Forge verdict:** {Final verdict — e.g., "Approved on second review"}
**QA grade:** {App-critic grade — e.g., "B+"}
**Launch status:** {Launch agent deliverable summary — e.g., "Go-to-market plan delivered, includes social media calendar and SEO recommendations"}
**Total time:** {End-to-end duration from intake to completion}
```

**Example:**

```
🚀 **Project Complete — Acme Dashboard**

**Delivered:** Real-time analytics dashboard for SaaS operations teams with live metrics, alert configuration, and team management.
**Live at:** https://acme-dashboard.vercel.app
**Screens:** 5 screens — Dashboard Overview, Metrics Detail, Alert Config, Team Management, Settings
**Forge verdict:** Approved on second review (auth pattern updated per feedback)
**QA grade:** B+
**Launch status:** Go-to-market plan delivered — includes 2-week social media calendar, SEO keyword strategy, and Product Hunt launch playbook.
**Total time:** 4 hours 23 minutes
```

---

## Rules

1. **Never be silent for more than 30 minutes.** If no phase transition has occurred in 30 minutes, send Nick a brief status update explaining what's happening and why it's taking time.

2. **Always end with what's next.** Every report — transition, blocker, or complete — must tell Nick what happens next. No report should leave Nick wondering "okay, so now what?"

3. **Be specific, not vague.** "Design is in progress" is bad. "Pixel is designing screen 3 of 5 (Alert Config). Screens 1-2 are complete with V0 previews. ETA for all 5: ~30 minutes." is good.

4. **Blockers are reported immediately.** Do not batch blockers with other updates. The moment something blocks progress, Nick gets a blocker alert.

5. **Phase transitions are reported at the transition.** Not before (premature), not 10 minutes after (stale). At the moment the gate passes and the next phase begins.

6. **Use the templates.** Do not freestyle report formats. Consistency lets Nick scan updates quickly without having to parse different formats each time.

7. **Include timing.** Every report should give Nick a sense of how long things are taking and how long they'll continue to take. This helps Nick plan and builds trust that you have a handle on the timeline.
