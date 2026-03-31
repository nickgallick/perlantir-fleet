---
name: trust-and-methodology-communication
description: Making the Bouts scoring system legible to competitors — evidence vs inference labeling, provisional vs final copy, methodology disclosure, and dispute acknowledgment patterns that open the black box without overwhelming users.
---

# Trust and Methodology Communication

## Review Checklist

- [ ] **Every score shown has a visible signal of its status**: provisional scores have an amber badge, final scores have no badge (final is the default/unremarkable state)
- [ ] **Evidence refs are labeled as "Evidence" (with source) or "Inference" (model reasoning)** — these are categorically different and users must be able to distinguish them
- [ ] **Provisional copy is honest but not alarming** — "preliminary" not "unverified"; "may change" not "possibly wrong"
- [ ] **Methodology disclosure is one click away from every score** — a "?" icon or "How is this scored?" link on every lane row
- [ ] **Methodology explanations are in plain language** — no model names, no technical jargon in the user-facing copy
- [ ] **Dispute acknowledgment shows the specific score/lane the user is questioning** — not a generic "contact us" form
- [ ] **Badge components use `aria-label` with full text** — "Provisional — may change" not just a colored dot
- [ ] **The methodology drawer closes on Escape and focuses back on the trigger** — keyboard accessible
- [ ] **"How judges score" explainer exists at the bout level, not just per-lane** — users need to understand the system before reading lane details
- [ ] **No score shows "0 confidence"** — confidence of null (legacy) renders as N/A; confidence of 0.0 (unlikely but valid) renders as "very low" not "0%"
- [ ] **Dispute flow captures enough context server-side** — submission ID, lane ID, judge ID, user's stated reason
- [ ] **Final badge is NOT shown on partially-scored results** — even if some lanes are complete, partial = provisional

---

## The Trust Gap: Why Black-Box Scoring Fails

Competitors in an AI evaluation platform have one core vulnerability: they invested real effort (and possibly real money) into a submission, and an AI they've never seen gave it a number. Their instinct is suspicion. If you don't proactively explain *why* and *how*, you don't get trust — you get disputes, churn, and bad word-of-mouth.

**The trust gap has three components:**

1. **Opacity gap**: "I don't know what the AI actually measured"
2. **Evidence gap**: "I don't know if the score is based on what I actually did"
3. **Process gap**: "I don't know if the score is final or might change"

Each gap requires a specific design intervention. Closing all three doesn't require a wall of text — it requires the right signal at the right moment.

**What builds trust — ordered by impact:**
- Specific evidence tied to actual output ("Your agent said: '…' — this reduced the Clarity score")
- Named criteria with plain-language definitions ("Clarity: does the agent communicate its plan?")
- Score lineage ("3 judges scored this; their average was 72.4")
- Honest provisional language ("Preliminary score — may change by up to 5 points")

**What destroys trust immediately:**
- Generic feedback ("The agent could be more clear")
- Score with no evidence at all
- "Final" label on a score that later changes
- Black-box lane names ("fw_003_composite_eval: 6.2")

---

## Evidence vs Inference Labeling

Evidence and inference are categorically different and must be labeled differently.

| Type | Definition | Example | Label |
|------|-----------|---------|-------|
| **Evidence** | Quote, measurement, or annotation directly from the agent's output | "Agent said: 'I'll check the database first'" | 🔎 Evidence |
| **Inference** | Judge's reasoning or interpretation of what the output implies | "The agent appeared to lack a verification step" | 💭 Inference |
| **Metric** | Computed measurement (token count, response time, etc.) | "Response latency: 4.2s" | 📊 Metric |

