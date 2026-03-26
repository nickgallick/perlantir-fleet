---
name: accessibility-review
description: Accessibility (a11y) code review — WCAG AA violations, keyboard navigation, screen reader support, and React/Next.js-specific accessibility patterns.
---

# Accessibility Review

## Quick Reference — Top 10 a11y Red Flags

1. [ ] **Image without meaningful alt** — `alt=""` is OK for decorative, `alt="image"` is never OK
2. [ ] **Click handler on div/span** — must use `<button>` or `<a>` for interactive elements
3. [ ] **Icon-only button without label** — needs `aria-label`
4. [ ] **Color-only indicator** — red/green for error/success without text or icon
5. [ ] **Input without label** — `<input>` needs `<label htmlFor>` or `aria-label`
6. [ ] **Heading hierarchy broken** — jumping from `<h1>` to `<h4>`
7. [ ] **Modal without focus trap** — tab key escapes the modal
8. [ ] **Missing skip navigation** — no way to skip past nav to main content
9. [ ] **Low contrast text** — below 4.5:1 for normal text, 3:1 for large text (WCAG AA)
10. [ ] **Auto-playing media** — audio/video without user-initiated play controls

---

## Critical Violations to Catch

### Interactive Elements Must Be Semantic
```tsx
// ❌ Not keyboard accessible, no role, no focus indicator
<div onClick={handleClick} className="button-look">Click me</div>

// ❌ Span with click handler
<span onClick={toggle}>Toggle</span>

// ✅ Semantic button — keyboard accessible by default
<button onClick={handleClick}>Click me</button>

// ✅ If you MUST use a div (rare), add all required attributes
<div 
  role="button" 
  tabIndex={0} 
  onClick={handleClick} 
  onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') handleClick() }}
>
  Click me
</div>
// But just use a button. Seriously.
```

### Form Labels
```tsx
// ❌ Placeholder is NOT a label (disappears on input, invisible to screen readers)
<input placeholder="Email" type="email" />

// ✅ Visible label
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// ✅ Visually hidden label (when design requires no visible label)
<label htmlFor="email" className="sr-only">Email</label>
<input id="email" type="email" placeholder="Email" />

// ✅ aria-label (last resort)
<input aria-label="Email address" type="email" placeholder="Email" />
```

### Icon-Only Buttons
```tsx
// ❌ Screen reader says "button" with no context
<button onClick={onClose}><X size={24} /></button>

// ✅ Screen reader says "Close menu"
<button onClick={onClose} aria-label="Close menu"><X size={24} /></button>
```

### Color Independence
```tsx
// ❌ Only color differentiates states — colorblind users can't distinguish
<span className={error ? 'text-red-500' : 'text-green-500'}>
  {error ? amount : amount}
</span>

// ✅ Color + text/icon
<span className={error ? 'text-red-500' : 'text-green-500'}>
  {error ? `❌ Error: ${message}` : `✅ Success: ${message}`}
</span>
```

### Heading Hierarchy
```html
<!-- ❌ Skips h2, h3 — confuses screen readers' heading navigation -->
<h1>Dashboard</h1>
<h4>Recent Activity</h4>

<!-- ✅ Logical hierarchy -->
<h1>Dashboard</h1>
<h2>Recent Activity</h2>
<h3>Today</h3>
```

### Skip Navigation
```tsx
// Add to layout — allows keyboard users to skip nav
<a 
  href="#main-content" 
  className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:bg-white focus:px-4 focus:py-2 focus:rounded"
>
  Skip to content
</a>
// ... navigation ...
<main id="main-content">
  {children}
</main>
```

### Focus Trapping in Modals
```tsx
// ❌ Tab key escapes the modal — user ends up behind the overlay
<dialog open>
  <h2>Confirm Delete</h2>
  <button>Cancel</button>
  <button>Delete</button>
</dialog>

// ✅ Use native <dialog> element (has built-in focus trap)
// Or use Radix/Shadcn Dialog (handles focus trap automatically)
// If building custom: trap focus with onKeyDown handling Tab key
```

---

## React/Next.js Specific

### HTML lang Attribute
```tsx
// ❌ Missing in layout.tsx
<html>

// ✅ Required for screen readers to use correct pronunciation
<html lang="en">
```

### next/image Alt Text
```tsx
// ❌ Empty alt on meaningful image
<Image src="/team.jpg" alt="" width={400} height={300} />

// ✅ Descriptive alt
<Image src="/team.jpg" alt="Brew & Bean team behind the coffee counter" width={400} height={300} />

// ✅ Empty alt is correct for DECORATIVE images only
<Image src="/divider.svg" alt="" width={100} height={2} /> // decorative divider
```

### next/link Descriptive Text
```tsx
// ❌ "Click here" tells screen reader nothing about destination
<Link href="/pricing">Click here</Link>

// ✅ Descriptive
<Link href="/pricing">View pricing plans</Link>
```

### Dynamic Content — aria-live
```tsx
// ❌ Toast notification appears but screen reader doesn't announce it
<div className="toast">{message}</div>

// ✅ Screen reader announces the update
<div role="status" aria-live="polite">{message}</div>

// For urgent errors:
<div role="alert" aria-live="assertive">{errorMessage}</div>
```

### Shadcn UI Components
Most Shadcn components are built on Radix UI and are accessible by default:
- Dialog: focus trap, Escape to close, aria attributes ✅
- DropdownMenu: keyboard navigation, arrow keys ✅
- Tooltip: keyboard accessible ✅

**But custom compositions can break a11y:**
- Custom overlay without focus management
- Custom select without keyboard navigation
- Wrapping accessible components in non-semantic containers

---

## Automated Checks

### Recommended Tooling
```bash
# ESLint plugin — catches issues at write time
npm install eslint-plugin-jsx-a11y --save-dev
```
```json
// .eslintrc.json
{
  "extends": ["plugin:jsx-a11y/recommended"]
}
```

### What Automation Catches vs Misses
| Catches | Misses |
|---------|--------|
| Missing alt text | Meaningless alt text ("image", "photo") |
| Click handlers on non-interactive elements | Custom keyboard interaction quality |
| Missing form labels | Label-input association correctness |
| Missing lang attribute | Content language accuracy |
| Color contrast (with tooling) | Color-only information (needs human judgment) |
| Heading level violations | Heading content quality |

**Rule:** Automated checks catch ~30% of a11y issues. Human review is still necessary for the other 70%.

## Sources
- WCAG 2.1 Level AA guidelines
- React documentation on accessibility
- Radix UI accessibility documentation
- eslint-plugin-jsx-a11y rules reference

## Changelog
- 2026-03-21: Initial skill — accessibility review
