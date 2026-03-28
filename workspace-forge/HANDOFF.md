# HANDOFF.md — Forge Context (read on every startup)
# Last updated: 2026-03-29 ~00:32 AM KL

## Active Project: Bouts / Agent Arena

### Key Facts
- **Live URL**: https://agent-arena-roan.vercel.app
- **Codebase**: `/data/agent-arena` (already cloned on this VPS)
- **GitHub repo**: https://github.com/nickgallick/Agent-arena
- **GitHub token**: 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
- **Stack**: Next.js App Router, TypeScript strict, Tailwind, Supabase, Vercel
- **Deploy command**: `cd /data/agent-arena && vercel deploy --prod --yes --token $(cat ~/.vercel/auth.json | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")`
- **Vercel org/project**: team_h7szk9Nd73ydfud2R8vnQwSx / prj_Nlf54QOI9zrMmLGJ7ZtJjL9hslzt

### Supabase
- **URL**: https://gojpbtlajzigvyfkghrg.supabase.co
- **Credentials**: in `/data/agent-arena/.env.local`
- **Personal Access Token**: sbp_851afa9dfe477af8cb5c9a6e2c22ecdab2d5960b

### QA
- **QA user**: qa-bouts-001@mailinator.com (admin role, coins: 1450)
- **QA login**: `/qa-login` — MUST NOT be enabled in prod

---

## Current Tasks (as of 2026-03-29 00:32 AM KL)

### Next Steps — Challenge Pipeline
- [ ] Task Gauntlet to generate first batch: 5 bundles (2 Blacksite Debug, 2 False Summit, 1 Fog of War — Lightweight/Middleweight, Sprint/Standard only, no Abyss/Frontier/Marathon)
- [ ] Gauntlet submits via POST /api/challenges/intake (Bearer: 1b12f7484f1d283543c98ae1ecbd1c358d68f68b5e896dac2b9bca92e91c1f8e)
- [ ] Forge reviews each bundle via /api/admin/forge-review
- [ ] Calibration runs automatically after Forge approval
- [ ] Nick makes inventory decisions via /api/admin/inventory (publish_now / hold_reserve / etc.)

### Nick's Side (still pending)
- [ ] Stripe live keys + webhook
- [ ] Iowa business address for /legal/contest-rules
- [ ] bouts.gg domain → Cloudflare → Vercel
- [ ] ORACLE_WALLET_ADDRESS + BASE_RPC_URL (from Chain)

### Known Open Issues (non-blocking)
- `/api/challenges/daily` returns 500 — DB schema issue, handled gracefully
- Landing stats hardcoded in `src/app/page.tsx` lines 50-59
- Test agents in DB: `final-auth-test`, `Testagentarwna`

---

## Full System Status (as of 2026-03-29 00:32 AM KL)

### Platform
✅ 4-lane judging system (Objective 50% / Process 20% / Strategy 20% / Integrity 10%)
✅ Challenge quality automation (CDI, auto-flag, quarantine, enforcement cron every 15min)
✅ Activation gate + freeze snapshot
✅ Hybrid calibration system v3 (synthetic + real LLM, escalation, divergence risk, flagship gates)
✅ Mutation engine (semantic/structural/adversarial)
✅ Live prize pool (platform_fee_percent, recompute_prize_pool() trigger)
✅ All public pages content-aligned (philosophy, fair-play, how-it-works, contest rules, docs)
✅ SITE_CANON.md locked
✅ No fake data anywhere
✅ Full E2E test: 85/85 passing

### Challenge Pipeline (built 2026-03-28 evening)
✅ **Migration 00024** — pipeline_status (14 states), challenge_bundles, challenge_forge_reviews, challenge_inventory_decisions tables
✅ **POST /api/challenges/intake** — Gauntlet bundle ingestion, Bearer auth, 9-point auto-validation
✅ **GET/POST /api/admin/forge-review** — Forge review queue + structured verdict submission
✅ **GET/POST /api/admin/inventory** — Operator inventory decisions
✅ **src/lib/intake/bundle-schema.ts** — Zod schema (families: blacksite_debug|fog_of_war|false_summit|recovery_spiral|toolchain_betrayal|abyss_protocol)
✅ **src/lib/intake/bundle-validator.ts** — 9-point semantic validation
✅ **src/lib/intake/inventory-advisor.ts** — pool size / family cap advisory
✅ **GAUNTLET_INTAKE_API_KEY** set in Vercel: `1b12f7484f1d283543c98ae1ecbd1c358d68f68b5e896dac2b9bca92e91c1f8e`
✅ **Auth confirmed working** — test POST returned 422 with correct field-level errors (auth passed, validation caught empty payload)

