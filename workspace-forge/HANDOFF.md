# HANDOFF.md — Forge Context (read on every startup)
# Last updated: 2026-03-29 ~03:55 AM KL

---

## Phase A — Multi-Access Platform Layer (built 2026-03-29 ~03:55 AM KL)
✅ **Migration 00027** applied — api_tokens, submission_idempotency_keys, webhook_subscriptions, webhook_deliveries
✅ **src/lib/auth/token-auth.ts** — resolveAuth(), requireScope(), optionalAuth(), hasScope()
   - Handles bouts_sk_* API tokens, Supabase JWTs, aa_* connector tokens
   - Admin users implicitly have all scopes
✅ **src/lib/utils/rate-limit-policy.ts** — RATE_LIMITS const, applyRateLimit(), readCategory(), rateLimitIdentity()
✅ **src/lib/api/response-helpers.ts** — v1Success(), v1Error(), v1Paginated() with standard envelope + headers
✅ **src/lib/api/versioning.ts** — addVersionHeaders() with deprecation support
✅ **Token management API**:
   - GET/POST /api/v1/auth/tokens — list/create tokens (JWT auth only, max 20, SHA-256 hashed)
   - DELETE /api/v1/auth/tokens/:id — revoke token
✅ **v1 route layer** (all thin wrappers over existing service logic):
   - GET /api/v1/challenges (paginated, rate-tiered)
   - GET /api/v1/challenges/:id
   - POST /api/v1/challenges/:id/sessions (IDEMPOTENT)
   - GET /api/v1/sessions/:id
   - POST /api/v1/sessions/:id/submissions (IDEMPOTENT via Idempotency-Key header)
   - GET /api/v1/submissions/:id
   - GET /api/v1/submissions/:id/breakdown (audience-gated)
   - GET /api/v1/results/:id
   - GET /api/v1/leaderboards/:challengeId (cursor-based pagination)
   - GET/POST /api/v1/webhooks
   - DELETE/POST /api/v1/webhooks/:id (deactivate / test)
✅ **OpenAPI 3.1 spec** at /api/v1/openapi (GET /api/v1/openapi)
✅ **Deploy**: https://agent-arena-roan.vercel.app (git: eeafdf5)
✅ TypeScript clean (0 errors)

### Phase B TODO (next)
- Webhook delivery engine (retry, backoff, HMAC signing)
- /api/v1/agents endpoint (agent:write scope)
- MCP tool layer (Phase C, mcp:tool rate limit already wired)

---

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

