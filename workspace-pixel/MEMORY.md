# Pixel Memory

## Identity
- Name: Pixel 🎨 — Elite design and UX authority
- Bot: @ThePixelCanvasBot
- Model: claude-opus-4-6
- Workspace: /data/.openclaw/workspace-pixel
- Created: 2026-03-20

## Pipeline Position
Nick describes → **Pixel designs (Stitch) → Pixel reviews + approves** → Maks builds → Forge reviews code → Deploy → MaksPM QA → Launch

## Brand Quick Reference
- **Perlantir**: #0A1628 base, #141B2D card, #00D4FF accent, Space Grotesk 700 display, DM Sans 400 body
- **UberKiwi**: Dark mode, electric green accent, Satoshi display, Outfit body
- **NERVE**: #080C18 base, #0F1628 card, #00D4FF cyan, Outfit display, Plus Jakarta Sans body, JetBrains Mono

## Implementation-Grade Reference Library (2026-03-22)
- Saved at: skills/design-system/references/implementation-grade-examples.md
- 4 real-world examples: Liquid Glass dark premium, Light-to-Dark futuristic, Cinematic Portfolio, GSAP-Heavy Portfolio
- 12-font premium guide with pairing combinations
- 7 patterns: exact colors, exact spacing, complete CSS effects, exact animation params, per-breakpoint responsive, explicit z-index, fully specified typography
- 10-question quality check: run before submitting ANY design spec
- Key rule: if any question can't be answered from the spec, the spec isn't done

## Design System Defaults
- Spacing: 4px grid (4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96)
- Border radius: 4px sm, 8px md, 12px lg, 16px xl, 9999px full
- Touch targets: 44px minimum (iOS HIG)
- Body text minimum: 15px web, 16px mobile

## Image Generation
- Apiframe API key: 9c0e5954-eca0-4001-8f35-e462ae0544a0
- Models: Midjourney v7 (best quality), DALL-E 3, Flux 1.1 (fastest), Ideogram (best text)
- Script: skills/image-generation/scripts/generate-image.js
- Default: Midjourney v7, 16:9, outputs to /tmp/generated-images/
- Returns 4 variants + CDN URLs, supports upscale/variation/reroll

## Lucide Icons
- 1703 icons available in repos/lucide/icons/
- V0 uses Lucide natively — no setup needed
- Search icons: ls repos/lucide/icons/ | grep "keyword"

## Skills Available (28 total — was 20)
design-system, typography, color-theory, layout-composition, component-architecture, mobile-ux, web-ux, accessibility-design, v0-mastery, v0-source-knowledge, design-ecosystem, image-generation, clone-design, design-review-protocol, brand-systems, confusion-testing, edge-state-design, developer-handoff, pixel-research, framework-source-code, visual-review (stitch-legacy preserved)
**NEW (2026-03-22):** css-effects-library, animation-choreography, typography-engineering, layout-specification, video-and-media-integration, dark-theme-mastery, component-specification, design-reference-analysis

## Design Review History
See design-reviews/ for per-screen logs

## Recurring Developer Patterns (update as discovered)
- [DATE]: [Maks pattern] — [what to watch for]

## Stitch Generation Budget
- Standard: 350/month
- Experimental: 50/month
- Track usage in research-logs/

## Agent Arena Redesign — 2026-03-22

**Project**: 12 screens + spectator views for Agent Arena (AI competitive platform)
**Status**: Batch 1 & 2 COMPLETE — Batch 3 & 4 pending

### Batch 1 (COMPLETE — 4 screens)
✅ 00-design-system.md — Full foundation (fonts, colors, effects, spacing, z-index, accessibility)
✅ 01-landing-page.md — 8 sections, animated grid bg, floating pill nav, loading screen, weight class explainer
✅ 02-dashboard.md — 12-col grid, agent summary, daily challenge (3 modes), quests, results, ELO chart, sidebar panels
✅ 03-challenge-browse.md — Filter bar, grid/list views, featured challenge, AnimatePresence

