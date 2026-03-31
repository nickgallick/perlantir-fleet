---
name: provisional-final-ranking-logic
description: Open-window ranking, provisional placement, finalization triggers, edge case handling (ties, disqualifications, late submissions), rank history storage, and clear status communication for Bouts.
---

# Provisional and Final Ranking Logic

## Review Checklist

1. **Provisional rank is never shown as a definitive number**: The UI must include a visible "provisional" indicator alongside any rank shown during an open window. Verify: `RankStatusBadge` component renders "Provisional" when `rankStatus !== 'final'`.
2. **Ranking query locks on `window_closed_at` timestamp**: Final rankings compute scores only from submissions received before `window_closed_at`. Test: submit at `window_closed_at + 1 second` — verify it's excluded from final rankings.
3. **Minimum submission threshold is enforced before finalizing**: If a bout has fewer than `min_submissions` participants, rankings don't finalize — the window extends or the bout is voided. Verify this check exists in `finalizeRankings()`.
4. **Ties are broken deterministically**: Two submissions with the same score must produce a consistent rank order that doesn't change between page loads. Use `submission.created_at` as the tiebreaker (earlier submission ranks higher). Verify: run ranking query twice — results must be identical.
5. **Disqualification during open window recomputes provisional rankings**: When a submission is disqualified mid-window, all subsequent rank numbers must shift. Verify: disqualify the #1 submission and confirm #2 becomes #1 in the provisional view.
6. **Rank history table is append-only**: Never UPDATE rank_history rows. Each ranking recomputation (provisional or final) inserts new rows. Verify: after a disqualification, `SELECT COUNT(*) FROM rank_history WHERE submission_id = $1` increases.
7. **Admin override finalizes with an explicit audit record**: `finalizeRankings(boutId, { adminOverride: true, reason: '...' })` must insert a row in `ranking_finalization_events` with `trigger_type = 'admin_override'`. Verify this field is non-null.
8. **No rank is displayed for failed evaluations**: A submission with `evaluation_status = 'failed'` must show "Evaluation failed" not a score or rank. Verify: the ranking query filters out `status = 'failed'` submissions.
9. **Window close is idempotent**: Calling `finalizeRankings()` twice on the same bout must not create duplicate rank_history rows or double-send notifications. Add `ON CONFLICT DO NOTHING` or unique constraint.
10. **Percentile calculation excludes disqualified submissions**: A disqualified submission must not count toward the denominator when computing percentile. Verify: with 10 submissions, 2 disqualified, percentile denominator is 8.
11. **Rank display shows the correct timestamp**: Provisional rank cards must show "as of [timestamp]" — not just "provisional". This anchors the user's expectation of when it updates.
12. **Session timing vs window timing is distinct**: A user's evaluation session (how long the agent ran) is separate from the bout window (when submissions are accepted). Verify: the schema separates `evaluation_started_at` from `window_closes_at`.

---

## Provisional vs Final: Technical Definitions

**Provisional** means: the score has been computed, a rank has been assigned based on current standings, but the bout window is still open. More submissions may arrive. The rank number may change.

**Final** means: `window_closed_at` has passed, `min_submissions` threshold was met, and no pending disqualification reviews remain. The rank number is permanent.

A submission can be in these states:
- `evaluating` — score not yet computed
- `scored_provisional` — score computed, window open
- `scored_final` — score computed, window closed, rankings finalized
- `disqualified` — removed from rankings
- `failed` — evaluation failed, no score
- `voided` — bout was cancelled, no final rankings

---

## SQL: Ranking Tables and Window Management

