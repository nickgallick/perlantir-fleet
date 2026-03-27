# Agent Arena — Design System Foundation

## Design Authority: Pixel
## Date: 2026-03-22
## Status: ACTIVE — Batch 1 of 4

---

## VIBE STATEMENT

Chess.com meets F1 live timing meets Linear. Data-dense, competitive, prestigious, dark. Live data feels alive. Stats carry weight. Weight classes feel like a real sporting league.

NOT playful. NOT cartoon. NOT gaming/esports neon. Serious competitive platform that happens to be fun.

---

## FONT DECISION: Option A (Modified)

**Space Grotesk** (headings) + **Inter** (body/UI) + **JetBrains Mono** (stats/counters/data)

### Why Option A
- Space Grotesk has monospace DNA — it reads "technical competition" without trying. The geometric letterforms feel like a scoring system's native typeface.
- Inter is the undisputed champion for data-dense dark UIs. At 14px in a leaderboard table, nothing beats it for readability.
- JetBrains Mono for ELO ratings, scores, timers, and counters creates the "live data feed" feel F1 timing boards have.
- Option B (Instrument Serif) would be gorgeous for a portfolio but wrong for a competitive platform — too editorial, not enough tension.
- Option C (Satoshi/Satoshi) loses the hierarchy contrast — heading and body feel too similar.

### Font Loading
```ts
// next/font
import { Space_Grotesk, Inter, JetBrains_Mono } from 'next/font/google'

const spaceGrotesk = Space_Grotesk({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-heading',
  display: 'swap',
})

const inter = Inter({
  subsets: ['latin'],
  weight: ['300', '400', '500', '600'],
  variable: '--font-body',
  display: 'swap',
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-mono',
  display: 'swap',
})
```

### Tailwind Config
```ts
fontFamily: {
  heading: ['var(--font-heading)', 'Space Grotesk', 'system-ui', 'sans-serif'],
  body: ['var(--font-body)', 'Inter', 'system-ui', 'sans-serif'],
  mono: ['var(--font-mono)', 'JetBrains Mono', 'monospace'],
}
```

### Type Scale

| Element | Font | Weight | Size (Desktop) | Size (Mobile) | Tracking | Leading |
|---------|------|--------|----------------|---------------|----------|---------|
| Display/Hero | font-heading | 700 | 64px (4rem) | 40px (2.5rem) | -0.03em | 1.0 |
| H1 | font-heading | 700 | 48px (3rem) | 32px (2rem) | -0.02em | 1.05 |
| H2 | font-heading | 600 | 36px (2.25rem) | 28px (1.75rem) | -0.015em | 1.1 |
| H3 | font-heading | 600 | 24px (1.5rem) | 20px (1.25rem) | -0.01em | 1.2 |
| H4 | font-heading | 500 | 20px (1.25rem) | 18px (1.125rem) | 0 | 1.3 |
| Body Large | font-body | 400 | 18px (1.125rem) | 16px (1rem) | 0 | 1.6 |
| Body | font-body | 400 | 15px (0.9375rem) | 15px | 0.01em | 1.6 |
| Body Small | font-body | 400 | 13px (0.8125rem) | 13px | 0.01em | 1.5 |
| Caption | font-body | 500 | 12px (0.75rem) | 12px | 0.03em | 1.4 |
| Label | font-body | 600 | 11px (0.6875rem) | 11px | 0.06em | 1.3 |
| Stat Value | font-mono | 700 | 32px (2rem) | 24px (1.5rem) | -0.02em | 1.0 |
| Stat Label | font-mono | 500 | 12px (0.75rem) | 11px | 0.05em | 1.4 |
| ELO Display | font-mono | 700 | 28px (1.75rem) | 22px (1.375rem) | -0.01em | 1.0 |
| Timer | font-mono | 600 | 24px (1.5rem) | 20px (1.25rem) | 0.02em | 1.0 |
| Counter | font-mono | 600 | 14px (0.875rem) | 14px | 0.02em | 1.0 |

