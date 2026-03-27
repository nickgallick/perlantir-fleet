# Review Management & Solicitation

## Review Solicitation Timing

### When to Ask (High-Conversion Moments)
1. **After a win** — User's agent just placed top 3 in a challenge
2. **After a milestone** — Level up, new badge earned, streak milestone
3. **After 3+ sessions** — User has demonstrated retention
4. **After completing onboarding** — User has experienced core value

### When NOT to Ask
- During first session (haven't experienced value yet)
- After a loss or negative ELO change
- When the app just crashed or errored
- More than once per 30 days (iOS limits)
- During a complex flow (mid-challenge entry)

### iOS SKStoreReviewController Rules
- Apple limits prompts to 3 per year per user
- System decides whether to actually show the prompt
- Cannot customize the dialog — it's system-standard
- Must not incentivize reviews ("rate us for coins" = rejection)

### Google Play In-App Review API
- Similar constraints — Google controls display
- Cannot promise rewards for reviews
- Must not redirect to Play Store page for review

## Review Response Strategy

### Respond to All Negative Reviews (1-3 stars)
**Template:**
```
Hi [name], thanks for the feedback. [Acknowledge specific issue].
We're [working on fix / have fixed this in version X].
Would love to hear more — reach out at [support email].
```

**Rules:**
- Respond within 24 hours
- Never be defensive
- Acknowledge the issue specifically
- Offer a path to resolution
- Keep it short (3-4 sentences max)

### Respond to Constructive 4-Star Reviews
**Template:**
```
Thanks for the feedback! We're noting [feature request/suggestion]
for our roadmap. Glad you're enjoying [specific feature they mentioned].
```

### 5-Star Reviews
- Thank briefly or don't respond (avoid looking like you're farming engagement)
- Exception: if they mention a specific feature, acknowledge it

## Rating Improvement Tactics

1. **Fix the top 3 complaints** in negative reviews — then reply to those reviews saying you fixed it
2. **Time your prompts** to moments of delight, not routine
3. **Reset negative sentiment** with a major update — users often re-rate after fixes
4. **Segment prompt timing** — power users get prompted earlier, casual users later
5. **Monitor competitor reviews** — their complaints are your positioning opportunities

## Arena Review Strategy
- Prompt after: first top-3 finish, first badge earned, 7-day streak
- Never prompt after: lost challenge, negative ELO, error states
- Review response SLA: 24 hours for 1-3 stars, 48 hours for 4 stars
- Monthly review audit: categorize complaints, feed into product roadmap
