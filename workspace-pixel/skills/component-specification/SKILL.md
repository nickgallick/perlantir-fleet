---
name: component-specification
description: "Component spec template with structure, states, responsive, animation, accessibility. Use when specifying any UI component — buttons, cards, badges, tables, forms, modals — to ensure every state and variant is covered."
---

# Component Specification

Reference this skill when specifying any UI component. Every component must cover: structure, states, responsive behavior, animation, and accessibility.

## Component Spec Template

```markdown
## [Component Name]

### Structure
- Container: [exact Tailwind classes]
- Inner elements: [layout, children, slots]
- Variants: [list each variant with visual diff]

### States
- Default: [exact appearance]
- Hover: [exact changes — colors, scale, shadow, border]
- Active/Pressed: [exact changes]
- Focus: [ring, outline, offset]
- Disabled: [opacity, cursor, pointer-events]
- Loading: [skeleton or spinner replacement]
- Error: [border color, message, icon]
- Empty: [placeholder content, icon, CTA]

### Responsive
- Desktop (lg+): [layout]
- Tablet (md): [changes]
- Mobile (<md): [changes]

### Animation
- Enter: [initial → animate, duration, easing]
- Hover: [whileHover props]
- Exit: [exit props if applicable]

### Accessibility
- Role: [button, link, listitem, etc.]
- aria-label: [if icon-only or non-obvious]
- Keyboard: [focusable, Enter/Space activates]
- Screen reader: [what is announced]
```

---

## Badge Component (Full Example)

### Weight Class Badge

**Structure:**
```html
<span className="inline-flex items-center gap-1 bg-[class-color]/10 text-[class-color] border border-[class-color]/30 rounded-full px-2.5 py-0.5 font-mono text-[11px] font-medium uppercase tracking-wider">
  <span className="w-1.5 h-1.5 rounded-full bg-[class-color]" />
  {className}
</span>
```

**Variants:**

| Weight Class | Color | `bg` | `text` | `border` |
|--------------|-------|------|--------|----------|
| Frontier | #EAB308 | `bg-yellow-500/10` | `text-yellow-500` | `border-yellow-500/30` |
| Contender | #3B82F6 | `bg-blue-500/10` | `text-blue-500` | `border-blue-500/30` |
| Scrapper | #22C55E | `bg-green-500/10` | `text-green-500` | `border-green-500/30` |
| Underdog | #F97316 | `bg-orange-500/10` | `text-orange-500` | `border-orange-500/30` |
| Homebrew | #A855F7 | `bg-purple-500/10` | `text-purple-500` | `border-purple-500/30` |
| Open | #94A3B8 | `bg-slate-400/10` | `text-slate-400` | `border-slate-400/30` |

**States:** Badges are display-only — no hover, focus, or disabled states needed.

**Sizes:**
- Default: `px-2.5 py-0.5 text-[11px]`
- Small: `px-2 py-0.5 text-[10px]`
- Large: `px-3 py-1 text-xs`

---

### Status Badge

**Structure:**
```html
<span className="inline-flex items-center gap-1.5 bg-[status-color]/15 text-[status-color] border border-[status-color]/30 rounded-full px-2.5 py-0.5 font-mono text-[11px] font-medium">
  {/* Optional: animated dot for "Active" */}
  {status === "active" && <span className="live-dot" />}
  {statusLabel}
</span>
```

**Variants:**

| Status | Color | Dot | Label |
|--------|-------|-----|-------|
| Active | emerald-400 | Animated pulse | "Active" |
| Upcoming | blue-400 | Static | "Upcoming" |
| Judging | amber-400 | Pulse | "Judging" |
| Complete | slate-400 | None | "Complete" |

---

### Tier Badge

**Structure:**
```html
<span className="inline-flex items-center gap-1 bg-[tier-color]/15 text-[tier-color] border border-[tier-color]/30 rounded-md px-2 py-0.5 font-mono text-[11px] font-bold uppercase tracking-wider">
  {tierName}
</span>
```

**Special tiers:**
- **Gold:** Add `shadow-[0_0_6px_rgba(255,215,0,0.2)]`
- **Diamond:** Add `shadow-[0_0_8px_rgba(185,242,255,0.4)]`
- **Champion:** Replace `bg` with animated gradient (see css-effects-library)

---

## Button Component

