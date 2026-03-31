---
name: failure-mode-classifier
description: Purpose-built LLM classifier design for failure mode taxonomy — 15-code classification with confidence scoring, anti-convergence patterns, evidence anchoring, and anti-generic prompt enforcement.
---

# Failure Mode Classifier — Prompt Engineering

## The Core Problem

Generic LLM classifiers converge on 2-3 codes regardless of input. If your Stage 2 classifier produces the same 3 failure modes for every agent, the taxonomy is useless. This skill prevents that.

## Review Checklist

1. [ ] Classifier prompt presents ALL 15 codes with descriptions — not a subset
2. [ ] Prompt explicitly bans "I don't have enough evidence" — classifier must commit
3. [ ] Each classified failure code requires a `confidence` field AND a `confidence_reasoning` field
4. [ ] Prompt enforces minimum 3, maximum 7 codes per submission (prevents convergence AND over-labeling)
5. [ ] Prompt explicitly names the anti-convergence codes (common ones to over-weight) and instructs model to actively look for rarer codes
6. [ ] Evidence anchoring required — every code must cite at least one transcript line / tool trace / diff hunk
7. [ ] Anti-generic language enforced in coaching output (specific examples below)
8. [ ] Output validated with Zod before writing to DB
9. [ ] Confidence scoring is calibrated — if everything is "high", prompt is wrong
10. [ ] Classifier re-run on structured output failure — don't silently accept malformed output

---

## Failure Mode Taxonomy Schema

Define your 15 codes once in a shared constants file. The classifier prompt MUST include all 15:

```typescript
// lib/failure-taxonomy.ts
export const FAILURE_TAXONOMY = [
  {
    code: 'FW-001',
    label: 'Premature Tool Invocation',
    description: 'Agent calls a tool before fully reasoning through whether it is the right tool for the current step',
    convergence_risk: 'low', // rare — actively look for this
  },
  {
    code: 'FW-002',
    label: 'Context Window Neglect',
    description: 'Agent fails to use information already present in context, re-derives it or ignores it',
    convergence_risk: 'medium',
  },
  {
    code: 'FW-003',
    label: 'Planning Depth Failure',
    description: 'Agent proceeds step-by-step without a multi-step plan, leading to avoidable backtracking',
    convergence_risk: 'high', // over-labeled — apply strict evidence requirement
  },
  {
    code: 'FW-004',
    label: 'Verification Skipping',
    description: 'Agent asserts task completion without verifying the output meets the acceptance criteria',
    convergence_risk: 'high', // over-labeled
  },
  {
    code: 'FW-005',
    label: 'Instruction Drift',
    description: 'Agent gradually drifts from the original task requirements across multiple steps',
    convergence_risk: 'medium',
  },
  {
    code: 'FW-006',
    label: 'Error Recovery Failure',
    description: 'Agent receives an error but does not change strategy — repeats the same failing approach',
    convergence_risk: 'low',
  },
  {
    code: 'FW-007',
    label: 'Over-Tooling',
    description: 'Agent uses tools when the answer was derivable from existing context — unnecessary API calls',
    convergence_risk: 'low',
  },
  {
    code: 'FW-008',
    label: 'Hallucinated Capability',
    description: 'Agent attempts to call a tool or function that does not exist in the available tool set',
    convergence_risk: 'low',
  },
  {
    code: 'FW-009',
    label: 'Output Format Non-Compliance',
    description: 'Agent produces output that does not match the required format, schema, or structure',
    convergence_risk: 'medium',
  },
  {
    code: 'FW-010',
    label: 'Scope Creep',
    description: 'Agent modifies files, data, or behavior outside the stated scope of the task',
    convergence_risk: 'low',
  },
  {
    code: 'FW-011',
    label: 'Reasoning-Action Mismatch',
    description: 'Agent\'s stated reasoning in scratchpad or explanation contradicts the action it takes',
    convergence_risk: 'low',
  },
  {
    code: 'FW-012',
    label: 'Latency Bloat',
    description: 'Agent takes significantly more steps than necessary for the complexity of the task',
    convergence_risk: 'medium',
  },
  {
    code: 'FW-013',
    label: 'Dependency Assumption',
    description: 'Agent assumes a resource, library, or prior step exists without confirming',
    convergence_risk: 'medium',
  },
  {
    code: 'FW-014',
    label: 'Confidence Miscalibration',
    description: 'Agent expresses high confidence in an incorrect result, or hedges excessively on a correct one',
    convergence_risk: 'low',
  },
  {
    code: 'FW-015',
    label: 'Partial Task Completion',
    description: 'Agent completes the literal request but misses the underlying intent or leaves obvious follow-on steps undone',
    convergence_risk: 'high', // over-labeled — require specific evidence
  },
] as const

export type FailureCode = typeof FAILURE_TAXONOMY[number]['code']
```

---

## Stage 2 Classifier Prompt (Anti-Convergence Design)

This prompt structure is engineered to prevent the 2-3 code convergence problem:

```typescript
function buildStage2Prompt(
  signals: Stage1Signal[],
  taxonomy: typeof FAILURE_TAXONOMY
): string {
  // Identify high convergence-risk codes to call out explicitly
  const highRiskCodes = taxonomy.filter(t => t.convergence_risk === 'high')
  const rareCodesStr = taxonomy
    .filter(t => t.convergence_risk === 'low')
    .map(t => `${t.code} (${t.label})`)
    .join(', ')

  return `
