# Forge Handoff

## Last Updated
2026-04-01 ~02:19 KL

## Latest Deploy
Git: dawn-prairie | https://agent-arena-roan.vercel.app

## Status: COMPLETE — Calibration Pipeline v2 live. Migration 00048 pending Nick.

---

## ⚠️ IMMEDIATE ACTION REQUIRED (Nick)

### Apply Migration 00048 in Supabase SQL Editor

```sql
CREATE TABLE IF NOT EXISTS challenge_calibration_dossiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  dossier jsonb NOT NULL DEFAULT '{}'::jsonb,
  ai_analysis jsonb,
  recommendation text CHECK (recommendation IN ('auto_pass','needs_light_review','needs_deep_review','quarantine')),
  confidence text CHECK (confidence IN ('high','medium','low')),
  recommended_profile jsonb,
  recommended_session_minutes int,
  recommended_window_hours int,
  reviewer_status text NOT NULL DEFAULT 'unreviewed' CHECK (reviewer_status IN ('unreviewed','benchmarked','recommended','approved','adjusted','quarantined')),
  reviewed_by uuid REFERENCES profiles(id),
  reviewed_at timestamptz,
  reviewer_notes text,
  final_profile jsonb,
  generated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_calibration_dossiers_challenge ON challenge_calibration_dossiers(challenge_id);
ALTER TABLE challenge_calibration_dossiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY calibration_dossiers_admin ON challenge_calibration_dossiers FOR ALL TO authenticated USING (public.is_admin());
ALTER TABLE challenges ADD COLUMN IF NOT EXISTS calibration_confidence text CHECK (calibration_confidence IN ('high','medium','low'));
ALTER TABLE challenges ADD COLUMN IF NOT EXISTS calibration_recommendation text CHECK (calibration_recommendation IN ('auto_pass','needs_light_review','needs_deep_review','quarantine'));
ALTER TABLE challenges ADD COLUMN IF NOT EXISTS calibration_reviewer_status text NOT NULL DEFAULT 'unreviewed' CHECK (calibration_reviewer_status IN ('unreviewed','benchmarked','recommended','approved','adjusted','quarantined'));
CREATE INDEX IF NOT EXISTS idx_challenges_reviewer_status ON challenges(calibration_reviewer_status);
```

Then go to https://agent-arena-roan.vercel.app/admin/calibration and click **"Analyze All Unreviewed"**.

---

## Session Summary — 2026-04-01 (00:09–02:19 KL)

### Admin Mobile — Calibration Section (00:09–00:51 KL)
- Made admin challenges page fully mobile-responsive
- Filter tabs by calibration status
- Challenge preview panel (expandable on tap)
- Difficulty sliders work on mobile
- Backfill migration 00046: all challenges got valid calibration_status values
- Discovered calibration_status enum mismatch (uncalibrated→draft, calibrated→passed) — fixed
- Commits: 7075fbb → fd2d0d9 → faint-river

### Calibration Pipeline v2 (00:51–02:11 KL)
Complete system built replacing manual slider workflow.

**New files:**
- `src/lib/calibration/challenge-analyzer.ts` — LLM prompt analyzer
- `src/lib/calibration/dossier.ts` — dossier generator + recommendation engine
- `src/app/api/admin/calibration/pipeline/route.ts` — unified pipeline endpoint
- `src/app/api/admin/calibration/run-batch/route.ts` — batch trigger
- `src/app/api/admin/calibration/auto-trigger/route.ts` — intake auto-trigger
- `src/app/api/admin/calibration/queue/route.ts` — reviewer queue data API
- `src/app/admin/calibration/page.tsx` — reviewer queue UI (mobile-first)
- `supabase/migrations/00048_calibration_dossiers.sql` — schema

**Modified files:**
- `src/app/api/challenges/intake/route.ts` — fires auto-trigger on new challenge
- `src/app/admin/AdminDashboardClient.tsx` — adds "Open Reviewer Queue →" link

**Operating model:**
1. Gauntlet submits challenge → intake fires → auto-trigger runs Stage 1 → dossier written
2. Nick sees queue at `/admin/calibration` — only reviews exceptions
3. Approve = applies recommended difficulty_profile, sets calibration_status=passed
4. Quarantine = blocks challenge
5. Stage 2 (benchmark) available on demand via "Run Benchmark" button
6. Stage 3 (live recalibration) already runs via quality enforcement cron

---

## Active Project State

- **Live URL**: https://agent-arena-roan.vercel.app ✅
- **Active challenges**: "Full-Stack Todo App", "Debug the Payment Flow" (2 active)
- **DB**: Supabase project gojpbtlajzigvyfkghrg
- **Git branch**: master (107 commits ahead of origin/main)
- **Latest migrations applied**: 00045 (feedback hardening)
- **Pending migrations**: 00046 (applied ✅), 00047 (defaults — optional), 00048 (⚠️ PENDING)

## Existing Calibration Architecture (do not break)
- `src/lib/calibration/types.ts` — shared types (CalibrationTier, runners, thresholds)
- `src/lib/calibration/synthetic-runner.ts` — fast tier simulation (no LLM)
- `src/lib/calibration/real-llm-runner.ts` — real LLM runs (4 tiers via OpenRouter)
- `src/lib/calibration/orchestrator.ts` — routes by CALIBRATION_POLICY, caches, persists
- `src/app/api/admin/calibration/route.ts` — original endpoint (run_synthetic / run_full / mutate)
- `challenge_calibration_results` table — stores synthetic + real LLM benchmark results

## Deferred Items
- Run initial calibration dossiers for Full-Stack Todo App + Debug Payment Flow (blocked by migration 00048)
- After 00048 applied: hit "Analyze All Unreviewed" to backfill all 27 uncalibrated challenges
- Stage 2 (real LLM benchmark) can be triggered per-challenge via "Run Benchmark" button in reviewer queue
