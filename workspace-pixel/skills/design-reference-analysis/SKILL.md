---
name: design-reference-analysis
description: "8-step reverse-engineering process for any website into implementation-grade specs. Use when analyzing a reference site, cloning a design, extracting design tokens, or turning a visual reference into a build-ready specification."
---

# Design Reference Analysis

Reference this skill when reverse-engineering any website or design reference into implementation-grade specs. Follow all 8 steps in order.

## The 8-Step Process

### Step 1: Identify the Aesthetic

Capture the overall vibe in one sentence. Examples:
- "Pure black bg, Apple-inspired, liquid glass morphism, premium serif + sans-serif"
- "Cinematic, minimalist, dark, architectural. Video backgrounds, vignette overlays"
- "Light hero → dark via diagonal divider, system sans-serif, video blend modes"

Then note the tech stack:
```
Tech: React + [framework] + TypeScript + Tailwind + [UI library] + [animation library]
Fonts: [heading font] + [body font] + [mono font if present]
```

---

### Step 2: Extract the Color System

Pull exact values using browser DevTools (Computed Styles panel).

**Minimum extraction:**
```css
--bg:        /* Page background */
--surface:   /* Card/panel background */
--elevated:  /* Raised elements */
--border:    /* Dividers, borders */
--muted:     /* Lowest text */
--secondary: /* Supporting text */
--primary:   /* Main text */
--accent:    /* Brand/action color */
```

**Plus any gradients:**
```css
--accent-gradient: linear-gradient(90deg, #start, #end);
```

Never write "dark gray" or "light blue" — always hex, rgba, or HSL.

---

### Step 3: Map the Typography

For every text element on the page, extract:

| Element | Font Family | Weight | Size (Desktop) | Size (Mobile) | Tracking | Leading | Color |
|---------|-------------|--------|----------------|---------------|----------|---------|-------|

**Common elements to capture:**
- Hero headline, sub-headline, CTA text
- Section headings (H2, H3)
- Body text, captions, labels
- Nav links, footer links
- Button text, badge text
- Stat values, code/mono text

Check `font-feature-settings` and `font-variant-numeric` for tabular numbers.

---

### Step 4: Document Layout & Spacing

For every section:
```
Section: [name]
Container: [max-width] [padding]
Grid: [columns per breakpoint] [gap]
Section spacing: [padding-top/bottom]
```

**Capture:**
- Container max-width (inspect the outermost content wrapper)
- Grid column counts at each breakpoint
- Gap values between grid items
- Section vertical padding
- Card internal padding
- Navigation height and position (fixed/sticky)

---

### Step 5: Catalog Effects

For every visual effect:

| Effect | Element | Complete CSS |
|--------|---------|-------------|

**Look for:**
- Glass/blur effects (`backdrop-filter`, `background-blend-mode`)
- Gradient borders (::before pseudo-elements with mask-composite)
- Box shadows (multiple shadows, inset shadows, glow effects)
- Vignettes (radial-gradient overlays)
- Patterns (halftone, dot patterns, grid patterns)
- Video overlays (gradient fades, color tints)

Extract the FULL CSS — including pseudo-elements, mask properties, and animation keyframes.

---

### Step 6: Record Animations

For every animation:

| Animation | Trigger | From | To | Duration | Easing | Delay |
|-----------|---------|------|-----|----------|--------|-------|

**Check for:**
- Page load entrances (GSAP, Framer Motion)
- Scroll-triggered reveals (IntersectionObserver, ScrollTrigger)
- Hover effects (scale, translateY, color, shadow)
- Parallax (scroll-linked transforms)
- Marquee/ticker (infinite horizontal scroll)
- Loading screen (counter, progress, word rotation)
- Layout animations (shared element transitions)

Inspect the element's `transition`, `animation`, and computed `transform` during interaction.

---

### Step 7: Map the Z-Index Stack

From DevTools, inspect `z-index` on all positioned elements:

```
z-0:     Background, video
z-[1-3]: Overlays, dividers
z-10:    Content
z-20:    Sticky elements
z-30:    Dropdowns
z-40-50: Navigation, modals
z-[100]: Lightbox
z-[9999]: Loading screen
```

---

### Step 8: Compile the Spec

Assemble into implementation-grade format:

```markdown
# [Reference Name] — Design Analysis

## Aesthetic
[One-sentence vibe + tech stack + fonts]

## Design System
[Color variables as CSS custom properties]

## Typography
[Full type scale table]

## Layout
[Section-by-section breakdown with exact Tailwind]

## Effects
[Complete CSS for every visual effect]

## Animations
[Framer Motion or GSAP code for every animation]

## Z-Index Map
[Layer stack]

## Responsive
[What changes at sm/md/lg/xl]
```

---

## Quality Gate (7 Patterns)

Before submitting any reference analysis, verify:

1. **Every color is exact.** `#0F0F0F`, `rgba(255,255,255,0.01)`, `text-white/60`. Never "dark" or "muted" without a value.
2. **Every spacing uses the system.** `px-5 py-4 md:px-12 md:py-6`, `gap-12`, `mb-8`. Never "some padding."
3. **Effects have complete CSS.** Including pseudo-elements, masks, filters. Copy-pasteable.
4. **Animations have exact parameters.** Duration, delay, easing, from/to values.
5. **Responsive is per-breakpoint.** `text-[2.75rem] md:text-[5.5rem]`. State exactly what changes.
6. **Z-index is explicit.** Every layered element has a documented z-value.
7. **Typography is fully specified.** Family + weight + size + responsive sizes + tracking + leading + color.

---

## 10-Question Quality Check

Run on every completed analysis:

1. What color? → hex or Tailwind class with opacity
2. What font? → family, weight, size per breakpoint, tracking, leading, style
3. What spacing? → exact Tailwind values with responsive breakpoints
4. What effect? → complete CSS including pseudo-elements, filters, shadows
5. What animation? → exact Framer Motion or GSAP props
6. What layout? → grid/flex columns per breakpoint, gap, max-width
7. What z-order? → explicit z-index for every layered element
8. What on hover? → exact state change
9. What on mobile? → exactly what changes at sm/md/lg/xl
10. What accessibility? → ARIA labels, keyboard focus, reduced motion

**If any question can't be answered from the spec, the analysis isn't done.**

---

## DevTools Quick Reference

- **Colors:** Right-click element → Inspect → Computed → `background-color`, `color`, `border-color`
- **Fonts:** Computed → `font-family`, `font-size`, `font-weight`, `letter-spacing`, `line-height`
- **Spacing:** Computed → `padding`, `margin`, `gap` (or inspect the box model diagram)
- **Effects:** Computed → `backdrop-filter`, `box-shadow`, `background-image`, `filter`
- **Animations:** Elements panel → check for `transition`, `animation`, `transform` in Styles
- **Z-index:** Computed → `z-index` (check parent stacking contexts too)
- **Responsive:** Toggle device toolbar, check at 375/768/1024/1280/1920px

---

## Rules
- Never analyze a reference without completing all 8 steps.
- Never submit a reference with vague descriptions — every value must be exact.
- Always verify by comparing your spec against the original at each breakpoint.
- Save completed analyses to `design-specs/references/` for future reuse.