```sql
-- migrations/20260331_rankings.sql

CREATE TABLE bouts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id          UUID NOT NULL REFERENCES challenges(id),
  name                  TEXT NOT NULL,
  status                TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'closed', 'finalized', 'voided')),
  window_opens_at       TIMESTAMPTZ NOT NULL,
  window_closes_at      TIMESTAMPTZ NOT NULL,
  min_submissions       INTEGER NOT NULL DEFAULT 5,
  prize_pool_usd        NUMERIC(12,2),
  on_chain_pool_address TEXT,  -- Base chain address for prize pool
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_window CHECK (window_closes_at > window_opens_at)
);

CREATE TABLE submissions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bout_id               UUID NOT NULL REFERENCES bouts(id),
  user_id               UUID NOT NULL REFERENCES users(id),
  attempt_number        INTEGER NOT NULL DEFAULT 1,
  status                TEXT NOT NULL DEFAULT 'evaluating'
    CHECK (status IN ('evaluating', 'scored_provisional', 'scored_final', 'disqualified', 'failed', 'voided')),
  final_score           NUMERIC(5,2),       -- NULL until evaluated
  adjusted_score        NUMERIC(5,2),       -- NULL until evaluated; score after integrity deductions
  submitted_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  evaluated_at          TIMESTAMPTZ,        -- when score was assigned
  disqualified_at       TIMESTAMPTZ,
  disqualification_reason TEXT,
  UNIQUE (bout_id, user_id, attempt_number)
);

-- Ranking snapshot: each finalization creates a new snapshot
CREATE TABLE rank_snapshots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bout_id         UUID NOT NULL REFERENCES bouts(id),
  snapshot_type   TEXT NOT NULL CHECK (snapshot_type IN ('provisional', 'final')),
  snapshot_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submission_count INTEGER NOT NULL,
  trigger_type    TEXT NOT NULL CHECK (trigger_type IN ('auto_window_close', 'admin_override', 'periodic_refresh')),
  triggered_by    UUID REFERENCES users(id),
  admin_reason    TEXT
);

-- Individual rank assignments per snapshot (append-only)
CREATE TABLE rank_history (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_id       UUID NOT NULL REFERENCES rank_snapshots(id),
  submission_id     UUID NOT NULL REFERENCES submissions(id),
  user_id           UUID NOT NULL REFERENCES users(id),
  bout_id           UUID NOT NULL REFERENCES bouts(id),
  rank_position     INTEGER NOT NULL,  -- 1 = first place
  total_participants INTEGER NOT NULL,
  percentile        NUMERIC(5,2),      -- 0-100, higher = better (100th = top)
  score             NUMERIC(5,2) NOT NULL,
  adjusted_score    NUMERIC(5,2) NOT NULL,
  is_final          BOOLEAN NOT NULL DEFAULT false,
  snapshot_at       TIMESTAMPTZ NOT NULL,
  UNIQUE (snapshot_id, submission_id)
);

-- Finalization event log
CREATE TABLE ranking_finalization_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bout_id       UUID NOT NULL REFERENCES bouts(id),
  triggered_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  trigger_type  TEXT NOT NULL,
  triggered_by  UUID REFERENCES users(id),
  admin_reason  TEXT,
  success       BOOLEAN NOT NULL,
  error_message TEXT,
  rank_count    INTEGER
);

-- Indexes
CREATE INDEX idx_submissions_bout_status ON submissions(bout_id, status);
CREATE INDEX idx_submissions_user_bout ON submissions(user_id, bout_id);
CREATE INDEX idx_rank_history_submission ON rank_history(submission_id, is_final);
CREATE INDEX idx_rank_history_bout_final ON rank_history(bout_id, is_final, rank_position);
CREATE INDEX idx_rank_snapshots_bout ON rank_snapshots(bout_id, snapshot_type, snapshot_at DESC);
CREATE INDEX idx_bouts_status_closes ON bouts(status, window_closes_at);

-- View: current rank for each submission (most recent snapshot)
CREATE VIEW current_ranks AS
SELECT DISTINCT ON (rh.submission_id)
  rh.submission_id,
  rh.user_id,
  rh.bout_id,
  rh.rank_position,
  rh.total_participants,
  rh.percentile,
  rh.score,
  rh.adjusted_score,
  rh.is_final,
  rh.snapshot_at,
  rs.snapshot_type,
  rs.trigger_type
FROM rank_history rh
JOIN rank_snapshots rs ON rs.id = rh.snapshot_id
ORDER BY rh.submission_id, rh.snapshot_at DESC;
```

---

## TypeScript: Rank Computation Engine

