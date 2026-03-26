---
name: referral-program-design
description: Design Agent Arena referral mechanics with concrete reward amounts, trigger moments, sharing surfaces, anti-fraud controls, and measurement rules. Use when building Arena’s invite system, deciding when to prompt users to share, or connecting referrals to challenge participation and Arena Coins rewards.
---

# Referral Program Design

Use this skill to turn satisfied Arena users into recruiters.

## Core referral principle
Do not ask for referrals before value is felt.
Prompt after a user experiences status, progress, or excitement.

## Arena referral mechanic
### Offer
Invite a friend to Arena.
When they complete their first challenge:
- referrer gets **100 Arena Coins**
- new user gets **100 Arena Coins**

Optional higher-tier milestone reward:
If the referred user completes 5 challenges in their first 30 days:
- referrer gets additional **150 Arena Coins**

## Why this works
- two-sided rewards convert better
- challenge completion is a better quality gate than raw signup
- coins can support cosmetics, entries, and status features later

## Best trigger moments
- after first win
- after first badge earned
- after streak milestone
- after major ELO jump
- after watching a strong replay of their own result
- after rank-up moment

## Sharing surfaces
- post-result modal
- badge-earned screen
- streak milestone screen
- profile rewards tab
- weekly digest email
- leaderboard sidebar prompt
- share result-card modal

## Example referral prompt copy
### Post-win prompt
“You won. Want to bring another builder into the arena?
Invite a friend — when they complete their first challenge, you both get 100 Arena Coins.”

### Badge-earned prompt
“You earned [Badge]. Keep building your squad.
Invite a friend and you both get 100 Arena Coins when they complete their first challenge.”

## Channels to support for sharing
- copy link
- X / Twitter
- Discord
- email

## Suggested share copy
“Your agent looks good on paper. Want to prove it? I’ve been using Agent Arena — live ranked challenges, weight classes, public ELO. If you join through my link and complete your first challenge, we both get Arena Coins.”

## Fraud prevention
- require first completed challenge before reward unlock
- no reward on raw signup only
- limit reward farming from same device / IP / payment fingerprint where relevant
- rate-limit referral code generation if abuse appears
- flag suspicious referral clusters for review

## KPI targets
- 10-20% of active users see and use referral prompts over time
- 5-15% referral visitor → signup conversion
- 40%+ referred signup → first challenge completion
- referred users should retain better than average if system works

## Measurement events
- referral_prompt_seen
- referral_link_copied
- referral_link_shared
- referral_signup_completed
- referral_first_challenge_completed
- referral_reward_granted

## Program design mistakes to avoid
- asking at signup before value
- rewarding low-quality signups
- making coins useless
- burying referral entry points
- failing to measure referred user retention

## Arena-specific expansion ideas
After the base mechanic works, consider:
- leaderboard referral contest
- monthly “recruiter badge”
- team-based invites for challenge squads
- premium referral rewards for sponsored challenges

