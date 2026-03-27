# Framer Motion Reference

Complete Framer Motion reference for implementing Pixel's animation specs in Next.js + React projects.

## Installation

```bash
npm install framer-motion
```

App Router: add `"use client"` to any component using motion.

---

## Core Motion Components

```tsx
"use client";
import { motion } from "framer-motion";

// Any HTML element
<motion.div animate={{ opacity: 1 }} />
<motion.span />
<motion.button />
<motion.img />
<motion.svg />
<motion.path />

// Custom component wrapping
import { forwardRef } from "react";
const Card = forwardRef<HTMLDivElement, CardProps>((props, ref) => (
  <div ref={ref} {...props} />
));
const MotionCard = motion.create(Card);
```

---

## Animation Props

### initial / animate / exit

```tsx
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0, y: -10 }}
  transition={{ duration: 0.5 }}
/>
```

### whileInView (scroll-triggered)

```tsx
<motion.div
  initial={{ opacity: 0, y: 40 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-100px" }}
  transition={{ duration: 0.6, ease: "easeOut" }}
/>
```

- `viewport.once: true` — animate only on first scroll into view (performance, prevents re-triggering)
- `viewport.margin` — negative margin triggers earlier (before element is fully visible)
- `viewport.amount` — fraction of element visible before triggering (0-1, default 0)

### whileHover / whileTap

```tsx
<motion.button
  whileHover={{ scale: 1.02, y: -2 }}
  whileTap={{ scale: 0.98 }}
  transition={{ type: "spring", stiffness: 400, damping: 25 }}
/>
```

---

## Transition Types

### Spring (default — natural motion)

```tsx
transition={{
  type: "spring",
  stiffness: 300,  // higher = snappier
  damping: 24,     // higher = less bounce
  mass: 1,         // higher = heavier feel
}}
```

Common spring presets:
- **Snappy UI**: `stiffness: 400, damping: 30` — buttons, toggles
- **Smooth entrance**: `stiffness: 200, damping: 20` — cards, panels
- **Bouncy**: `stiffness: 300, damping: 10` — attention-grabbing
- **Heavy/luxury**: `stiffness: 100, damping: 20, mass: 1.5` — premium feel

### Tween (CSS-like duration)

```tsx
transition={{
  type: "tween",
  duration: 0.5,
  ease: "easeOut",       // string shorthand
  // OR cubic-bezier:
  ease: [0.25, 0.1, 0.25, 1.0],
}}
```

Ease options: `"linear"`, `"easeIn"`, `"easeOut"`, `"easeInOut"`, `"circIn"`, `"circOut"`, `"backIn"`, `"backOut"`, `"anticipate"`, or `[x1, y1, x2, y2]` cubic-bezier.

### Per-property transitions

```tsx
transition={{
  opacity: { duration: 0.3 },
  y: { type: "spring", stiffness: 300, damping: 24 },
  filter: { duration: 0.6, ease: "easeOut" },
}}
```

---

## Variants (Parent + Children Orchestration)

Variants define named animation states and enable stagger/orchestration between parent and children.

```tsx
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
      delayChildren: 0.1,
      when: "beforeChildren", // parent animates first, then children
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { type: "spring", stiffness: 300, damping: 24 },
  },
};

function StaggeredGrid({ items }: { items: Item[] }) {
  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, margin: "-50px" }}
      className="grid grid-cols-3 gap-6"
    >
      {items.map((item) => (
        <motion.div key={item.id} variants={itemVariants}>
          <Card {...item} />
        </motion.div>
      ))}
    </motion.div>
  );
}
```

Key rules:
- Children inherit `initial`/`animate`/`whileInView` from parent automatically — don't re-declare them on children
- `staggerChildren` in the parent's `visible.transition` controls delay between each child
- `delayChildren` adds a flat delay before the first child starts
- `when: "beforeChildren"` or `"afterChildren"` controls sequencing

---

## AnimatePresence (Exit Animations & Page Transitions)

### Basic exit animation

```tsx
import { AnimatePresence, motion } from "framer-motion";

function Modal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          key="modal"
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
          transition={{ duration: 0.2 }}
        >
          <ModalContent onClose={onClose} />
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

### Page transitions (App Router)

```tsx
// app/template.tsx — wraps page content, re-mounts on navigation
"use client";
import { AnimatePresence, motion } from "framer-motion";
import { usePathname } from "next/navigation";

