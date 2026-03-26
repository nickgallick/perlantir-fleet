---
name: demand-validation-scoring
description: Scout research skill — Demand Validation Scoring
---

# Skill: Demand Validation Scoring

Score every piece of evidence on a standardized rubric. No vibes. Numbers only.

## Signal Strength Scoring

Each evidence source gets points:

### Reddit / Hacker News Posts
- <10 upvotes, >1 year old = 1 point
- 10-50 upvotes, <1 year old = 2 points
- 50-200 upvotes, <6 months old = 3 points
- 200-500 upvotes, <3 months old = 5 points
- 500+ upvotes, <3 months old = 7 points

### G2 / Capterra / App Store Reviews
- Single review mentioning the pain point = 1 point
- 3-5 reviews with the same complaint = 3 points
- 10+ reviews with the same complaint = 5 points
- Consistent pattern across multiple competing products = 7 points

### Twitter/X
- Tweet with <10 likes about the pain = 1 point
- Tweet with 10-50 likes = 2 points
- Thread with 50+ likes discussing the problem = 4 points
- Multiple independent people tweeting the same pain = 5 points

### Product Hunt
- Comment on a launch saying "wish it did X" = 2 points
- Multiple comments on different launches requesting the same thing = 4 points
- A failed PH launch in the space (demand existed but execution was bad) = 3 points

### IndieHackers / Founder Signals
- Revenue report showing traction in related space = 3 points
- Founder publicly saying "I'm looking for X" = 2 points
- Multiple founders building in adjacent space = 3 points

### Professional / Institutional Signals
- YC RFS matching the problem area = 5 points
- Recent VC funding in adjacent space = 3 points
- Job posting for a role that exists because tooling doesn't = 3 points
- Industry report citing the market gap = 4 points
- Government data showing demographic/economic shift creating the need = 4 points

### Existing Spend Signals (from revenue-validation.md)
- People paying for a bad competitor = 5 points
- Freelancers/agencies being hired to solve this manually = 4 points
- Companies hiring full-time roles to do what software could = 5 points

## Multipliers
- Multiple INDEPENDENT sources describing the same pain = total × 1.5
- Pain point shows up across different platforms (Reddit AND Twitter AND G2) = total × 1.5
- Problem is getting WORSE over time (increasing complaints, growing market) = total × 1.25

## Demand Score Thresholds
- Score < 8: WEAK — not enough evidence. Find something else.
- Score 8-12: MODERATE — report it but flag as "unproven demand, proceed with caution"
- Score 13-20: STRONG — multiple signals, real pain, people actively looking
- Score 21+: VERY STRONG — obvious gap, pent-up demand, convergent signals

## MINIMUM SCORE TO INCLUDE IN REPORT: 10
Below 10, the idea does not get sent regardless of how clever it seems.
