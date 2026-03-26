---
name: design-ecosystem
description: Complete map of every design component library, animation framework, and pattern available. Reference when selecting components, animations, or patterns for V0 prompts. Covers Magic UI (70 animated components), Shadcn UI (40+ core), 150+ community registries, Framer Motion patterns, and Apple HIG rules.
---

# Design Ecosystem Knowledge

## Magic UI (repos/magicui — 70 components)

### Complete Component List
**Text Animation**: animated-gradient-text, animated-shiny-text, aurora-text, comic-text, hyper-text, line-shadow-text, morphing-text, sparkles-text, spinning-text, text-animate, text-reveal, typing-animation, word-rotate

**Background/Texture**: animated-grid-pattern, dot-pattern, flickering-grid, grid-pattern, interactive-grid-pattern, retro-grid, striped-pattern, warp-background

**Visual Effects**: border-beam, confetti, cool-mode, light-rays, meteors, neon-gradient-card, particles, pixel-image, progressive-blur, ripple, shine-border, video-text

**Buttons**: interactive-hover-button, pulsating-button, rainbow-button, ripple-button, shimmer-button, shiny-button, animated-subscribe-button

**Cards & Containers**: bento-grid, magic-card, safari (browser mockup), iphone (phone mockup), android (phone mockup), terminal, lens

**Data Display**: animated-beam, animated-circular-progress-bar, animated-list, avatar-circles, code-comparison, file-tree, icon-cloud, number-ticker, orbiting-circles

**Navigation**: dock, marquee, scroll-based-velocity, scroll-progress, smooth-cursor, pointer

**Device Mockups**: safari, iphone, android

**Misc**: animated-theme-toggler, client-tweet-card, dotted-map, globe, hero-video-dialog, highlighter, tweet-card

### When to Use Magic UI in V0 Prompts
| Need | Magic UI Component | V0 Prompt Phrase |
|---|---|---|
| Hero wow factor | globe, particles, meteors | "Use Magic UI Globe as hero background" |
| Animated stats/numbers | number-ticker | "Use Magic UI NumberTicker for the counters" |
| Text entrance | word-rotate, text-animate, typing-animation, blur-fade | "Use Magic UI BlurFade for section reveals" |
| Background texture | dot-pattern, retro-grid, flickering-grid | "Use Magic UI DotPattern as subtle background" |
| Button emphasis | shimmer-button, pulsating-button, rainbow-button | "Use Magic UI ShimmerButton for the CTA" |
| Card effects | magic-card, border-beam, neon-gradient-card | "Use Magic UI MagicCard with hover glow" |
| List animations | animated-list, marquee | "Use Magic UI AnimatedList for the feed" |
| Device mockup frame | iphone, safari | "Wrap the design in Magic UI iPhone mockup" |
| Scroll progress | scroll-progress, scroll-based-velocity | "Add Magic UI ScrollProgress bar at top" |
| Logo cloud | marquee, icon-cloud | "Use Magic UI Marquee for partner logos" |

## Shadcn UI Core Components (repos/shadcn-ui — 40+ components)

### Complete List
**Input**: Button, Input, Textarea, Select, Checkbox, RadioGroup, Switch, Slider, Toggle, ToggleGroup, InputOTP
**Layout**: Card, Separator, Tabs, Accordion, Collapsible, Sheet, Dialog, Drawer, ScrollArea, ResizablePanel, AspectRatio
**Data**: Table, Badge, Avatar, Calendar, HoverCard, Carousel
**Feedback**: Alert, AlertDialog, Toast (Sonner), Tooltip, Popover, Progress, Skeleton
**Navigation**: Breadcrumb, Command, DropdownMenu, Menubar, NavigationMenu, Pagination, ContextMenu
**Form**: Form, Label
**Overlay**: Dialog, Sheet, Drawer, Popover, HoverCard

## Top 20 Shadcn Community Registries (from repos/awesome-shadcn)

| Registry | What It Offers | Best For |
|---|---|---|
| **magicui.design** | 70 animated components | Animations, wow factor |
| **originui.com** | Beautiful base components | Clean, minimal UI |
| **aceternity-ui** | Trending animated components | Landing pages |
| **21st.dev** | NPM for shadcn components | Finding specific components |
| **shadcnblocks.com** | Pre-built page blocks | Landing pages, marketing |
| **kokonutui.com** | Modern components | Next.js apps |
| **cult-ui.com** | Animated shadcn components | Interactive UIs |
| **eldoraui.site** | Animated components | Motion-heavy interfaces |
| **hexta-ui** | Modern responsive components | Full apps |
| **novel** | Notion-style WYSIWYG editor | Rich text editing |
| **plate** | AI-powered rich-text editor | Document editing |
| **shadcn-chat** | Chat UI components | Chat/messaging features |
| **assistant-ui** | AI chat components | AI interfaces |
| **auto-form** | Auto-generated forms from zod | Form-heavy apps |
| **file-uploader** | File upload with react-dropzone | Upload flows |
| **roadmap-ui** | Interactive roadmaps | Planning features |
| **kibo-ui.com** | Comprehensive component library | Complex apps |
| **launch-ui** | Landing page components | Marketing sites |
| **commerce-ui** | E-commerce components | Storefronts |
| **number-flow** | Number transition animations | Financial/stats displays |

