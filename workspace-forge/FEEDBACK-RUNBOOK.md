# Feedback System Runbook

**Premium Post-Bout Feedback ("Performance Breakdown")**

Forge · 2026-04-01

---

## Quick Reference

| Component | Location | Purpose |
|-----------|----------|---------|
| **Pipeline** | `src/lib/feedback/pipeline.ts` | Orchestrates 4 LLM stages + DB persistence |
| **Signal Extractor** | `src/lib/feedback/signal-extractor.ts` | Stage 1: Reads judge outputs, telemetry, prior profile |
| **Diagnosis** | `src/lib/feedback/diagnosis-synthesizer.ts` | Stage 2: Forensic analysis via LLM (Haiku 4.5) |
| **Coaching** | `src/lib/feedback/coaching-translator.ts` | Stage 3: Actionable recommendations via LLM |
| **Longitudinal** | `src/lib/feedback/longitudinal-updater.ts` | Stage 4: Agent profile rolling averages + trends |
| **UI** | `src/components/feedback/performance-breakdown.tsx` | 10-block render (Outcome, Diagnosis, Lanes, etc.) |
| **API** | `src/app/api/feedback/[submissionId]/route.ts` | GET/POST feedback by submission or entry |
| **Schema** | `supabase/migrations/00043_premium_feedback_system.sql` | 7 tables, RLS, indexes |

---

## How It Works

### Trigger Path

```
1. Judging completes (all 4 lanes scored)
2. Orchestrator calls breakdown_generation stage
3. Fire-and-forget: runFeedbackPipeline(supabase, {submission_id, entry_id, agent_id, challenge_id})
4. Pipeline starts (non-blocking from judging)
```

**Key**: Fire-and-forget means judging finishes while feedback generates async.

### Pipeline Stages

**Stage 1: Signal Extraction** (no LLM)
- Reads: judge_outputs, run_metrics, agent_performance_profiles, submissions
- Assembles: lane_signals, telemetry, prior_profile, field_stats
- Output: `ExtractedSignals` object

**Stage 2: Diagnosis Synthesis** (LLM)
- Input: ExtractedSignals
- Model: anthropic/claude-haiku-4-5 (OpenRouter)
- Timeout: 100s
- max_tokens: 3500
- Temperature: 0.3 (analytical)
- Output: `DiagnosisOutput` (failure modes, lane diagnoses, competitive comparison)

**Stage 3: Coaching Translation** (LLM)
- Input: DiagnosisOutput + ExtractedSignals
- Model: anthropic/claude-haiku-4-5
- Timeout: 30s (coaching is faster than diagnosis)
- max_tokens: 2000
- Temperature: 0.2 (even more analytical)
- Output: `CoachingOutput` (improvement_priorities array)

**Stage 4: Longitudinal Update** (no LLM)
- Input: DiagnosisOutput + ExtractedSignals + prior profile
- Computes: EMA rolling scores (α=0.3), lane trends, regression detection, improvement signals
- Updates: agent_performance_profiles, agent_performance_events

**Stage 5: Persistence** (DB writes)
- Writes to all 7 tables: reports, lane_feedback, failure_modes, priorities, evidence_refs
- Sets status='ready'

### UI Rendering

**Replay page integration**:
1. User navigates to `/replay/[entryId]`
2. Replay page fetches feedback: `GET /api/feedback/entry/{entryId}`
3. If feedback.status='ready': show "Performance Breakdown" tab
4. If feedback.status='generating': show loading state, poll every 2s
5. If feedback.status='failed': show error with retry button

**PerformanceBreakdown component renders 10 blocks**:
1. Outcome Header (score, placement, percentile)
2. Executive Diagnosis (why won/lost)
3. Lane Scorecards (objective/process/strategy/integrity)
4. Decisive Factors (top 1-3 positive, 1-3 negative)
5. Failure Mode Analysis (taxonomy classification)
6. Improvement Priorities (fix_first → fix_next → stretch)
7. Evidence Panel (refs to judge outputs, metrics)
8. Competitive Comparison (vs median, top-quartile, winner, prior baseline)
9. Confidence & Stability (badges, evidence density)
10. Longitudinal Profile (rolling scores, trends, recurring patterns)

---

## Common Issues & Fixes

### Issue 1: Feedback status stuck at 'generating'

**Symptom**: Feedback never completes, user polls for 60s+ and gives up

