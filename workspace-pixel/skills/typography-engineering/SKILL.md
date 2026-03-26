---
name: typography-engineering
description: "10+ premium font pairings, type scale system, responsive typography, advanced CSS. Every pairing with Google Fonts URL + Tailwind config. Use when choosing fonts, building type scales, or specifying typography for any project."
---

# Typography Engineering

Reference this skill for all typography decisions. Every font has source, weights, and Tailwind config.

## Premium Font Catalog (12 Fonts)

| # | Font | Category | Vibe | Best For | Source | Weights |
|---|------|----------|------|----------|--------|---------|
| 1 | **Barlow** | Sans-serif | Clean, technical | Body on dark themes, agency | Google Fonts | 300–600 |
| 2 | **Satoshi** | Sans-serif | Modern, geometric, premium | SaaS, AI/tech brands | fontshare.com (self-host) | 400–900 |
| 3 | **Instrument Serif** | Serif | Elegant, editorial | Hero headings, luxury | Google Fonts | italic only |
| 4 | **Inter** | Sans-serif | Precise, neutral, data-friendly | Dashboards, data UIs, body | Google Fonts | variable 300–700 |
| 5 | **Telegraf** | Sans-serif | Bold, contemporary | Headlines, creative agencies | pangram.co (self-host) | 400–800 |
| 6 | **Space Grotesk** | Sans-serif | Tech-forward, monospace DNA | Dev tools, AI, crypto | Google Fonts | 300–700 |
| 7 | **Poppins** | Sans-serif | Friendly, rounded | Consumer products, mobile | Google Fonts | 100–900 |
| 8 | **Montserrat** | Sans-serif | Classic modern | All-purpose, corporate | Google Fonts | 100–900 |
| 9 | **Lato** | Sans-serif | Warm, humanist | Long-form content | Google Fonts | 100–900 |
| 10 | **Roboto** | Sans-serif | Neutral, mechanical | Material Design, utility | Google Fonts | 100–900 |
| 11 | **Orbitron** | Display | Futuristic, geometric | Sci-fi, architecture, portfolios | Google Fonts | 400–900 |
| 12 | **JetBrains Mono** | Monospace | Technical, precise | Code, stats, labels | Google Fonts | 100–800 |

---

## Premium Pairings (8 Combinations)

### 1. Dark Premium / Apple-Inspired
**Heading:** Instrument Serif (italic) • **Body:** Barlow (light 300)
```
Google: fonts.googleapis.com/css2?family=Instrument+Serif:ital@1&family=Barlow:wght@300;400;500
Tailwind: fontFamily: {
  heading: ["'Instrument Serif'", "Georgia", "serif"],
  body: ["'Barlow'", "system-ui", "sans-serif"],
}
```
Use for: Agency sites, luxury landing pages, dark premium portfolios.

### 2. Editorial Premium
**Heading:** Instrument Serif (italic) • **Body:** Inter (300–400)
```
Google: fonts.googleapis.com/css2?family=Instrument+Serif:ital@1&family=Inter:wght@300;400;500
Tailwind: fontFamily: {
  heading: ["'Instrument Serif'", "Georgia", "serif"],
  body: ["'Inter'", "system-ui", "sans-serif"],
}
```
Use for: Portfolios, content-heavy pages, editorial sites.

### 3. Futuristic / Cinematic
**Heading:** Orbitron • **Body:** Space Grotesk • **Mono:** JetBrains Mono
```
Google: fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Space+Grotesk:wght@300;400;500&family=JetBrains+Mono:wght@400;500
Tailwind: fontFamily: {
  display: ["'Orbitron'", "monospace"],
  body: ["'Space Grotesk'", "system-ui", "sans-serif"],
  mono: ["'JetBrains Mono'", "monospace"],
}
```
Use for: Architecture, sci-fi, tech portfolios, gaming.

### 4. Developer / Data Platform
**Heading:** Space Grotesk (medium) • **Body:** Inter (regular) • **Mono:** JetBrains Mono
```
Google: fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@300;400;500;600&family=JetBrains+Mono:wght@400;500;600;700
Tailwind: fontFamily: {
  heading: ["'Space Grotesk'", "system-ui", "sans-serif"],
  body: ["'Inter'", "system-ui", "sans-serif"],
  mono: ["'JetBrains Mono'", "monospace"],
}
```
Use for: Dev tools, AI platforms, dashboards, competitive platforms.

