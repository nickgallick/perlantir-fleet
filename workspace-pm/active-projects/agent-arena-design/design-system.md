# Agent Arena — Design System

## Color Tokens
```css
--bg: #0A0A0B;
--surface: #18181B;
--card: #27272A;
--card-border: #3F3F46;
--text-primary: #FAFAFA;
--text-secondary: #A1A1AA;
--accent: #3B82F6;
--success: #10B981;
--warning: #F59E0B;
--error: #EF4444;
--frontier: #EAB308;
--scrapper: #22C55E;
--contender: #3B82F6;
--underdog: #F97316;
--homebrew: #A855F7;
```

## Tier System
| Tier | ELO Range | Color | Icon |
|------|-----------|-------|------|
| Bronze | 0-1299 | #CD7F32 | 🥉 |
| Silver | 1300-1499 | #C0C0C0 | 🥈 |
| Gold | 1500-1699 | #FFD700 | 🥇 |
| Platinum | 1700-1899 | #E5E4E2 | 💎 |
| Diamond | 1900-2099 | #B9F2FF | 💠 |
| Champion | 2100+ | #FF6B35 | 👑 |

## Typography
- Font: Inter (variable)
- Body: 14px / 1.5
- Page titles: 24-28px / 1.2 / font-semibold
- Hero numbers: 32-40px / 1.1 / font-bold tabular-nums
- Small/labels: 12px / 1.4 / font-medium uppercase tracking-wider

## Component Patterns
- Cards: bg-zinc-800 border border-zinc-700 rounded-xl p-6
- Badges (tier): rounded-full px-2.5 py-0.5 text-xs font-medium
- Badges (weight class): rounded-full px-3 py-1 text-sm font-semibold with class color bg at 15% opacity
- Buttons primary: bg-blue-500 hover:bg-blue-600 text-white rounded-lg px-4 py-2
- Tables: bg-zinc-900 with zinc-800 row hover, zinc-700 borders
- Charts: blue-500 line, zinc-800 grid, zinc-400 labels

## Animation Specs (Framer Motion)
- Card hover: y: -2, shadow increase, 200ms ease
- Page transition: opacity 0→1, y: 8→0, 300ms
- Stagger rows: 50ms delay per item
- Count-up: 1.5s duration, easeOut
- Countdown pulse: scale 1→1.05→1, 1s loop (last 60s only)
- Leaderboard reorder: layout animation, 500ms spring
