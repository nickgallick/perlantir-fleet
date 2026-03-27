# Agent Arena — Design System

## Font Selection: Option A (Space Grotesk + Inter + JetBrains Mono)

**Why Option A over B/C:**
- Space Grotesk has monospace DNA — it signals "technical platform" instantly. Perfect for a competitive AI arena where precision matters.
- Inter is the undisputed king for data-dense UIs. Tabular numbers, neutral, every weight.
- JetBrains Mono for stats/counters/ELO gives the F1 live-timing feel.
- Option B (Instrument Serif) is too editorial/luxury — wrong for competitive tech.
- Option C (Satoshi) is too SaaS/startup — lacks the technical edge.

### Font Config
```
heading: ["'Space Grotesk'", "system-ui", "sans-serif"]     // 500-700, Google Fonts
body:    ["'Inter'", "system-ui", "sans-serif"]              // variable 300-600, Google Fonts
mono:    ["'JetBrains Mono'", "'Fira Code'", "monospace"]    // 400-600, Google Fonts
```

### Typography Scale
| Element | Font | Weight | Size (mobile) | Size (md) | Size (lg+) | Tracking | Leading | Color |
|---------|------|--------|---------------|-----------|------------|----------|---------|-------|
| Display hero | Space Grotesk | 700 | text-4xl (36px) | text-6xl (60px) | text-7xl (72px) | tracking-tighter (-0.05em) | leading-[0.9] | text-white |
| Page title | Space Grotesk | 600 | text-2xl (24px) | text-3xl (30px) | text-3xl | tracking-tight (-0.025em) | leading-[1.1] | text-white |
| Section heading | Space Grotesk | 600 | text-xl (20px) | text-2xl (24px) | text-2xl | tracking-tight | leading-[1.2] | text-white |
| Card title | Inter | 600 | text-base (16px) | text-base | text-base | tracking-normal | leading-[1.4] | text-white |
| Body | Inter | 400 | text-sm (14px) | text-sm | text-sm | tracking-normal | leading-[1.5] | text-[#8B8FA3] |
| Body small | Inter | 400 | text-xs (12px) | text-xs | text-xs | tracking-normal | leading-[1.5] | text-[#6B7084] |
| Label/overline | Inter | 600 | text-xs (12px) | text-xs | text-xs | tracking-[0.08em] | leading-[1] | text-[#6B7084] |
| Stat number | JetBrains Mono | 600 | text-2xl (24px) | text-3xl (30px) | text-4xl (36px) | tracking-tight | leading-[1] | text-white |
| Stat small | JetBrains Mono | 500 | text-sm (14px) | text-sm | text-sm | tracking-normal | leading-[1] | text-white |
| ELO display | JetBrains Mono | 700 | text-xl (20px) | text-2xl (24px) | text-2xl | tracking-tight | leading-[1] | text-white |
| Timer/countdown | JetBrains Mono | 600 | text-xl (20px) | text-2xl (24px) | text-3xl (30px) | tracking-tight | leading-[1] | text-white |
| Code blocks | JetBrains Mono | 400 | text-xs (12px) | text-xs | text-sm (14px) | tracking-normal | leading-[1.6] | text-[#E2E8F0] |

---

## Color System

### Background Hierarchy (7 levels)
| Level | Name | Value | Tailwind | Use |
|-------|------|-------|----------|-----|
| 0 | Page bg | #09090B | bg-[#09090B] | Page background, deepest layer |
| 1 | Surface | #0F1117 | bg-[#0F1117] | Cards, panels, sidebar |
| 2 | Elevated | #161922 | bg-[#161922] | Raised cards, modals, dropdowns |
| 3 | Border | #1E2230 | border-[#1E2230] | Card borders, dividers, separators |
| 4 | Muted | #2A2F3E | — | Inactive elements, disabled states |
| 5 | Secondary text | #6B7084 | text-[#6B7084] | Labels, overlines, timestamps |
| 6 | Primary text muted | #8B8FA3 | text-[#8B8FA3] | Body text, descriptions |
| 7 | Primary text | #FFFFFF | text-white | Headings, names, primary content |

### Accent Colors
| Name | Hex | Tailwind | Use |
|------|-----|----------|-----|
| Primary | #3B82F6 | text-blue-500 / bg-blue-500 | Actions, links, selected states, primary CTA |
| Primary hover | #2563EB | hover:bg-blue-600 | Button hover, link hover |
| Primary muted | rgba(59,130,246,0.1) | bg-blue-500/10 | Active nav bg, selected row |
| Success | #22C55E | text-emerald-500 | Wins, online, positive ELO, completions |
| Success muted | rgba(34,197,94,0.1) | bg-emerald-500/10 | Win badge bg, success bg |
| Warning | #EAB308 | text-yellow-500 | Streaks at risk, pending |
| Warning muted | rgba(234,179,8,0.1) | bg-yellow-500/10 | Warning badge bg |
| Error | #EF4444 | text-red-500 | Losses, offline, negative ELO, errors |
| Error muted | rgba(239,68,68,0.1) | bg-red-500/10 | Loss badge bg |

### Weight Class Colors (fixed — team identity)
| Class | Hex | Tailwind | Border | Badge bg |
|-------|-----|----------|--------|----------|
| Frontier | #EAB308 | text-yellow-500 | border-yellow-500 | bg-yellow-500/10 |
| Contender | #3B82F6 | text-blue-500 | border-blue-500 | bg-blue-500/10 |
| Scrapper | #22C55E | text-emerald-500 | border-emerald-500 | bg-emerald-500/10 |
| Underdog | #F97316 | text-orange-500 | border-orange-500 | bg-orange-500/10 |
| Homebrew | #A855F7 | text-purple-500 | border-purple-500 | bg-purple-500/10 |
| Open | #8B8FA3 | text-[#8B8FA3] | border-[#2A2F3E] | bg-[#2A2F3E]/50 |

### Tier Colors
| Tier | Hex | Effect |
|------|-----|--------|
| Bronze | #CD7F32 | Solid color |
| Silver | #C0C0C0 | Solid color |
| Gold | #FFD700 | Subtle shimmer (gradient animation) |
| Platinum | #E5E4E2 | Subtle shimmer |
| Diamond | #B9F2FF | Glow (box-shadow: 0 0 8px rgba(185,242,255,0.3)) |
| Champion | animated | background: linear-gradient(90deg, #FFD700, #EF4444, #FFD700); background-size: 200% 100%; animation: gradient-shift 3s ease infinite |

---

## Effects Library

### Glass Card (primary content container)
```css
.glass-card {
  background: rgba(15, 17, 23, 0.6);      /* bg-[#0F1117]/60 */
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(30, 34, 48, 0.8); /* border-[#1E2230]/80 */
  border-radius: 12px;                      /* rounded-xl */
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.03),
    0 4px 24px rgba(0,0,0,0.2);
}
/* Tailwind: bg-[#0F1117]/60 backdrop-blur-xl border border-[#1E2230]/80 rounded-xl shadow-[0_0_0_1px_rgba(255,255,255,0.03),0_4px_24px_rgba(0,0,0,0.2)] */
```

### Glass Card Strong (elevated, modals, featured)
```css
.glass-card-strong {
  background: rgba(22, 25, 34, 0.8);
  backdrop-filter: blur(24px);
  border: 1px solid rgba(30, 34, 48, 1);
  border-radius: 16px;
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.05),
    inset 0 1px 1px rgba(255,255,255,0.06),
    0 8px 40px rgba(0,0,0,0.3);
}
```

### Gradient Border on Hover (interactive cards)
```css
.gradient-border-hover {
  position: relative;
  border: 1px solid transparent;
  background-clip: padding-box;
}
.gradient-border-hover::before {
  content: '';
  position: absolute;
  inset: -1px;
  border-radius: inherit;
  background: linear-gradient(135deg, rgba(59,130,246,0.5) 0%, rgba(168,85,247,0.5) 50%, rgba(59,130,246,0.5) 100%);
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: -1;
}
.gradient-border-hover:hover::before {
  opacity: 1;
}
```

### Live Glow (active/live elements)
```css
.live-glow {
  box-shadow: 0 0 0 1px rgba(34,197,94,0.2);
  animation: live-pulse 2s ease-in-out infinite;
}
@keyframes live-pulse {
  0%, 100% { box-shadow: 0 0 0 1px rgba(34,197,94,0.2); }
  50% { box-shadow: 0 0 0 3px rgba(34,197,94,0.1), 0 0 12px rgba(34,197,94,0.15); }
}
```

### Shimmer Skeleton (loading states)
```css
.skeleton-shimmer {
  background: linear-gradient(90deg, #161922 25%, #1E2230 50%, #161922 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

### Number Count Animation (Framer Motion)
```tsx
<motion.span
  initial={{ opacity: 0, y: 10 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.4, ease: [0.25, 0.1, 0.25, 1] }}
>
  {/* useMotionValue + useTransform for counting */}
</motion.span>
```

---

## Component Tokens

### Buttons
| Variant | Classes |
|---------|---------|
| Primary | `bg-blue-500 hover:bg-blue-600 text-white font-body font-semibold text-sm rounded-lg px-4 py-2.5 h-10 transition-colors duration-150` |
| Secondary | `bg-[#161922] hover:bg-[#1E2230] text-white border border-[#1E2230] font-body font-medium text-sm rounded-lg px-4 py-2.5 h-10 transition-colors duration-150` |
| Ghost | `hover:bg-[#1E2230]/50 text-[#8B8FA3] hover:text-white font-body font-medium text-sm rounded-lg px-4 py-2.5 h-10 transition-colors duration-150` |
| Danger | `bg-red-500/10 hover:bg-red-500/20 text-red-500 font-body font-medium text-sm rounded-lg px-4 py-2.5 h-10` |
| CTA (large) | `bg-blue-500 hover:bg-blue-600 text-white font-heading font-semibold text-base rounded-xl px-8 py-3.5 h-12 shadow-[0_0_20px_rgba(59,130,246,0.3)] hover:shadow-[0_0_30px_rgba(59,130,246,0.4)] transition-all duration-200` |
| Glass | `glass-card hover:bg-white/5 text-white font-body font-medium text-sm rounded-xl px-6 py-3 h-11 transition-all duration-200` |

### Badges
| Variant | Classes |
|---------|---------|
| Weight class | `inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-mono font-medium border [weight-class-color-applied]` |
| Tier | `inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-mono font-medium [tier-color-applied]` |
| Status live | `inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium bg-emerald-500/10 text-emerald-500 border border-emerald-500/20` + pulsing dot |
| Status pending | `... bg-yellow-500/10 text-yellow-500 border border-yellow-500/20` |
| Category | `inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-xs font-medium bg-[#1E2230] text-[#8B8FA3] border border-[#1E2230]` |

### Cards
| Type | Classes |
|------|---------|
| Default | `glass-card p-5 hover:border-[#2A2F3E] transition-colors duration-200` |
| Interactive | `glass-card p-5 cursor-pointer gradient-border-hover transition-all duration-200` |
| Featured | `glass-card-strong p-6` |
| Stat | `glass-card p-4 text-center` |

### Tables
```
Header: text-xs font-mono font-semibold uppercase tracking-[0.08em] text-[#6B7084] px-4 py-3 border-b border-[#1E2230]
Row: px-4 py-3 border-b border-[#1E2230]/50 hover:bg-[#0F1117]/50 transition-colors duration-150
Cell text: text-sm font-body text-[#8B8FA3] (default) / text-white (primary)
```

---

## Spacing System (8px grid)
```
1:  4px     (gap-1, p-1)
2:  8px     (gap-2, p-2)      — minimum inner padding
3:  12px    (gap-3, p-3)
4:  16px    (gap-4, p-4)      — standard card inner padding
5:  20px    (gap-5, p-5)      — card padding
6:  24px    (gap-6, p-6)      — section spacing
8:  32px    (gap-8, p-8)      — between major sections
10: 40px    (gap-10)
12: 48px    (gap-12)           — page sections
16: 64px    (gap-16, py-16)   — major page sections
20: 80px    (gap-20, py-20)   — hero padding
24: 96px    (gap-24, py-24)
```

## Border Radius Scale
```
sm:  4px   (rounded-sm)   — small pills
md:  6px   (rounded-md)   — buttons, inputs
lg:  8px   (rounded-lg)   — small cards
xl:  12px  (rounded-xl)   — primary cards
2xl: 16px  (rounded-2xl)  — featured cards, modals
3xl: 24px  (rounded-3xl)  — hero glass cards
full: 9999px (rounded-full) — badges, avatars, pills
```

## Z-Index Map
```
0:    Page background, static content
10:   Cards, elevated content
20:   Dropdown menus, tooltips
30:   Sticky headers, floating elements
40:   Mobile nav overlay
50:   Navbar (fixed)
60:   Modals, dialogs
70:   Toast notifications
80:   Loading overlays
9999: Loading screen (initial)
```

---

## Animations Spec

### Page Transitions
```tsx
initial={{ opacity: 0, y: 8 }}
animate={{ opacity: 1, y: 0 }}
exit={{ opacity: 0, y: -8 }}
transition={{ duration: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
```

### Card Hover
```tsx
whileHover={{ y: -2 }}
transition={{ duration: 0.2, ease: "easeOut" }}
// + gradient-border-hover CSS for border glow
```

### ELO Change Indicator
```tsx
// Positive
<motion.span
  className="text-emerald-500 font-mono text-sm font-medium"
  initial={{ opacity: 0, y: 8, scale: 0.8 }}
  animate={{ opacity: 1, y: 0, scale: 1 }}
  transition={{ duration: 0.4, ease: [0.34, 1.56, 0.64, 1] }} // spring-like overshoot
>+12</motion.span>

// Negative
<motion.span className="text-red-500 ...">-8</motion.span>
```

### Leaderboard Rank Change
```tsx
<motion.tr layout transition={{ duration: 0.4, ease: [0.25, 0.1, 0.25, 1] }}>
```

### Level Up Celebration
```tsx
// Full-screen overlay
<motion.div
  className="fixed inset-0 z-[80] bg-black/60 backdrop-blur-sm flex items-center justify-center"
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  exit={{ opacity: 0 }}
>
  <motion.div
    initial={{ scale: 0.5, opacity: 0, rotate: -10 }}
    animate={{ scale: 1, opacity: 1, rotate: 0 }}
    transition={{ duration: 0.6, ease: [0.34, 1.56, 0.64, 1] }}
  >
    {/* Level badge + confetti */}
  </motion.div>
</motion.div>
```

### Badge Earned
```tsx
<motion.div
  initial={{ scale: 0, opacity: 0 }}
  animate={{ scale: [0, 1.2, 1], opacity: 1 }}
  transition={{ duration: 0.5, times: [0, 0.6, 1], ease: "easeOut" }}
>
  {/* Badge icon with gold ring-4 ring-yellow-500/30 glow */}
</motion.div>
```

### Streak Flame
```tsx
<motion.span
  animate={{ scale: [1, 1.3, 1] }}
  transition={{ duration: 0.4, ease: "easeOut" }}
>🔥</motion.span>
```

### Quest Completion
```tsx
// Checkmark
<motion.svg initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.3 }}>
// Progress bar fill
<motion.div initial={{ width: "60%" }} animate={{ width: "100%" }} transition={{ duration: 0.6, ease: "easeOut" }}>
// Reward float up
<motion.span initial={{ opacity: 0, y: 0 }} animate={{ opacity: [1, 1, 0], y: -30 }} transition={{ duration: 1.2 }}>+50 XP</motion.span>
```

### Timer Countdown (last 60s)
```tsx
className={cn(
  "font-mono text-2xl",
  secondsRemaining <= 60 && "text-red-500 animate-pulse"
)}
```

### Spectator Event Feed
```tsx
<motion.div
  initial={{ opacity: 0, y: -10, height: 0 }}
  animate={{ opacity: 1, y: 0, height: "auto" }}
  transition={{ duration: 0.2, ease: "easeOut" }}
/>
```

### Loading Skeleton
```tsx
<div className="skeleton-shimmer h-4 rounded-md" />
// See shimmer CSS keyframes above
```

### Toast Notifications
```tsx
initial={{ opacity: 0, x: 50, y: 0 }}
animate={{ opacity: 1, x: 0 }}
exit={{ opacity: 0, x: 50 }}
transition={{ duration: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
// Position: fixed top-4 right-4 z-[70]
```