```tsx
// components/trust/EvidenceBadge.tsx
'use client';

import React from 'react';
import { cn } from '@/lib/utils';

export type EvidenceType = 'evidence' | 'inference' | 'metric';

interface EvidenceBadgeProps {
  type: EvidenceType;
  size?: 'sm' | 'xs';
  className?: string;
}

const config: Record<EvidenceType, { label: string; ariaLabel: string; icon: string; styles: string }> = {
  evidence: {
    label: 'Evidence',
    ariaLabel: 'Evidence — directly quoted from agent output',
    icon: '🔎',
    styles: 'bg-blue-50 text-blue-700 border border-blue-200',
  },
  inference: {
    label: 'Inference',
    ariaLabel: 'Inference — judge interpretation, not a direct quote',
    icon: '💭',
    styles: 'bg-purple-50 text-purple-700 border border-purple-200',
  },
  metric: {
    label: 'Metric',
    ariaLabel: 'Measured metric — computed from agent output',
    icon: '📊',
    styles: 'bg-gray-50 text-gray-600 border border-gray-200',
  },
};

export function EvidenceBadge({ type, size = 'sm', className }: EvidenceBadgeProps) {
  const cfg = config[type];
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full font-medium',
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-1.5 py-0.5 text-[10px]',
        cfg.styles,
        className
      )}
      aria-label={cfg.ariaLabel}
      title={cfg.ariaLabel}
    >
      <span aria-hidden="true">{cfg.icon}</span>
      {cfg.label}
    </span>
  );
}

// Usage in evidence ref display
export function EvidenceRefItem({
  type,
  content,
  judgeId,
  confidence,
}: {
  type: EvidenceType;
  content: string;
  judgeId: string;
  confidence: number | null;
}) {
  return (
    <div className="space-y-1.5 py-3 border-b border-gray-100 last:border-0">
      <div className="flex items-center gap-2 flex-wrap">
        <span className="text-xs font-medium text-gray-500 capitalize">{judgeId}</span>
        <EvidenceBadge type={type} size="xs" />
        {confidence !== null && (
          <span className="text-[10px] text-gray-400">
            {(confidence * 100).toFixed(0)}% confidence
          </span>
        )}
      </div>
      {type === 'evidence' ? (
        <blockquote className="text-sm text-gray-700 leading-relaxed pl-3 border-l-2 border-blue-200 italic">
          "{content}"
        </blockquote>
      ) : (
        <p className="text-sm text-gray-700 leading-relaxed pl-3 border-l-2 border-purple-200">
          {content}
        </p>
      )}
    </div>
  );
}
```

---

## Provisional vs Final Copy Patterns

The scoring lifecycle has three states. Each requires different copy that is honest without being alarming.

| State | When | Badge | Copy pattern |
|-------|------|-------|-------------|
| **Scoring** | Judges actively running | Amber pulsing dot | "Scoring in progress — preliminary results below" |
| **Provisional** | All judges done, aggregation pending / review period active | Amber static badge | "Preliminary score — final in ~2 hours" |
| **Final** | Aggregation complete, review period closed | No badge (silence is final) | No special copy — final is the unremarkable state |

```tsx
// components/trust/ScoreStatusBadge.tsx
'use client';

import React from 'react';
import { cn } from '@/lib/utils';

export type ScoreStatus = 'scoring' | 'provisional' | 'final';

interface ScoreStatusBadgeProps {
  status: ScoreStatus;
  estimatedFinalAt?: Date | null;
}

function formatEta(date: Date): string {
  const diffMs = date.getTime() - Date.now();
  const diffH = Math.round(diffMs / (1000 * 60 * 60));
  if (diffH <= 0) return 'soon';
  if (diffH === 1) return 'in ~1 hour';
  if (diffH < 24) return `in ~${diffH} hours`;
  return `in ~${Math.round(diffH / 24)} days`;
}

export function ScoreStatusBadge({ status, estimatedFinalAt }: ScoreStatusBadgeProps) {
  if (status === 'final') {
    // Final state has no badge — silence signals finality
    return null;
  }

  if (status === 'scoring') {
    return (
      <span
        className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 border border-amber-200 px-2.5 py-1 text-xs font-medium text-amber-700"
        aria-label="Scoring in progress — preliminary results shown"
        role="status"
      >
        <span className="h-1.5 w-1.5 rounded-full bg-amber-400 animate-pulse" aria-hidden="true" />
        Scoring…
      </span>
    );
  }

  // provisional
  const eta = estimatedFinalAt ? formatEta(estimatedFinalAt) : null;
  return (
    <span
      className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 border border-amber-200 px-2.5 py-1 text-xs font-medium text-amber-700"
      aria-label={`Preliminary score${eta ? ` — final expected ${eta}` : ' — may change'}`}
      role="status"
    >
      <span className="h-1.5 w-1.5 rounded-full bg-amber-300" aria-hidden="true" />
      Preliminary{eta ? ` — final ${eta}` : ''}
    </span>
  );
}

// ─── Prose copy patterns for each state ───────────────────────────────────────
// Use these in banners, tooltips, and explanatory text — do not invent new copy.

export const SCORE_STATUS_COPY = {
  scoring: {
    headline: 'Scoring in progress',
    body: 'Your submission is being evaluated. Preliminary scores appear below as judges complete each lane.',
    tooltip: 'These scores are preliminary and may change once all judges complete.',
  },
  provisional: {
    headline: 'Preliminary score',
    body: 'All judges have scored your submission. This score may change slightly during the final aggregation and review period.',
    tooltip: 'Preliminary — final score confirmed after review period closes.',
  },
  final: {
    headline: null,   // no copy needed for final state
    body: null,
    tooltip: 'This score is final.',
  },
} as const;
```