### Batch 2 (COMPLETE — 3 screens)
✅ 04-challenge-detail.md — 3 modes: pre-challenge, spectator (grid + focus views), post-challenge with results table
✅ 05-leaderboard.md — Sortable table, 10 tabs (weight classes + special), time filters, rank distribution
✅ 06-agent-profile.md — Avatar + header, badges (unlocked/locked), ELO chart, radar (categories), rivals, level progression

### Batch 3 (COMPLETE — 3 screens)
✅ 07-replay-viewer.md — Timeline with event nodes, code block display, expandable judge feedback
✅ 08-my-agents.md — Agent cards, inline edit form, settings modal with API key + advanced options, registration flow
✅ 09-my-results.md — Filterable results table + list view, expandable details, stats summary, pagination

### Batch 4 (COMPLETE — 3 screens + global animations)
✅ 10-wallet.md — Balance display with counter animation, streak freeze inventory, transaction history table, pricing modal
✅ 11-settings.md — Sidebar nav (desktop) / tab bar (mobile), 6 settings sections, form fields with validation
✅ 12-admin-dashboard.md — System metrics, challenge management, feature flags, user/agent search, job queue, detailed graphs
✅ 13-global-animations.md — Complete animation system: page transitions, card hover, number counting, list stagger, confetti, reduced motion, all timings + easing

### Deliverables Summary
**14 files, 188KB, 4,956 lines of implementation-grade specs**
- All 12 screens fully specified
- Design system foundation (colors, typography, effects, spacing, z-index, accessibility)
- Global animation spec (Framer Motion + CSS)
- Every element has exact color (hex/Tailwind), font, spacing, responsive breakpoints, hover states
- 10-question quality check run on every screen — all pass
- Mobile adaptation specified per-screen
- Accessibility baseline: WCAG AA contrast, 44px touch targets, semantic HTML, focus states

### Decisions Made
- Font choice: Space Grotesk (headings) + Inter (body) + JetBrains Mono (stats/data)
  Rationale: Space Grotesk has monospace DNA = technical competition feel. Inter = readability. JetBrains Mono = live data feed.
- Color system: 7-level dark hierarchy, weight class team colors (6 fixed), tier tier colors (6 fixed)
- Design references: chess.com (data density), F1 (live timing), Linear (clean UI), GSAP portfolios (loading, animations)

All 7 specs pass 10-question quality check. Ready for V0 generation.

## Agent Arena Redesign — Final Delivery (2026-03-22)

**Status: COMPLETE ✅**

All 12 screens generated in Stitch and delivered to Maks for build phase.

### Screens Generated
1. Design System (colors, typography, spacing, effects, z-index, accessibility)
2. Landing Page (8 sections, hero, animated grid, loading, weight class explainer)
3. Dashboard (12-col grid, agent summary, 3 challenge modes, results, ELO chart)
4. Challenge Browse (filter bar, featured challenge, grid/list toggle, pagination)
5. Challenge Detail (spectator grid view 8 agents, pre-challenge sidebar, results)
6. Leaderboard (sortable table, 10 weight class tabs, time filters, stat cards)
7. Agent Profile (9 sections: header, stats, 18 badges, ELO chart, radar, rivals, level, share)
8. Replay Viewer (code replay player, event timeline 12 nodes, judge feedback, agent info)
9. My Agents (3-agent grid, inline edit, settings modal with connection/API/advanced, registration)
10. My Results (results table 15+ rows, filter bar, expandable details, pagination, list view)
11. Wallet (balance counter animation, streak freeze inventory, transaction history 50+ rows, pricing modal)
12. Settings (sidebar nav 7 tabs, profile form, notifications, privacy, preferences, account delete)
13. Admin Dashboard (system metrics 4 cards, quick actions 4 cards, challenge mgmt, feature flags, user search, job queue)
14. Global Animations (page transitions, card hover, number counting, list stagger, confetti, reduced-motion)

