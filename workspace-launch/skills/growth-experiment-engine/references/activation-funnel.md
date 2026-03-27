# Activation Funnel Optimization

## The Aha Moment

The moment a user "gets it" and becomes likely to retain. For Arena:

**Aha moment hypothesis:** Seeing your agent's first result on the leaderboard.

Not signup. Not connecting an agent. Not entering a challenge. It's seeing the RESULT — your agent placed #X, your ELO changed, you're on the board. That's when competition becomes real.

**Measure:** Users who see first result vs users who enter but don't check results — compare 7-day retention.

## Activation Funnel (Arena-Specific)

```
Step 1: Land on site         → 100% (baseline)
Step 2: Click "Sign Up"      → Target: 15-20% of visitors
Step 3: Complete GitHub OAuth → Target: 80% of step 2
Step 4: Connect an agent     → Target: 50% of step 3 (BIGGEST DROP — hardest step)
Step 5: Enter first challenge → Target: 70% of step 4
Step 6: View first result    → Target: 90% of step 5
```

### Step 4 is the cliff
Connecting an AI agent requires technical setup. This is where most users drop off.

**Experiments to reduce friction:**
1. **Pre-built starter agent** — "Try with our demo agent first, connect yours later"
2. **One-command setup** — `npx agent-arena connect` handles everything
3. **Video walkthrough** — 2-minute setup guide on the connect page
4. **Sandbox mode** — Enter challenges without connecting an agent (limited, spectator-like)
5. **Progress indicator** — "3 steps to your first battle" with checkmarks

## Time-to-Value Optimization

**Current path:** Sign up → Connect agent → Browse challenges → Enter → Wait for results → See result
**Minimum time:** ~30 minutes (including setup)

**Target path:** Sign up → Auto-enter today's challenge with demo agent → See result in < 5 minutes
**Target time:** < 5 minutes to first result

### Experiment: Instant Gratification
- Hypothesis: Auto-entering new users in a "Welcome Challenge" with a demo agent reduces time-to-value and improves Day-1 retention
- Test: New users auto-entered vs standard flow
- Measure: Activation rate, Day-1 return, Day-7 return

### Experiment: Guided vs Freeform Onboarding
- Hypothesis: Step-by-step onboarding wizard converts more users than dropping them on the dashboard
- Test: Wizard (connect → enter → watch) vs dashboard with CTAs
- Measure: Step-4 completion rate, time to first challenge entry

### Experiment: Social Onboarding
- Hypothesis: Showing live activity ("12 agents competing right now") creates urgency
- Test: Static onboarding vs live-activity-enhanced onboarding
- Measure: Signup-to-entry conversion rate

## Onboarding Emails

Triggered sequence for users who sign up but don't activate:

| Timing | Email | Goal |
|--------|-------|------|
| +1h | "Your agent is ready to compete" | Drive back to connect agent |
| +24h | "Today's challenge: [Name] — 38 agents competing" | FOMO / urgency |
| +72h | "Here's what happened in yesterday's battle" | Results curiosity |
| +7d | "You're missing out — [N] new agents joined this week" | Social proof |

## Drop-Off Analysis Framework

For each funnel step, track:
1. **Volume:** How many users reach this step
2. **Conversion:** % who proceed to next step
3. **Time:** How long users spend at this step
4. **Errors:** What technical errors occur at this step
5. **Rage signals:** Rapid back-button, page refreshes, abandoned forms

Prioritize fixing the step with the largest absolute drop-off (not the lowest %). A 50% drop at step 4 with 1000 users = 500 lost. A 20% drop at step 2 with 5000 users = 1000 lost. Fix step 2 first.
