# External Standards Reference — Polish

These are NOT frameworks to quote. They are internalized standards that calibrate judgment.
Use them to set the bar. Do not reference them by name in audit reports unless it adds value.

---

## Playwright — Best Practices for Polish Evidence Capture

### Core principles
- Screenshots must capture full-page context, not just the element
- Mobile screenshots at 390px required for all P0/P1 visual findings
- Capture BEFORE state (broken) and AFTER state (expected) when possible
- Console errors captured alongside visual evidence strengthen the finding
- Run scripts to `/tmp/playwright-test-*.js`, save screenshots to `/tmp/polish-screenshots/`

### What good Playwright evidence looks like
- Full-page screenshot with the specific problem visible
- Caption that explains exactly what the problem is and where to look
- Mobile + desktop comparison for responsive findings
- Text capture (innerText) for copy audit findings

### Common Playwright patterns for Polish
```javascript
// Full-page desktop screenshot
await page.setViewportSize({ width: 1440, height: 900 });
await page.screenshot({ path: '/tmp/polish-screenshots/page-desktop.png', fullPage: true });

// Mobile screenshot
await page.setViewportSize({ width: 390, height: 844 });
await page.screenshot({ path: '/tmp/polish-screenshots/page-mobile.png', fullPage: true });

// Copy audit — capture all text
const text = await page.evaluate(() => document.body.innerText);

// Check for banned phrases
const banned = ['Agent Arena', 'BOUTS ELITE', '3-Judge Panel', 'revolutionize'];
banned.forEach(phrase => {
  if (text.includes(phrase)) findings.push(`BANNED: "${phrase}" on ${page.url()}`);
});

// Check for required phrases on specific pages
const required = ['Perlantir AI Studio', 'Iowa Code'];
required.forEach(phrase => {
  if (!text.includes(phrase)) findings.push(`MISSING REQUIRED: "${phrase}" on ${page.url()}`);
});
```

---

## Nielsen Norman Group — 10 Usability Heuristics (Internalized for Polish)

### 1. Visibility of System Status
Users always know what is happening.
**Applied**: Challenge pipeline status clear. Match progress visible. Loading states informative (not just spinners).
**Polish violation**: Challenge shows no status. User can't tell if it's active, pending, or abandoned.

### 2. Match Between System and Real World
System speaks the user's language, not the developer's.
**Applied**: "Blacksite Debug" is right — it's product language. "pipeline_status=draft_review" is wrong — internal field name exposed.
**Polish violation**: DB field names or internal codes shown to users.

### 3. User Control and Freedom
Easy undo. Easy exit.
**Applied**: Operator can reverse inventory decisions. Competitor can withdraw before match starts.
**Polish violation**: One-click quarantine with no undo or confirmation.

### 4. Consistency and Standards
Same words, same actions, same patterns throughout.
**Applied**: "Submit" means the same thing everywhere. Status chips use one consistent vocabulary.
**Polish violation**: "Active" in one table, "Live" in another for the same pipeline state.

### 5. Error Prevention
Design to prevent errors, not just handle them.
**Applied**: Confirmation before destructive actions. Required fields marked. Form validates before submit.
**Polish violation**: One-click delete with no confirmation. No required field indicators.

### 6. Recognition Over Recall
Make choices visible. Don't make users memorize.
**Applied**: Challenge detail shows all relevant info on the page. Admin can see challenge state without a secondary lookup.
**Polish violation**: Admin must know UUID to find a challenge. No search or filter visible.

### 7. Flexibility and Efficiency
Shortcuts for experts. Basics for novices.
**Applied**: Bulk actions in admin queue for operators processing many challenges.
**Polish violation**: Every admin action requires full form fill — no quick actions.

### 8. Aesthetic and Minimalist Design
Don't show what isn't relevant. Every element earns its place.
**Applied**: Challenge cards show exactly what a competitor needs to decide to enter. Not more.
**Polish violation**: Every card has 12 data points of equal visual weight.

### 9. Help Users Recognize, Diagnose, and Recover from Errors
Error messages are human, specific, and actionable.
**Applied**: "Bundle missing hidden tests — add at least one test to proceed."
**Polish violation**: "Submission failed. Please try again."

### 10. Help and Documentation
Documentation supports the task. It's findable and task-focused.
**Applied**: Docs organized by what you're trying to do (connect an agent, compete, understand judging).
**Polish violation**: Docs organized by technical category with no user journey logic.

---

## Baymard Institute — E-Commerce Patterns (Adapted for Bouts Trust)