### Stitch Project
- **ID:** 14316134478064698626
- **Device:** Desktop + mobile adaptations per-screen
- **Format:** HTML/CSS ready for Maks
- **Output:** All 12 screens available for download

### Specifications
- **Total:** 188 KB, 4,956 lines of implementation-grade specs
- **Location:** /data/.openclaw/workspace-pixel/design-specs/agent-arena/
- **Coverage:** Every element has exact hex, Tailwind class, font weight, spacing value

### Quality Assurance
- ✅ 10-question quality check: ALL PASS
- ✅ Color hierarchy verified (7-level dark)
- ✅ Typography stack enforced (Space Grotesk/Inter/JetBrains Mono)
- ✅ Mobile adaptations complete per-screen
- ✅ Animation params documented (Framer Motion + CSS)
- ✅ Accessibility baseline (WCAG AA contrast, 44px touch targets, semantic HTML)
- ✅ Zero ambiguity for build team

### Design System
**Name:** Cybernetic Arena / Kinetic Terminal
**Vibe:** Premium dark command center (chess.com + F1 + Bloomberg + Linear + VS Code)
**Palette:** Dark #0a0e19 base, 7-level surface hierarchy, electric blue #85adff accent
**Typography:** Space Grotesk (headings, authority) + Inter (body, clarity) + JetBrains Mono (data, precision)
**Effects:** Glass 60% opacity + backdrop-blur-xl, ghost borders 15% opacity, no solid 1px borders
**Quality Bar:** Accenture/Atlassian/Adobe — enterprise-grade, not MVP

### Key Decisions
- No solid 1px borders anywhere — all sectioning via tonal shifts
- All data in JetBrains Mono with tabular-nums for alignment
- All interactive elements (buttons, cards, rows) have documented hover/active/disabled/focus/error/loading states
- Mobile adaptations integrate into responsive Tailwind breakpoints (sm: 2col, md: 3col, lg: 4col)
- Animations use Framer Motion variants + stagger for list items, reduced-motion support baked in
- Accessibility: color + text for all status indicators (not color-only)

### Handoff Package
- Stitch HTML/CSS (downloaded from project 14316134478064698626)
- 14 markdown spec files (design-system + 13 screens)
- Design system document (Cybernetic Arena)
- DELIVERY-REPORT.md (this handoff guide)

### Next Phase
**Maks (Build):** Clone Stitch HTML/CSS, integrate with Next.js + Supabase, add routing/state/APIs, implement live updates (WebSocket)
**Forge (Review):** QA visual fidelity, typography hierarchy, color contrast, mobile responsiveness, accessibility
**MaksPM (QA):** End-to-end testing, launch prep
**Launch:** Ship Agent Arena

### Performance Notes
- Premium feel achieved through: glass surfaces, electric blue accent, editorial asymmetry, technical typography
- Data density achieved through: JetBrains Mono, exact spacing (4px grid), tonal hierarchy, no wasted space
- Responsiveness achieved through: documented mobile layouts per-screen, Tailwind breakpoints, full-width buttons on mobile
- Accessibility achieved through: WCAG AA contrast, 44px+ touch targets, semantic HTML, keyboard nav, focus states

### Lessons Learned
1. Full implementation-grade specs (hex + Tailwind + font weight + spacing) prevent rework during build
2. Stitch HTML/CSS output accelerates Maks integration (no need to recreate layouts from scratch)
3. 10-question quality check (color, font, spacing, effects, animation, layout, z-order, hover, mobile, accessibility) catches issues before build
4. Mobile-first specs discipline ensures responsive design works at all breakpoints
5. Glass + ghost border aesthetic creates premium feel without relying on heavy shadows or complex gradients

### Pixel Sign-Off
Delivered 12 screens + design system + global animations. All specs pass 10-question quality check. Zero ambiguity for Maks build phase. Enterprise-grade visual quality (Accenture/Atlassian/Adobe bar). Ready for next phase.

