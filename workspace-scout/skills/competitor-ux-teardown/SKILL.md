---
name: competitor-ux-teardown
description: Scout research skill — Competitor UX Teardown & Design Handoff
---

# Skill: Competitor UX Teardown

Bridge the gap between finding competitors (competitive-intelligence) and handing design intel to Maks (action-triggers). This skill extracts the specific UX patterns, trust signals, and conversion tactics that Maks needs to build something better.

## When to Use
- After competitive-intelligence identifies 3-5 competitors
- Before any "go" handoff to Maks
- When Nick says "dig deeper" on a surviving idea

## Step 1: Map Each Competitor's User Journey

For each top competitor (3 minimum), document the full flow:

### Landing Page → Signup
- **First impression**: What do you see above the fold? (headline, subheadline, hero image/demo, CTA)
- **Trust signals**: Logos, testimonials, review badges, "Used by X companies", security badges
- **Pricing visibility**: Is pricing shown upfront or hidden behind "Contact Sales"?
- **CTA copy**: What does the button say? (e.g., "Start Free Trial" vs "Get Started" vs "Book a Demo")
- **Social proof placement**: Where and how? (inline, dedicated section, floating badge)

### Signup → First Value
- **Signup friction**: Email only? Google SSO? Credit card required?
- **Onboarding steps**: How many screens between signup and doing the core thing?
- **Empty state**: What does the user see when they first log in? (guided tour, sample data, blank page)
- **Time to value**: How long from signup to the first "aha" moment? Measure it.

### Core Product Experience
- **Navigation pattern**: Sidebar, top nav, tab bar, command palette?
- **Information density**: Clean/minimal vs data-heavy dashboard?
- **Primary action**: What's the most prominent thing you can do? Is it obvious?
- **Design language**: Modern/polished or dated/cluttered? Dark mode? Typography quality?

### Free → Paid Trigger
- **What's gated**: Which features are behind the paywall?
- **Upgrade prompt**: How and when do they push you to pay? (hard wall, soft nudge, usage limit)
- **Pricing page patterns**: Tiers, annual discount, enterprise "Contact Us", money-back guarantee

## Step 2: Extract Patterns for Maks

### Trust Signal Inventory
Document every trust mechanism found across competitors. Examples from Perlantir products:
- **FinanceCalc** (hypothetical lending tool): Would need compliance badges, bank-grade security language, "Your data is encrypted" messaging — because fintech users won't enter sensitive info without visible trust
- **GolfScenario Pro** (hypothetical golf SaaS): Would need pro golfer endorsements, course partnership logos, tournament badges — because sports audiences trust credibility over corporate polish
- **AI Builder Tool**: Would need GitHub stars, "Built by developers" messaging, open-source components, technical blog posts — because dev tools earn trust through transparency

### UX Patterns Worth Stealing
For each pattern, note:
- What competitor uses it
- Why it works for THIS audience
- How Perlantir should adapt it (not copy — improve)

Example: If building a fintech dashboard and Competitor X has an excellent risk visualization — describe the pattern, why it builds confidence, and how Nick's lending expertise could make it more accurate.

### UX Antipatterns to Avoid
Document what competitors get wrong:
- Cluttered dashboards that overwhelm new users
- Aggressive upgrade nags that feel desperate
- Poor empty states that leave users confused
- Slow onboarding that delays the value moment
- Generic templates when the audience expects domain-specific polish

## Step 3: Conversion Funnel Comparison

| Stage | Competitor A | Competitor B | Competitor C | Our Approach |
|-------|-------------|-------------|-------------|-------------|
| Landing → Signup | % or friction level | | | |
| Signup → First Action | Steps / time | | | |
| First Action → Repeat | What brings them back | | | |
| Free → Paid | Trigger / wall type | | | |

## Step 4: Design Handoff Package for Maks

Every handoff to Maks MUST include:

### 🎨 DESIGN HANDOFF
1. **Target Persona**: Who is the primary user? What do they care about visually? (e.g., "CFO at mid-size lender — needs to feel this is enterprise-grade, not a startup toy")
2. **Competitor UI Patterns**: Top 3 patterns to replicate or improve, with specific competitor URLs
3. **Trust Signals Required**: Exact trust mechanisms needed for THIS audience (not generic — specific to the vertical)
4. **Conversion-Critical Screens**: Which 2-3 screens determine if the user converts? (usually: landing page, empty state/first-run, core workflow)
5. **Design Direction**: "Build like [reference product] but with [Nick's edge]" — e.g., "Build like Stripe's dashboard clarity but with lending-specific terminology and compliance confidence"
6. **Mobile Considerations**: Is mobile critical for this audience? If yes, what patterns matter? (thumb zones, bottom nav, gesture support)
7. **What NOT to Build**: Explicitly list competitor features that look impressive but don't serve the MVP

## Quality Check
Before including in a report, verify:
- [ ] At least 3 competitors analyzed (not just 1)
- [ ] Specific URLs provided (not "Competitor X has good UX")
- [ ] Trust signals are audience-specific (not generic "add testimonials")
- [ ] Patterns include WHY they work, not just WHAT they are
- [ ] Antipatterns documented (what to avoid is as valuable as what to copy)
- [ ] Design direction references products Nick actually respects (Accenture, Atlassian, Adobe, NVIDIA aesthetic per USER.md)

## Changelog
- 2026-03-22: Created — fills gap between competitive-intelligence and action-triggers handoff
