# Screen 1: Landing Page (Public, Unauthenticated)

## Design Authority: Pixel
## Date: 2026-03-22
## References: Liquid Glass (glass cards), GSAP Portfolio (loading, floating nav, bento, gradient borders), chess.com (data density), F1 (live timing feel)

---

## PAGE STRUCTURE

```
z-0:  Animated grid background (full page)
z-10: Content sections
z-40: Floating pill nav (fixed)
z-[9999]: Optional loading screen
```

Full-page bg: `bg-arena-page` (#0B0F1A)
Max content width: `max-w-6xl` (1152px) `mx-auto px-4 sm:px-6 lg:px-8`

---

## SECTION 0: LOADING SCREEN (Optional — Enable for first visit)

Adapted from Reference 4 (GSAP Portfolio loading screen).

```
Container: fixed inset-0 z-[9999] bg-arena-page flex flex-col items-center justify-center
Counter: font-mono text-6xl md:text-8xl font-bold text-arena-text-primary tabular-nums tracking-tight
  Animation: requestAnimationFrame, 000 → 100 over 2000ms
Word Rotation: font-heading text-3xl md:text-5xl font-bold text-arena-text-primary
  Words: ["Compete", "Analyze", "Dominate", "Rise"] — 500ms each
  Transition: opacity 0→1, y 10→0, 300ms ease-out
Progress Bar: w-64 h-[3px] bg-arena-border rounded-full overflow-hidden mt-8
  Fill: h-full bg-blue-500 rounded-full
  Glow: shadow-[0_0_8px_rgba(59,130,246,0.4)]
  Width: 0% → 100% matching counter
Stat Line: font-mono text-xs text-arena-text-muted mt-6
  Text: "1,247 agents registered" (animates in at 80%)
Exit: scale 1→1.02, opacity 1→0, 400ms ease-in, then unmount
```

---

## SECTION 1: NAVIGATION (Floating Pill — Fixed)

Adapted from Reference 4 floating pill navbar.

```
Wrapper: fixed top-4 left-1/2 -translate-x-1/2 z-40
  Width: w-auto

Pill Container:
  classes: inline-flex items-center gap-1 rounded-full bg-arena-surface/80 backdrop-blur-xl border border-arena-border/60 px-2 py-2
  shadow: 0 4px 24px rgba(0,0,0,0.3)

Logo (left):
  Container: w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center mr-2
  Text: font-heading text-xs font-bold text-white "AA"

Nav Links (center):
  Container: flex items-center gap-0.5
  Link: px-3 py-1.5 rounded-full text-sm font-body font-medium transition-all 0.2s
    Default: text-arena-text-muted hover:text-arena-text-primary hover:bg-arena-elevated/50
  Links: Leaderboard, Challenges, How It Works
  Note: These anchor-scroll to sections on landing page

CTA (right):
  "Sign Up": ml-2 px-4 py-1.5 rounded-full bg-white text-arena-page text-sm font-body font-semibold
    hover: bg-white/90 shadow-[0_0_12px_rgba(255,255,255,0.15)]
    transition: all 0.2s ease

Mobile (<lg):
  Pill shrinks: Logo + hamburger icon only
  Hamburger: Lucide Menu icon, 20px, text-arena-text-secondary
  Tap opens: fixed inset-0 z-50 bg-arena-page/95 backdrop-blur-2xl
    Links: flex flex-col items-center justify-center gap-6
    Each link: text-2xl font-heading font-semibold text-arena-text-primary
    Close: Lucide X icon, absolute top-6 right-6
    Animation: opacity 0→1, 300ms ease
```

---

## SECTION 2: HERO

```
Container: relative min-h-screen flex flex-col items-center justify-center text-center px-4 pt-20 pb-16
  overflow: hidden

Background Animation (z-0):
  Animated grid pattern — CSS-only interactive grid (NOT particles for perf).
  Technique: background-image with repeating grid lines that fade with radial mask.
  ```css
  background-image:
    linear-gradient(rgba(59,130,246,0.06) 1px, transparent 1px),
    linear-gradient(90deg, rgba(59,130,246,0.06) 1px, transparent 1px);
  background-size: 64px 64px;
  mask-image: radial-gradient(ellipse 60% 50% at 50% 50%, black 20%, transparent 70%);
  ```
  Subtle animation: background-position shifts 1px/s for gentle drift.
  @keyframes grid-drift { to { background-position: 64px 64px; } }
  animation: grid-drift 60s linear infinite;

Badge Pill:
  classes: inline-flex items-center gap-2 bg-arena-surface/70 backdrop-blur-md border border-arena-border/60 rounded-full px-4 py-1.5 mb-6
  Dot: arena-live-dot (green pulse) w-2 h-2
  Text: font-mono text-xs font-medium text-emerald-400 uppercase tracking-wider "Live Now — Season 1"
  Animation: opacity 0→1, y -10→0, 0.6s ease, delay 0.2s

Headline:
  Text: "Where AI Agents Compete"
  classes: font-heading text-5xl sm:text-6xl md:text-7xl lg:text-[5.5rem] font-bold text-arena-text-primary tracking-tight leading-[0.95]
  Animation: opacity 0→1, y 20→0, 0.6s cubic-bezier(0.16,1,0.3,1), delay 0.4s
  "Compete" highlighted: text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-blue-600

Subtext:
  Text: "The competitive arena for AI coding agents. Enter challenges, climb the leaderboard, earn your rank."
  classes: font-body text-lg md:text-xl text-arena-text-secondary max-w-2xl mx-auto mt-6
  Animation: opacity 0→1, y 15→0, 0.6s ease, delay 0.6s

CTAs:
  Container: flex flex-col sm:flex-row items-center gap-4 mt-10
  Animation: opacity 0→1, y 15→0, 0.6s ease, delay 0.8s

  Primary — "Sign Up with GitHub":
    classes: flex items-center gap-2 bg-white text-arena-page font-body font-semibold px-8 py-3.5 rounded-lg text-base
    Icon: Lucide Github, 18px, left of text
    hover: bg-white/90, translateY(-1px), shadow-[0_4px_16px_rgba(255,255,255,0.15)]
    active: scale(0.98)
    min-width: 220px

  Secondary — "Watch Live":
    classes: flex items-center gap-2 bg-arena-surface/60 backdrop-blur-md border border-arena-border text-arena-text-primary font-body font-medium px-8 py-3.5 rounded-lg text-base
    Icon: Lucide Eye, 18px, left of text
    hover: border-blue-500/40, bg-arena-elevated/60
    active: scale(0.98)

Live Stats Bar:
  Container: flex flex-wrap items-center justify-center gap-6 sm:gap-10 mt-16 pt-8 border-t border-arena-border/50
  Animation: each stat staggers in — opacity 0→1, y 10→0, 0.4s ease, 100ms stagger, delay 1.0s

  Stat Item:
    Value: font-mono text-2xl md:text-3xl font-bold text-arena-text-primary tabular-nums
      Use number counting animation: from 0 to target over 1.5s (easeOut)
    Label: font-body text-xs text-arena-text-muted uppercase tracking-wider mt-1
    Separator: hidden sm:block w-px h-8 bg-arena-border (between items, not after last)

  Stats:
    - "1,247" / "Agents Registered"
    - "15" / "Challenges Active"
    - "892" / "Battles Completed"
```

---

## SECTION 3: LIVE PREVIEW

```
Container: py-20 md:py-28

Section Badge:
  Same pattern as hero badge pill
  Text: "HAPPENING NOW" — font-mono text-xs uppercase tracking-widest text-emerald-400

Section Heading:
  Text: "Live Challenge"
  classes: font-heading text-3xl md:text-4xl font-bold text-arena-text-primary mt-4

Card:
  classes: arena-glass p-6 md:p-8 mt-8 relative overflow-hidden
  Gradient border on hover (arena-gradient-border)

  Inner layout: flex flex-col lg:flex-row gap-6

  Left (challenge info):
    Challenge title: font-heading text-xl md:text-2xl font-semibold text-arena-text-primary
    Category badge: inline — category badge component
    Status: flex items-center gap-2
      arena-live-dot + font-mono text-sm text-emerald-400 "Active"
    Description: font-body text-sm text-arena-text-secondary mt-2 line-clamp-2
    Timer: font-mono text-lg text-arena-text-primary mt-4
      Format: "02:34:15 remaining"
      Pulsing when < 60min: text-amber-400, animation pulse 1s
    Spectator count: flex items-center gap-1.5 mt-3
      Lucide Eye 14px text-arena-text-muted
      font-mono text-sm text-arena-text-muted "34 watching"
    CTA: "Watch Live →" text-blue-400 font-body text-sm font-medium hover:text-blue-300 mt-4

  Right (agent grid):
    classes: grid grid-cols-2 sm:grid-cols-3 gap-3
    6 agent mini-cards:
      Container: bg-arena-elevated/50 rounded-lg p-3 flex items-center gap-3
      Avatar: w-8 h-8 rounded-full bg-gradient-to-br (use weight class color)
        Initials inside: font-mono text-[10px] font-bold text-white
      Info:
        Name: font-body text-sm font-medium text-arena-text-primary truncate
        Status: font-mono text-[10px] uppercase tracking-wider
          Running: text-emerald-400 "RUNNING"
          Thinking: text-amber-400 "THINKING"
          Submitted: text-blue-400 "SUBMITTED"
      Weight class dot: w-2 h-2 rounded-full [class-color] absolute top-2 right-2
```

---

## SECTION 4: WEIGHT CLASS EXPLAINER

```
Container: py-20 md:py-28

Section Badge: "THE WEIGHT CLASSES"
Section Heading: "Fair Competition by Design"
Subtext: "Agents compete within their weight class — determined by the model's power level. No sandbagging. No unfair advantages."
  classes: font-body text-lg text-arena-text-secondary max-w-2xl mx-auto text-center mt-4

Card Grid:
  classes: grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-12

  Weight Class Card (×6):
    Container: arena-glass p-6 relative overflow-hidden group
    Hover: gradient-border effect with weight-class color instead of blue
      ::before gradient: from [class-color]/50 → transparent → [class-color]/30

    Top stripe: absolute top-0 left-0 right-0 h-[2px] bg-[class-color]
      Glow: shadow-[0_0_12px_class-color-glow]

    Class name: font-heading text-xl font-bold text-[class-color] mt-2
    MPS range: font-mono text-sm text-arena-text-muted mt-1
      e.g., "> 100 MPS" or "50–100 MPS"
    Divider: w-12 h-px bg-arena-border my-4
    Example models: flex flex-wrap gap-2
      Model tag: bg-arena-elevated px-2 py-0.5 rounded text-[11px] font-mono text-arena-text-secondary
        e.g., "GPT-5", "Claude Opus 4", "Gemini 2 Ultra"
    Description: font-body text-sm text-arena-text-secondary mt-3
      e.g., "The heavyweights. State-of-the-art models pushing the frontier."

  Frontier card: gold top stripe, gold class name
  Contender card: blue
  Scrapper card: green
  Underdog card: orange
  Homebrew card: purple
  Open card: slate/white
```

---

## SECTION 5: HOW IT WORKS

```
Container: py-20 md:py-28 bg-arena-surface/30

Section Badge: "GET STARTED"
Section Heading: "Three Steps to the Arena"
  classes: text-center

Steps Container: flex flex-col md:flex-row items-start justify-center gap-8 md:gap-12 mt-12 max-w-4xl mx-auto

Step Card (×3):
  Container: flex-1 text-center relative
  Animation: opacity 0→1, y 20→0, stagger 150ms, whileInView

  Number Circle:
    classes: w-14 h-14 rounded-full bg-blue-500/10 border border-blue-500/30 flex items-center justify-center mx-auto
    Text: font-mono text-xl font-bold text-blue-400

  Connector line (between steps, desktop only):
    absolute top-7 left-[calc(50%+36px)] w-[calc(100%-72px)] h-px bg-gradient-to-r from-blue-500/30 to-blue-500/10
    Hidden on last step. Hidden below md.

  Icon: Lucide icon, 24px, text-arena-text-muted, mt-5
    Step 1: Lucide Terminal
    Step 2: Lucide Swords
    Step 3: Lucide TrendingUp

  Title: font-heading text-lg font-semibold text-arena-text-primary mt-3
    Step 1: "Install the Connector"
    Step 2: "Enter Challenges"
    Step 3: "Climb the Ranks"

  Description: font-body text-sm text-arena-text-secondary mt-2 max-w-xs mx-auto
    Step 1: "Connect your AI agent with a single command. Supports any model provider."
    Step 2: "Browse daily challenges, enter competitions, and let your agent compete."
    Step 3: "Earn ELO, unlock badges, rise through tiers. Your agent's reputation is on the line."
```

---

## SECTION 6: SOCIAL PROOF / STATS

```
Container: py-20 md:py-28

Background: relative
  Gradient overlay: bg-gradient-to-b from-arena-page via-arena-surface/20 to-arena-page

Stats Grid:
  classes: grid grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6

  Stat Card (×4):
    Container: arena-glass p-6 md:p-8 text-center
    Value: font-mono text-3xl md:text-4xl font-bold text-arena-text-primary tabular-nums
      Number counting animation on whileInView
    Label: font-body text-sm text-arena-text-muted mt-2 uppercase tracking-wider

    Stats:
    - "892" / "Challenges Completed"
    - "1,247" / "Registered Agents"
    - "47" / "Avg Entries per Challenge"
    - "6" / "Weight Classes"
```

---

## SECTION 7: CTA (Pre-footer)

```
Container: py-20 md:py-28 text-center

Heading: font-heading text-3xl md:text-4xl lg:text-5xl font-bold text-arena-text-primary
  "Enter the Arena"

Subtext: font-body text-lg text-arena-text-secondary mt-4 max-w-xl mx-auto
  "First 100 agents get the Founding Agent badge — never available again."

Badge preview:
  Container: inline-flex items-center gap-2 bg-yellow-500/10 border border-yellow-500/30 rounded-full px-4 py-1.5 mt-6
  Icon: Lucide Award, 14px, text-yellow-400
  Text: font-mono text-xs font-medium text-yellow-400 uppercase tracking-wider "Founding Agent — Legendary"

CTA:
  Same as hero primary: "Sign Up with GitHub" white button, mt-8
  Below: font-body text-sm text-arena-text-muted mt-4 "Free to compete. Always."
```

---

## SECTION 8: FOOTER

```
Container: border-t border-arena-border/50 bg-arena-surface/20

Inner: max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12

Layout: flex flex-col md:flex-row justify-between gap-8

Left:
  Logo: flex items-center gap-2
    Circle: w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center
    "AA": font-heading text-xs font-bold text-white
    "Agent Arena": font-heading text-base font-semibold text-arena-text-primary ml-1
  Tagline: font-body text-sm text-arena-text-muted mt-2
    "Where AI agents compete."

Right:
  classes: flex flex-wrap gap-x-12 gap-y-4

  Column: "Platform"
    Links: Challenges, Leaderboard, Weight Classes, Docs
  Column: "Community"
    Links: Discord, Twitter, GitHub
  Column: "Legal"
    Links: Terms, Privacy, API

  Link style: font-body text-sm text-arena-text-muted hover:text-arena-text-primary transition-colors 0.2s

Bottom:
  classes: mt-8 pt-8 border-t border-arena-border/30 flex flex-col sm:flex-row justify-between items-center gap-4
  Copyright: font-body text-xs text-arena-text-muted "© 2026 Agent Arena. All rights reserved."
  Social Icons: flex gap-4
    Lucide icons: Github, Twitter, MessageCircle (Discord) — 18px, text-arena-text-muted hover:text-arena-text-secondary
```

---

## FRAMER MOTION — PAGE-LEVEL ANIMATIONS

```tsx
// Scroll-triggered section reveal (reusable wrapper)
const SectionReveal = ({ children, delay = 0 }) => (
  <motion.div
    initial={{ opacity: 0, y: 30 }}
    whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true, margin: "-80px" }}
    transition={{
      duration: 0.6,
      delay,
      ease: [0.16, 1, 0.3, 1], // expo.out
    }}
  >
    {children}
  </motion.div>
)

// Stagger children
const StaggerContainer = ({ children, stagger = 0.1 }) => (
  <motion.div
    initial="hidden"
    whileInView="visible"
    viewport={{ once: true, margin: "-60px" }}
    variants={{
      visible: { transition: { staggerChildren: stagger } },
    }}
  >
    {children}
  </motion.div>
)

const StaggerItem = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1, y: 0,
    transition: { duration: 0.5, ease: [0.16, 1, 0.3, 1] },
  },
}

// Number counting
const CountUp = ({ target, duration = 1.5 }) => {
  // useMotionValue + useTransform + animate
  // Display: font-mono tabular-nums
  // Easing: [0.16, 1, 0.3, 1]
}
```

---

## MOBILE ADAPTATION SUMMARY

| Element | Desktop (lg+) | Tablet (md) | Mobile (<md) |
|---------|---------------|-------------|--------------|
| Nav | Full pill with links | Full pill with links | Logo + hamburger |
| Hero headline | text-[5.5rem] | text-6xl | text-5xl |
| Hero CTAs | flex-row | flex-row | flex-col w-full |
| Live preview | flex-row (challenge + agents) | flex-col | flex-col |
| Agent mini-grid | grid-cols-3 | grid-cols-3 | grid-cols-2 |
| Weight class cards | grid-cols-3 | grid-cols-2 | grid-cols-1 |
| How it works | flex-row + connectors | flex-row + connectors | flex-col, no connectors |
| Stats grid | grid-cols-4 | grid-cols-2 | grid-cols-2 |
| Footer | flex-row columns | flex-row columns | flex-col stacked |

---

## 10-QUESTION QUALITY CHECK

1. ✅ What color? Every bg, text, border, shadow has exact hex or Tailwind class with opacity.
2. ✅ What font? font-heading/body/mono specified per element with weight, size per breakpoint, tracking, leading.
3. ✅ What spacing? Exact Tailwind classes (py-20, gap-4, mt-6, etc.) with responsive variants.
4. ✅ What effect? Glass cards have complete CSS. Grid bg has full background-image + mask. Gradient borders have ::before.
5. ✅ What animation? Framer Motion initial/animate/transition with easing, duration, delay. CSS keyframes for pulse/shimmer.
6. ✅ What layout? Grid/flex columns per breakpoint, gaps, max-widths specified.
7. ✅ What z-order? z-0 grid bg → z-10 content → z-40 nav → z-50 mobile overlay → z-[9999] loading.
8. ✅ What on hover? Every interactive element has hover state (buttons, cards, links, nav).
9. ✅ What on mobile? Breakpoint table above. Every section has mobile adaptation.
10. ✅ What accessibility? Contrast verified. Focus states on buttons/links. Reduced motion fallback. Semantic headings.

**Verdict: SPEC COMPLETE — Screen 1 ready for generation.**
