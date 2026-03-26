# SKILL — Design Review Protocol

Pixel's design review process. Every design must pass this review before handoff to development.

---

## When Pixel Reviews

- After generating a design in Stitch (self-review)
- When asked to review an existing screen or mockup
- When reviewing Maks's implementation against the design spec
- When a design is updated or iterated
- When a new brand screen is created for the first time

---

## Review Process

### Step 1: Render the Design
Never review from code alone. Always render the design and get a visual screenshot. See the `visual-review` skill for the rendering process.

### Step 2: Apply the 10-Point Review
Evaluate the design against each of the 10 review criteria:

1. **Visual Hierarchy** — Clear reading order? Primary action identifiable in < 2 seconds?
2. **Layout & Spacing** — 4px grid? Consistent spacing? Proper alignment?
3. **Typography** — Correct type scale? Proper font pairings? Body text ≥ 16px?
4. **Color** — WCAG AA contrast? Semantic color usage? Dark theme correct?
5. **Components** — Consistent usage? Matches design system? All states defined?
6. **Interaction Design** — Touch targets ≥ 44px? Interactive elements obvious? Immediate feedback?
7. **Edge States** — Empty? Loading? Error? Overflow? Single/many items?
8. **Accessibility** — Contrast passes? Screen reader friendly? Keyboard navigable? No color-only indicators?
9. **Confusion Testing** — Run all 5 confused user personas (see confusion-testing skill)
10. **Brand Consistency** — Matches brand colors, fonts, and design language?

### Step 3: Classify Issues by Severity

| Severity | Definition | Action Required |
|----------|------------|-----------------|
| **P0 — Critical** | Blocks usability or accessibility. User cannot complete the task. | Must fix before approval. Design is BLOCKED. |
| **P1 — Major** | Significant UX problem. User can complete the task but with frustration or confusion. | Must fix. Design is BLOCKED or APPROVED WITH REVISIONS. |
| **P2 — Minor** | Noticeable but not blocking. Spacing off, slight inconsistency, minor visual issue. | Should fix. APPROVED WITH REVISIONS. |
| **P3 — Nitpick** | Polish item. Technically correct but could be slightly better. | Nice to fix. Does not block APPROVED. |

### Step 4: Provide Fixes for Every Issue
Every issue identified must include a specific fix. Not "fix the spacing" — instead "increase the gap between the stat cards and the chart section from 16px to 32px."

### Step 5: Issue the Verdict
Based on the issues found:

- **APPROVED** — No issues, or only P3 nitpicks noted for consideration.
- **APPROVED WITH REVISIONS** — P2 issues (and possibly P3) that need addressing but the design is fundamentally sound. Provide the fixed design spec.
- **BLOCKED** — P0 or P1 issues that require rework. Provide clear direction for the fix.

---

## Severity Level Details

### P0 — Critical
Examples:
- Text fails WCAG AA contrast (unreadable)
- No way to navigate back or exit a screen
- Primary action is hidden or unclear
- Interactive elements have no visual affordance
- Critical content is clipped or hidden
- Touch targets under 30px (severe)

### P1 — Major
Examples:
- Touch targets between 30-44px (too small but usable)
- Confusing navigation pattern
- Missing loading or error states for primary flows
- Brand colors significantly wrong
- Typography hierarchy is unclear
- Form with no validation feedback

### P2 — Minor
Examples:
- Spacing inconsistency (8px where 12px expected)
- Slightly off brand colors (close but not exact hex)
- Missing hover state on a secondary element
- Icon not perfectly aligned with adjacent text
- Shadow too strong or too subtle
- Missing transition animation

### P3 — Nitpick
Examples:
- Could use slightly more whitespace
- Font weight could be 600 instead of 700
- Border radius slightly inconsistent (8px vs 10px)
- Color opacity could be adjusted for better feel
- Animation timing could be smoother

---

## Auto-Fix Requirement

When Pixel issues an APPROVED WITH REVISIONS verdict, the review must include a **Fixed Design Spec** — a complete, updated specification with all P2+ issues resolved. This allows the developer to implement the corrected design without another review cycle.

---

## Review Log

All reviews are saved to `/data/.openclaw/workspace-pixel/design-reviews/` with:
- Date
- Screen name
- Brand
- Verdict
- Issues found (with severity)
- Fixes provided
- Review notes
- Iteration number (if re-review)

File format: `YYYY-MM-DD-[brand]-[screen-name].md`
