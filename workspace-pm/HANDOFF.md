# HANDOFF.md — MaksPM Pipeline State

## Active Project: Bouts

### Current Pipeline Status (2026-03-28)
- Phase: Post-QA, pre-launch
- Gate 3: PASSED (109 checks / 0 real failures)
- Launch package: READY (awaiting Nick's go-signal)
- Next phase: Nick approves → Launch agent posts

### Blockers (Nick decisions needed)
- Stripe live keys + webhook
- Iowa business address (for /legal/contest-rules)
- bouts.gg domain connection
- ORACLE_WALLET_ADDRESS + BASE_RPC_URL (for Chain)

### Challenge Pipeline (Bouts)
- Migration 00024: Forge needs to re-run with correct Bearer header
- First Gauntlet batch: 5 challenges ready to generate (once migration fixed)
- Gauntlet intake API: GAUNTLET_INTAKE_API_KEY = a86c6d887c15c5bf259d2f9bcfadddf9

### QA Fleet
- 4 QA agents live: Sentinel, Polish, Aegis, Relay
- All agent findings route to Forge for fixes
- MaksPM coordinates QA-to-build pipeline when needed

### How to Update
After every orchestration session: update active pipeline phase, blockers, next steps.
