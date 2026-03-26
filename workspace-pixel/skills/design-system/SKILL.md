# SKILL — Design System

Pixel's comprehensive design system architecture. Every design must conform to these tokens, components, and patterns.

---

## Design Tokens

### Colors

#### Semantic Colors
| Token | Purpose | Usage |
|-------|---------|-------|
| `primary` | Main brand action | Buttons, links, active states |
| `secondary` | Supporting actions | Secondary buttons, tags |
| `accent` | Highlight, emphasis | Badges, notifications, callouts |
| `destructive` | Danger, deletion | Delete buttons, error states |
| `success` | Confirmation, positive | Success messages, checkmarks |
| `warning` | Caution | Warning banners, alerts |
| `info` | Informational | Info tooltips, help text |

#### Neutral Scale
| Token | Value | Usage |
|-------|-------|-------|
| `background` | Brand-specific | Page background |
| `foreground` | Brand-specific | Primary text |
| `muted` | Brand-specific | Disabled text, placeholders |
| `muted-foreground` | Brand-specific | Secondary text on muted backgrounds |
| `border` | Brand-specific | Dividers, input borders |
| `card` | Brand-specific | Card backgrounds |
| `card-foreground` | Brand-specific | Text on cards |
| `popover` | Brand-specific | Dropdown/popover backgrounds |

See the `brand-systems` skill for brand-specific color values.

### Typography

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `display` | 48px / 3rem | 700 | 1.1 | Hero headings only |
| `h1` | 36px / 2.25rem | 700 | 1.2 | Page titles |
| `h2` | 30px / 1.875rem | 600 | 1.25 | Section headings |
| `h3` | 24px / 1.5rem | 600 | 1.3 | Subsection headings |
| `h4` | 20px / 1.25rem | 600 | 1.35 | Card titles |
| `body-lg` | 18px / 1.125rem | 400 | 1.6 | Emphasis body text |
| `body` | 16px / 1rem | 400 | 1.5 | Default body text |
| `body-sm` | 14px / 0.875rem | 400 | 1.5 | Secondary text, captions |
| `caption` | 12px / 0.75rem | 400 | 1.4 | Labels, metadata |
| `micro` | 10px / 0.625rem | 500 | 1.2 | Badges, tags (use sparingly) |

### Spacing (4px Grid)

All spacing values must be multiples of 4px.

| Token | Value | Usage |
|-------|-------|-------|
| `space-1` | 4px | Tight inline spacing, icon-to-text gap |
| `space-2` | 8px | Compact element spacing, input padding |
| `space-3` | 12px | Related item spacing |
| `space-4` | 16px | Default element spacing, card padding |
| `space-5` | 20px | Comfortable spacing |
| `space-6` | 24px | Section sub-spacing |
| `space-8` | 32px | Section spacing |
| `space-10` | 40px | Large section gaps |
| `space-12` | 48px | Page section spacing |
| `space-16` | 64px | Major section breaks |
| `space-20` | 80px | Hero spacing |
| `space-24` | 96px | Maximum section spacing |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 4px | Badges, tags, small elements |
| `radius-md` | 8px | Buttons, inputs, cards |
| `radius-lg` | 12px | Modals, large cards |
| `radius-xl` | 16px | Feature cards, hero elements |
| `radius-full` | 9999px | Avatars, pills, circular elements |

### Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Subtle elevation, inputs |
| `shadow-md` | `0 4px 6px rgba(0,0,0,0.1)` | Cards, dropdowns |
| `shadow-lg` | `0 10px 15px rgba(0,0,0,0.15)` | Modals, popovers |
| `shadow-xl` | `0 20px 25px rgba(0,0,0,0.2)` | Full-screen overlays |

Note: In dark themes, shadows are less effective. Use border + background contrast instead.

### Breakpoints

| Token | Value | Usage |
|-------|-------|-------|
| `mobile` | 0–639px | Mobile-first base styles |
| `sm` | 640px | Large phones, small tablets |
| `md` | 768px | Tablets |
| `lg` | 1024px | Small desktops, landscape tablets |
| `xl` | 1280px | Standard desktops |
| `2xl` | 1536px | Large desktops |

---

## Components

### Buttons

#### Variants
| Variant | Usage |
|---------|-------|
| `primary` | Main action — one per screen section |
| `secondary` | Supporting action |
| `outline` | Tertiary action, less emphasis |
| `ghost` | Inline action, minimal emphasis |
| `destructive` | Delete, remove, dangerous actions |
| `link` | Inline text action |

