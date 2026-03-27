---
name: action-triggers
description: Scout research skill — Action Triggers
---

# Skill: Action Triggers

Turn Scout reports into real projects when Nick says go.

## On "go" or "build it" reply:

Generate and send these four deliverables:

### 1. OpenClaw Build Prompt
Full build prompt in the standard Perlantir format:
- Project overview (what it does, who it's for)
- Tech stack (Next.js + Tailwind + Supabase + Vercel)
- Supabase schema (all tables with SQL)
- Page-by-page feature list
- API integrations needed
- Auth setup
- Stripe/payment setup (if applicable)
- Deployment config (vercel.json)
- Seed data for demo
- Verification checklist

### 2. Landing Page Copy
- Headline (clear, benefit-driven, under 10 words)
- Subheadline (one sentence expanding the value prop)
- 3 key benefits with short descriptions
- Social proof angle (what to say before you have real users — "Join 50+ founders on the waitlist")
- CTA button text
- Waitlist email capture setup

### 3. Validation Post Drafts
Three versions:
- Reddit version: formatted for relevant subreddit, conversational tone, "I'm building X, would you use it?" framing
- Hacker News version: Show HN format, technical angle, clear problem statement
- Twitter/X version: thread format, hook + problem + solution + CTA, under 280 chars per tweet

### 4. Day-1 Launch Checklist
- [ ] Ship landing page with waitlist (OpenClaw can build this in hours)
- [ ] Post validation post to [specific subreddit]
- [ ] Post to Hacker News
- [ ] Tweet thread from [relevant account]
- [ ] Share in [specific Slack/Discord communities]
- [ ] Set up basic analytics (Vercel Analytics or Plausible)
- [ ] Set up Stripe for when first customers want to pay
- [ ] Start building MVP while waitlist grows

## On "dig deeper" reply:

- Find 5-10 additional evidence sources for the demand signal
- Deep competitor teardown: sign up for free trials if possible, document their UX flow, identify specific feature gaps and weaknesses
- Draft a detailed PRD with user stories (As a [persona], I want to [action], so that [outcome])
- Research competitor founder stories: how did they start, what was their first distribution channel, what's their background
- Produce a "competitive moat" analysis: what would make Perlantir's version defensible over time

## On "dead" or "pass" reply:

- Log to scout_ideas table with status = 'killed' and Nick's reason
- Add the rejection pattern to a "patterns to avoid" list
- If Nick has killed 3+ ideas with similar reasons, proactively adjust research criteria to avoid that pattern
- Acknowledge and move on: "Logged. Tomorrow's report will avoid [pattern]."
