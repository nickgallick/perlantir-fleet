# SKILL — Color Theory

Pixel's color knowledge. Color communicates meaning, creates hierarchy, and establishes brand identity.

---

## Building a Color System

Every color system has these layers:

### Primary Color
The main brand color. Used for primary actions, key interactive elements, and brand identity.
- One primary color per brand
- Must have accessible contrast on the brand's background
- Needs light and dark variants for hover/active states

### Secondary Color
A complementary color for supporting elements. Used for secondary actions, tags, and visual variety.
- Should harmonize with primary (complementary, analogous, or triadic)
- Lower visual weight than primary
- Used sparingly — secondary should never compete with primary

### Accent Color
A high-contrast pop color for emphasis. Used for notifications, badges, highlights, and callouts.
- Must stand out against both background and primary
- Used very sparingly — if everything is accented, nothing is
- Often warm (amber, orange) to contrast cool brand palettes

### Semantic Colors
Colors with fixed meaning across the entire application:

| Semantic | Color | Hex Range | Usage |
|----------|-------|-----------|-------|
| Success | Green | `#10B981` – `#22C55E` | Confirmations, completed states, positive indicators |
| Warning | Amber/Yellow | `#F59E0B` – `#EAB308` | Caution, pending states, attention needed |
| Error/Destructive | Red | `#EF4444` – `#DC2626` | Errors, failures, destructive actions |
| Info | Blue | `#3B82F6` – `#60A5FA` | Informational messages, help, tips |

**Rule**: Semantic colors must NEVER be used for non-semantic purposes. Green is always success. Red is always error/danger. No exceptions.

### Neutral Scale
A range of grays (or tinted grays) for backgrounds, text, borders, and non-interactive elements.
- Generate from background color (slightly tinted, not pure gray)
- Need at least 8-10 steps from darkest to lightest
- In dark themes: lighter neutrals for text, darker for backgrounds
- In light themes: darker neutrals for text, lighter for backgrounds

---

## Dark Theme Rules

All our brands use dark themes. These rules are critical:

1. **Never use pure black (#000000)** — Use near-black with a slight color tint (navy, charcoal, etc.)
2. **Never use pure white (#FFFFFF) for body text** — Use off-white (#E5E7EB, #F1F5F9, etc.)
3. **Create depth with surface layers, not shadows** — Shadow barely visible on dark backgrounds
4. **Surface elevation**: Background → Surface → Surface Elevated → Surface Top
5. **Reduce saturation of colors** — Highly saturated colors vibrate painfully on dark backgrounds
6. **Primary colors may need adjustment** — A color that works on white may not work on dark navy
7. **Test with f.lux / night mode** — Ensure colors remain distinguishable under warm screen tints
8. **Ensure borders are subtle** — Use low-opacity white borders (`rgba(255,255,255,0.1)`) not hard grays

### Dark Theme Surface Layers
```
Background:        #0A1628 (deepest)
Surface:           #111D30 (cards, containers)
Surface Elevated:  #1A2740 (dropdowns, popovers)
Surface Top:       #243350 (tooltips, overlays)
```
*(Values shown for Perlantir — adjust per brand)*

---

## Contrast Requirements (WCAG AA)

| Element | Minimum Ratio | How to Check |
|---------|---------------|--------------|
| Normal text (< 18px) | 4.5:1 | Text color vs background |
| Large text (≥ 18px bold or ≥ 24px) | 3:1 | Text color vs background |
| UI components (borders, icons) | 3:1 | Component color vs background |
| Focus indicators | 3:1 | Focus ring vs surrounding area |
| Graphical objects (charts, icons) | 3:1 | Each data element vs background |

### Testing Contrast
- Use WebAIM Contrast Checker or similar tool
- Test EVERY text color against its actual background (not just the page background)
- Test interactive states too — hover/focus colors must also pass
- Cards with backgrounds need their own contrast checks

---

## Color Psychology

Understanding what colors communicate:

| Color | Communicates | Use For |
|-------|-------------|---------|
| Blue | Trust, stability, professionalism | Enterprise, finance, communication |
| Green | Growth, success, nature, money | Fintech, health, sustainability |
| Red | Urgency, danger, energy, passion | Alerts, sales, entertainment |
| Purple | Premium, creative, wisdom | Luxury, creative tools, education |
| Orange/Amber | Energy, warmth, caution | CTAs, warnings, food/lifestyle |
| Cyan | Technology, clarity, innovation | Tech products, data, SaaS |
| Yellow | Optimism, attention, caution | Highlights, warnings, youth brands |
| Black/Dark | Premium, power, sophistication | Luxury, tech, professional |
| White/Light | Clean, simple, open | Minimalist, health, consumer |

### Our Brands and Their Color Psychology
- **Perlantir** (Dark Navy) — Authority, trust, institutional confidence
- **UberKiwi** (Electric Green) — Growth, energy, boldness, disruption
- **NERVE** (Cyan `#00D4FF`) — Technology, precision, futuristic intensity

---

## Common Color Mistakes

1. **Too many colors** — More than 3-4 intentional colors creates visual chaos. Neutrals don't count.
2. **Color as the only indicator** — Never communicate state through color alone. Always pair with icon, text, or pattern.
3. **Ignoring color blindness** — ~8% of men are color blind. Red/green is the most common conflict. Test with color blindness simulators.
4. **Insufficient contrast** — "It looks fine on my retina display" is not a contrast check. Use tools.
5. **Semantic color misuse** — Using red for a non-error purpose confuses users. Green for non-success is equally bad.
6. **Over-saturated colors on dark backgrounds** — They vibrate and cause eye strain. Reduce saturation 10-20%.
7. **Inconsistent opacity usage** — Pick standard opacity levels (10%, 20%, 50%, 70%) and use them consistently.
8. **No color documentation** — Every color used should be traceable to a design token. No hex codes in components.
9. **Gradient overuse** — Gradients should be subtle and purposeful. Not every surface needs a gradient.
10. **Ignoring ambient light** — Dark UIs look different in bright environments. Test in various lighting conditions.
