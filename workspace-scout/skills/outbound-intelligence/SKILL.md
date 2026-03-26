---
name: outbound-intelligence
description: Scout research skill — Signal-Based Outbound & Lead Scoring for evaluating outbound SaaS ideas and designing cold outreach strategy for UberKiwi and OUTBOUND.
---

# Skill: Outbound Intelligence

Frameworks for evaluating outbound/sales-driven products and designing actual cold outreach. Use when: (1) evaluating whether an outbound SaaS idea has legs, (2) designing OUTBOUND's lead gen pipeline, (3) planning UberKiwi's cold email strategy.

Source: agency-agents/sales/sales-outbound-strategist.md

## Signal-Based Selling Framework

Modern outbound converts 4-8x better when triggered by buying signals vs. untargeted cold outreach. Every outbound product or strategy should be evaluated against this hierarchy:

### Signal Tiers (Ranked by Intent Strength)

**Tier 1 — Active Buying Signals (Highest Priority)**
- Direct intent: G2/review site visits, pricing page views, competitor comparison searches
- RFP or vendor evaluation announcements
- Technology evaluation job postings
- *OUTBOUND example: A prospect visits 3 competitor pricing pages in one week → trigger immediate personalized outreach*
- *UberKiwi example: SMB posts "looking for web designer" in local Facebook group → same-day DM*

**Tier 2 — Organizational Change Signals**
- Leadership changes in the buying persona's function (new VP = new priorities)
- Funding events (Series B+ = budget + urgency)
- Hiring surges in the department your product serves (scaling pain is real)
- M&A activity (integration = tool consolidation pressure)
- *Agent Arena example: AI startup raises Series A and posts 5 ML engineer jobs → they need agent tooling*

**Tier 3 — Technographic & Behavioral Signals**
- Tech stack changes (BuiltWith, Wappalyzer, job postings)
- Conference attendance or speaking on adjacent topics
- Content engagement: downloads, webinar attendance, social engagement
- Competitor contract renewal timing
- *OUTBOUND example: Prospect's current email tool (Mailchimp) shows up in their job posting as "migrating from" → they're evaluating alternatives*

### Speed-to-Signal Rule
Signal half-life is short:
- < 30 minutes: Optimal response window
- < 24 hours: Still warm
- > 72 hours: A competitor already had the conversation
- *Implication for OUTBOUND product: real-time signal routing is a MUST-HAVE feature, not nice-to-have*

## ICP Refinement Framework

A useful ICP is falsifiable. If it doesn't exclude companies, it's a TAM slide, not an ICP.

### ICP Definition Template

```
FIRMOGRAPHIC FILTERS
- Industry verticals: [2-4 specific, not "enterprise"]
- Revenue range or employee count band
- Geography
- Technology stack requirements (what must they already use?)

BEHAVIORAL QUALIFIERS
- What business event makes them a buyer RIGHT NOW?
- What pain does your product solve that they cannot ignore?
- Who inside the org feels that pain most acutely?
- What does their current workaround look like?

DISQUALIFIERS (equally important — most ICPs skip this)
- What makes an account look good on paper but never close?
- Industries or segments where win rate is below 15%
- Company stages where the product is premature or overkill
```

### UberKiwi ICP Example
```
FIRMOGRAPHIC: Local service businesses (plumbers, dentists, realtors), 1-20 employees, US-based, no existing website OR website older than 3 years
BEHAVIORAL: Just opened a new location, got a bad Google review mentioning "couldn't find your website", or hiring their first marketing person
DISQUALIFIERS: Franchises (corporate controls web), businesses with existing agency relationship under contract, businesses that explicitly say "I don't need a website"
```

### OUTBOUND ICP Example
```
FIRMOGRAPHIC: B2B SaaS companies, 10-200 employees, Series A-B, using Salesforce or HubSpot
BEHAVIORAL: SDR team growing (hiring 3+ reps), current reply rates below 5%, recently appointed VP Sales
DISQUALIFIERS: Enterprise-only sales motion (no outbound volume), companies already using 3+ outbound tools (tool fatigue), companies with < 100 target accounts (too small for outbound tooling)
```

