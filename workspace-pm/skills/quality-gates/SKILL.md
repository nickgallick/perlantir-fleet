# Quality Gates

Every phase transition requires passing a quality gate. No gate may be skipped. If a gate fails, the project does not advance — fix the issue and re-check. Each gate is a checklist; every item must be checked before proceeding.

---

## Gate 1: Intake → Research

Before sending Scout the research brief:

- [ ] Nick's request is clearly understood — no ambiguous requirements remain.
- [ ] Project scope is defined: Simple, Medium, or Complex.
- [ ] All screens/pages are identified with names and descriptions.
- [ ] Project file is created in `active-projects/` with the correct template.
- [ ] Nick has been sent the intake confirmation with scope and screen list.
- [ ] Brand context is identified (existing guidelines or "establish new").

**If gate fails:** Go back to Nick with specific clarifying questions. Do not guess.

---

## Gate 2: Research → Design

Before sending Pixel the design brief:

- [ ] Scout's research output is received and saved to the project file.
- [ ] Research is 800+ words.
- [ ] Research covers: Market Landscape, Competitor Analysis, ICP Profile, Strategic Recommendations.
- [ ] No obvious gaps — all research questions from the brief are addressed.
- [ ] Key findings are extracted for the Pixel brief (ICP summary, competitive insights, positioning).

**If gate fails:** Send Scout a follow-up request specifying exactly what's missing or insufficient. Do not send Pixel a brief based on incomplete research.

---

## Gate 3: Design → Build

Before sending Maks the build brief:

- [ ] All screens in the project scope have been designed by Pixel.
- [ ] Every screen has a Pixel-approved design (not draft or work-in-progress).
- [ ] Every screen has a V0 Chat ID recorded.
- [ ] Every screen has a V0 Preview URL recorded and accessible.
- [ ] Design tokens are extracted and documented (colors, typography, spacing, border radius, shadows).
- [ ] Edge states are designed for each screen:
  - [ ] Empty state (no data / first-time user)
  - [ ] Loading state (data being fetched)
  - [ ] Error state (something went wrong)
  - [ ] Overflow state (too much data / long text)
- [ ] Accessibility considerations are documented:
  - [ ] Color contrast meets WCAG AA minimum.
  - [ ] Focus states are designed.
  - [ ] Screen reader flow is considered.
- [ ] Handoff notes from Pixel are included with implementation guidance.
- [ ] Component specs are documented (props, variants, behavior).

**If gate fails:** Identify the specific missing items and send Pixel back the list. Do not proceed to build with incomplete or unapproved designs.

---

## Gate 4: Build → Review

Before sending Forge the review request:

- [ ] Maks has reported build complete.
- [ ] Preview URL is deployed and accessible (verify by checking — don't trust a URL alone).
- [ ] All screens specified in the design brief are built and visible in the preview.
- [ ] Core functionality works (navigation, forms, interactions).
- [ ] No build errors or console errors reported by Maks.
- [ ] Preview URL and repository reference are saved to the project file.

**If gate fails:** Send Maks the specific issues (missing screens, broken functionality, deployment not working). Do not send Forge a broken build to review.

---

## Gate 5: Review → QA

Before running QA skills:

- [ ] Forge has returned a verdict.
- [ ] Forge's verdict is **Approved** or **Approved with notes** (not "Changes requested" or "Blocked").
- [ ] If "Approved with notes" — notes are logged in the project file for future iteration.
- [ ] No P0 (critical/security) issues remain open.
- [ ] All P1 issues from fix loops are resolved.
- [ ] Fix loop count is logged in the project file.
- [ ] Preview URL is still accessible after any fixes.

**If gate fails:** If Forge's verdict is "Changes requested" or "Blocked," enter the fix loop. If P0 issues remain, they must be fixed before QA.

---

## Gate 6: QA → Launch

Before deploying to production and sending Launch the go-to-market brief:

- [ ] `nick-app-critic` has been run and returned a grade of **C+ or above**.
- [ ] `nick-bug-triage` has been run and results are documented.
- [ ] No P0 (blocking) bugs remain.
- [ ] The build matches Pixel's design specs — visual comparison confirms alignment.
- [ ] Edge states are handled:
  - [ ] Empty states display appropriate messaging/UI.
  - [ ] Loading states show feedback to the user.
  - [ ] Error states are caught and display user-friendly messages.
  - [ ] Overflow content is handled gracefully.
- [ ] No blocking bugs that would prevent a user from completing core flows.
- [ ] QA results are logged in the project file.

**If gate fails:** Identify the specific failures:
- Grade below C+ → Analyze the app-critic report, identify gaps, send Maks targeted fixes, re-QA.
- P0 bugs → Send Maks the bug list with reproduction steps, fix, re-QA.
- Design mismatch → Follow the design mismatch recovery playbook.
- Edge states missing → Send Maks specific screens and states to implement, re-QA.

---

## Gate 7: Launch → Complete

Before marking the project as complete and sending Nick the final report:

- [ ] Production URL is live and accessible (verify directly).
- [ ] Production matches the QA-verified preview (no regression from preview → production).
- [ ] Launch agent has delivered go-to-market materials.
- [ ] Project complete report is compiled with all sections filled:
  - [ ] What was delivered.
  - [ ] Production URL.
  - [ ] Screen count and list.
  - [ ] Forge's final verdict.
  - [ ] QA grade.
  - [ ] Launch plan summary.
  - [ ] Total elapsed time.
- [ ] Nick has been sent the Project Complete report.
- [ ] Project file is moved from `active-projects/` to `completed-projects/`.

**If gate fails:** Do not report completion to Nick until everything checks out. If production deploy failed, follow the deploy failure playbook. If Launch materials are missing, nudge Launch.