```typescript
// lib/rankings/rank-engine.ts
import { createClient } from '@/lib/supabase/server';

export interface RankComputationInput {
  boutId: string;
  snapshotType: 'provisional' | 'final';
  triggerType: 'auto_window_close' | 'admin_override' | 'periodic_refresh';
  triggeredBy?: string;
  adminReason?: string;
}

export interface ComputedRank {
  submissionId: string;
  userId: string;
  rankPosition: number;
  totalParticipants: number;
  percentile: number;
  score: number;
  adjustedScore: number;
}

export interface RankComputationResult {
  snapshotId: string;
  boutId: string;
  rankedSubmissions: ComputedRank[];
  isFinal: boolean;
  computedAt: string;
}

export async function computeRankings(
  input: RankComputationInput
): Promise<RankComputationResult> {
  const supabase = createClient();

  // 1. Verify bout exists and is in correct state
  const { data: bout, error: boutError } = await supabase
    .from('bouts')
    .select('id, status, window_closes_at, min_submissions')
    .eq('id', input.boutId)
    .single();

  if (boutError || !bout) {
    throw new Error(`Bout not found: ${input.boutId}`);
  }

  if (input.snapshotType === 'final' && bout.status === 'finalized') {
    throw new Error(`Bout ${input.boutId} is already finalized`);
  }

  // 2. For final rankings: verify window is closed
  if (input.snapshotType === 'final') {
    const now = new Date();
    const windowClose = new Date(bout.window_closes_at);
    if (now < windowClose && input.triggerType !== 'admin_override') {
      throw new Error(`Cannot finalize: window closes at ${bout.window_closes_at}`);
    }
  }

  // 3. Fetch eligible submissions
  // - scored (not evaluating, not failed, not voided)
  // - not disqualified
  // - submitted before window_closes_at (for final)
  const statusFilter = ['scored_provisional', 'scored_final'];
  if (input.snapshotType === 'provisional') {
    statusFilter.push('scored_provisional');
  }

  let query = supabase
    .from('submissions')
    .select('id, user_id, adjusted_score, final_score, submitted_at')
    .eq('bout_id', input.boutId)
    .in('status', ['scored_provisional', 'scored_final'])
    .not('adjusted_score', 'is', null);

  if (input.snapshotType === 'final') {
    // Only submissions received before window close
    query = query.lte('submitted_at', bout.window_closes_at);
  }

  const { data: submissions, error: subError } = await query;

  if (subError) {
    throw new Error(`Failed to fetch submissions: ${subError.message}`);
  }

  const eligible = submissions ?? [];

  // 4. Check minimum threshold for final rankings
  if (input.snapshotType === 'final' && eligible.length < bout.min_submissions) {
    // Log the failure and throw
    await supabase.from('ranking_finalization_events').insert({
      bout_id: input.boutId,
      trigger_type: input.triggerType,
      triggered_by: input.triggeredBy ?? null,
      admin_reason: input.adminReason ?? null,
      success: false,
      error_message: `Insufficient submissions: ${eligible.length} < ${bout.min_submissions}`,
      rank_count: eligible.length,
    });
    throw new Error(
      `Cannot finalize: only ${eligible.length} submissions, minimum is ${bout.min_submissions}`
    );
  }

  // 5. Sort: by adjusted_score DESC, then submitted_at ASC (earlier wins tiebreak)
  const sorted = [...eligible].sort((a, b) => {
    const scoreDiff = (b.adjusted_score ?? 0) - (a.adjusted_score ?? 0);
    if (scoreDiff !== 0) return scoreDiff;
    // Tiebreaker: earlier submission wins (better rank)
    return new Date(a.submitted_at).getTime() - new Date(b.submitted_at).getTime();
  });

  const total = sorted.length;
  const isFinal = input.snapshotType === 'final';

  // 6. Assign ranks and compute percentiles
  const rankedSubmissions: ComputedRank[] = sorted.map((sub, i) => {
    const rankPosition = i + 1;
    // Percentile: what percent of participants scored below you
    // Rank 1 of 10 = 100th percentile, Rank 10 of 10 = 10th percentile
    const percentile = parseFloat(
      (((total - rankPosition) / (total - 1 || 1)) * 100).toFixed(2)
    );

    return {
      submissionId: sub.id,
      userId: sub.user_id,
      rankPosition,
      totalParticipants: total,
      percentile,
      score: sub.final_score ?? 0,
      adjustedScore: sub.adjusted_score ?? 0,
    };
  });

  // 7. Create snapshot
  const { data: snapshot, error: snapError } = await supabase
    .from('rank_snapshots')
    .insert({
      bout_id: input.boutId,
      snapshot_type: input.snapshotType,
      submission_count: total,
      trigger_type: input.triggerType,
      triggered_by: input.triggeredBy ?? null,
      admin_reason: input.adminReason ?? null,
    })
    .select('id')
    .single();

  if (snapError || !snapshot) {
    throw new Error(`Failed to create rank snapshot: ${snapError?.message}`);
  }

  // 8. Insert rank_history rows (append-only)
  const historyRows = rankedSubmissions.map((r) => ({
    snapshot_id: snapshot.id,
    submission_id: r.submissionId,
    user_id: r.userId,
    bout_id: input.boutId,
    rank_position: r.rankPosition,
    total_participants: r.totalParticipants,
    percentile: r.percentile,
    score: r.score,
    adjusted_score: r.adjustedScore,
    is_final: isFinal,
    snapshot_at: new Date().toISOString(),
  }));

  const { error: historyError } = await supabase
    .from('rank_history')
    .insert(historyRows);

  if (historyError) {
    throw new Error(`Failed to insert rank history: ${historyError.message}`);
  }

  // 9. If final, update bout status and submission statuses
  if (isFinal) {
    await supabase
      .from('bouts')
      .update({ status: 'finalized' })
      .eq('id', input.boutId);

    await supabase
      .from('submissions')
      .update({ status: 'scored_final' })
      .eq('bout_id', input.boutId)
      .eq('status', 'scored_provisional');

    await supabase.from('ranking_finalization_events').insert({
      bout_id: input.boutId,
      trigger_type: input.triggerType,
      triggered_by: input.triggeredBy ?? null,
      admin_reason: input.adminReason ?? null,
      success: true,
      rank_count: total,
    });
  }

  return {
    snapshotId: snapshot.id,
    boutId: input.boutId,
    rankedSubmissions,
    isFinal,
    computedAt: new Date().toISOString(),
  };
}

// ---- Load current rank for a single submission ----

export interface CurrentRankView {
  rankPosition: number;
  totalParticipants: number;
  percentile: number;
  score: number;
  adjustedScore: number;
  isFinal: boolean;
  snapshotAt: string;
  snapshotType: 'provisional' | 'final';
}

export async function getCurrentRank(
  submissionId: string
): Promise<CurrentRankView | null> {
  const supabase = createClient();

  const { data } = await supabase
    .from('current_ranks')
    .select('*')
    .eq('submission_id', submissionId)
    .single();

  if (!data) return null;

  return {
    rankPosition: data.rank_position,
    totalParticipants: data.total_participants,
    percentile: data.percentile,
    score: data.score,
    adjustedScore: data.adjusted_score,
    isFinal: data.is_final,
    snapshotAt: data.snapshot_at,
    snapshotType: data.snapshot_type,
  };
}

// ---- Edge case: disqualification mid-window ----

export async function disqualifySubmission(
  submissionId: string,
  reason: string,
  adminUserId: string
): Promise<void> {
  const supabase = createClient();

  // 1. Update submission status
  const { data: sub } = await supabase
    .from('submissions')
    .update({
      status: 'disqualified',
      disqualified_at: new Date().toISOString(),
      disqualification_reason: reason,
    })
    .eq('id', submissionId)
    .select('bout_id')
    .single();

  if (!sub) throw new Error(`Submission ${submissionId} not found`);

  // 2. Recompute provisional rankings (everyone shifts)
  const { data: bout } = await supabase
    .from('bouts')
    .select('status')
    .eq('id', sub.bout_id)
    .single();

  if (bout?.status === 'open') {
    // Trigger provisional recomputation
    await computeRankings({
      boutId: sub.bout_id,
      snapshotType: 'provisional',
      triggerType: 'admin_override',
      triggeredBy: adminUserId,
      adminReason: `Disqualification of submission ${submissionId}: ${reason}`,
    });
  }
}
```

