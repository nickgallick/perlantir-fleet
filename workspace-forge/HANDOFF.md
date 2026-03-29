# HANDOFF.md — Forge Context (read on every startup)
# Last updated: 2026-03-30 04:15 AM KL

---

## Web Submission System (Phase W) — IN PROGRESS (2026-03-30)

### Status
- W0 ✅ COMPLETE — Git: abdf3dc | Deployed
- W1 ✅ COMPLETE — Git: 0ccf990 | Deployed
- W1-patch ✅ DEPLOYED — Git: d9ec19f | result_ready CTA fixed, judging state removed, workspace_open confirmed clean
- W1-patch2 ✅ DEPLOYED — Git: f7a8bfc | workspace_open added to SUBMITTABLE_STATUSES in v1/submissions route
- W2 ✅ COMPLETE — Git: 48903d4 | Deployed
- W3 ✅ COMPLETE — Git: 7104052 | Deployed
- W3-patch ✅ DEPLOYED + FULLY VERIFIED (2026-03-30 04:15 AM KL) — Git: 09a9462
- W3-patch2 ✅ DEPLOYED (2026-03-30 04:35 AM KL) — Git: 1baefd4 | All Aegis blockers resolved
- W3-patch3 ✅ DEPLOYED (2026-03-30 04:55 AM KL) — Git: d432ec8 | Sentinel P1 blocker resolved
  - workspace/route.ts + web-submit/route.ts: .maybeSingle() → .order('created_at').limit(1)[0]
  - Fixes PGRST116 for multi-agent users — no more false "No agent registered" for users with >1 agent
  - web-submit also expanded agent select to include name (needed for "Submitting as" UI)
  - Migration 00037: sandbox challenges reseeded with v4 UUIDs (old all-zeros rows deleted, FKs cascaded)
  - New sandbox UUIDs: Hello Bouts=69e80bf0-597d-4ce0-8c1c-563db9c246f2, Echo Agent=5db50c6f-ac55-43d3-80a6-394420fc4781, Full Stack Test=b21fb84b-81f6-49cc-b050-bf5ec2a2fb8f
  - Real challenges flagged web_submission_supported=true: 22baff1f (Full-Stack Todo App), 41f952c5 (Debug the Payment Flow)
  - Root middleware.ts deleted (dead stale file — src/middleware.ts is the active one in Next.js src/ layout)
  - Duplicate getUser() fixed in src/middleware.ts — single hoisted call, reused for both cookie refresh + auth guard
  - All docs/lib/api refs to old all-zeros sandbox UUIDs updated (sandbox-judge, sandbox-guard, webhook test, docs pages)
- W4 = next: submission progress states polish, failed state handling, breakdown verify, timer+'Submitting as' merge (deferred Polaris) — awaiting Nick approval

### W0 Completed
- Migration 00035 applied to DB + committed to repo
- web_submission_supported column on challenges (default false)
- submission_source column on submissions ('web'|'connector'|'api'|'sdk'|'github_action'|'mcp'|'internal')
- challenge_entries.status constraint extended: added 'workspace_open', 'expired'; removed legacy 'judging' (migrated to 'in_progress')
- Sandbox challenges (all 3 fixed UUIDs) flagged web_submission_supported=true
- PATCH /api/admin/challenges/[id] accepts web_submission_supported boolean
- Challenge Health admin tab: Web Submit toggle column per row
- Supabase PAT rotated in TOOLS.md

### Nick's 7 Clarifications (locked before W0)
1. Session identity: one active session per user/challenge, idempotent on workspace open, timer starts on workspace open (deliberate fairness model)
2. Agent in web submission: user submits ON BEHALF OF their registered agent profile — agent is the identity, user is the operator. UI: "Submitting as [Agent Name]"
3. Integrity/process for web: submission_source='web' stored. Process lane scored on artifact quality not toolchain. Integrity lane notes manual path. No scoring disadvantage — different evidence profile, same standard.
4. UX framing: "Manual Browser Submission" label explicit in workspace header
5. Constraints surfaced: inline constraint panel in workspace (text-only, 100KB, one submission, no draft save, no auto-resume, session timing)
6. State model locked: Entered → Open Workspace → Submission Required → Submitted → Judging → Result Ready → Expired/Failed
7. W0 proceeding

### Phase W Build Plan (approved)
- W0: Migration 00035 (web_submission_supported, session_id FK), admin toggle, sandbox flag
- W1: Participation state model, entry flow clarity
- W2: Workspace page (/challenges/[id]/workspace)
- W3: POST /api/challenges/[id]/web-submit + runtime wiring
- W4: Status + result UX
- W5: Docs/messaging alignment

---

## Copy Cleanup + Docs Pass (2026-03-29 evening) — COMPLETE

