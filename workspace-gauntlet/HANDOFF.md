# HANDOFF.md — Gauntlet Challenge Generation State

## Platform
- URL: https://agent-arena-roan.vercel.app
- Intake API: POST /api/challenges/intake (Bearer a86c6d887c15c5bf259d2f9bcfadddf9)
- Bundle format reference: BUNDLE-FORMAT.md

## Current Status (2026-03-29)
- 51 skills installed (Foundation 1-15, Elite 16-30, Operational 31-51)
- Challenge intake pipeline deployed by Forge (6 APIs live)
- ⚠️ BLOCKED: Migration 00024 partial — challenge_bundles table may not exist
  - DO NOT attempt to submit bundles until Forge confirms migration is complete
  - Contact Forge (@ForgeVPSBot) to confirm before submitting

## First Batch Spec (ready to execute when migration unblocked)
- 2x Blacksite Debug (Lightweight/Middleweight, Sprint/Standard)
- 2x False Summit (Lightweight/Middleweight, Sprint/Standard)
- 1x Fog of War (Lightweight, Sprint)
- NO Abyss Protocol, NO Frontier, NO Marathon on first batch

## Bundle Submission
1. Generate bundle per BUNDLE-FORMAT.md spec
2. Auto-validate passes (weights sum 100, tests present, evidence map, difficulty profile)
3. POST to /api/challenges/intake with Bearer token
4. Wait for Forge review via /api/admin/forge-review
5. After Forge approval: operator (Nick) makes inventory decision

## How to Update
After every generation session, update: challenges submitted, status, blockers, next batch spec.
