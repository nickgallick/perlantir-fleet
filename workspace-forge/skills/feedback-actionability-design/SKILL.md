---
name: feedback-actionability-design
description: Turning Bouts evaluation breakdowns into coaching items that are concrete enough to act on — specificity ladder, failure code → next step derivation, deduplication across submissions, and a priority-ordered TSX coaching display component.
---

# Feedback Actionability Design

## Review Checklist

- [ ] **Every coaching item names a specific behavior to change**, not a quality to "improve" — "add an explicit verify_result() call after each tool use" not "improve verification"
- [ ] **Maximum 3 coaching items per breakdown** — more than 3 creates analysis paralysis; if there are 8 things wrong, show only the 3 highest-impact
- [ ] **Coaching items are derived from failure codes**, not generated fresh each time — the same failure code always produces the same coaching item, making it consistent and testable
- [ ] **Deduplication is applied**: if the user received the same coaching item in their last 2 submissions and their score didn't improve, escalate to a more specific variant
- [ ] **Priority ordering is explicit**: coaching items are ordered by impact, not by lane order or failure code sequence
- [ ] **Each coaching item has a specificity score** — items below threshold (< 60) are rejected before display
- [ ] **Coaching items use "upgrade" framing**: "strengthen X" not "fix X", "add Y" not "stop doing Z"
- [ ] **The coaching generator is a pure function** — same input always produces same output; unit-testable
- [ ] **Historical submission context is passed to the generator** — it's required for deduplication and escalation logic
- [ ] **Coaching items are typed with a discriminated union** — `primary | supporting | stretch` priority levels
- [ ] **The TSX component handles 1, 2, or 3 items gracefully** — doesn't look broken with fewer than 3
- [ ] **Failure codes are documented in a registry** — no undocumented codes that silently produce no coaching item

---

## Feedback vs Coaching: The Core Distinction

This distinction is not pedantic — it determines whether users leave with something actionable.

**Feedback** describes what happened:
> "Your agent failed to verify its output before responding."

**Coaching** prescribes what to change:
> "Add an explicit verification call immediately after your main processing step. The 3 top-scoring submissions in this lane all verified before responding."

Feedback is backward-looking. Coaching is forward-looking. Evaluation platforms default to feedback because it's easier to generate — just describe the score. Coaching requires knowing what the user *should* do differently, which requires connecting the failure code to a specific remediation.

**The rule**: Every coaching item must answer "what specifically should I do next time?" If it doesn't answer that question, it's feedback, not coaching. Send it back.

---

## The Specificity Ladder

Every coaching item can be scored on a specificity scale. Items below 60 should not be shown to users.

```typescript
// lib/coaching/specificity.ts

/**
 * Specificity scoring rubric.
 * A coaching item is scored by checking how many specific properties it has.
 * Items below 60 are rejected.
 */

export interface CoachingItem {
  failureCode: string;
  text: string;             // the actual coaching text shown to user
  rationale: string;        // why this matters for their score
  specificity: number;      // computed 0–100
  priority: 'primary' | 'supporting' | 'stretch';
  laneId: string;
  impactPoints: number;     // estimated points available if remediated
}

export interface SpecificityCheck {
  namedSpecificBehavior: boolean;     // +25: names a specific thing to do/add/change
  includesExample: boolean;           // +20: gives an example or template
  quantifiedImpact: boolean;          // +15: states how much this matters (points, rank)
  hasLaneContext: boolean;            // +10: references the specific lane it affects
  avoidsPlatitudes: boolean;          // +20: no "improve", "better", "stronger" without specifics
  hasTimeBinding: boolean;            // +10: when to apply it (bonus)
}

export function scoreSpecificity(checks: SpecificityCheck): number {
  let score = 0;
  if (checks.namedSpecificBehavior) score += 25;
  if (checks.includesExample) score += 20;
  if (checks.quantifiedImpact) score += 15;
  if (checks.hasLaneContext) score += 10;
  if (checks.avoidsPlatitudes) score += 20;
  if (checks.hasTimeBinding) score += 10;
  return score;
}

// Examples by score tier:
// 100 — "In the Verification lane, add a verify_result() call immediately after process_task(). The top 3 submissions all did this and averaged 18 points higher in this lane."
// 80  — "Add an explicit verification step in the Verification lane — this costs ~15 points when missing."
// 60  — "The Verification lane requires an explicit check before responding."
// 40  — "Improve your verification approach." ← REJECTED
// 20  — "Do better in verification." ← REJECTED
```

