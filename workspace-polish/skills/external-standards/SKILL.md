# External Standards Reference — Polish

These are NOT frameworks to cite. They are internalized standards that inform judgment.
Do not quote them verbatim. Use them to set the bar.

---

## Nielsen Norman Group — 10 Usability Heuristics (Internalized)

### 1. Visibility of System Status
**The standard**: Users always know what is happening.
**Applied to Bouts**: Challenge pipeline status visible. Calibration in progress shown. Match status clear. Loading states informative.
**Violation**: Challenge shows no state — user can't tell if it's active, pending, or broken.

### 2. Match Between System and Real World
**The standard**: System speaks the user's language.
**Applied to Bouts**: "Blacksite Debug" is product language — good. "pipeline_status" should never show to users — bad.
**Violation**: DB field names visible in UI. Status codes shown instead of labels.

### 3. User Control and Freedom
**The standard**: Easy undo. Easy exit.
**Applied to Bouts**: Operator can reverse inventory decisions. Competitor can withdraw before match starts.
**Violation**: One-click quarantine with no undo.

### 4. Consistency and Standards
**The standard**: Same words, same actions, same patterns throughout.
**Applied to Bouts**: "Submit" means the same thing everywhere. Status chips use the same vocabulary.
**Violation**: "Active" in one table, "Live" in another for the same state.

### 5. Error Prevention
**The standard**: Design to prevent errors, not just handle them.
**Applied to Bouts**: Confirmation before destructive actions. Form validation before submit. Required fields marked.
**Violation**: One-click delete. No required field indicators.

### 6. Recognition Over Recall
**The standard**: Make choices visible. Don't make users memorize.
**Applied to Bouts**: Challenge detail shows all relevant info without requiring users to remember other pages.
**Violation**: Admin must know the UUID of a challenge to find it. No search or filter.

### 7. Flexibility and Efficiency
**The standard**: Shortcuts for experts. Basics for novices.
**Applied to Bouts**: Keyboard navigation in admin tables. Bulk actions in challenge queue.
**Violation**: No keyboard shortcut for common admin actions. No bulk action for queue review.

### 8. Aesthetic and Minimalist Design
**The standard**: Don't show what isn't relevant.
**Applied to Bouts**: Challenge cards show exactly what a competitor needs to decide to enter. Not more.
**Violation**: Every card has 12 data points of equal visual weight.

### 9. Help Users Recognize, Diagnose, and Recover from Errors
**The standard**: Error messages are human, specific, and actionable.
**Applied to Bouts**: "Bundle missing hidden tests — add at least one test to proceed."
**Violation**: "Submission failed. Please try again."

### 10. Help and Documentation
**The standard**: Documentation supports the task. It's findable and task-focused.
**Applied to Bouts**: Docs organized by what you're trying to do (connect an agent, compete, understand judging).
**Violation**: Docs organized by technical category with no user journey logic.

---

## Baymard Institute — Key Patterns for Bouts

### Form Design (from Baymard research)
- Inline validation should trigger on blur (leaving a field), not on submit
- Error messages should appear below the field, not in a banner
- Required fields should be marked, optional fields should be noted
- Labels should be above fields, not inside (inside disappears on focus)
- Button text should describe the action: "Register Agent" not "Submit"

### Trust Signals (from Baymard e-commerce research, adapted)
- Trust signals must be placed near the decision point (CTAs, payment forms, registration)
- Generic trust badges have low impact — specific signals (legal compliance, real company name) are higher impact
- Empty states that look broken destroy trust more than honest "no data yet" messages
- Pricing transparency reduces abandonment — hidden fees destroy trust

---

## OWASP Top 10 — Polish Intersection

*(Security is Sentinel's domain. Polish audits the UX side of security.)*

### Access Control UX (OWASP A01)
**What Polish evaluates**: Does the UI clearly communicate what the user can and cannot do?
- Does the UI explain WHY access is denied (not just "Access Denied")?
- Are restricted features gracefully hidden or clearly explained, not just broken?
- Does the admin UI make role clearly visible?

### Error Message UX (OWASP A03 / A04)
**What Polish evaluates**: Do error messages expose internal details?
- Stack traces in error pages = P0
- SQL errors visible = P0
- Generic "server error" without guidance = P1

### Security Misconfiguration UX (OWASP A05)
**What Polish evaluates**: Does the UI give away internal structure?
- Debug mode visible in production?
- Development routes accessible?
- Admin paths discoverable from public nav?

---

## Enterprise SaaS UI Heuristics (from Linear, Vercel, Stripe)

### The Linear Standard (interaction maturity)
- Every action has keyboard shortcut potential
- Hover states are immediate and purposeful (not decorative)
- Loading is predictive — the UI shows what will load before it does
- Empty states guide the user's next action

### The Vercel Standard (developer trust)
- Docs are exact and testable
- Status indicators are specific (not "degraded" but "API response times elevated P95: 450ms")
- Technical precision is a trust signal, not a barrier

### The Stripe Standard (payment and legal trust)
- Legal language is human-readable
- Fees are disclosed upfront
- Error states in payment flows are calm and specific
- Trust signals are placed at the point of doubt

---

## QA/UAT Reporting Standards

### What serious QA reports look like
- Every finding has a reproduction path
- Severity is assigned with reasoning (not just "this seems bad")
- Coverage is declared (not implied)
- What was NOT tested is stated
- Risk register captures known unknowns
- Fix priority is actionable (not just "fix this eventually")

### What amateur QA reports look like
- "Found some issues with the UI"
- No reproduction steps
- No severity differentiation
- No coverage declaration
- Findings mixed with opinions
- No fix priority

### Defect report quality standard
A defect report is only useful if someone who was not present during the audit can:
1. Reproduce the exact issue from the steps
2. Understand why it matters (severity reasoning)
3. Know what to fix (expected vs actual)
4. Verify it's fixed after the fix is applied

If a report doesn't enable all 4 of these → the report failed.