---

## Methodology Disclosure: Tooltip and Drawer Components

Methodology disclosure must be one click away from every scored element. The pattern: a `?` icon triggers a tooltip for brief context and a "Learn more" link opens a drawer with full methodology.

```tsx
// components/trust/MethodologyTooltip.tsx
'use client';

import React, { useState, useRef, useEffect, useCallback } from 'react';
import { cn } from '@/lib/utils';

export interface LaneMethodology {
  laneId: string;
  laneName: string;
  shortDescription: string;  // 1 sentence, plain language
  whatWeScore: string[];      // 3–5 bullet points, plain language
  whatWeDoNotScore: string[]; // 1–3 things explicitly NOT measured
  maxScore: number;
  weight: number;
}

interface MethodologyTooltipProps {
  methodology: LaneMethodology;
  children: React.ReactNode;
}

export function MethodologyTooltip({ methodology, children }: MethodologyTooltipProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [showDrawer, setShowDrawer] = useState(false);
  const triggerRef = useRef<HTMLButtonElement>(null);

  const close = useCallback(() => {
    setIsOpen(false);
    triggerRef.current?.focus();
  }, []);

  useEffect(() => {
    if (!isOpen) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [isOpen, close]);

  return (
    <div className="relative inline-flex items-center gap-1.5">
      {children}
      <button
        ref={triggerRef}
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="h-4 w-4 rounded-full bg-gray-100 text-gray-400 hover:bg-gray-200 hover:text-gray-600 transition-colors flex items-center justify-center text-[10px] font-bold"
        aria-label={`How ${methodology.laneName} is scored`}
        aria-expanded={isOpen}
        aria-haspopup="dialog"
      >
        ?
      </button>

      {isOpen && (
        <>
          {/* Backdrop for click-outside close */}
          <div className="fixed inset-0 z-10" onClick={close} aria-hidden="true" />
          {/* Tooltip popover */}
          <div
            role="dialog"
            aria-label={`${methodology.laneName} scoring methodology`}
            className="absolute bottom-full left-0 z-20 mb-2 w-72 rounded-xl bg-white border border-gray-200 shadow-xl p-4 space-y-3"
          >
            <div>
              <h4 className="text-sm font-semibold text-gray-900">{methodology.laneName}</h4>
              <p className="text-xs text-gray-500 mt-0.5">{methodology.shortDescription}</p>
            </div>
            <div>
              <p className="text-xs font-medium text-gray-700 mb-1.5">What we measure:</p>
              <ul className="space-y-1">
                {methodology.whatWeScore.map((item, i) => (
                  <li key={i} className="text-xs text-gray-600 flex items-start gap-1.5">
                    <span className="text-emerald-500 mt-0.5 shrink-0">✓</span>
                    {item}
                  </li>
                ))}
              </ul>
            </div>
            {methodology.whatWeDoNotScore.length > 0 && (
              <div>
                <p className="text-xs font-medium text-gray-700 mb-1.5">Not scored:</p>
                <ul className="space-y-1">
                  {methodology.whatWeDoNotScore.map((item, i) => (
                    <li key={i} className="text-xs text-gray-400 flex items-start gap-1.5">
                      <span className="shrink-0 mt-0.5">—</span>
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            )}
            <div className="flex items-center justify-between pt-1 border-t border-gray-100">
              <span className="text-xs text-gray-400">
                Max: {methodology.maxScore} · Weight: ×{methodology.weight}
              </span>
              <button
                type="button"
                onClick={() => { setShowDrawer(true); close(); }}
                className="text-xs text-indigo-600 hover:text-indigo-800 font-medium"
              >
                Full methodology →
              </button>
            </div>
          </div>
        </>
      )}

      {showDrawer && (
        <MethodologyDrawer
          methodology={methodology}
          onClose={() => {
            setShowDrawer(false);
            triggerRef.current?.focus();
          }}
        />
      )}
    </div>
  );
}

// Full methodology drawer
function MethodologyDrawer({
  methodology,
  onClose,
}: {
  methodology: LaneMethodology;
  onClose: () => void;
}) {
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [onClose]);

  return (
    <>
      <div className="fixed inset-0 z-30 bg-black/30" onClick={onClose} aria-hidden="true" />
      <div
        role="dialog"
        aria-label={`Full scoring methodology for ${methodology.laneName}`}
        aria-modal="true"
        className="fixed right-0 top-0 z-40 h-full w-full max-w-md bg-white shadow-2xl overflow-y-auto"
      >
        <div className="p-6 space-y-6">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-lg font-bold text-gray-900">{methodology.laneName}</h2>
              <p className="text-sm text-gray-500 mt-1">{methodology.shortDescription}</p>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 text-xl leading-none"
              aria-label="Close methodology"
            >
              ×
            </button>
          </div>

          <section>
            <h3 className="text-sm font-semibold text-gray-900 mb-3">What we measure</h3>
            <ul className="space-y-2">
              {methodology.whatWeScore.map((item, i) => (
                <li key={i} className="flex items-start gap-2 text-sm text-gray-700">
                  <span className="text-emerald-500 mt-0.5 shrink-0">✓</span>
                  {item}
                </li>
              ))}
            </ul>
          </section>

          {methodology.whatWeDoNotScore.length > 0 && (
            <section>
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Not scored in this lane</h3>
              <ul className="space-y-2">
                {methodology.whatWeDoNotScore.map((item, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-gray-500">
                    <span className="shrink-0 mt-0.5">—</span>
                    {item}
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className="rounded-lg bg-gray-50 p-4">
            <h3 className="text-sm font-semibold text-gray-900 mb-2">Scoring weight</h3>
            <p className="text-sm text-gray-600">
              This lane contributes{' '}
              <strong>{((methodology.weight / 1) * 100).toFixed(0)}%</strong>{' '}
              to your overall score, with a maximum of{' '}
              <strong>{methodology.maxScore} points</strong>.
            </p>
          </section>
        </div>
      </div>
    </>
  );
}
```

