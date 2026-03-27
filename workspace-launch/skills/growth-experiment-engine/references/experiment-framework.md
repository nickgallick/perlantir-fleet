# Growth Experiment Framework

## Experiment Design Template

Every experiment follows this format:

```
NAME: [Descriptive name]
HYPOTHESIS: If we [change], then [metric] will [improve/increase] by [amount] because [reasoning].
METRIC: [Primary metric to measure]
GUARDRAIL: [Metric that must NOT get worse]
AUDIENCE: [Who sees this — % of users, segment]
DURATION: [Minimum days to run]
SAMPLE SIZE: [Minimum users per variant for significance]
ICE SCORE: Impact [1-10] × Confidence [1-10] × Ease [1-10] = [total]
```

## Prioritization: ICE Scoring

| Score | Impact | Confidence | Ease |
|-------|--------|------------|------|
| 10 | 2x+ improvement to North Star | Proven at similar companies | < 1 day to implement |
| 7 | 50%+ improvement to funnel step | Strong signal from data/research | < 1 week |
| 5 | 20%+ improvement | Reasonable hypothesis | 1-2 weeks |
| 3 | 10%+ improvement | Educated guess | 2-4 weeks |
| 1 | Marginal improvement | Pure hunch | > 1 month |

Run experiments in ICE score order. If tied, prefer higher Impact.

## Statistical Significance

### Minimum Sample Size
For a meaningful result with 95% confidence:
- Detecting 10% change: ~3,000 per variant
- Detecting 20% change: ~800 per variant
- Detecting 50% change: ~150 per variant

At early-stage traffic (< 1000 users/week), you can only detect large effects. Design experiments for big swings, not 5% optimizations.

### Minimum Duration
- Always run for at least 7 days (capture weekday + weekend behavior)
- Ideally 14 days for retention experiments
- Never call a winner before reaching minimum sample size

### When to Stop Early
- If variant is significantly WORSE and guardrail metric is degrading → stop immediately
- If variant shows 99%+ confidence in positive direction → can stop early
- If no effect after 2x minimum duration → stop and move on

## Experiment Velocity

**Target: 3-5 experiments per month at launch**

| Week | Experiment | Funnel Stage |
|------|-----------|-------------|
| 1-2 | Onboarding wizard vs freeform | Activation |
| 2-3 | Share prompt after win vs every result | Referral |
| 3-4 | Demo agent auto-entry for new users | Activation |
| 4-5 | Daily challenge email nudge | Retention |
| 5-6 | Result card A vs B design | Referral |

## Experiment Log

Maintain a running log of all experiments:

```
| # | Name | Start | End | Result | Impact | Learnings |
|---|------|-------|-----|--------|--------|-----------|
| 1 | Onboarding wizard | 2026-04-01 | 2026-04-14 | +22% activation | Shipped | Users need guidance |
| 2 | Win share prompt | 2026-04-08 | 2026-04-22 | +15% shares | Shipped | Only prompt on wins |
| 3 | Demo agent | 2026-04-15 | 2026-04-29 | Inconclusive | Dropped | Sample too small |
```

## Common Growth Experiment Categories

### Acquisition Experiments
- Landing page headline A/B test
- CTA button text/color/placement
- Social proof elements (counter, testimonials)
- Pricing page layout and anchor pricing

### Activation Experiments
- Onboarding flow length (3 steps vs 5 steps vs wizard)
- Default settings (auto-enroll vs opt-in)
- First-run experience (tutorial vs sandbox vs guided challenge)
- Progress indicators and checklists

### Retention Experiments
- Email/push notification timing and content
- Streak mechanics (reward size, freeze availability)
- Daily challenge variety and difficulty
- Social features (rivalries, teams, following)

### Referral Experiments
- Referral incentive size (100 coins vs 200 vs 500)
- Share trigger timing (after win, after milestone, after streak)
- Shareable asset format (image card, link, video clip)
- Referral tracking visibility (show referral count or not)

### Revenue Experiments
- Streak freeze pricing ($4.99 vs $3.99 vs $2.99)
- Bundle discounts (3-pack vs 10-pack)
- Premium feature gating (which features drive upgrade)
- Free trial of premium features