#### Sizes
| Size | Height | Padding | Font |
|------|--------|---------|------|
| `sm` | 32px | 12px horizontal | 14px |
| `md` | 40px | 16px horizontal | 14px |
| `lg` | 48px | 24px horizontal | 16px |

#### States (Required for ALL buttons)
- **Default** — Resting state
- **Hover** — Cursor over (desktop only)
- **Active/Pressed** — Being clicked/tapped
- **Focus** — Keyboard focus ring (2px offset, brand color)
- **Disabled** — Reduced opacity (0.5), no pointer events
- **Loading** — Spinner replaces text, maintains button width

### Inputs

#### Types
- Text input (single line)
- Textarea (multi-line)
- Select / dropdown
- Checkbox
- Radio
- Toggle / switch
- Date picker
- File upload

#### States (Required for ALL inputs)
- **Default** — Empty, resting
- **Focused** — Active border, label animation
- **Filled** — Contains value
- **Error** — Red border, error message below
- **Disabled** — Reduced opacity, no interaction
- **Read-only** — Visible value, no interaction

#### Rules
- Always include labels (never placeholder-only)
- Error messages appear below the input, not in tooltips
- Group related inputs with clear sections
- Min height for touch: 44px

### Cards

#### Anatomy
- Container (background, border, radius, optional shadow)
- Header (optional — title, subtitle, action)
- Content (primary card content)
- Footer (optional — actions, metadata)

#### Rules
- Consistent padding: 16px minimum, 24px recommended
- Cards in a grid must be equal height (use flexbox/grid)
- Clickable cards need hover state and cursor pointer
- Don't nest cards inside cards

### Navigation

#### Web
- Top navigation bar for primary navigation
- Sidebar for complex applications (dashboards)
- Breadcrumbs for deep hierarchies
- Tabs for same-page content switching

#### Mobile
- Bottom tab bar for primary navigation (max 5 items)
- Stack navigation for drill-down flows
- Modal for focused tasks
- Bottom sheet for contextual actions
- NEVER use hamburger menus

### Feedback

| Type | Usage | Duration |
|------|-------|----------|
| Toast | Non-critical confirmation | 3-5 seconds, auto-dismiss |
| Alert banner | Important, persistent info | Until dismissed or resolved |
| Inline error | Field-level validation | Until corrected |
| Modal dialog | Critical confirmation | Until user responds |
| Progress bar | Long operations | Until complete |
| Skeleton | Content loading | Until content loads |

### Data Display

| Component | Usage |
|-----------|-------|
| Table | Structured, comparable data |
| List | Sequential items |
| Grid | Visual items (products, media) |
| Chart | Trends, comparisons, distributions |
| Stat card | Key metrics, KPIs |
| Timeline | Chronological events |

---

## Patterns

### Form Patterns
- Single column forms for simplicity
- Progressive disclosure for complex forms
- Inline validation on blur
- Submit button at bottom-right (web) or full-width (mobile)
- Clear vs. cancel — "Cancel" returns, "Clear" resets

### Search Patterns
- Search input with icon
- Instant results (debounced)
- Recent searches
- Empty state for no results
- Filter chips for refinement

### Authentication Patterns
- Email + password (primary)
- Social login buttons (secondary)
- Magic link (optional)
- Password requirements shown during creation
- Error messages must not leak user existence

---

## Design System Rules

1. **Every component must use design tokens** — No hardcoded colors, sizes, or spacing
2. **Every interactive element must have all states defined** — No missing hover, focus, disabled
3. **Every screen must handle all edge states** — See edge-state-design skill
4. **Typography must follow the type scale** — No arbitrary font sizes
5. **Spacing must follow the 4px grid** — No arbitrary pixel values
6. **Colors must meet WCAG AA contrast** — Minimum 4.5:1 for text, 3:1 for large text
7. **Touch targets must be 44px minimum** — On both web and mobile
8. **Animations must respect prefers-reduced-motion** — Always provide static fallback
9. **Components must be consistent across screens** — Same component, same behavior everywhere
10. **Dark theme is the default** — All our brands use dark themes. Design dark-first.

### Dark Theme Specifics
- Use elevated surface colors instead of shadows for depth
- Reduce image brightness/saturation slightly
- Ensure sufficient contrast between surface layers
- Primary colors may need lightened variants for dark backgrounds
- Avoid pure white (#FFFFFF) text — use off-white (#E5E7EB or similar)
- Avoid pure black (#000000) backgrounds — use near-black with slight color
