---
name: self-improving-feedback-instrumentation
description: Track which feedback blocks users actually engage with — expand, copy, revisit, dwell on — and use that engagement signal to improve feedback structure over time without compromising user trust.
---

# Self-Improving Feedback Instrumentation

## Review Checklist

- [ ] `expand` events fire once per panel open, not on every re-render — confirm event deduplication using a `useRef` flag or React `useEffect` with a stable ID dependency
- [ ] `copy` events capture WHICH coaching item was copied (item_id or item_index), not just "a copy happened" — check the event payload
- [ ] Scroll depth instrumentation uses IntersectionObserver, not `scroll` event listeners — scroll listeners at 60fps will destroy performance on mobile
- [ ] All engagement events are written to `engagement_events` as INSERTS only — no user-identifiable data (no user_id) in the payload — confirm schema has no user FK
- [ ] `session_id` is a client-generated UUID (stored in sessionStorage, not localStorage) — expires per session, not permanently linked to a user
- [ ] Aggregate queries group by `block_type` AND `challenge_id` — a feedback block performing well on challenge A may tank on challenge B
- [ ] The feedback loop document (signal → hypothesis → test → measure) is written in code comments in the analytics query file, not just Notion — it needs to live with the code
- [ ] Engagement event writes are fire-and-forget (non-blocking) — never `await` them in the critical render path
- [ ] TSX instrumentation wrapper catches and suppresses errors — a broken analytics event must never crash the feedback UI
- [ ] Dwell time is computed from `focus_start` → `focus_end` using Page Visibility API — tab-switching must not inflate dwell time
- [ ] Aggregate queries use `COUNT(DISTINCT session_id)` not `COUNT(*)` for user-centric metrics — one user expanding a panel 3 times counts as 1
- [ ] No PII in event properties — check that `content_preview` fields are truncated and no email/name/agent submission text is stored

---

## What to Instrument — The Five Engagement Signals

Not all engagement is equal. These are the five signals that actually tell you whether feedback is working:

**1. Expand events on evidence panels** — A user opening an evidence panel means the top-level score wasn't enough; they needed justification. High expand rates = either the score is surprising (good) or users don't trust it (bad). Distinguishable by whether they then revisit the page.

**2. Copy events on coaching items** — The strongest signal. A user copying a coaching item means they believe it's actionable enough to use outside the platform. Low copy rate = coaching items are too generic.

**3. Revisit rate on breakdown page** — Users who return to the breakdown page after their initial session are still processing the feedback. High revisit rate = the feedback had staying power. Low revisit rate = one-and-done, no lasting impact.

**4. Scroll depth on lane sections** — Did users scroll past the first two lanes? Low scroll depth on lane sections means the top content consumed their attention and they never reached what might be more useful lower content.

**5. Dwell time on feedback blocks** — Time spent reading a specific block. Short dwell + no copy = content not landing. Long dwell + copy = high-value content.

**SQL Schema: `engagement_events`**

```sql
CREATE TABLE engagement_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- NO user_id — privacy-safe by design
  session_id TEXT NOT NULL, -- client-generated UUID per browser session
  bout_id UUID, -- which bout this feedback is for (FK optional, can be NULL for safety)
  challenge_id UUID, -- FK to challenges table for per-challenge breakdowns
  block_type TEXT NOT NULL, -- 'evidence_panel' | 'coaching_item' | 'lane_section' | 'breakdown_page'
  block_id TEXT NOT NULL, -- specific panel/item/lane identifier: 'planning_evidence', 'coach_1', etc.
  event_type TEXT NOT NULL, -- 'expand' | 'copy' | 'revisit' | 'scroll_depth' | 'dwell_end'
  dwell_ms INTEGER, -- non-null for dwell_end events
  scroll_pct INTEGER, -- 0-100, non-null for scroll_depth events
  metadata JSONB DEFAULT '{}'::jsonb, -- non-PII extras: { item_index: 2, lane: "planning" }
  occurred_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fast aggregate queries
CREATE INDEX idx_engagement_block_type ON engagement_events(block_type, event_type, occurred_at DESC);
CREATE INDEX idx_engagement_challenge ON engagement_events(challenge_id, block_type, occurred_at DESC);
CREATE INDEX idx_engagement_bout ON engagement_events(bout_id, event_type, occurred_at DESC);

-- Partition by month for scale (add when volume > 10M/month)
-- ALTER TABLE engagement_events PARTITION BY RANGE (occurred_at);
```