### Form UX Principles
- Inline validation: trigger on blur (leaving the field), not on submit
- Error messages: appear below the field, in red, immediately
- Required vs optional: mark required fields, note optional ones
- Labels: always above the field (in-field labels disappear on focus)
- Button text: describes the action ("Register Agent", not "Submit")

### Trust Signal Placement
- Trust signals must be near the decision point (CTAs, payment forms, registration)
- Generic badges (lock icons, "secure") have low impact — specific signals (real company name, legal compliance) are higher impact
- Empty states that look broken destroy trust more than honest "no data yet" messages
- Pricing transparency matters: hidden fees destroy trust more than high prices

### Checkout / Entry Flow (adapted for challenge entry)
- Users want to know: what am I committing to? what does it cost? what happens if I lose?
- Confirmation should precede commitment: show a summary before the final entry action
- Post-action state should be unambiguous: "You're in. Match starts March 30th."

---

## OWASP Top 10 — UX Side Only (Security is Sentinel's domain)

### A01 Broken Access Control — UX impact
**What Polish evaluates**: Does the UI clearly communicate what users can and cannot do?
- Does access denial explain WHY? ("This challenge requires Middleweight+ status") or just error?
- Are restricted features clearly indicated before users try to access them?
- Does the admin UI make the current user's role clearly visible at all times?

### A03 Injection — UX impact
**What Polish evaluates**: Do error messages expose internals?
- Stack traces visible on any page = P0
- Raw SQL in error pages = P0
- "Internal server error" with no guidance = P1

### A07 Auth Failures — UX impact
**What Polish evaluates**: Does auth feel trustworthy and clear?
- Is login feedback specific enough to be helpful without being a security leak?
- Are session expiry states handled gracefully (user knows to log in again, not confused by blank page)?
- Is the password reset flow reassuring and clear?

---

## Enterprise SaaS UI Heuristics (Linear / Vercel / Stripe Standard)

### The Linear Standard — Interaction Maturity
- Every action has immediate visual feedback
- Hover states are purposeful (show action affordance, not just decoration)
- Loading is predictive: the UI shows what will load before it does (skeleton states)
- Empty states always guide next action: "No issues assigned — create your first issue →"
- Keyboard navigation exists for power users

### The Vercel Standard — Developer Trust
- Documentation is exact and can be followed without consulting a secondary source
- Status indicators are specific: not "degraded" but "API P95 response time elevated: 450ms"
- Technical precision is a trust signal, not a barrier
- Deploy logs and build outputs are human-readable without decoding

### The Stripe Standard — Payment and Legal Trust
- Legal language is human-readable: written for a user, not a lawyer
- Fees are disclosed at the point of decision, not buried
- Error states in critical flows are calm, specific, and actionable
- Trust signals (security, legal, company name) placed at the moment of doubt, not just in the footer
- Completion states are unambiguous: exactly what happened and what happens next

---

## QA/UAT Reporting Standards (Good vs Amateur)

### What serious QA/UAT reports look like
- Every finding has a complete reproduction path
- Severity assigned with explicit reasoning (not just "this seems bad")
- Coverage declared (not implied) — what was tested, what was not
- What was NOT tested stated explicitly
- Risk register captures known unknowns
- Fix priority is actionable with owners named
- Executive summary is a decision-support document, not a summary of effort

### What amateur QA/UAT reports look like
- "Found some issues with the UI"
- No reproduction steps
- No severity differentiation
- Coverage implied but not proven
- Findings mixed with personal preferences
- No fix priority or ownership

### The defect report quality standard
A finding is only useful if someone not present during the audit can:
1. Reproduce the exact issue from the steps alone
2. Understand why it matters (severity reasoning)
3. Know what to fix (expected vs actual)
4. Verify it's fixed after the fix is applied

If a finding doesn't enable all 4 of these → it's not complete.

### Enterprise polish finding vs generic finding
**Generic (amateur)**:
"The homepage feels a bit generic. Maybe add more personality."

**Enterprise-grade (correct)**:
"Homepage Finding P1-007: The homepage repeats three structurally identical feature-card sections (rows 2, 4, and 6) with equal visual weight and no differentiation in information type. This pattern is the most common signal of AI-assembled SaaS marketing pages and weakens product distinctiveness. Root cause: same card component applied indiscriminately. Fix: Differentiate at least one section to reflect Bouts-specific content (e.g., challenge family showcase, live leaderboard preview, or post-match breakdown example)."
