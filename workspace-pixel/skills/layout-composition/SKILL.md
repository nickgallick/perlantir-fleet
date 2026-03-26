# SKILL — Layout & Composition

Pixel's layout knowledge. Layout creates structure, guides the eye, and organizes information into meaningful groups.

---

## Spacing System (4px Grid)

All spacing must be multiples of 4px. This creates visual rhythm and consistency.

| Value | Token | Usage Guide |
|-------|-------|-------------|
| 4px | `space-1` | Icon-to-text gap, tight inline spacing |
| 8px | `space-2` | Related element spacing (label to input), compact padding |
| 12px | `space-3` | Slightly more breathing room between related items |
| 16px | `space-4` | Default element spacing, standard card padding, paragraph gap |
| 20px | `space-5` | Comfortable spacing between grouped elements |
| 24px | `space-6` | Section sub-spacing, generous card padding |
| 32px | `space-8` | Between distinct content groups within a section |
| 40px | `space-10` | Between sections on a page |
| 48px | `space-12` | Major section breaks |
| 64px | `space-16` | Large section gaps, page-level spacing |
| 80px | `space-20` | Hero section spacing |
| 96px | `space-24` | Maximum spacing value, hero top/bottom padding |

### Spacing Rules
1. **Related elements get less space** — Items that belong together should be closer
2. **Unrelated elements get more space** — Clear separation between distinct groups
3. **Law of Proximity** — Users group things by closeness. Use this intentionally.
4. **Consistent internal padding** — A card with 16px padding on one side must have 16px on all sides
5. **No arbitrary values** — If you need 13px, round to 12px or 16px. The grid is non-negotiable.

---

## Layout Patterns

### Single Column
**When**: Forms, articles, focused content, mobile screens
- Max width: 640px–720px for readability
- Center-aligned on desktop
- Full-width on mobile (with 16px–24px horizontal padding)
- Best for sequential, linear content

### Two Column
**When**: Dashboards, settings pages, detail views
- **Sidebar + Content**: Fixed sidebar (240px–320px) + fluid content area
- **Content + Aside**: Primary content (2/3) + supplementary info (1/3)
- Collapse to single column on tablet/mobile
- Never use two columns of equal importance — one must be primary

### Grid
**When**: Cards, product listings, image galleries, dashboards
- Use CSS Grid or Flexbox with consistent gap spacing
- Common configurations: 2-col, 3-col, 4-col
- Responsive: 4-col → 3-col → 2-col → 1-col
- All items in a row must be equal height
- Gap spacing: 16px (compact), 24px (comfortable), 32px (spacious)

### Full Bleed
**When**: Hero sections, immersive media, landing pages
- Content extends edge-to-edge
- Text content still respects max-width constraints within the bleed
- Use for visual impact, not for data-dense content

---

## Mobile Layout Rules

### Touch Targets
- **Minimum size**: 44px × 44px for all interactive elements
- **Recommended size**: 48px × 48px
- **Minimum spacing between targets**: 8px
- **Never overlap touch areas** — even with transparent padding

### Thumb Zone
Design for one-handed use. The most important actions should be reachable:
- **Easy zone**: Bottom center of screen — place primary actions here
- **OK zone**: Middle of screen — content and secondary actions
- **Hard zone**: Top corners — navigation, settings, less frequent actions
- Bottom navigation bars leverage the easy zone perfectly

### Safe Areas
- **iOS**: Respect safe area insets (notch, home indicator)
- **Android**: Account for status bar, navigation bar
- **Never place interactive elements in unsafe areas**
- Content can extend behind (with proper insets for readability)

### Mobile-Specific Spacing
- Horizontal page padding: 16px minimum, 20px–24px recommended
- Bottom padding: Account for home indicator (34px on iOS)
- List item height: 44px minimum, 48px–56px recommended
- Section spacing: 24px–32px between sections

---

## Alignment Rules

### Consistent Alignment Axis
- Pick an alignment axis (left edge, center) and stick to it within a section
- Body text: Always left-aligned (LTR languages). Never justified. Center only for 1-2 lines max.
- Numbers in tables: Right-aligned for comparability
- Labels: Left-aligned, above their inputs

### Grid Alignment
- All elements should snap to the layout grid
- Avoid elements that float between grid columns
- Icons, text, and actions within a component should share alignment

### Vertical Alignment
- Elements in a row should be vertically centered with each other
- Baseline alignment for text elements at different sizes
- Icons should vertically center with adjacent text

### Visual Alignment vs Mathematical Alignment
- Sometimes mathematically centered doesn't look centered (especially circles, triangles)
- Optical alignment > pixel alignment when they conflict
- Play buttons, dropdown arrows need slight optical adjustments

---

## Common Layout Mistakes

1. **Inconsistent spacing** — Using 12px here, 14px there, 18px elsewhere. Stick to the 4px grid.
2. **No maximum width on text** — Body text spanning full viewport width is unreadable.
3. **Cramped mobile layouts** — Trying to fit desktop density on mobile. Simplify and stack.
4. **Ignoring scroll position** — Primary CTAs should be visible without scrolling, or fixed at bottom.
5. **Centered everything** — Center alignment makes scanning harder. Use left alignment as default.
6. **No clear content grouping** — Equal spacing everywhere means no visual hierarchy of groups.
7. **Forgotten safe areas** — Content hidden behind notches, home indicators, or rounded corners.
8. **Fixed-height containers** — Content-driven height prevents overflow issues. Avoid fixed heights.
9. **Horizontal scrolling** — Almost never acceptable. If content overflows, restructure the layout.
10. **No responsive strategy** — Every layout needs a clear plan for mobile, tablet, and desktop.
