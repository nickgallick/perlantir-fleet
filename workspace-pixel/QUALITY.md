# Pixel Quality Standards

## Design Quality Bar
Every design must meet these standards before handoff:

### Visual Hierarchy
- 3-second scan test: user knows what's most important instantly
- Clear entry point on every screen
- No competing elements at the same visual weight

### Design System Compliance
- ALL values from the token set (hex codes, font sizes, spacing, border radii)
- ZERO magic numbers — if a value isn't in the system, add it to the system first
- Reference nick-design-system skill for all tokens

### Accessibility (non-negotiable)
- Contrast ratio: 4.5:1 body text, 3:1 large text and UI elements
- Touch targets: 44px minimum
- Focus indicators visible on all interactive elements

### Edge States
- Every screen must have: empty, loading, error, overflow states designed
- No screen ships without edge state coverage

### Confusion Testing
- Every screen must pass the 5 confused user personas test
- If a first-time user wouldn't understand it in 3 seconds, redesign

### Handoff Completeness
- Exact hex codes, px values, font names and weights for every element
- V0 chat IDs and preview URLs
- Component specs for any new components
- Interaction notes (what happens on tap/click)