## Tiered Account Engagement Model

**Tier 1 (Top 50-100 accounts): Deep, Multi-Threaded**
- Full account research: 10-K, earnings, strategic initiatives
- Multi-thread: 3-5 contacts (economic buyer, champion, influencer, end user)
- Custom messaging per persona referencing account-specific initiatives
- *UberKiwi Tier 1: Local businesses Nick personally knows or has warm intros to*

**Tier 2 (Next 200-500): Semi-Personalized**
- Industry-specific messaging with account-level personalization in opening line
- 2-3 contacts per account
- Signal-triggered sequence enrollment
- *UberKiwi Tier 2: Businesses found via Google Maps with bad/no websites in target metros*

**Tier 3 (Remaining ICP-fit): Automated with Light Personalization**
- Industry and role-based sequences with dynamic tokens
- Single contact per account
- Signal-triggered enrollment only
- *OUTBOUND product: This tier is what OUTBOUND should automate — the tool should make Tier 3 feel like Tier 2*

## Multi-Channel Sequence Architecture

### 10-Touch Sequence Template (3-4 weeks)
```
Touch 1  (Day 1,  Email):    Signal-based opening + specific value prop + soft CTA
Touch 2  (Day 3,  LinkedIn): Connection request with personalized note (no pitch)
Touch 3  (Day 5,  Email):    Share relevant insight/data tied to their situation
Touch 4  (Day 8,  Phone):    Call + voicemail referencing email thread
Touch 5  (Day 10, LinkedIn): Engage with their content or share relevant content
Touch 6  (Day 14, Email):    Case study from similar company + clear CTA
Touch 7  (Day 17, Video):    60-second personalized Loom showing something specific
Touch 8  (Day 21, Email):    New angle — different pain point or stakeholder perspective
Touch 9  (Day 24, Phone):    Final call attempt
Touch 10 (Day 28, Email):    Breakup email — honest, brief, leave door open
```

### Cold Email Anatomy (High-Converting)

**Subject line:** 3-5 words, lowercase, looks like an internal email. Never clickbait/ALL CAPS/emoji.
- Good: "re: the new data team"
- Bad: "🚀 Scale Your Revenue 10x!"

**Opening line (signal-based, personalized):**
- Bad: "I hope this email finds you well."
- Bad: "I'm reaching out because [company] helps companies like yours..."
- Good: "Saw you just hired 4 data engineers — scaling the analytics team usually means the current tooling is hitting its ceiling."

**Value prop (buyer's language, one sentence):**
- Use their vocabulary, not marketing copy
- Specificity beats cleverness: numbers, timeframes, concrete outcomes

**Social proof (optional, one line):**
- "[Similar company] cut their [metric] by [number] in [timeframe]"

**CTA (single, clear, low friction):**
- Bad: "Would love to set up a 30-minute call to walk you through a demo"
- Good: "Worth a 15-minute conversation to see if this applies to your team?"

### Reply Rate Benchmarks
| Approach | Expected Reply Rate |
|----------|-------------------|
| Generic, untargeted | 1-3% |
| Role/industry personalized | 5-8% |
| Signal-based with account research | 12-25% |
| Warm intro / referral | 30-50% |

*Use these benchmarks when evaluating outbound SaaS ideas: if the product can move users from 1-3% to 12-25%, that's a real value prop.*

## Evaluating Outbound SaaS Ideas (Scout Application)

When researching an outbound/sales tool idea, score against:

1. **Does it help detect signals?** (Tier 1/2/3 from above)
2. **Does it help act on signals faster?** (Speed-to-signal)
3. **Does it help personalize at scale?** (Moving Tier 3 engagement to feel like Tier 2)
4. **Does it help measure what works?** (Reply rates, conversion, channel effectiveness)
5. **Does it integrate with existing workflow?** (Salesforce, HubSpot, Gmail, LinkedIn)

If the product only does 1 of these 5, it's a feature, not a product. If it does 3+, it's worth evaluating further.

## Changelog
- 2026-03-22: Created from agency-agents/sales-outbound-strategist.md — adapted for OUTBOUND product evaluation and UberKiwi sales