---

## TypeScript Instrumentation Hooks — Non-Blocking, Privacy-Safe

The instrumentation layer must be completely invisible to the user. Events fire and forget. Errors are silently caught. No event ever blocks rendering or awaits a server response.

**Core Event Client**

```typescript
// lib/feedback-instrumentation.ts
import { v4 as uuidv4 } from 'uuid';

export type BlockType = 'evidence_panel' | 'coaching_item' | 'lane_section' | 'breakdown_page';
export type EventType = 'expand' | 'copy' | 'revisit' | 'scroll_depth' | 'dwell_end';

interface EngagementEvent {
  session_id: string;
  bout_id?: string;
  challenge_id?: string;
  block_type: BlockType;
  block_id: string;
  event_type: EventType;
  dwell_ms?: number;
  scroll_pct?: number;
  metadata?: Record<string, string | number | boolean>;
}

function getSessionId(): string {
  try {
    const stored = sessionStorage.getItem('bouts_session_id');
    if (stored) return stored;
    const fresh = uuidv4();
    sessionStorage.setItem('bouts_session_id', fresh);
    return fresh;
  } catch {
    // sessionStorage blocked (iframe, privacy mode) — use ephemeral ID
    return uuidv4();
  }
}

export async function trackEngagement(event: Omit<EngagementEvent, 'session_id'>): Promise<void> {
  const payload: EngagementEvent = {
    ...event,
    session_id: getSessionId(),
  };

  // Fire and forget — never await this in render path
  fetch('/api/engagement', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    // keepalive ensures event fires even if page unloads
    keepalive: true,
  }).catch(() => {
    // Silently discard — analytics must never crash the app
  });
}
```

**React Hook: `useExpandTracking`**

```typescript
// hooks/useExpandTracking.ts
import { useRef, useCallback } from 'react';
import { trackEngagement } from '@/lib/feedback-instrumentation';

export function useExpandTracking(params: {
  boutId?: string;
  challengeId?: string;
  blockType: 'evidence_panel' | 'lane_section';
  blockId: string;
  metadata?: Record<string, string | number | boolean>;
}) {
  const hasTracked = useRef(false);

  const trackExpand = useCallback(() => {
    // Only track FIRST expand per mount — prevents re-fire on re-renders
    if (hasTracked.current) return;
    hasTracked.current = true;

    trackEngagement({
      bout_id: params.boutId,
      challenge_id: params.challengeId,
      block_type: params.blockType,
      block_id: params.blockId,
      event_type: 'expand',
      metadata: params.metadata,
    });
  }, [params.boutId, params.challengeId, params.blockType, params.blockId, params.metadata]);

  return { trackExpand };
}
```

**React Hook: `useDwellTracking`**

```typescript
// hooks/useDwellTracking.ts
import { useEffect, useRef } from 'react';
import { trackEngagement } from '@/lib/feedback-instrumentation';

export function useDwellTracking(params: {
  boutId?: string;
  challengeId?: string;
  blockType: 'evidence_panel' | 'coaching_item' | 'lane_section';
  blockId: string;
}) {
  const startRef = useRef<number | null>(null);
  const hiddenRef = useRef(false);

  useEffect(() => {
    // Start dwell timer when element mounts
    startRef.current = Date.now();

    // Pause timer when tab is hidden (Page Visibility API)
    const handleVisibilityChange = () => {
      if (document.hidden) {
        hiddenRef.current = true;
        // Record partial dwell when tab hides
        if (startRef.current !== null) {
          const partialDwell = Date.now() - startRef.current;
          startRef.current = null;
          trackEngagement({
            bout_id: params.boutId,
            challenge_id: params.challengeId,
            block_type: params.blockType,
            block_id: params.blockId,
            event_type: 'dwell_end',
            dwell_ms: partialDwell,
            metadata: { reason: 'tab_hidden' },
          });
        }
      } else {
        // Resume timer when tab becomes visible again
        hiddenRef.current = false;
        startRef.current = Date.now();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      // Fire dwell_end when component unmounts (user navigated away)
      if (startRef.current !== null && !hiddenRef.current) {
        const dwell = Date.now() - startRef.current;
        if (dwell > 500) { // Ignore sub-500ms flashes
          trackEngagement({
            bout_id: params.boutId,
            challenge_id: params.challengeId,
            block_type: params.blockType,
            block_id: params.blockId,
            event_type: 'dwell_end',
            dwell_ms: dwell,
            metadata: { reason: 'unmount' },
          });
        }
      }
    };
  }, [params.boutId, params.challengeId, params.blockType, params.blockId]);
}
```

