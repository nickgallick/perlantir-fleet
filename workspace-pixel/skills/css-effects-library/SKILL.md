---
name: css-effects-library
description: Glass morphism, gradients, shadows, blur, borders, cursor effects. Every effect with exact CSS/Tailwind. Use when specifying visual effects for any screen — glass cards, gradient borders, glow, vignettes, halftone patterns, shimmer loading. Copy-pasteable CSS for every effect.
---

# CSS Effects Library

Reference this skill whenever a design spec needs visual effects. Every effect is copy-pasteable CSS with Tailwind equivalents.

## Liquid Glass (Dark Premium)

```css
.liquid-glass {
  background: rgba(255, 255, 255, 0.01);
  background-blend-mode: luminosity;
  backdrop-filter: blur(4px);
  border: none;
  box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.1);
  position: relative;
  overflow: hidden;
}
.liquid-glass::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  padding: 1.4px;
  background: linear-gradient(180deg,
    rgba(255,255,255,0.45) 0%, rgba(255,255,255,0.15) 20%,
    rgba(255,255,255,0) 40%, rgba(255,255,255,0) 60%,
    rgba(255,255,255,0.15) 80%, rgba(255,255,255,0.45) 100%);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  pointer-events: none;
}
```

**Liquid Glass Strong** (elevated modals, emphasized cards):
```css
.liquid-glass-strong {
  background: rgba(255, 255, 255, 0.03);
  background-blend-mode: luminosity;
  backdrop-filter: blur(12px);
  box-shadow: inset 0 1px 2px rgba(255, 255, 255, 0.15);
}
/* Same ::before as liquid-glass but padding: 2px and higher opacity stops */
```

**Tailwind shortcut** (no pseudo-element, simpler): `bg-white/[0.01] backdrop-blur-sm border border-white/10 shadow-[inset_0_1px_1px_rgba(255,255,255,0.1)]`

---

## Surface Glass (Data-Dense Dark UIs)

For cards, panels, and containers on dark backgrounds:

```css
.arena-glass {
  background: rgba(17, 24, 39, 0.7);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(30, 41, 59, 0.8);
  border-radius: 12px;
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.03),
    0 4px 24px rgba(0,0,0,0.3);
}
```

Tailwind: `bg-gray-900/70 backdrop-blur-xl border border-slate-800/80 rounded-xl shadow-[0_0_0_1px_rgba(255,255,255,0.03),0_4px_24px_rgba(0,0,0,0.3)]`

---

## Gradient Border on Hover

Animated gradient border that appears on hover using mask-composite:

```css
.gradient-border {
  position: relative;
  border-radius: 12px;
  overflow: hidden;
}
.gradient-border::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  padding: 1px;
  background: linear-gradient(135deg,
    rgba(59,130,246,0.5) 0%,
    rgba(59,130,246,0) 50%,
    rgba(59,130,246,0.3) 100%);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
}
.gradient-border:hover::before {
  opacity: 1;
}
```

Customize gradient color by replacing `59,130,246` (blue-500) with any RGB.

---

## Vignette Overlays

**Desktop vignette** (radial, subtle darkening at edges):
```css
background: radial-gradient(ellipse, transparent 70%, rgba(0,0,0,0.7) 100%);
```

**Mobile vignette** (bottom-up, for content readability over video):
```css
background: linear-gradient(to top, rgba(0,0,0,0.8), transparent 60%);
```

**Video top/bottom fades** (200px black fades):
```css
/* Top fade */
.video-fade-top {
  position: absolute; top: 0; left: 0; right: 0;
  height: 200px;
  background: linear-gradient(to bottom, black, transparent);
  pointer-events: none;
}
/* Bottom fade */
.video-fade-bottom {
  position: absolute; bottom: 0; left: 0; right: 0;
  height: 200px;
  background: linear-gradient(to top, black, transparent);
  pointer-events: none;
}
```

---

## Halftone Pattern

Dot pattern overlay for editorial/portfolio vibes:
```css
.halftone {
  background-image: radial-gradient(circle, #000 1px, transparent 1px);
  background-size: 4px 4px;
  opacity: 0.2;
}
```

---

## Live Pulse Glow

Pulsing ring for active/live elements:
```css
.live-pulse {
  box-shadow: 0 0 0 0 rgba(16,185,129,0.4);
  animation: pulse 2s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(16,185,129,0.4); }
  50% { box-shadow: 0 0 0 6px rgba(16,185,129,0); }
}
```

**Live dot** (8px green indicator):
```css
.live-dot {
  width: 8px; height: 8px; border-radius: 50%;
  background: #10B981;
  box-shadow: 0 0 6px rgba(16,185,129,0.6);
  animation: dot-pulse 2s ease-in-out infinite;
}
@keyframes dot-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
```

---

## Shimmer / Skeleton Loading

```css
.skeleton {
  background: linear-gradient(90deg, #111827 25%, #1A2332 50%, #111827 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
  border-radius: 8px;
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

---

## Glow Shadows (Per Weight Class / Accent)

| Color | Glow CSS |
|-------|----------|
| Blue (#3B82F6) | `box-shadow: 0 0 12px rgba(59,130,246,0.3)` |
| Gold (#EAB308) | `box-shadow: 0 0 12px rgba(234,179,8,0.3)` |
| Green (#22C55E) | `box-shadow: 0 0 12px rgba(34,197,94,0.3)` |
| Orange (#F97316) | `box-shadow: 0 0 12px rgba(249,115,22,0.3)` |
| Purple (#A855F7) | `box-shadow: 0 0 12px rgba(168,85,247,0.3)` |
| Cyan (#00D4FF) | `box-shadow: 0 0 12px rgba(0,212,255,0.3)` |

---

## Animated Gradient Background (Champion Tier)

```css
.champion-gradient {
  background: linear-gradient(90deg, #FFD700, #EF4444, #FFD700);
  background-size: 200% 100%;
  animation: champion-shift 3s linear infinite;
}
@keyframes champion-shift {
  0% { background-position: 0% 50%; }
  100% { background-position: 200% 50%; }
}
```

---

## Diagonal SVG Section Divider

Light-to-dark transition between sections:
```html
<svg viewBox="0 0 1440 120" preserveAspectRatio="none" className="h-[60px] md:h-[120px]">
  <polygon points="0,0 0,120 1440,120 1440,80 920,80 680,0" fill="#0F0F0F" />
</svg>
```
Position: `absolute bottom-0 left-0 w-full z-[3]`

---

## Card Hover Elevation

Standard interactive card hover:
```css
.card {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.3);
  border-color: rgba(59,130,246,0.3);
}
```

---

## Rules
- Never use vague descriptions ("subtle shadow", "light glow"). Always provide complete CSS.
- Every effect must include the exact `background`, `box-shadow`, `backdrop-filter`, `border`, and animation properties.
- Pseudo-element effects (::before, ::after) must include `content`, `position`, `inset`, `border-radius: inherit`, and `pointer-events: none`.
- Always test contrast — glass effects on dark backgrounds must maintain WCAG AA text readability.
