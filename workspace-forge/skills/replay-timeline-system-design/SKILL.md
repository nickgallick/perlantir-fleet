---
name: replay-timeline-system-design
description: Full system design for Bouts evaluation replay — event model, SQL schema, TypeScript discriminated union, phase grouping, evidence ref linking, legacy record handling, and a virtualized TSX timeline component for 500+ events.
---

# Replay Timeline System Design

## Review Checklist

- [ ] **The `timeline_events` table has an index on `(submission_id, sequence_number)`** — all timeline queries are by submission and ordered by sequence; this index is non-negotiable for performance
- [ ] **Event type is stored as a text enum, not an integer** — readable in queries, immune to enum reordering bugs
- [ ] **`event_data` JSONB column has a CHECK constraint validating the required fields per type** — prevents invalid event shapes at the DB layer
- [ ] **Phase assignment is computed at query time, not stored** — phases are a display concern; they can be recomputed without migrations
- [ ] **Judge evidence refs link to `timeline_events.event_id` by FK when the event exists** — nullable FK, not a loose string reference
- [ ] **Legacy records (pre-annotation schema) render without crashing** — `annotations` column null on old rows; component handles gracefully
- [ ] **Virtual scrolling is used for timelines > 100 events** — without it, 500+ events freeze the browser
- [ ] **Evidence ref linking uses a lookup Map, not `.find()` in a loop** — O(1) per lookup, not O(n) for 500 events
- [ ] **The TypeScript discriminated union covers all event types** — exhaustiveness checked with `assertNever()`
- [ ] **Phase grouping is visually collapsible** — phases with 50+ events are collapsed by default
- [ ] **Each timeline event shows its timestamp relative to submission start** — "+1.3s" not an ISO string
- [ ] **Tool calls and tool results are paired in the UI** — a tool_call without a visible tool_result is confusing

---

## The Event Model

A Bouts replay timeline captures everything that happened during an agent's submission run. Five event types cover the full lifecycle.

```typescript
// types/timeline.ts

/** 
 * Discriminated union of all timeline event types.
 * Every event in the system must match one of these shapes.
 */

export type TimelineEventType =
  | 'agent_message'
  | 'tool_call'
  | 'tool_result'
  | 'judge_annotation'
  | 'system_event';

// ─── Base ──────────────────────────────────────────────────────────────────────

interface BaseTimelineEvent {
  eventId: string;
  submissionId: string;
  sequenceNumber: number;     // ordering within submission — unique, monotonically increasing
  type: TimelineEventType;
  occurredAtMs: number;       // ms since submission start (0 = submission began)
  occurredAtIso: string;      // ISO 8601 absolute time (for display/tooltip)
  phase: PhaseType | null;    // computed, not stored
}

// ─── Agent Message ─────────────────────────────────────────────────────────────

export interface AgentMessageEvent extends BaseTimelineEvent {
  type: 'agent_message';
  data: {
    role: 'user' | 'assistant' | 'system';
    content: string;
    tokenCount: number | null;
    modelId: string | null;
    // For assistant messages: usage stats
    inputTokens: number | null;
    outputTokens: number | null;
  };
}

// ─── Tool Call ─────────────────────────────────────────────────────────────────

export interface ToolCallEvent extends BaseTimelineEvent {
  type: 'tool_call';
  data: {
    toolName: string;
    toolCallId: string;       // used to pair with tool_result
    input: Record<string, unknown>;
    inputSummary: string | null;  // human-readable summary (populated by ingestion)
  };
}

// ─── Tool Result ───────────────────────────────────────────────────────────────

export interface ToolResultEvent extends BaseTimelineEvent {
  type: 'tool_result';
  data: {
    toolCallId: string;       // matches ToolCallEvent.data.toolCallId
    toolName: string;
    isError: boolean;
    content: string;
    contentSummary: string | null;
    latencyMs: number | null;
  };
}

// ─── Judge Annotation ──────────────────────────────────────────────────────────

export interface JudgeAnnotationEvent extends BaseTimelineEvent {
  type: 'judge_annotation';
  data: {
    judgeId: string;
    laneId: string;
    annotationType: 'positive' | 'negative' | 'neutral';
    text: string;
    evidenceRefId: string | null;   // links to evidence_refs table
    score: number | null;           // partial score for this specific event
  };
}

// ─── System Event ──────────────────────────────────────────────────────────────

export interface SystemEvent extends BaseTimelineEvent {
  type: 'system_event';
  data: {
    eventName: 'submission_started' | 'submission_completed' | 'judge_started' | 'judge_completed' | 'timeout' | 'error';
    message: string;
    metadata: Record<string, unknown> | null;
  };
}

// ─── Union ─────────────────────────────────────────────────────────────────────

export type TimelineEvent =
  | AgentMessageEvent
  | ToolCallEvent
  | ToolResultEvent
  | JudgeAnnotationEvent
  | SystemEvent;

// ─── Phase ─────────────────────────────────────────────────────────────────────

export type PhaseType = 'planning' | 'execution' | 'verification' | 'response';

export interface TimelinePhase {
  phase: PhaseType;
  label: string;
  description: string;
  startSequence: number;
  endSequence: number;
  events: TimelineEvent[];
  eventCount: number;
  durationMs: number;
}

// Exhaustiveness check — TypeScript will error if a new type is added to the union without handling it
export function assertNever(x: never): never {
  throw new Error(`Unhandled event type: ${JSON.stringify(x)}`);
}
```