---

## TSX: Rank Status Display Components

```tsx
// components/rankings/RankStatusBadge.tsx
'use client';

interface RankStatusBadgeProps {
  isFinal: boolean;
  snapshotAt: string;
  snapshotType: 'provisional' | 'final';
}

export function RankStatusBadge({ isFinal, snapshotAt, snapshotType }: RankStatusBadgeProps) {
  const displayTime = new Date(snapshotAt).toLocaleString('en-US', {
    month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
  });

  if (isFinal) {
    return (
      <span className="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-700 bg-emerald-100 px-2.5 py-1 rounded-full">
        <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full" />
        Final · Ranked {displayTime}
      </span>
    );
  }

  return (
    <span className="inline-flex items-center gap-1.5 text-xs font-medium text-amber-700 bg-amber-100 px-2.5 py-1 rounded-full">
      <span className="w-1.5 h-1.5 bg-amber-400 rounded-full animate-pulse" />
      Provisional · as of {displayTime}
    </span>
  );
}

// components/rankings/RankCard.tsx
'use client';

import { RankStatusBadge } from './RankStatusBadge';

interface RankCardProps {
  rankPosition: number;
  totalParticipants: number;
  percentile: number;
  isFinal: boolean;
  snapshotAt: string;
  snapshotType: 'provisional' | 'final';
  windowClosesAt?: string;  // null if finalized
}

export function RankCard({
  rankPosition,
  totalParticipants,
  percentile,
  isFinal,
  snapshotAt,
  snapshotType,
  windowClosesAt,
}: RankCardProps) {
  const isTopTen = rankPosition <= 10;
  const isTopThree = rankPosition <= 3;

  return (
    <div className={`bg-white border rounded-xl p-5 ${
      isTopThree ? 'border-amber-300 shadow-sm shadow-amber-100' : 'border-gray-200'
    }`}>
      <div className="flex items-start justify-between mb-3">
        <div>
          <p className="text-xs text-gray-500 font-medium mb-1">Your Ranking</p>
          <div className="flex items-baseline gap-2">
            <span className={`text-4xl font-black tabular-nums ${
              isTopThree ? 'text-amber-600' :
              isTopTen ? 'text-indigo-600' : 'text-gray-700'
            }`}>
              #{rankPosition}
            </span>
            <span className="text-sm text-gray-400 font-medium">
              of {totalParticipants}
            </span>
          </div>
        </div>
        <RankStatusBadge
          isFinal={isFinal}
          snapshotAt={snapshotAt}
          snapshotType={snapshotType}
        />
      </div>

      {isFinal && (
        <div className="mb-3">
          <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
            <span>Percentile</span>
            <span className="font-medium text-gray-700">{percentile.toFixed(0)}th</span>
          </div>
          <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-indigo-500 rounded-full"
              style={{ width: `${percentile}%` }}
            />
          </div>
        </div>
      )}

      {!isFinal && windowClosesAt && (
        <WindowCountdown windowClosesAt={windowClosesAt} />
      )}

      {!isFinal && (
        <p className="text-xs text-gray-400 mt-2">
          Rankings update as new submissions are evaluated. Final positions lock when the window closes.
        </p>
      )}
    </div>
  );
}

function WindowCountdown({ windowClosesAt }: { windowClosesAt: string }) {
  // Client-side countdown — simplified, use a proper countdown hook in production
  const closeDate = new Date(windowClosesAt);
  const now = new Date();
  const diffMs = closeDate.getTime() - now.getTime();
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffMins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

  if (diffMs <= 0) {
    return (
      <div className="text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded px-2 py-1 mt-2">
        Window closing — rankings finalizing soon
      </div>
    );
  }

  return (
    <div className="flex items-center gap-1.5 text-xs text-gray-500 mt-2">
      <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
          d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      Window closes in {diffHours > 0 ? `${diffHours}h ` : ''}{diffMins}m
    </div>
  );
}
```

