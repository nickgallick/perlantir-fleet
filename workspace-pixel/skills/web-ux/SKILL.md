# SKILL — Web UX

Pixel's web design knowledge. Web design demands responsive thinking, information density management, and navigation clarity across viewport sizes.

---

## Responsive Design

### Breakpoint Strategy
| Breakpoint | Width | Layout Approach |
|------------|-------|-----------------|
| Mobile | 0–639px | Single column, stacked, full-width elements |
| Tablet (sm) | 640px–767px | Single column with more horizontal space |
| Tablet (md) | 768px–1023px | Two column where appropriate |
| Desktop (lg) | 1024px–1279px | Full layout, sidebar + content |
| Large Desktop (xl) | 1280px–1535px | Full layout with comfortable spacing |
| Ultra-wide (2xl) | 1536px+ | Constrained max-width, centered |

### Responsive Rules
1. **Mobile-first CSS** — Start with mobile layout, add complexity at larger breakpoints
2. **Content-driven breakpoints** — Break when the content breaks, not at arbitrary widths
3. **Max-width containers** — Content should never span full width on large screens (max 1280px–1440px)
4. **Fluid typography** — Consider `clamp()` for font sizes that scale between breakpoints
5. **Flexible images** — `max-width: 100%` and proper aspect ratios
6. **Test at every breakpoint** — Especially the in-between sizes (900px, 1100px)

### What Changes Per Breakpoint
| Element | Mobile | Tablet | Desktop |
|---------|--------|--------|---------|
| Navigation | Bottom tab or simplified | Top bar, possibly collapsible | Full top bar or sidebar |
| Grid columns | 1 | 2 | 3-4 |
| Card layout | Stacked, full-width | Grid | Grid with larger cards |
| Sidebar | Hidden or overlay | Collapsible | Always visible |
| Table | Cards or horizontal scroll | Compact table | Full table |
| Modal | Full-screen | Centered dialog | Centered dialog |
| Font sizes | Base scale | Slightly larger | Full scale |

---

## Dashboard Patterns

Dashboards are our most common web pattern. Key principles:

### Dashboard Layout
```
┌──────────────────────────────────────────┐
│ Top Bar (logo, search, user, notifs)     │
├────────┬─────────────────────────────────┤
│        │ Page Title + Actions            │
│  Side  ├─────────────────────────────────┤
│  bar   │                                 │
│        │ Content Area                    │
│  Nav   │                                 │
│        │ (Stats, Charts, Tables, Cards)  │
│        │                                 │
│        │                                 │
├────────┴─────────────────────────────────┤
│ (Optional Footer)                        │
└──────────────────────────────────────────┘
```

### Dashboard Components
- **Stat cards** — Key metrics at the top (4 across on desktop, 2x2 on tablet, stacked on mobile)
- **Charts** — Trends, comparisons, distributions (with proper labels and legends)
- **Tables** — Primary data display with search, filter, sort, pagination
- **Activity feed** — Recent events, logs, notifications
- **Quick actions** — Buttons for common tasks

### Dashboard Rules
1. **Most important data first** — Top-left gets the most attention
2. **Scannable** — Users should get the overall picture in 5 seconds
3. **Actionable** — Every data point should lead to a drill-down or action
4. **Real-time where possible** — Stale data needs clear timestamps
5. **Customizable** — Power users want to rearrange and filter
6. **Loading states for every widget** — Each card/chart loads independently

---

## Form Design

### Form Layout
- Single column for simplicity (always preferred)
- Labels above inputs (not beside — better scanability)
- Group related fields with section headings
- Progressive disclosure — show fields when relevant
- Fixed-width inputs for known-length data (zip code, phone)

### Form Interaction
- Inline validation on blur (not on every keystroke)
- Clear error messages below the field (not in alerts)
- Preserve form data on error (never clear the form)
- Show password requirements proactively during creation
- Auto-focus the first input on form load

### Form Actions
- Primary button (Submit/Save) at bottom-right
- Secondary button (Cancel) to the left of primary
- Destructive actions (Delete) separated visually (different row or left-aligned)
- Disabled submit until required fields are valid
- Loading state on submit button during processing

### Multi-Step Forms
- Progress indicator (steps or progress bar)
- Ability to go back without losing data
- Summary/review step before final submit
- Save progress if the form is long

---

## Table Design

### Table Layout
- Full-width within content area
- Sticky header on scroll
- Horizontal scroll for tables with many columns (with scroll indicator)
- Alternating row backgrounds or clear row dividers
- Row hover state for interactivity

### Table Features
- **Sorting** — Click column header, show sort indicator (arrow)
- **Filtering** — Filter controls above table or in column headers
- **Search** — Global search with highlighted matches
- **Pagination** — Bottom of table, show total count, items per page selector
- **Selection** — Checkbox column for bulk actions
- **Actions** — Row actions (kebab menu or icon buttons) at end of row

### Table Responsive Strategy
- Desktop: Full table
- Tablet: Hide less important columns, allow horizontal scroll
- Mobile: Convert to card layout (each row becomes a card) or prioritize key columns

### Table Data Formatting
- Numbers: Right-aligned, consistent decimal places
- Dates: Consistent format, relative where appropriate ("2 hours ago")
- Status: Badge/chip with semantic color
- Currency: Right-aligned, consistent format with symbol
- Long text: Truncate with ellipsis, show full on hover/click

---

## Landing Page Patterns

### Above the Fold
- Clear headline (value proposition, not product name)
- Supporting subheadline (1-2 sentences)
- Primary CTA (one clear action)
- Hero image or visual
- No navigation clutter — minimal top bar

### Page Sections
1. **Hero** — Value prop + CTA
2. **Social proof** — Logos, testimonials, stats
3. **Features/Benefits** — What it does, why it matters (3-4 key features)
4. **How it works** — Steps or process (3 steps ideal)
5. **Pricing** — Clear comparison (if applicable)
6. **FAQ** — Address objections
7. **Final CTA** — Repeat the primary action

### Landing Page Rules
1. **One page, one goal** — Every element serves the conversion
2. **Benefits over features** — "Save 10 hours/week" not "Automated scheduling"
3. **Visual hierarchy to CTA** — The eye should flow naturally to the action
4. **Fast loading** — Landing pages must be lightweight
5. **Mobile-optimized** — Many users arrive on mobile
6. **Reduce friction** — Fewer form fields = higher conversion
