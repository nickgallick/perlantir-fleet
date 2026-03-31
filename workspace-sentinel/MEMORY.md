# Sentinel Long-Term Memory

## Identity
- Name: Sentinel — Runtime QA Auditor for Bouts
- Role: Verify Bouts works as a launch-ready evaluation platform. Test from the outside in. Document truth.
- Workspace: /data/.openclaw/workspace-sentinel
- Channel: Telegram (@RuntimeQAAuditorBot)
- Model: anthropic/claude-sonnet-4-6
- Created: 2026-03-29

## Platform
- Live URL: https://agent-arena-roan.vercel.app
- Codebase: /data/agent-arena
- Stack: Next.js App Router, TypeScript, Tailwind, Supabase, Vercel
- QA credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin role)
- GAUNTLET_INTAKE_API_KEY: a86c6d887c15c5bf259d2f9bcfadddf9

## Current Known Issues (as of 2026-03-31)
- ⚠️ Migration 00024 partial — challenge_bundles table may not exist in DB. All intake/forge-review/inventory routes may 500.
- /api/challenges/daily returns 500 (no challenge with is_daily=true in DB — data state, non-blocking)
- Landing stats hardcoded in src/app/page.tsx lines 50-59
- Stripe live keys not yet added — billing not live
- Iowa address placeholder in /legal/contest-rules
- bouts.gg domain not connected (still on agent-arena-roan.vercel.app)
- ORACLE_WALLET_ADDRESS + BASE_RPC_URL not set (chain calls not active)

## Resolved Issues (2026-03-31 — Forge remediation, 14 findings A1–D3)

### Section A — Runtime/Pipeline
- **A1 FIXED**: UNIQUE constraint added on submission_feedback_reports.submission_id (migration 00045). Duplicates cleaned. Upsert now works correctly.
- **A2 FIXED**: Fire-and-forget pipeline replaced with synchronous await on both GET feedback endpoints. No more Vercel context kills.
- **A3 FIXED**: 30s polling loop replaced with single AbortController fetch. All terminal states (timeout/failure/not_available) transition correctly. No spinner dead-ends.
- **A4 FIXED**: Default tab is now classic. Score data visible immediately on page load. Premium tab auto-switches only when report is ready.

### Section B — Trust/Security
- **B1 FIXED**: Fabricated numeric comparisons eliminated. signal-extractor.ts queries real composite scores from DB. MIN_ENTRIES_FOR_COMPARISON = 5 enforced. LLM writes narrative only — no invented numbers.
- **B2 FIXED**: Infra fields (model_id, latency_ms, is_fallback) confirmed not leaking in public replay API. Page type + normalize function + PostMatchBreakdown treat as optional.
- **B3 FIXED**: short_rationale scoped to owner/admin only. API already correct; page type updated to optional.

### Section C — (covered in commit 7d978e0)

### Section D — Data Integrity/Display
- **D1 FIXED**: decisive_moment prompt now requires citation of specific flag, telemetry metric, score differential, or concrete behavior. Coaching prompt has specificity test gate.
- **D2 FIXED**: evidence_density hidden from users. Lane percentile now human-readable with tooltip (was raw "p78").
- **D3 FIXED**: MIN_ENTRIES = 5 enforced in signal extractor. Comparison block suppressed when < 5 entries.

### Pipeline Config (final — Nick verified 3/3)
- Model: Haiku 4.5 (Sonnet 4.6 rejected: 45–95s, too slow)
- max_tokens: 3500 (root cause was 2000 — truncated mid-JSON → silent fallback every run)
- Fetch timeout: 100s
- Route maxDuration: 120 on both feedback endpoints
- Stress test: Run 1 53.9s ✅ | Run 2 49.0s ✅ | Run 3 45.0s ✅ | confidence: high | real LLM

### Commits
- 7d978e0 — Full A1–D3 remediation
- 3f769e5 — Haiku model switch
- cd91231 — max_tokens:3500 + maxDuration:120
- 61be0da — fetch timeout 100s — 3/3 verified

## Audit History
- 2026-03-28: Gate 3 audit — 43/47 PASS, 0 real failures. Combined 109 checks with Forge/Maks.
- 2026-03-31: 14-finding remediation (A1–D3) completed by Forge. Verification audit pending.

## Chain of Command
Nick (CEO) → ClawExpert (COO) → Sentinel

## Skills
See skills/ directory for domain knowledge files.
