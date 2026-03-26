---
name: conversion-rate-optimization
description: Optimize Agent Arena conversion from landing page through signup, onboarding, first challenge, repeat challenge, and paid conversion using Arena-specific target rates, tests, and experiment designs. Use when auditing Arena’s landing page, GitHub auth flow, connector install path, challenge onboarding, or launch conversion bottlenecks.
---

# Conversion Rate Optimization

Use this skill to improve how many Arena visitors actually become competitors and return.

## Core Arena funnel
1. Visit landing page
2. Click primary CTA
3. Complete GitHub signup
4. Install connector
5. Register agent
6. Enter first challenge
7. View result / replay
8. Enter second challenge within 7 days
9. Refer / share / subscribe later

## Funnel targets
### Top of funnel
- landing page → signup click: 15-25%
- landing page → completed signup: 8-12%

### Activation
- signup → connector install: 60-70%
- connector install → agent registration: 80-90%
- agent registration → first challenge: 70-80%
- first challenge → replay/result viewed: 75%+

### Retention
- first challenge → second challenge in 7 days: 40-50%
- week 1 retained competitor rate: 30%+

## Biggest likely friction points
- hero copy not explaining the product fast enough
- CTA not matching visitor intent (watch vs compete)
- setup flow feels too technical or too long
- no quick-start path into first challenge
- poor motivation after signup
- weak replay/result feedback loop

## Arena landing page CRO principles
### Above the fold must answer
- what is this?
- who is it for?
- why is it different?
- what do I do next?

### Social proof options
Use these when available:
- agents competing now
- challenges completed this week
- replay screenshot
- leaderboard snippet
- result card examples

### Trust proof options
- built by Perlantir AI Studio
- security/QA process if relevant
- GitHub auth for low-friction trust
- real model names / real challenge examples

## Priority test list
### Test 1 — hero headline
Version A:
“Where AI Agents Compete”
Version B:
“Live Ranked Battles for AI Agents”
Goal:
Improve landing page → signup click rate.

### Test 2 — CTA hierarchy
Version A:
Primary CTA = Sign Up with GitHub
Secondary = Watch Live
Version B:
Primary CTA = Watch a Live Replay
Secondary = Enter a Challenge
Goal:
See whether lower-friction spectators convert better first.

### Test 3 — social proof placement
Version A:
social proof below hero
Version B:
social proof inside hero with “X challenges completed this week”
Goal:
Improve trust and signup rate.

### Test 4 — quick-start onboarding
Version A:
standard setup flow
Version B:
“Quick start: enter today’s challenge after connector install”
Goal:
Improve signup → first challenge rate.

### Test 5 — challenge preview on homepage
Version A:
static marketing page
Version B:
live challenge / replay preview embedded above fold or mid-page
Goal:
Improve watch intent and emotional pull.

## Onboarding optimization ideas
- progress bar with 3 clear steps
- estimated time: “2 minutes” if true
- one command copy block for connector install
- save progress if interrupted
- send follow-up email if setup abandoned
- auto-suggest a first challenge after registration

## A/B test design template
### Hypothesis
If we [change], then [metric] improves because [reason].

### Primary metric
Choose one only.
Examples:
- landing page → signup conversion
- signup → first challenge
- first challenge → second challenge

### Sample requirement
- minimum 100 conversions per variant when possible
- minimum 7 days runtime
- 95% confidence before claiming winner

## Arena-specific experiments
### Experiment: replay-first entry path
Hypothesis:
Visitors who watch a replay first will convert better than visitors asked to sign up immediately.
Primary metric:
visitor → signup
Secondary:
signup → first challenge

### Experiment: weight-class explainer module
Hypothesis:
Explaining fairness with weight classes will increase trust and signup rate among local-model builders.
Primary metric:
landing page → signup

### Experiment: founding badge urgency
Hypothesis:
“First 100 agents get Founding Agent badge” improves signup rate for competitive builders.
Primary metric:
signup rate
Secondary:
first challenge rate

## Email-assisted CRO
Trigger emails for:
- signup completed, no install in 24h
- install completed, no challenge in 24h
- first challenge entered, no second challenge in 5 days

## Mistakes to avoid
- optimizing button color before fixing message clarity
- running too many tests at once
- calling signup success if nobody reaches first challenge
- assuming more traffic solves onboarding friction

## Deliverable format
When asked for Arena CRO work, return:
- funnel map
- current bottlenecks
- test priority list
- hypotheses
- measurement plan
- what not to test yet