export default function Template({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.25, ease: "easeInOut" }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

`mode="wait"` — current page exits completely before new page enters. Prevents layout overlap.

Other modes:
- `mode="sync"` (default) — enter and exit happen simultaneously
- `mode="popLayout"` — exiting element removed from flow immediately

---

## useScroll + useTransform (Parallax & Scroll-linked)

### Page scroll progress

```tsx
"use client";
import { motion, useScroll, useTransform } from "framer-motion";

function ParallaxHero() {
  const { scrollY } = useScroll();
  const y = useTransform(scrollY, [0, 500], [0, -150]);
  const opacity = useTransform(scrollY, [0, 300], [1, 0]);

  return (
    <motion.div style={{ y, opacity }} className="h-screen">
      <h1>Hero Content</h1>
    </motion.div>
  );
}
```

### Element scroll progress

```tsx
function ScrollRevealSection() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
    // "start end" = element's top hits viewport bottom
    // "end start" = element's bottom hits viewport top
  });

  const scale = useTransform(scrollYProgress, [0, 0.5], [0.8, 1]);
  const opacity = useTransform(scrollYProgress, [0, 0.3], [0, 1]);

  return (
    <motion.div ref={ref} style={{ scale, opacity }}>
      Content
    </motion.div>
  );
}
```

### Scroll progress bar

```tsx
function ScrollProgressBar() {
  const { scrollYProgress } = useScroll();

  return (
    <motion.div
      style={{ scaleX: scrollYProgress, transformOrigin: "left" }}
      className="fixed top-0 left-0 right-0 h-1 bg-primary z-50"
    />
  );
}
```

---

## Layout Animations

### Auto-animate layout changes

```tsx
// layout prop auto-animates position and size changes
<motion.div layout className={isExpanded ? "w-full" : "w-48"}>
  <motion.h2 layout="position">Title</motion.h2>
  {isExpanded && <p>Extra content</p>}
</motion.div>
```

- `layout` — animates both position and size
- `layout="position"` — only animates position (prevents text reflow)
- `layout="size"` — only animates size

### Shared layout (element morphing between states)

```tsx
import { LayoutGroup, motion } from "framer-motion";

function Tabs({ tabs, activeTab, onSelect }) {
  return (
    <LayoutGroup>
      <div className="flex gap-2">
        {tabs.map((tab) => (
          <button key={tab.id} onClick={() => onSelect(tab.id)} className="relative px-4 py-2">
            {tab.label}
            {activeTab === tab.id && (
              <motion.div
                layoutId="active-tab"
                className="absolute inset-0 bg-primary/10 rounded-lg"
                transition={{ type: "spring", stiffness: 400, damping: 30 }}
              />
            )}
          </button>
        ))}
      </div>
    </LayoutGroup>
  );
}
```

`layoutId` — elements with the same `layoutId` morph into each other across mounts/unmounts. Use for tab indicators, card expand/collapse, list reordering.

---

## Pixel's Common Animation Patterns

### 1. Blur Reveal (blur 10px→0px + opacity + y movement)

```tsx
const blurRevealVariants = {
  hidden: {
    opacity: 0,
    y: 20,
    filter: "blur(10px)",
  },
  visible: {
    opacity: 1,
    y: 0,
    filter: "blur(0px)",
    transition: {
      duration: 0.6,
      ease: "easeOut",
      filter: { duration: 0.8 }, // blur clears slightly slower
    },
  },
};

<motion.div
  variants={blurRevealVariants}
  initial="hidden"
  whileInView="visible"
  viewport={{ once: true, margin: "-100px" }}
>
  <SectionContent />
</motion.div>
```

### 2. Staggered Grid Entrance (staggerChildren: 0.05)

```tsx
const gridContainerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
      delayChildren: 0.1,
    },
  },
};

const gridItemVariants = {
  hidden: { opacity: 0, y: 20, scale: 0.95 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      type: "spring",
      stiffness: 300,
      damping: 24,
    },
  },
};

<motion.div
  variants={gridContainerVariants}
  initial="hidden"
  whileInView="visible"
  viewport={{ once: true }}
  className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
>
  {items.map((item) => (
    <motion.div key={item.id} variants={gridItemVariants}>
      <GridCard {...item} />
    </motion.div>
  ))}
</motion.div>
```

### 3. Count-Up Numbers

```tsx
"use client";
import { useEffect, useRef, useState } from "react";
import {
  useInView,
  useMotionValue,
  useTransform,
  motion,
  animate,
} from "framer-motion";

function CountUp({
  target,
  duration = 2,
  suffix = "",
  prefix = "",
}: {
  target: number;
  duration?: number;
  suffix?: string;
  prefix?: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });
  const motionValue = useMotionValue(0);
  const rounded = useTransform(motionValue, (v) => Math.round(v));
  const [display, setDisplay] = useState(0);

  useEffect(() => {
    if (!isInView) return;

    const controls = animate(motionValue, target, {
      duration,
      ease: "easeOut",
    });

    const unsubscribe = rounded.on("change", (v) => setDisplay(v));

    return () => {
      controls.stop();
      unsubscribe();
    };
  }, [isInView, target, duration, motionValue, rounded]);

  return (
    <motion.span ref={ref}>
      {prefix}{display.toLocaleString()}{suffix}
    </motion.span>
  );
}

// Usage
<CountUp target={10000} suffix="+" />         // "10,000+"
<CountUp target={99} suffix="%" />             // "99%"
<CountUp target={4.9} duration={1.5} />        // rounds to integers
```

### 4. Card Hover Lift (y: -2, shadow increase)

```tsx
const cardHoverVariants = {
  rest: {
    y: 0,
    boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
    transition: { type: "spring", stiffness: 400, damping: 25 },
  },
  hover: {
    y: -2,
    boxShadow: "0 8px 25px rgba(0,0,0,0.12)",
    transition: { type: "spring", stiffness: 400, damping: 25 },
  },
};

<motion.div
  variants={cardHoverVariants}
  initial="rest"
  whileHover="hover"
  className="rounded-xl border bg-card p-6 cursor-pointer"
>
  <CardContent />
</motion.div>
```

### 5. Page Transitions (exit opacity→0, enter opacity→1 with mode="wait")

```tsx
// app/template.tsx
"use client";
import { AnimatePresence, motion } from "framer-motion";
import { usePathname } from "next/navigation";

const pageVariants = {
  initial: { opacity: 0, y: 8 },
  enter: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.3, ease: "easeOut" },
  },
  exit: {
    opacity: 0,
    y: -8,
    transition: { duration: 0.2, ease: "easeIn" },
  },
};

export default function Template({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        variants={pageVariants}
        initial="initial"
        animate="enter"
        exit="exit"
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

---

## Reduced Motion (Accessibility — Required)

Always provide `prefers-reduced-motion` fallbacks. Users with vestibular disorders need this.

### useReducedMotion hook

```tsx
import { useReducedMotion } from "framer-motion";

function AnimatedCard({ children }: { children: React.ReactNode }) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div
      initial={shouldReduceMotion ? { opacity: 0 } : { opacity: 0, y: 20, filter: "blur(10px)" }}
      whileInView={shouldReduceMotion ? { opacity: 1 } : { opacity: 1, y: 0, filter: "blur(0px)" }}
      viewport={{ once: true }}
      transition={shouldReduceMotion ? { duration: 0.01 } : { duration: 0.6 }}
    >
      {children}
    </motion.div>
  );
}
```

### Global reduced motion wrapper

```tsx
// components/motion-wrapper.tsx
"use client";
import { useReducedMotion } from "framer-motion";
import { createContext, useContext } from "react";