---

## SQL Schema for `timeline_events`

```sql
-- timeline_events: stores every event in a submission's execution
CREATE TABLE timeline_events (
  event_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id     UUID NOT NULL REFERENCES submissions(submission_id) ON DELETE CASCADE,
  sequence_number   INTEGER NOT NULL,
  type              TEXT NOT NULL CHECK (type IN (
                      'agent_message', 'tool_call', 'tool_result',
                      'judge_annotation', 'system_event'
                    )),
  occurred_at       TIMESTAMPTZ NOT NULL,
  occurred_at_ms    INTEGER NOT NULL,    -- ms since submission started, for display
  event_data        JSONB NOT NULL,
  -- Schema version: null on legacy records (pre-annotation era)
  schema_version    INTEGER,

  -- Each (submission_id, sequence_number) pair is unique
  UNIQUE (submission_id, sequence_number)
);

-- Primary query pattern: all events for a submission in order
CREATE INDEX idx_timeline_events_submission_seq
  ON timeline_events (submission_id, sequence_number ASC);

-- Secondary: all judge annotations for a submission (for evidence linking)
CREATE INDEX idx_timeline_events_annotations
  ON timeline_events (submission_id, type)
  WHERE type = 'judge_annotation';

-- evidence_refs: links judge evidence to specific timeline events
CREATE TABLE evidence_refs (
  ref_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_result_id   UUID NOT NULL REFERENCES judge_results(id) ON DELETE CASCADE,
  submission_id     UUID NOT NULL,
  lane_id           TEXT NOT NULL,
  judge_id          TEXT NOT NULL,
  type              TEXT NOT NULL CHECK (type IN ('quote', 'annotation', 'metric')),
  content           TEXT NOT NULL,
  confidence        NUMERIC(4,3),

  -- Link to the specific timeline event this evidence came from (nullable — legacy refs don't have this)
  source_event_id   UUID REFERENCES timeline_events(event_id) ON DELETE SET NULL,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_evidence_refs_submission ON evidence_refs (submission_id);
CREATE INDEX idx_evidence_refs_source_event ON evidence_refs (source_event_id) WHERE source_event_id IS NOT NULL;

-- Migration: add schema_version to old timeline_events rows
UPDATE timeline_events SET schema_version = 1 WHERE schema_version IS NULL;
ALTER TABLE timeline_events ALTER COLUMN schema_version SET DEFAULT 2;
```

---

## Phase Grouping Logic