---

## Anti-Patterns

### Anti-Pattern 1: Showing percentile during open window

```typescript
// ❌ BAD: Percentile changes every hour as new submissions arrive
// User sees "82nd percentile" then refreshes and sees "71st percentile" — trust destroyed
function UserRank({ submissionId }: { submissionId: string }) {
  const rank = useCurrentRank(submissionId);
  return <div>You're in the {rank.percentile}th percentile</div>;
}

// ✅ GOOD: Only show percentile when final
function UserRank({ submissionId }: { submissionId: string }) {
  const rank = useCurrentRank(submissionId);
  return (
    <div>
      <div>Rank #{rank.rankPosition} of {rank.totalParticipants}</div>
      {rank.isFinal && <div>{rank.percentile}th percentile</div>}
      {!rank.isFinal && <div>Percentile available after window closes</div>}
    </div>
  );
}
```

### Anti-Pattern 2: Updating rank_history rows on recomputation

```typescript
// ❌ BAD: Updates destroy the history; can't audit rank changes over time
await supabase
  .from('rank_history')
  .update({ rank_position: newRank })
  .eq('submission_id', submissionId);

// ✅ GOOD: Always insert new snapshot rows; history is append-only
// Use the current_ranks VIEW to get the latest; never modify historical rows
const newSnapshot = await computeRankings({ boutId, snapshotType: 'provisional', ... });
// New rows inserted in rank_history; old rows preserved unchanged
```

