# Forge Memory

## Identity
- Name: Forge 🔥 — Technical architect + code reviewer for Bouts / Agent Arena
- Bot: @ForgeVPSBot
- Model: claude-sonnet-4-6 (runtime default)
- Workspace: /data/.openclaw/workspace-forge
- Created: 2026-03-20

## Standing Operating Rules (permanent)
- After EVERY deploy: update HANDOFF.md (current tasks, what's live) AND MEMORY.md (key decisions). No exceptions.
- Forge builds directly in /data/agent-arena — no need to route through Maks for Bouts work
- All commits author as "Maks Build / build@perlantir.com"

## Pipeline Position
Scout → **Forge (architecture)** → Pixel → Maks → **Forge (review)** → QA → Launch

## Ballot Ingestion Stats (last updated: 2026-03-31 02:04 KL — run #4)
- Total calibration_results: 163 | Passed: 33 | Flagged: 129 | Calibrating: 5
- Total challenges: 187 (all pipeline_status=draft)
- ballot_lesson_entries in DB: 28 (positive: 7, negative: 7, mutation: 6, calibration_system: 6, family_health: 2)
- Real-LLM validated passes: 2 — FizzBuzz With Teeth (sep=69) + Async Memoize Gone Wrong (sep=84)
- Active alerts: WebSocket branch exhaustion (27 consecutive fails), 4 empty families, artifact trigger broken, 186/187 challenges untagged
- No contamination, family collapse, or do-not-publish emergencies detected
- generate_learning_artifact() DB trigger still not firing — Ballot in fallback synthesis mode
- Lesson files: positive, negative, mutation, calibration-system, family-health, all 6 family files, index.json — all current
- Last ingestion with new data: 2026-03-30 08:04 AM KL (run #2, 2 new real-LLM passes)
- Runs #3 and #4 confirmed no new data. System stable.

## Full Pre-Launch Pass — COMPLETE (2026-03-31 06:42 KL) — commit eaf4261

### RLS Verified Live (applied manually in Supabase SQL editor)
- submissions, challenge_entries, profiles, api_tokens: anon blocked ✅
- agents.api_key_hash, remote_endpoint_url, secret_hash: column-blocked ✅
- challenges (anon): active-only (2 rows visible) ✅

### Key decisions
- Paid tiers: fully disabled at launch. Backend inert (503), UI hidden. Re-enable when Stripe Connect activated.
- MCP: confirmed live (Supabase Edge Function v1.0, bouts_sk_ auth). NOT coming soon.
- 158 junk Pipeline-Test challenges deleted from DB. 2 preserved (had entries).
- Challenge pipeline: semi-automated. Gauntlet → intake API → Forge Review (manual) → calibration (auto) → Activate (manual).
- Reserve challenges ready to activate: ~25 non-junk waiting in pipeline.
- Active public challenges: "Full-Stack Todo App", "Debug the Payment Flow" (2 total).
- Admin health dashboard now has Remote Invoke toggle column.

### Commits this session
- 0818dc1: Free-at-launch (payment surfaces)
- c7c86ad: Gaming language removed
- 9896c79: Connector sweep (3 bugs: GH Action result URL, idempotency key truncation, deprecated API docs)
- ce114a5: API docs auth zones clarified
- 76190de: Pre-launch remediation (RLS migration, admin 500s, v1 challenges filter)
- eaf4261: Deferred items (junk challenges, USDC labels, RI toggle, MCP restored)

## Free-at-Launch Pass — COMPLETE (2026-03-31 03:20 KL)
Two-commit pass executed. Bouts is now fully free at launch with zero payment or gaming friction.

### Commit 0818dc1 — Payment surfaces disabled
- POST /api/challenges/[id]/checkout → 503 (inert, never creates Stripe session)
- POST /api/webhooks/stripe → always {received:true}, no processing
- POST /api/stripe/connect/onboard → 503
- GET /api/stripe/connect/return → safe redirect to /wallet
- enter-challenge-button: paid checkout branch removed; always free path
- wallet page: bank connect CTA removed, "Payouts coming soon" note added
- challenge detail: Entry Fee tag hardcoded to "Free", fee breakdown copy removed
- challenge card: entry fee badge suppressed
- how-it-works: cost FAQ + payout copy rewritten for free launch

### Commit c7c86ad — Betting/gaming framing removed
- /legal/responsible-gaming → redirect to /legal/terms
- /legal/contest-rules → redirect to /legal/terms
- Footer: gaming disclaimer bar removed (helplines, 18+, void-in-state), RG + Contest Rules links removed
- Onboarding: full rewrite — removed DOB, state dropdown, age gate, restricted state block, 6-checkbox compliance wall; now: name + Terms + Privacy only
- Middleware: US state geo-blocking (WA/AZ/LA/MT/ID) removed; OFAC blocking retained
- /unavailable: OFAC-only copy
- Wallet: restricted-state copy removed

### Intentionally inert (not deleted)
- src/lib/stripe.ts — functional but unreachable from UI
- entry-fee-modal.tsx — not imported anywhere
- Wallet W9/claim flow — retained for future payout system

### Post-launch deferred cleanup
- Remove entry-fee-modal.tsx
- Re-enable Stripe Connect + webhook when paid challenges ship
- Un-hardcode Entry Fee = "Free" tag
- Re-add state geo-blocking if paid contests return

## Active Project: Bouts / Agent Arena
- Live: https://agent-arena-roan.vercel.app ✅ Confirmed operational (2026-03-31)
- Stack: Next.js App Router, TypeScript strict, Tailwind, Supabase, Vercel
- Latest deploy: 2026-03-31 ~10:45 KL — full launch remediation pass complete (9817615)

## Full Launch Remediation Pass — COMPLETE (2026-03-31 ~10:45 KL)
Git: c0970ad → 56ca946 → 9817615 | Migration 00042 applied by Nick in Supabase SQL editor

### Key decisions and permanent patterns:
- **RLS fix**: public.is_admin() SECURITY DEFINER function — recursion-safe, bypasses RLS internally. All policies now use this instead of inline profiles subqueries.
- **App pattern**: All API routes that read profiles or challenge_entries use createAdminClient() — safe (always filtered to user.id), eliminates RLS recursion risk permanently.
- **requireAdmin()**: Uses createAdminClient() — all admin routes unaffected by future RLS changes.
- **Replay route**: Strips optional columns (positive_signal, primary_weakness, overall_verdict) from SELECT until migration applied; UI synthesizes from lane data when null. Pattern to maintain.
- **Provisional placement rule**: challenge_ends_at > now → show "· provisional" + "Official standings finalize when the challenge closes." challenge_ends_at ≤ now → final label only. Consistent across results, replay, challenge detail.
- **Session-extends-past-close warning**: shown in workspace when challengeCloseMs < sessionExpiresMs AND close < 30 min away.
- **Admin form labels**: "Challenge Window Opens/Closes (UTC)" + "Per-Entry Session (minutes)" — never "Time Limit" or "Starts/Ends At" alone.
- **StatusBadge**: has full 30-entry human label map — never renders raw snake_case to operators.
- **Supabase PAT**: expired as of 2026-03-31 — needs renewal for future CLI/Management API access.

### Columns added (migration 00042):
- judge_outputs.positive_signal TEXT
- judge_outputs.primary_weakness TEXT  
- challenge_entries.overall_verdict TEXT
All nullable — UI gracefully handles null via synthesis from lane data.

## Launch Timing + Feedback Model — COMPLETE (2026-03-31 ~08:00 KL)
- Git: 335b23e + 1031d1a (two commits)
- Challenge window vs per-entry session fully separated throughout codebase, UI, and docs
- Default: 48h challenge window, 60min per-entry session
- Dual-clock in workspace: "Your Session" timer + "Challenge Closes in Xh" — separate labels
- PostMatchBreakdown fully rewritten: synthesized verdict (never generic filler), per-lane positive/weakness, "What to improve next" (evidence-derived, max 5), relative context with provisional label
- Provisional placement on status page + replay — labeled explicitly, "standings finalize at close"
- Schema: judge_outputs.positive_signal, judge_outputs.primary_weakness, challenge_entries.overall_verdict (migration 00041 — applied manually)
- All timing copy updated: how-it-works, compete docs, quickstart, challenge-detail-header, landing current-challenge card
- "LIVE SESSION" badge replaced with "Open — enter any time" everywhere
- Landing current-challenge: now fetches real active challenge from API (was hardcoded stale data)
- CRITICAL FIX (78f741e): lane-runner was sending submission_id to edge functions that require entry_id → match_results were never written. Fixed.
- Fix A (2c9eaa5): @bouts/connector@0.1.2 published to npm. submitSolution() uses /api/connector/submit. Package renamed from arena-connector → @bouts/connector.
- Fix B (565886b): GitHub Action makeIdempotencyKey(sessionId) — aligns with Python SDK pattern.

## RAI — FULLY COMPLETE (2026-03-31 01:35 KL — QA browser-verified)
All 6 polish items passed QA. One P1 bug caught by QA and fixed immediately.
- Git trail: 812b72d (RAI remediation) → 1675bb7 (polish pass) → e423617 (settings mobile + docs copy button) → 02d24d4 (P1 bug fix)
- 6/6 items browser-verified ✅: validate shortcut, deep-link subtab, trust note link, env microcopy, web-submission page, copy consistency
- P1 BUG FIXED (02d24d4): workspace/route.ts early returns (already_submitted, expired x2) missing remote_invocation_supported → client showed "Connector Required" instead of correct terminal state for RI challenges
- Shared CodeBlock component: src/components/docs/code-block.tsx — copy button on all 12 docs pages
- Settings mobile: tab row now horizontal-scrolls on mobile (no more wrap/overlap)
- /docs/web-submission: explanatory transition page (not silent redirect)
- All settings links deep-link to ?tab=agent&subtab=remote-invocation
- Zero open RAI items. Feature is launch-ready.

## Remote Agent Invocation — Decision (2026-03-30 11:27 AM KL — Nick locked)
- DECISION: Replacing manual text-submission web path with Remote Agent Invocation (Option 1)
- Production web path = Remote Agent Invocation (Bouts calls user's HTTP endpoint server-side)
- Sandbox/practice = manual text path retained but clearly separated + labeled
- NOT: hosted runtime, cloud execution, browser IDE — just HTTP invocation of user's running agent
- Build plan: 3 phases, no confirmation needed between phases
  - Phase 1: Architecture spec + data model (migrations 00038+, new tables)
  - Phase 2: Backend (endpoint registration, invocation engine, pipeline integration)
  - Phase 3: Frontend UX + docs updates
- Architecture spec saved to: /data/.openclaw/workspace-forge/remote-agent-invocation-spec.md
- submission_source='remote_agent' for this path
- SSRF protection required: block private IPs, require HTTPS in prod, domain allowlist option
- HMAC-SHA256 signing: per-agent secret, X-Bouts-Signature, X-Bouts-Timestamp, replay window 5min
- Invocation timeout: 30s hard limit, no retries on timeout (terminal)

## Phase R1 Complete — Security + Pipeline (2026-03-30 09:58 AM KL)
- Item 9: POST /api/v1/submissions → 410 Gone (deprecated, use session-based flow)
- Item 10: Legacy /api/challenges list filters to active+non-sandbox+public for anon users; detail route returns 404 for sandbox/draft/org-private to anon
- Item 11: Replay endpoint now checks org_id on challenge; org-private replays require authenticated org membership → 404 for non-members
- Item 12: /qa-login → hard 404 (rewrite to /_not-found) unless NODE_ENV=development AND ENABLE_QA_LOGIN=true
- Item 13: All 3 cron routes (process-judging-jobs, challenge-quality, gauntlet) use isCronAuthorized() — fail-closed if no CRON_SECRET and no x-vercel-cron: 1 header
- Item 14: DB unique index idx_submissions_one_per_entry confirmed from migration 00036; app-level duplicate check added to v1/sessions/[id]/submissions (connector and web-submit already had it)
- Item 2: Dead-job recovery in process-judging-jobs: clears running jobs >15min as failed before claiming new jobs; orchestrator catch block updated with rejection_reason; 1 stuck job cleaned up manually in DB
- Chain's on-chain env vars: ALL set as Supabase secrets (Mar 27). Edge functions only — nothing needed in Vercel.
- Supabase project: gojpbtlajzigvyfkghrg
- Supabase project: gojpbtlajzigvyfkghrg

## Phase A Complete — Multi-Access Layer (2026-03-29 ~03:55 AM KL)
- api_tokens table: SHA-256 hashed, bouts_sk_ prefix, scopes, expiry, revocation
- submission_idempotency_keys: 24h TTL, 64-char hex key
- webhook_subscriptions + webhook_deliveries: event subscriptions, delivery log
- token-auth.ts: unified auth resolver — handles bouts_sk_*, JWT, aa_* connector tokens
- rate-limit-policy.ts: named policies (public:read, authed:read, submission:create, token:create, webhook:manage, admin:operations, mcp:tool)
- v1 route layer: /api/v1/* with standard envelope, X-Request-ID, X-API-Version, rate limit headers
- OpenAPI 3.1 spec at /api/v1/openapi
- All routes: requireScope() enforced, v1Error() shape, no any types, no console.log

## Phase 2 Complete (2026-03-29 ~02:30 AM KL)
- All Phase 1 gap fixes applied (judge_weights wired, has_prize wired, edge fn normalizer added)
- /api/challenges/daily fixed (difficulty column removed, correct columns used)
- connector docs v0.1.1 badge added
- 5 new admin tabs in AdminDashboardClient.tsx
- 5 new admin API endpoints (intake-queue, health-dashboard, quarantine, retire, cleanup)
- Judging queue status bar on all admin pages
- Git: 6319f59 | Deploy: https://agent-arena-roan.vercel.app

## Challenge Pipeline Architecture (2026-03-28 — permanent decisions)
- Gauntlet = challenge creator. Platform validates, calibrates, routes, publishes.
- Gauntlet submits Skill 77 bundles via POST /api/challenges/intake
- Auth: Bearer 1b12f7484f1d283543c98ae1ecbd1c358d68f68b5e896dac2b9bca92e91c1f8e (GAUNTLET_INTAKE_API_KEY — set in Vercel, confirmed working)
- Bundle families: blacksite_debug | fog_of_war | false_summit | recovery_spiral | toolchain_betrayal | abyss_protocol
- Bundle formats: sprint | standard | marathon
- Bundle weight classes: lightweight | middleweight | heavyweight | frontier
- 14-state pipeline_status on challenges table
- Forge reviews via /api/admin/forge-review (structured package, not chat)
- Operator inventory decisions via /api/admin/inventory
- First batch: 2 Blacksite Debug + 2 False Summit + 1 Fog of War, Lightweight–Middleweight, Sprint/Standard only

## Ballot Learning System (2026-03-28 — permanent decisions)
- Ballot = background-only agent, Sonnet model, no Telegram bot
- Workspace: /data/.openclaw/workspace-ballot/
- Triggered automatically after every calibration verdict (fire-and-forget from orchestrator)
- Flow: calibration verdict → generate_learning_artifact() DB fn → POST /api/admin/ballot/run → ingest-artifacts.ts → write lesson files
- Lesson files: workspace-gauntlet/private/gauntlet-lessons/ (positive, negative, mutation, family-health, calibration-system, 6 per-family files, index.json)
- Confidence: 1 obs=low, 3+=medium, 5+=high. High-confidence = hard signal for Gauntlet
- Ballot synthesizes — never dumps raw logs
- Direct Gauntlet messaging ONLY for: contamination alert, family collapse (3+ consecutive fails), do-not-publish emergency, branch exhaustion
- Opus escalation mode available later: family collapse, contradictory lessons, monthly deep synthesis

## Judging System Canon (permanent)
- 4 lanes: Objective 50% (published as 45–65% band), Process 20%, Strategy 20%, Integrity 10%
- Calibration: synthetic first, real LLM per policy, CDI computed
- Activation gate: calibration_status=passed + required assets check + trigger
- Activation freeze snapshot: prompt hash, test config, judge weights, thresholds frozen at activation

## Multi-Access Platform Architecture (2026-03-29 — permanent decisions)
- Phase A complete: /api/v1/ layer, scoped API tokens (bouts_sk_*), idempotency (sessions + submissions), named rate limit policy, webhook foundation, OpenAPI 3.1 spec
- Token format: bouts_sk_ + 55 hex chars. SHA-256 hash stored only, plaintext shown once on creation.
- Scopes: challenge:read, challenge:enter, submission:create, submission:read, result:read, leaderboard:read, agent:write, webhook:manage. admin:* never issuable externally.
- Idempotency-Key header required for API submission; 24h dedup via submission_idempotency_keys table
- Session creation idempotent on (challenge_id, agent_id) — returns existing open session
- OpenAPI spec live at: /api/v1/openapi
- API index at: /api/v1
- Deprecation policy: 90-day minimum notice, X-API-Sunset header, changelog entry required
- Phase B (next): TypeScript SDK, CLI, docs hub, full webhook system
- Phase C (future): Python SDK, GitHub Action, MCP server, enterprise tracks

## Phase Build Status (2026-03-29) — ALL COMPLETE
- Phase 1 ✅ — Competition runtime (judging_jobs + FOR UPDATE SKIP LOCKED, 13-stage orchestrator, aggregator, immutable match_results, 3-audience breakdowns, challenge activation 7-gate)
- Phase 2 ✅ — Admin UI (5 tabs: Intake/Forge Review/Calibration/Inventory/Health), lifecycle endpoints (quarantine/retire/activate/unpublish), gap fixes (judge_weights, has_prize, edge fn normalizer), /api/challenges/daily fix, connector v0.1.1 badge, agent cleanup endpoint
- Phase 3 ✅ — Ballot cron registered (ID: 4a50d140-918c-4a75-bb52-ca565c439eb8, every 6h UTC, session: ballot-ingestion)
- Deployed and confirmed operational: /api/status returns {status: "operational"}

## DB Migrations Applied
- 00020: challenge quality automation
- 00021: activation snapshot
- 00022: calibration system
- 00023: challenge pipeline (reserve status, calibration states)
- 00024: intake pipeline (pipeline_status, challenge_bundles, forge_reviews, inventory_decisions)
- 00025: ballot learning system (calibration_learning_artifacts, ballot_lesson_entries, generate_learning_artifact())
- 00026: competition runtime (judging_jobs + claim_judging_job() FOR UPDATE SKIP LOCKED, challenge_sessions, submission_artifacts, submission_events, judge_runs, judge_lane_scores, judge_lane_artifacts, judge_execution_logs, match_results, match_lane_scores, match_breakdowns, match_breakdown_versions, audit_trigger_rules)
- 00026: competition runtime (judging_jobs, challenge_sessions, submission_artifacts, submission_events, judge_runs, judge_lane_scores, judge_lane_artifacts, judge_execution_logs, match_results, match_result_overrides, match_lane_scores, match_breakdowns, audit_trigger_rules + claim_judging_job/enqueue_judging_job functions)

## Key API Routes
| Route | Purpose |
|-------|---------|
| POST /api/challenges/intake | Gauntlet bundle submission |
| GET/POST /api/admin/forge-review | Forge review queue + verdict |
| GET/POST /api/admin/inventory | Operator publish/reserve decisions |
| GET/POST /api/admin/ballot | Ballot stats + manual run |
| GET/POST /api/admin/calibration | Run calibration on a challenge |
| GET/POST /api/admin/challenge-quality | CDI + quality enforcement |
| POST /api/challenges/[id]/sessions | Create challenge session (version snapshot frozen) |
| GET /api/challenge-sessions/[id] | Session status + submission count |
| GET /api/challenge-submissions/[id] | Submission status + event log |
| GET /api/submissions/[id]/breakdown | Audience-aware breakdown (competitor/spectator/admin) |
| POST /api/internal/judge-submission | Trigger orchestrator (service key auth) |
| GET /api/cron/process-judging-jobs | Claim + dispatch judging job (cron, every 2min) |
| POST /api/admin/challenges/[id]/activate | 7-gate activation |
| POST /api/admin/challenges/[id]/unpublish | Revert to passed_reserve |
| GET /api/admin/judging-queue | Queue depth, latency, stuck jobs, dead letters |

## Competition Runtime Architecture (2026-03-29 — permanent decisions)
- Judging queue: judging_jobs table with FOR UPDATE SKIP LOCKED claim (no race conditions)
- Version snapshots frozen at session AND submission time (config changes don't affect past runs)
- Artifacts immutable: SHA-256 hash stored, content never updated
- Events append-only: submission_events, judge_execution_logs
- match_results IMMUTABLE: use match_result_overrides for admin corrections
- Audit rules configurable from DB (not hardcoded): audit_trigger_rules table
- 4 default rules seeded: process_strategy_divergence (>15pt), divergence_weak_objective, high_score_integrity_anomaly, prize_challenge_override
- Cron job ID: 4e028b13-dad0-4b36-a7f7-32dd5fdfd950 (bouts-judging-processor, every 2min)

## Stack Being Reviewed
- Next.js App Router + TypeScript strict + Tailwind + Supabase + Vercel
- Expo (React Native) for mobile
- Claude API (Anthropic SDK)
- Zod validation

## Known Recurring Patterns (Maks blind spots — check these first)
- Missing Supabase error checking (destructures {data} without {error})
- Skips auth on server-side routes
- Uses getSession() instead of getClaims() on server
- Over-fetches with select('*')
- Weak Zod validation (missing .uuid(), .positive())

## Review History
See review-history/ for per-project logs

## CVEs / Security Advisories Tracked
- [DATE]: [CVE] — [framework] — [severity] — [action taken]

## Skills Available
security-review, typescript-mastery, react-nextjs, supabase-patterns, database-review, api-design, performance, accessibility-seo, expo-react-native, testing-quality, devops-docker, code-review-protocol, forge-research, framework-source-code, developer-patterns, auto-fix, threat-modeling, self-review, weekly-security-scan, owasp-stack-specific, react-nextjs-security, supabase-attack-vectors, and 80+ more

## Web Submission System — W4 COMPLETE (2026-03-30 06:08 AM KL)
Git: 5528022 | Deploy: https://agent-arena-roan.vercel.app

### W3-patch2 (04:35 AM KL) — Git: 1baefd4
- Migration 00037: sandbox challenges reseeded with RFC 4122 v4 UUIDs
  - Hello Bouts: 69e80bf0-597d-4ce0-8c1c-563db9c246f2
  - Echo Agent:  5db50c6f-ac55-43d3-80a6-394420fc4781
  - Full Stack:  b21fb84b-81f6-49cc-b050-bf5ec2a2fb8f
- Real challenges flagged web_submission_supported=true: 22baff1f (Full-Stack Todo), 41f952c5 (Debug Payment Flow)
- Stale root middleware.ts deleted — src/middleware.ts is active
- Duplicate getUser() fixed in src/middleware.ts

### W3-patch3 (04:55 AM KL) — Git: d432ec8
- workspace/route.ts + web-submit/route.ts: .maybeSingle() → .order('created_at').limit(1)[0]
- Fixes PGRST116 false-negative for multi-agent users

### W4 (06:08 AM KL) — Git: 5528022
- challenge-submissions/[submissionId]/route.ts: maybeSingle→limit(1) (Sentinel carry-over) + result_id returned on completed status
- status/page.tsx: failed state redesigned (AlertTriangle, rejection_reason box, platform framing, retry button, support guidance), result_id in type
- workspace/page.tsx: timer + "Submitting as" merged into single identity card; in-flight submitting state (spinner, blue border, Sending badge)
- W5 next: docs/messaging alignment

## Web Submission System — W3 COMPLETE (2026-03-30 03:35 AM KL)
Git: 7104052 | Deploy: https://agent-arena-roan.vercel.app
- POST /api/challenges/[id]/web-submit: full pipeline, submission_source='web', dual-session conflict resolved explicitly, always JSON errors
- /submissions/[id]/status: polls every 5s, 5 states, event log, terminal-state stop, 10min timeout, always has fallback link
- Polaris applied: 'Web Submission' label, 'Your Solution' textarea, ⚠ amber danger constraints, Bot icon, confirm copy tightened, 50-char warning removed
## Web Submission System — W-FINAL COMPLETE (2026-03-30 07:20 AM KL)
Git: 728c7ad | Deploy: https://agent-arena-roan.vercel.app
All phases complete: W0→W5 + W3-patch1/2/3 + W4-polish + W-final
No known user-facing polish/coherence items remain in this path.

P1 fixes:
- replays/[entryId]/page.tsx: debug header replaced with product-grade 'Submission Breakdown' header
  (Bot/date/placement meta row, back nav, 'Visual Output Rendering'→'Visual Output', 'Replay Timeline'→'Execution Timeline')
- status/page.tsx: sanitizeRejectionReason() gate (blocks stack traces, exceptions, >200 chars, ALL_CAPS codes, Postgres errors)
  Fallback: 'We hit a platform issue while processing this submission.'
  CTA: 'View Your Results →' → 'View Full Breakdown →'
- results/page.tsx: 'View Replay' → 'View Breakdown'

P2 fixes:
- compete/page.tsx: 'How to Submit' section with web vs connector two-path grid
- quickstart/page.tsx: Track 0 icon Globe → MonitorCheck (distinct from REST API Globe)

Status: ✅ COMPLETE — Sentinel 10/10 PASS, Polaris all items cleared. Nick confirmed 2026-03-30 08:47 AM KL.

## Web Submission System — W2 COMPLETE (2026-03-30 03:05 AM KL)
Git: 48903d4 | Deploy: https://agent-arena-roan.vercel.app
- GET /api/challenges/[id]/workspace: idempotent session creation, timer-start on first open, 5 workspace states
- /challenges/[id]/workspace page: left=prompt panel, right=timer+constraints+textarea+submit
- Manual Browser Submission badge, Submitting as [Agent Name], 5-min warning banner
- Constraints panel (collapsed default), byte counter + progress bar, 1-submission confirm modal
- 7 handled states: loading/open/not_entered/already_submitted/expired/not_supported/error
- Fixed [challengeId]/sessions route: upsert status 'active' → 'workspace_open'
- Submit wired to POST /api/challenges/[id]/web-submit (built in W3)
- W3 next: web-submit route + status polling page

## Web Submission System — W1-patch2 DEPLOYED (2026-03-30 02:38 AM KL)
Git: f7a8bfc | Deploy: https://agent-arena-roan.vercel.app
- SUBMITTABLE_STATUSES in /api/v1/submissions/route.ts now includes workspace_open
- All Sentinel W1 findings resolved — W2 fully cleared

## Web Submission System — W1-patch DEPLOYED (2026-03-30 02:25 AM KL)
Git: d9ec19f | Deploy: https://agent-arena-roan.vercel.app
- P1 fix: result_ready CTA → /results (real dashboard), was broken /challenges/[id]/results (404)
- Dead state removed: 'judging' eliminated from ParticipationState type + stateConfig (not a real entry status)
- workspace_open allowlists confirmed complete — no further changes needed in existing routes
- W2 cleared by Forge, awaiting Nick approval

## Web Submission System — W1 COMPLETE (2026-03-30 02:25 AM KL)
Git: 0ccf990 | Deploy: https://agent-arena-roan.vercel.app
- ParticipationStatusBlock component: 8 explicit states (not_entered/entered/workspace_open/submitted/judging/result_ready/expired/failed)
- participation_state + user_entry_id returned from challenge detail API
- web_submission_supported in public challenge detail + list API
- workspace_open in events/stream allowlist + JUDGEABLE_STATUSES
- expired state copy: "This entry can no longer accept a submission"
- W2 next: workspace page /challenges/[id]/workspace

## Web Submission System — W0 COMPLETE (2026-03-30 01:55 AM KL)
Git: abdf3dc | Deploy: https://agent-arena-roan.vercel.app
- Migration 00035: web_submission_supported (challenges), submission_source (submissions), status constraint extended (workspace_open, expired), legacy judging→in_progress
- Sandbox challenges flagged web_submission_supported=true (all 3)
- PATCH /api/admin/challenges/[id]: accepts web_submission_supported
- Challenge Health admin tab: Web Submit toggle column (per-challenge enable/disable)
- Supabase PAT updated in TOOLS.md: sbp_f8240f4ee4a6edf7bbdb8f60aa1efa5affeb2b27
- W1 next: participation state model — explicit entry states on challenge detail page

## Web Submission System (Phase W) — APPROVED, W0 STARTING (2026-03-30 01:20 AM KL)
- Nick approved phased web submission build (W0–W5)
- 7 clarifications locked (see HANDOFF.md)
- Key decisions: session-aware workspace, timer starts on open, submission_source='web', "Manual Browser Submission" UX label, explicit constraint panel, 7-state model on challenge detail
- Migration: 00035_web_submission.sql (web_submission_supported on challenges, session_id FK on entries)
- Product truth gap closes when W5 ships

## Tier 1 Docs Pass (2026-03-29 ~23:43 PM KL) ✅ COMPLETE
Git: 86d9999 | Deploy: https://agent-arena-roan.vercel.app
- /docs: "Where do you want to start?" 6-card path chooser added
- /docs/quickstart: 4 tracks (0=Web, 1=REST, 2=TS SDK, 3=CLI) + "Not sure which path?" note
- /docs/connector: H1 → "Connector CLI — Setup Guide", intro leads with "Bouts Connector CLI"
- /docs/api, /docs/sdk, /docs/python-sdk, /docs/cli, /docs/github-action, /docs/mcp: all have "Who this is for" intros
- GitHub Action: sandbox-first section added
- MCP: "production-capable but not recommended first path" framing

## Connection-Path Architecture Analysis (2026-03-29 ~23:05 PM KL)
Full analysis produced (9 sections) — matrix, onboarding arcs, depth audit, IA recommendation, copy per path, fix package, tier plan, truthfulness rules.
Tier 1 implemented: 86d9999
Tier 2 (deferred): SDK sandbox walkthroughs, CLI vs connector comparison note, GitHub Action troubleshooting, sandbox path matrix
Tier 3 (later): full tutorials per path, interactive path selector, MCP client-specific guides

## Copy Cleanup Passes (2026-03-29) — ALL COMPLETE
Commits: 049eeb8 → 6367f8b → 439296f → 8a7dc34 → 8b0be6a
Root cause fixed: duplicate header components (public-header.tsx was the live one, Track A only edited header.tsx)

## Sitewide Copy Cleanup — COMPLETE + CLOSED (2026-03-29)
Source: BOUTS_FINAL_COPY_ALIGNMENT.md (workspace-launch)

Pass 1 (Track A): 049eeb8 — 20 files, all Tier 1/2/3 rewrites
Pass 2 (completion): 6367f8b — 17 more files, final string sweep

Status: CLOSED. Do not reopen unless specific leftover string found in live product.

Bucket B (deferred — safe later):
- Docs card reorder (individually-written JSX blocks, layout risk)
- [ARENA:*] wire protocol markers (connector protocol syntax, not copy)
- arena.json config name
- x-arena-api-key header (API contract)

Bucket C (migration sprint — NOT opportunistic cleanup):
- [ARENA:*] event protocol → connector v2 + backwards compat
- x-arena-api-key header → API v2 deprecation cycle
- CSS classes (arena-glass, arena-live-dot, etc.)
- /components/arena/ directory rename

## FGHI Follow-up Fixes (2026-03-29 ~12:27 PM KL) ✅ COMPLETE
Git: 605c289 | All 9 fixes deployed
- DocsTracker expanded to 6 more docs pages
- 4 milestone events: first_sandbox/production_flow_completed, first_webhook_delivery_success, first_repeat_submission
- Invite rate limit (10/hr) + idempotent duplicate invite
- org_audit_log table (delete/member_removed/role_changed)
- recent_form explicitly defined + recent_form_meta in API
- Family strength confidence tiers: ≥5=high, ≥2=medium, =1 suppressed
- Tag normalization on write (lowercase, trim, dedup)
- Interest inbox UI per agent + PATCH signal endpoint
- Admin abuse monitoring (interest_signal_abuse in analytics)

## Phase I — Marketplace-Readiness Foundation (2026-03-29 ~12:12 PM KL) ✅ COMPLETE
Git: 29d7541 | Migration: 00034_marketplace_readiness.sql
- capability_tags, domain_tags, availability_status, contact_opt_in on agents
- Tag filtering on GET /api/v1/agents, PATCH /api/v1/agents/[id]/discovery
- Interest signals: hard opt-in check, 5/hr rate limit, 24h cooldown, UNIQUE(agent,requester)
- ClaimBadge used throughout, /docs/discovery page

## Phase H — Verified Agent Reputation (2026-03-29 ~11:58 AM KL) ✅ COMPLETE
Git: a6689c5 | Migration: 00033_reputation.sql
- agent_reputation_snapshots (participation, completion, consistency, family strengths, recent form)
- ClaimBadge shared component (src/components/shared/claim-badge.tsx) — used everywhere
- computeAgentReputation() — excludes sandbox + org-private, is_verified at 3+ completions
- GET /api/v1/agents/[id]/reputation — public, below_floor suppresses all stats
- Daily recompute cron (04:00 UTC), /docs/reputation page

## Phase G — Private/Org Tracks (2026-03-29 ~11:43 AM KL) ✅ COMPLETE
Git: 7cb3bb1 | Migration: 00032_orgs.sql
- organizations, org_members, org_invitations tables + challenges.org_id FK
- org-guard.ts: hard 404 on all 5 surfaces (list, detail, sessions, results, breakdowns)
- Full /api/v1/orgs/* CRUD + members + invitations
- OrgManagement settings tab, admin org selector, /docs/orgs

## Phase F — Adoption Analytics (2026-03-29 ~10:56 AM KL) ✅ COMPLETE

Git: c4311ff | Deploy: https://agent-arena-roan.vercel.app
Migration: 00031_platform_analytics.sql (platform_events table, 5 indexes, cleanup fn, pg_cron weekly)

Key files:
- src/lib/analytics/log-event.ts — fire-and-forget logger, inferAccessMode()
- src/app/api/analytics/track/route.ts — client-side whitelisted ingestion
- src/components/analytics/docs-tracker.tsx — DocsTracker + TrackableButton
- src/app/api/admin/analytics/route.ts — access_mode_breakdown, friction_hotspots, env_split, recent_errors
- src/app/api/admin/analytics/funnel/route.ts — 9-stage funnel with drop-off %
- src/app/api/admin/analytics/access-modes/route.ts — per-mode activity

Events wired: token_created, token_revoked, session_created, sandbox_session_created, submission_received (v1+connector), result_retrieved, breakdown_retrieved, webhook_created, dry_run_validated, auth_failed, scope_error
Docs funnel: DocsTracker on docs-home, quickstart, sandbox, sdk pages

## Phase E — Developer/Integration Management UI (2026-03-29 ~10:42 AM KL) ✅ COMPLETE

Git: 3c56492 | Deploy: https://agent-arena-roan.vercel.app
Migration: 00030_settings_ui.sql applied (consecutive_failures + last_rotated_at on webhooks, notifications table, admin_developer_metrics view)

Key files:
- src/components/settings/token-management.tsx — full token CRUD, environment filter, one-time reveal modal
- src/components/settings/webhook-management.tsx — health indicators, delivery history, rotate secret, test event
- src/components/settings/developer-quickstart.tsx — live diagnostics + SDK/CLI snippets
- src/app/(dashboard)/settings/page.tsx — Tokens + Webhooks + Developer tabs added
- src/app/api/v1/webhooks/[id]/deliveries/route.ts — delivery history endpoint
- src/app/api/v1/webhooks/[id]/rotate-secret/route.ts — secret rotation (plaintext shown once)
- src/app/api/admin/developer-metrics/route.ts — admin-only metrics

## Phase D — Sandbox / Test Mode (2026-03-29 ~10:30 AM KL) ✅ COMPLETE

Git: a71c84c | Deploy: https://agent-arena-roan.vercel.app
Migration: 00029_sandbox.sql applied

Architecture: Stripe-style token environment split. bouts_sk_test_* = sandbox, bouts_sk_* = production.
Hard boundary enforced at DB query level (sandboxFilter + enforceEnvironmentBoundary).

Key files:
- src/lib/auth/token-auth.ts — AuthContext now has environment + token_id fields
- src/lib/auth/sandbox-guard.ts — enforceEnvironmentBoundary(), sandboxFilter()
- src/lib/judging/sandbox-judge.ts — deterministic synthetic judging (no LLM, no on-chain)
- src/lib/judging/orchestrator.ts — sandbox early-exit path
- src/app/api/v1/dry-run/validate/route.ts — validation_only + simulated(501) modes
- src/app/api/v1/sandbox/challenges/route.ts — public sandbox challenge list
- src/app/api/v1/sandbox/webhooks/test/route.ts — test webhook event delivery
- src/app/docs/sandbox/page.tsx — full sandbox docs page

Seeded sandbox challenges (permanent UUIDs):
- 00000000-0000-0000-0000-000000000001 — [Sandbox] Hello Bouts (sprint, 30min)
- 00000000-0000-0000-0000-000000000002 — [Sandbox] Echo Agent (standard, 60min)
- 00000000-0000-0000-0000-000000000003 — [Sandbox] Full Stack Test (marathon, 120min)

CLI: bouts login --sandbox, [SANDBOX] indicator, doctor shows env, @bouts/cli v0.1.2 published

## 2026-03-29 — Phase D–I Build Directives (locked by Nick)

1. Settings UI (/settings/) — build new section, must feel native to existing dashboard (not bolt-on)
2. Analytics — Supabase platform_events only, no third-party for v1, 90-day retention
3. Docs tracking — HYBRID: server-side for core route hits, client-side for quickstart started/completed, copy actions, install snippet clicks
4. Orgs — anyone can create an org (user-initiated)
5. Private challenge access — hard 404 everywhere for non-members (no existence leakage)
6. Agent profiles — fully public (no auth required to view)
7. Reputation floor — suppress public stats until 3+ completed submissions
8. Interest signals — in-app notification only (no email for now)
9. Verified vs self-claimed — shared React component system used everywhere (not ad hoc per page)
10. CLI publishing — publish each phase as it completes (@bouts/cli v0.1.2 with Phase D sandbox support)

## 2026-03-29 — Phase C (Python SDK, GitHub Action, MCP, Docs, Examples)

1. **Python SDK (bouts-sdk v0.1.0)** — packages/python-sdk/. Sync + async, Pydantic v2, auto-retry, typed exceptions. Builds to .whl. PyPI publish pending token from Nick.
2. **GitHub Action v1.0.0** — github-action/. node20, ncc-built dist/index.js committed. Score thresholds, idempotent, api_key never logged.
3. **MCP Server** — supabase/functions/mcp-server/. 8 tools, JSON-RPC 2.0, admin tokens blocked, deployed. mcp_request_logs table (migration 00028).
4. **Docs** — /docs/python-sdk, /docs/github-action, /docs/mcp all new. /docs page updated with Phase C cards.
5. **Examples** — 4 complete copy-pasteable examples in /data/agent-arena/examples/
6. **tsconfig** — github-action excluded from Next.js compilation
7. **Deploy** — https://agent-arena-roan.vercel.app ✅

## 2026-03-29 — Phase B DX Refinements

Applied 6 DX refinements to Bouts docs and CLI:

1. **CLI docs complete** — /docs/cli is no longer a placeholder. Full guide with all commands, credential storage (OS table), error handling, --json flag.
2. **Quickstart page** — /docs/quickstart added (new). Three tracks: REST/curl, TypeScript SDK, CLI. "Before you start" checklist with token + active challenge prereqs.
3. **Auth page** — CLI Credential Storage section added: OS-specific config paths, plaintext warning, BOUTS_API_KEY env var, keychain roadmap.
4. **Webhooks page** — Event types split into "Currently Emitted (Live)" and "Planned Future (Not Yet Emitted)". Explicit warning that subscribing to planned events produces no deliveries today.
5. **Changelog page** — /docs/changelog (new). Semver policies for SDK/CLI/API, deprecation header spec, v0.1.0 release notes.
6. **Docs index** — Start Here banner, Quickstart card, Changelog card added. CLI card no longer dimmed/Soon.
7. **CLI env var support** — BOUTS_API_KEY + BOUTS_BASE_URL now checked before conf file. @bouts/cli v0.1.1 published to npm.

## Bugs A/B/C Fix (2026-03-30 11:25 AM KL) — Git: 3f7945b
CRITICAL: Bug A (time_limit_seconds) was blocking ALL programmatic session creation.
- Bug A: v1/sessions route was selecting time_limit_seconds (column doesn't exist) → 404 on every session POST. Fixed to time_limit_minutes * 60.
- Bug B: .maybeSingle() on agent lookup in v1/sessions and v1/submissions routes → PGRST116 for multi-agent users. Fixed to .order().limit(1).
- Bug C: Python SDK difficulty_profile Dict[str,float] crashes on string values. Fixed to Dict[str,Any].
- CLI doctor --json added.
These 3 bugs were blocking REST API, TS SDK, Python SDK, CLI, MCP, and Connector simultaneously.

## Platform Status (2026-03-30 11:35 AM KL) — FULLY OPERATIONAL
Latest deploy: git 3f7945b | https://agent-arena-roan.vercel.app
All QA phases passed: Sentinel 10/10, Polaris cleared, Web Submission system complete.
Remediation pass (R1+R2+R3) complete. All P0/P1 issues resolved.
Nick's session reset lost a feedback message — awaiting resend.

## RAI (Remote Agent Invocation) — COMPLETE (2026-03-30 ~17:15 KL)
Git: fcc3100 | Deploy: https://agent-arena-roan.vercel.app

### What was built
- Migration 00038: agents endpoint columns, agent_rai_secrets, rai_invocation_nonces, rai_invocation_log, challenges.remote_invocation_supported — RUN AND CONFIRMED in Supabase
- /api/challenges/[id]/invoke: RAI trigger route — HMAC-SHA256 signed, SSRF-protected, validates response, logs provenance, enqueues into existing judging pipeline (submission_source=remote_invocation)
- /api/v1/agents/[id]/endpoint: CRUD (configure/update/delete). Secret generated on create, never stored plaintext.
- /api/v1/agents/[id]/endpoint/ping: HEAD ping, records last_ping_status
- /api/v1/agents/[id]/endpoint/rotate-secret: new secret, old invalidated immediately
- Workspace page: RAI-first UI — 9 invocation states, timer, confirm gate, endpoint status panel
- Settings → Agent: Endpoint tab (RemoteInvocation component) — configure, ping, rotate, delete, one-time secret reveal
- /docs/remote-invocation: full launch-grade docs (trust model, contract, verification code, comparison table)
- /docs/compete, /docs/quickstart: updated to RAI language
- /docs/web-submission: redirects to /docs/remote-invocation

### Architecture
- submission_source = remote_invocation → same enqueue_judging_job() → same pipeline. No side-channel.
- Provenance: invocation_id, endpoint_host, latency_ms, response_content_hash, request_sent_at, schema_valid
- SSRF: private IPs blocked at config AND invocation time
- Rate limit: 3 invocations / 5 min / user
- Max response: 100KB
- Timeout: 10–120s (user-configurable, default 30s)

## RAI Tightening Pass — COMPLETE (2026-03-30 ~17:55 KL)
Git: 58dd137 | Deploy: https://agent-arena-roan.vercel.app

1. remote_invocation_supported: default=false in code, ALL challenges reset to false in DB, 2 production challenges explicitly enabled (Full-Stack Todo, Debug Payment Flow). Admin PATCH endpoint now accepts this field.
2. Retries: maxRetries=0 hardcoded in invoke route. isRetryable(): only pure TCP failure (no HTTP status code). Everything else terminal.
3. /api/v1/agents/[id]/endpoint/validate: 5-step contract validation (reachability, signing, request_parse, response_schema, response_size). Sends real signed payload, not HEAD ping. Settings shows Validate Contract button with per-step report.
4. One-shot semantics: timeout/invalid_response/content_too_large/platform_error return entry_consumed=false. Only successful submission INSERT + enqueue consumes the entry. Entry status updated to submitted only after submission row confirmed.
5. Provenance visibility in breakdown API: admin=full (invocation_id, endpoint_host, latency, hash, http_status), competitor=host+env+timing+hash (no URL, no errors), public=source label only.
6. Trust language: "Bouts verifies signed invocation, response schema, timing, and content hash. Bouts does not directly observe what runs inside your system."
7. Schema decision: columns stay on agents table for launch. Rationale: one endpoint per agent, config co-located, no join overhead. Dedicated table is a v2 migration if multi-endpoint per agent is needed.
8. Production path: RAI. Sandbox: web-submit still accessible (explicitly labeled). challenge detail page gates workspace button on remote_invocation_supported OR web_submission_supported.

## RAI Aegis Audit Fixes — COMPLETE (2026-03-30 ~19:55 KL)
Git: aa4db7f | Deploy: https://agent-arena-roan.vercel.app

P0 AEG-P0-001: migration 00038 default changed to false (was true — backfill already done in DB)
P1 AEG-P1-001: validateEndpointUrl() wired into PUT /api/v1/agents/[id]/endpoint (registration time, synchronous)
P1 AEG-P1-001: isPrivateIp() wired into POST /api/challenges/[id]/invoke (DNS-level check at invocation time, DNS rebinding protection)
P2: docs signature algorithm corrected — actual format is method\nurl\ntimestamp\nnonce\nbodyHash (not timestamp.invocationId.bodyHash)
P2: docs retry table corrected — zero retries, no "1 retry on connection error"
P2: docs request headers corrected — X-Bouts-Nonce not X-Bouts-Invocation-Id

## RAI Full Remediation Pass — COMPLETE (2026-03-30 ~21:15 KL)
Git: 812b72d | Deploy: https://agent-arena-roan.vercel.app
Migration 00039 written (ALTER default to false, zero max_retries)

R-Fix-1: max_retries=0 enforced throughout; redirect:error in fetch; SSRF active
R-Fix-2: workspace API select fixed; null-safe weight_class/format/time; pre-entry nudge; env badges
R-Fix-3: tab renamed Remote Invocation; max_retries removed from UI; Validate shortcut in workspace
R-Fix-4: signature algo/retry/headers all correct in docs
R-Fix-5: agent columns confirmed as launch schema; dead retry branches removed
R-Fix-6: production (green) / sandbox (amber) environment badges; pre-entry nudge before timer

FINAL STATE:
- Default: false (explicit admin opt-in)
- Retries: zero, hardcoded, no UI
- One-shot: entry consumed only on submission write
- SSRF: validateEndpointUrl at registration, isPrivateIp DNS at invocation, redirect:error in fetch
- Provenance: admin=full, competitor=host+timing+hash, public=source-label-only
- Schema: agent columns (intentional launch decision)
- Production path: RAI only. Sandbox: web-submit accessible.
