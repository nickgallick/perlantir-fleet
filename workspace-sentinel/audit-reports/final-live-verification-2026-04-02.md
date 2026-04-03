# Sentinel — Final Live Verification Pass
**Date:** 2026-04-02  
**Systems:** Feedback V2 + Challenge Calibration  
**Method:** Git log, code diff, DB direct query, live API probe  
**Commit verified:** d831510 (combined remediation)

---

## Executive Verdict

> **READY WITH MINOR FOLLOW-UPS**

Both systems are live, generating real data, and behaving honestly. No P0s. Three P1s — none are blockers to using the systems operationally, but all three should be fixed before heavy reliance.

---

## P0 Findings

**None.**

---

## Section A — Feedback V2

### Status: LIVE ✅

**Confirmed in production:**
- Both `/api/feedback/[submissionId]` and `/api/feedback/entry/[entryId]` import and call `runFeedbackPipelineV2` from `pipeline-v2.ts`
- Both routes load via `loadFeedbackReportV2` from the new `load-report-v2.ts` loader
- All 4 existing reports show `pipeline_version: v2`
- `rendering_mode`, `confidence_band`, `low_evidence_warnings` present and populated on all reports
- 3 reports: `confidence_band: high`, `rendering_mode: full`; 1 report: `confidence_band: medium`
- No infra field leakage confirmed (generated_by_model, generation_ms, error_message, model_id — absent from all reports)
- `humanizeDriver()` applied — primary/secondary loss drivers reach the client humanized (but raw values still in DB; see P1-1)

---

### P1-1 — `root_failure_mode` in Causal Chain block not humanized in UI

**Severity:** P1  
**Surface:** Feedback V2 browser UX / trust  

The `load-report-v2.ts` loader correctly applies `humanizeDriver()` to `primary_loss_driver` and `secondary_loss_driver` before returning the API response. But the V2Blocks component directly renders `data.root_failure_mode` from the causal chain:

```tsx
// performance-breakdown-v2-blocks.tsx line 222:
<div className="text-base font-bold text-red-400 capitalize">
  {data.root_failure_mode.replace(/_/g, ' ')}
</div>
```

This renders "validation omission" via `.replace(/_/g,' ')` rather than the DRIVER_LABELS map ("Validation Gap"). The `replace` approach is inconsistent with the rest of the system and will render any new failure mode codes as raw lowercase words. All 4 causal chain rows have `root_failure_mode: 'validation_omission'` — renders as "validation omission" in the UI.

**Fix:** Apply `humanizeDriver()` or `FAILURE_MODE_LABELS` lookup in the V2Blocks component for `root_failure_mode`.

---

### P1-2 — `total_score_damage: 0.0` on all causal chain rows

**Severity:** P1  
**Surface:** Feedback V2 / calibration quality  

All 4 causal chain rows in production have `total_score_damage: 0.0`. The damage attribution in `v2-causal-chains.ts` computes damage via `severity_weight` mapped from `primary_failure?.severity` — but the data reaching the function at runtime has either no severity value or the computation falls through. The causal chain block still renders with narrative content (the causal_narrative is real and specific), but the damage number shown to users is always 0.

**Impact:** The "X points of score damage attributed to this root cause" display is misleading — it shows 0 for every submission. This is a fake precision failure in the other direction: understating damage rather than overstating it.

**Fix:** Verify `primary_failure?.severity` is populated when `analyzeCausalChains` is called. If lane scores are missing at pipeline time, compute damage from the composite score differential instead.

---

### V2 Block Suppression — Verified Correct (not bugs)

The following V2 blocks have 0 rows in production. All suppressions are **legitimate** given current data state:

| Block | Rows | Why Suppressed | Legitimate? |
|---|---|---|---|
| Judge Disagreement | 0 | No `judge_outputs` linked to these entries (older entries used legacy `judge_scores` table) | ✅ Yes |
| Change Deltas | 0 | All 4 agents have < 2 prior bouts — `analyzeChangeDeltas` correctly returns null | ✅ Yes |
| Win Conditions | 0 | < 5 field entries per challenge — MIN_ENTRIES gate fires, block suppressed | ✅ Yes |
| Preservation | 0 | No preservation recs generated because diagnosis failure modes required — returns empty array | ✅ Yes |