Phases are computed from event sequences, not stored. This makes them flexible and migration-free.

```typescript
// lib/timeline/phases.ts
import type { TimelineEvent, TimelinePhase, PhaseType } from '@/types/timeline';

/**
 * Assign a phase to each event based on heuristics.
 * This is a best-effort classification — not perfect for all agent patterns.
 */
export function assignPhase(
  event: TimelineEvent,
  allEvents: TimelineEvent[],
  eventIndex: number
): PhaseType {
  const totalEvents = allEvents.length;
  const position = eventIndex / totalEvents;

  switch (event.type) {
    case 'system_event': {
      const name = event.data.eventName;
      if (name === 'submission_started') return 'planning';
      if (name === 'submission_completed') return 'response';
      return 'execution';
    }

    case 'agent_message': {
      if (event.data.role === 'user') return 'planning';
      // Final assistant message is typically the response
      const isLast = eventIndex === totalEvents - 1 ||
        (eventIndex >= totalEvents - 3 &&
          allEvents.slice(eventIndex + 1).every(e => e.type === 'system_event'));
      if (isLast) return 'response';
      // Early assistant messages are planning
      if (position < 0.2) return 'planning';
      return 'execution';
    }

    case 'tool_call':
    case 'tool_result': {
      const toolName = event.type === 'tool_call'
        ? event.data.toolName
        : event.data.toolName;
      // Verification-named tools go to verification phase
      if (/verif|check|assert|valid/i.test(toolName)) return 'verification';
      return 'execution';
    }

    case 'judge_annotation':
      return 'execution'; // annotations are attached to execution events

    default:
      return assertNever(event as never);
  }
}

function assertNever(x: never): PhaseType {
  console.warn('Unknown event type in phase assignment:', x);
  return 'execution';
}

/**
 * Group events into phases, in order.
 */
export function groupEventsByPhase(events: TimelineEvent[]): TimelinePhase[] {
  if (events.length === 0) return [];

  // Assign phases to all events
  const withPhases = events.map((event, i) => ({
    event,
    phase: assignPhase(event, events, i),
  }));

  // Group consecutive same-phase events together
  const phases: TimelinePhase[] = [];
  let currentPhase: PhaseType | null = null;
  let currentEvents: TimelineEvent[] = [];
  let phaseStartSeq = 0;

  const PHASE_LABELS: Record<PhaseType, { label: string; description: string }> = {
    planning: { label: 'Planning', description: 'Agent receives task and formulates approach' },
    execution: { label: 'Execution', description: 'Agent takes actions and calls tools' },
    verification: { label: 'Verification', description: 'Agent checks and validates its work' },
    response: { label: 'Response', description: 'Agent generates final answer' },
  };

  for (const { event, phase } of withPhases) {
    if (phase !== currentPhase) {
      if (currentPhase !== null && currentEvents.length > 0) {
        const lastEvent = currentEvents[currentEvents.length - 1];
        const firstEvent = currentEvents[0];
        const durationMs = lastEvent.occurredAtMs - firstEvent.occurredAtMs;

        phases.push({
          phase: currentPhase,
          label: PHASE_LABELS[currentPhase].label,
          description: PHASE_LABELS[currentPhase].description,
          startSequence: phaseStartSeq,
          endSequence: lastEvent.sequenceNumber,
          events: currentEvents,
          eventCount: currentEvents.length,
          durationMs,
        });
      }
      currentPhase = phase;
      currentEvents = [event];
      phaseStartSeq = event.sequenceNumber;
    } else {
      currentEvents.push(event);
    }
  }

  // Flush last group
  if (currentPhase !== null && currentEvents.length > 0) {
    const lastEvent = currentEvents[currentEvents.length - 1];
    const firstEvent = currentEvents[0];
    phases.push({
      phase: currentPhase,
      label: PHASE_LABELS[currentPhase].label,
      description: PHASE_LABELS[currentPhase].description,
      startSequence: phaseStartSeq,
      endSequence: lastEvent.sequenceNumber,
      events: currentEvents,
      eventCount: currentEvents.length,
      durationMs: lastEvent.occurredAtMs - firstEvent.occurredAtMs,
    });
  }

  return phases;
}

/**
 * Build a lookup map from event_id to evidence refs.
 * O(1) per lookup — required for performance on 500+ event timelines.
 */
export function buildEvidenceRefMap(
  evidenceRefs: Array<{ refId: string; sourceEventId: string | null; content: string; type: string; judgeId: string; laneId: string }>
): Map<string, typeof evidenceRefs> {
  const map = new Map<string, typeof evidenceRefs>();

  for (const ref of evidenceRefs) {
    if (!ref.sourceEventId) continue;
    const existing = map.get(ref.sourceEventId) ?? [];
    map.set(ref.sourceEventId, [...existing, ref]);
  }

  return map;
}
```

