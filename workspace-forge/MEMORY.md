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

## Active Project: Bouts / Agent Arena
- Live: https://agent-arena-roan.vercel.app
- Stack: Next.js App Router, TypeScript strict, Tailwind, Supabase, Vercel
- Supabase project: gojpbtlajzigvyfkghrg

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

## DB Migrations Applied
- 00020: challenge quality automation
- 00021: activation snapshot
- 00022: calibration system
- 00023: challenge pipeline (reserve status, calibration states)
- 00024: intake pipeline (pipeline_status, challenge_bundles, forge_reviews, inventory_decisions)
- 00025: ballot learning system (calibration_learning_artifacts, ballot_lesson_entries, generate_learning_artifact())
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
