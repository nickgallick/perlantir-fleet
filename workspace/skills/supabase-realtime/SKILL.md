# Supabase Realtime Patterns

Complete Supabase Realtime reference for live data features. Covers Postgres Changes, Broadcast, Presence, and React hook patterns.

## Setup

```bash
npm install @supabase/supabase-js
```

Realtime is enabled per-table in Supabase Dashboard → Database → Replication. **Must enable replication for each table you want to listen to.**

---

## Channel Fundamentals

### Creating a channel

```tsx
const channel = supabase.channel("channel-name");
```

Channel names are arbitrary strings. Clients subscribed to the same channel name receive the same events. Prefix with context for clarity: `spectator:arena`, `user:${userId}`, `challenge:${challengeId}`.

### Subscribing

```tsx
channel.subscribe((status) => {
  if (status === "SUBSCRIBED") {
    console.log("Connected");
  }
  if (status === "CHANNEL_ERROR") {
    console.error("Subscription failed");
  }
  if (status === "TIMED_OUT") {
    console.warn("Subscription timed out");
  }
});
```

Status values: `SUBSCRIBED`, `TIMED_OUT`, `CLOSED`, `CHANNEL_ERROR`

### Unsubscribing (cleanup)

```tsx
supabase.removeChannel(channel);
```

Always clean up in `useEffect` return. `removeChannel` unsubscribes AND removes the channel object.

---

## 1. Postgres Changes (Database Listeners)

Listen to INSERT, UPDATE, DELETE on specific tables. Requires table replication enabled.

### All changes on a table

```tsx
const channel = supabase
  .channel("challenges-all")
  .on(
    "postgres_changes",
    {
      event: "*",           // INSERT | UPDATE | DELETE | *
      schema: "public",
      table: "challenges",
    },
    (payload) => {
      // payload.eventType: "INSERT" | "UPDATE" | "DELETE"
      // payload.new: new row data (INSERT/UPDATE)
      // payload.old: old row data (UPDATE/DELETE) — requires REPLICA IDENTITY FULL
      // payload.errors: any errors
      console.log("Change:", payload.eventType, payload.new);
    }
  )
  .subscribe();
```

### Filtered changes

```tsx
// Only listen to changes for a specific challenge
const channel = supabase
  .channel(`challenge-${challengeId}`)
  .on(
    "postgres_changes",
    {
      event: "UPDATE",
      schema: "public",
      table: "challenges",
      filter: `id=eq.${challengeId}`,
    },
    (payload) => {
      setChallengeStatus(payload.new.status);
    }
  )
  .subscribe();
```

Filter syntax matches PostgREST: `column=eq.value`, `column=in.(val1,val2,val3)`, `column=gt.value`.

### Multiple listeners on one channel

```tsx
const channel = supabase
  .channel("arena-updates")
  .on("postgres_changes", { event: "INSERT", schema: "public", table: "challenge_entries" }, handleNewEntry)
  .on("postgres_changes", { event: "UPDATE", schema: "public", table: "challenges" }, handleChallengeUpdate)
  .on("postgres_changes", { event: "*", schema: "public", table: "leaderboard" }, handleLeaderboardChange)
  .subscribe();
```

---

## 2. Broadcast (Custom Events)

Send arbitrary messages to all subscribers on a channel. No database involved. Low latency. Use for ephemeral events (typing indicators, cursor positions, live reactions).

### Sending

```tsx
channel.send({
  type: "broadcast",
  event: "agent-action",    // custom event name
  payload: {
    agentId: "agent-123",
    action: "submitted_code",
    timestamp: Date.now(),
  },
});
```

### Receiving

```tsx
const channel = supabase
  .channel("spectator:arena")
  .on("broadcast", { event: "agent-action" }, (payload) => {
    // payload.payload contains the sent data
    addSpectatorEvent(payload.payload);
  })
  .subscribe();
```

### Broadcast with acknowledgment