### Sitewide Copy Cleanup — CLOSED
Commits: 049eeb8 → 6367f8b → 439296f → 8a7dc34 → 8b0be6a
Root cause: duplicate header components. public-header.tsx is the live public nav (Track A missed it).
Bucket C (migration sprint only): [ARENA:*] wire protocol, CSS arena-* classes, /components/arena/ directory, x-arena-api-key, arena-connect/arena-connector package names, ARENA_API_KEY

### Tier 1 Docs Pass — COMPLETE (86d9999)
- /docs: 6-card "Where do you want to start?" path chooser
- /docs/quickstart: Track 0 (web) + tracks 1-3 + "Not sure which path?" note
- /docs/connector H1: "Connector CLI — Setup Guide"  
- All 6 underdocumented paths have "Who this is for" intros: API, TS SDK, Python SDK, CLI, GitHub Action, MCP
- GitHub Action: sandbox-first 6-step section
- MCP: honest framing ("production-capable, not first path for most users")
- Awaiting: Nick production verification → Launch polish pass on intros

### Tier 2 Docs (deferred, do when capacity allows)
- SDK pages: sandbox walkthrough examples
- CLI: vs connector comparison note
- GitHub Action: troubleshooting section
- Sandbox: "which paths support sandbox" matrix

### Connection-Path Architecture Analysis
Produced in session. 9 sections (matrix, onboarding arcs, depth audit, IA recommendation, copy per path, fix package, tier plan, truthfulness rules). Forward to Launch for messaging reference.

---

---

## Nick's Follow-Up Items (2026-03-29 — post Phases F/G/H, non-blocking)

### Phase F Follow-ups
1. Expand DocsTracker to: Python SDK, GitHub Action, MCP, auth, CLI, webhooks pages (as those surfaces grow)
2. Keep analytics metadata structured — no high-cardinality blobs, stay queryable
3. Add "aha moment" milestone events: first_sandbox_flow_completed, first_production_flow_completed, first_webhook_delivery_success, first_repeat_submission
4. Future: retention/cohort view — repeat use by mode, sandbox→production conversion, first→second submission conversion

### Phase I Follow-ups
1. Tag normalization — lowercase on write, dedup, controlled vocabulary later, basic moderation to prevent junk tags
2. Interest inbox UX — owner needs clean inbox: unread/read, archived, resolved, spam/abuse flag
3. Discovery ranking logic — later: verified performance should influence ordering, self-claimed tags should not dominate
4. Abuse monitoring — admin visibility into repeated rejections, muted/blocked requester behavior
5. Taxonomy governance — define who creates tags, freeform vs canonical, when tags graduate to official vocabulary

### Phase G Follow-ups
1. Hard 404 rule must apply to ALL future org-private surfaces (leaderboards, profile-derived, org-scoped API filters)
2. Invitation hardening: rate limit invites, duplicate handling, expired token behavior, revoked membership after invite
3. Clarify org deletion semantics: what happens to private challenges, soft vs hard delete, auditability
4. Resist role/permission sprawl — keep org roles simple unless strong reason to expand

### Phase H Follow-ups
1. Define "recent form" explicitly in code + docs: how many runs, recency weighting, category filtering
2. Suppress OR visibly mark low-confidence family strengths (insufficient data even above 3-completion floor)
3. Keep public profiles restrained and trust-oriented — no vanity drift
4. Future confidence layer: emerging → established → high-confidence labels (only when sample sizes justify)

---

---

## Phase D–I Status (2026-03-29)

### Phase D — Sandbox / Test Mode ✅ COMPLETE (2026-03-29 ~10:30 AM KL)
Git: a71c84c | Migration: 00029_sandbox.sql
- bouts_sk_test_* sandbox tokens, bouts_sk_* production tokens
- Hard access boundary at DB query level (sandboxFilter + enforceEnvironmentBoundary)
- 3 seeded sandbox challenges (UUIDs ...0001, ...0002, ...0003)
- Deterministic sandbox judging (orchestrator early-exit, no LLM/on-chain)
- POST /api/v1/dry-run/validate — validation_only live, simulated=501 placeholder
- GET /api/v1/sandbox/challenges — public
- POST /api/v1/sandbox/webhooks/test
- /docs/sandbox page, quickstart defaulted to sandbox
- CLI: --sandbox flag, [SANDBOX] indicator, @bouts/cli v0.1.2 published

### Phase E — Developer/Integration Management UI ✅ COMPLETE (2026-03-29 ~10:42 AM KL)
Git: 3c56492 | Migration: 00030_settings_ui.sql
- Token management UI: create/revoke, environment filter, amber=sandbox/blue=production, one-time reveal modal
- Webhook management UI: health indicators, delivery history, rotate secret, test, delete
- Developer quickstart panel: live diagnostics, SDK/CLI snippets, real copy-to-clipboard
- Admin developer metrics: token creation by day, webhook health, 24h failure alerts
- New endpoints: /api/v1/webhooks/[id]/deliveries, /api/v1/webhooks/[id]/rotate-secret, /api/admin/developer-metrics

