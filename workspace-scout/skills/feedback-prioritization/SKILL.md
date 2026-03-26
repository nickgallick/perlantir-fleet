---
name: feedback-prioritization
description: Scout research skill — Feature Prioritization & Feedback Analysis using RICE, Kano, and structured synthesis. Use when evaluating which features to build, analyzing user feedback, or prioritizing product backlogs for Agent Arena, OUTBOUND, or any Perlantir product.
---

# Skill: Feedback Prioritization & Feature Scoring

Structured frameworks for turning user feedback into prioritized build decisions. Use when: (1) evaluating which features matter most for an MVP, (2) analyzing early user feedback for Agent Arena or OUTBOUND, (3) helping Nick decide what to build next vs. what to skip.

Source: agency-agents/product/product-feedback-synthesizer.md

## RICE Scoring Framework

Score every feature request or backlog item on 4 dimensions. Multiply to get a priority score.

### The Formula
```
RICE Score = (Reach × Impact × Confidence) / Effort
```

### Scoring Guide

**Reach** — How many users/customers does this affect per quarter?
- Score: actual number estimate (100 users, 1000 users, etc.)
- *Agent Arena example*: "Leaderboard filtering" → affects every user who visits the leaderboard → Reach = ~500/quarter (early stage)
- *UberKiwi example*: "Mobile-responsive redesign" → affects every site visitor → Reach = ~5000/quarter

**Impact** — How much does this move the needle per user?
- 3 = Massive (directly drives conversion/retention, users can't work without it)
- 2 = High (significant improvement to core workflow)
- 1 = Medium (noticeable improvement)
- 0.5 = Low (minor, nice-to-have)
- 0.25 = Minimal (barely noticeable)
- *Agent Arena*: "Real-time head-to-head comparison" → Impact = 3 (core value prop)
- *OUTBOUND*: "Pretty email templates" → Impact = 0.5 (users care about reply rates, not template aesthetics)

**Confidence** — How sure are you about Reach and Impact estimates?
- 100% = High (data-backed — user interviews, analytics, multiple feedback sources)
- 80% = Medium (some evidence — a few requests, reasonable assumption)
- 50% = Low (gut feel, one data point, speculative)
- *Always be honest here. A high-RICE feature with 50% confidence should be validated before building.*

**Effort** — Person-weeks to build (or use person-days for small items)
- Estimate realistically. Include design, build, test, deploy.
- For Perlantir with OpenClaw: divide typical industry estimates by 3-5x (our build speed advantage)

### RICE Score Example: Agent Arena Features
| Feature | Reach | Impact | Confidence | Effort | RICE Score |
|---------|-------|--------|------------|--------|------------|
| Real-time leaderboard | 500 | 3 | 80% | 2 weeks | 600 |
| Agent submission API | 200 | 3 | 100% | 1 week | 600 |
| Head-to-head comparison | 300 | 3 | 80% | 3 weeks | 240 |
| Social sharing badges | 500 | 0.5 | 50% | 1 week | 125 |
| Email notifications | 400 | 1 | 80% | 0.5 weeks | 640 |

*The score doesn't make the decision — it structures the conversation. If a low-RICE feature is strategically important (e.g., needed for a partnership), override with reasoning.*

## Kano Model

Categorize features by how users perceive them. Prevents building "more of the same" when what users need is a different category of feature.

### Feature Categories

**Must-Have (Basic Expectations)**
- Users don't notice when present, but are angry when absent
- Not building these = product feels broken
- *Agent Arena*: User accounts, basic search, reliable uptime
- *OUTBOUND*: Email deliverability, unsubscribe handling, basic analytics
- *UberKiwi*: Mobile responsive, fast load time, contact form

**Performance (More is Better — Linear Satisfaction)**
- Satisfaction scales linearly with quality/quantity
- These are where you compete on execution
- *Agent Arena*: Number of agent benchmarks, leaderboard accuracy, comparison depth
- *OUTBOUND*: Reply rate improvement, sequence personalization quality, signal detection accuracy

**Delighters (Unexpected — Exponential Satisfaction)**
- Users don't expect these and are thrilled when they discover them
- These create word-of-mouth and differentiation
- *Agent Arena*: AI-generated battle commentary, viral shareable results cards, "What would GPT-4 say about this?" feature
- *OUTBOUND*: Auto-generated personalized Loom scripts, "Here's why this prospect will reply" explainer
- *UberKiwi*: Auto-generated SEO content, real-time "your site just got a new visitor" notifications

**Indifferent (Nobody Cares)**
- Building these wastes time — no satisfaction impact either way
- *Common trap*: Admin settings nobody changes, reporting nobody reads, integrations nobody uses
- *Test*: Would users notice if you removed this? If not, skip it.

**Reverse (Actually Hurts)**
- Features that some users actively dislike
- *Common trap*: Mandatory onboarding tours, aggressive upsell modals, auto-playing videos

### Kano Application Rule
For every MVP, ensure:
- All Must-Haves are covered (non-negotiable)
- 2-3 Performance features that are your competitive edge
- 1 Delighter that creates word-of-mouth
- Zero Indifferent or Reverse features

## Feedback Synthesis Framework

When collecting and analyzing user feedback (post-launch):

### Source Hierarchy (Most Reliable → Least)
1. **User behavior data** (what they DO, not what they say) — analytics, session recordings, usage patterns
2. **Support tickets** (real problems, real frustration, unsolicited)
3. **Churn interviews** (why they LEFT — most honest feedback you'll get)
4. **In-app feedback** (contextual, in-the-moment)
5. **User interviews** (structured, but subject to courtesy bias)
6. **Feature request votes** (popularity ≠ importance — vocal minority problem)
7. **Social media mentions** (noisy, but reveals perception and word-of-mouth)
8. **App store / G2 reviews** (useful for competitors, less for your own product early on)

### Feedback Processing Steps
1. **Collect**: Pull from all active channels weekly
2. **Deduplicate**: Same person, same complaint = 1 data point, not 5
3. **Categorize**: Bug / UX friction / feature request / praise / confusion
4. **Quantify**: How many unique users reported this? What segment?
5. **Score**: Apply RICE to feature requests, severity to bugs
6. **Decide**: Top 3 items by RICE score → next sprint. Everything else → backlog or kill.

### The "5 Users" Rule
If 5+ independent users report the same problem unprompted → it's real, prioritize it.
If 1 user requests a feature passionately → it might be an edge case. Validate before building.
If 0 users mention something → they don't care, regardless of how clever you think it is.

## Feature Prioritization Decision Matrix

For quick prioritization without full RICE scoring:

| | High Impact | Low Impact |
|---|---|---|
| **Low Effort** | ✅ DO NOW | 🤷 Maybe (filler work) |
| **High Effort** | 📋 Plan carefully | ❌ SKIP |

### Kill Criteria for Feature Requests
Skip the feature if ANY of these are true:
- Only 1 user asked for it and it takes > 1 day to build
- It serves a persona you're not targeting in v1
- It requires maintaining a new integration/dependency
- Building it delays a Must-Have or core Performance feature
- "Competitor has it" is the only justification (they might be wrong too)

## Changelog
- 2026-03-22: Created from agency-agents/product/product-feedback-synthesizer.md — extracted RICE, Kano, and feedback synthesis; adapted with Agent Arena/OUTBOUND/UberKiwi examples
