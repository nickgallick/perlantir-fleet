# Polish Long-Term Memory

## Identity
- Name: Polish — Product Polish, Enterprise Readiness, and Anti-AI-Built Auditor for Bouts
- Role: Audit whether Bouts feels like a premium, human-led product or a generic AI-built site
- Workspace: /data/.openclaw/workspace-polish
- Channel: Telegram (@ProductPolishAntiAIQABot)
- Model: anthropic/claude-sonnet-4-6
- Created: 2026-03-29

## Platform
- Live URL: https://agent-arena-roan.vercel.app
- Brand: Bouts (Perlantir AI Studio LLC) — dark theme, competitive evaluation platform
- QA credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
- Design intent: premium, enterprise-grade, operator-serious

## Audit History

### 2026-03-30 — Full Platform Polish Audit
- Verdict: **LAUNCH-SAFE BUT NOT FINISHED** — Grade B− / 7.1 overall
- Report: AUDIT-2026-03-30-FULL-PLATFORM.md
- P0s found: 3 (auth routes 404, "Arena Challenges" H1, /docs/web-submission 404)
- P1s found: 8 (raw DB values, leaderboard opacity, dead profile/submissions routes, dev URL in docs, broken onboarding CTA, gamey dashboard copy, sign-in CTA routing)
- P2s found: 10
- P3s found: 7
- Routed to Forge for P0/P1 fixes

### 2026-03-30 — Verification Pass (Post-Forge Fixes)
- 8 fixes confirmed ✅, 15 issues still open ❌
- All 3 P0s still open (auth routes, Arena Challenges H1, /docs/web-submission)
- New issue: TypeError: Cannot read properties of null (reading 'charAt') — JS runtime error in challenge detail
- Challenge detail now shows "Something went wrong" error page

## Key Product Context
- 4-lane judging: Objective (50%) / Process (20%) / Strategy (20%) / Integrity (10%)
- Challenge families: Blacksite Debug, Fog of War, False Summit, Recovery Spiral, Toolchain Betrayal, Abyss Protocol
- Bouts is NOT a chatbot, NOT a workflow builder — it's a serious competitive evaluation platform
- Legal entity: Perlantir AI Studio LLC, Iowa Code § 99B

## Known Brand/Copy Issues (as of 2026-03-29)
- Landing page stats hardcoded (src/app/page.tsx lines 50-59)
- Footer shows "© 2026 BOUTS ELITE" — brand should be just "Bouts"
- Iowa address placeholder in /legal/contest-rules
- Support email references @agent-arena-roan.vercel.app (not final domain)

## Chain of Command
Nick (CEO) → ClawExpert (COO) → Polish
