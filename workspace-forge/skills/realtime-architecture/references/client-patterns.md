# Client Patterns (React Hooks)

## Reconnection with Exponential Backoff

Supabase JS client handles basic reconnection, but for custom resilience:

```tsx
function useResilientChannel(
  channelName: string,
  handlers: {
    onBroadcast?: (event: string, payload: any) => void;
    onPostgresChange?: (payload: any) => void;
    onPresenceSync?: (state: Record<string, any>) => void;
  }
) {
  const channelRef = useRef<RealtimeChannel | null>(null);
  const retryCount = useRef(0);
  const maxRetries = 10;

  const connect = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.unsubscribe();
    }

    const channel = supabase.channel(channelName, { config: { private: true } });

    if (handlers.onBroadcast) {
      channel.on('broadcast', { event: '*' }, ({ event, payload }) => {
        handlers.onBroadcast!(event, payload);
      });
    }

    if (handlers.onPostgresChange) {
      channel.on('postgres_changes', { event: '*', schema: 'public' }, handlers.onPostgresChange);
    }

    if (handlers.onPresenceSync) {
      channel.on('presence', { event: 'sync' }, () => {
        handlers.onPresenceSync!(channel.presenceState());
      });
    }

    channel.subscribe((status, err) => {
      if (status === 'SUBSCRIBED') {
        retryCount.current = 0; // Reset on success
      } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
        if (retryCount.current < maxRetries) {
          // Exponential backoff with jitter
          const delay = Math.min(
            1000 * 2 ** retryCount.current + Math.random() * 1000,
            30_000 // Max 30 seconds
          );
          retryCount.current++;
          setTimeout(connect, delay);
        }
      }
    });

    channelRef.current = channel;
  }, [channelName]);

  useEffect(() => {
    connect();
    return () => {
      channelRef.current?.unsubscribe();
    };
  }, [connect]);

  return channelRef;
}
```

## Channel Cleanup on Unmount

Every `useEffect` that subscribes **must** unsubscribe in cleanup:

```tsx
// ✅ Correct: unsubscribe on unmount
useEffect(() => {
  const channel = supabase.channel('my-channel')
    .on('broadcast', { event: 'update' }, handleUpdate)
    .subscribe();

  return () => {
    channel.unsubscribe(); // Critical: prevents memory leak + ghost listeners
  };
}, []);
```

### Route Change Cleanup

For Next.js App Router, channels in page components auto-cleanup on navigation (React unmounts the component). But for channels in layout components or providers:

```tsx
// RealtimeProvider.tsx — cleanup all channels on auth change
useEffect(() => {
  const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT') {
      // Unsubscribe all channels
      supabase.removeAllChannels();
    }
  });

  return () => subscription.unsubscribe();
}, []);
```

## Max Channels Per User

Enforce in the RealtimeProvider to prevent resource exhaustion:

```tsx
const MAX_CHANNELS_PER_USER = 5;

export function RealtimeProvider({ children }: { children: React.ReactNode }) {
  const channels = useRef(new Map<string, RealtimeChannel>());

  const subscribe = useCallback((name: string, setup: (ch: RealtimeChannel) => void) => {
    // Already subscribed?
    if (channels.current.has(name)) return channels.current.get(name)!;

    // At limit? Remove oldest
    if (channels.current.size >= MAX_CHANNELS_PER_USER) {
      const [oldestName, oldestChannel] = channels.current.entries().next().value;
      oldestChannel.unsubscribe();
      channels.current.delete(oldestName);
    }

    const channel = supabase.channel(name, { config: { private: true } });
    setup(channel);
    channel.subscribe();
    channels.current.set(name, channel);
    return channel;
  }, []);

  const unsubscribe = useCallback((name: string) => {
    const channel = channels.current.get(name);
    if (channel) {
      channel.unsubscribe();
      channels.current.delete(name);
    }
  }, []);

  // Cleanup everything on unmount
  useEffect(() => {
    return () => {
      channels.current.forEach(ch => ch.unsubscribe());
      channels.current.clear();
    };
  }, []);

  return (
    <RealtimeContext.Provider value={{ subscribe, unsubscribe }}>
      {children}
    </RealtimeContext.Provider>
  );
}
```

## Functional State Updates (Avoiding Stale Closures)

Realtime event handlers are registered once in a `useEffect`. If they reference state directly, they capture a stale snapshot:

```tsx
// ❌ Stale: `data` is captured at subscription time
useEffect(() => {
  const channel = supabase.channel('updates')
    .on('broadcast', { event: 'change' }, ({ payload }) => {
      setData([...data, payload]); // `data` is always the initial value
    })
    .subscribe();
  return () => channel.unsubscribe();
}, []); // empty deps = stale

// ✅ Safe: functional update always gets current state
useEffect(() => {
  const channel = supabase.channel('updates')
    .on('broadcast', { event: 'change' }, ({ payload }) => {
      setData(prev => [...prev, payload]); // `prev` is always current
    })
    .subscribe();
  return () => channel.unsubscribe();
}, []); // safe with functional update
```

## Presence for Live Spectator Count

```tsx
function useSpectatorCount(challengeId: string) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const channel = supabase.channel(`presence:challenge:${challengeId}`, {
      config: { private: true }
    });

    channel.on('presence', { event: 'sync' }, () => {
      const state = channel.presenceState();
      setCount(Object.keys(state).length);
    });

    channel.subscribe(async (status) => {
      if (status === 'SUBSCRIBED') {
        // Track self as spectator (anonymous — just a count)
        await channel.track({ joined_at: Date.now() });
      }
    });

    return () => {
      channel.untrack();
      channel.unsubscribe();
    };
  }, [challengeId]);

  return count;
}
```

**Privacy note:** `track()` data is visible to all channel subscribers. Only include non-identifying information. Use `{ joined_at: timestamp }` not `{ user_id, name, email }`.

## Challenge Timer Sync

Server broadcasts authoritative time every 30 seconds. Client uses local countdown for smooth display, corrects drift when server update arrives:

```tsx
function useSyncedTimer(challengeId: string, endsAt: Date) {
  const [remaining, setRemaining] = useState(
    Math.max(0, endsAt.getTime() - Date.now())
  );

  // Local countdown (1Hz)
  useEffect(() => {
    const interval = setInterval(() => {
      setRemaining(Math.max(0, endsAt.getTime() - Date.now()));
    }, 1000);
    return () => clearInterval(interval);
  }, [endsAt]);

  // Server time correction
  useEffect(() => {
    const channel = supabase.channel(`challenge:${challengeId}:timer`, {
      config: { private: true }
    })
    .on('broadcast', { event: 'time_sync' }, ({ payload }) => {
      const drift = Math.abs(payload.remaining_ms - (endsAt.getTime() - Date.now()));
      if (drift > 3000) {
        // Drift > 3s: hard correction
        setRemaining(payload.remaining_ms);
      }
    })
    .subscribe();

    return () => channel.unsubscribe();
  }, [challengeId, endsAt]);

  return remaining;
}
```