### Ballot Learning System (built 2026-03-28 late evening)
✅ **Migration 00025** — calibration_learning_artifacts, ballot_lesson_entries, generate_learning_artifact() SQL function
✅ **Calibration orchestrator** — fire-and-forgets generate_learning_artifact RPC + POST /api/admin/ballot/run after every verdict
✅ **GET/POST /api/admin/ballot** — ingestion stats, per-family lessons, manual run trigger
✅ **workspace-ballot created** — SOUL.md, MEMORY.md, BOOTSTRAP.md, AGENTS.md, scripts/ingest-artifacts.ts
✅ **Gauntlet lesson scaffold** — private/gauntlet-lessons/ (positive, negative, mutation, family-health, calibration-system, 6 family files, index.json)
✅ **BUNDLE-FORMAT.md** — complete Gauntlet reference with example bundle, first-batch spec, Ballot integration section

### Ballot Agent Summary
- Background-only, Sonnet model, no Telegram bot
- Triggered automatically after every calibration verdict
- Synthesizes → categorizes → deduplicates lessons (confidence: 1=low, 3+=medium, 5+=high)
- Writes to workspace-gauntlet/private/gauntlet-lessons/ (auditable, compounding)
- Direct Gauntlet messaging ONLY for: contamination alert, family collapse, do-not-publish emergency, branch exhaustion

---

## Complete Pipeline Flow

```
Gauntlet generates bundle
  → POST /api/challenges/intake (Bearer GAUNTLET_INTAKE_API_KEY)
  → 9-point auto-validation
  → pipeline_status: draft_review (pass) | draft_failed_validation (fail)
  → Forge reviews via /api/admin/forge-review
  → approved_for_calibration | needs_revision
  → Calibration: synthetic → real LLM → CDI → verdict
  → generate_learning_artifact() fires
  → Ballot ingests → writes lesson files to Gauntlet workspace
  → Operator inventory decision via /api/admin/inventory
  → publish_now → status: active (activation gate + freeze snapshot fire)
  → Live monitoring cron (every 15min): CDI, solve rate, exploit rate, same-model clustering
```

---

## Pipeline Status Values
```
draft → draft_failed_validation
draft → draft_review → needs_revision (back to Gauntlet)
draft_review → approved_for_calibration → calibrating → passed | flagged
passed → passed_reserve | queued | active
active → quarantined | retired | archived
```

---

## Key Files & Locations
| Purpose | Path |
|---------|------|
| Bundle schema (Zod) | src/lib/intake/bundle-schema.ts |
| Bundle validator | src/lib/intake/bundle-validator.ts |
| Inventory advisor | src/lib/intake/inventory-advisor.ts |
| Intake API | src/app/api/challenges/intake/route.ts |
| Forge review API | src/app/api/admin/forge-review/route.ts |
| Inventory API | src/app/api/admin/inventory/route.ts |
| Ballot API | src/app/api/admin/ballot/route.ts |
| Ballot workspace | /data/.openclaw/workspace-ballot/ |
| Ballot ingestion script | /data/.openclaw/workspace-ballot/scripts/ingest-artifacts.ts |
| Gauntlet lesson files | /data/.openclaw/workspace-gauntlet/private/gauntlet-lessons/ |
| Gauntlet bundle format ref | /data/.openclaw/workspace-gauntlet/BUNDLE-FORMAT.md |
| Site canon | /data/.openclaw/workspace-forge/SITE_CANON.md |

---

## Foundry — Phase 0 Status
All frontend/backend architecture complete. Docs in workspace-forge:
- foundry-frontend-architecture.md — Next.js spec (canonical)
- foundry-frontend-architecture-lovable.md — Lovable SPA version
- foundry-v0-homepage.md — v0.dev prompt for homepage

Legal rulings applied (Counsel 2026-03-28):
- Binary AI review only — no numerical scores to backers
- "Claim Reward" primary CTA, marketplace secondary
- Velocity limits: 24hr hold + 10/day cap → Chain's Marketplace.sol
- All 6 gaps vs Chain v1.8 closed and committed

Phase 1 gate — remaining on Chain:
- [ ] Velocity limits in Marketplace.sol
- [ ] One-address-one-vote in voting logic
- [ ] Stake scaling formula
- [ ] Fiat on-ramp architecture (Nick + Chain decision)
- [ ] Section 15 Q3/Q5/Q6/Q7/Q8 (Nick decisions)

Nick's design plan: v0.dev → Figma → Maks builds

---

## Standing Rules (permanent)
- After EVERY deploy: update HANDOFF.md + MEMORY.md. No exceptions.
- Forge can build directly in /data/agent-arena (no need to route through Maks for Bouts work)
- All git commits author as "Maks Build / build@perlantir.com" (repo-level config)
- Apply migrations via Supabase Management API (project: gojpbtlajzigvyfkghrg, PAT in TOOLS.md)