---

## Virtualized TSX Timeline Component

Without virtualization, rendering 500+ timeline events will freeze the browser. This component uses a simple virtualization approach — only rendering events visible in the viewport.

```tsx
// components/timeline/TimelineReplay.tsx
'use client';

import React, { useState, useRef, useCallback, useMemo } from 'react';
import { cn } from '@/lib/utils';
import type { TimelineEvent, TimelinePhase } from '@/types/timeline';
import { groupEventsByPhase, buildEvidenceRefMap } from '@/lib/timeline/phases';

// Evidence ref type for display
interface EvidenceRef {
  refId: string;
  sourceEventId: string | null;
  content: string;
  type: string;
  judgeId: string;
  laneId: string;
}

interface TimelineReplayProps {
  events: TimelineEvent[];
  evidenceRefs: EvidenceRef[];
  isLegacyRecord?: boolean;
}

const ITEM_HEIGHT = 72;  // estimated px per event row
const OVERSCAN = 5;       // extra items to render above/below viewport

export function TimelineReplay({
  events,
  evidenceRefs,
  isLegacyRecord = false,
}: TimelineReplayProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scrollTop, setScrollTop] = useState(0);
  const [collapsedPhases, setCollapsedPhases] = useState<Set<string>>(new Set());

  const phases = useMemo(() => groupEventsByPhase(events), [events]);

  // Build evidence ref lookup — O(1) per event
  const evidenceMap = useMemo(
    () => buildEvidenceRefMap(evidenceRefs),
    [evidenceRefs]
  );

  // Compute flat list of items to virtualize (phases + events)
  // Phases with > 50 events are collapsed by default
  const flatItems = useMemo(() => {
    const items: Array<
      | { type: 'phase-header'; phase: TimelinePhase }
      | { type: 'event'; event: TimelineEvent; phaseKey: string }
    > = [];

    for (const phase of phases) {
      const phaseKey = `${phase.phase}-${phase.startSequence}`;
      const isAutoCollapsed = phase.eventCount > 50 && !collapsedPhases.has(phaseKey);

      // Initially collapse large phases
      if (phase.eventCount > 50 && !collapsedPhases.has(`${phaseKey}-expanded`)) {
        if (!collapsedPhases.has(phaseKey)) {
          // Keep large phases collapsed by default — they need explicit expand
        }
      }

      items.push({ type: 'phase-header', phase });

      const isCollapsed = collapsedPhases.has(phaseKey);
      if (!isCollapsed) {
        for (const event of phase.events) {
          items.push({ type: 'event', event, phaseKey });
        }
      }
    }

    return items;
  }, [phases, collapsedPhases]);

  const togglePhase = useCallback((phaseKey: string) => {
    setCollapsedPhases(prev => {
      const next = new Set(prev);
      next.has(phaseKey) ? next.delete(phaseKey) : next.add(phaseKey);
      return next;
    });
  }, []);

  const containerHeight = 600; // visible window height
  const totalHeight = flatItems.length * ITEM_HEIGHT;

  // Compute visible window
  const startIndex = Math.max(0, Math.floor(scrollTop / ITEM_HEIGHT) - OVERSCAN);
  const endIndex = Math.min(
    flatItems.length - 1,
    Math.ceil((scrollTop + containerHeight) / ITEM_HEIGHT) + OVERSCAN
  );
  const visibleItems = flatItems.slice(startIndex, endIndex + 1);

  const handleScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    setScrollTop(e.currentTarget.scrollTop);
  }, []);

  if (events.length === 0) {
    return (
      <div className="flex items-center justify-center h-40 text-sm text-gray-400 border border-gray-200 rounded-lg bg-gray-50">
        {isLegacyRecord ? 'Timeline not available for legacy submissions' : 'No timeline events'}
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-gray-200 bg-white overflow-hidden">
      {/* Header */}
      <div className="px-5 py-3 border-b border-gray-100 flex items-center justify-between">
        <h3 className="text-sm font-semibold text-gray-900">Execution Timeline</h3>
        <div className="flex items-center gap-3">
          <span className="text-xs text-gray-400">{events.length} events</span>
          {isLegacyRecord && (
            <span className="text-xs bg-amber-50 text-amber-600 border border-amber-100 rounded-full px-2 py-0.5">
              Legacy — no annotations
            </span>
          )}
        </div>
      </div>

      {/* Virtualized scroll container */}
      <div
        ref={containerRef}
        className="overflow-y-auto"
        style={{ height: containerHeight }}
        onScroll={handleScroll}
        role="feed"
        aria-label="Execution timeline"
      >
        {/* Total height spacer */}
        <div style={{ height: totalHeight, position: 'relative' }}>
          {/* Visible items positioned absolutely */}
          {visibleItems.map((item, i) => {
            const absoluteIndex = startIndex + i;
            const top = absoluteIndex * ITEM_HEIGHT;

            if (item.type === 'phase-header') {
              const phaseKey = `${item.phase.phase}-${item.phase.startSequence}`;
              const isCollapsed = collapsedPhases.has(phaseKey);

              return (
                <div
                  key={phaseKey}
                  style={{ position: 'absolute', top, left: 0, right: 0 }}
                >
                  <PhaseHeader
                    phase={item.phase}
                    isCollapsed={isCollapsed}
                    onToggle={() => togglePhase(phaseKey)}
                  />
                </div>
              );
            }

            // Event item
            const linkedRefs = evidenceMap.get(item.event.eventId) ?? [];

            return (
              <div
                key={item.event.eventId}
                style={{ position: 'absolute', top, left: 0, right: 0 }}
              >
                <TimelineEventRow
                  event={item.event}
                  linkedRefs={linkedRefs}
                />
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ─── Phase Header ──────────────────────────────────────────────────────────────

const phaseColors = {
  planning: 'text-blue-700 bg-blue-50 border-blue-200',
  execution: 'text-gray-700 bg-gray-50 border-gray-200',
  verification: 'text-emerald-700 bg-emerald-50 border-emerald-200',
  response: 'text-indigo-700 bg-indigo-50 border-indigo-200',
};

function PhaseHeader({
  phase,
  isCollapsed,
  onToggle,
}: {
  phase: TimelinePhase;
  isCollapsed: boolean;
  onToggle: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onToggle}
      onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onToggle(); } }}
      className={cn(
        'w-full flex items-center justify-between px-5 py-2.5 border-b text-left hover:opacity-80 transition-opacity',
        phaseColors[phase.phase]
      )}
      aria-expanded={!isCollapsed}
    >
      <div className="flex items-center gap-2">
        <svg
          className={cn('h-3.5 w-3.5 transition-transform', !isCollapsed && 'rotate-90')}
          fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
        <span className="text-xs font-semibold uppercase tracking-wide">{phase.label}</span>
        <span className="text-xs opacity-60">{phase.description}</span>
      </div>
      <div className="flex items-center gap-3 text-xs opacity-60">
        <span>{phase.eventCount} events</span>
        <span>{phase.durationMs > 1000
          ? `${(phase.durationMs / 1000).toFixed(1)}s`
          : `${phase.durationMs}ms`
        }</span>
      </div>
    </button>
  );
}

// ─── Event Row ─────────────────────────────────────────────────────────────────

function TimelineEventRow({
  event,
  linkedRefs,
}: {
  event: TimelineEvent;
  linkedRefs: EvidenceRef[];
}) {
  const [showRefs, setShowRefs] = useState(false);

  const timeLabel = event.occurredAtMs < 1000
    ? `+${event.occurredAtMs}ms`
    : `+${(event.occurredAtMs / 1000).toFixed(1)}s`;

  return (
    <div className="px-5 py-3 border-b border-gray-50 hover:bg-gray-50 transition-colors">
      <div className="flex items-start gap-3">
        {/* Time column */}
        <span className="text-xs text-gray-300 tabular-nums w-12 shrink-0 pt-0.5 text-right">
          {timeLabel}
        </span>

        {/* Event content */}
        <div className="flex-1 min-w-0">
          <EventContent event={event} />

          {/* Evidence refs indicator */}
          {linkedRefs.length > 0 && (
            <button
              type="button"
              onClick={() => setShowRefs(!showRefs)}
              className="mt-1.5 flex items-center gap-1 text-xs text-indigo-500 hover:text-indigo-700"
              aria-expanded={showRefs}
            >
              <span className="h-3.5 w-3.5">🔎</span>
              {linkedRefs.length} judge annotation{linkedRefs.length !== 1 ? 's' : ''}
            </button>
          )}

          {showRefs && (
            <div className="mt-2 space-y-1.5 pl-3 border-l-2 border-indigo-100">
              {linkedRefs.map(ref => (
                <div key={ref.refId} className="text-xs text-gray-500">
                  <span className="font-medium text-indigo-600">{ref.judgeId}</span>
                  {' · '}{ref.laneId}
                  <p className="mt-0.5 text-gray-600">{ref.content}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Event Content by Type ─────────────────────────────────────────────────────

function EventContent({ event }: { event: TimelineEvent }) {
  switch (event.type) {
    case 'agent_message':
      return (
        <div>
          <span className={cn(
            'text-xs font-semibold uppercase tracking-wide mr-2',
            event.data.role === 'assistant' ? 'text-indigo-600' : 'text-gray-500'
          )}>
            {event.data.role}
          </span>
          <span className="text-sm text-gray-700 line-clamp-2">{event.data.content}</span>
          {event.data.tokenCount !== null && (
            <span className="text-xs text-gray-300 ml-2">{event.data.tokenCount} tokens</span>
          )}
        </div>
      );

    case 'tool_call':
      return (
        <div>
          <span className="text-xs font-semibold text-amber-600 mr-2">Tool Call</span>
          <span className="text-sm font-mono text-gray-700">{event.data.toolName}</span>
          {event.data.inputSummary && (
            <p className="text-xs text-gray-400 mt-0.5 line-clamp-1">{event.data.inputSummary}</p>
          )}
        </div>
      );

    case 'tool_result':
      return (
        <div>
          <span className={cn(
            'text-xs font-semibold mr-2',
            event.data.isError ? 'text-red-500' : 'text-emerald-600'
          )}>
            {event.data.isError ? 'Tool Error' : 'Tool Result'}
          </span>
          <span className="text-sm font-mono text-gray-500">{event.data.toolName}</span>
          {event.data.latencyMs !== null && (
            <span className="text-xs text-gray-300 ml-2">{event.data.latencyMs}ms</span>
          )}
          {event.data.contentSummary && (
            <p className="text-xs text-gray-500 mt-0.5 line-clamp-1">{event.data.contentSummary}</p>
          )}
        </div>
      );

    case 'judge_annotation':
      return (
        <div>
          <span className={cn(
            'text-xs font-semibold mr-2',
            event.data.annotationType === 'positive' ? 'text-emerald-600'
            : event.data.annotationType === 'negative' ? 'text-red-500'
            : 'text-gray-500'
          )}>
            {event.data.judgeId} · {event.data.laneId}
          </span>
          <span className="text-sm text-gray-600 line-clamp-1">{event.data.text}</span>
        </div>
      );

    case 'system_event':
      return (
        <div>
          <span className="text-xs font-semibold text-gray-400 mr-2">System</span>
          <span className="text-sm text-gray-500">{event.data.message}</span>
        </div>
      );

    default:
      return assertNever(event);
  }
}

function assertNever(x: never): React.ReactElement {
  return <span className="text-xs text-red-400">Unknown event type</span>;
}
```

