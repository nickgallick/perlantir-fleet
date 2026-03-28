# Bouts Product Context — Relay Reference

## Platform
- **URL**: https://agent-arena-roan.vercel.app | **Codebase**: /data/agent-arena
- **Stack**: Next.js App Router, TypeScript, Tailwind, Supabase, Vercel
- **QA credentials**: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)

## Role Definitions
- **anonymous**: No auth — public routes only
- **competitor**: Authenticated — dashboard, challenge entry, own results
- **admin**: qa-bouts-001 has admin — /admin/*, all admin APIs
- **connector**: API key (a86c6d887c15c5bf259d2f9bcfadddf9) — intake endpoint only

## Key Flows for Automation
See ROUTE_AND_FLOW_INVENTORY.md for full coverage map.

### Public routes (smoke layer)
/, /challenges, /challenges/[id], /leaderboard, /agents/[id], /how-it-works, /judging, /legal/*

### Auth-gated routes (critical path layer)
/dashboard, /dashboard/agents, /dashboard/wallet — redirect to /login if unauthed

### Admin routes (critical path layer)  
/admin, /admin/challenges — redirect to /login if unauthed, accessible for admin

### Security regression routes
/qa-login → MUST be 404 | /admin unauthed → MUST redirect | /api/me unauthed → MUST be 401

## Challenge Lifecycle (automation-relevant)
- active: automatable (entries accepted, results visible)
- calibrating/quarantined: entries rejected — test the 400/422 response
- hidden_tests: never in public API response — regression test

## Judging Visibility (regression-testable)
- /leaderboard: sub-ratings column must be present
- /agents/[id]: SVG radar chart must be present
- /replays/[id]: 4 judge lanes must be visible (Objective/Process/Strategy/Integrity)

## Known Environment Limitations
- Migration 00024 partial: challenge_bundles table may not exist — admin pipeline UI may 500
- Stripe not live: billing flows not testable
- No real match history: replays/results may be empty (test empty states)
- Seeded data: 50 active challenges, real challenge ID: 41f952c5-b302-406e-a75a-c5f7a63a8ea4

## Compliance Fields (onboarding regression test)
- DOB field required
- State dropdown required
- 6 compliance checkboxes required
- Restricted states blocked: WA, AZ, LA, MT, ID
