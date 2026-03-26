---
name: advanced-animation-and-interaction
description: Framer Motion patterns, micro-interactions, scroll animations, layout transitions, React Native Reanimated, and animation performance rules.
---

# Advanced Animation & Interaction

## Performance Rules (Non-Negotiable)

- **ONLY animate** `transform` and `opacity` (GPU-accelerated)
- **NEVER animate** `width`, `height`, `top`, `left`, `margin`, `padding` (triggers layout)
- **Respect** `prefers-reduced-motion` — disable animations for users who request it
- **`layout` animations** are expensive — only on elements that actually move

```tsx
const prefersReduced = typeof window !== 'undefined' 
  && window.matchMedia('(prefers-reduced-motion: reduce)').matches

<motion.div animate={prefersReduced ? {} : { opacity: 1, y: 0 }} />
```

---

## Framer Motion Patterns

### Mount/Unmount
```tsx
<AnimatePresence>
  {isVisible && (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      transition={{ duration: 0.2 }}
    />
  )}
</AnimatePresence>
```

### Layout Animation (Items Reorder Smoothly)
```tsx
{items.map(item => (
  <motion.div 
    key={item.id} 
    layout 
    transition={{ type: "spring", stiffness: 500, damping: 35 }}
  >
    {item.name}
  </motion.div>
))}
```

### Stagger Children
```tsx
const container = { hidden: {}, show: { transition: { staggerChildren: 0.05 } } }
const item = { hidden: { opacity: 0, y: 10 }, show: { opacity: 1, y: 0 } }

<motion.ul variants={container} initial="hidden" animate="show">
  {items.map(i => <motion.li key={i.id} variants={item}>{i.name}</motion.li>)}
</motion.ul>
```

### Scroll-Triggered
```tsx
import { useScroll, useTransform, motion } from 'framer-motion'

function ParallaxHero() {
  const { scrollYProgress } = useScroll()
  const y = useTransform(scrollYProgress, [0, 1], [0, -200])
  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0])
  
  return <motion.div style={{ y, opacity }}>Hero Content</motion.div>
}
```

### Gestures
```tsx
<motion.div
  drag="x"
  dragConstraints={{ left: -100, right: 100 }}
  whileHover={{ scale: 1.02, y: -2 }}
  whileTap={{ scale: 0.98 }}
/>
```

---

## Micro-Interactions (Premium Feel)

| Interaction | Implementation | Impact |
|------------|---------------|--------|
| Button press | `whileTap={{ scale: 0.97 }}` | Tactile feedback |
| Card hover | `whileHover={{ y: -2, boxShadow: "0 8px 30px rgba(0,0,0,0.12)" }}` | Depth |
| Number counting | Animate from 0 to value over 0.5s | Data emphasis |
| Toast slide-in | `initial={{ y: -100 }}` with spring | Smooth notification |
| Skeleton → content | AnimatePresence swap with crossfade | Perceived speed |
| Progress ring | SVG `strokeDashoffset` animation | Timer/mastery display |
| Page transition | Exit: fade left. Enter: fade from right. | Spatial navigation |

---

## React Native (Reanimated 3)

```tsx
import Animated, { 
  useSharedValue, useAnimatedStyle, withSpring 
} from 'react-native-reanimated'

function AnimatedCard() {
  const scale = useSharedValue(1)
  const style = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }]
  }))
  
  return (
    <Pressable
      onPressIn={() => { scale.value = withSpring(0.95) }}
      onPressOut={() => { scale.value = withSpring(1) }}
    >
      <Animated.View style={style}><Text>Card</Text></Animated.View>
    </Pressable>
  )
}
```

**Key difference from web:** Reanimated runs on UI thread (60fps always). React Native's built-in `Animated` runs on JS thread (drops frames during computation). Always use Reanimated.

Additional mobile tools:
- **Lottie**: pre-built animations (confetti, spinners) — `lottie-react-native`
- **Rive**: interactive state-machine animations (character reactions in MathMind)
- **Shared Element Transitions**: seamless screen-to-screen morphing

## Sources
- framer/motion documentation and examples
- software-mansion/react-native-reanimated worklet pattern
- Apple Human Interface Guidelines (animation timing)

## Changelog
- 2026-03-21: Initial skill — advanced animation and interaction