---

## Failure Code Registry and Coaching Item Generator

Failure codes are the bridge between the judge's assessment and the coaching item. Each code maps to a specific coaching template.

```typescript
// lib/coaching/failure-codes.ts
import type { CoachingItem } from './specificity';

export type FailureCode =
  | 'FW-001'  // Missing verification step
  | 'FW-002'  // Tool call not grounded in task requirements
  | 'FW-003'  // Response before all constraints satisfied
  | 'FW-004'  // Planning phase too brief
  | 'FW-005'  // Assumption not stated before acting
  | 'CL-001'  // Response unclear about what action was taken
  | 'CL-002'  // Technical jargon without explanation
  | 'CL-003'  // Final answer not explicitly stated
  | 'EF-001'  // Redundant tool calls
  | 'EF-002'  // Same tool called with same params multiple times
  | 'EF-003'  // Unnecessary preamble before main action
  | string;   // allow extension

export interface FailureCodeDefinition {
  code: FailureCode;
  laneAffected: string;   // which lane this primarily affects
  impactPoints: number;   // typical point impact when this failure occurs
  primaryCoaching: string;
  primaryRationale: string;
  escalatedCoaching: string;    // used when user has seen primary 2+ times
  escalatedRationale: string;
  specificity: number;    // pre-computed for template
}

export const FAILURE_CODE_REGISTRY: Record<string, FailureCodeDefinition> = {
  'FW-001': {
    code: 'FW-001',
    laneAffected: 'Verification',
    impactPoints: 15,
    primaryCoaching: 'Add an explicit verification call immediately after your main processing step, before generating your response.',
    primaryRationale: 'The top 3 submissions in the Verification lane all verified before responding. This single step accounts for ~15 points.',
    escalatedCoaching: 'Your verification step is missing for the second time. Specifically: after calling process_task(), add a call to verify_output(result) and include the verification outcome in your response.',
    escalatedRationale: 'This has been flagged in your previous submission. The pattern is consistent — add it as a mandatory step in your agent\'s workflow.',
    specificity: 90,
  },
  'FW-002': {
    code: 'FW-002',
    laneAffected: 'Relevance',
    impactPoints: 10,
    primaryCoaching: 'Before each tool call, state explicitly which task requirement it addresses.',
    primaryRationale: 'Judges in the Relevance lane look for grounded tool use — every action should connect back to a constraint from the task brief.',
    escalatedCoaching: 'Add a one-line comment in your reasoning before each tool call: "This addresses constraint X from the task." Judges cannot score relevance without visible grounding.',
    escalatedRationale: 'Your tool calls are being scored as ungrounded for the second time. Make the connection to task requirements explicit and visible.',
    specificity: 85,
  },
  'FW-003': {
    code: 'FW-003',
    laneAffected: 'Completeness',
    impactPoints: 18,
    primaryCoaching: 'Before generating your final response, enumerate all constraints from the task brief and confirm each is satisfied.',
    primaryRationale: 'The Completeness lane checks every constraint, not just the primary one. Enumerate them and confirm explicitly — this adds ~18 points when done correctly.',
    escalatedCoaching: 'Your response is being cut before all constraints are met. Add a final checklist step: list each constraint from the task brief, mark it satisfied or not, and only respond after all are marked satisfied.',
    escalatedRationale: 'This is the second time your response was generated before all constraints were satisfied. A structured constraint check at the end is the fix.',
    specificity: 92,
  },
  'FW-004': {
    code: 'FW-004',
    laneAffected: 'Planning',
    impactPoints: 12,
    primaryCoaching: 'Spend at least 2–3 explicit reasoning steps on planning before your first tool call or action.',
    primaryRationale: 'The Planning lane scores whether the agent demonstrates a coherent strategy. Two or more visible planning steps before acting is the threshold for full credit.',
    escalatedCoaching: 'Your planning phase is consistently too brief. Before ANY tool call, explicitly state: (1) what the task requires, (2) what your approach will be, (3) what the expected outcome is.',
    escalatedRationale: 'Planning scores have been low across both your submissions. This structured approach is the pattern used by top-scoring submissions.',
    specificity: 80,
  },
  'CL-001': {
    code: 'CL-001',
    laneAffected: 'Clarity',
    impactPoints: 8,
    primaryCoaching: 'State what action you took and what the result was at the end of each significant step.',
    primaryRationale: 'The Clarity lane checks whether a reader can follow what the agent did. Explicit "I did X, which resulted in Y" statements at each step are the pattern.',
    escalatedCoaching: 'Your responses are consistently unclear about what happened. Use this template at each step: "I [specific action]. This [specific result]. Next I will [specific next action]."',
    escalatedRationale: 'Clarity scores have been below median twice. The template above is the fastest fix.',
    specificity: 82,
  },
  'EF-001': {
    code: 'EF-001',
    laneAffected: 'Efficiency',
    impactPoints: 7,
    primaryCoaching: 'Check if a tool call result already contains the information you need before calling another tool.',
    primaryRationale: 'Redundant tool calls directly cost points in the Efficiency lane. Before each call, ask: do I already have this result?',
    escalatedCoaching: 'Your submissions consistently include redundant tool calls. Add a "do I already know this?" check before every tool call. If the result exists in context, use it — don\'t re-fetch.',
    escalatedRationale: 'This pattern has appeared in both submissions. It\'s a systematic habit, not a one-time mistake.',
    specificity: 78,
  },
};

/**
 * Generate coaching items from a list of failure codes.
 * Handles deduplication against historical failure codes.
 */
export function generateCoachingItems(
  failureCodes: string[],
  historicalFailureCodes: string[][],  // array of failure code arrays from previous submissions, newest first
  maxItems = 3
): CoachingItem[] {
  if (failureCodes.length === 0) return [];

  const items: CoachingItem[] = [];

  for (const code of failureCodes) {
    const def = FAILURE_CODE_REGISTRY[code];
    if (!def) continue;  // unknown code — skip silently

    // Deduplication: check if this code appeared in last 2 submissions
    const recentCount = historicalFailureCodes
      .slice(0, 2)
      .filter(codes => codes.includes(code)).length;

    const useEscalated = recentCount >= 2;

    const text = useEscalated ? def.escalatedCoaching : def.primaryCoaching;
    const rationale = useEscalated ? def.escalatedRationale : def.primaryRationale;

    items.push({
      failureCode: code,
      text,
      rationale,
      specificity: def.specificity,
      priority: 'supporting', // will be reassigned below
      laneId: def.laneAffected,
      impactPoints: def.impactPoints,
    });
  }

  // Sort by impact (highest impact first)
  items.sort((a, b) => b.impactPoints - a.impactPoints);

  // Assign priority tiers
  return items.slice(0, maxItems).map((item, index) => ({
    ...item,
    priority: index === 0 ? 'primary' : index === 1 ? 'supporting' : 'stretch',
  }));
}

/**
 * Specificity gate — filter out items below threshold before display.
 * Never show vague coaching items even if generated.
 */
export function filterBySpecificity(
  items: CoachingItem[],
  threshold = 60
): CoachingItem[] {
  return items.filter(item => item.specificity >= threshold);
}
```