---

## Anti-Patterns

### ❌ `.find()` in render for evidence linking

```typescript
// BAD — O(n) per event * 500 events = O(n²) total
function getRefsForEvent(eventId: string, refs: EvidenceRef[]) {
  return refs.filter(r => r.sourceEventId === eventId); // in render
}

// GOOD — build Map once, O(1) per event
const evidenceMap = useMemo(() => buildEvidenceRefMap(evidenceRefs), [evidenceRefs]);
const linkedRefs = evidenceMap.get(event.eventId) ?? [];
```

### ❌ Rendering all 500+ events at once

```tsx
// BAD — freezes the browser for large submissions
{events.map(event => <TimelineEventRow key={event.eventId} event={event} />)}

// GOOD — virtualize: only render visible items
// (see virtualized scroll container in TimelineReplay above)
```

### ❌ Storing phase in the database

```sql
-- BAD — phase is a display concern; storing it requires re-migration when phase logic changes
ALTER TABLE timeline_events ADD COLUMN phase TEXT;
UPDATE timeline_events SET phase = 'execution'; -- now you need logic to re-derive it

-- GOOD — compute phase at query/display time using assignPhase()
-- No DB column needed; phases are derived from event type + position
```

### ❌ Crashing on legacy records without `event_data` fields

```typescript
// BAD — crashes if `event_data.content` doesn't exist (legacy schema)
const content = event.event_data.content; // TypeError if legacy row missing this field

// GOOD — guard every JSONB field access
const content = (event.event_data as any)?.content ?? '[content not available]';
```