```tsx
// Sender receives confirmation server received it
const channel = supabase.channel("arena", {
  config: { broadcast: { ack: true } },
});

channel.subscribe(async (status) => {
  if (status === "SUBSCRIBED") {
    const resp = await channel.send({
      type: "broadcast",
      event: "agent-action",
      payload: { action: "start" },
    });
    // resp === "ok" if server acknowledged
  }
});
```

---

## 3. Presence (Who's Online)

Track connected users/agents in real time. Automatically syncs join/leave across all subscribers.

### Tracking presence

```tsx
const channel = supabase.channel("arena-spectators");

channel
  .on("presence", { event: "sync" }, () => {
    const state = channel.presenceState();
    // state: { [key: string]: PresenceState[] }
    // Each key is a presence_ref, value is array of states for that key
    const onlineUsers = Object.values(state).flat();
    setSpectators(onlineUsers);
  })
  .on("presence", { event: "join" }, ({ key, newPresences }) => {
    console.log("Joined:", newPresences);
  })
  .on("presence", { event: "leave" }, ({ key, leftPresences }) => {
    console.log("Left:", leftPresences);
  })
  .subscribe(async (status) => {
    if (status === "SUBSCRIBED") {
      await channel.track({
        userId: user.id,
        username: user.username,
        avatarUrl: user.avatar_url,
        joinedAt: new Date().toISOString(),
      });
    }
  });
```

### Untracking

```tsx
await channel.untrack();
```

Presence events:
- `sync` — fires whenever the full state changes (most reliable, use this for UI updates)
- `join` — fires when a new presence joins
- `leave` — fires when a presence leaves (including disconnect)

---

## Agent Arena — 4 Channel Patterns

### Channel 1: Spectator Channel (Live Agent Events with 30s Delay)

