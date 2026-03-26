---
name: webhook-infrastructure
description: Webhook patterns at scale — inbound handling (Stripe, Supabase), outbound sending with retry, monitoring, and dead letter queues.
---

# Webhook Infrastructure

## Inbound Webhook Handling

```ts
// The complete pattern: verify → dedup → process async → return 200
export async function POST(req: NextRequest) {
  const body = await req.text()
  
  // 1. VERIFY SIGNATURE (constant-time comparison)
  const signature = req.headers.get('x-webhook-signature')!
  const timestamp = req.headers.get('x-webhook-timestamp')!
  if (!verifyHMAC(body, signature, timestamp, process.env.WEBHOOK_SECRET!)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 })
  }
  
  // 2. REPLAY PROTECTION (reject old events)
  if (Date.now() - parseInt(timestamp) * 1000 > 5 * 60 * 1000) {
    return NextResponse.json({ error: 'Event too old' }, { status: 400 })
  }
  
  // 3. IDEMPOTENCY CHECK
  const event = WebhookSchema.parse(JSON.parse(body))
  const { data: existing } = await supabase
    .from('processed_events').select('id').eq('event_id', event.id).single()
  if (existing) return NextResponse.json({ received: true })
  
  // 4. RETURN 200 IMMEDIATELY (process async)
  // If processing takes >5s and you return 500, sender retries = duplicates
  await supabase.from('jobs').insert({
    type: 'process_webhook',
    payload: event,
  })
  
  await supabase.from('processed_events').insert({ event_id: event.id })
  return NextResponse.json({ received: true })
}
```

## Outbound Webhook Sending

```ts
async function sendWebhook(endpoint: string, payload: unknown, secret: string) {
  const body = JSON.stringify(payload)
  const timestamp = Math.floor(Date.now() / 1000).toString()
  const signature = createHmac('sha256', secret)
    .update(`${timestamp}.${body}`)
    .digest('hex')
  
  const MAX_ATTEMPTS = 5
  
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Signature': signature,
          'X-Webhook-Timestamp': timestamp,
        },
        body,
        signal: AbortSignal.timeout(10000), // 10s timeout
      })
      
      await supabase.from('webhook_deliveries').insert({
        endpoint, attempt, status: response.status, success: response.ok
      })
      
      if (response.ok) return // success
      if (response.status >= 400 && response.status < 500) return // don't retry client errors
      
    } catch (error) {
      await supabase.from('webhook_deliveries').insert({
        endpoint, attempt, status: 0, error: String(error), success: false
      })
    }
    
    // Exponential backoff with jitter
    const delay = 1000 * Math.pow(4, attempt) + Math.random() * 1000
    await new Promise(r => setTimeout(r, delay))
  }
  
  // All attempts failed → dead letter queue
  await supabase.from('dead_letter_queue').insert({
    type: 'webhook', endpoint, payload, attempts: MAX_ATTEMPTS
  })
}
```

## Monitoring

| Metric | Alert |
|--------|-------|
| Success rate per endpoint | <90% → notify |
| Average delivery latency | >5s → investigate |
| Consecutive failures | >100 → auto-disable endpoint |
| DLQ depth | >50 → urgent review |

## Sources
- Stripe webhook best practices
- Svix (webhook infrastructure service) patterns
- cal.com webhook implementation

## Changelog
- 2026-03-21: Initial skill — webhook infrastructure
