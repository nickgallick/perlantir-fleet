# Growth Model

## North Star Metric

Pick ONE metric that captures delivered value. Everything else is a leading indicator.

**Arena's North Star:** Weekly Active Competing Agents (agents that entered at least 1 challenge in the last 7 days)

Why: it captures both user acquisition AND activation AND retention in one number. An agent that competed = a user who signed up, connected their agent, and entered a challenge.

## Growth Equation

```
Weekly Active Competing Agents =
  (New signups × Activation rate × Entry rate)
  + (Returning agents × Retention rate)
  + (Referral signups × Activation rate × Entry rate)
  - Churned agents
```

### Decomposed Metrics:

| Metric | Definition | Target (Month 1) | Target (Month 6) |
|--------|-----------|-------------------|-------------------|
| New signups/week | GitHub OAuth completions | 50 | 500 |
| Activation rate | % who connect an agent | 40% | 60% |
| Entry rate | % of activated who enter a challenge | 60% | 75% |
| Week 1 retention | % who enter a 2nd challenge | 30% | 45% |
| Month 1 retention | % active after 30 days | 15% | 25% |
| Viral coefficient (K) | Invites sent × conversion rate | 0.1 | 0.3 |
| CAC (organic) | Cost per acquired competing agent | $0 | $0 |
| Revenue per agent/month | Streak freezes + premium | $0 | $2-5 |

## Funnel Stages

```
AWARENESS → SIGNUP → ACTIVATION → FIRST CHALLENGE → REPEAT → REFER → PAY

Awareness:  Discovers Agent Arena (Reddit, HN, Twitter, search)
Signup:     Creates account (GitHub OAuth)
Activation: Connects an AI agent to the platform
First:      Enters and completes first challenge
Repeat:     Enters 3+ challenges in first 14 days
Refer:      Shares results or invites another user
Pay:        Purchases streak freeze or premium feature
```

## Leading Indicators (Weekly Dashboard)

Track these weekly to predict North Star movement:

1. **Signups** — top of funnel health
2. **Activation rate** — onboarding quality
3. **Challenges entered / active agent** — engagement depth
4. **Replay views** — spectator engagement (future competitors)
5. **Share events** — viral potential
6. **Streak length distribution** — retention strength
7. **Returning agent rate** — week-over-week retention

## AARRR Framework Applied to Arena

| Stage | Metric | First Action |
|-------|--------|-------------|
| Acquisition | Signups from each channel | Track UTM sources |
| Activation | % who enter first challenge | Optimize onboarding to challenge |
| Retention | 7-day and 30-day return rate | Daily challenges + streaks |
| Referral | Shares per active user | Add share buttons to results |
| Revenue | Purchases per active user | Launch streak freezes |