Live feed of agent actions for spectators. 30-second delay for anti-cheat (prevents agents from watching each other's solutions).

```tsx
// Server-side: delayed broadcast via Edge Function or API route
// When an agent submits an action, store it with timestamp
// A scheduled process broadcasts events that are 30+ seconds old

// API route: /api/arena/broadcast-delayed
export async function POST(req: Request) {
  const supabase = createServerClient();

  // Fetch events older than 30 seconds that haven't been broadcast
  const thirtySecondsAgo = new Date(Date.now() - 30_000).toISOString();

  const { data: events } = await supabase
    .from("arena_events")
    .select("*")
    .eq("broadcast", false)
    .lte("created_at", thirtySecondsAgo)
    .order("created_at", { ascending: true })
    .limit(50);

  if (!events?.length) return Response.json({ sent: 0 });

  // Broadcast each event
  const channel = supabase.channel("spectator:arena");
  await channel.subscribe();

  for (const event of events) {
    await channel.send({
      type: "broadcast",
      event: "agent-action",
      payload: {
        agentId: event.agent_id,
        challengeId: event.challenge_id,
        action: event.action_type,
        summary: event.summary,       // sanitized — no solution details
        timestamp: event.created_at,
      },
    });
  }

  // Mark as broadcast
  const eventIds = events.map((e) => e.id);
  await supabase
    .from("arena_events")
    .update({ broadcast: true })
    .in("id", eventIds);

  await supabase.removeChannel(channel);

  return Response.json({ sent: events.length });
}

// Client-side: spectator view
function useSpectatorFeed() {
  const supabase = useSupabase();
  const [events, setEvents] = useState<SpectatorEvent[]>([]);

  useEffect(() => {
    const channel = supabase
      .channel("spectator:arena")
      .on("broadcast", { event: "agent-action" }, ({ payload }) => {
        setEvents((prev) => [payload, ...prev].slice(0, 100)); // keep last 100
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [supabase]);

  return events;
}
```

### Channel 2: Challenge Updates (Status Changes, New Entries)

Real-time updates when challenge status changes or new entries are submitted.

```tsx
function useChallengeUpdates(challengeId: string) {
  const supabase = useSupabase();
  const queryClient = useQueryClient();

  useEffect(() => {
    const channel = supabase
      .channel(`challenge:${challengeId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "challenges",
          filter: `id=eq.${challengeId}`,
        },
        (payload) => {
          // Invalidate React Query cache to refetch
          queryClient.invalidateQueries({ queryKey: ["challenge", challengeId] });

          // Or update directly
          queryClient.setQueryData(
            ["challenge", challengeId],
            (old: Challenge) => ({ ...old, ...payload.new })
          );
        }
      )
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "challenge_entries",
          filter: `challenge_id=eq.${challengeId}`,
        },
        (payload) => {
          queryClient.invalidateQueries({
            queryKey: ["challenge-entries", challengeId],
          });
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [supabase, challengeId, queryClient]);
}
```

### Channel 3: Leaderboard Live Updates (ELO Changes)

Real-time leaderboard updates when ELO ratings change after challenge completion.

```tsx
function useLeaderboardUpdates() {
  const supabase = useSupabase();
  const queryClient = useQueryClient();

  useEffect(() => {
    const channel = supabase
      .channel("leaderboard-live")
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "agent_profiles",
          // No filter — listen to all agent profile ELO updates
        },
        (payload) => {
          const { id, elo_rating, wins, losses, rank } = payload.new;

          // Optimistic update: patch the leaderboard cache directly
          queryClient.setQueryData(
            ["leaderboard"],
            (old: AgentProfile[] | undefined) => {
              if (!old) return old;
              return old
                .map((agent) =>
                  agent.id === id
                    ? { ...agent, elo_rating, wins, losses, rank }
                    : agent
                )
                .sort((a, b) => b.elo_rating - a.elo_rating);
            }
          );
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [supabase, queryClient]);
}
```

### Channel 4: Notification Channel (Per-User)

User-specific notifications (challenge invites, results, system messages).

```tsx
function useUserNotifications(userId: string) {
  const supabase = useSupabase();
  const [notifications, setNotifications] = useState<Notification[]>([]);

  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel(`notifications:${userId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "notifications",
          filter: `user_id=eq.${userId}`,
        },
        (payload) => {
          const notification = payload.new as Notification;
          setNotifications((prev) => [notification, ...prev]);

          // Optional: show toast
          toast({
            title: notification.title,
            description: notification.body,
          });
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [supabase, userId]);

  return notifications;
}
```

---

## React Hook Pattern: useRealtime

Generic reusable hook for any realtime subscription with proper cleanup.

```tsx
// hooks/use-realtime.ts
"use client";
import { useEffect, useRef } from "react";
import { useSupabase } from "@/lib/supabase/client";
import type { RealtimeChannel, RealtimePostgresChangesPayload } from "@supabase/supabase-js";

type PostgresChangeEvent = "INSERT" | "UPDATE" | "DELETE" | "*";

interface UseRealtimeOptions {
  /** Channel name — must be unique per subscription */
  channelName: string;
  /** Table to listen to */
  table: string;
  /** Event type filter */
  event?: PostgresChangeEvent;
  /** Schema (default: "public") */
  schema?: string;
  /** PostgREST filter (e.g., "id=eq.123") */
  filter?: string;
  /** Callback when a change occurs */
  onchange: (payload: RealtimePostgresChangesPayload<Record<string, unknown>>) => void;
  /** Whether the subscription is active (default: true) */
  enabled?: boolean;
}

export function useRealtime({
  channelName,
  table,
  event = "*",
  schema = "public",
  filter,
  onchange,
  enabled = true,
}: UseRealtimeOptions) {
  const supabase = useSupabase();
  const callbackRef = useRef(onchange);
  callbackRef.current = onchange; // always use latest callback without re-subscribing

  useEffect(() => {
    if (!enabled) return;

    const channelConfig: Record<string, string> = {
      event,
      schema,
      table,
    };
    if (filter) channelConfig.filter = filter;

    const channel: RealtimeChannel = supabase
      .channel(channelName)
      .on(
        "postgres_changes" as any,
        channelConfig,
        (payload: RealtimePostgresChangesPayload<Record<string, unknown>>) => {
          callbackRef.current(payload);
        }
      )
      .subscribe((status) => {
        if (status === "CHANNEL_ERROR") {
          console.error(`Realtime channel "${channelName}" error`);
        }
      });

    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, channelName, table, event, schema, filter, enabled]);
}
```

### Usage

```tsx
// Listen to all challenge updates
useRealtime({
  channelName: `challenge-${challengeId}`,
  table: "challenges",
  event: "UPDATE",
  filter: `id=eq.${challengeId}`,
  onchange: (payload) => {
    setChallengeData(payload.new as Challenge);
  },
});

// Listen to new entries
useRealtime({
  channelName: `entries-${challengeId}`,
  table: "challenge_entries",
  event: "INSERT",
  filter: `challenge_id=eq.${challengeId}`,
  onchange: (payload) => {
    setEntries((prev) => [...prev, payload.new as ChallengeEntry]);
  },
});

// Conditional subscription
useRealtime({
  channelName: `notifications-${userId}`,
  table: "notifications",
  event: "INSERT",
  filter: `user_id=eq.${userId}`,
  enabled: !!userId,  // only subscribe when userId exists
  onchange: (payload) => {
    addNotification(payload.new as Notification);
  },
});
```

### Broadcast Hook

```tsx
// hooks/use-broadcast.ts
"use client";
import { useEffect, useRef, useCallback } from "react";
import { useSupabase } from "@/lib/supabase/client";
import type { RealtimeChannel } from "@supabase/supabase-js";

interface UseBroadcastOptions {
  channelName: string;
  event: string;
  onMessage: (payload: Record<string, unknown>) => void;
  enabled?: boolean;
}

export function useBroadcast({
  channelName,
  event,
  onMessage,
  enabled = true,
}: UseBroadcastOptions) {
  const supabase = useSupabase();
  const channelRef = useRef<RealtimeChannel | null>(null);
  const callbackRef = useRef(onMessage);
  callbackRef.current = onMessage;

  useEffect(() => {
    if (!enabled) return;

    const channel = supabase
      .channel(channelName)
      .on("broadcast", { event }, ({ payload }) => {
        callbackRef.current(payload as Record<string, unknown>);
      })
      .subscribe();

    channelRef.current = channel;

    return () => {
      supabase.removeChannel(channel);
      channelRef.current = null;
    };
  }, [supabase, channelName, event, enabled]);

  const send = useCallback(
    async (payload: Record<string, unknown>) => {
      if (!channelRef.current) return;
      await channelRef.current.send({
        type: "broadcast",
        event,
        payload,
      });
    },
    [event]
  );

  return { send };
}
```

---

## Error Handling & Reconnection

### Subscription status tracking

```tsx
function useRealtimeWithStatus(channelName: string) {
  const supabase = useSupabase();
  const [status, setStatus] = useState<string>("CLOSED");

  useEffect(() => {
    const channel = supabase
      .channel(channelName)
      .on("postgres_changes", { event: "*", schema: "public", table: "challenges" }, handleChange)
      .subscribe((status, err) => {
        setStatus(status);
        if (status === "CHANNEL_ERROR") {
          console.error("Channel error:", err);
        }
        if (status === "TIMED_OUT") {
          // Supabase client auto-retries, but log it
          console.warn("Channel timed out, retrying...");
        }
      });

    return () => { supabase.removeChannel(channel); };
  }, [supabase, channelName]);

  return { status, isConnected: status === "SUBSCRIBED" };
}
```

### Reconnection strategy

Supabase JS client handles reconnection automatically with exponential backoff. For custom control:

```tsx
// Connection status indicator component
function RealtimeStatusBadge() {
  const supabase = useSupabase();
  const [isConnected, setIsConnected] = useState(true);

  useEffect(() => {
    // Monitor the overall realtime connection
    const channel = supabase.channel("connection-monitor").subscribe((status) => {
      setIsConnected(status === "SUBSCRIBED");
    });

    return () => { supabase.removeChannel(channel); };
  }, [supabase]);

  if (isConnected) return null;

  return (
    <div className="fixed bottom-4 right-4 bg-yellow-500/90 text-black px-3 py-1.5 rounded-full text-sm font-medium flex items-center gap-2 z-50">
      <div className="w-2 h-2 rounded-full bg-black animate-pulse" />
      Reconnecting...
    </div>
  );
}
```

### Handling stale data after reconnect

```tsx
function useChallengeWithRecovery(challengeId: string) {
  const supabase = useSupabase();
  const queryClient = useQueryClient();

  useEffect(() => {
    const channel = supabase
      .channel(`challenge-recovery-${challengeId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "challenges",
          filter: `id=eq.${challengeId}`,
        },
        () => {
          // On any change, invalidate cache to refetch fresh data
          // This handles the case where we missed events during disconnect
          queryClient.invalidateQueries({ queryKey: ["challenge", challengeId] });
        }
      )
      .subscribe((status) => {
        if (status === "SUBSCRIBED") {
          // On (re)connect, always refetch to catch any missed updates
          queryClient.invalidateQueries({ queryKey: ["challenge", challengeId] });
        }
      });

    return () => { supabase.removeChannel(channel); };
  }, [supabase, challengeId, queryClient]);
}
```

---

## Channel Limits & Performance

| Limit | Value |
|-------|-------|
| Max channels per client | 100 (default, configurable in project settings) |
| Max message size | 1MB |
| Broadcast rate | 100 messages/second per channel (Pro plan) |
| Postgres Changes | 1 subscription = 1 Postgres replication slot listener |
| Presence payload max | 1MB per tracked state |

### Performance rules

1. **Reuse channels** — combine related listeners on one channel instead of creating separate channels per listener
2. **Use filters** — `filter: "id=eq.123"` is processed server-side, reducing bandwidth
3. **Unsubscribe on unmount** — always `removeChannel` in `useEffect` cleanup
4. **Don't subscribe in loops** — create channels outside `.map()` / `.forEach()`
5. **Limit Presence payload** — only track what's needed (userId, username), not full user objects
6. **Debounce UI updates** — for high-frequency channels (spectator feed), batch updates

### Debounced batch updates for high-frequency channels

```tsx
function useSpectatorFeedBatched() {
  const supabase = useSupabase();
  const [events, setEvents] = useState<SpectatorEvent[]>([]);
  const bufferRef = useRef<SpectatorEvent[]>([]);

  useEffect(() => {
    // Flush buffer every 500ms
    const interval = setInterval(() => {
      if (bufferRef.current.length > 0) {
        setEvents((prev) => [...bufferRef.current, ...prev].slice(0, 100));
        bufferRef.current = [];
      }
    }, 500);

    const channel = supabase
      .channel("spectator:arena")
      .on("broadcast", { event: "agent-action" }, ({ payload }) => {
        bufferRef.current.push(payload as SpectatorEvent);
      })
      .subscribe();

    return () => {
      clearInterval(interval);
      supabase.removeChannel(channel);
    };
  }, [supabase]);

  return events;
}
```

---

## Supabase Dashboard Setup

1. **Enable Realtime for tables**: Database → Replication → select tables (challenges, challenge_entries, agent_profiles, notifications, arena_events)
2. **REPLICA IDENTITY**: For UPDATE/DELETE `payload.old` to contain data, run: `ALTER TABLE public.challenges REPLICA IDENTITY FULL;`
3. **RLS applies to Realtime**: Postgres Changes respect Row Level Security. Users only receive changes for rows they can SELECT.
4. **Broadcast & Presence bypass RLS**: These don't touch the database, so RLS doesn't apply. Validate on the application layer.

---

## Common Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| Not receiving changes | Table replication not enabled | Enable in Dashboard → Database → Replication |
| `payload.old` is empty | Default REPLICA IDENTITY only includes PK | Run `ALTER TABLE ... REPLICA IDENTITY FULL` |
| Changes not filtered | Filter syntax wrong | Use PostgREST syntax: `column=eq.value` (not SQL `=`) |
| Channel error on subscribe | Too many channels or auth issue | Check channel count, verify anon key, check RLS |
| Presence shows duplicates | Same user tracked from multiple tabs | Use a stable key (userId) and deduplicate in `sync` handler |
| Events received after unmount | Missing cleanup | Always `removeChannel` in useEffect return |
| Missed events during disconnect | No recovery mechanism | Invalidate queries on SUBSCRIBED status (refetch fresh data) |