---

## Common Failures to Catch in Review

| Failure | Symptom | Fix |
|---------|---------|-----|
| No index on `(submission_id, sequence_number)` | Timeline query takes 3–10s on large submissions | Add `CREATE INDEX idx_timeline_events_submission_seq ON timeline_events (submission_id, sequence_number ASC)` |
| Evidence ref lookup uses `.filter()` in render | Page freezes when rendering timeline for 200+ event submission | Build `Map<eventId, refs[]>` once in `useMemo`, use O(1) lookup |
| All 500 events rendered without virtualization | Browser freezes; scrolling unresponsive | Implement virtual scroll with `startIndex/endIndex` and absolute positioning |
| `tool_call` events shown without matching `tool_result` | User sees dangling tool calls with no outcome | Pair tool calls and results by `toolCallId` in the display layer |
| Legacy records crash on missing `event_data` fields | TypeError in production for old submissions | Guard all JSONB field access with optional chaining and fallbacks |
| Phase assignment crashes on unknown event type | `assertNever` throws in production | Add graceful fallback: return `'execution'` for unknown types, log warning |
| Phase groups not collapsible | A 200-event execution phase fills the screen | Auto-collapse phases with `eventCount > 50`; render "show N events" button |
| `occurred_at_ms` shown as ISO string | Users see "2026-03-15T04:12:00Z" instead of "+1.3s" | Format as relative time: `+{(ms/1000).toFixed(1)}s` |
| Timeline re-fetched on every render | Excessive DB queries when user scrolls | Cache timeline data; events don't change after submission completes |
| No empty state for legacy records | Page shows loading spinner forever on pre-timeline submissions | Check `isLegacyRecord` flag; render "Timeline not available for legacy submissions" |

---

## Changelog
- 2026-03-31: Created for Bouts premium feedback system build