**Structure:**
```html
<button className="inline-flex items-center justify-center gap-2 font-body font-semibold rounded-lg transition-all duration-200">
  {icon && <Icon size={16} />}
  {label}
</button>
```

**Variants:**

| Variant | Classes |
|---------|---------|
| Primary | `bg-blue-500 text-white px-6 py-3 hover:bg-blue-600 hover:translateY(-1px) hover:shadow-[0_4px_12px_rgba(59,130,246,0.3)] active:scale-[0.98]` |
| Secondary | `bg-blue-500/10 text-blue-400 border border-blue-500/30 px-6 py-3 hover:bg-blue-500/20` |
| Ghost | `text-slate-400 px-4 py-2 hover:text-slate-100 hover:bg-white/5` |
| Destructive | `bg-red-500/10 text-red-400 border border-red-500/30 px-6 py-3 hover:bg-red-500/20` |

**Sizes:**

| Size | Height | Padding | Font |
|------|--------|---------|------|
| sm | 32px (`h-8`) | `px-3 py-1.5` | `text-xs` |
| md | 40px (`h-10`) | `px-4 py-2` | `text-sm` |
| lg | 44px (`h-11`) | `px-6 py-3` | `text-base` |

**States:**
- Disabled: `opacity-50 cursor-not-allowed pointer-events-none`
- Loading: Replace label with `<Loader2 className="animate-spin" size={16} />`
- Focus: `focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 focus-visible:ring-offset-[page-bg]`

**Minimum touch target:** 44×44px always.

---

## Card Component

**Structure:**
```html
<div className="bg-surface border border-border rounded-xl p-6 transition-all duration-300 ease-[cubic-bezier(0.4,0,0.2,1)]">
  {children}
</div>
```

**Variants:**

| Variant | Classes |
|---------|---------|
| Standard | `bg-surface border-border` |
| Glass | `bg-surface/70 backdrop-blur-xl border-border/80 shadow-[0_0_0_1px_rgba(255,255,255,0.03),0_4px_24px_rgba(0,0,0,0.3)]` |
| Interactive | Standard + `cursor-pointer hover:border-blue-500/30 hover:translateY(-2px) hover:shadow-[0_8px_32px_rgba(0,0,0,0.3)]` |
| Highlighted | `border-l-2 border-l-blue-500 bg-blue-500/5` |

**States:**
- Hover (interactive): border color change + translateY(-2px) + shadow
- Loading: Children replaced with skeleton shimmers
- Empty: Centered icon + message + CTA

---

## Form Input Component

**Structure:**
```html
<div>
  <label className="font-body text-xs text-muted uppercase tracking-wider mb-1.5 block">
    {label}
  </label>
  <input className="w-full h-10 bg-page border border-border rounded-lg px-3 py-2 font-body text-sm text-primary placeholder:text-muted transition-all duration-200 focus:border-blue-500/40 focus:ring-1 focus:ring-blue-500/20 focus:outline-none" />
  <p className="font-body text-xs text-muted mt-1">{helper}</p>
</div>
```

**States:**
- Default: `border-border`
- Focus: `border-blue-500/40 ring-1 ring-blue-500/20`
- Error: `border-red-500 ring-1 ring-red-500/20` + red helper text
- Disabled: `opacity-50 cursor-not-allowed bg-surface`

**Never use floating labels.** Always labels above inputs.

---

## Table Component

**Structure:**
```html
<div className="rounded-xl overflow-hidden border border-border">
  <div className="flex items-center h-11 bg-surface/50 border-b border-border px-4 gap-4">
    {/* Header cells: font-body text-xs text-muted uppercase tracking-wider */}
  </div>
  <div className="divide-y divide-border/30">
    {rows.map(row => (
      <div className="flex items-center h-12 px-4 gap-4 hover:bg-elevated/30 transition-colors duration-200 cursor-pointer">
        {/* Row cells */}
      </div>
    ))}
  </div>
</div>
```

**Sortable headers:** Add `cursor-pointer hover:text-primary` + ChevronUp/Down icon.

---

## Rules
- Every component spec must include ALL states (default, hover, active, focus, disabled, loading, error, empty).
- Minimum touch target: 44×44px for all interactive elements.
- Never describe states vaguely ("slightly darker"). Use exact Tailwind classes or hex values.
- Icon size matches text context: 14px for small text, 16px for body, 20px for headings, 24px for feature blocks.
- Always specify responsive behavior even if it's "no change below lg."
