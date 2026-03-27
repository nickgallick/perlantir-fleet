# Realtime Security

## RLS on Realtime

### Postgres Changes
Automatically respects table-level RLS. If a user can't SELECT a row via RLS, they won't receive the change event for that row. No additional configuration needed.

```sql
-- This RLS policy automatically filters realtime events:
CREATE POLICY "notifications_select_own" ON notifications
  FOR SELECT USING (auth.uid() = user_id);
-- User A will never receive User B's notification INSERT events
```

### Broadcast & Presence
**No automatic RLS.** Must use `private: true` on channel config:

```ts
// ❌ INSECURE: any authenticated user can read/write
const channel = supabase.channel('challenge:abc123:events');

// ✅ SECURE: requires realtime.messages RLS policy
const channel = supabase.channel('challenge:abc123:events', {
  config: { private: true }
});
```

With `private: true`, Supabase checks the `realtime.messages` table RLS before allowing subscribe or send. You need a policy:

```sql
-- Allow authenticated users to subscribe to challenge spectator channels
CREATE POLICY "allow_spectator_channels" ON realtime.messages
  FOR SELECT TO authenticated
  USING (
    -- Allow subscription to any challenge spectator channel
    realtime.topic() LIKE 'challenge:%:events'
    OR realtime.topic() LIKE 'presence:challenge:%'
    OR realtime.topic() LIKE 'challenge:%:timer'
    -- Allow own notification channel
    OR realtime.topic() = 'notifications:' || auth.uid()::text
    -- Allow leaderboard channels
    OR realtime.topic() LIKE 'leaderboard:%'
  );
```

## Channel Authorization

### Preventing Event Spoofing

Problem: with Broadcast, any subscribed client can also SEND messages to the channel (if not restricted).

Solution: spectator channels are **read-only for clients**. Only the server (service role) sends events.

```sql
-- Clients can read but not write to spectator channels
CREATE POLICY "spectator_read_only" ON realtime.messages
  FOR INSERT TO authenticated
  USING (
    -- Only allow sending to user-specific channels (e.g., own presence track)
    realtime.topic() = 'presence:challenge:' || realtime.topic()
    -- Block all other sends
    AND false  -- effectively: no client can broadcast
  );
```

In practice, the simplest approach: **never use client-side broadcast sends for competitive data.** All spectator events and leaderboard updates originate from server-side (service role) calls only.

### Per-Agent Spectator Privacy

Agents with `allow_spectators = false` should not have their events broadcast. Enforce server-side:

```ts
// In the event buffering logic:
async function shouldBroadcast(entryId: string): Promise<boolean> {
  const { data } = await supabase
    .from('entries')
    .select('agents(allow_spectators)')
    .eq('id', entryId)
    .single();

  return data?.agents?.allow_spectators ?? false;
}
```

Also enforce in RLS on `replay_events` table (see competitive-platform-integrity skill).

## Token Security

### Channel Names as Access Control

Never encode sensitive data in channel names. Channel names are visible to any subscriber.

```
❌ Bad:  channel "user:sk_live_xxx:notifications"
✅ Good: channel "notifications:user-uuid"
```

### Subscription Limits

Enforce max channels per connection to prevent resource exhaustion:

```tsx
// RealtimeProvider.tsx
const MAX_CHANNELS = 5;
const activeChannels = useRef(new Set<string>());

function subscribe(channelName: string) {
  if (activeChannels.current.size >= MAX_CHANNELS) {
    // Unsubscribe oldest channel
    const oldest = activeChannels.current.values().next().value;
    supabase.channel(oldest).unsubscribe();
    activeChannels.current.delete(oldest);
  }
  activeChannels.current.add(channelName);
  return supabase.channel(channelName, { config: { private: true } });
}
```
