# Connector & Billing Docs — Polish Reference

## Connector Overview
The Bouts Connector is the integration point between a developer's AI agent and the Bouts platform. Its quality matters enormously because it is the first technical interaction a serious buyer/developer has with the platform.

If docs feel rough or incomplete: the developer loses trust before they ever submit an agent.

## Connector Docs to Audit (Polish Perspective)
Routes: `/docs/connector`, `/docs/connector/setup`, `/docs/api`, `/docs/compete`

### What great connector docs feel like
- Written for the developer who just found Bouts and wants to connect their agent today
- Step-by-step setup that actually works
- API reference with real, tested examples
- Clear explanation of the submission contract (what format, what fields, what gets judged)
- No "coming soon" placeholders where critical info should be
- Tone matches the product: technical, precise, no filler

### What Polish should flag
**P1**:
- Connector docs lead nowhere (no actual setup path)
- API reference has no code examples
- Docs look sparse, placeholder-y, or clearly incomplete
- Version badge stale (v0.1.1 not shown — known P2)

**P2**:
- Docs are complete but feel rough (poor spacing, no code syntax highlighting)
- Setup guide exists but doesn't explain why steps are needed
- API reference is technically complete but unreadable

**P3**:
- Minor copy issues in docs
- Formatting inconsistencies

### The Connector UX Test
Would a developer who found Bouts at 11pm be able to:
1. Understand what they need to do?
2. Install and configure the connector?
3. Make a test submission?
4. Understand how their agent will be judged?

If no → P1 or P0 depending on severity.

---

## Billing & Payments (Polish Perspective)

### Current Status (as of 2026-03-29)
- Stripe NOT live — no payments processing
- Coin wallet exists (profiles.coins and arena_wallets.balance)
- Prize pool calculated (DB trigger, 8% platform fee)
- No coin purchase flow yet
- No prize payout flow yet

### What to audit (when billing goes live)
**Trust signals in billing**:
- Is it clear what you're paying for?
- Are prices stated clearly with no hidden fees?
- Is the 8% platform fee disclosed?
- Is the prize pool calculation transparent?
- Is the refund policy stated?
- Are payment security signals present (SSL, payment processor logos)?

**Billing UX quality**:
- Is the purchase flow simple and fast?
- Is the payment confirmation immediate and clear?
- Is the wallet balance always visible where relevant?
- Are transaction histories readable?

### What Polish should NOT flag as billing issues
- Stripe not being live yet (known, Nick owns this)
- Missing coin purchase UI (not built yet)
- Prize payout flow missing (not built yet)

Only flag billing polish issues when the billing UI actually exists.

---

## Docs Hub Quality Standards
Route: `/docs`

The docs hub should have 4 clear sections:
1. Connector / Setup Guide
2. API Reference
3. Competitor Guide
4. (Optional) Operator/Admin docs

**What good looks like**:
- Clear visual hierarchy between sections
- Entry point for each major user type (developer integrating, competitor competing)
- Real content descriptions, not generic "learn more" links
- Search if enough content to warrant it

**What bad looks like**:
- Flat list of links with no context
- "Coming soon" on primary sections
- All links look the same with no hierarchy
- Docs hub exists but the actual docs pages are sparse
