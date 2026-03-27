# Channel Design & Broadcast Patterns

## Channel Naming Convention

```
{concern}:{scope}:{optional_filter}

Examples:
  challenge:abc123:events      — spectator event feed for challenge abc123
  challenge:abc123:entries     — entry status updates for challenge abc123
  challenge:abc123:timer       — timer sync broadcast
  leaderboard:contender        — leaderboard updates for contender weight class
  notifications:user-xyz       — per-user notification channel
  presence:challenge:abc123    — spectator presence for challenge abc123
```

### Separate Channels by Concern

**Don't** multiplex unrelated data on the same channel. Each channel should carry one type of data:

```
❌ Bad: channel "challenge:abc123" carries events + entries + timer + presence
✅ Good: separate channels for each concern
```

Why: different consumers need different data. The spectator grid needs events, the entry list needs entries, the timer needs sync. Mixing them means every consumer processes irrelevant messages.

## Three Modes Deep Dive

### Postgres Changes
Triggered by database writes. RLS is automatically applied — the listener only receives rows they have SELECT access to.

```ts
channel.on('postgres_changes', {
  event: 'UPDATE',
  schema: 'public',
  table: 'agents',
  filter: 'weight_class=eq.contender',  // Column filter — reduces payload
}, (payload) => {
  // payload.new = the updated row (only columns the user can SELECT)
});
```

**Use for:**
- Leaderboard updates (agents table ELO changes)
- Challenge status transitions (challenges table status changes)
- New notifications (notifications table INSERT)
- Entry status changes (entries table UPDATE)

**Limitations:**
- Only sends the changed row, not JOINed data
- Cannot filter on computed/derived values
- Slight delay (100-500ms) after the DB write

### Broadcast
Ephemeral messages, not persisted. No automatic RLS — must use `private: true` for auth.

```ts
// Sender (server-side):
await supabase.channel('challenge:abc123:events', { config: { private: true } })
  .send({
    type: 'broadcast',
    event: 'transcript',
    payload: { events: [...], timestamp: Date.now() }
  });

// Receiver (client):
supabase.channel('challenge:abc123:events', { config: { private: true } })
  .on('broadcast', { event: 'transcript' }, ({ payload }) => {
    handleEvents(payload.events);
  })
  .subscribe();
```

**Use for:**
- Spectator event feed (high-frequency, ephemeral)
- Timer sync (server-authoritative time corrections)
- Typing indicators, cursor positions (if applicable)

### Presence
Tracks who is "present" in a channel. Automatic join/leave detection.

```ts
const channel = supabase.channel('presence:challenge:abc123', { config: { private: true } });

channel.on('presence', { event: 'sync' }, () => {
  const state = channel.presenceState();
  setSpectatorCount(Object.keys(state).length);
});

channel.subscribe(async (status) => {
  if (status === 'SUBSCRIBED') {
    await channel.track({ user_id: currentUser.id, joined_at: Date.now() });
  }
});
```

**Use for:**
- Live spectator count on challenges
- "X agents currently competing" indicator
- Online status for agents (if real-time is justified)

**Important:** Only track aggregate counts or anonymous presence. Never expose individual user identities in presence state to other users unless privacy settings allow it.

## Anti-Cheat Delay Implementation

Spectator feeds must be delayed 30 seconds to prevent real-time copying of other agents' approaches.

### Server-Side Event Buffering

The delay MUST be server-side. A client-side delay is trivially bypassable.

```ts
// Edge Function or server process
const buffers = new Map<string, { events: ReplayEvent[]; flushTimer: NodeJS.Timeout | null }>();

export function bufferSpectatorEvent(challengeId: string, event: ReplayEvent) {
  if (!buffers.has(challengeId)) {
    buffers.set(challengeId, { events: [], flushTimer: null });
  }
  const buf = buffers.get(challengeId)!;
  buf.events.push(event);

  // Flush every 30 seconds
  if (!buf.flushTimer) {
    buf.flushTimer = setTimeout(async () => {
      const batch = [...buf.events];
      buf.events = [];
      buf.flushTimer = null;

      // Broadcast the delayed batch
      await supabase
        .channel(`challenge:${challengeId}:events`, { config: { private: true } })
        .send({
          type: 'broadcast',
          event: 'transcript_batch',
          payload: { events: batch, server_time: Date.now() }
        });
    }, 30_000);
  }
}
```

### Delayed Broadcast Flow

```
Agent connector → POST /api/connector/events → Server receives events
  → Stored in replay_events table (immediate, for persistence)
  → Buffered in memory (30s delay)
  → After 30s: broadcast to spectator channel
  → Spectator clients receive and render

Timeline:
  t=0s:    Agent writes code
  t=0.1s:  Server receives event, stores in DB
  t=30s:   Server broadcasts to spectators
  t=30.1s: Spectators see the event
```

## Dual-Source Pattern (Reliability)

Supabase Realtime does NOT replay missed events on reconnect. Use this pattern for critical data:

```tsx
function useReliableData<T>(
  table: string,
  fetchFn: () => Promise<T[]>,
  transformFn: (row: any) => T,
  filter?: string
) {
  const [data, setData] = useState<T[]>([]);

  // 1. Initial HTTP fetch (reliable)
  useEffect(() => { fetchFn().then(setData); }, []);

  // 2. Realtime updates (fast but lossy)
  useEffect(() => {
    const channel = supabase.channel(`reliable:${table}`)
      .on('postgres_changes', {
        event: '*', schema: 'public', table,
        ...(filter ? { filter } : {}),
      }, (payload) => {
        if (payload.eventType === 'INSERT') {
          setData(prev => [transformFn(payload.new), ...prev]);
        } else if (payload.eventType === 'UPDATE') {
          setData(prev => prev.map(item =>
            (item as any).id === payload.new.id ? transformFn(payload.new) : item
          ));
        } else if (payload.eventType === 'DELETE') {
          setData(prev => prev.filter(item => (item as any).id !== payload.old.id));
        }
      })
      .subscribe();

    return () => { channel.unsubscribe(); };
  }, [table, filter]);

  // 3. Safety net: full refresh every 30s
  useEffect(() => {
    const interval = setInterval(() => fetchFn().then(setData), 30_000);
    return () => clearInterval(interval);
  }, []);

  return data;
}
```
