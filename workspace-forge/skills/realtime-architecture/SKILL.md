---
name: realtime-architecture
description: Architecture patterns for Supabase Realtime in competitive/live applications. Covers channel design, broadcast vs postgres_changes, presence, scaling, anti-cheat delays, reconnection, cleanup, security (RLS on realtime, channel auth, anti-spoofing), performance (batching, throttling, filters). Includes decision framework for Realtime vs polling vs SSE.
---

# Realtime Architecture

## Decision Framework: Realtime vs Polling vs SSE

Choose the right transport for each data type:

| Data Type | Transport | Why |
|---|---|---|
| Spectator events (live feed) | **Supabase Broadcast** | Ephemeral, high-frequency, many consumers |
| Leaderboard rank changes | **Postgres Changes** | Persisted, low-frequency, needs RLS |
| Challenge status transitions | **Postgres Changes** | Persisted, low-frequency, triggers UI state |
| Notification count (nav bell) | **Postgres Changes** | Persisted, per-user, needs RLS |
| Live spectator count | **Presence** | Ephemeral, aggregate count, auto-cleanup |
| Challenge timer sync | **Broadcast** | Ephemeral, server-authoritative, low-frequency |
| Agent online/offline status | **Polling (30s)** | Derived from heartbeat, not worth a channel |
| ELO history chart data | **HTTP fetch** | Static after calculation, no live updates |
| Dashboard stats | **HTTP fetch + 30s poll** | Aggregated, too expensive for realtime |
| Admin job queue | **Polling (5s)** | Admin-only, low user count, simple |

### When NOT to Use Realtime
- Data that changes less than once per minute → poll
- Data visible to only 1 user with no urgency → poll
- Large payloads (> 100KB) → HTTP fetch
- Data requiring complex JOINs → HTTP fetch (Postgres Changes only sends the changed row)

For detailed patterns on each transport, see:
- **Channel design & broadcast** → [references/channels.md](references/channels.md)
- **Security & anti-spoofing** → [references/security.md](references/security.md)
- **Performance & scaling** → [references/performance.md](references/performance.md)
- **Client patterns (React hooks)** → [references/client-patterns.md](references/client-patterns.md)

---

## Quick Reference — Code Review Checklist

1. [ ] Every Broadcast channel uses `config: { private: true }` — never public
2. [ ] Every `useEffect` with `.subscribe()` returns cleanup with `.unsubscribe()`
3. [ ] Realtime event handlers use functional state updates (`setData(prev => ...)`)
4. [ ] Spectator delay is 30s **server-side**, not client `setTimeout`
5. [ ] Max 5 concurrent channels per user enforced in RealtimeProvider
6. [ ] Reconnection uses exponential backoff with jitter
7. [ ] High-frequency events (spectator feed) are batched to ≤ 2 broadcasts/second
8. [ ] Postgres Changes filters use column filters to reduce payload
9. [ ] Presence tracks only aggregate counts, never individual user details
10. [ ] All channels unsubscribe on route change / component unmount
