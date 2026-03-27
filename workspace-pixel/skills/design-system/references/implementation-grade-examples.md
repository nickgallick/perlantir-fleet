# Implementation-Grade Design Reference Library

## Saved: 2026-03-22
## Source: Nick (direct specification)
## Purpose: Quality bar for ALL design specs — every value must be exact

---

## PREMIUM FONT GUIDE

| # | Font | Category | Vibe | Best For | Source |
|---|------|----------|------|----------|--------|
| 1 | **Barlow** | Sans-serif | Clean, technical, versatile | Body on dark themes, agency sites | Google Fonts (300-600) |
| 2 | **Satoshi** | Sans-serif | Modern, geometric, premium | SaaS, AI/tech brands | fontshare.com (self-host) |
| 3 | **Instrument Serif** | Serif | Elegant, editorial, italic-forward | Hero headings, luxury | Google Fonts (italic) |
| 4 | **Inter** | Sans-serif | Precise, neutral, data-friendly | Dashboards, data-heavy UIs, body text | Google Fonts (variable 300-700) |
| 5 | **Telegraf** | Sans-serif | Bold, contemporary, geometric | Headlines, creative agencies | pangram.co (self-host) |
| 6 | **Space Grotesk** | Sans-serif | Tech-forward, monospace-adjacent | Developer tools, AI, crypto | Google Fonts (300-700) |
| 7 | **Poppins** | Sans-serif | Friendly, rounded, approachable | Consumer products, mobile apps | Google Fonts (100-900) |
| 8 | **Montserrat** | Sans-serif | Classic modern, geometric | All-purpose, corporate | Google Fonts (100-900) |
| 9 | **Lato** | Sans-serif | Warm, humanist, readable | Long-form content, professional | Google Fonts (100-900) |
| 10 | **Roboto** | Sans-serif | Neutral, mechanical | Material Design, utility | Google Fonts (100-900) |
| 11 | **Orbitron** | Display | Futuristic, geometric, technical | Sci-fi, architecture, tech portfolios | Google Fonts (400-900) |
| 12 | **JetBrains Mono** | Monospace | Technical, precise, developer | Code, technical specs, labels | Google Fonts (100-800) |

### Premium Pairing Combinations

| Heading | Body | Mono/Technical | Vibe | Use For |
|---------|------|----------------|------|---------|
| Instrument Serif (italic) | Barlow (light 300) | — | Dark premium, Apple-inspired | Agency sites, luxury landing pages |
| Instrument Serif (italic) | Inter (300-400) | — | Editorial premium | Portfolios, content-heavy pages |
| Orbitron | Space Grotesk | JetBrains Mono | Futuristic, cinematic | Architecture, sci-fi, tech portfolios |
| Space Grotesk (medium) | Inter (regular) | JetBrains Mono | Developer-focused | Dev tools, AI platforms, dashboards |
| Satoshi (bold) | Satoshi (regular) | — | Clean modern | SaaS products, startups |
| Telegraf (bold) | Barlow (regular) | — | Bold contemporary | Creative agencies, bold brands |
| Clash Display | Satoshi | — | Distinctive, startup | Brand-forward sites |
| Poppins (semibold) | Poppins (regular) | — | Friendly, approachable | Consumer apps, onboarding |

### Font Loading Rules
- Load ONLY the weights you use
- font-display: swap (prevent FOIT)
- Non-Google fonts (Satoshi, Telegraf): self-host .woff2 in /public/fonts/
- Variable fonts (Inter, Barlow) = one file for all weights = smaller bundle
- Tailwind config ALWAYS includes fallback stack:
  - heading: ["'Instrument Serif'", "Georgia", "serif"]
  - body: ["'Barlow'", "system-ui", "sans-serif"]
  - display: ["'Orbitron'", "monospace"]
  - mono: ["'JetBrains Mono'", "monospace"]

---

## REFERENCE 1: DARK PREMIUM — "Liquid Glass" Agency Landing Page

**Aesthetic:** Pure black bg, Apple-inspired, liquid glass morphism, HLS video bgs, premium serif + sans-serif
**Tech:** React + Vite + TypeScript + Tailwind + shadcn/ui + hls.js + Framer Motion + Lucide
**Fonts:** Instrument Serif (italic headings) + Barlow (light body)

### Design System
```css
:root {
  --background: 213 45% 67%;
  --foreground: 0 0% 100%;
  --primary: 0 0% 100%;
  --border: 0 0% 100% / 0.2;
  --radius: 9999px;
}
```
- All headings: font-heading italic text-white tracking-tight leading-[0.9]
- All body: font-body font-light text-white/60 text-sm
- All buttons: font-body rounded-full
- All badges: liquid-glass rounded-full px-3.5 py-1 text-xs font-medium text-white font-body inline-block mb-4
- All section headings: text-4xl md:text-5xl lg:text-6xl font-heading italic text-white tracking-tight leading-[0.9]
- All video fades: 200px height, linear-gradient(to bottom/top, black, transparent)