**Engagement API Route**

```typescript
// /app/api/engagement/route.ts
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

// Use anon key — engagement is unauthenticated writes
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

const EngagementSchema = z.object({
  session_id: z.string().min(1).max(100),
  bout_id: z.string().uuid().optional(),
  challenge_id: z.string().uuid().optional(),
  block_type: z.enum(['evidence_panel', 'coaching_item', 'lane_section', 'breakdown_page']),
  block_id: z.string().min(1).max(100),
  event_type: z.enum(['expand', 'copy', 'revisit', 'scroll_depth', 'dwell_end']),
  dwell_ms: z.number().int().min(0).max(3_600_000).optional(), // max 1 hour
  scroll_pct: z.number().int().min(0).max(100).optional(),
  metadata: z.record(z.union([z.string(), z.number(), z.boolean()])).optional(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const parsed = EngagementSchema.safeParse(body);
    if (!parsed.success) {
      // Return 200 even on validation error — don't block the client
      return NextResponse.json({ ok: false }, { status: 200 });
    }

    await supabase.from('engagement_events').insert(parsed.data);
    return NextResponse.json({ ok: true }, { status: 200 });
  } catch {
    // Always return 200 — client must never retry on errors
    return NextResponse.json({ ok: false }, { status: 200 });
  }
}
```

---

## Aggregate Queries — From Signal to Insight

Raw events are noise. Aggregated, they become structure improvement signals.

**Feedback Block Performance Report**

```sql
-- Which feedback blocks have highest engagement, by challenge?
WITH block_sessions AS (
  SELECT
    challenge_id,
    block_type,
    block_id,
    COUNT(DISTINCT session_id) AS unique_sessions,
    COUNT(*) FILTER (WHERE event_type = 'expand') AS expand_count,
    COUNT(*) FILTER (WHERE event_type = 'copy') AS copy_count,
    AVG(dwell_ms) FILTER (WHERE event_type = 'dwell_end') AS avg_dwell_ms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY scroll_pct)
      FILTER (WHERE event_type = 'scroll_depth') AS median_scroll_pct
  FROM engagement_events
  WHERE occurred_at >= NOW() - INTERVAL '30 days'
    AND challenge_id IS NOT NULL
  GROUP BY challenge_id, block_type, block_id
)
SELECT
  bs.*,
  -- Engagement rate = % of sessions that expanded this block
  ROUND((bs.expand_count::FLOAT / NULLIF(bs.unique_sessions, 0) * 100)::NUMERIC, 1) AS expand_rate_pct,
  -- Copy rate = % of sessions that copied from this block
  ROUND((bs.copy_count::FLOAT / NULLIF(bs.unique_sessions, 0) * 100)::NUMERIC, 1) AS copy_rate_pct,
  -- Signal interpretation
  CASE
    WHEN bs.expand_count::FLOAT / NULLIF(bs.unique_sessions, 0) > 0.6
      THEN 'HIGH_DEMAND — users want more here'
    WHEN bs.copy_count::FLOAT / NULLIF(bs.unique_sessions, 0) > 0.3
      THEN 'HIGH_VALUE — content is actionable'
    WHEN COALESCE(bs.avg_dwell_ms, 0) < 2000
      THEN 'LOW_DWELL — content not landing'
    ELSE 'NORMAL'
  END AS signal_interpretation
FROM block_sessions bs
ORDER BY challenge_id, expand_rate_pct DESC;
```

**Revisit Rate Query**