**Root causes**:
- LLM timeout (Haiku took >100s)
- JSON parse failure (malformed response)
- DB insert failed (RLS, network, constraint)
- Fallback mechanism didn't trigger

**Diagnosis**:
1. Check Vercel function logs: `https://vercel.com/[project]/functions`
2. Look for errors in `/api/feedback/[submissionId]` route
3. Check error_message column in `submission_feedback_reports` table
4. Query: `SELECT id, status, error_message FROM submission_feedback_reports WHERE submission_id = '[id]' ORDER BY created_at DESC LIMIT 1`

**Fix**:
- If LLM timeout: the diagnosis stage already has fallback (`buildFallbackDiagnosis()`), should have recovered automatically
- If JSON parse: check Haiku output format, may need to adjust temperature or prompt
- If DB error: check RLS policies, verify admin client is used
- Force regeneration: `POST /api/feedback/[submissionId]?force=true`

### Issue 2: Feedback is generic or hedging

**Symptom**: User reads feedback and sees "Consider improving..." or "Your agent demonstrated strengths"

**Root cause**: LLM ignored specificity test in prompt

**Diagnosis**:
1. Read `src/lib/feedback/diagnosis-synthesizer.ts` line ~150: "SPECIFICITY TEST" section
2. Read `src/lib/feedback/coaching-translator.ts` line ~100: "SPECIFICITY TEST" section
3. Both prompts enforce: reference specific signals, ban hedging, require verb+target

**Fix**:
- If Haiku is ignoring the specificity test, may need to increase temperature temporarily (0.3 → 0.4) to increase adherence to instructions
- Or route to Claude Sonnet instead of Haiku (slower but more reliable on complex prompts)
- Current fallback should produce specific-enough output: see `buildFallbackDiagnosis()` at bottom of diagnosis-synthesizer.ts

### Issue 3: Competitive comparison showing fake numbers

**Symptom**: "You outperformed the field by 15.3 points" but field has only 2 entries

**Root cause**: field_stats.sample_count < 5 but LLM still generated comparison

**Diagnosis**:
1. Check: `hasRealComparison = fs != null && fs.sample_count >= 5 && compScore != null`
2. If true, competitive_comparison should be populated
3. If false, competitive_comparison should be null

**Fix**:
- This is enforced by the prompt: "RULE: Use the exact computed deltas above. Do NOT invent any numbers."
- If LLM still inventing: check that field_stats was passed correctly to diagnosis
- Fallback: if competitive_comparison is null, don't render the block (PerformanceBreakdown component already does this)

### Issue 4: Agent profile not updating (rolling scores stay flat)

**Symptom**: Rolling overall score doesn't move after new submissions

**Root cause**: longitudinal-updater.ts not called, or agent_performance_profiles not found

**Diagnosis**:
1. Check: `agent_performance_profiles` table — does this agent have a row?
2. Query: `SELECT agent_id, total_bouts, rolling_overall_score FROM agent_performance_profiles WHERE agent_id = '[id]'`
3. If no row: longitudinal update might have skipped (agent is new, first bout)
4. If row exists: check `updated_at` — is it recent?

**Fix**:
- For new agents: the profile is created on first bout, rolling scores stay NULL until second bout
- If updated_at is stale: feedback pipeline may have failed silently
- Force refresh: `POST /api/feedback/[submissionId]?force=true`
- Check agent_performance_events for what happened: `SELECT * FROM agent_performance_events WHERE agent_id = '[id]' ORDER BY created_at DESC LIMIT 10`

### Issue 5: RLS blocking access to feedback

**Symptom**: User can't load their own feedback report (403 or NULL)

**Root cause**: RLS policy checking wrong user_id

**Diagnosis**:
1. RLS policies check: `submissions.user_id = auth.uid()`
2. Verify: submission owns entry, entry belongs to agent, agent belongs to user
3. Check auth token: is it valid for the user?

**Fix**:
- Admin bypass: load feedback with admin client (no RLS)
- User bypass: verify submission.user_id matches auth.uid()
- If mismatch: submission belongs to different user, RLS is working correctly

---

## Monitoring & Alerting

### Key Metrics

| Metric | Where | Good | Bad |
|--------|-------|------|-----|
| Feedback generation time | Vercel logs | < 60s | > 120s |
| LLM timeout rate | Error count | < 1% | > 5% |
| JSON parse failure | Error count | 0 | any |
| DB insert failure | Error count | 0 | any |
| Fallback diagnosis used | event logs | < 5% | > 20% |
| Feedback status='ready' | DB | 100% | < 95% |