You are a precision failure mode classifier for AI agent submissions. Your job is to classify
observed failure patterns from the signal list below into the taxonomy provided.

## Critical Instructions

1. You MUST classify between 3 and 7 failure modes. No fewer, no more.

2. ANTI-CONVERGENCE RULE: The following codes are frequently over-applied and require STRICT
   evidence before classifying:
${highRiskCodes.map(c => `   - ${c.code} (${c.label}): Only classify if you can cite a SPECIFIC step where this occurred`).join('\n')}

3. RARE CODE PRIORITY: Actively look for evidence of these less common codes before concluding
   they don't apply: ${rareCodesStr}

4. EVIDENCE REQUIREMENT: Every classified code MUST include at least one signal_id from the
   signal list below. Do NOT classify a code if you cannot cite specific evidence.

5. CONFIDENCE CALIBRATION:
   - high: Direct, unambiguous evidence in 2+ signals
   - medium: Indirect evidence or single occurrence
   - low: Plausible but circumstantial — include only if evidence exists

6. ANTI-GENERIC RULE: Your confidence_reasoning must be specific to THIS agent's submission.
   Do NOT write "The agent failed to verify its output" — write "At step 14, the agent reported
   task complete after tool call X returned error 404 without checking the response."

## Failure Mode Taxonomy

${taxonomy.map(t => `### ${t.code} — ${t.label}\n${t.description}`).join('\n\n')}

## Observed Signals

${signals.map(s => `[${s.signal_id}] ${s.category}: ${s.observation}\nEvidence: ${s.evidence_refs.join(', ')}`).join('\n\n')}

## Output Format

Respond with valid JSON matching this schema exactly:
{
  "diagnoses": [
    {
      "failure_code": "FW-XXX",
      "failure_label": "...",
      "confidence": "high" | "medium" | "low",
      "confidence_reasoning": "Specific reasoning citing step numbers and signal IDs",
      "evidence_signal_ids": ["signal_id_1", ...],
      "severity": "critical" | "significant" | "minor"
    }
  ]
}
`
}
```

---

## Anti-Generic Coaching Enforcement

The Stage 3 coaching prompt must explicitly ban generic output. Failing to do this produces the same coaching for every agent:

```typescript
const ANTI_GENERIC_PATTERNS = [
  "Consider improving your planning",
  "Try to verify your outputs",
  "Work on your reasoning process",
  "Focus on task completion",
  "Be more careful with tool usage",
]

// Add to Stage 3 system prompt:
const antiGenericInstruction = `
BANNED PHRASES: The following patterns are PROHIBITED in coaching output. If you find yourself
writing any of these, stop and rewrite with a specific example from this submission:
${ANTI_GENERIC_PATTERNS.map(p => `- "${p}"`).join('\n')}

COACHING FORMAT REQUIREMENT:
❌ Bad: "The agent should verify task completion before reporting done."
✅ Good: "After calling search_files() at step 8 and receiving 0 results, you reported the task
complete without attempting an alternative search strategy. Next time: when a primary search
returns empty, try 2 variations (broader query, different path) before concluding the file
doesn't exist."

Every coaching item must reference a specific step, tool call, or decision point from this submission.
`
```

---

## Output Validation Before DB Write

```typescript
import { z } from 'zod'

const DiagnosisSchema = z.object({
  failure_code: z.string().regex(/^FW-\d{3}$/),
  failure_label: z.string().min(1),
  confidence: z.enum(['high', 'medium', 'low']),
  confidence_reasoning: z.string().min(50), // too short = generic
  evidence_signal_ids: z.array(z.string()).min(1), // must have evidence
  severity: z.enum(['critical', 'significant', 'minor']),
})

const Stage2OutputSchema = z.object({
  diagnoses: z.array(DiagnosisSchema).min(3).max(7) // enforce diversity
})

// In your pipeline:
const raw = await callLLM(stage2Prompt, { responseFormat: 'json' })
const parsed = Stage2OutputSchema.safeParse(JSON.parse(raw))

if (!parsed.success) {
  // Don't silently accept — retry once with error feedback
  const retryPrompt = `Your previous output failed validation: ${parsed.error.message}. 
Regenerate your response fixing these issues.`
  const retryRaw = await callLLM(retryPrompt, { responseFormat: 'json' })
  const retried = Stage2OutputSchema.parse(JSON.parse(retryRaw)) // throw if fails twice
}
```

---

## Common Classifier Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Convergence on 2-3 codes | Same codes every submission | Add anti-convergence section to prompt |
| Generic confidence_reasoning | "The agent failed to plan" | Enforce min_length + cite step numbers |
| Missing taxonomy in prompt | Model invents codes | Include full 15-code list in every call |
| No min/max code count | 1 code or 15 codes returned | Enforce 3-7 in Zod schema |
| No evidence validation | Diagnoses with no signal refs | Validate every ref against Stage 1 |
| Coaching too short | <100 chars per item | Min length validation on coaching items |
| Same coaching for all agents | Generic language leaked in | Run anti-generic pattern check on output |

---

## Changelog
- 2026-03-31: Created for Bouts feedback pipeline — anti-convergence classifier design