These blocks will populate as the platform accumulates more submissions and bouts. Suppression is clean and honest — no hollow empty blocks render.

**Judge Disagreement edge case worth noting:** `analyzeJudgeDisagreement()` returns a stub object when `lane_signals.length === 0` rather than returning `null`. The pipeline then tries to persist this stub. The stub has `agreement_summary: 'Insufficient judge outputs to analyze alignment.'` and `confidence: 'low'` — which is honest, but it currently doesn't get persisted because the pipeline checks `if (v2_results.disagreement)` which is truthy even for the stub. This means it's being persisted as a row with low-confidence stub data, but the DB shows 0 rows so either the condition check is filtering it or the upsert is failing silently. The net UI effect is correct (block doesn't render) but worth verifying the code path.

---

### A3 — Suppression Honesty ✅

Confirmed:
- No fabricated comparisons — competitive comparison suppressed below 5 entries (D3 fix holding)
- No raw `p78` percentile notation — human-readable "top X%" format in code
- `evidence_density` not exposed as raw number
- `low_evidence_warnings: []` on all reports (consistent with `confidence_band: high/medium`)
- `observe_signals` mode not active on any current report — all in `full` mode

---

### A4 — Trust Correctness ✅

Confirmed:
- No snake_case in `primary_loss_driver` / `secondary_loss_driver` at API level (humanizeDriver applied)
- Counterfactual impact shown as **ranges** (e.g., 6–11–17 points), not fake precision single numbers
- Methodology labeled: all 4 counterfactual rows have `methodology: 'symptom_severity'` (empirical field comparison suppressed correctly — no field data available)
- `field_sample_count: null` on counterfactual rows — not fabricating a sample count
- Infra fields absent from API responses (confirmed via direct API probe)

**One gap:** `root_failure_mode` in causal chain arrives as raw snake_case at the component level (P1-1 above).

---

### A5 — Results / Replay UX ✅

Confirmed in code:
- Classic tab default confirmed (`useState<'premium'|'classic'>('classic')`)
- No spinner dead-ends — all terminal states (failed, not_available, error) redirect to classic tab with message
- Legacy `/10` scale explicitly labeled "Legacy scoring · /10 scale" in Judge Evaluation panel
- Phase 1+ composite `/100` scale labeled throughout
- Provisional placement logic confirmed correct (checks both `challenge.status === 'active'` AND `ends_at > Date.now()`)

---

## Section B — Challenge Calibration

### Status: LIVE ✅

**Confirmed in production:**
- 23 dossiers total (up from 15 in prior audit)
- 3 approved, 1 quarantined, 19 recommended — reviewer flow has been exercised
- `calibration_recommendation` preserved on approve (B3 fix working — approved challenges keep original AI recommendation label)
- Predicted solve rate labeled with tooltip: "AI-predicted solve rate (estimated, not empirically measured)" ✅
- `reviewer_notes` required at API level for adjust — returns 400 if absent or < 5 chars ✅
- New dossiers (post-d831510) have `decision` key in JSONB ✅

---

### P1-3 — `rules_fired: []` in All Dossier Decision Objects

**Severity:** P1  
**Surface:** Calibration reviewer workflow  

The new dossiers (generated after d831510) have `decision` in the JSONB with correct keys: `rules_fired`, `evidence_used`, `blocking_rules`, `recommendation`, `override_possible`. But `rules_fired` is empty array (`[]`) on every dossier checked.

**Evidence:**
```json
"decision": {
  "rules_fired": [],
  "evidence_used": ["ai_analysis"],
  "blocking_rules": [],
  "recommendation": "needs_deep_review",
  "override_possible": true
}
```

**Root cause:** `computeCalibrationDecision()` in `decision-policy.ts` pushes rules into the `rules` array and returns it. The dossier builder calls it correctly. The serialization to JSONB appears to work (keys are present). Most likely the `buildDossier()` → `computeCalibrationDecision()` return value is being serialized but `rules_fired` specifically is either being stripped by a Zod/type transform or the decision object reference is being modified before persist. Given `blocking_rules: []` and `recommendation: 'needs_deep_review'` are correct (deep_review requires a gate to fire), the decision _logic_ is right — only the audit trail array is empty.

**Impact:** Every dossier in the reviewer queue shows "0 rules in trace." The `DecisionRulesSection` component renders the summary banner (which reads correctly from `blocking_rules`) but the expandable rule list shows nothing. The reviewer sees the outcome but not the evidence chain. This was the headline feature of the evidence-based reviewer UI.

**Fix:** Add a logging breakpoint or console trace in `computeCalibrationDecision` to confirm `rules` array is populated before return. Check if TypeScript/tRPC/Zod is stripping it. Alternatively, inspect whether the `...dossier` spread in the upsert call is inadvertently overwriting the decision field with a version where rules_fired was empty.

---

### P2-1 — Approve Action on Previously-Unanalyzed Challenges Loses AI Data

**Severity:** P2  
**Surface:** Calibration reviewer workflow / evidence integrity  

The B2 fix correctly preserves existing dossier JSONB when approving a challenge that already has a dossier. But when approve fires on a challenge with **no prior dossier** (the `else` branch), it creates a new row with only:
```json
{ "review_action": "approved", "review_timestamp": "..." }
```

This happened in production: challenge `4d4c621a` ("Debug the Broken Event Emitter") was approved with no prior dossier — its dossier row now has no AI analysis, no recommendation, no decision trace. The challenge is `calibration_status: passed` but there is zero evidence record of why it was approved.

**Impact:** The audit trail for this approval is empty. If someone asks "why was this challenge approved?", the only answer is the `reviewer_notes` field ("Polish live verification test") — no supporting analysis.

**Fix:** The approve action should always run Stage 1 analysis first if no dossier exists, or at minimum reject approval for un-analyzed challenges with an error requiring analysis first.

---

### P2-2 — Stuck-Calibrating Watchdog Targets Wrong Column

**Severity:** P2  
**Surface:** Calibration pipeline state  

The watchdog in the queue GET handler targets `calibration_reviewer_status = 'calibrating'` but the stuck column is `calibration_status = 'calibrating'` — two different columns.

```ts
// queue/route.ts line 40-41 — WRONG COLUMN:
.update({ calibration_reviewer_status: 'unreviewed' })
.eq('calibration_reviewer_status', 'calibrating')
```

**Evidence:** 5 challenges confirmed stuck with `calibration_status: 'calibrating'` including 3 sandbox challenges (updated 2026-03-31) and 2 production challenges. The watchdog has never fired for any of them because it's watching the wrong field.

**Fix:** Change watchdog to target `calibration_status = 'calibrating'` and reset to `calibration_status = 'draft'` (not `'unreviewed'`).

---

### P2-3 — Approved Quarantine-Recommended Challenge: Contradictory Badge Display

**Severity:** P2  
**Surface:** Calibration admin UX  

Challenge `7274d2fc` ("Build a URL Shortener in 20 Minutes") has:
- `calibration_recommendation: 'quarantine'` (AI said quarantine it)
- `calibration_reviewer_status: 'approved'` (reviewer approved it)
- `calibration_status: 'passed'`

The admin queue renders both badges simultaneously: a red "Quarantine" recommendation badge next to a green "Approved" status badge. This is confusing — it looks like the system is contradicting itself. A reviewer scanning the queue would not immediately understand this means "human overrode the AI quarantine recommendation."

**B3 fix context:** The B3 fix intentionally preserves the original AI recommendation on approve. This is architecturally correct (the AI said X, the human decided Y — both facts are preserved). But the UI doesn't explain this. The recommendation badge should either be relabeled "AI: Quarantine" when the reviewer has overridden it, or the override should be visually differentiated from a non-overriding approval.

---

### P3 Findings — Calibration

**P3-1: 5 challenges stuck in `calibration_status: calibrating`**
- 3 sandbox challenges (probably harmless — sandbox excluded from queue)
- "Live E2E Test: Fix the Rate Limiter" — quarantine dossier exists, `calibration_status` should be `quarantined` not `calibrating`
- "Debug: Authentication Regression" — has dossier, needs status reconciliation
- Manual fix: `UPDATE challenges SET calibration_status='draft' WHERE calibration_status='calibrating' AND id IN (...)` for the two production ones

**P3-2: Admin action audit trail empty**
`challenge_admin_actions` table has 0 rows. Approve/quarantine/adjust actions don't log to this table. No audit trail of who approved what when (only `reviewed_at` timestamp and `reviewer_notes` string on the dossier row).

---

## Section C — Regression Check

All prior fixes confirmed holding:

| Fix | Status |
|-----|--------|
| A1: No spinner dead-ends (A3 fix) | ✅ Confirmed — all terminal states named |
| A2: Default tab = classic (A4 fix) | ✅ Confirmed in source |
| A3: No fabricated comparisons (B1/D3 fix) | ✅ Confirmed — competitive_comparison null, block suppressed |
| A4: No infra field leakage | ✅ Confirmed — API probe clean |
| A5: Percentile human-readable (D2 fix) | ✅ Confirmed |
| A6: Access control (403 unauth) | ✅ Confirmed |
| A7: /10 vs /100 scale labels | ✅ Confirmed — legacy panel labeled "Legacy scoring · /10 scale" |
| A8: Provisional placement logic | ✅ Confirmed — dual gate (status=active AND ends_at future) |
| B1: Calibration prompt-length fix | ✅ Auto-trigger passes real `prompt.length` |
| B2: Dossier preserve on review actions | ✅ Confirmed for UPDATE path (existing dossier); INSERT path (P2-1 above) |
| B3: calibration_recommendation preserved on approve | ✅ Confirmed |

---

## Explicit Answers

**Is Feedback V2 truly live in runtime now?**  
Yes. Both routes call `runFeedbackPipelineV2`. All reports are `pipeline_version: v2`. V2 child tables have real rows.

**Are any V2 blocks still decorative or dead?**  
Counterfactual and Causal Chain are live and generating real, specific content. Judge Disagreement, Change Deltas, Win Conditions, Preservation are correctly suppressed due to insufficient data — not dead, waiting for data. The only defect is `root_failure_mode` renders as lowercase words instead of the human label (P1-1), and `total_score_damage: 0.0` (P1-2). No block is decorative or fake.

**Is Calibration now trustworthy enough for operator use?**  
Yes for daily use. The AI analysis is real and specific. Reviewer actions (approve/quarantine) are live and confirmed working in production. The decision outcome is correct. The weakness is the evidence trail (rules_fired empty) which reduces confidence in the "why" without removing the "what."

**Are reviewer actions preserving evidence correctly?**  
Partially. UPDATE path (existing dossier) preserves AI analysis correctly. INSERT path (no prior dossier) creates an empty evidence record — this is the P2-1 gap. Quarantine action confirmed working with decision and notes preserved.

**Is anything still misleading, overstated, or not fully proven?**  
- `total_score_damage: 0.0` on causal chains — understate rather than overstate, but inaccurate
- `root_failure_mode` as lowercase words in UI (P1-1) — minor trust friction
- `rules_fired: []` means reviewer cannot verify the decision logic chain (P1-3)
- Quarantine + Approved badge pair on override cases needs visual disambiguation (P2-3)

---

## Fix Priority Order

```
1. [P1-3] rules_fired empty in dossier JSONB — decision trace feature non-functional
2. [P1-1] root_failure_mode in V2Blocks — apply humanizeDriver() or FAILURE_MODE_LABELS
3. [P1-2] total_score_damage = 0.0 on all causal chains — fix damage attribution
4. [P2-2] Watchdog targeting wrong column (calibration_reviewer_status vs calibration_status)
5. [P2-1] Approve without prior dossier creates empty evidence record
6. [P2-3] UI: distinguish "AI quarantine, human approved" from normal approved state
7. [P3-1] Manually reset 2 stuck production challenges (manual DB fix, 1 line)
8. [P3-2] Add action logging to challenge_admin_actions on review events
```

---

*Report written: 2026-04-02 | Sentinel 🛡️*
