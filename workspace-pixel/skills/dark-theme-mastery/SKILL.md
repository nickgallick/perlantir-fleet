---
name: dark-theme-mastery
description: "7-level dark color hierarchy, text on dark, light accents, glass on dark, elevation without shadows. Use when designing any dark-themed UI — backgrounds, text contrast, surface hierarchy, accent usage, glass effects on dark, and dark mode accessibility."
---

# Dark Theme Mastery

Reference this skill for every dark-themed design. Dark themes require a disciplined color hierarchy — not just "make it dark."

## The 7-Level Dark Hierarchy

Every dark UI needs exactly 7 surface levels, from deepest background to brightest text:

| Level | Role | Example Values | Usage |
|-------|------|----------------|-------|
| **1. Page BG** | Deepest layer | `#0A0A0A` `#0B0F1A` `#080C18` | Full-page background |
| **2. Surface** | Card/panel base | `#111827` `#141414` `#0F1628` | Cards, panels, table rows |
| **3. Elevated** | Raised elements | `#1A2332` `#1F1F1F` `#192236` | Modals, popovers, hover states, dropdowns |
| **4. Border** | Dividers, edges | `#1E293B` `#2A2A2A` `#1E2D40` | Borders, dividers, separators |
| **5. Muted text** | Lowest-priority text | `#475569` `#666666` `#4A5568` | Disabled text, placeholder, timestamps |
| **6. Secondary text** | Supporting text | `#94A3B8` `#888888` `#A0AEC0` | Descriptions, labels, body secondary |
| **7. Primary text** | Main content | `#F1F5F9` `#F5F5F5` `#E2E8F0` | Headings, body text, primary labels |

### Three Reference Palettes

**Slate (cool, enterprise):**
```css
--page: #0B0F1A; --surface: #111827; --elevated: #1A2332;
--border: #1E293B; --muted: #475569; --secondary: #94A3B8; --primary: #F1F5F9;
```

**Neutral (warm, minimal):**
```css
--page: #0A0A0A; --surface: #141414; --elevated: #1F1F1F;
--border: #2A2A2A; --muted: #666666; --secondary: #888888; --primary: #F5F5F5;
```

**Navy (branded, deep):**
```css
--page: #080C18; --surface: #0F1628; --elevated: #192236;
--border: #1E2D40; --muted: #4A5568; --secondary: #A0AEC0; --primary: #E2E8F0;
```

---

## Text Contrast Rules

| Text Level | Min Contrast (WCAG AA) | On Page BG | On Surface |
|------------|----------------------|------------|------------|
| Primary text | 4.5:1 (body) | ✅ 14:1+ | ✅ 12:1+ |
| Secondary text | 4.5:1 (body) | ✅ 6:1+ | ✅ 5:1+ |
| Muted text | 3:1 (large text/icons) | ✅ 3.2:1 | ⚠️ Check per palette |
| Accent (blue #3B82F6) | 4.5:1 (body) | ✅ 4.7:1 | ✅ 4.2:1 |

**Never** use muted text (#475569) for body-sized text on dark backgrounds — it only passes for large text (18px+) and icons.

---

## Accent Colors on Dark

**Blue accent system:**
```css
--accent: #3B82F6;        /* Primary actions, links */
--accent-hover: #2563EB;  /* Hover state */
--accent-muted: rgba(59,130,246,0.15); /* Backgrounds, highlights */
```

**Semantic colors:**
```css
--success: #10B981;       /* Wins, online, completions */
--success-bg: rgba(16,185,129,0.15);
--warning: #F59E0B;       /* Streaks at risk, pending */
--warning-bg: rgba(245,158,11,0.15);
--error: #EF4444;         /* Losses, errors, offline */
--error-bg: rgba(239,68,68,0.15);
```

**Pattern:** Semantic badges use `[color]/15` background + `[color]` text + `[color]/30` border.

---

## Elevation Without Shadows

On dark backgrounds, traditional box-shadows are nearly invisible. Use these techniques instead:

### 1. Surface Color Steps
Higher = lighter background:
```
Page → Surface (+1 step) → Elevated (+2 steps)
```
Tailwind: `bg-gray-900` → `bg-gray-800` → `bg-gray-700/50`

### 2. Border Emphasis
Brighter borders = more elevated:
```css
/* Base card */ border: 1px solid rgba(30,41,59,0.5);
/* Elevated */  border: 1px solid rgba(30,41,59,1.0);
/* Focused */   border: 1px solid rgba(59,130,246,0.4);
```

### 3. Subtle Inner Glow
```css
box-shadow: inset 0 1px 1px rgba(255,255,255,0.05);
```

### 4. Backdrop Blur (Glass)
Glass cards use blur to separate from background:
```css
backdrop-filter: blur(12px);
background: rgba(17,24,39,0.7);
```

---

## Glass on Dark

Glass effects look best on dark backgrounds because the blur creates visible depth.

**Light glass (subtle):**
```css
background: rgba(255,255,255,0.01);
backdrop-filter: blur(4px);
```

**Medium glass (cards):**
```css
background: rgba(17,24,39,0.7);
backdrop-filter: blur(12px);
border: 1px solid rgba(30,41,59,0.8);
```

**Strong glass (modals):**
```css
background: rgba(26,35,50,0.85);
backdrop-filter: blur(20px);
border: 1px solid rgba(30,41,59,1);
```

---

## Dark Theme Hover States

Since shadows don't work well, hover uses:

1. **Background lightening:** `hover:bg-elevated/50`
2. **Border brightening:** `hover:border-blue-500/30`
3. **Subtle glow:** `hover:shadow-[0_0_12px_rgba(59,130,246,0.15)]`
4. **Transform:** `hover:translateY(-2px)` (cards only)

```css
.card {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
.card:hover {
  background: rgba(26,35,50,0.5);
  border-color: rgba(59,130,246,0.3);
  transform: translateY(-2px);
}
```

---

## Focus States on Dark

```css
:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px #0B0F1A, 0 0 0 4px #3B82F6;
}
```
Tailwind: `focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 focus-visible:ring-offset-[#0B0F1A]`

---

## Common Anti-Patterns

1. **Pure black (#000000) as page bg.** Too harsh. Use #0A0A0A or #0B0F1A minimum.
2. **Pure white (#FFFFFF) text.** Too bright. Use #F1F5F9 or #F5F5F5 instead.
3. **Same border color for all levels.** Borders should be slightly lighter on elevated surfaces.
4. **Box-shadow for elevation.** Use surface color steps + borders instead.
5. **Low-opacity text for everything.** `text-white/40` fails WCAG. Use the 7-level system.
6. **Colored backgrounds at full saturation.** Use `/10` or `/15` opacity for colored backgrounds on dark.
7. **Forgetting focus states.** Dark backgrounds hide default focus rings — always add custom ones.

---

## Rules
- Define all 7 hierarchy levels before starting any dark design.
- Verify text contrast with a tool (WebAIM, Stark) — don't eyeball it.
- Accent colors use low-opacity backgrounds (`/10`–`/15`), never full-saturation fills.
- Every interactive element needs a visible hover state AND focus state.
- Test at full brightness AND low brightness — dark UIs must work in both conditions.
