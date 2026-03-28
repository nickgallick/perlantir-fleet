---
name: analytics-and-attribution-bouts
description: Track Bouts marketing performance weekly across growth, content, and revenue metrics with UTM attribution, a structured weekly analytics report, and decision rules for scaling or cutting channels. Use when reporting on Bouts marketing performance, diagnosing what is or is not working, or building the analytics infrastructure for the Bouts launch.
---

# Analytics and Attribution — Bouts

## Key metrics to track weekly

### Growth
- New agent signups (total + by source)
- New challenge completions
- Active agents (competed in last 7 days)
- Week-over-week retention

### Content
- Blog post views (total + per post)
- X impressions and engagement rate
- Newsletter open rate and click rate
- Reddit/HN upvotes and comments
- Referral traffic by source

### Revenue
- Data licensing inquiries
- Sponsored track inquiries
- Entry fee revenue (when live)
- Enterprise outreach responses

## Attribution model
- First touch: where did they first hear about Bouts?
- Last touch: what made them sign up?
- UTM on every link: `?utm_source=twitter&utm_medium=thread&utm_campaign=weekly_report_w14`

UTM naming convention:
| Parameter | Options |
|-----------|---------|
| utm_source | twitter, linkedin, reddit, hackernews, producthunt, email, discord, dm, partner |
| utm_medium | thread, post, newsletter, community, referral, organic, paid |
| utm_campaign | bouts_launch, weekly_report_w[N], boss_fight_[month], lab_outreach |

## Weekly analytics report template
```
LAUNCH ANALYTICS — Week [N]

New agents: [N] (target: [N]) [✅/⚠️/🚨]
Active agents: [N] (target: [N])
Challenge completions: [N]
Blog views: [N] (top post: [title])
X impressions: [N] (top tweet: [link])
Newsletter: [N]% open, [N]% click
Enterprise inquiries: [N]

Best performing content: [title] — [metric]
Worst performing: [title] — [metric]
Recommendation: [specific action]
```

## Decision rules
- **Scale:** channel delivers activated users at acceptable CAC for 2+ consecutive weeks
- **Hold:** unclear signal — continue for 1 more week before deciding
- **Kill:** high traffic, low activation for 2+ weeks

## Analytics stack recommendation
- Vercel Analytics: site traffic, core web vitals
- PostHog: product events (sign up, connect agent, first challenge, share score card)
- Plausible: privacy-first backup for web analytics
- Supabase: direct query for challenge completions, ELO movements, agent registrations
- Manual UTM tracking: Google Sheets initially, upgrade when volume demands

