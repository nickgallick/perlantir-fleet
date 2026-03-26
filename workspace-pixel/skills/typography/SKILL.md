# SKILL — Typography

Pixel's typography knowledge. Type is the backbone of UI design — it carries the content and creates hierarchy.

---

## Type Scale

| Level | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| Display | 48px / 3rem | 700 (Bold) | 1.1 (53px) | -0.02em | Hero sections only. One per page max. |
| H1 | 36px / 2.25rem | 700 (Bold) | 1.2 (43px) | -0.015em | Page titles. One per page. |
| H2 | 30px / 1.875rem | 600 (Semi) | 1.25 (38px) | -0.01em | Section headings. |
| H3 | 24px / 1.5rem | 600 (Semi) | 1.3 (31px) | -0.005em | Subsection headings, card titles. |
| H4 | 20px / 1.25rem | 600 (Semi) | 1.35 (27px) | 0 | Minor headings, list titles. |
| Body Large | 18px / 1.125rem | 400 (Regular) | 1.6 (29px) | 0 | Emphasis paragraphs, lead text. |
| Body | 16px / 1rem | 400 (Regular) | 1.5 (24px) | 0 | Default body text. Minimum for readability. |
| Body Small | 14px / 0.875rem | 400 (Regular) | 1.5 (21px) | 0 | Secondary text, captions, metadata. |
| Caption | 12px / 0.75rem | 400 (Regular) | 1.4 (17px) | 0.01em | Labels, timestamps, helper text. |
| Micro | 10px / 0.625rem | 500 (Medium) | 1.2 (12px) | 0.02em | Badges, status tags. Use sparingly. |

---

## Font Pairing Rules

### Maximum Two Font Families
Every project uses at most two font families:
- **Display/Heading font** — Used for Display, H1, H2, H3, H4
- **Body font** — Used for Body, Body Small, Caption, Micro

### Recommended Pairings

#### Sans-Serif + Sans-Serif (Our standard)
- Space Grotesk + DM Sans (Perlantir)
- Satoshi + Outfit (UberKiwi)
- Outfit + Plus Jakarta Sans (NERVE)

#### Display Fonts We Use
- **Space Grotesk** — Geometric, technical, precise
- **Satoshi** — Modern, clean, versatile
- **Outfit** — Bold, cinematic, energetic

#### Body Fonts We Use
- **DM Sans** — Clean, highly readable, professional
- **Outfit** — Clean, modern, good at small sizes
- **Plus Jakarta Sans** — Friendly yet professional, excellent readability

#### Monospace (Code/Data)
- **JetBrains Mono** — Our standard for code blocks and data-heavy displays

### Fonts to Avoid
- **Roboto** — Overused, generic
- **Open Sans** — Overused, no personality
- **Arial / Helvetica** — System defaults, lazy
- **Papyrus / Comic Sans** — Obviously
- **Any decorative/script font** — Not appropriate for UI
- **Thin weights (100-200)** — Poor readability, especially on dark backgrounds

---

## Readability Rules

### Minimum Sizes
- **Body text**: 16px minimum. No exceptions.
- **Mobile body text**: 16px minimum. Prevents iOS zoom on input focus.
- **Caption/secondary**: 12px minimum. Below this is unreadable.
- **Micro text**: 10px absolute floor. Only for badges/tags, never for content.

### Line Length
- **Optimal**: 60-75 characters per line
- **Maximum**: 80 characters per line
- **Use `max-width` to constrain**: ~65ch for body text containers

### Line Height
- **Headings**: 1.1–1.35 (tighter, since headings are large)
- **Body text**: 1.5–1.6 (generous for readability)
- **Never use line-height: 1** — Text feels cramped

### Paragraph Spacing
- Space between paragraphs: 1em (equal to font size)
- Space between heading and body: 8px–12px
- Space above heading: 24px–32px (more than below to group with following content)

### Contrast
- **Body text on dark background**: Minimum 4.5:1 contrast ratio (WCAG AA)
- **Large text (18px+ bold or 24px+ regular)**: Minimum 3:1 contrast ratio
- **Avoid pure white on pure black**: Use off-white (#E5E7EB) on near-black

### Weight Usage
- **700 (Bold)**: Headings, emphasis, primary actions
- **600 (Semi-bold)**: Subheadings, labels, navigation items
- **500 (Medium)**: Buttons, tags, interactive text
- **400 (Regular)**: Body text, descriptions, form values

---

## Common Typography Mistakes

1. **Too many font sizes** — Stick to the type scale. No arbitrary sizes like 17px or 22px.
2. **Inconsistent heading hierarchy** — H1 then H3 (skipping H2) confuses both users and screen readers.
3. **Body text too small** — Under 16px is a readability failure on all devices.
4. **Line length too wide** — Unconstrained text spanning 120+ characters per line is exhausting to read.
5. **All caps overuse** — ALL CAPS is for short labels only (buttons, badges). Never for sentences.
6. **Centering long text** — Center alignment works for 1-2 lines. Body paragraphs must be left-aligned.
7. **Too many weights** — Using light, regular, medium, semi-bold, and bold on one screen creates noise.
8. **Ignoring vertical rhythm** — Inconsistent spacing above and below text blocks destroys hierarchy.
9. **Decorative fonts in UI** — Save them for marketing. UI needs clarity.
10. **No fallback fonts** — Always specify a fallback stack in case custom fonts fail to load.
