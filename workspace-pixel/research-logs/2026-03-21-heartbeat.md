# Research Log — 2026-03-21 Heartbeat Cycle

## Repo Updates
- All 14 repos checked. v0-sdk: no changes. Others lack proper .git remotes (shallow clones).
- **Action:** Consider re-cloning repos with full git history for proper update tracking.

## SaaS UI Design Trends 2026 (source: saasui.design)
Key patterns shipping in production right now:

### 1. Calm Design — Reducing Cognitive Overload
- Default views show only what's needed for current workflow
- Advanced settings behind progressive disclosure
- Generous whitespace as functional tool, not decoration
- Typography does heavy lifting — no icons competing for attention
- "Feels like Linear" is the highest compliment in 2026
- **Relevance:** Aligns perfectly with our "Clarity Over Cleverness" principle. Reinforces our approach. Continue.

### 2. AI as Infrastructure, Not a Feature
- AI badges disappearing — intelligence is invisible infrastructure
- Inline suggestions appear contextually, not in separate panels
- Auto-classification happens on save, not on demand
- Natural language commands replacing complex filter UIs
- **Relevance:** For Perlantir especially — AI features should feel like autocomplete, not a chatbot.

### 3. Command Palettes & Unified Search (Cmd+K)
- Now standard in any SaaS with 10+ features
- Actions AND navigation in one palette
- Recent items surfaced by default, fuzzy search, keyboard navigable
- **Relevance:** Should be standard in all Perlantir dashboards. Add to design-system skill as required pattern.

## shadcn/ui March 2026 Update
**Major release: CLI v4 + shadcn/skills + Presets engine**

### CLI v4: Safe & Inspectable Changes
- `--dry-run`: simulation of what will be added
- `--diff`: compare registry updates with local changes
- `--view`: inspect registry payload before adding
- No longer just an installer — manages project state

### shadcn/skills: AI Agent Context
- New system for bringing design context to coding agents
- Directly relevant to our workflow — investigate how this integrates with V0 and our agent pipeline

### Presets Engine
- Design system presets — modular, portable
- Could standardize our brand configurations (Perlantir, UberKiwi, NERVE)

**Action items:**
1. Update shadcn-ui repo to get CLI v4
2. Investigate shadcn/skills — may replace or complement our design-system skill
3. Test Presets engine for brand-specific configurations
4. Add Cmd+K pattern to design-system skill as standard dashboard pattern

## V0 Pipeline Learnings (from today's Brew & Bean + PaySync work)
- **NEVER use Framer Motion whileInView/initial={{opacity:0}} in V0 prompts** — causes invisible sections in demo deployments
- V0 sendChatMessage can timeout on very long messages — keep fix messages SHORT
- Demo URLs update with each iteration (new URL per V0 message)
- Image-first approach works well for photography-forward designs
- Light mode Stripe-style designs: V0 sometimes injects green/teal where #635BFF should be — always specify "NO green except status badges" explicitly
- Midjourney CDN images (cdn.apiframe.pro) work reliably as img src in V0 components