---

## Scoring Dispute Acknowledgment

When a user thinks a score is wrong, what they need is:
1. To feel heard (acknowledge their question is legitimate)
2. To understand what the platform can and can't do
3. A specific, low-friction path to flag it

```tsx
// components/trust/DisputeButton.tsx
'use client';

import React, { useState } from 'react';
import { z } from 'zod';

const DisputeFormSchema = z.object({
  submissionId: z.string().uuid(),
  laneId: z.string().min(1),
  judgeId: z.string().optional(),
  reason: z.string().min(20, 'Please describe what you believe is incorrect (20+ characters)').max(500),
  userContact: z.string().email().optional(),
});

type DisputeFormData = z.infer<typeof DisputeFormSchema>;

interface DisputeButtonProps {
  submissionId: string;
  laneId: string;
  laneName: string;
  score: number;
  maxScore: number;
}

export function DisputeButton({
  submissionId,
  laneId,
  laneName,
  score,
  maxScore,
}: DisputeButtonProps) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    const parsed = DisputeFormSchema.safeParse({
      submissionId,
      laneId,
      reason,
    });

    if (!parsed.success) {
      setError(parsed.error.errors[0]?.message ?? 'Invalid input');
      return;
    }

    setSubmitting(true);
    try {
      const res = await fetch('/api/disputes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(parsed.data),
      });
      if (!res.ok) throw new Error('Failed to submit');
      setSubmitted(true);
    } catch {
      setError('Failed to submit. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="text-xs text-gray-400 hover:text-gray-600 underline transition-colors"
      >
        Question this score
      </button>
    );
  }

  return (
    <div className="mt-3 rounded-lg bg-gray-50 border border-gray-200 p-4 space-y-3">
      {submitted ? (
        <div className="space-y-1">
          <p className="text-sm font-medium text-gray-900">Your question has been logged.</p>
          <p className="text-xs text-gray-500">
            We review disputes weekly. You'll receive an update via email if we identify a scoring issue.
            Scores are rarely changed, but every question is reviewed.
          </p>
          <button
            type="button"
            onClick={() => { setOpen(false); setSubmitted(false); setReason(''); }}
            className="text-xs text-indigo-600 hover:text-indigo-800 font-medium mt-1"
          >
            Close
          </button>
        </div>
      ) : (
        <>
          <div>
            <p className="text-sm font-semibold text-gray-900">Question this score</p>
            <p className="text-xs text-gray-500 mt-0.5">
              {laneName}: <span className="font-medium text-gray-700">{score}/{maxScore}</span>
            </p>
          </div>
          <p className="text-xs text-gray-500">
            Describe what you believe is incorrect or missing from this evaluation.
            Be specific — vague questions can't be reviewed effectively.
          </p>
          <form onSubmit={handleSubmit} className="space-y-3">
            <textarea
              value={reason}
              onChange={e => setReason(e.target.value)}
              placeholder="e.g., 'The judge cited my agent as missing a verification step, but in line 3 of my output, the agent explicitly calls verify_result() before responding.'"
              className="w-full text-xs rounded-lg border border-gray-200 bg-white px-3 py-2 text-gray-700 placeholder-gray-300 focus:border-indigo-400 focus:outline-none resize-none"
              rows={4}
              maxLength={500}
              aria-label="Describe the scoring issue"
            />
            {error && <p className="text-xs text-red-500">{error}</p>}
            <div className="flex items-center gap-2 justify-end">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="text-xs text-gray-400 hover:text-gray-600"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={submitting || reason.length < 20}
                className="rounded-lg bg-indigo-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {submitting ? 'Submitting…' : 'Submit question'}
              </button>
            </div>
          </form>
        </>
      )}
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Generic "AI may make mistakes" disclaimer instead of specific methodology

```tsx
// BAD — builds zero trust, just creates anxiety
<p className="text-xs text-gray-400">
  Scores are generated by AI and may not be perfectly accurate.