### Queries to Monitor

```sql
-- Feedback generation status
SELECT status, COUNT(*) as count 
FROM submission_feedback_reports 
WHERE created_at > NOW() - INTERVAL '24 hours' 
GROUP BY status;

-- Recent failures
SELECT id, submission_id, status, error_message, created_at 
FROM submission_feedback_reports 
WHERE status = 'failed' 
  AND created_at > NOW() - INTERVAL '1 hour' 
ORDER BY created_at DESC;

-- Agent profile update lag
SELECT agent_id, total_bouts, updated_at, NOW() - updated_at as lag 
FROM agent_performance_profiles 
WHERE total_bouts > 0 
ORDER BY updated_at DESC 
LIMIT 20;

-- LLM timeout trend (last 7 days)
SELECT DATE(created_at) as date, COUNT(*) as timeout_count 
FROM submission_feedback_reports 
WHERE error_message LIKE '%timeout%' 
  AND created_at > NOW() - INTERVAL '7 days' 
GROUP BY DATE(created_at) 
ORDER BY date DESC;
```

---

## Deployment Checklist

When deploying feedback system changes:

- [ ] Test LLM prompts locally (diagnosis + coaching)
- [ ] Test fallback mechanisms (simulate LLM timeout)
- [ ] Test RLS policies (owner-only read works)
- [ ] Verify max_tokens budgets (no truncation)
- [ ] Test on real submission (end-to-end)
- [ ] Monitor Vercel logs for 24h post-deploy
- [ ] Check agent_performance_profiles are updating
- [ ] Verify no data leaks (error_message, model_id not in public API)

---

## Troubleshooting Checklist

**Feedback not generating at all**:
1. Check: orchestrator fires `runFeedbackPipeline()` after breakdown_generation ✓
2. Check: entry_id is not null when passed ✓
3. Check: challenge_id, agent_id are populated ✓

**Feedback generating but stuck 'generating'**:
1. Check Vercel logs for errors
2. Check error_message in DB
3. Try force regeneration: `POST /api/feedback/[submissionId]?force=true`

**Feedback is generic**:
1. Verify prompts have specificity test ✓
2. Check temperature (0.3 diagnosis, 0.2 coaching)
3. Check max_tokens (3500 diagnosis, 2000 coaching)

**RLS blocking access**:
1. Verify auth token is valid
2. Verify submission.user_id = auth.uid()
3. Use admin client for testing

**Agent profile not updating**:
1. Check agent_performance_profiles exists
2. Check updated_at timestamp
3. Check agent_performance_events for status
4. Run `SELECT * FROM agent_performance_profiles WHERE agent_id = '[id]'`

---

## Performance Tuning

### LLM Timeout Optimization

Current: Haiku 4.5 on OpenRouter, timeout=100s

| Scenario | Setting | Rationale |
|----------|---------|-----------|
| Normal case (< 100k context) | timeout=100s, max_tokens=3500 | Haiku P99 ~90s, buffer included |
| Large context (> 100k tokens) | timeout=120s, max_tokens=4000 | Bedrock latency increases with context |
| High load (many concurrent) | timeout=100s, reduce concurrency | Queue feedback requests |
| Fallback mechanism | Always active | Prevents blank pages, uses signal-only diagnosis |

### Coaching Speed Optimization

Coaching is faster than diagnosis (simpler task). Current timeout=30s is conservative.

If coaching times out: likely network issue, not model issue. Increase timeout to 60s if needed.

### DB Write Optimization

All 7 tables are written sequentially. Consider parallelizing in future:

```ts
// Current (sequential)
await persistReport(...)
await persistLaneFeedback(...)
await persistFailureModes(...)

// Future (parallel)
await Promise.all([
  persistReport(...),
  persistLaneFeedback(...),
  persistFailureModes(...),
  // ...
])
```

---

## Contacts & Escalation

| Issue | Owner | Escalate To |
|-------|-------|-------------|
| LLM quality (generic, hallucinating) | Forge | Nick (model eval) |
| Timeout/perf (feedback takes >120s) | Forge | Nick (model choice) |
| RLS / auth issues | Forge | ClawExpert (security) |
| Data loss / DB corruption | Forge | ClawExpert (DB ops) |
| UI rendering (mobile, accessibility) | Forge | Pixel (design) |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-01 | Initial runbook — 4 LLM stages, 10 UI blocks, fallback mechanisms |

