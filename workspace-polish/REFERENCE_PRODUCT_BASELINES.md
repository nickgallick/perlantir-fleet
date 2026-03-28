# REFERENCE_PRODUCT_BASELINES.md — Polish Benchmark Reference

This file anchors "top-tier" to a real bar. Use it to calibrate every score.
Do not benchmark against average startups. Benchmark against these categories.

---

## Category 1 — Premium Technical Infrastructure Products
**Examples**: Vercel, Cloudflare, Fly.io, Railway

**Why relevant**: Bouts is infrastructure for AI evaluation. It should feel as credible as the tools serious developers already trust.

**What they do right:**
- Technical precision is a trust signal. Numbers are exact, not rounded.
- Status pages are specific and real-time. Not "we're looking into it."
- Error messages are diagnostic, not apologetic.
- Docs are written for the developer's workflow, not for coverage.
- Pricing is transparent. No hidden costs, no vague tiers.
- Empty states are informative: "No deployments yet — create your first project to deploy."

**The bar for Bouts:**
- Challenge and match data should be as precise as Vercel's deployment logs
- Status page should feel as operational as Cloudflare's incident dashboard
- Connector docs should feel as testable as Fly.io's quickstart

---

## Category 2 — Operator-Grade SaaS Products
**Examples**: Linear, Notion, Airtable, Retool

**Why relevant**: Bouts has an operator/admin layer. It needs to feel like a serious work tool, not a startup dashboard.

**What they do right:**
- Information density is earned. Dense pages are structured, not cluttered.
- Tables are interactive: sortable, filterable, keyboard-navigable.
- Keyboard shortcuts exist for power users.
- Workflows are completable without consulting documentation.
- Status transitions are visible and logged.
- Empty states are designed: they explain the state AND show what to do next.

**The bar for Bouts:**
- Admin challenge pipeline view should feel as usable as a Linear issue list
- Forge review queue should feel as structured as a Retool table
- Status chips should use the same precise vocabulary as Linear labels

---

## Category 3 — Enterprise Trust Surfaces
**Examples**: Stripe, DocuSign, Brex, Mercury

**Why relevant**: Bouts handles legal compliance, prize money, and competitive stakes. It needs the trust level of products that deal with serious money and legal obligation.

**What they do right:**
- Legal language is human-readable. It doesn't feel like a liability shield.
- Every decision point has trust signals nearby (not just in the footer).
- Pricing is precise and disclosed upfront.
- Refund and dispute policies are easy to find.
- Error states in critical flows are calm and specific — not panicky or vague.
- Security signals are present without being intrusive.

**The bar for Bouts:**
- Legal pages should feel as real as Stripe's terms — not like a template copy-paste
- Prize pool and entry fee displays should be as clear as Mercury's transaction view
- Onboarding compliance should feel as considered as a financial account opening flow

---

## Category 4 — Docs-Heavy Technical Products
**Examples**: Stripe Docs, Anthropic API Docs, Supabase Docs, Tailwind CSS Docs

**Why relevant**: The connector docs and API reference are critical trust surfaces for developers.

**What they do right:**
- Every code example is tested and works.
- Docs are organized by what you're trying to do, not by technical structure.
- Search is fast and actually finds what you need.
- There is a clear "getting started" path for a new user.
- Advanced content is available but doesn't pollute the entry path.
- API references have request/response examples in the main flow, not appended at the bottom.

**The bar for Bouts:**
- /docs/connector should feel as usable as the Supabase quickstart
- /docs/api should feel as precise as the Anthropic API reference
- No section should have "Coming soon" where real content should be

---

## Category 5 — High-Trust Auth and Billing Experiences
**Examples**: Stripe Checkout, GitHub OAuth, Apple App Store purchase flow, Coinbase onboarding

**Why relevant**: Bouts onboarding has legal compliance requirements. The auth and compliance flow must feel as trustworthy as financial-grade onboarding.

**What they do right:**
- Each step is explained: why you're being asked for this information.
- Restrictions are communicated respectfully: not "error" but "This service is not available in your state."
- Progress is clear: users know where they are in the flow.
- Legal checkboxes have real text that users can actually read.
- Completion state is unambiguous: "You're in. Here's what happens next."

**The bar for Bouts:**
- Onboarding state restriction block should feel as respectful as Coinbase's compliance messaging
- Age verification should feel as considered as any financial account opening
- Compliance checkboxes should have readable, real text — not legal boilerplate filler

---

## Category 6 — Competitive / Leaderboard Products
**Examples**: Lichess.org, Kaggle, HackerRank, Codeforces

**Why relevant**: Bouts is a competition platform. Leaderboard, rankings, and results surfaces should feel credible to competitive communities.

**What they do right:**
- Leaderboard data is precise: ELO ratings, exact win/loss counts, match history.
- Rating changes are visible and explainable.
- Competition results have enough detail to understand what happened.
- Historical data is accessible and trustworthy.
- Statistical breakdowns are readable and actionable.

**The bar for Bouts:**
- Leaderboard should feel as credible as Lichess's rating system display
- Post-match breakdown should feel as informative as Kaggle's competition submission detail
- Sub-ratings (Process/Strategy/Integrity) should feel as structured as Kaggle's leaderboard filters

---

## Using These Baselines in Practice

When scoring Visual Maturity, ask:
> "Does this feel closer to Vercel's design discipline or to an average startup template?"

When scoring Copy Maturity, ask:
> "Does this copy feel as specific and trusted as Stripe's public messaging or as generic as 100 other SaaS sites?"

When scoring Enterprise Readiness, ask:
> "Would a technical operator from Linear or Retool find this admin surface adequate?"

When scoring Trust Signal Quality, ask:
> "Would this legal and compliance experience feel trustworthy to someone who has used Mercury or Brex?"

When scoring Docs quality, ask:
> "Does this connector guide feel as usable as the Supabase quickstart on a first-time read?"

**Anchor every score to a specific category and product. Don't float.**
