# Sentinel Audit Report — Feedback System V2
**Date:** 2026-04-01  
**Auditor:** Sentinel 🛡️  
**Scope:** Full V2 feedback system — end-to-end generation, V2 blocks, trust, UX, access control  
**Method:** Code inspection + DB queries + Playwright browser tests (partial auth) + live API probes  

---

## Executive Verdict

> **NOT LAUNCH-READY**

**One P0. Three P1s. V2 is not shipping.**

The V2 pipeline (`pipeline-v2.ts`) was built correctly and is fully wired — 10 stages, all 6 new analysis blocks, 5 new DB tables, V2-aware rendering mode, calibration context columns. **None of it runs in production.** Both API routes (`/api/feedback/[submissionId]` and `/api/feedback/entry/[entryId]`) import and call V1 `pipeline.ts`, not `pipeline-v2.ts`. Every report in the database has `pipeline_version: "v1"`. Every V2 table is empty. The new blocks (Counterfactual, Judge Disagreement, Change Deltas, Causal Chain, Win Conditions, Preservation) have **never generated output in production**.

The V1 pipeline itself works correctly and the remediated A1–D3 fixes are confirmed real. But V2 as a shipped feature does not exist in runtime — it only exists in code.

---

## P0 Findings

### P0-1 — V2 Pipeline Never Runs: Both API Routes Import V1

**Severity:** P0 (silent misdeploy — V2 shipped as code but never executes)  
**Surface:** Runtime/pipeline  
**Route:** `/api/feedback/[submissionId]/route.ts` + `/api/feedback/entry/[entryId]/route.ts`

**Evidence (code):**
```
// Both routes, line 15:
import { runFeedbackPipeline, loadFeedbackReport } from '@/lib/feedback/pipeline'
//                                                                        ^^^^^^^^ V1
// NOT:
import { runFeedbackPipelineV2, ... } from '@/lib/feedback/pipeline-v2'
```

**Evidence (DB):** All 4 reports in `submission_feedback_reports` have `pipeline_version: "v1"`. All V2 tables (`submission_counterfactual_analysis`, `submission_judge_disagreement`, `submission_change_deltas`, `submission_causal_chains`, `submission_win_condition_analysis`, `submission_preservation_recommendations`) have **0 rows**.

**Impact:** Every V2 block — Counterfactual Coaching, Judge Disagreement, Change Deltas, Causal Chain, Win Conditions, Preservation, Observed Signals mode, Calibration Context — never executes. The `PerformanceBreakdown` component tries to render V2 blocks from `(report as any).v2_counterfactual` etc, but those fields are never populated. All V2 blocks silently don't render. Users get V1 only.

**Fix:** Both route files must import and call `runFeedbackPipelineV2` from `pipeline-v2.ts` instead of `runFeedbackPipeline` from `pipeline.ts`. The `loadFeedbackReport` function in V1 also does not load V2 child tables — it needs to be extended or replaced with a V2-aware loader that joins the 5 new tables and maps them into the report object as `v2_counterfactual`, `v2_disagreement`, `v2_deltas`, `v2_causal`, `v2_win_conditions`, `v2_preservation`.

---

## P1 Findings

### P1-1 — `loadFeedbackReport` Does Not Load V2 Child Tables

**Severity:** P1  
**Surface:** Runtime/pipeline  

Even after fixing P0-1, the V1 `loadFeedbackReport` function will return a report without the V2 fields. It queries 5 child tables (lane_feedback, failure_modes, improvement_priorities, evidence_refs, agent profile) but **not** the 5 new V2 tables. The component reads `(report as any).v2_counterfactual` etc — those will be `undefined` unless the loader is extended. The V2 blocks in the component have null-guards so they silently skip — but even after correct pipeline routing, users will still see no V2 blocks until the loader is also fixed.

**Fix:** Extend `loadFeedbackReport` (or create `loadFeedbackReportV2`) to additionally query:
- `submission_counterfactual_analysis`
- `submission_judge_disagreement`
- `submission_change_deltas`
- `submission_causal_chains`
- `submission_win_condition_analysis`
- `submission_preservation_recommendations`

And map results onto the return object as `v2_counterfactual`, `v2_disagreement`, `v2_deltas`, `v2_causal`, `v2_win_conditions`, `v2_preservation`.

---

### P1-2 — Calibration Context Never Populated

**Severity:** P1  
**Surface:** Feedback quality / calibration context  

The `submission_feedback_reports` table has columns `challenge_calibration_context_json`, `challenge_trait_summary`, `contextual_explanation` — all present in the schema. All 4 reports in DB have `null` for all three. `pipeline-v2.ts` does not include a calibration context stage. No code in any of the V2 modules populates these fields. The `FeedbackReportV2` type defines `calibration_context: CalibrationContext | null` but it is never built.