---

## Deduplication Logic Across Historical Submissions

When the same agent submits multiple times without improving on a specific failure, the coaching should escalate — more specific, more direct.

```typescript
// lib/coaching/deduplication.ts
import { generateCoachingItems, filterBySpecificity } from './failure-codes';
import type { CoachingItem } from './specificity';

export interface SubmissionHistory {
  submissionId: string;
  failureCodes: string[];
  submittedAt: Date;
}

/**
 * Compute coaching items with full deduplication context.
 * Handles: new codes, repeated codes (primary → escalated), and resolved codes.
 */
export function computeCoachingWithHistory(
  currentFailureCodes: string[],
  submissionHistory: SubmissionHistory[],  // sorted newest-first, not including current
  maxItems = 3
): {
  items: CoachingItem[];
  escalatedCodes: string[];
  resolvedCodes: string[];
} {
  // Sort history newest first
  const sortedHistory = [...submissionHistory].sort(
    (a, b) => b.submittedAt.getTime() - a.submittedAt.getTime()
  );

  const historicalFailureCodes = sortedHistory.map(s => s.failureCodes);

  // Resolved codes: appeared in history but not in current — user improved
  const previousCodes = new Set(sortedHistory.flatMap(s => s.failureCodes));
  const currentCodeSet = new Set(currentFailureCodes);
  const resolvedCodes = [...previousCodes].filter(code => !currentCodeSet.has(code));

  // Escalated codes: appear in current AND last 2 submissions
  const escalatedCodes = currentFailureCodes.filter(code => {
    const recentCount = historicalFailureCodes.slice(0, 2).filter(codes => codes.includes(code)).length;
    return recentCount >= 2;
  });

  const rawItems = generateCoachingItems(currentFailureCodes, historicalFailureCodes, maxItems * 2);
  const filteredItems = filterBySpecificity(rawItems);
  const finalItems = filteredItems.slice(0, maxItems);

  return {
    items: finalItems,
    escalatedCodes,
    resolvedCodes,
  };
}
```