## Phase 1 Competition Runtime (built 2026-03-29 ~01:50 AM KL)
✅ **Migration 00026** — 12 new tables: judging_jobs, challenge_sessions, submission_artifacts, submission_events, judge_runs, judge_lane_scores, judge_lane_artifacts, judge_execution_logs, match_results, match_result_overrides, match_lane_scores, match_breakdowns, audit_trigger_rules
✅ **DB functions**: claim_judging_job() (FOR UPDATE SKIP LOCKED), enqueue_judging_job() (idempotent)
✅ **4 default audit trigger rules** seeded
✅ **src/lib/submissions/**: validate-submission, artifact-store (SHA-256 hashing), event-logger (append-only, never throws), version-snapshot (frozen config state)
✅ **src/lib/judging/**: evidence-packager (strict lane isolation), lane-runner (30s timeout, 2 attempts, fallback model), idempotency, aggregator (weighted scoring, exploit detection, confidence), audit-checker (configurable rules engine), orchestrator (13-stage, idempotent, traceable)
✅ **src/lib/breakdowns/**: generator (3-audience breakdowns), leakage-auditor, template-engine (5 outcome types × 6 families)
✅ **src/lib/challenges/**: activation (7-gate validation + atomic activate), discovery (enterable check)
✅ **API routes**: POST /api/challenges/[id]/sessions, GET /api/challenge-sessions/[id], GET /api/challenge-submissions/[id], GET /api/submissions/[id]/breakdown (audience-aware), POST /api/internal/judge-submission (service key auth), GET /api/cron/process-judging-jobs, POST /api/admin/challenges/[id]/activate, POST /api/admin/challenges/[id]/unpublish, GET /api/admin/judging-queue
✅ **Updated /api/connector/submit** — now validates, hashes, stores artifact, enqueues judging job, logs events
✅ **Cron registered**: bouts-judging-processor, every 2min, ID: 4e028b13-dad0-4b36-a7f7-32dd5fdfd950
✅ **Deploy**: https://agent-arena-roan.vercel.app (git: 45380fc)
✅ TypeScript clean (0 errors)

### Judging Flow (end-to-end)
```
Agent submits → POST /api/connector/submit
  → validateSubmission() checks: active, size, session, no dupe
  → storeArtifact() SHA-256 hashes content → submission_artifacts
  → logSubmissionEvent('received')
  → captureVersionSnapshot() freezes config state
  → enqueue_judging_job() RPC → judging_jobs table
  → logSubmissionEvent('queued')
  → submission_status = 'queued'

Cron (every 2min) → GET /api/cron/process-judging-jobs
  → claim_judging_job() FOR UPDATE SKIP LOCKED (concurrency-safe)
  → POST /api/internal/judge-submission (fire-and-forget)

Orchestrator (13 stages):
  1. submission_received → job status=running
  2. submission_prevalidation → re-check challenge active
  3. objective_evaluation → objective-judge edge fn → judge_lane_scores
  4. evidence_package_assembly → 3 parallel packages (no cross-lane leakage)
  5+6+7. lane_judging → Promise.all(process, strategy, integrity) → lane scores
  8. audit_trigger_check → evaluates configurable rules
  9. audit_lane_judging → conditional (only if triggered)
  10. aggregation → weighted score, exploit detection, confidence
  11. result_persistence → match_results + match_lane_scores (immutable)
  12. breakdown_generation → 3 audience breakdowns + leakage audit
  13. finalization → job=completed, submission=completed, judge_run=finalized
```

## Phase 2 Competition Runtime (built 2026-03-29 ~02:30 AM KL)
✅ **Gap Fix 1A**: judge_weights now read from `challenges.judge_weights` or `judging_config.judge_weights`, default 50/20/20/10
✅ **Gap Fix 1B**: has_prize / prize_pool_cents now looked up from `prizes` table before audit trigger check
✅ **Gap Fix 1C**: `normalizeEdgeFunctionResponse()` added to lane-runner.ts — normalizes score/rationale/confidence/flags from any edge fn shape
✅ **Fix /api/challenges/daily**: replaced `difficulty`, `scheduled_start`, `duration_minutes` with `difficulty_profile`, `starts_at`, `ends_at`, `time_limit_minutes`, `prize_pool`
✅ **Fix connector docs badge**: v0.1.1 badge added to Connector Docs title header
✅ **New endpoint GET /api/admin/intake-queue**: returns pending/failed challenge_bundles with challenge join
✅ **New endpoint GET /api/admin/health-dashboard**: returns challenge health with health_signal (healthy/warning/critical) + summary counts
✅ **New endpoint POST /api/admin/challenges/[id]/quarantine**: validates pipeline_status, sets quarantined+upcoming, logs to challenge_admin_actions
✅ **New endpoint POST /api/admin/challenges/[id]/retire**: validates pipeline_status, sets retired+complete, logs to challenge_admin_actions
✅ **New endpoint POST /api/admin/agents/cleanup**: dry_run support, name_pattern/older_than_days/agent_ids/force filters, entry count guard
✅ **Admin UI**: 5 new tabs (Intake Queue, Forge Review, Calibration, Inventory, Challenge Health) + judging queue status bar
✅ **Deploy**: https://agent-arena-roan.vercel.app (git: 6319f59)
✅ TypeScript clean (0 errors)

## Current Tasks (as of 2026-03-29 01:50 AM KL)

### ✅ Phase 1 Runtime Deployed (2026-03-29 ~02:00 AM KL)
**26 files. Migration 00026 applied. TypeScript clean. Deployed. Cron registered.**

Files built:
- `src/lib/submissions/` — validate-submission, artifact-store (SHA-256 immutable), event-logger, version-snapshot
- `src/lib/judging/` — orchestrator (13 stages), evidence-packager (strict lane isolation), lane-runner (30s timeout/2 retries/fallback), idempotency, aggregator, audit-checker (configurable rules)
- `src/lib/breakdowns/` — generator (3 audience views), leakage-auditor, template-engine (5 outcomes × 6 families)
- `src/lib/challenges/` — activation (7-gate), discovery
- 9 new API routes + updated /api/connector/submit
- OpenClaw cron `4e028b13-dad0-4b36-a7f7-32dd5fdfd950` (every 2min) for judging job processor

Known gaps to wire in Phase 2:
- `judge_weights` in orchestrator currently hardcoded 25/25/25/25 — needs wiring from challenges.judging_config once populated
- `has_prize` in audit-checker hardcoded false — needs lookup from prizes table
- Edge functions need response schema update to return `{ raw_score, rationale_summary, confidence, flags }`

### ✅ Phase 2 Complete (2026-03-29 ~02:15 AM KL)
All gap fixes + admin UI + lifecycle endpoints. Git: 6319f59. Deployed.

### ✅ Phase A Multi-Access Layer (2026-03-29 ~03:50 AM KL)
- Migration 00027: api_tokens, submission_idempotency_keys, webhook_subscriptions, webhook_deliveries
- /api/v1/ versioned route layer (16 endpoints) — live at https://agent-arena-roan.vercel.app/api/v1
- OpenAPI 3.1 spec at /api/v1/openapi
- Scoped API tokens (bouts_sk_* format, SHA-256 hash only, shown once)
- Idempotency: session creation (returns existing), submissions (Idempotency-Key header, 24h)
- Named rate limit policy (6 categories defined)
- Webhook subscription management + delivery log
- Versioning headers + deprecation policy (90-day minimum)
- Git: eeafdf5

### ✅ Phase 3 Complete (2026-03-29 ~02:25 AM KL)
- ✅ Ballot cron registered — ID: 4a50d140-918c-4a75-bb52-ca565c439eb8, runs every 6 hours UTC, session: ballot-ingestion
- ✅ /api/challenges/daily 500 — FIXED (shipped in Phase 2, confirmed returning {challenge: null, your_entry: null} cleanly)
- ✅ Connector docs v0.1.1 badge — FIXED (confirmed in source)
- ✅ Agent cleanup endpoint — BUILT (POST /api/admin/agents/cleanup, dry-run + commit, audit logged)

### Next Steps — Challenge Pipeline
- [ ] Task Gauntlet to generate first batch: 5 bundles (2 Blacksite Debug, 2 False Summit, 1 Fog of War — Lightweight/Middleweight, Sprint/Standard only, no Abyss/Frontier/Marathon)
- [ ] Gauntlet submits via POST /api/challenges/intake (Bearer: 1b12f7484f1d283543c98ae1ecbd1c358d68f68b5e896dac2b9bca92e91c1f8e)
- [ ] Forge reviews each bundle via /api/admin/forge-review
- [ ] Calibration runs automatically after Forge approval
- [ ] Nick makes inventory decisions via /api/admin/inventory

### Nick's Side (still pending)
- [ ] Stripe live keys + webhook
- [ ] Iowa business address for /legal/contest-rules
- [ ] bouts.gg domain → Cloudflare → Vercel

### Chain's Side — ✅ ALL DONE
All on-chain env vars confirmed set as Supabase secrets (Mar 27). Used exclusively by edge functions — nothing needs to go in Vercel.
- ✅ ORACLE_WALLET_ADDRESS, BASE_RPC_URL, BOUTS_ESCROW_ADDRESS, BOUTS_AGGREGATOR_ADDRESS
- ✅ BOUTS_SBT_ADDRESS, JUDGE_CONTRACT_ADDRESS, JUDGE_ORACLE_PRIVATE_KEY, CHAIN_ENV

### Known Open Issues (non-blocking)
- `/api/challenges/daily` returns 500 — Phase 3 fix
- Test agents in DB: `final-auth-test`, `Testagentarwna` — Phase 3 cleanup endpoint

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
| Competition runtime libs | src/lib/submissions/, src/lib/judging/, src/lib/breakdowns/, src/lib/challenges/ |
| Judging orchestrator | src/lib/judging/orchestrator.ts |
| Submit (updated) | src/app/api/connector/submit/route.ts |
| Judging cron | src/app/api/cron/process-judging-jobs/route.ts |
| Internal judge trigger | src/app/api/internal/judge-submission/route.ts |
| Admin judging queue | src/app/api/admin/judging-queue/route.ts |
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
