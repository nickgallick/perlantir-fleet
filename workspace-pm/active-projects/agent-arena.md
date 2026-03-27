# Bouts (formerly Agent Arena) — Active Project Tracker
**Rebrand**: Agent Arena → **Bouts** (bouts.ai) — Nick's decision 2026-03-24

## Status
**Phase**: LAUNCH — All gates passed, execution copy ready, awaiting Nick's go
**Owner**: MaksPM (orchestrating) → Launch (executing)
**Last Updated**: 2026-03-24 05:12 GMT+8

## Pipeline
```
Nick → ~~Scout~~ → Forge ✅ → Gate 1 ✅ → Pixel ✅ → Gate 2 ✅ → Maks ✅ → Forge ❌ → Fix ✅ → Forge ✅ → Gate 3 ✅ → QA ⚠️ → Launch ✅ → Forge Backend ✅ → **Deployed**
```

## Completed Phases

### Forge — Architecture ✅
- **Deliverable**: architecture-spec-agent-arena.md (70KB)
- **Location**: /data/.openclaw/workspace-forge/architecture-spec-agent-arena.md
- **COO Gate 1**: PASSED

### Pixel — Design ✅
- **Deliverable**: 12 Stitch-generated screens + 14 implementation-grade specs (188KB)
- **Location**: /data/.openclaw/workspace-pixel/design-specs/agent-arena/
- **COO Gate 2**: PASSED

## Current Status
- ✅ COO cross-check PASSED (2026-03-22 12:46 GMT+8)
- ✅ Build order sent to Maks (2026-03-22 12:47 GMT+8)
- ✅ Maks build COMPLETE (2026-03-22 13:11 GMT+8) — 24 min build time
- ✅ Deployed: https://agent-arena-roan.vercel.app (HTTP 200)
- ✅ Forge code review complete (2026-03-22 13:20 GMT+8) — VERDICT: ❌ BLOCKED (13 P0s)
- ✅ Fix order sent to Maks (2026-03-22 13:21 GMT+8) — Fix iteration 1/3
- ✅ Maks P0 fixes complete (2026-03-22 13:33 GMT+8) — all 13 P0s + 7 P1s fixed, redeployed
- ✅ Forge re-review PASSED WITH NOTES (2026-03-22 13:37 GMT+8) — all 13 P0s verified fixed
- ✅ COO Gate 3 PASSED (2026-03-22 13:40 GMT+8)
- ❌ QA Round 1: NEEDS WORK (2026-03-22 13:45 GMT+8) — 4 critical, 9 major
- ✅ Maks QA fixes complete + redeployed (~14:00 GMT+8)
- ⚠️ QA Round 2: PASS WITH NOTES (2026-03-22 15:55 GMT+8) — 0 critical, 2 major (cosmetic), 20 passed
- ✅ All 4 critical auth issues VERIFIED FIXED
- ✅ All 8 404 pages VERIFIED FIXED
- ✅ Launch package delivered (2026-03-22 16:01 GMT+8)
- 📋 Deliverable: `/data/.openclaw/workspace-launch/launch-packages/agent-arena-launch.md`
- 🔜 Final report to Nick
- ✅ Backend completion DONE (2026-03-22 18:44 GMT+8) — Forge via Claude Code
  - 15 API routes built (all responding on prod)
  - 7 core libraries (elo, mps, judge, badges, quests, api-key, stripe)
  - 11 hooks (SWR pattern)
  - 1 migration (00006_spec_completion.sql — economy, social, admin tables, 30+ indexes, RLS)
  - 1 spectate page
  - Zero TypeScript errors, 48 routes registered
  - Deployed to Vercel (HTTP 200)

## Next Steps (MaksPM owns all)
1. **Receive COO clearance** from cross-check
2. **Send build order to Maks** with both deliverables (architecture spec + design specs)
3. **Track Maks build progress** — monitor for stalls, nudge if needed
4. **Route to Forge** for code review when build completes
5. **COO Gate 3** — pass/fail on Forge review
6. **Run QA phase** — vercel-qa + visual-design-review + deep-uat
7. **Activate Launch** for GTM once QA passes

## Build Order Template (ready to send on clearance)
- Architecture spec: /data/.openclaw/workspace-forge/architecture-spec-agent-arena.md
- Design specs: /data/.openclaw/workspace-pixel/design-specs/agent-arena/
- Stack: Next.js App Router, Tailwind, Supabase, Vercel
- Quality bar: Enterprise-grade, first deploy polished

## Timeline
- Build started: 2026-03-22 12:47 GMT+8
- Expected build duration: 30-60 min (complex, 12 screens + DB + auth)
- Deploy target: 2026-03-22 ~13:30-14:00 GMT+8

## Supabase Project
- **Active/correct project**: `gojpbtlajzigvyfkghrg.supabase.co` ✅ (verified 2026-03-26 — service role key returns 200, live app API confirmed)
- `sbirszjpnmduxnhxfnll.supabase.co` — returns 401, NOT active
- Forge handling config with new credentials

## Notes
- This project moved through early pipeline phases without MaksPM orchestration — process failure noted and corrected as of 2026-03-22.
