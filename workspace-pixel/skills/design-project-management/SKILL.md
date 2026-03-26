---
name: design-project-management
description: Manage multi-screen design projects from start to delivery. Use when designing 3+ screens for a single project. Covers batching strategy, progress tracking, naming conventions, design system consistency, and version control. Prevents the scattered, inconsistent delivery that happened on Agent Arena.
---

# Design Project Management

## When to Use
Any design request with 3+ screens. Single-screen requests don't need this overhead.

## Pre-Flight Check

Before designing anything:

1. **Architecture spec exists?** Check for Forge's `architecture-spec.md`. If missing → REFUSE the design request and tell MaksPM to get Forge's spec first. Design happens AFTER architecture. No exceptions.
2. **Design brief complete?** Must include: product name, brand (which brand system), target screens list, user flows, any reference sites/screenshots.
3. **Stitch project created?** Create one Stitch project per product. One project = one design system = one canonical name.

## Canonical Naming Rule

**ONE design system name per project. Ever.**

Pick the name during project setup. Write it down. Use it in every Stitch prompt. Never invent alternatives.

### Lesson Learned: Agent Arena Failure
Agent Arena shipped with 6 different design system names across 12 screens: "Cybernetic Vanguard", "Kinetic Command", "Quantum Observer", "Sovereign Command", "Synthetic Architect", "Precision Cockpit", "Technical Vanguard". This happened because Stitch auto-generates a `designMd` document per screen, and each generation invented a new creative name. The canonical name was "Cybernetic Vanguard" but was not enforced consistently.

**Fix:** Always include `Design system name: [CANONICAL NAME]` in every Stitch prompt. After generation, verify the output `displayName` matches. If Stitch drifts the name in the `designMd` body text, that's cosmetic — what matters is the `displayName` field and visual consistency.

## Batching Strategy

Design screens in this order:

### Batch 0: Design System Foundation
- Create the design system screen/document FIRST
- Define: colors (exact hex), typography (fonts + weights + scale), spacing scale, border radius, effects (glass, shadows, gradients), component patterns (buttons, cards, badges, inputs)
- This becomes the reference for ALL subsequent screens

### Batch 1: Hero + Core Entry Points (screens that define the visual identity)
- Landing page / marketing page
- Dashboard / authenticated home
- Primary flow entry (e.g., browse/list page)
- Why first: these set the visual tone. If they're wrong, everything downstream is wrong.

### Batch 2: Core Flows (the screens users spend 80% of time on)
- Detail pages
- Leaderboards / data-dense views
- Profile pages
- Why second: these are the product. They must feel cohesive with Batch 1.

### Batch 3: Secondary Flows
- Settings / preferences
- Wallet / billing
- Results / history
- Why third: these follow established patterns from Batches 1-2.

### Batch 4: Admin + Edge Cases
- Admin dashboards
- Modals / overlays (if not already shown inline)
- Global animation spec
- Why last: admin uses the same system but is lower-traffic. Edge cases are polish.

## Progress Tracking

Maintain a tracker in the project directory. Format:

```markdown
# [Project Name] — Design Tracker

**Stitch Project ID:** [ID]
**Design System:** [CANONICAL NAME]
**Architect:** [Forge spec path]
**Started:** [date]

| # | Screen | Status | Stitch ID | Iterations | Notes |
|---|--------|--------|-----------|------------|-------|
| 00 | Design System | ✅ DONE | abc123... | 1 | Foundation |
| 01 | Landing Page | ✅ DONE | def456... | 2 | v2: fixed nav |
| 02 | Dashboard | 🔄 IN PROGRESS | — | 0 | Generating |
| 03 | Challenge Browse | ⏳ QUEUED | — | 0 | — |
```

**Status values:** ⏳ QUEUED → 🔄 IN PROGRESS → 👀 REVIEW → ✅ DONE → 🔁 REWORK

**Update the tracker after every screen generation.** This is the single source of truth.

## Version Control for Iterations

When iterating on a screen in Stitch:
- v1: Initial generation via `generate_screen_from_text`
- v2+: Edits via `edit_screens` with specific change instructions
- Track iteration count in the progress tracker
- Keep notes on what changed: "v2: fixed nav spacing, added mobile menu"

If a screen needs a full regeneration (not just edit), note it: "v3: REGENERATED — v2 had wrong layout"

## Design System Consistency Across 10+ Screens

1. **Generate the design system screen first** (Batch 0)
2. **Include the design system name and key tokens in every prompt:**
   ```
   Design system: [CANONICAL NAME]
   Colors: bg #0A1628, surface #141B2D, accent #3B82F6
   Fonts: Space Grotesk headings, Inter body, JetBrains Mono data
   Borders: ghost only (15% opacity), no solid borders
   ```
3. **Reference previous screens:** "Same nav/header as Screen 02"
4. **After generation, spot-check:** Does the output use the right fonts? Right colors? Right border treatment? If not, use `edit_screens` to fix before moving on.
5. **Never let Stitch diverge.** If a screen looks visually different from the others, fix it immediately. Don't say "close enough" and move on.

## Progress Updates

For projects with 6+ screens, send Nick a progress update every 3 screens:
```
🎨 Pixel Progress — [N/total] screens designed.
Completed: [list]
Working on: [next]
ETA: [estimate]
```

## Delivery Checklist

Before marking a project COMPLETE:
- [ ] All screens generated in Stitch with verified screen IDs
- [ ] Progress tracker fully updated
- [ ] Design system name is consistent across all screens
- [ ] Handoff document created (see handoff-checklist skill)
- [ ] Architecture spec cross-checked (component names match Forge's hierarchy)
- [ ] Nick/ClawExpert notified of completion