### Anti-Pattern 3: Tiebreaker that changes between calls

```typescript
// ❌ BAD: Non-deterministic tiebreaker; rank order changes on every load
const sorted = submissions.sort((a, b) => b.adjusted_score - a.adjusted_score);
// When scores are equal, sort is implementation-dependent — may differ across JS engines

// ✅ GOOD: Explicit, deterministic tiebreaker
const sorted = [...submissions].sort((a, b) => {
  const scoreDiff = b.adjusted_score - a.adjusted_score;
  if (scoreDiff !== 0) return scoreDiff;
  // Tiebreaker: earlier submission (submitted_at ASC) wins
  return new Date(a.submitted_at).getTime() - new Date(b.submitted_at).getTime();
});
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| `finalizeRankings()` called twice (race condition) | Duplicate rank_history rows; rank_position duplicated for same submission | Add `UNIQUE (snapshot_id, submission_id)` in rank_history; add idempotency check at API layer |
| Late submission included in final rankings | Submission at T+5s appears in final rankings with earlier `submitted_at` | Always filter `submitted_at <= window_closes_at` for final queries; add DB constraint check |
| Disqualified submission counted in percentile denominator | Percentile inflated; user at rank 5 of 10 shows 50th percentile instead of correct lower rank | Filter `status = 'disqualified'` from rank computation; recalculate total_participants |
| Provisional rank shown without staleness notice | User sees rank from 6 hours ago thinking it's current | Always show `snapshotAt` timestamp; add real-time subscription or auto-refresh every 5 min |
| Min submission threshold not checked before finalization | Bout with 2 submissions finalizes; prizes distributed to tiny pool | Enforce `eligible.length < bout.min_submissions` check and throw before any snapshot creation |
| Admin override creates no audit record | Can't trace why rankings finalized early; compliance issue | `ranking_finalization_events` insert with `trigger_type = 'admin_override'` is mandatory |
| Rank 1 gets percentile of Infinity (N=1 case) | `((1 - 1) / (1 - 1)) * 100` = NaN | Guard: `totalParticipants <= 1 ? 100 : calculation`; add N=1 test case |
| `computeRankings()` called from client component | Rankings recalculated on every page load; wrong computation context | `computeRankings()` is a server-only function; only call from API routes or server actions |
| Session timing conflated with window timing | Evaluation session timeout causes submission to miss window | `evaluation_timeout` and `window_closes_at` are independent; submission timestamp is when submitted, not when evaluated |
| `bout.status` not updated to 'finalized' after final rankings | Rankings are final but bout shows 'open'; new submissions still accepted | Wrap status update and ranking computation in same transaction or add post-rank-finalization status update |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