---

## TSX Coaching Display Component

```tsx
// components/coaching/CoachingBreakdown.tsx
'use client';

import React, { useState } from 'react';
import { cn } from '@/lib/utils';
import type { CoachingItem } from '@/lib/coaching/specificity';

interface CoachingBreakdownProps {
  items: CoachingItem[];
  resolvedCodes?: string[];
  agentName: string;
}

const priorityConfig = {
  primary: {
    label: 'Key Focus',
    labelStyle: 'bg-indigo-100 text-indigo-700 border border-indigo-200',
    cardStyle: 'border-indigo-200 bg-white',
    iconBg: 'bg-indigo-50',
    icon: '🎯',
  },
  supporting: {
    label: 'Also Address',
    labelStyle: 'bg-gray-100 text-gray-600 border border-gray-200',
    cardStyle: 'border-gray-200 bg-white',
    iconBg: 'bg-gray-50',
    icon: '↑',
  },
  stretch: {
    label: 'Bonus',
    labelStyle: 'bg-gray-50 text-gray-400 border border-gray-100',
    cardStyle: 'border-gray-100 bg-gray-50',
    iconBg: 'bg-gray-50',
    icon: '◦',
  },
};

export function CoachingBreakdown({
  items,
  resolvedCodes = [],
  agentName,
}: CoachingBreakdownProps) {
  const [expandedItems, setExpandedItems] = useState<Set<string>>(new Set());

  const toggleExpand = (code: string) => {
    setExpandedItems(prev => {
      const next = new Set(prev);
      next.has(code) ? next.delete(code) : next.add(code);
      return next;
    });
  };

  if (items.length === 0) {
    return (
      <div className="rounded-xl bg-emerald-50 border border-emerald-200 p-5">
        <p className="text-sm font-semibold text-emerald-900">No specific improvements flagged.</p>
        <p className="text-xs text-emerald-700 mt-1">
          The judges found no significant pattern failures in {agentName}'s submission.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-gray-900">
          Next submission coaching
        </h3>
        <span className="text-xs text-gray-400">
          {items.length} item{items.length !== 1 ? 's' : ''} · highest impact first
        </span>
      </div>

      {/* Resolved codes — celebrate wins */}
      {resolvedCodes.length > 0 && (
        <div className="rounded-lg bg-emerald-50 border border-emerald-100 px-4 py-3">
          <p className="text-xs text-emerald-700 font-medium">
            ✓ {resolvedCodes.length} issue{resolvedCodes.length !== 1 ? 's' : ''} from your last submission {resolvedCodes.length === 1 ? 'was' : 'were'} resolved.
          </p>
        </div>
      )}

      {/* Coaching items — ordered by priority (primary first) */}
      {items.map((item) => {
        const cfg = priorityConfig[item.priority];
        const isExpanded = expandedItems.has(item.failureCode);

        return (
          <div
            key={item.failureCode}
            className={cn('rounded-xl border overflow-hidden', cfg.cardStyle)}
          >
            <div className="px-5 py-4">
              <div className="flex items-start gap-3">
                <div className={cn('mt-0.5 h-8 w-8 shrink-0 rounded-lg flex items-center justify-center text-base', cfg.iconBg)}>
                  {cfg.icon}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap mb-1.5">
                    <span className={cn('text-[10px] font-semibold px-2 py-0.5 rounded-full', cfg.labelStyle)}>
                      {cfg.label}
                    </span>
                    <span className="text-xs text-gray-400">{item.laneId}</span>
                    <span className="text-xs text-indigo-500 font-medium">
                      ~{item.impactPoints} pts
                    </span>
                  </div>
                  <p className="text-sm text-gray-800 leading-relaxed">{item.text}</p>

                  {/* Expandable rationale */}
                  <button
                    type="button"
                    onClick={() => toggleExpand(item.failureCode)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        toggleExpand(item.failureCode);
                      }
                    }}
                    className="mt-2 flex items-center gap-1 text-xs text-gray-400 hover:text-gray-600 transition-colors"
                    aria-expanded={isExpanded}
                    aria-controls={`rationale-${item.failureCode}`}
                  >
                    <svg
                      className={cn('h-3 w-3 transition-transform', isExpanded && 'rotate-90')}
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                    {isExpanded ? 'Less' : 'Why this matters'}
                  </button>
                </div>
              </div>
            </div>

            {/* Rationale panel */}
            <div
              id={`rationale-${item.failureCode}`}
              className={cn(
                'px-5 border-t border-gray-100 bg-gray-50 transition-all duration-150 overflow-hidden',
                isExpanded ? 'py-3 max-h-40' : 'max-h-0 py-0'
              )}
            >
              <p className="text-xs text-gray-600 leading-relaxed">{item.rationale}</p>
            </div>
          </div>
        );
      })}

      {/* Hard limit note */}
      <p className="text-xs text-gray-400 text-center">
        Showing top {items.length} of potentially more issues · focus here first
      </p>
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Showing all failure codes as coaching items

```typescript
// BAD — dumps all 8 failures; user doesn't know where to start
const coachingItems = failureCodes.map(code => ({
  code,
  text: FAILURE_CODE_REGISTRY[code]?.primaryCoaching ?? code,
}));
// Result: 8 items, no priority, no deduplication, user overwhelmed

