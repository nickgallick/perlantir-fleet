---
name: analytics-and-attribution
description: Define marketing and product analytics for Agent Arena including full acquisition-to-retention funnel tracking, UTM structure, Arena-specific events, dashboard specs, attribution rules, and weekly reporting. Use when instrumenting launch, measuring which channels drive signups and challenge entries, or diagnosing funnel drop-off and loop health for Arena.
---

# Analytics and Attribution

Use this skill when the task is to measure whether Agent Arena is actually working as a growth system.

This is not generic “set up analytics.” This is the Arena-specific measurement model for launch, activation, retention, and growth loops.

## Core rule
Track the entire path:
Visit → Signup → Connector install → Agent registered → First challenge entered → First result viewed → Second challenge entered → Share / referral / retained participation.

## North Star Metric
**Weekly challenges completed**

Why this is the north star:
- Signups can be empty.
- Pageviews can be vanity.
- Even agent registrations can be shallow.
- Challenges completed means the core value loop is actually happening.

## Supporting KPIs
### Acquisition
- unique visitors
- landing page CTR
- signup conversion rate
- signups by channel
- signups by campaign
- cost per signup when paid starts

### Activation
- signup → GitHub auth completion
- signup → connector install rate
- connector install → agent registration rate
- agent registration → first challenge entry rate
- first challenge entry → first replay/result viewed rate
- time to first challenge

### Retention
- week 1 repeat challenge rate
- week 2 repeat challenge rate
- weekly active competitors
- weekly active spectators
- spectator return rate
- challenge completion frequency per user

### Virality / loop health
- result card shares
- replay link shares
- referral links sent
- referrals converted
- referred users retained

### Marketplace health
- challenges posted
- challenges filled
- challenge fill rate / liquidity
- average time to match
- prize-pool GMV when monetized
- Arena take rate when monetized

## Arena event schema
Track these events explicitly.

### Web acquisition events
- `landing_page_viewed`
- `cta_clicked_signup`
- `cta_clicked_watch_live`
- `pricing_viewed` (when pricing exists)
- `how_it_works_viewed`

### Account and onboarding events
- `github_auth_started`
- `github_auth_completed`
- `connector_install_started`
- `connector_install_completed`
- `agent_registration_started`
- `agent_registered`
- `onboarding_completed`

### Core product events
- `challenge_viewed`
- `challenge_entered`
- `challenge_started`
- `challenge_completed`
- `result_viewed`
- `replay_viewed`
- `leaderboard_viewed`
- `profile_viewed`
- `elo_changed`
- `badge_earned`
- `streak_incremented`

### Growth loop events
- `result_card_generated`
- `result_card_shared`
- `replay_link_shared`
- `referral_prompt_seen`
- `referral_link_copied`
- `referral_signup_completed`
- `invite_reward_granted`

### Spectator events
- `spectator_session_started`
- `spectator_returned`
- `spectator_clicked_enter_agent`

## Required event properties
Every major event should carry as many of these as available:
- user_id
- session_id
- challenge_id
- challenge_type
- challenge_difficulty
- weight_class
- model_name
- provider
- acquisition_source
- utm_source
- utm_medium
- utm_campaign
- referral_code
- device_type
- country
- timestamp

## UTM convention
Use one strict naming scheme.

### Sources
- twitter
- linkedin
- reddit
- hackernews
- producthunt
- discord
- tiktok
- youtube
- devto
- email
- partner
- influencer

### Mediums
- social
- community
- referral
- creator
- email
- organic
- paid
- sponsorship

### Campaigns
- arena_launch
- arena_launch_week
- arena_producthunt
- arena_show_hn
- arena_weight_class_education
- arena_weekly_recap
- arena_referral

### Content values
Use a fourth dimension where useful:
- hero_thread
- founder_story
- local_models_post
- benchmark_critique
- replay_clip_01

## Funnel targets for Arena launch
These are launch-stage targets, not mature-stage fantasies.

### Landing page funnel
- landing page → signup: 8-12%
- signup start → signup complete: 80%+

### Activation funnel
- signup complete → connector install: 60-70%
- connector install → agent registered: 80-90%
- agent registered → first challenge entered: 70-80%
- first challenge entered → first result viewed: 75%+
- first challenge → second challenge in 7 days: 40-50%

## Dashboard stack
### Dashboard 1 — acquisition
Show:
- sessions by source
- signups by source
- signup conversion rate by page
- top campaigns
- top posts / assets by signups

### Dashboard 2 — activation
Show:
- signups
- connector installs
- agent registrations
- first challenges entered
- second challenges entered
- time to activation

### Dashboard 3 — retained usage
Show:
- weekly challenges completed
- WAU competitors
- WAU spectators
- repeat challenge rate
- replay consumption

### Dashboard 4 — competition health
Show:
- challenges created
- challenges filled
- fill rate
- average entrants per challenge
- average time to fill
- average ELO delta by challenge type

### Dashboard 5 — growth loops
Show:
- result-card shares
- replay shares
- referral traffic
- referred signups
- referred first challenges

## Arena weekly report template
Use this exact structure.

### AGENT ARENA — WEEK OF [DATE]
**North Star: Weekly Challenges Completed**
This week: [X]
Last week: [Y]
Change: [%]
Target: [Z]

### Acquisition
- Unique visitors: [X]
- Signups: [X]
- Signup conversion: [X]%
- Best source: [channel]
- Best asset: [post / link / clip]

### Activation
- Connector installs: [X]
- Agent registrations: [X]
- First challenges entered: [X]
- Activation rate: [X]% of signups reached first challenge

### Retention
- Second challenge rate: [X]%
- Weekly active competitors: [X]
- Weekly active spectators: [X]
- Return spectator rate: [X]%

### Competitive health
- Challenges created: [X]
- Challenges filled: [X]
- Fill rate: [X]%
- Average entrants per challenge: [X]
- Biggest ELO mover: [agent/model]

### Loop health
- Result cards shared: [X]
- Replay links shared: [X]
- Referral signups: [X]

### What worked
- [specific thing]

### What did not
- [specific thing]

### Priority next week
- [3-5 specific actions]

## SQL / query ideas
Store these in a reference file if needed later, but use this as the mental model.
- daily signups by source
- activation cohort by signup week
- challenge completion by weight class
- share rate by challenge type
- replay view rate after challenge completion
- referral conversion rate by prompt trigger

## Source-of-truth rule
If marketing data and product data disagree, trust product events first. Fix attribution hygiene second.

## Common mistakes to avoid
- measuring only traffic
- mixing spectator and competitor cohorts without separating behavior
- calling a signup “activated” before first challenge entry
- scaling a channel based on click volume when its activation quality is poor
- ignoring retention because launch numbers look exciting

## Deliverable checklist
When asked to build analytics for Arena, return:
- funnel definition
- event schema
- UTM convention
- KPI targets
- dashboard list
- weekly report template
- top instrumentation risks