</p>

// GOOD — specific, names what is measured
<MethodologyTooltip methodology={laneMethodology}>
  <span className="text-sm font-medium text-gray-700">{lane.laneName}</span>
</MethodologyTooltip>
```

### ❌ Showing "Final" on partially-scored results

```tsx
// BAD — if any judge is pending, the score is NOT final
const isFinal = result.overallScore !== null;  // WRONG
{isFinal && <span>Final score</span>}

// GOOD
const isFinal = result.isFullyScored && !result.inReviewPeriod;
{isFinal ? null : <ScoreStatusBadge status={result.scoreStatus} />}
// Final state has NO badge — silence signals finality
```

### ❌ Hiding dispute option because you're afraid of disputes

```tsx
// BAD — no dispute path = users feel powerless = distrust compounds
// (just don't render DisputeButton at all — common omission)

// GOOD — dispute option is visible, even if rarely used
<DisputeButton submissionId={id} laneId={lane.laneId} ... />
// The existence of a dispute path signals confidence in the scoring
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Evidence and inference shown with same styling | Users can't tell if a quote is from their agent or a judge opinion | Apply `EvidenceBadge` type classification to every ref |
| Provisional badge on a final score | Users worry their score will change after they've accepted it | Track `score_finalized_at` timestamp; only show provisional badge before it |
| Methodology tooltip without keyboard support | Tab-only users can't access methodology | Add `aria-expanded`, `onKeyDown` for Escape, and focus management |
| Dispute form with no specific lane context | Reviewers can't identify what was questioned | Always pass `submissionId + laneId + score` to dispute form |
| "Score may be wrong" copy instead of honest provisional language | Creates alarm; users assume the platform is unreliable | Use approved copy: "Preliminary — final in ~X hours" |
| Methodology in a FAQ page, not inline | Users don't find it; 95% don't read FAQ | One-click methodology from every lane row |
| Evidence with confidence=0 displayed as "0% confident" | Looks like judge had no basis for the score | `confidence === 0` → "very low confidence"; `confidence === null` → "N/A" |
| No methodology for new lanes added after launch | Existing users see new lane with no explanation | Methodology required in lane config before lane goes live |
| Dispute confirmation copy says "We'll investigate" | Sets expectation of score change; rarely delivered | Use: "Your question has been logged. Scores are rarely changed, but every question is reviewed." |
| Black-box lane IDs like "fw_003" visible to users | Users see technical IDs instead of plain names | Always resolve lane_id → lane_name before rendering; IDs are internal only |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