// GOOD — limit to 3, sort by impact, gate on specificity
const rawItems = generateCoachingItems(failureCodes, history, 6);
const gatedItems = filterBySpecificity(rawItems, 60);
const finalItems = gatedItems.slice(0, 3); // hard cap at 3
```

### ❌ Same coaching item every submission without escalation

```typescript
// BAD — user gets "add verification step" for the 5th time with no improvement signal
function getCoaching(code: string): string {
  return FAILURE_CODE_REGISTRY[code]?.primaryCoaching ?? '';
}

// GOOD — escalate when code is persistent
const recentCount = history.slice(0, 2).filter(s => s.failureCodes.includes(code)).length;
const text = recentCount >= 2
  ? FAILURE_CODE_REGISTRY[code]?.escalatedCoaching
  : FAILURE_CODE_REGISTRY[code]?.primaryCoaching;
```

### ❌ Feedback framing instead of coaching framing

```typescript
// BAD — describes what happened (feedback)
{ text: 'Your agent did not verify its output before responding.' }

// GOOD — prescribes what to change (coaching)
{ text: 'Add an explicit verify_output() call immediately after process_task(). Do this before any response generation.' }
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| All failure codes displayed without limit | User sees 7 coaching items, ignores all of them | Hard cap at 3; sort by `impactPoints` desc first |
| Unknown failure codes produce empty coaching | Users get no coaching for new judges | Add a fallback generic coaching item for unregistered codes |
| Same primary coaching after 3+ identical failures | User sees same advice they've ignored twice; loses faith | Implement escalation logic: `recentCount >= 2 → escalatedCoaching` |
| Coaching text says "improve" without specifics | Scores below 60 specificity pass the filter | Add specificity gate: `filterBySpecificity(items, 60)` |
| Resolved codes not surfaced | User improved but gets no acknowledgment | Compute and display `resolvedCodes` from history diff |
| Impact points missing from display | User can't prioritize — all items look equally important | Show `~{impactPoints} pts` next to each item |
| Coaching item derived from wrong lane | "Add verification" shown for a Clarity failure | Verify `laneAffected` in failure code registry matches the judged lane |
| Expand/collapse rationale not keyboard accessible | Tab users can't read why the coaching matters | Add `onKeyDown` for Enter/Space on toggle button |
| Coaching component crashes if `items` is empty | White box when no failure codes found | Render empty state: "No specific improvements flagged" |
| Coaching items ordered by lane order not impact | Lane #1 coaching shown even when Lane #3 has 3x the impact | Always sort by `impactPoints` descending before slicing |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
