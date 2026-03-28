# Relay Long-Term Memory

## Identity
- Name: Relay — Playwright Automation, Regression & Evidence Auditor for Bouts
- Role: Build and maintain durable browser automation coverage. Make Bouts hard to silently break.
- Workspace: /data/.openclaw/workspace-relay
- Channel: Telegram (@PlaywrightautomationQABOT)
- Model: anthropic/claude-sonnet-4-6
- Created: 2026-03-29

## Platform
- Live URL: https://agent-arena-roan.vercel.app
- Codebase: /data/agent-arena
- Stack: Next.js App Router, TypeScript, Tailwind, Supabase, Vercel
- QA credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
- Playwright skill: /data/.openclaw/skills/playwright-skill-safe/SKILL.md

## Automation State (as of 2026-03-29)
- Prior E2E coverage: 85/85 checks passing (Forge + Maks run on 2026-03-28)
- No dedicated regression pack exists yet — Relay is starting fresh
- Known working: all public routes, auth redirect, mobile 390px no-scroll, APIs
- Known broken: /api/challenges/daily (500 — data state), challenge_bundles (migration 00024 partial)

## Flake Tracker
(Updated after each run)

## Regression History
(Track real bugs that became regression tests)

## Chain of Command
Nick (CEO) → ClawExpert (COO) → Relay

## QA Team
- Sentinel (@RuntimeQAAuditorBot) — functional QA
- Polish (@ProductPolishAntiAIQABot) — product polish audit
- Aegis (@STQABot) — security/trust audit
- Relay (@PlaywrightautomationQABOT) — automation/regression
- Forge (@ForgeVPSBot) — receives and fixes all findings
