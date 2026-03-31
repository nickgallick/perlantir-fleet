---
name: multi-stage-llm-pipeline
description: Multi-stage async LLM pipeline design — stage isolation, structured handoffs, idempotency, concurrency-safe profile updates, and failure handling across chained LLM calls.
---

# Multi-Stage LLM Pipeline Architecture

## Review Checklist

1. [ ] Pipeline is async — never synchronous in an API route (will timeout on any real load)
2. [ ] Each stage has a typed input and typed output schema (Zod)
3. [ ] Stage handoffs stored in DB — pipeline is resumable, not in-memory
4. [ ] Each stage is idempotent — re-running it with the same input produces the same output
5. [ ] Final DB writes use upsert, not insert (concurrent completions safe)
6. [ ] LLM output validated before writing (don't trust structured output blindly)
7. [ ] Each stage has a timeout — no hanging indefinitely on LLM failure
8. [ ] Pipeline status is queryable (status field, not fire-and-forget)
9. [ ] Partial failures don't corrupt downstream stages
10. [ ] Evidence refs are preserved through all stages — no summarization that loses them

---

## Core Architecture: 4-Stage Feedback Pipeline

This is the correct architecture for the Bouts feedback pipeline. DO NOT collapse into a single monolithic LLM call.

```
Stage 1: Signal Extraction
  Input: raw submission data (code diff, tool traces, transcript, scores)
  Output: structured signals — factual observations, no interpretation
  Key constraint: NO inference, only extraction. "Agent called X 3 times" not "Agent struggles with X"

Stage 2: Diagnosis Synthesis
  Input: Stage 1 signals + failure mode taxonomy
  Output: failure mode classifications with confidence + evidence refs
  Key constraint: every diagnosis MUST reference at least 1 signal from Stage 1

Stage 3: Coaching Translation
  Input: Stage 2 diagnoses + agent's historical profile
  Output: actionable coaching items — specific, non-generic, ranked by impact
  Key constraint: coaching text must differ from median agent text by > threshold

Stage 4: Longitudinal Update
  Input: Stage 3 output + existing agent_performance_profile
  Output: updated rolling aggregates (lane scores, failure frequency, trend deltas)
  Key constraint: upsert with optimistic lock — concurrent updates must not clobber
```

---

## Stage Handoff Schema

Store each stage output in DB so the pipeline is resumable:

```sql
CREATE TABLE pipeline_stages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  submission_id uuid NOT NULL REFERENCES submissions(id),
  stage int NOT NULL CHECK (stage BETWEEN 1 AND 4),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  input jsonb,
  output jsonb,
  error text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE (submission_id, stage)
);
```

---

## TypeScript Pipeline Orchestrator

```typescript
import { z } from 'zod'

// Stage schemas — define BEFORE writing prompts
const Stage1Output = z.object({
  signals: z.array(z.object({
    signal_id: z.string(),
    category: z.enum(['tool_use', 'reasoning', 'code_quality', 'planning', 'communication']),
    observation: z.string(),         // factual, no interpretation
    evidence_refs: z.array(z.string()), // transcript line numbers, tool trace IDs, diff hunks
    frequency: z.number().optional(), // how many times observed
  }))
})

const Stage2Output = z.object({
  diagnoses: z.array(z.object({
    failure_code: z.string(),           // e.g. "FW-007"
    failure_label: z.string(),
    confidence: z.enum(['high', 'medium', 'low']),
    confidence_reasoning: z.string(),   // why this confidence level
    evidence_signal_ids: z.array(z.string()), // MUST reference Stage1 signal_ids
    severity: z.enum(['critical', 'significant', 'minor']),
  }))
})

type Stage1Result = z.infer<typeof Stage1Output>
type Stage2Result = z.infer<typeof Stage2Output>

// Pipeline runner
async function runPipeline(submissionId: string) {
  const submission = await getSubmission(submissionId)
  
  // Stage 1
  await updateStageStatus(submissionId, 1, 'running')
  let stage1: Stage1Result
  try {
    stage1 = await runStage1(submission)
    await saveStageOutput(submissionId, 1, stage1)
  } catch (err) {
    await updateStageStatus(submissionId, 1, 'failed', String(err))
    throw err // pipeline aborts — don't proceed with empty signals
  }

  // Stage 2 — only runs if Stage 1 completed
  await updateStageStatus(submissionId, 2, 'running')
  let stage2: Stage2Result
  try {
    stage2 = await runStage2(stage1, submission.challengeContext)
    await saveStageOutput(submissionId, 2, stage2)
  } catch (err) {
    await updateStageStatus(submissionId, 2, 'failed', String(err))
    throw err
  }

  // ... stages 3 and 4 follow same pattern
}
```

---

## Idempotency Pattern

Re-running a stage with the same input must produce the same output. Use a deterministic stage key:

```typescript
async function runStage1(submission: Submission): Promise<Stage1Result> {
  // Check if already completed
  const existing = await db
    .from('pipeline_stages')
    .select('output')
    .eq('submission_id', submission.id)
    .eq('stage', 1)
    .eq('status', 'completed')
    .single()

  if (existing.data?.output) {
    return Stage1Output.parse(existing.data.output) // return cached result
  }

  // Run LLM call
  const result = await callLLMWithStructuredOutput(stage1Prompt(submission), Stage1Output)
  return result
}
```

---

## Concurrency-Safe Profile Update (Stage 4)

`agent_performance_profiles` is written by concurrent pipeline completions. Use advisory lock:

```sql
-- Upsert with lock — prevents concurrent overwrites
SELECT pg_advisory_xact_lock(hashtext(agent_id::text)) FROM agent_performance_profiles;

INSERT INTO agent_performance_profiles (agent_id, lane_id, score, submission_count, updated_at)
VALUES ($1, $2, $3, 1, now())
ON CONFLICT (agent_id, lane_id) DO UPDATE SET
  score = (
    agent_performance_profiles.score * agent_performance_profiles.submission_count + EXCLUDED.score
  ) / (agent_performance_profiles.submission_count + 1),
  submission_count = agent_performance_profiles.submission_count + 1,
  updated_at = now();
```

In TypeScript (Supabase Edge Function):
```typescript
// Use a transaction + lock
const { error } = await supabase.rpc('upsert_agent_profile_locked', {
  p_agent_id: agentId,
  p_lane_id: laneId,
  p_new_score: newScore
})
```

---

## Evidence Ref Integrity Check

Before Stage 2 writes diagnoses, validate that every evidence ref actually exists in Stage 1 output:

```typescript
function validateEvidenceRefs(stage1: Stage1Result, stage2: Stage2Result): void {
  const validSignalIds = new Set(stage1.signals.map(s => s.signal_id))
  
  for (const diagnosis of stage2.diagnoses) {
    for (const ref of diagnosis.evidence_signal_ids) {
      if (!validSignalIds.has(ref)) {
        throw new Error(
          `Stage 2 diagnosis '${diagnosis.failure_code}' references unknown signal '${ref}'. ` +
          `LLM hallucinated a signal ID. Reject this output.`
        )
      }
    }
    if (diagnosis.evidence_signal_ids.length === 0) {
      throw new Error(
        `Stage 2 diagnosis '${diagnosis.failure_code}' has no evidence refs. ` +
        `Every diagnosis must be grounded in at least one Stage 1 signal.`
      )
    }
  }
}
```

---

## Common Failure Modes to Catch in Review

| Failure | Pattern | Fix |
|---------|---------|-----|
| Monolithic call | Single LLM call for all 4 stages | Reject — split into stages |
| Synchronous pipeline in API route | `await runFullPipeline()` in route handler | Move to background job |
| No stage status storage | Pipeline runs in memory, unrecoverable | Store each stage in DB |
| Non-idempotent stages | Re-run duplicates data | Always check for existing completed stage |
| Concurrent profile clobber | `UPDATE ... SET score = $1` without lock | Use advisory lock + weighted average |
| Hallucinated evidence refs | Stage 2 invents signal IDs | Validate all refs against Stage 1 output |
| Missing stage timeout | LLM hangs → pipeline stuck forever | AbortSignal timeout on every call |

---

## Changelog
- 2026-03-31: Created for Bouts feedback pipeline build
