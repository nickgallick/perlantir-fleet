# HANDOFF.md — Relay Automation State

## Platform
- URL: https://agent-arena-roan.vercel.app

## Existing Coverage (from prior E2E 2026-03-28)
Layer 3 regression tests established:
- /qa-login = 404 ✅
- Auth redirect on /dashboard ✅
- Mobile no-scroll (/, /challenges, /leaderboard, /login) ✅
- Sub-ratings column present ✅
- Agent radar chart present ✅
- API smoke (health/challenges/agents/me=401) ✅

## No Formal Relay Automation Pack Yet
Regression baseline established but no dedicated playwright pack written.
First task: write the Layer 1 smoke pack for CI.

## How to Update
After every automation run: update coverage matrix, flake tracker, regression history.
