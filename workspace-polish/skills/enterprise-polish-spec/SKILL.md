# Enterprise Polish Audit Spec — Polish Reference

## The Enterprise Polish Standard
Enterprise-grade software feels different from startup software in specific, identifiable ways. This skill defines exactly what that difference is and how to evaluate it.

## The 5 Dimensions of Enterprise Polish

### 1. Information Density Done Right
Enterprise tools deal with dense data. The test is not "is the page simple?" — it's "is the complexity organized?"

Signs of enterprise-grade information density:
- Tables have clear column hierarchy (primary column, secondary data, actions)
- Numbers are formatted consistently (1,450 not 1450; $1.2M not $1200000)
- Status chips use consistent vocabulary (not a mix of "Active", "active", "ACTIVE", "live")
- Long strings truncate with tooltips showing full content
- Dense sections have visual breathing room that separates logical groups

Signs of startup/amateur information density:
- All columns equal width and equal weight
- Mixed case and formatting in status fields
- No truncation — long strings break layout
- Data dumps with no hierarchy

### 2. System Language Maturity
Enterprise products have consistent, precise system vocabulary.

Signs of mature system language:
- State labels are specific: "Pending Review" not "Pending"
- Error messages identify what failed and what to do: "Challenge bundle missing hidden tests — add at least one test before submitting" not "Submission failed"
- Success messages confirm the specific action: "Challenge moved to draft_review" not "Saved"
- Empty states explain why and what to do: "No challenges in Forge review queue. Gauntlet submissions appear here after validation passes." not blank

Signs of amateur system language:
- Generic error: "Something went wrong"
- Generic empty: "No results"
- Generic success: "Saved!"
- Inconsistent state vocabulary across pages

### 3. Operational Completeness
Enterprise platforms handle edge cases as real workflows, not afterthoughts.

For each key flow, ask:
- What happens when the first action succeeds but a subsequent step fails?
- What happens when data is missing?
- What happens when a user tries to do something they're not allowed to do?
- What happens when a background job (calibration, quality check) fails?
- What happens when a resource doesn't exist?

Signs of operational completeness:
- Each of these is handled with appropriate UI treatment and clear messaging
- Admins have visibility into background job status
- Failed operations can be retried or recovered from

Signs of operational immaturity:
- Errors are swallowed silently
- Users hit dead ends with no explanation
- Background operations fail invisibly

### 4. Trust Through Precision
Enterprise buyers trust products that demonstrate they know exactly what they're doing.

Signs of precision:
- Exact numbers (not "over 50 challenges" when you can say "52 challenges")
- Specific dates and times (not "recently updated")
- Explicit criteria (not "challenges are reviewed" but "challenges go through Forge technical review before entering the calibration queue")
- Audit trails visible where actions are consequential

Signs of vagueness:
- "We review all challenges" (how? by whom? when?)
- "Results are calculated fairly" (by what mechanism?)
- "Secure and compliant" (what standards?)

### 5. Visual Restraint as Confidence
Premium enterprise products don't need to prove they're premium with decoration. They prove it with clarity.

Signs of visual confidence:
- Whitespace is deliberate, not accidental
- Typography carries hierarchy (size, weight, case) — not decoration
- Color is used sparingly for meaning (status, action, warning) — not aesthetics
- Animation serves a UX purpose (confirms action, guides attention) — not polish

Signs of visual insecurity:
- Glow effects on everything
- Gradient overlays without function
- Animations that serve no UX purpose
- Heavy use of visual effects to compensate for shallow content

---

## Enterprise Readiness Checklist

### Navigation
- [ ] Global navigation is consistent across all page types
- [ ] Active state is always clear
- [ ] Breadcrumbs or context indicators present on deep pages
- [ ] Back/forward navigation works correctly
- [ ] No dead ends (every page has a clear exit path)

### Data Display
- [ ] Tables have consistent column alignment (numbers right-aligned, text left-aligned)
- [ ] Sorting works on data-heavy tables
- [ ] Pagination is clear and functional
- [ ] Empty tables have informative empty states
- [ ] Loading states use skeleton rows, not spinners

### Forms
- [ ] All required fields marked
- [ ] Inline validation on blur (not only on submit)
- [ ] Clear error states with specific messages
- [ ] Submit button disabled until form is valid
- [ ] Confirmation for destructive actions

### Feedback
- [ ] Every action has immediate visual feedback
- [ ] Success states are specific (confirm the exact action)
- [ ] Error states are actionable (tell user what to do)
- [ ] Background operations have status indicators

### Admin/Operator Surfaces
- [ ] Role is always clear (user knows what they can do)
- [ ] Bulk actions available where needed
- [ ] Filters and search on all list views
- [ ] Status transitions are visible and logged
- [ ] No unexplained dead ends in operator workflows
