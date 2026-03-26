---
name: stripe-payment-patterns
description: Stripe Checkout, subscriptions, webhook handling, one-time payments, and Supabase integration patterns. Covers the complete payment lifecycle for Arena and OUTBOUND.
---

# Stripe Payment Patterns

## Security Checklist

1. [ ] Secret key NEVER in client code or `NEXT_PUBLIC_` env vars
2. [ ] Webhook signature verified with `stripe.webhooks.constructEvent()`
3. [ ] Payment amounts calculated server-side (never trust client prices)
4. [ ] Idempotency on all webhook handlers (check `event.id` before processing)
5. [ ] Failed payment handling exists (not just happy path)
6. [ ] Subscription status checked on every protected route
7. [ ] No raw Stripe objects returned to client

---

## Subscription Lifecycle

```
trial → active → past_due → canceled
                     ↓
                  unpaid → canceled
```

| State | Meaning | App Action |
|-------|---------|------------|
| `trialing` | Free trial active | Full access, show days remaining |
| `active` | Paying customer | Full access |
| `past_due` | Payment failed, retrying | Show warning banner, full access for grace period |
| `canceled` | Subscription ended | Downgrade to free tier immediately |
| `unpaid` | All retries exhausted | Block premium features |

## Webhook Handler (Complete Implementation)

```ts
// app/api/webhooks/stripe/route.ts
import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'
import { createClient } from '@supabase/supabase-js'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // service role for writes
)

export async function POST(req: NextRequest) {
  const body = await req.text()
  const sig = req.headers.get('stripe-signature')!
  
  // 1. VERIFY SIGNATURE (mandatory)
  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  } catch (err) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }
  
  // 2. IDEMPOTENCY CHECK
  const { data: existing } = await supabase
    .from('processed_events').select('id').eq('event_id', event.id).single()
  if (existing) return NextResponse.json({ received: true }) // already processed
  
  // 3. PROCESS EVENT
  try {
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutComplete(event.data.object as Stripe.Checkout.Session)
        break
      case 'customer.subscription.updated':
        await handleSubscriptionUpdate(event.data.object as Stripe.Subscription)
        break
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription)
        break
      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object as Stripe.Invoice)
        break
    }
  } catch (err) {
    console.error(`[stripe-webhook] Failed: ${event.type}`, err)
    return NextResponse.json({ error: 'Processing failed' }, { status: 500 })
  }
  
  // 4. MARK AS PROCESSED
  await supabase.from('processed_events').insert({ event_id: event.id, type: event.type })
  
  return NextResponse.json({ received: true })
}

async function handleCheckoutComplete(session: Stripe.Checkout.Session) {
  const userId = session.metadata?.user_id
  if (!userId) throw new Error('Missing user_id in metadata')
  
  await supabase.from('subscriptions').upsert({
    user_id: userId,
    stripe_customer_id: session.customer as string,
    stripe_subscription_id: session.subscription as string,
    plan_tier: session.metadata?.plan_tier ?? 'pro',
    status: 'active',
  }, { onConflict: 'user_id' })
}

async function handleSubscriptionUpdate(sub: Stripe.Subscription) {
  await supabase.from('subscriptions').update({
    status: sub.status,
    plan_tier: sub.items.data[0]?.price?.lookup_key ?? 'pro',
    current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
  }).eq('stripe_subscription_id', sub.id)
}

async function handleSubscriptionDeleted(sub: Stripe.Subscription) {
  await supabase.from('subscriptions').update({
    status: 'canceled',
    plan_tier: 'free',
  }).eq('stripe_subscription_id', sub.id)
}

async function handlePaymentFailed(invoice: Stripe.Invoice) {
  if (!invoice.subscription) return
  await supabase.from('subscriptions').update({
    status: 'past_due',
  }).eq('stripe_subscription_id', invoice.subscription as string)
}
```

## Supabase Schema for Subscriptions

```sql
CREATE TABLE subscriptions (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  stripe_customer_id text,
  stripe_subscription_id text,
  plan_tier text NOT NULL DEFAULT 'free',
  status text NOT NULL DEFAULT 'inactive',
  current_period_end timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can read their own sub
CREATE POLICY "read_own" ON subscriptions FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- Only service role can write (webhook handler)
-- No INSERT/UPDATE policy for authenticated = client can't modify

CREATE TABLE processed_events (
  event_id text PRIMARY KEY,
  type text NOT NULL,
  processed_at timestamptz DEFAULT now()
);
```

## One-Time Payments (Arena Coins)

```ts
// Server Action: create checkout for coin purchase
'use server'
export async function purchaseCoins(packageId: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Unauthorized' }
  
  const PACKAGES: Record<string, { amount: number; coins: number }> = {
    'coins_500': { amount: 499, coins: 500 },
    'coins_2000': { amount: 1499, coins: 2000 },
  }
  
  const pkg = PACKAGES[packageId]
  if (!pkg) return { error: 'Invalid package' }
  
  const session = await stripe.checkout.sessions.create({
    mode: 'payment', // one-time, not subscription
    line_items: [{ price_data: {
      currency: 'usd',
      product_data: { name: `${pkg.coins} Arena Coins` },
      unit_amount: pkg.amount,
    }, quantity: 1 }],
    metadata: { user_id: user.id, coins: String(pkg.coins) },
    success_url: `${process.env.NEXT_PUBLIC_URL}/coins/success`,
    cancel_url: `${process.env.NEXT_PUBLIC_URL}/coins`,
  })
  
  return { url: session.url }
}
// Fulfillment via checkout.session.completed webhook, NOT redirect
```

## Sources
- stripe/stripe-node SDK documentation
- vercel/nextjs-subscription-payments template (canonical reference)
- Stripe webhook best practices documentation

## Changelog
- 2026-03-21: Initial skill — Stripe payment patterns
