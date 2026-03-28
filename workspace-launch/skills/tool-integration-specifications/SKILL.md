---
name: tool-integration-specifications
description: Specify the tools and API integrations Launch needs to operate autonomously including priority, approval workflows, rate limits, and auto-publish rules for X, email, blog, Discord, LinkedIn, Reddit, and analytics. Use when requesting integrations from Maks or Nick, or when building the autonomous publishing infrastructure.
---

# Tool Integration Specifications

## Required integrations by priority

| Tool | Purpose | Priority |
|------|---------|----------|
| X/Twitter API | Post tweets, threads, monitor mentions | P0 — must have |
| Resend | Send emails (newsletter, onboarding, win-back) | P0 |
| CMS/Blog API | Publish blog posts directly | P0 |
| Buffer or Typefully | Schedule social posts | P1 |
| Plausible or PostHog | Analytics, attribution | P1 |
| Discord webhook | Post to Discord channels | P1 |
| LinkedIn API | Post updates (or via Buffer) | P2 |
| Reddit API | Post and comment (rate-limited, ban risk) | P2 |
| Google Ads API | Manage search campaigns | P3 |
| Stripe | Track revenue metrics | P3 |

## Auto-publish rules

| Content type | Approval required |
|---|---|
| Blog posts | Counsel review OR 24h timeout for non-enterprise content |
| Tweets (data-based) | Auto-publish |
| Tweets (opinion/commentary) | Queue for Nick review |
| Newsletter | Auto-send Thursday (established cadence) |
| Reddit/HN | Queue for review (ban risk if over-promotional) |
| LinkedIn | Auto-publish |
| Enterprise outreach emails | ALWAYS queue for Nick's review |
| Prize pool / legal copy | ALWAYS Counsel review |

## Requesting integrations from Nick
When requesting an API credential:
1. Name the tool
2. Explain specifically what it enables (one sentence)
3. Specify what data it accesses
4. Confirm it's in the auto-publish rules

Example request: "I need the Resend API key to send the weekly newsletter and onboarding sequence. It accesses the email list. Newsletter auto-sends Thursday; onboarding sequences are triggered by signups."