## Framer Motion Key Patterns (repos/framer-motion)

### Core Animation
```tsx
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0, y: -20 }}
  transition={{ duration: 0.3, ease: "easeOut" }}
/>
```

### Scroll-Linked
```tsx
const { scrollYProgress } = useScroll()
const opacity = useTransform(scrollYProgress, [0, 0.5], [0, 1])
```

### Stagger Children
```tsx
const container = { transition: { staggerChildren: 0.1 } }
const item = { initial: { opacity: 0 }, animate: { opacity: 1 } }
```

### Layout Animations
```tsx
<motion.div layoutId="shared-element" /> // Shared layout transitions
```

### Gestures
```tsx
<motion.button
  whileHover={{ scale: 1.05 }}
  whileTap={{ scale: 0.95 }}
  whileInView={{ opacity: 1 }}
/>
```

### Spring Physics
```tsx
transition={{ type: "spring", stiffness: 300, damping: 30 }}
```

### V0 Prompt for Framer Motion
"Use Framer Motion for: page transitions with AnimatePresence, card hover scale with whileHover, list items with stagger animation, scroll-triggered reveals with whileInView"

## Apple HIG — iOS Design Rules

### Typography (SF Pro)
- Large Title: 34pt bold
- Title 1: 28pt bold
- Title 2: 22pt bold
- Title 3: 20pt semibold
- Headline: 17pt semibold
- Body: 17pt regular
- Callout: 16pt regular
- Subhead: 15pt regular
- Footnote: 13pt regular
- Caption 1: 12pt regular
- Caption 2: 11pt regular

### Spacing & Layout
- Standard margins: 16pt (compact), 20pt (regular)
- Minimum touch target: 44×44pt
- Navigation bar height: 44pt (plus status bar)
- Tab bar height: 49pt (plus home indicator 34pt = 83pt total)
- Status bar: 54pt (iPhone with Dynamic Island)
- Home indicator: 34pt
- Safe area insets: respect all edges

### Navigation Patterns
- Tab Bar: 2-5 tabs max, icons above labels, active state highlighted
- Navigation Bar: back button left, title center, actions right
- Modal: full-screen or sheet (detent at medium/large)
- Search: search bar in navigation bar or inline

### Dark Mode Rules
- Use semantic colors (system backgrounds, labels)
- Elevated surfaces get lighter, not darker
- Reduce saturation slightly for dark backgrounds
- Maintain same contrast ratios as light mode
- Blur effects adapt automatically

### Gesture Conventions
- Swipe back: navigate back in stack
- Pull down: dismiss modal sheet
- Long press: context menu
- Pinch: zoom
- Edge swipe: tab switching (in some contexts)

### Accessibility
- 4.5:1 contrast ratio minimum for text
- 3:1 for large text and UI elements
- Support Dynamic Type (scalable text)
- VoiceOver labels on all interactive elements
- Reduce Motion preference support

## Component Selection Guide

| Need | Best Option | V0 Prompt |
|---|---|---|
| Standard form | Shadcn Form + Input | "Use Shadcn Form with Input, Select" |
| Data table | Shadcn Table + DataTable | "Use Shadcn DataTable with sorting" |
| Modal dialog | Shadcn Dialog or Sheet | "Use Shadcn Sheet for mobile drawer" |
| Toast notification | Sonner | "Use Sonner for toast notifications" |
| Animated hero | Magic UI Globe + BlurFade | "Use Magic UI Globe with BlurFade text" |
| Stats dashboard | Shadcn Card + Magic UI NumberTicker | "Use NumberTicker inside Shadcn Cards" |
| Navigation | Shadcn Tabs (bottom) | "Bottom tab bar with Shadcn Tabs" |
| Charts | Recharts | "Use Recharts LineChart/BarChart" |
| File upload | shadcn-dropzone | "Use file-uploader component" |
| Rich text | Plate or Novel | "Use Plate editor" |
| Chat UI | shadcn-chat or assistant-ui | "Use assistant-ui for chat" |
| Background | Magic UI DotPattern/Particles | "Magic UI Particles as bg" |
| Loading | Shadcn Skeleton | "Skeleton loading state" |
| Page transitions | Framer Motion AnimatePresence | "AnimatePresence page transitions" |

## Changelog
- 2026-03-20: Initial ecosystem mapping — 70 Magic UI components cataloged, 20 community registries, Framer Motion patterns, Apple HIG rules
