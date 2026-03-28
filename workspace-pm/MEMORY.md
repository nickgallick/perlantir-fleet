# MaksPM Memory

## Long-Term Facts
- Nick is founder of Perlantir AI Studio, builds SaaS in fintech/AI/golf verticals
- Uses 5 specialized agents: Maks (build), MaksPM (you), Scout (research), ClawExpert (ops), Launch (go-to-market)
- Quality bar: Enterprise-grade design, first deploy polished (not MVP)
- Timezone: Central US (GMT-6)

## Active Projects
See projects.md for current tracker

## Key Decisions
- Build pipeline order: Strategy → Design Director → Stitch → Schema → Build → Deploy → 3-step QA → Launch
- QA is gate: below C-grade = don't launch until fixed
- Launch only activates after all 3 QA steps pass
- Tech debt and security are blocking — ClawExpert monitors

## Lessons Learned
- **2026-03-22**: Agent Arena process failure — project moved through Forge architecture + Pixel design phases without MaksPM orchestrating or tracking in active-projects/. COO (ClawExpert) caught it and issued direct order. Fix: EVERY project gets an active-projects/ file from intake. NO phase transitions happen without MaksPM tracking them. This is non-negotiable.

## Skills Available to You
- nick-project-orchestrator — knows the full pipeline
- nick-bug-triage — severity classification
- nick-tech-debt — debt tracking
- nick-git-ops — repo management
- nick-launch-operator — launch coordination
- nick-analytics-setup — metrics setup

## Fleet Update (2026-03-29)
- Fleet expanded to 14 agents (added QA fleet: Sentinel, Polish, Aegis, Relay)
- QA agents now part of pipeline: Sentinel/Polish/Aegis/Relay → Forge fixes → Launch
- Bouts Gate 3 PASSED (2026-03-28): 109 checks, 0 real failures
- Bouts launch package ready, awaiting Nick's go-signal

## Active Project
- Bouts: live at https://agent-arena-roan.vercel.app
- Pipeline: challenge intake (Gauntlet → Forge review → operator decision → active)
- Pending: Migration 00024 (challenge_bundles table), Stripe keys, bouts.gg domain
