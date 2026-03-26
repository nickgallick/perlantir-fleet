---
name: payment-webhook-security
description: Security patterns for Stripe payment integration, webhook verification, and financial transaction safety in Next.js + Supabase applications. Use when reviewing Stripe checkout flows, webhook handlers, subscription management, payment intent processing, refund logic, pricing endpoints, or any code that handles money. Covers CVE-2026-21894 (n8n missing Stripe-Signature verification — forged webhooks), CVE-2026-2890 (payment reuse for higher-cost items), legacy Stripe API skimming, webhook replay attacks, price manipulation, subscription state bypasses, and idempotency requirements.
---

# Payment & Webhook Security

## Why This Is P0

If an attacker can forge a webhook event that says "payment succeeded," they get your product for free. If they can manipulate prices, they pay $0.01 for a $999 product. If they can replay a payment, one transaction covers unlimited purchases.

**Real CVEs in 2026**:
- CVE-2026-21894: n8n's Stripe webhook handler never verified `Stripe-Signature` header. Anyone who knew the webhook URL could forge any Stripe event.
- CVE-2026-2890: Formidable Forms allowed reusing a low-value Stripe PaymentIntent for a higher-cost purchase.

## The #1 Rule: Verify Webhook Signatures

### The Vulnerability
```typescript
// CRITICALLY VULNERABLE — no signature verification
export async function POST(request: Request) {
  const event = await request.json()  // Trusts any POST as a Stripe event
  
  if (event.type === 'payment_intent.succeeded') {
    await activateSubscription(event.data.object.customer)  // Free subscription
  }
}
```

An attacker sends:
```bash
curl -X POST https://your-app.com/api/webhooks/stripe \
  -H "Content-Type: application/json" \
  -d '{"type":"payment_intent.succeeded","data":{"object":{"customer":"cus_victim","amount":0}}}'
```

### The Fix (Non-Negotiable)
```typescript
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!

export async function POST(request: Request) {
  const body = await request.text()  // Raw body for signature verification
  const signature = request.headers.get('stripe-signature')!
  
  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err) {
    console.error('Webhook signature verification failed:', err)
    return new Response('Invalid signature', { status: 400 })
  }
  
  // NOW safe to process — Stripe's signature confirms authenticity
  switch (event.type) {
    case 'payment_intent.succeeded':
      await handlePaymentSuccess(event.data.object as Stripe.PaymentIntent)
      break
    case 'customer.subscription.updated':
      await handleSubscriptionUpdate(event.data.object as Stripe.Subscription)
      break
  }
  
  return new Response('OK', { status: 200 })
}
```

### Critical Implementation Details
1. **Use `request.text()` not `request.json()`** — signature is computed over the raw body bytes
2. **`stripe-signature` header is required** — reject requests without it
3. **Webhook secret is per-endpoint** — different from your Stripe secret key
4. **Don't `JSON.parse` before verifying** — the raw string IS the signed payload
5. **Next.js App Router**: disable body parsing if it interferes with raw body access

## Webhook Event Processing Security

### Idempotency (Process Each Event Once)
```typescript
async function handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent) {
  // Check if already processed (idempotent)
  const { data: existing } = await supabase
    .from('processed_events')
    .select('id')
    .eq('stripe_event_id', paymentIntent.id)
    .single()
  
  if (existing) return  // Already processed
  
  // Process the payment
  await supabase.from('orders').update({ status: 'paid' })
    .eq('stripe_payment_intent_id', paymentIntent.id)
  
  // Mark as processed (atomically — use upsert with unique constraint)
  await supabase.from('processed_events').upsert({
    stripe_event_id: paymentIntent.id,
    processed_at: new Date().toISOString()
  })
}
```

**Why**: Stripe may send the same event multiple times (retries). Without idempotency, a user could get credited multiple times.

### Verify Event Data Against Your Database
```typescript
// DON'T: Trust the amount from the webhook
await creditUser(event.data.object.amount)  // Attacker-controlled if unverified

// DO: Look up the original intent from Stripe
const paymentIntent = await stripe.paymentIntents.retrieve(event.data.object.id)
const order = await getOrderByPaymentIntent(paymentIntent.id)

// Verify amount matches what you expected
if (paymentIntent.amount !== order.expected_amount) {
  console.error('Amount mismatch — potential manipulation')
  return
}

await creditUser(order.expected_amount)  // Your trusted value
```

### Handle ALL Relevant Event Types
```typescript
// Don't just listen for success — handle failures and disputes
switch (event.type) {
  case 'payment_intent.succeeded': handleSuccess(event); break
  case 'payment_intent.payment_failed': handleFailure(event); break
  case 'charge.dispute.created': handleDispute(event); break
  case 'charge.refunded': handleRefund(event); break
  case 'customer.subscription.deleted': handleCancellation(event); break
  case 'invoice.payment_failed': handleInvoiceFailure(event); break
}
```

Missing `charge.refunded` handler = user pays, gets product, gets refund, keeps product.

## Checkout Flow Security

### Server-Side Price Determination
```typescript
// VULNERABLE — price from client
const session = await stripe.checkout.sessions.create({
  line_items: [{
    price_data: {
      unit_amount: req.body.price,  // Attacker sends 1 cent
      currency: 'usd',
      product_data: { name: req.body.productName }
    },
    quantity: req.body.quantity
  }]
})

// SAFE — price from server
const product = await getProduct(req.body.productId)  // Server lookup
if (!product) throw new Error('Invalid product')

const session = await stripe.checkout.sessions.create({
  line_items: [{
    price: product.stripe_price_id,  // Pre-configured Stripe Price object
    quantity: Math.min(Math.max(1, parseInt(req.body.quantity)), 100)
  }]
})
```