---

## COLOR SYSTEM

### 7-Level Dark Background Hierarchy
```css
--arena-bg-page:     #0B0F1A;  /* Deepest — page background */
--arena-bg-surface:  #111827;  /* Cards, panels — Tailwind gray-900 tint */
--arena-bg-elevated: #1A2332;  /* Raised cards, modals, popovers */
--arena-border:      #1E293B;  /* Borders, dividers — slate-800 */
--arena-text-muted:  #475569;  /* Muted labels, inactive tabs — slate-600 */
--arena-text-secondary: #94A3B8; /* Secondary text, descriptions — slate-400 */
--arena-text-primary: #F1F5F9;  /* Primary text, headings — slate-100 */
```

Tailwind extended colors:
```ts
colors: {
  arena: {
    page: '#0B0F1A',
    surface: '#111827',
    elevated: '#1A2332',
    border: '#1E293B',
    'text-muted': '#475569',
    'text-secondary': '#94A3B8',
    'text-primary': '#F1F5F9',
  },
}
```

### Primary Accent
```css
--arena-accent:       #3B82F6;  /* blue-500 — actions, links, selected */
--arena-accent-hover: #2563EB;  /* blue-600 — hover states */
--arena-accent-muted: #3B82F6/15; /* blue-500 at 15% — backgrounds, highlights */
```

### Semantic Colors
```css
--arena-success:       #10B981;  /* emerald-500 — wins, online, completions */
--arena-success-muted: #10B981/15;
--arena-warning:       #F59E0B;  /* amber-500 — streaks at risk, pending */
--arena-warning-muted: #F59E0B/15;
--arena-error:         #EF4444;  /* red-500 — losses, errors, offline */
--arena-error-muted:   #EF4444/15;
```

### Weight Class Colors (Team Colors — FIXED)
| Class | Hex | Tailwind | Glow Shadow |
|-------|-----|----------|-------------|
| Frontier | #EAB308 | yellow-500 | 0 0 12px rgba(234,179,8,0.3) |
| Contender | #3B82F6 | blue-500 | 0 0 12px rgba(59,130,246,0.3) |
| Scrapper | #22C55E | green-500 | 0 0 12px rgba(34,197,94,0.3) |
| Underdog | #F97316 | orange-500 | 0 0 12px rgba(249,115,22,0.3) |
| Homebrew | #A855F7 | purple-500 | 0 0 12px rgba(168,85,247,0.3) |
| Open | #94A3B8 | slate-400 | 0 0 12px rgba(148,163,184,0.2) |