const ReducedMotionContext = createContext(false);

export function MotionProvider({ children }: { children: React.ReactNode }) {
  const shouldReduceMotion = useReducedMotion() ?? false;
  return (
    <ReducedMotionContext.Provider value={shouldReduceMotion}>
      {children}
    </ReducedMotionContext.Provider>
  );
}

export function useMotionSafe() {
  const shouldReduceMotion = useContext(ReducedMotionContext);

  return {
    shouldReduceMotion,
    // Returns static values if reduced motion preferred
    entrance: shouldReduceMotion
      ? { initial: { opacity: 0 }, animate: { opacity: 1 }, transition: { duration: 0.01 } }
      : undefined, // let caller define full animation
  };
}
```

### CSS fallback (always include alongside framer-motion)

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

---

## Performance Rules

1. **Use `viewport={{ once: true }}`** on scroll-triggered animations — prevents re-triggering on scroll up
2. **Avoid animating `width`/`height`** — use `scale`, `opacity`, `x`, `y` (GPU-composited properties)
3. **Use `layout` sparingly** — layout animations are expensive; only use when needed
4. **Use `will-change: transform`** on elements with continuous animations (parallax)
5. **Don't animate filter on large elements** — `blur()` is expensive; keep blur-reveal elements small or use short durations
6. **Unmount animated components** — use `AnimatePresence` to cleanly unmount, don't just hide with CSS
7. **Avoid stagger on 50+ items** — stagger 20+ items gets sluggish; paginate or virtualize

---

## Next.js App Router Integration Notes

- All motion components require `"use client"` directive
- `AnimatePresence` with page transitions goes in `template.tsx` (not `layout.tsx` — layouts don't re-mount)
- Server Components can import client motion components as children
- For SSR hydration: `initial` prop prevents flash-of-unstyled on hydration
- Framer Motion v11+ supports React 18+ and React Server Components (as long as motion usage is in client components)

---

## Common Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| Exit animations don't play | Missing `AnimatePresence` wrapper | Wrap conditional render in `AnimatePresence` |
| Content invisible on load | `initial` opacity 0, `whileInView` but element already in viewport | Add `animate` fallback or check viewport on mount |
| Stagger not working | Children missing `variants` prop | Children must use `variants`, not inline `animate` |
| Layout animation glitchy | Animating between very different layouts | Use `layout="position"` instead of `layout` |
| Hydration mismatch | Motion values differ server vs client | Use `initial={false}` to skip initial animation |
| Page transition flicker | Using `layout.tsx` instead of `template.tsx` | Move `AnimatePresence` to `template.tsx` |