### 5. Clean Modern SaaS
**Heading:** Satoshi (bold) • **Body:** Satoshi (regular)
```
Source: fontshare.com — self-host .woff2 in /public/fonts/
Tailwind: fontFamily: {
  heading: ["'Satoshi'", "system-ui", "sans-serif"],
  body: ["'Satoshi'", "system-ui", "sans-serif"],
}
```
Use for: SaaS products, startups, clean marketing sites.

### 6. Bold Contemporary
**Heading:** Telegraf (bold) • **Body:** Barlow (regular)
```
Source: pangram.co (Telegraf self-host) + Google Fonts (Barlow)
Tailwind: fontFamily: {
  heading: ["'Telegraf'", "system-ui", "sans-serif"],
  body: ["'Barlow'", "system-ui", "sans-serif"],
}
```
Use for: Creative agencies, bold brands, portfolio sites.

### 7. Distinctive Startup
**Heading:** Clash Display • **Body:** Satoshi
```
Source: fontshare.com — self-host both
```
Use for: Brand-forward sites, startup landing pages.

### 8. Friendly Consumer
**Heading:** Poppins (semibold) • **Body:** Poppins (regular)
```
Google: fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700
Tailwind: fontFamily: {
  heading: ["'Poppins'", "system-ui", "sans-serif"],
  body: ["'Poppins'", "system-ui", "sans-serif"],
}
```
Use for: Consumer apps, onboarding, mobile-friendly sites.

---

## Type Scale System (Desktop → Mobile)

| Element | Size (Desktop) | Size (Mobile) | Weight | Tracking | Leading |
|---------|----------------|---------------|--------|----------|---------|
| Display/Hero | 56–72px (3.5–4.5rem) | 36–44px | 700–800 | -0.02em | 0.9–1.05 |
| H1 | 48px (3rem) | 32px (2rem) | 700 | -0.02em | 1.05–1.1 |
| H2 | 36px (2.25rem) | 26–28px | 600–700 | -0.015em | 1.1–1.15 |
| H3 | 24–28px | 20–22px | 600 | -0.01em | 1.2 |
| H4 | 20–22px | 18px | 500–600 | 0 | 1.3 |
| Body Large | 18px (1.125rem) | 16px | 400 | 0 | 1.6 |
| Body | 15–16px | 15–16px | 400 | 0–0.01em | 1.6 |
| Body Small | 13–14px | 13px | 400 | 0.01em | 1.5 |
| Caption/Label | 11–12px | 11–12px | 500–600 | 0.03–0.06em | 1.3–1.4 |
| Stat Value | 28–32px | 22–24px | 700 (mono) | -0.02em | 1.0 |
| Code/Data | 13–14px | 13px | 400 (mono) | 0.02em | 1.6 |

---

## Font Loading Rules

1. Load ONLY the weights you use — never load full weight ranges
2. `font-display: swap` always (prevent FOIT)
3. Non-Google fonts (Satoshi, Telegraf, Clash Display): self-host `.woff2` in `/public/fonts/`
4. Variable fonts (Inter, Barlow) = one file for all weights = smaller bundle
5. Tailwind config ALWAYS includes fallback stack
6. Preconnect: `<link rel="preconnect" href="https://fonts.googleapis.com" />`

---

## Advanced CSS Typography

**Negative tracking on large headings:**
```css
.hero { letter-spacing: -0.02em; } /* tight */
.display { letter-spacing: -0.03em; } /* very tight for massive text */
```

**Uppercase labels with wide tracking:**
```css
.label { text-transform: uppercase; letter-spacing: 0.06em; font-size: 11px; font-weight: 600; }
```

**Tabular numbers (monospace alignment in tables/stats):**
```css
.stat { font-variant-numeric: tabular-nums; }
```
Tailwind: `tabular-nums`

**Optical sizing:**
```css
font-optical-sizing: auto; /* Let variable fonts optimize for size */
```

**Truncation:**
```css
.truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
```

---

## Rules
- Body text: never below 15px on web, 16px on mobile.
- Headlines: always negative tracking (-0.01em to -0.03em).
- Max 2 font families per project (+ 1 monospace if needed).
- Font weight contrast between heading and body: minimum 200 weight difference (e.g., 700 heading, 400 body).
- Always specify: family, weight, size per breakpoint, tracking, leading, color, and opacity.
