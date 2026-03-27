# Research Log — 2026-03-22 (4:01 AM heartbeat)

## Repo Updates
- **v0-sdk**: Already up to date (only cloned repo)
- **magicui, awesome-shadcn, framer-motion, v0-mcp-source, shadcn-ui**: Not cloned yet — consider cloning priority repos

## Key Findings

### shadcn/ui March 2026 Update (HIGH RELEVANCE)
- **CLI v4** released: now includes `--dry-run`, `--diff`, `--view` inspection flags before writing files
- **shadcn/skills**: New system bringing context to AI coding agents — relevant for our V0/agent workflow
- **Presets engine**: Design system presets for more modular theming
- Source: medium.com/@nakranirakesh (Mar 9, 2026)
- **Action**: Update design-system skill to reference CLI v4 capabilities. Inform Maks about `--diff` and `--dry-run` for safer component updates.

### shadcn Ecosystem Status
- shadcn/ui v3.5 + Radix v1 + React 19 + Tailwind CSS v4 is the current standard stack
- Kokonut UI: New animated component library aligned with shadcn conventions — worth evaluating
- Block libraries releasing ~50-100 new blocks/month

### V0 (v0.dev) Updates
- "The New v0" announced Feb 2026: GitHub repo import, Git panel (branch/PR/merge per chat), Snowflake/AWS DB connections, enterprise features
- V0 rebranded from v0.dev to v0.app (Aug 2025)
- 3M+ users, 6.5 apps generated per second
- **Action**: Update v0-mastery skill to reference new Git panel and repo import features

### Dashboard Design Trends
- Gradient-forward animated designs trending for SaaS (Flux template: Next.js 16 + 35 shadcn primitives + Framer Motion)
- Live theme customizers with 300+ color schemes becoming standard
- RTL + i18n support expected in premium templates
- Dark/light/system triple-theme support now baseline

## Relevance to Our Brands
- shadcn CLI v4 presets could streamline per-brand theming (Perlantir vs UberKiwi vs NERVE)
- Gradient-forward trend aligns with NERVE's cinematic aesthetic but NOT with Perlantir's clean authority
- V0 Git panel could improve our design→build handoff workflow

## Action Items
- [ ] Clone missing repos (shadcn-ui, magicui, framer-motion, awesome-shadcn, v0-mcp-source)
- [ ] Update v0-mastery skill with Feb 2026 "New v0" features
- [ ] Evaluate Kokonut UI for animated component needs
- [ ] Test shadcn CLI v4 --diff workflow for component updates
- [ ] Consider v0.app URL references (rebranded from v0.dev)