**Impact:** Challenge difficulty profile, "is this weakness global vs challenge-specific", trait context — none of it ever appears in any report.

**Fix:** Add a calibration extraction stage to `pipeline-v2.ts` that reads challenge traits/difficulty config (if present in DB) and writes to those columns. If challenge calibration data doesn't exist yet, add a clear fallback that suppresses the block rather than silently omitting it.

---

### P1-3 — `pipeline_version` Never Written as "v2"

**Severity:** P1  
**Surface:** Runtime / data integrity  

`pipeline-v2.ts` writes `pipeline_version: 'v1'` is never written by V2... actually it doesn't write it at all — the V2 persist block updates `status`, `rendering_mode`, `confidence_band`, `low_evidence_warnings` but does **not** set `pipeline_version: 'v2'`. This means even after fixing the route import, there will be no way to distinguish V2-generated reports from V1 in the DB or in the response — making debugging, monitoring, and rollback impossible.

**Fix:** Add `pipeline_version: 'v2'` to the final update in `pipeline-v2.ts`.

---

## P2 Findings

### P2-1 — `rendering_mode` / `confidence_band` Set But Not Returned to Client

**Severity:** P2  
**Surface:** Browser UX / feedback quality  

The V2 pipeline correctly sets `rendering_mode` and `confidence_band` on the report row. The `loadFeedbackReport` function has a column whitelist (`FEEDBACK_REPORT_PUBLIC_COLUMNS`) that does **not** include `rendering_mode` or `confidence_band`. These are set in the DB but never returned by the API. The component checks `(report as any).rendering_mode` — it will always be `undefined`. The `V2Blocks.RenderingMode` block and Observed Signals mode can never render.

**Fix:** Add `rendering_mode`, `confidence_band`, `low_evidence_warnings` to `FEEDBACK_REPORT_PUBLIC_COLUMNS` in `pipeline.ts` (or in a V2-aware loader).

---

### P2-2 — V2 Blocks Rendered via `(report as any)` — No Type Safety, Silent Failure

**Severity:** P2  
**Surface:** Browser UX / reliability  

All V2 block rendering uses unsafe type casts: `(report as any).v2_counterfactual`, `(report as any).v2_deltas` etc. TypeScript provides zero protection. The FeedbackReport type does not include V2 fields. If a field name is misspelled or the loader maps it under a slightly different key, blocks silently don't render with no console error.

**Fix:** Extend the `FeedbackReport` type (or create `FeedbackReportV2` extending it) with V2 fields as proper optional typed properties. Remove all `as any` casts from the component.

---

### P2-3 — Tabs Not Visible to Unauthenticated Users on Replay Page

**Severity:** P2  
**Surface:** Browser UX  

The replay page `/replays/[entryId]` renders the tab interface (Performance Breakdown / Score Breakdown) conditionally — it only appears if `replay.judge_outputs` is populated or `replay.composite_score` is not null. The replay API returns this data only when the user is authenticated as owner or admin. Unauthenticated visitors see no breakdown tabs at all — just the submission code and a raw `6/100` score with no explanation.

**Impact:** Public users cannot see even basic score breakdown for public challenge entries. The replay experience is degraded for the platform's public-facing surface.

**Note:** This may be intentional (breakdown is a logged-in feature). If so, it should be explicitly stated on the page ("Log in to see full breakdown"). Currently the page just silently omits all context.

---

### P2-4 — `loadFeedbackReport` Loads Longitudinal from `agent_performance_profiles` But V2 Doesn't Update It With V2 Signals

**Severity:** P2  
**Surface:** Longitudinal intelligence  

`pipeline-v2.ts` calls `updateLongitudinalProfile` (V1 function) in Stage 5 but never updates it with V2-specific signals (change deltas, new failure modes, recovered weaknesses). The longitudinal profile for an agent will accumulate V1 signals but V2's richer change tracking is never persisted back into the rolling profile.

---

## P3 Findings

### P3-1 — `/results` Page: 41.7% Win Rate on 5/12 Completed Entries (Display)

Scoring of "win" in win rate widget not clearly defined — 93.6 score with no placement shown doesn't indicate if it "won." Minor trust/clarity issue.

### P3-2 — Replay Page Mobile: No Tab Interface

Confirmed by screenshot: mobile (390px) replay page shows no tabs at all. The tab switcher renders in the right column of a 12-col grid — at mobile width that column stacks but appears the tabbed section is not clearly accessible. Visual inspection suggests the tab section exists below a lot of content. Not a hard break but tab discoverability is poor on mobile.

### P3-3 — Challenge Results Page Timeout

`/challenges/[id]` (spectate route) timed out at 20s in multiple browser test attempts. This may indicate a slow Supabase query or missing data for certain challenge IDs. Not blocking but worth flagging.

---

## What Was Actually Verified (V1 Baseline)

These fixes from the A1–D3 remediation are **confirmed working** in the live system:

| Fix | Status | Evidence |
|-----|--------|----------|
| A1: UNIQUE constraint on submission_id | ✅ CONFIRMED | No duplicate rows; upsert works |
| A2: Synchronous pipeline (no fire-and-forget) | ✅ CONFIRMED | Both routes use `await runFeedbackPipeline()` |
| A3: No spinner dead-end (AbortController) | ✅ CONFIRMED | All terminal states named; no `.animate-spin` at rest |
| A4: Default tab = classic | ✅ CONFIRMED | `useState<'premium' | 'classic'>('classic')` in source |
| B1: No fabricated comparisons | ✅ CONFIRMED | `competitive_comparison: null` in all reports (< 5 entries) |
| B2: No infra field leakage (public) | ✅ CONFIRMED | API returns 403 for unauthenticated; no model_id/latency in response |
| B3: short_rationale scoped to owner/admin | ✅ CONFIRMED | Column excluded from public loader whitelist |
| D2: evidence_density hidden from UI | ✅ CONFIRMED | Not present in page text; ConfidenceBadge used instead |
| D2: Percentile human-readable | ✅ CONFIRMED | "top X%" format in code; no raw "p78" found in UI |
| D3: MIN_ENTRIES=5 gate | ✅ CONFIRMED | competitive_comparison suppressed on all current reports |

V1 pipeline generates successfully. API access control works correctly (403 for unauth). No infra leaks. No mobile overflow.

---

## Explicit Answers

**Does V2 actually generate and load reliably?**  
No. V2 never runs. Both API routes call V1 exclusively. Zero V2 DB rows exist.

**Does it feel materially better than standard model commentary?**  
Cannot evaluate — V2 has never generated output in production. V1 reports are generating and completing in 45–54s. V1 quality is real but untested in this audit (no authenticated browser session with full V1 report rendered was captured due to Playwright/Supabase auth network constraint).

**Are the new V2 blocks genuinely useful or mostly decorative?**  
The code quality of the V2 modules is solid — counterfactuals use empirical DB data + confidence ranges, causal chains use a defined graph structure, change deltas correctly require ≥2 prior entries. The logic looks defensible. But it has never run, so we cannot verify runtime output quality.

**Is any part of it overstating certainty?**  
V1 confidence and ambiguity handling is correct. V2 trust mechanisms (MIN_ENTRIES_FOR_COMPARISON=5, evidence range bands) are in place in code. Cannot verify in production since V2 has never run.

**Is anything still misleading, generic, or easy to game?**  
V1: No confirmed fabrication — competitive comparisons are correctly suppressed below 5 entries. Needs more entries to fully stress-test the comparison block quality.

**Is it safe to ship as a flagship trust feature?**  
No. V2 doesn't run. Fix P0-1 + P1-1 first, then re-audit on a submission with the V2 pipeline actually generating.

---

## Fix Priority Order

```
1. [P0] Both routes: import runFeedbackPipelineV2 from pipeline-v2, not pipeline v1
2. [P1] Extend loadFeedbackReport to join + return all 5 V2 child tables
3. [P1] Add pipeline_version: 'v2' to pipeline-v2.ts final update
4. [P1] Add calibration context stage to pipeline-v2.ts (or explicit null suppression)
5. [P2] Add rendering_mode / confidence_band / low_evidence_warnings to public column whitelist
6. [P2] Extend FeedbackReport type with V2 optional fields; remove all (report as any) casts
7. [P3] Investigate /challenges/[id] timeout
8. [P3] Mobile tab discoverability on replay page
```

---

## Coverage Summary

| Area | Coverage | Notes |
|------|----------|-------|
| API routes (code) | ✅ Full | Both routes read |
| Pipeline V1 (code) | ✅ Full | Read completely |
| Pipeline V2 (code) | ✅ Full | Read completely; confirmed never called |
| V2 module implementations | ✅ Full | All 6 modules read; logic defensible |
| DB table existence | ✅ Full | All 7 tables confirmed exist |
| DB content | ✅ Full | 4 reports, all v1; V2 tables all empty |
| V2 schema on main table | ✅ Full | V2 columns exist but all null |
| Access control (API) | ✅ Full | 403 for unauth confirmed |
| Infra leakage (API) | ✅ Full | None detected |
| Browser (unauthenticated) | ✅ Full | Screenshots, trust checks confirmed |
| Browser (authenticated) | ⚠️ Partial | Session injection; tabs not rendered (Next.js SSR auth gate) |
| V2 blocks rendered in UI | ❌ Not possible | V2 has never generated output |
| Generation timing (V2) | ❌ Not tested | V2 never triggered |
| Longitudinal V2 behavior | ❌ Not tested | No V2 data exists |
| Calibration context | ❌ Not tested | Never populated |

---

*Report written: 2026-04-01 | Sentinel 🛡️*