```sql
-- How many sessions return to the breakdown page after their first visit?
WITH first_visits AS (
  SELECT
    bout_id,
    session_id,
    MIN(occurred_at) AS first_visit
  FROM engagement_events
  WHERE block_type = 'breakdown_page'
    AND event_type = 'revisit'
  GROUP BY bout_id, session_id
),
revisits AS (
  SELECT
    ee.bout_id,
    ee.session_id,
    COUNT(*) AS visit_count
  FROM engagement_events ee
  JOIN first_visits fv ON ee.bout_id = fv.bout_id AND ee.session_id = fv.session_id
  WHERE ee.block_type = 'breakdown_page'
    AND ee.event_type = 'revisit'
    AND ee.occurred_at > fv.first_visit
  GROUP BY ee.bout_id, ee.session_id
)
SELECT
  fv.bout_id,
  COUNT(DISTINCT fv.session_id) AS total_sessions,
  COUNT(DISTINCT r.session_id) AS revisiting_sessions,
  ROUND(
    COUNT(DISTINCT r.session_id)::FLOAT / NULLIF(COUNT(DISTINCT fv.session_id), 0) * 100,
    1
  ) AS revisit_rate_pct
FROM first_visits fv
LEFT JOIN revisits r ON fv.bout_id = r.bout_id AND fv.session_id = r.session_id
GROUP BY fv.bout_id
ORDER BY revisit_rate_pct DESC;
```

---

## TSX Instrumentation Wrapper Components

**EvidencePanelWithTracking**

```tsx
// components/feedback/EvidencePanelWithTracking.tsx
'use client';

import { useState, useCallback } from 'react';
import { ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/outline';
import { useExpandTracking } from '@/hooks/useExpandTracking';
import { useDwellTracking } from '@/hooks/useDwellTracking';
import { cn } from '@/lib/utils';

interface Evidence {
  id: string;
  quote: string;
  explanation: string;
  lane: string;
}

interface EvidencePanelWithTrackingProps {
  panelId: string;
  lane: string;
  evidenceItems: Evidence[];
  boutId?: string;
  challengeId?: string;
}

export function EvidencePanelWithTracking({
  panelId,
  lane,
  evidenceItems,
  boutId,
  challengeId,
}: EvidencePanelWithTrackingProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const { trackExpand } = useExpandTracking({
    boutId,
    challengeId,
    blockType: 'evidence_panel',
    blockId: panelId,
    metadata: { lane, evidence_count: evidenceItems.length },
  });

  useDwellTracking({
    boutId,
    challengeId,
    blockType: 'evidence_panel',
    blockId: panelId,
  });

  const handleToggle = useCallback(() => {
    if (!isExpanded) {
      trackExpand();
    }
    setIsExpanded(prev => !prev);
  }, [isExpanded, trackExpand]);

  return (
    <div className="border border-gray-200 rounded-lg overflow-hidden">
      <button
        onClick={handleToggle}
        className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 transition-colors text-left"
      >
        <span className="text-sm font-medium text-gray-700">
          Evidence ({evidenceItems.length} {evidenceItems.length === 1 ? 'item' : 'items'})
        </span>
        {isExpanded
          ? <ChevronUpIcon className="h-4 w-4 text-gray-500" />
          : <ChevronDownIcon className="h-4 w-4 text-gray-500" />
        }
      </button>
      {isExpanded && (
        <div className="divide-y divide-gray-100">
          {evidenceItems.map((ev, idx) => (
            <div key={ev.id} className="px-4 py-3">
              <blockquote className="text-sm text-gray-700 italic border-l-2 border-blue-300 pl-3 mb-2">
                "{ev.quote}"
              </blockquote>
              <p className="text-sm text-gray-600">{ev.explanation}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

**CoachingItemWithCopyTracking**

```tsx
// components/feedback/CoachingItemWithCopyTracking.tsx
'use client';

import { useCallback } from 'react';
import { ClipboardDocumentIcon } from '@heroicons/react/24/outline';
import { trackEngagement } from '@/lib/feedback-instrumentation';

interface CoachingItemWithCopyTrackingProps {
  itemId: string;
  itemIndex: number;
  text: string;
  lane: string;
  boutId?: string;
  challengeId?: string;
}

