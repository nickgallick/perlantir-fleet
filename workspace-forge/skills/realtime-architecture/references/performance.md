# Performance & Scaling

## Supabase Realtime Plan Limits

| Plan | Max Concurrent Connections | Messages/sec (project) | Max Channels/Connection | Max Message Size |
|---|---|---|---|---|
| Free | 200 | 100 | 100 | 1MB (broadcast) |
| Pro | 500 | 500 | 100 | 1MB |
| Team | 1,000 | 1,000 | 100 | 1MB |
| Enterprise | Custom | Custom | 100 | Custom |

### Scaling Considerations

A "connection" = one WebSocket from one browser tab. A user with 3 tabs = 3 connections.

For Agent Arena at launch:
- 50 concurrent spectators per challenge × 5 active challenges = 250 connections for spectating
- 50 users on leaderboard page = 50 connections
- Dashboard users = ~20 connections
- **Total estimate: ~400 concurrent connections** → Pro plan sufficient for launch

### Max Connections Per Channel

Supabase doesn't enforce a hard per-channel limit, but performance degrades above ~500 subscribers per channel. For popular challenges:
- If spectator count > 500, consider sharding: `challenge:abc:events:shard-0`, `challenge:abc:events:shard-1`
- Assign users to shards via hash of user ID

## Batching High-Frequency Events

Spectator event feeds can generate 10+ events per second per agent. With 50 agents, that's 500 events/second — too much to broadcast individually.

### Server-Side Batching

```ts
// Batch all events for a challenge, flush every 500ms
const BATCH_INTERVAL_MS = 500;
const MAX_BATCH_SIZE = 100;

const batches = new Map<string, ReplayEvent[]>();

function addEvent(challengeId: string, event: ReplayEvent) {
  if (!batches.has(challengeId)) {
    batches.set(challengeId, []);
    setTimeout(() => flushBatch(challengeId), BATCH_INTERVAL_MS);
  }
  const batch = batches.get(challengeId)!;
  batch.push(event);

  // Force flush if batch is large
  if (batch.length >= MAX_BATCH_SIZE) {
    flushBatch(challengeId);
  }
}

async function flushBatch(challengeId: string) {
  const events = batches.get(challengeId) || [];
  batches.delete(challengeId);
  if (events.length === 0) return;

  // Note: this goes through the 30s delay buffer first (see channels.md)
  await bufferSpectatorEvent(challengeId, events);
}
```

### Client-Side Throttling

Even with server batching, the client should throttle renders:

```tsx
function useThrottledEvents(channelName: string, throttleMs = 200) {
  const [events, setEvents] = useState<ReplayEvent[]>([]);
  const bufferRef = useRef<ReplayEvent[]>([]);
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    const channel = supabase.channel(channelName, { config: { private: true } })
      .on('broadcast', { event: 'transcript_batch' }, ({ payload }) => {
        bufferRef.current.push(...payload.events);

        if (!timerRef.current) {
          timerRef.current = setTimeout(() => {
            setEvents(prev => [...prev, ...bufferRef.current]);
            bufferRef.current = [];
            timerRef.current = null;
          }, throttleMs);
        }
      })
      .subscribe();

    return () => {
      channel.unsubscribe();
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [channelName, throttleMs]);

  return events;
}
```

## Postgres Changes Filters

Reduce payload by filtering at the source:

```ts
// ❌ Receives ALL agent updates (name changes, bio edits, etc.)
.on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'agents' }, ...)

// ✅ Only receives ELO changes for the weight class we're viewing
.on('postgres_changes', {
  event: 'UPDATE',
  schema: 'public',
  table: 'agents',
  filter: 'weight_class=eq.contender',
}, (payload) => {
  // Only fires when a contender agent is updated
  if (payload.old.elo_rating !== payload.new.elo_rating) {
    // ELO actually changed — update leaderboard
    updateLeaderboardRow(payload.new);
  }
})
```

**Available filter operators:** `eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `in`

**Limitation:** Can only filter on one column. For multi-column filtering, filter client-side:
```ts
.on('postgres_changes', {
  event: 'UPDATE', schema: 'public', table: 'entries',
  filter: `challenge_id=eq.${challengeId}`,
}, (payload) => {
  // Client-side filter for specific status change
  if (payload.new.status === 'judged' && payload.old.status !== 'judged') {
    handleEntryJudged(payload.new);
  }
})
```

## Message Size Optimization

Broadcast messages have a 1MB limit. For spectator feeds, keep payloads small:

```ts
// ❌ Sending full code content in events
{ type: 'code_write', data: { file: 'routes.ts', content: '... 500 lines ...' } }

// ✅ Send summary only — full content available via HTTP if needed
{ type: 'code_write', data: { file: 'routes.ts', lines_changed: 12, preview: 'export async function...' } }
```

Target: < 2KB per event, < 50KB per batch broadcast.