### Use Stripe Price Objects (Not Ad-Hoc Prices)
Pre-create prices in Stripe dashboard or via API. Reference by `price_id`, never construct `price_data` from user input.

### Validate Checkout Session Completion
```typescript
// After redirect from Stripe Checkout
export async function GET(request: Request) {
  const sessionId = new URL(request.url).searchParams.get('session_id')
  
  // ALWAYS verify with Stripe — don't trust the redirect alone
  const session = await stripe.checkout.sessions.retrieve(sessionId!)
  
  if (session.payment_status !== 'paid') {
    return redirect('/payment-failed')
  }
  
  // Verify this session belongs to the authenticated user
  const user = await getUser()
  if (session.metadata?.user_id !== user.id) {
    return redirect('/unauthorized')
  }
  
  await activateSubscription(user.id, session)
}
```

## Subscription Security

### State Machine
```
                ┌─────────────┐
                │   CREATED   │
                └──────┬──────┘
                       │ payment_intent.succeeded
                ┌──────▼──────┐
                │   ACTIVE    │◄──── invoice.paid (renewal)
                └──┬───┬──────┘
    dispute.created│   │ subscription.updated (cancel)
                ┌──▼── ▼──────┐
                │  PAST_DUE   │
                └──────┬──────┘
                       │ invoice.payment_failed (final)
                ┌──────▼──────┐
                │  CANCELED   │
                └─────────────┘
```

### Common Subscription Bypass Patterns
- [ ] **Direct API access to premium features without subscription check**: Frontend hides UI but API endpoint doesn't verify plan
- [ ] **Subscription check uses cached/stale data**: User cancels but cache still says active
- [ ] **Grace period abuse**: Cancel → get refund → use product during grace period → re-subscribe
- [ ] **Plan downgrade without feature removal**: Downgrade from premium to free but keep premium features active in DB
- [ ] **Trial abuse**: Create new account → start trial → cancel before charge → repeat

### Server-Side Subscription Verification
```typescript
async function requireSubscription(userId: string, requiredPlan: string = 'pro') {
  // Always check current Stripe subscription state — not cached data
  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('stripe_subscription_id, status, plan')
    .eq('user_id', userId)
    .single()
  
  if (!subscription || subscription.status !== 'active') {
    throw new Error('Active subscription required')
  }
  
  // For critical operations, verify with Stripe directly
  if (requiredPlan === 'enterprise') {
    const stripeSub = await stripe.subscriptions.retrieve(subscription.stripe_subscription_id)
    if (stripeSub.status !== 'active') {
      // DB is stale — update and reject
      await supabase.from('subscriptions')
        .update({ status: stripeSub.status })
        .eq('user_id', userId)
      throw new Error('Subscription not active in Stripe')
    }
  }
}
```

## Refund Security

### Refund Amount Validation
```typescript
// VULNERABLE — trusts client-provided refund amount
async function processRefund(orderId: string, amount: number) {
  await stripe.refunds.create({ payment_intent: order.payment_intent_id, amount })
}

// SAFE — validate against original payment
async function processRefund(orderId: string, amount: number) {
  const order = await getOrder(orderId)
  const paymentIntent = await stripe.paymentIntents.retrieve(order.payment_intent_id)
  
  // Can't refund more than was paid
  if (amount > paymentIntent.amount) {
    throw new Error('Refund amount exceeds payment')
  }
  
  // Can't refund more than remaining (after previous refunds)
  const existingRefunds = await stripe.refunds.list({ payment_intent: order.payment_intent_id })
  const totalRefunded = existingRefunds.data.reduce((sum, r) => sum + r.amount, 0)
  
  if (amount + totalRefunded > paymentIntent.amount) {
    throw new Error('Total refunds would exceed payment amount')
  }
  
  await stripe.refunds.create({ payment_intent: order.payment_intent_id, amount })
}
```

## Review Checklist

### Webhook Endpoint
- [ ] Signature verified using `stripe.webhooks.constructEvent()`
- [ ] Raw body used (not parsed JSON) for signature verification
- [ ] Requests without `stripe-signature` header are rejected
- [ ] Event processing is idempotent (duplicate events don't double-credit)
- [ ] Event data is verified against Stripe API (not just trusted from webhook)
- [ ] All relevant event types are handled (including failures, disputes, refunds)
- [ ] Webhook endpoint is not exposed in frontend code or docs

### Checkout
- [ ] Prices come from server/Stripe Price objects, never from client
- [ ] Quantities are validated and bounded
- [ ] Checkout session completion is verified with Stripe API
- [ ] Session metadata ties to authenticated user
- [ ] Success redirect can't be spoofed without valid session

### Subscriptions
- [ ] Subscription status checked server-side on every premium feature access
- [ ] Subscription changes (upgrade/downgrade/cancel) update both Stripe and DB
- [ ] Grace periods are correctly handled
- [ ] Trial limits enforced (one per user/email)
- [ ] Feature access revoked immediately on cancellation (or at period end, as intended)

### Refunds
- [ ] Refund amounts validated against original payment
- [ ] Cumulative refunds can't exceed total payment
- [ ] Product/feature access revoked on refund
- [ ] Partial refund logic is correct

## References

For business logic patterns around payments, see `business-logic-exploitation` skill.
For race conditions in payment flows, see `race-condition-async` skill.