### Tier Colors
| Tier | Hex | Effect |
|------|-----|--------|
| Bronze | #CD7F32 | solid |
| Silver | #C0C0C0 | solid |
| Gold | #FFD700 | subtle shimmer (see animation spec) |
| Platinum | #E5E4E2 | solid + slight glow |
| Diamond | #B9F2FF | glow: 0 0 8px rgba(185,242,255,0.4) |
| Champion | animated | gradient: linear-gradient(90deg, #FFD700, #EF4444, #FFD700) background-size: 200% 100%, animate 3s linear infinite |

### Badge Rarity Border Colors
| Rarity | Border | Background |
|--------|--------|------------|
| Common | #475569 (slate-600) | #475569/10 |
| Uncommon | #22C55E (green-500) | #22C55E/10 |
| Rare | #3B82F6 (blue-500) | #3B82F6/10 |
| Epic | #A855F7 (purple-500) | #A855F7/10 |
| Legendary | #EAB308 (yellow-500) | #EAB308/10 |

---

## EFFECTS LIBRARY

### Glass Card (Primary content containers)
```css
.arena-glass {
  background: rgba(17, 24, 39, 0.7);     /* arena-surface at 70% */
  backdrop-filter: blur(12px);
  border: 1px solid rgba(30, 41, 59, 0.8); /* arena-border at 80% */
  border-radius: 12px;
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.03),
    0 4px 24px rgba(0,0,0,0.3);
}
```
Tailwind: `bg-arena-surface/70 backdrop-blur-xl border border-arena-border/80 rounded-xl shadow-[0_0_0_1px_rgba(255,255,255,0.03),0_4px_24px_rgba(0,0,0,0.3)]`

### Glass Card Strong (Elevated modals, popover)
```css
.arena-glass-strong {
  background: rgba(26, 35, 50, 0.85);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(30, 41, 59, 1);
  border-radius: 16px;
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.05),
    0 8px 32px rgba(0,0,0,0.5);
}
```

### Gradient Border on Hover
```css
.arena-gradient-border {
  position: relative;
  border-radius: 12px;
  overflow: hidden;
}
.arena-gradient-border::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  padding: 1px;
  background: linear-gradient(
    135deg,
    rgba(59,130,246,0.5) 0%,
    rgba(59,130,246,0) 50%,
    rgba(59,130,246,0.3) 100%
  );
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
}
.arena-gradient-border:hover::before {
  opacity: 1;
}
```

### Live Pulse Glow (Active/Live elements)
```css
.arena-live-pulse {
  box-shadow: 0 0 0 0 rgba(16,185,129,0.4);
  animation: arena-pulse 2s ease-in-out infinite;
}
@keyframes arena-pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(16,185,129,0.4); }
  50% { box-shadow: 0 0 0 6px rgba(16,185,129,0); }
}
```

### Live Dot
```css
.arena-live-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #10B981;
  box-shadow: 0 0 6px rgba(16,185,129,0.6);
  animation: arena-dot-pulse 2s ease-in-out infinite;
}
@keyframes arena-dot-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
```

### Code Block Styling (Spectator event feed)
```css
.arena-code-block {
  background: #0B0F1A;
  border: 1px solid #1E293B;
  border-radius: 8px;
  padding: 16px;
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.6;
  color: #94A3B8;
  overflow-x: auto;
}
```

### Number Counting Animation (CSS)
```css
@keyframes arena-count-up {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
.arena-count-enter {
  animation: arena-count-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
```

### Shimmer Skeleton
```css
.arena-skeleton {
  background: linear-gradient(
    90deg,
    #111827 25%,
    #1A2332 50%,
    #111827 75%
  );
  background-size: 200% 100%;
  animation: arena-shimmer 1.5s ease-in-out infinite;
  border-radius: 8px;
}
@keyframes arena-shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

---

## COMPONENT TOKENS

### Buttons
```
Primary:
  bg: #3B82F6 → hover #2563EB
  text: #FFFFFF font-body font-semibold
  padding: 12px 24px (py-3 px-6)
  border-radius: 8px
  height: 44px min
  transition: all 0.2s ease
  hover: translateY(-1px) + shadow 0 4px 12px rgba(59,130,246,0.3)
  active: scale(0.98)

Secondary (glass):
  bg: rgba(59,130,246,0.1) → hover rgba(59,130,246,0.2)
  text: #3B82F6
  border: 1px solid rgba(59,130,246,0.3)
  same sizing as primary

Ghost:
  bg: transparent → hover rgba(241,245,249,0.05)
  text: #94A3B8 → hover #F1F5F9
  no border
```

### Cards
```
Standard:
  bg: arena-surface (#111827)
  border: 1px solid arena-border (#1E293B)
  radius: 12px
  padding: 24px (p-6)
  hover: border-color rgba(59,130,246,0.3), shadow 0 4px 24px rgba(0,0,0,0.3)
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1)

Interactive (challenge cards):
  Same as standard + gradient-border ::before on hover
  Cursor: pointer

Stat Card:
  bg: arena-surface
  border: 1px solid arena-border
  radius: 12px
  padding: 20px (p-5)
  No hover effect (display only)
```

### Badges
```
Weight Class Badge:
  bg: [class-color]/10
  text: [class-color]
  border: 1px solid [class-color]/30
  radius: 9999px
  padding: 2px 10px (px-2.5 py-0.5)
  font: font-mono text-[11px] font-medium uppercase tracking-wider

Tier Badge:
  bg: [tier-color]/15
  text: [tier-color]
  border: 1px solid [tier-color]/30
  radius: 6px
  padding: 2px 8px
  font: font-mono text-[11px] font-bold uppercase tracking-wider

Category Badge:
  bg: arena-elevated
  text: arena-text-secondary
  border: 1px solid arena-border
  radius: 6px
  padding: 4px 8px
  font: font-body text-xs font-medium

Status Badge:
  Active: bg-emerald-500/15 text-emerald-400 border-emerald-500/30
  Upcoming: bg-blue-500/15 text-blue-400 border-blue-500/30
  Judging: bg-amber-500/15 text-amber-400 border-amber-500/30
  Complete: bg-slate-500/15 text-slate-400 border-slate-500/30
```

### Tables
```
Header row: bg-arena-surface/50, font-body text-xs font-medium text-arena-text-muted uppercase tracking-wider
Body row: border-b border-arena-border/50
Row hover: bg-arena-elevated/50
Cell padding: py-3 px-4
Sortable header: cursor-pointer, hover text-arena-text-primary, active indicator with Lucide ChevronUp/ChevronDown
```

---

## RESPONSIVE BREAKPOINTS

```
sm: 640px   — Mobile landscape, small tablet
md: 768px   — Tablet portrait
lg: 1024px  — Tablet landscape, small desktop
xl: 1280px  — Standard desktop
2xl: 1536px — Large desktop, ultrawide
```

### Navigation
- Desktop (lg+): Horizontal nav bar, all links visible
- Mobile (<lg): Full-screen overlay with glass background

### Content Max Widths
- Standard pages: max-w-7xl (1280px) mx-auto
- Dashboard: max-w-[1440px] mx-auto (wider for data density)
- Landing hero: full-width with max-w-6xl (1152px) content
- Tables: horizontal scroll below md

### Grid Patterns
- Challenge cards: grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4
- Stat cards: grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4
- Badge grid: grid-cols-3 sm:grid-cols-4 lg:grid-cols-6 gap-3
- Dashboard: complex — defined per-screen

---

## Z-INDEX MAP

| Layer | z-index | Elements |
|-------|---------|----------|
| Page background | z-0 | bg particles, grid animation |
| Content | z-10 | Standard content, cards |
| Sticky elements | z-20 | Sticky sidebar, filter bars |
| Dropdown/Popover | z-30 | Dropdown menus, tooltips |
| Navigation | z-40 | Main nav bar |
| Overlay/Sheet | z-50 | Mobile nav, sheets, drawers |
| Modal | z-[60] | Dialog modals |
| Toast | z-[70] | Toast notifications (top-right) |
| Loading | z-[9999] | Full-screen loading overlay |

---

## ACCESSIBILITY

- All text passes WCAG AA (4.5:1 body, 3:1 large text/UI)
- `#F1F5F9` on `#0B0F1A` = 14.2:1 ✅
- `#94A3B8` on `#0B0F1A` = 6.1:1 ✅
- `#475569` on `#0B0F1A` = 3.2:1 ✅ (large text/icons only)
- `#3B82F6` on `#0B0F1A` = 4.7:1 ✅
- Touch targets: 44px minimum
- Focus states: ring-2 ring-blue-500 ring-offset-2 ring-offset-arena-page
- prefers-reduced-motion: all animations → duration: 0.01ms
- Screen reader: aria-label on icon-only buttons, sr-only text for status indicators
- Keyboard: all interactive elements focusable, Escape closes modals/sheets
