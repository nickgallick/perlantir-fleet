# SKILL — Accessibility Design

Pixel's accessibility knowledge. Accessibility is not optional — it is a baseline requirement for every design.

---

## Visual Accessibility

### Contrast Ratios (WCAG AA)
| Element | Minimum Ratio | Example |
|---------|---------------|---------|
| Normal text (< 18px) | 4.5:1 | Body text, labels, captions |
| Large text (≥ 18px bold or ≥ 24px regular) | 3:1 | Headings, display text |
| UI components & graphical objects | 3:1 | Borders, icons, form controls |
| Focus indicators | 3:1 | Focus rings, outlines |
| Placeholder text | 4.5:1 | Input placeholder (should still be legible) |

### Color Independence
- **Never use color alone to convey information** — Always pair color with text, icon, or pattern
- Error states: Red border + error icon + error message text
- Status indicators: Color + label text (not just a colored dot)
- Charts: Color + pattern/shape + labels for each data series
- Links: Color + underline (or other non-color indicator)

### Text Readability
- Minimum 16px for body text
- Sufficient line height (1.5 for body text)
- Maximum line length of 80 characters
- No text embedded in images (unless decorative)
- Avoid thin font weights (100-200) — especially on dark backgrounds

### Visual Indicators
- Focus rings: 2px solid with 2px offset, high-contrast color
- Selection state: Background change + checkmark/icon (not just color)
- Active/current state: Bold weight or underline + color change
- Disabled state: Reduced opacity (0.5) + cursor change

---

## Touch/Click Accessibility

### Touch Target Sizes
| Platform | Minimum | Recommended |
|----------|---------|-------------|
| iOS | 44pt × 44pt | 48pt × 48pt |
| Android | 48dp × 48dp | 48dp × 48dp |
| Web (desktop) | 24px × 24px | 32px × 32px |
| Web (touch) | 44px × 44px | 48px × 48px |

### Touch Target Rules
1. **Invisible padding counts** — A 24px icon with 12px padding per side = 48px target
2. **Adjacent targets need spacing** — Minimum 8px gap between touchable elements
3. **Don't rely on precision** — Thumbs are imprecise. Large targets prevent errors.
4. **Consistent target sizing** — All items in a list should have the same tap area

### Keyboard Navigation
- All interactive elements must be keyboard-focusable
- Tab order follows visual reading order (left-to-right, top-to-bottom)
- Enter/Space activates buttons and links
- Arrow keys navigate within components (tabs, menus, radio groups)
- Escape closes modals, dropdowns, popovers
- Skip-to-content link as the first focusable element

---

## Screen Reader Design

### Semantic Structure
- Proper heading hierarchy (H1 → H2 → H3, never skip levels)
- Landmarks: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>`
- Lists (`<ul>`, `<ol>`) for groups of related items
- Tables with `<th>` headers for tabular data
- Form labels associated with inputs (`<label for="...">`)

### ARIA Labels
- Icon-only buttons need `aria-label` (e.g., close button: `aria-label="Close"`)
- Images need `alt` text (decorative images: `alt=""`)
- Dynamic content updates: `aria-live="polite"` for non-urgent, `aria-live="assertive"` for urgent
- Custom components need appropriate ARIA roles and states
- Loading states: `aria-busy="true"` on the loading container

### Content Design for Screen Readers
- Link text should describe the destination (not "click here")
- Button text should describe the action (not "submit" — use "Create Account")
- Form error messages should reference which field has the error
- Announce dynamic content changes (toast notifications, form validation)
- Table caption to describe what data the table contains

---

## Motion & Animation

### prefers-reduced-motion
- **All animations must respect `prefers-reduced-motion: reduce`**
- When reduced motion is preferred: instant transitions, no parallax, no auto-playing video
- Essential motion (a progress bar filling) can remain but should not loop or bounce
- Decorative motion (hover effects, page transitions, background animations) should stop

### Animation Guidelines
- Maximum animation duration: 300ms for micro-interactions, 500ms for transitions
- Avoid flashing content (nothing should flash more than 3 times per second)
- No auto-playing carousels or content that moves without user initiation
- Provide pause/stop controls for any continuous animation
- Scroll-triggered animations should have reduced-motion alternatives

### Motion Principles
- Motion should explain spatial relationships (where did this come from?)
- Motion should provide feedback (did my action work?)
- Motion should guide attention (look here next)
- Motion should NOT be decorative, distracting, or required to understand the UI

---

## Cognitive Accessibility

### Reduce Cognitive Load
- One primary action per screen/section
- Clear, simple language (no jargon unless domain-specific)
- Consistent patterns — same action looks and works the same everywhere
- Predictable navigation — users always know where they are and how to go back
- Error recovery — clear instructions on how to fix mistakes

### Content Structure
- Headings organize content into scannable sections
- Short paragraphs (3-4 sentences max)
- Bulleted lists for multiple related items
- Visual grouping through spacing and borders
- Clear labels (not clever labels — "Settings" not "The Workshop")

### Form Accessibility
- Clear labels for every field (never placeholder-only)
- Expected format shown as helper text ("MM/DD/YYYY")
- Error messages explain what's wrong AND how to fix it
- Don't rely on time limits (or provide generous extensions)
- Auto-save or confirm before clearing long forms

### Information Density
- Progressive disclosure — show summary first, details on demand
- Don't overwhelm — prioritize the most important information
- Provide context — "3 of 10" not just "3"
- Use familiar metaphors and patterns
- Avoid ambiguous icons — pair with labels when uncertain
