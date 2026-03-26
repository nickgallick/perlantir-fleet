---
name: developer-patterns
description: Tracks patterns, blind spots, and habits of each developer agent. Calibrates reviews to catch their specific recurring mistakes faster.
---

# Developer Pattern Memory

## Purpose
After every review, log what was found. Over time, build a profile of each developer's strengths and weaknesses. Use this to front-load reviews — check their known blind spots FIRST, then do the full checklist.

## Maks Profile

### Recurring Issues (update after every review)
| Date | Project | Issue | Severity | Category | Times Seen |
|------|---------|-------|----------|----------|------------|
| 2026-03-21 | MathMind | No COPPA age-gate or parental consent flow for children's math app | P0 | COPPA/Compliance | 1 |
| 2026-03-21 | MathMind | Missing COPPA-compliant privacy policy page | P2 | COPPA/Privacy | 1 |
| 2026-03-21 | MathMind | Hardcoded API keys in client-side code | P2 | Code Quality | 1 |
| 2026-03-21 | MathMind | Missing input validation on user-facing forms | P2 | Code Quality | 1 |
| 2026-03-21 | MathMind | Inconsistent error handling patterns across components | P2 | Code Quality | 1 |
| 2026-03-21 | MathMind | Missing alt text on educational images | P2 | Accessibility | 1 |
| 2026-03-21 | MathMind | Touch targets below 44px minimum for children's app | P2 | Accessibility | 1 |
| 2026-03-21 | MathMind | Color-only indicators for correct/incorrect answers | P2 | Accessibility | 1 |
| 2026-03-21 | MathMind | Unhandled promise rejections in async quiz logic | P2 | Error Handling | 1 |
| 2026-03-21 | MathMind | Missing error boundary around quiz component tree | P2 | Error Handling | 1 |
| 2026-03-21 | MathMind | Unoptimized image assets causing slow load on mobile | P2 | Performance | 1 |
| 2026-03-21 | MathMind | Layout broken on small screens (< 375px) | P2 | Responsive | 1 |

### Blind Spot Summary (update when patterns emerge)
After 1 review:
- Top 3 most frequent mistake categories: Accessibility (3), Code Quality (3), Error Handling (2)
- Things Maks consistently gets right: Component architecture, TypeScript types, Tailwind usage
- Things Maks consistently misses: Accessibility details, compliance requirements (COPPA), error boundaries
- Improving areas: [TRACK — need more data]
- Degrading areas: [TRACK — need more data]

### Review Calibration
Based on pattern data, prioritize these checks FIRST when reviewing Maks's code:
1. Compliance/regulatory requirements (COPPA, GDPR, ADA) — especially for apps targeting specific demographics
2. Accessibility — alt text, touch targets, color-only indicators
3. Error handling — error boundaries, unhandled promises, Supabase .error checks
4. Input validation at trust boundaries
5. [FILL after more data]

### Other Developer Profiles
(Add sections here if other agents or humans submit code for review)

## How to Update This Skill
After EVERY review:
1. Open this file
2. Add a row to the Recurring Issues table for each issue found
3. Increment "Times Seen" if it's a repeat pattern
4. After every 5th review, re-evaluate the Blind Spot Summary and Review Calibration
5. If a previously recurring issue stops appearing for 3+ consecutive reviews, move it to "Improving areas"

## Pattern Metrics
- Total reviews completed: 1
- Total issues found: 12
- Average issues per review: 12
- Most common P0 category: COPPA/Compliance
- Most common P1 category: [UPDATE after more data]
- Reviews since last Maks blind spot repeat: 0

## Changelog
- 2026-03-21: Populated with MathMind review data (12 issues across 6 categories)
- 2026-03-20: Initial skill — pattern tracking begins