### Liquid Glass CSS (Signature Effect)
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
  position: absolute; inset: 0;
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

### Sections
- **Navbar:** Fixed top-4 z-50, liquid-glass pill center, solid bg-white text-black rounded-full CTA right
- **Hero (h-[1000px]):** Video bg absolute top-[20%] object-contain z-0, overlay bg-black/5, bottom gradient h-[300px], BlurText word-by-word (blur(10px)→blur(0px), opacity 0→1, y 50→0, 0.35s/step, 100ms delay/word), CTAs at 1.1s delay
- **Partners:** text-2xl md:text-3xl font-heading italic text-white gap-12
- **How It Works:** HLS video bg via hls.js, top + bottom 200px black fades, badge → heading → subtext → CTA
- **Features chess:** Alternating lg:flex-row / lg:flex-row-reverse, GIFs in liquid-glass rounded-2xl
- **Features grid:** grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6, liquid-glass rounded-2xl p-6, icon in liquid-glass-strong rounded-full w-10 h-10
- **Stats:** Desaturated HLS video filter: saturate(0), liquid-glass rounded-3xl p-12 md:p-16, grid-cols-2 lg:grid-cols-4, values text-4xl md:text-5xl lg:text-6xl font-heading italic
- **Testimonials:** 3-col grid, liquid-glass rounded-2xl p-8, quote text-white/80 italic, role text-white/50 text-xs
- **CTA Footer:** HLS video bg, text-5xl md:text-6xl lg:text-7xl, liquid-glass-strong + bg-white text-black buttons, footer border-t border-white/10

---

## REFERENCE 2: LIGHT-TO-DARK — "New Digital Universe" Futuristic Landing

