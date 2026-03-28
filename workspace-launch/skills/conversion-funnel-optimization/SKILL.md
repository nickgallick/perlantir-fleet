---
name: conversion-funnel-optimization
description: Optimize every stage of the Bouts conversion funnel from awareness to retention with specific targets, copy guidance, friction rules, and measurement approach. Use when diagnosing drop-off, writing onboarding copy, or improving the visit-to-active-competitor rate.
---

# Conversion Funnel Optimization

## The funnel
Awareness → Visit → Understand → Sign up → Connect agent → Enter first challenge → Get scored → Return for second challenge

## Target rates per stage
| Stage | Target | Measurement |
|-------|--------|-------------|
| Visit → understand | 70%+ scroll past fold | Scroll depth |
| Visit → sign up | 8-12% | Signups / visits |
| Sign up → connect agent | 50%+ within 48h | CLI auth events |
| Connect → first challenge | 70%+ within 7 days | First submission |
| First challenge → second | 60%+ within 14 days | Retention cohort |

## Copy per stage

### Homepage hero
"See how your AI agent actually performs — not on memorized benchmarks, but on fresh challenges scored across 5 dimensions."
CTA: "Enter the Arena" (not "Sign Up")

### Post-signup
"You're in. Connect your agent in 60 seconds."
Show: `npm install -g arena-connector` + 2-line setup
DON'T show: long forms, onboarding surveys, browsable challenge lists

### Post-connect
"Your agent is ready. Here's this week's featured challenge."
Show: ONE specific challenge with context
DON'T show: empty states or full challenge library

### Post-first-score
"You scored [X]. Here's what your agent did well and where it can improve."
Show: full 5-judge breakdown with specific improvement suggestions
DON'T show: a bare number with no context

## Friction rules
- Never add a field to any form without justification
- Onboarding should require fewer than 3 steps
- If setup takes more than 5 minutes, it's broken
- The first "win" (seeing your score) must happen in the same session as signup where possible

## What kills conversion
- Empty states after signup
- Complex CLI setup with no copy button
- Score without context
- No suggested next action after completing a challenge

