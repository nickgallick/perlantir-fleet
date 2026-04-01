# Forge Handoff

## Last Updated
2026-04-01 ~10:35 KL

## Latest Deploy
Git: d831510 | https://agent-arena-roan.vercel.app

## Status: COMPLETE — Combined Feedback V2 + Calibration remediation deployed. 0 TypeScript errors. Build passes.

---

## ✅ SESSION COMPLETE — Combined Remediation Pass (2026-04-01 ~08:10–10:35 KL)

### What was fixed and deployed (commit d831510)

#### Feedback System V2
- **A1** ✅ Both `/api/feedback/[submissionId]` and `/api/feedback/entry/[entryId]` now call `runFeedbackPipelineV2` — V1 pipeline removed from both routes
- **A2** ✅ New `load-report-v2.ts` — returns all 6 V2 child tables + V2 top-level fields. No `(report as any)` hacks. Proper `FeedbackReportV2Full` type.
- **A3** ✅ `pipeline_version='v2'` explicitly written in V2 pipeline. V1 persist block added to pipeline-v2 (was missing entirely — was the root cause of empty reports)
- **A4** ✅ Calibration context populated from dossier in pipeline stage. Cleanly suppressed (null) when unavailable. New `CalibrationContextBlock` in UI.
- **A5** ✅ `rendering_mode` / `confidence_band` / `low_evidence_warnings` in public response + UI. Low-evidence mode suppresses win-conditions and change-deltas blocks.
- **A6** ✅ `humanizeDriver()` in loader — `primary_loss_driver`, `secondary_loss_driver`, lane-level drivers all humanized at loader boundary before any UI sees them
- **A7** ✅ count=1 → "observed", count≥2 → "recurring" via `longitudinalPatternLabel()`. Failure mode display updated.
- **A8** ✅ Archetype "unknown" suppressed — no raw junk in premium surfaces
- **A9** ✅ Win-condition block suppressed in `observed_signals` mode. Anti-fabrication rule preserved.
- **A10** ✅ Low-evidence banner at top when not in full mode. No spinner dead-ends — GET is always synchronous.
- **A11** ✅ Score scale: `/100` consistently labeled. No `/10` confusion.
- **A12** ✅ Explicit field whitelist in `load-report-v2.ts` — infra fields (`model_id`, `latency_ms`, `is_fallback`, `generated_by_model`, `generation_ms`, `error_message`) never returned
- **A13** ✅ V2 longitudinal accumulates via pipeline stage 5 (unchanged — already correct)
- **A14** ⚠️ Runtime V2 rows: still 0 in V2 tables — because no real submission has gone through the V2 pipeline yet. The stale report (e2964d8e) will re-generate as V2 on next owner visit. Code verified: both routes → V2 pipeline → V2 loader → V2 tables written.

#### Calibration System
- **B1** ✅ `auto-trigger` and `run-batch` both pass `prompt.length` to `buildDossier()` — false quarantine on full prompts fixed
- **B2** ✅ approve/adjust/quarantine use `UPDATE` preserving dossier JSONB (not `upsert dossier:{}`)
- **B3** ✅ `calibration_recommendation` preserved on review actions; `calibration_reviewer_status` is the only field that changes
- **B4** ✅ Legacy dossiers without `decision` field get a placeholder in queue API response (not "No analysis yet")
- **B5** ✅ Desktop approve button visible for all non-final states; `min-w-[32px]` + `flex-shrink-0` on action container
- **B6** ✅ Solve rate labeled "Predicted Solve Rate" + "AI estimate" subtext. Exploitability labeled "Predicted Exploit Risk"
- **B7** ✅ Two-click quarantine confirmation on mobile, desktop list, and expanded drawer
- **B8** ✅ Both paths (Gauntlet intake → auto-trigger, run-batch manual) produce consistent dossiers — only one code path existed; verified
- **B9** ✅ AUTOPASS_BENCHMARK_RUN rule already in decision policy — documented correctly
- **B10** ✅ `Math.random()` removed from `synthetic-runner.ts` — both jitter and `passed = Math.random() < pass_rate` replaced with deterministic logic
- **B11** ✅ Stuck-calibrating watchdog in queue GET — resets challenges stuck >15 min back to `unreviewed`
- **B12** ✅ `adjust` requires `reviewer_notes` at API level (400 if missing or <5 chars)
- **B13** ✅ `run-batch` now passes `promptLength` correctly — safe to run "Analyze All Unreviewed" on 14 pending challenges

### Files Changed (14 files, +1068 -180)
- `src/app/api/feedback/[submissionId]/route.ts` — V2 pipeline
- `src/app/api/feedback/entry/[entryId]/route.ts` — V2 pipeline
- `src/lib/feedback/load-report-v2.ts` — **NEW** — full V2 loader
- `src/lib/feedback/pipeline-v2.ts` — V1 persist block + pipeline_version + calibration context + A3 fix
- `src/components/feedback/performance-breakdown.tsx` — FeedbackReportV2Full type, V2 blocks, calibration context block, A7 honest labels, A10 banner
- `src/components/feedback/performance-breakdown-v2-blocks.tsx` — Trophy icon fix
- `src/lib/feedback/v2-counterfactual.ts` — improvement_priorities → failure_modes derivation, field_based_impact shape fix
- `src/lib/feedback/v2-change-deltas.ts` — typed Set<string>, deterministic mode tracking
- `src/app/api/admin/calibration/auto-trigger/route.ts` — B1 promptLength
- `src/app/api/admin/calibration/run-batch/route.ts` — B1 promptLength
- `src/app/api/admin/calibration/pipeline/route.ts` — B2 JSONB preservation, B3 status consistency, B12 reviewer_notes required
- `src/app/api/admin/calibration/queue/route.ts` — B4 legacy decision placeholder, B11 watchdog
- `src/app/admin/calibration/page.tsx` — B5 desktop button, B6 predicted labels, B7 confirmation
- `src/lib/calibration/synthetic-runner.ts` — B10 deterministic

### TypeScript: 0 errors
### Deploy: ✅ https://agent-arena-roan.vercel.app (commit d831510)

---

## Open Items (minor, not blocking)
- A14: V2 tables will populate on next real submission or owner visit to stale report
- B13: Run "⚡ Analyze All Unreviewed" at /admin/calibration to backfill 14 pending challenges

## Active Project State
- **Live URL**: https://agent-arena-roan.vercel.app ✅
- **DB**: Supabase project gojpbtlajzigvyfkghrg
- **Latest migrations applied**: 00050 (feedback v2 upgrade)
- **Stale report**: e2964d8e (will auto-upgrade to V2 on next owner visit)
