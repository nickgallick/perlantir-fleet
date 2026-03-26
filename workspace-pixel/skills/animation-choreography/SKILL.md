---
name: animation-choreography
description: Scroll-triggered entrances, stagger patterns, choreography rules, timing/easing, page transitions, parallax. Exact Framer Motion props for every animation. Use when specifying motion for any screen — entrances, exits, hover, scroll, live data updates, celebrations.
---

# Animation Choreography

Reference this skill for every animation specification. Every animation has exact Framer Motion or CSS props.

## Core Principle

Motion communicates — it never decorates. Every animation tells the user what happened, what changed, or where to look. If removing an animation wouldn't confuse the user, the animation shouldn't exist.

## Timing System

| Category | Duration | Use For |
|----------|----------|---------|
| Micro | 100–200ms | Button press, toggle, focus ring |
| Standard | 200–400ms | Card hover, dropdown, tab switch |
| Emphasis | 400–600ms | Section reveal, page transition, modal |
| Celebration | 600–1200ms | Badge unlock, level up, confetti |
| Ambient | 1500ms+ (infinite) | Shimmer, pulse, gradient shift |

## Easing Functions

| Name | CSS / Framer | When |
|------|--------------|------|
| **expo.out** | `[0.16, 1, 0.3, 1]` | Default for most UI. Fast start, gentle land. |
| **easeOut** | `"easeOut"` | Simpler animations, exits |
| **spring** | `type: "spring", stiffness: 300, damping: 20` | Celebrations, bouncy reveals |
| **linear** | `"linear"` | Infinite loops (shimmer, marquee, gradient) |
| **power3.out** | GSAP: `"power3.out"` | Hero entrances, parallax |

**Default:** Use expo.out `[0.16, 1, 0.3, 1]` unless you have a reason not to.

---

## Page Transitions

```tsx
<AnimatePresence mode="wait">
  <motion.div
    key={route}
    initial={{ opacity: 0, y: 10 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -10 }}
    transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
  >
    {children}
  </motion.div>
</AnimatePresence>
```

---

## Scroll-Triggered Section Reveals

```tsx
<motion.div
  initial={{ opacity: 0, y: 30 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-60px" }}
  transition={{ duration: 0.6, delay, ease: [0.16, 1, 0.3, 1] }}
/>
```

- `viewport.once: true` — animate only first time in view
- `margin: "-60px"` — trigger 60px before element enters viewport
- Duration: 600ms for sections, 400ms for individual elements

---

## Stagger Patterns

```tsx
// Parent
const container = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.05, delayChildren: 0.2 },
  },
}

// Child
const item = {
  hidden: { opacity: 0, y: 15 },
  visible: {
    opacity: 1, y: 0,
    transition: { duration: 0.4, ease: [0.16, 1, 0.3, 1] },
  },
}
```

**Stagger timing by context:**

| Context | Stagger Delay | Child Duration |
|---------|---------------|----------------|
| Challenge grid (cards) | 50ms | 400ms |
| Leaderboard rows | 20ms | 250ms |
| Badge grid | 30ms | 350ms |
| Stats counters | 100ms | 800ms |
| Event feed items | 0ms (instant) | 200ms |

---

## Card Hover

```tsx
<motion.div
  whileHover={{ y: -2, transition: { duration: 0.2, ease: "easeOut" } }}
/>
```

CSS:
```css
.card { transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); }
.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.3);
  border-color: rgba(59,130,246,0.3);
}
```

---

## Button Interactions

```tsx
<motion.button
  whileHover={{ translateY: -1 }}
  whileTap={{ scale: 0.98 }}
  transition={{ duration: 0.2 }}
/>
```

---

## Number Counting

```tsx
import { useMotionValue, useTransform, animate } from "framer-motion"

const CountUp = ({ target, duration = 1 }) => {
  const count = useMotionValue(0)
  const display = useTransform(count, (v) => Math.round(v).toLocaleString())

  useEffect(() => {
    const controls = animate(count, target, {
      duration,
      ease: "easeOut",
    })
    return controls.stop
  }, [target])

  return <motion.span className="font-mono tabular-nums">{display}</motion.span>
}
```

| Context | Duration | Trigger |
|---------|----------|---------|
| ELO change | 0.8s | On mount |
| Score display | 1.0s | On mount |
| Stat cards | 1.2s | whileInView |
| Rank change | 0.6s | On data update |

---

## Expand / Collapse

```tsx
<AnimatePresence>
  {isOpen && (
    <motion.div
      initial={{ height: 0, opacity: 0 }}
      animate={{ height: "auto", opacity: 1 }}
      exit={{ height: 0, opacity: 0 }}
      transition={{ duration: 0.3, ease: "easeOut" }}
      style={{ overflow: "hidden" }}
    />
  )}
</AnimatePresence>
```

Chevron rotation:
```tsx
<motion.div animate={{ rotate: isOpen ? 180 : 0 }} transition={{ duration: 0.2 }} />
```

---

## Live Data Updates

**Rank reordering:**
```tsx
<motion.div layoutId={`rank-${id}`}>
  {/* Smooth position change when rankings update */}
</motion.div>
```

**New event slide-in:**
```tsx
<motion.div
  initial={{ opacity: 0, x: -20 }}
  animate={{ opacity: 1, x: 0 }}
  transition={{ duration: 0.3, ease: "easeOut" }}
/>
```

---

## Filter / Sort Changes

```tsx
<AnimatePresence mode="popLayout">
  {items.map((item) => (
    <motion.div
      key={item.id}
      layout
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.25, ease: "easeOut" }}
    />
  ))}
</AnimatePresence>
```

---

## Celebrations

**Badge unlock:**
```tsx
<motion.div
  initial={{ opacity: 0, scale: 0.9 }}
  animate={{ opacity: 1, scale: 1 }}
  transition={{ duration: 0.5, type: "spring", stiffness: 300, damping: 20 }}
/>
// + confetti: 8 particles, 1.2s duration, radial spread
```

**Streak flame pulse:**
```tsx
<motion.div animate={{ scale: [1, 1.3, 1] }} transition={{ duration: 0.6, times: [0,0.5,1] }} />
```

**Level up banner:**
```tsx
<motion.div
  initial={{ opacity: 0, y: -100 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.6, type: "spring", bounce: 0.4 }}
/>
```

---

## GSAP Scroll Parallax

```tsx
// ScrollTrigger setup
gsap.to(leftElement, {
  y: "-120vh",
  ease: "none",
  scrollTrigger: { trigger: section, start: "top bottom", end: "bottom top", scrub: 1 },
})
```

**Marquee (infinite horizontal scroll):**
```tsx
gsap.to(marquee, {
  xPercent: -50,
  duration: 40,
  ease: "none",
  repeat: -1,
})
```

---

## Toast Notifications

```tsx
<motion.div
  initial={{ opacity: 0, x: 100, y: -20 }}
  animate={{ opacity: 1, x: 0, y: 0 }}
  exit={{ opacity: 0, x: 100 }}
  transition={{ duration: 0.3, ease: "easeOut" }}
/>
// Auto-dismiss: 3000ms
```

---

## Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

In Framer Motion: check `useReducedMotion()` and set duration to 0.01.

---

## Rules
- Every animation must specify: duration, easing, from/to values, and trigger condition.
- Stagger patterns must specify the delay between children and initial delay.
- Use `expo.out [0.16, 1, 0.3, 1]` as the default easing.
- Always implement `prefers-reduced-motion` fallback.
- Never animate more than `opacity` + `transform` for performance (avoid layout-triggering properties).