**Aesthetic:** Light hero (#FBFDFD) → dark (#0F0F0F) via diagonal SVG divider, system sans-serif, video blend modes
**Tech:** React + Vite + TypeScript + Tailwind + Lucide
**Fonts:** System sans-serif

### Key Techniques
Diagonal SVG section divider:
```html
<svg viewBox="0 0 1440 120" preserveAspectRatio="none" className="h-[60px] md:h-[120px]">
  <polygon points="0,0 0,120 1440,120 1440,80 920,80 680,0" fill="#0F0F0F" />
</svg>
```
Positioned absolute bottom-0 left-0 w-full z-[3] INSIDE the hero wrapper.

Video by breakpoint: Mobile: full width opacity-30. Desktop: w-[55%] full opacity, absolute right-0 top-0 bottom-0, object-cover object-top, mix-blend-mode: normal !important

Z-layers: z-0 solid bg → z-[1] video → z-[2] content → z-[3] divider

### Sections
- **Hero (light):** min-h-screen md:h-screen, heading text-[2.75rem] md:text-[5.5rem] leading-[0.95] font-light tracking-tight text-neutral-900, labels text-xs font-medium tracking-[0.3em] text-neutral-500 uppercase, CTA bg-neutral-900 text-white rounded px-6 py-3 md:px-8 md:py-3.5
- **About (dark #0F0F0F):** heading text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-light tracking-tight text-white leading-[1.05], pills rounded-full border border-neutral-700 text-sm text-neutral-300
- **Insights (tabbed):** text-4xl sm:text-5xl md:text-6xl lg:text-7xl xl:text-[5rem] font-light italic tracking-tight text-white leading-[1.05], images aspect-[4/3] rounded-2xl

---

## REFERENCE 3: CINEMATIC PORTFOLIO — "Modern Architect" Two-Page

**Aesthetic:** Cinematic, minimalist, dark, architectural. Video backgrounds, vignette overlays, page transitions
**Tech:** React + Tailwind + Framer Motion + Lucide
**Fonts:** Orbitron (display) + Space Grotesk (body) + JetBrains Mono (mono)

### Three-Font System
- Orbitron → font-display: massive titles, uppercase, tracking-tighter
- Space Grotesk → font-body: descriptions, font-light, max-w-[450px]
- JetBrains Mono → font-mono: nav counters, tech spec values, tags

### Vignette Overlays
- Desktop: radial-gradient(ellipse, transparent 70%, rgba(0,0,0,0.7) 100%)
- Mobile: linear-gradient(to top, rgba(0,0,0,0.8), transparent 60%)

### Sections
- **Hero:** Full-screen video bg, vignette overlay, title font-display uppercase tracking-tighter, glass card bg-white/5 backdrop-blur-xl rounded-xl, pill tags rounded-full border border-white/20 px-3 py-1 text-xs
- **Project Details:** Massive leading-[0.85] uppercase font-display, info blocks in uppercase mono, nav arrows rounded-full border border-white/20 w-10 h-10

---

## REFERENCE 4: GSAP-HEAVY PORTFOLIO — "Michael Smith" Dark Portfolio

**Aesthetic:** Dark, cinematic, GSAP scroll parallax, animated loading screen, marquee, complex hover interactions, lightbox
**Tech:** React + Vite + TypeScript + Tailwind + GSAP + Framer Motion + hls.js
**Fonts:** Inter (300-700 body) + Instrument Serif (italic display)

### Design System
```css
--bg: 0 0% 4%;        /* #0a0a0a */
--surface: 0 0% 8%;    /* #141414 */
--text: 0 0% 96%;      /* #f5f5f5 */
--muted: 0 0% 53%;     /* #888888 */
--stroke: 0 0% 12%;    /* #1f1f1f */
```
Accent gradient: linear-gradient(90deg, #89AACC 0%, #4E85BF 100%)

### Loading Screen
- fixed inset-0 z-[9999] bg-bg
- requestAnimationFrame counter 000→100 over 2700ms
- Rotating words ["Design", "Create", "Inspire"] every 900ms, text-4xl md:text-6xl lg:text-7xl font-display italic
- Counter text-6xl md:text-8xl lg:text-9xl font-display tabular-nums
- Progress bar h-[3px] with glow: box-shadow: 0 0 8px rgba(137, 170, 204, 0.35)

### Navbar (floating pill)
- fixed top-0 z-50, pill inline-flex rounded-full backdrop-blur-md border border-white/10 bg-surface px-2 py-2
- Logo: 9×9 circle, accent gradient border, inner bg-bg with initials font-display italic text-[13px]
- Links: text-xs sm:text-sm rounded-full px-3 sm:px-4 py-1.5 sm:py-2, active bg-stroke/50, inactive text-muted

### Hero
- HLS video bg, overlays bg-black/20 + bottom h-48 bg-gradient-to-t from-bg
- GSAP: ease "power3.out", y 50→0, 1.2s, delay 0.1s
- Name: text-6xl md:text-8xl lg:text-9xl font-display italic leading-[0.9] tracking-tight
- Role cycling: ["Creative", "Fullstack", "Founder", "Scholar"] every 2s, animate-role-fade-in

### Selected Works (Bento Grid)
- grid-cols-1 md:grid-cols-12 gap-5 md:gap-6, alternating col spans 7/5/5/7
- Cards: bg-surface border border-stroke rounded-3xl, hover scale-105
- Halftone: radial-gradient(circle, #000 1px, transparent 1px) 4×4px, opacity-20

### GSAP Scroll Parallax
- min-h-[300vh] for scroll-driven parallax
- Left: y "10vh" → "-120vh", scrub 1
- Right: y "40vh" → "-100vh", scrub 1.5
- Cards: rotation (id%2===0 ? 1 : -1) * (1.5 + id%3) degrees
- Lightbox: fixed z-[100] bg-black/95, Framer scale 0.9→1

### Marquee
- "BUILDING THE FUTURE • " ×10, text-5xl md:text-7xl lg:text-8xl font-display italic text-text-primary/10
- GSAP xPercent: -50, duration 40, ease "none", repeat -1

---

## THE 7 PATTERNS (QUALITY BAR)

1. **Every color is exact.** #0F0F0F, rgba(255,255,255,0.01), text-white/60, hsl(0 0% 53%). Never "dark" or "muted" without a value.
2. **Every spacing uses the system.** px-5 py-4 md:px-12 md:py-6, gap-12, mb-8. Never "some padding."
3. **Effects have complete CSS.** Liquid glass = ::before pseudo-element with mask-composite. Halftone = radial-gradient. Vignettes = exact gradient stops. Copy-pasteable.
4. **Animations have exact parameters.** Duration, delay, easing, from/to values. Always.
5. **Responsive is per-breakpoint.** text-[2.75rem] md:text-[5.5rem]. State exactly what changes.
6. **Z-index is explicit.** z-0 bg → z-[1] overlays → z-[2] content → z-50 nav → z-[100] lightbox → z-[9999] loading.
7. **Typography is fully specified.** Family + weight + size + responsive sizes + tracking + leading + color + opacity.

---

## 10-QUESTION QUALITY CHECK (run before submitting ANY design spec)

1. What color? → hex or Tailwind class with opacity
2. What font? → family, weight, size per breakpoint, tracking, leading, style
3. What spacing? → exact Tailwind values with responsive breakpoints
4. What effect? → complete CSS including pseudo-elements, filters, shadows
5. What animation? → exact Framer Motion or GSAP props (initial, animate, transition, easing, duration, delay)
6. What layout? → grid/flex columns per breakpoint, gap, max-width
7. What z-order? → explicit z-index for every layered element
8. What on hover? → exact state change (color, scale, shadow, border)
9. What on mobile? → exactly what changes at sm/md/lg/xl
10. What accessibility? → ARIA labels, keyboard focus, reduced motion

**If any question can't be answered from your spec, the spec isn't done.**