### Phase F — Adoption Analytics ✅ COMPLETE (2026-03-29 ~10:56 AM KL)
Git: c4311ff | Migration: 00031_platform_analytics.sql
- platform_events table, logEvent() fire-and-forget logger
- 11 routes instrumented, docs funnel (DocsTracker client component)
- Admin Analytics tab: funnel, access modes, friction hotspots, env split
- 90-day retention cron registered (pg_cron, Sundays 03:00 UTC)
### Phase G — Private/Org Track ✅ COMPLETE (2026-03-29 ~11:43 AM KL)
Git: 7cb3bb1 | Migration: 00032_orgs.sql
- organizations, org_members, org_invitations tables + challenges.org_id FK
- org-guard.ts: hard 404 on all 5 surfaces (list, detail, sessions, results, breakdowns)
- /api/v1/orgs/* — full CRUD + members + invitations
- OrgManagement settings tab, admin org selector, /docs/orgs page
### Phase H — Verified Agent Reputation ✅ COMPLETE (2026-03-29 ~11:58 AM KL)
Git: a6689c5 | Migration: 00033_reputation.sql
- agent_reputation_snapshots table, ClaimBadge shared component
- computeAgentReputation() fire-and-forget, wired into orchestrator
- GET /api/v1/agents/[id]/reputation — public, below_floor at <3 completions
- Public agent profiles, daily recompute cron, /docs/reputation

### Phase I — Marketplace-Readiness Foundation ✅ COMPLETE (2026-03-29 ~12:12 PM KL)
Git: 29d7541 | Migration: 00034_marketplace_readiness.sql
- capability_tags, domain_tags, availability_status, contact_opt_in on agents
- GET /api/v1/agents with tag filtering, PATCH /api/v1/agents/[id]/discovery
- POST/GET /api/v1/agents/[id]/interest — full anti-spam (opt-in check, 5/hr, 24h cooldown, UNIQUE constraint)
- Interest inbox UI per agent, /docs/discovery, agent profile page updated

### FGHI Follow-up Fixes ✅ COMPLETE (2026-03-29 ~12:27 PM KL)
Git: 605c289
- F: DocsTracker on 6 more docs pages, 4 milestone events wired (first_sandbox/production/webhook/repeat)
- G: Invite rate limit (10/hr) + idempotent duplicate handling, org_audit_log table + deletion semantics
- H: recent_form explicitly defined (JSDoc + API meta), family strength confidence tiers (suppress count<2)
- I: Tag normalization, interest inbox UI + PATCH signal endpoint, admin abuse monitoring
### Phase I — Marketplace-Readiness → QUEUED

### Build Directives (locked by Nick 2026-03-29 10:20 AM KL)
1. Settings nav — new /settings/ section, native feel to existing dashboard
2. Analytics — Supabase platform_events only, no third-party
3. Docs tracking — HYBRID (server-side routes + client-side for quickstart/copy/install events)
4. Orgs — user-initiated creation (anyone can create)
5. Private challenges — hard 404 everywhere for non-members
6. Agent profiles — fully public (no auth required)
7. Reputation floor — 3+ completed submissions to show public stats
8. Interest signals — in-app notification only (no email)
9. Verified/self-claimed — shared React component system everywhere
10. CLI — publish each phase as it completes

---

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

### npm Publishing
- npm org: @bouts (agent-arena is owner)
- npm token: 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 (long-lived)
- Published: @bouts/sdk@0.1.0, @bouts/cli@0.1.0

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

### ✅ Phase B — SDK, CLI, Docs, Webhooks (2026-03-29 ~04:45 AM KL)
- @bouts/sdk: TypeScript SDK (packages/sdk/) — challenges, sessions, submissions, results, webhooks resources, waitForResult(), verifySignature(), auto-retry, typed errors
- @bouts/cli: CLI (packages/cli/) — login, challenges, sessions, submit, results, breakdown, doctor
- src/lib/webhooks/deliver.ts: HMAC-signed delivery, 3-attempt retry (1s/5s/30s), dead letter, auto-disable at 10 failures
- Webhook events wired: result.finalized + submission.completed (orchestrator), challenge.published (activation), challenge.quarantined + challenge.retired (lifecycle routes)
- POST /api/v1/webhooks/:id/test + GET /api/v1/webhooks/:id/deliveries
- Docs hub: /docs/auth, /docs/sdk, /docs/webhooks, /docs/api (expanded), /docs/cli (placeholder)
- Git: a0e6484

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

## Phase C — 2026-03-29

### What was done
- **packages/python-sdk/** — `bouts-sdk` v0.1.0 Python package (fully built)
  - `BoutsClient` (sync, requests) + `AsyncBoutsClient` (httpx, context manager)
  - Resources: challenges, sessions, submissions, results, webhooks
  - `wait_for_result()` with configurable timeout + poll_interval
  - `verify_signature()` static method for webhook HMAC verification
  - Pydantic v2 models: Challenge, Session, Submission, Breakdown, MatchResult, WebhookSubscription
  - Typed exceptions: BoutsAuthError, BoutsRateLimitError, BoutsTimeoutError, BoutsNotFoundError
  - Auto-retry with exponential backoff on 429/5xx
  - Build artifacts: `bouts_sdk-0.1.0.tar.gz` + `.whl` (builds cleanly)

- **github-action/** — GitHub Action v1.0.0 (node20)
  - `action.yml` with all 10 inputs + 7 outputs
  - `src/index.ts`: session → submit → poll → breakdown → job summary → threshold gates
  - `dist/index.js`: built with ncc (958kB, committed)
  - api_key never logged; idempotency key from challengeId + GITHUB_SHA

- **supabase/functions/mcp-server/index.ts** — DEPLOYED
  - 8 MCP tools (JSON-RPC 2.0 over HTTPS)
  - Admin-scoped tokens blocked at auth layer
  - Competitor breakdown only (internal fields stripped)
  - mcp_request_logs table: migration 00028 applied

- **src/app/docs/python-sdk/page.tsx** — Full Python SDK guide
- **src/app/docs/github-action/page.tsx** — Full GitHub Action guide  
- **src/app/docs/mcp/page.tsx** — Full MCP Server guide
- **src/app/docs/page.tsx** — Phase C section with 3 new cards

- **examples/** — 4 complete examples:
  - `python-quickstart/` — sync SDK quickstart (accurate, copy-pasteable)
  - `github-action-example/` — full workflow YAML
  - `webhook-receiver/` — Flask receiver with HMAC verification
  - `mcp-example/` — config.json for MCP clients
  - `validation-matrix.md` — test coverage matrix

- TypeScript: clean (0 errors after excluding github-action from tsconfig)
- Deploy: https://agent-arena-roan.vercel.app

### Gaps / Pending
- **PyPI publish**: ✅ `bouts-sdk@0.1.0` LIVE on PyPI — `pip install bouts-sdk` works
  Command: `cd packages/python-sdk && twine upload dist/*` with TWINE_USERNAME=__token__
- **Live API tests**: SDK tests pending real BOUTS_API_KEY in production
- **GitHub Action CI test**: needs push to actual GitHub repo to trigger

---

## Standing Rules (permanent)
- After EVERY deploy: update HANDOFF.md + MEMORY.md. No exceptions.
- Forge can build directly in /data/agent-arena (no need to route through Maks for Bouts work)
- All git commits author as "Maks Build / build@perlantir.com" (repo-level config)
- Apply migrations via Supabase Management API (project: gojpbtlajzigvyfkghrg, PAT in TOOLS.md)

---

## Phase B DX Refinements — 2026-03-29

### What was done
- **packages/cli/src/config.ts** — added `BOUTS_API_KEY` + `BOUTS_BASE_URL` env var support (env takes priority over stored config)
- **CLI rebuilt** and published to npm as **@bouts/cli v0.1.1**
- **src/app/docs/cli/page.tsx** — full CLI guide (install, auth, all commands, --json flag, credential storage table, error handling)
- **src/app/docs/quickstart/page.tsx** — new page with 3-track quickstart: REST API (curl), TypeScript SDK, CLI
- **src/app/docs/auth/page.tsx** — added "CLI Credential Storage" section (OS-specific paths, plaintext warning, env var alternative, keychain future plan)
- **src/app/docs/webhooks/page.tsx** — replaced single event list with "Currently Emitted Events (Live)" table + "Planned Future Events (Not Yet Emitted)" table with explicit warning
- **src/app/docs/changelog/page.tsx** — new page: versioning policies (SDK/CLI/API), deprecation headers, v0.1.0 release history
- **src/app/docs/page.tsx** — added "Start Here" banner card, Quickstart card, Changelog card; removed "Soon" badge from CLI card
- TypeScript: clean (0 errors)
- Deploy: https://agent-arena-roan.vercel.app
- Git: committed on master, pushed

### CLI npm status
- @bouts/cli v0.1.1 published to npm (public)
- @bouts/sdk v0.1.0 unchanged

### Gaps / Notes
- No new API routes required — all changes were docs + CLI config only
- Webhook "planned events" (session.created, breakdown.generated) are documented but not wired — accurate per spec
