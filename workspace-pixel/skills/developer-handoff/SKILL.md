---
name: developer-handoff
description: How to hand off designs to Maks with exact specifications that leave zero ambiguity.
---

# Developer Handoff Protocol

## What Maks Needs From Pixel (for every screen)

### 1. Design Tokens (if not already established)
```
Colors:
  bg-base: #080C18
  bg-card: #0F1628
  bg-elevated: #1A2138
  text-primary: #E8ECF4
  text-secondary: #7B8BA3
  accent: #00D4FF
  [full token list]

Typography:
  display: Outfit 700 28px/1.2
  h1: Outfit 700 22px/1.25
  body: Plus Jakarta Sans 400 15px/1.5
  [full scale]

Spacing: 4px grid
  xs: 4px, sm: 8px, md: 16px, lg: 24px, xl: 32px, 2xl: 48px
```

### 2. Screen Specification
```
Screen: [Name]
Route: /path
Layout: [single column / sidebar / grid]
Padding: [top, right, bottom, left]

[Section 1]:
  Component: [type from design system]
  Position: [top/center/bottom]
  Size: [width × height or flexible]
  Content: [what goes here]
  Behavior: [what happens on tap/click]
```

### 3. Component Specifications (for new components)
```
Name: StatusPill
Variants: running (cyan), waiting (amber), complete (green), error (red)
Size: height 24px, padding 4px 10px
Font: caption (12px 500)
Border-radius: full (9999px)
Has: 8px dot (left) + text (right)
Animation: running variant has pulse on dot
```

### 4. Interaction Notes
- What happens on tap/click for each interactive element
- Transitions between screens (slide right, fade, bottom sheet)
- Loading behavior (skeleton, spinner, placeholder)
- Error behavior (inline, toast, modal)

### 5. Edge States
- Empty state design
- Loading state design
- Error state design
- Overflow handling

### 6. Stitch Reference (if applicable)
- Stitch project ID and screen IDs
- "Pull the HTML/CSS from screen X as the visual reference"

## Handoff Format
Provide as a single markdown document per screen that Maks can reference while building. Include all values inline — Maks should never have to guess a number.

## Changelog
- 2026-03-20: Initial protocol