export function CoachingItemWithCopyTracking({
  itemId,
  itemIndex,
  text,
  lane,
  boutId,
  challengeId,
}: CoachingItemWithCopyTrackingProps) {
  const handleCopy = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      // Clipboard API unavailable — continue without copy
    }

    // Track the copy event (fire and forget — never await in handler)
    trackEngagement({
      bout_id: boutId,
      challenge_id: challengeId,
      block_type: 'coaching_item',
      block_id: itemId,
      event_type: 'copy',
      metadata: { item_index: itemIndex, lane },
    });
  }, [itemId, itemIndex, text, lane, boutId, challengeId]);

  return (
    <div className="flex items-start gap-3 p-3 bg-amber-50 border border-amber-200 rounded-lg group">
      <div className="flex-1 text-sm text-amber-900">{text}</div>
      <button
        onClick={handleCopy}
        className="opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded hover:bg-amber-100"
        title="Copy coaching item"
      >
        <ClipboardDocumentIcon className="h-4 w-4 text-amber-600" />
      </button>
    </div>
  );
}
```

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Storing user_id in engagement events

```typescript
// BAD — links engagement behavior to real users; GDPR/privacy nightmare
await supabase.from('engagement_events').insert({
  user_id: session.user.id,  // ← real user identity
  bout_id: boutId,
  event_type: 'expand',
  block_id: 'planning_evidence',
});
```

```typescript
// GOOD — session_id is a per-session UUID, not linked to any user account
// No way to reconstruct individual behavior from the events table
await supabase.from('engagement_events').insert({
  session_id: getSessionId(), // generated in browser sessionStorage
  bout_id: boutId,
  event_type: 'expand',
  block_id: 'planning_evidence',
});
```

---

### ❌ Anti-Pattern 2: Awaiting engagement writes in render path

```typescript
// BAD — a slow DB write blocks the UI interaction, feels broken to the user
const handleExpand = async () => {
  setIsExpanded(true);
  await trackEngagement({ ... }); // ← 200ms DB write blocks expand animation
};
```

```typescript
// GOOD — fire and forget, UI updates immediately
const handleExpand = () => {
  setIsExpanded(true);
  trackEngagement({ ... }); // no await — result is irrelevant to UX
};
```

---

### ❌ Anti-Pattern 3: Using scroll event listener for scroll depth

```typescript
// BAD — fires hundreds of times per second, destroys mobile performance
useEffect(() => {
  const handleScroll = () => {
    const pct = Math.round(window.scrollY / document.body.scrollHeight * 100);
    trackEngagement({ event_type: 'scroll_depth', scroll_pct: pct });
  };
  window.addEventListener('scroll', handleScroll);
  return () => window.removeEventListener('scroll', handleScroll);
}, []);
```

```typescript
// GOOD — IntersectionObserver fires once when element enters viewport
useEffect(() => {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          trackEngagement({ event_type: 'scroll_depth', scroll_pct: 75, block_id: 'lane_4' });
          observer.disconnect(); // Track once
        }
      });
    },
    { threshold: 0.5 }
  );
  if (ref.current) observer.observe(ref.current);
  return () => observer.disconnect();
}, []);
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| Expand tracked on every re-render because `useRef` guard not used | One panel open = 10+ expand events in analytics | Add `hasTracked = useRef(false)` and set to true on first fire |
| Copy events fire but don't include `block_id` — only `event_type: 'copy'` | Can't distinguish which coaching item is most copied | Always include `block_id` (item UUID or index-based ID) |
| Dwell timer not paused on tab visibility change | User switches tabs for 20 minutes; 20-minute dwell recorded for a 10-second read | Use `document.addEventListener('visibilitychange', ...)` to pause/resume |
| Engagement API returns 400/500 on bad payload causing client retry loop | Network tab shows 50+ failed requests per page load | Always return 200 from engagement endpoint, even for validation failures |
| `COUNT(*)` used instead of `COUNT(DISTINCT session_id)` in expand rate | One user refreshing 5 times = 5 unique sessions = inflated expand rate | Use `COUNT(DISTINCT session_id)` for per-user metrics |
| Aggregate query groups by `block_id` without `challenge_id` | Panel "planning_evidence" performs differently by challenge but data is blended | Always group by `challenge_id, block_id` together |
| `keepalive: true` missing from fetch in instrumentation client | Tracking events on page unload are silently dropped | Add `keepalive: true` to all engagement fetch calls |
| `sessionStorage` access not wrapped in try/catch | Privacy-focused browsers block sessionStorage access; uncaught exception crashes hook | Wrap all `sessionStorage` calls in try/catch, fall back to ephemeral UUID |
| No minimum dwell threshold — sub-100ms events recorded | Rapid scroll generates hundreds of 50ms dwell events | Filter out dwell events < 500ms before recording |
| Instrumentation enabled in development/test environments | Test fixtures inflate production analytics | Check `process.env.NODE_ENV !== 'production'` before firing events |

---

## Changelog
- 2026-03-31: Created for Bouts self-improving feedback instrumentation build
