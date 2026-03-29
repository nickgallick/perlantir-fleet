# ClawExpert Long-Term Memory

## Identity
- Name: ClawExpert — COO & OpenClaw source-code-level intelligence agent
- Role: COO of the 7-agent fleet (promoted 2026-03-22 by Nick). Oversee agent process, quality gates, direct corrections, review/approve deliverables.
- Workspace: /data/.openclaw/workspace-clawexpert
- Detailed memory in: memory/YYYY-MM-DD.md files

## System
- OpenClaw version running: 2026.3.13 (HEAD: 2026.3.14)
- Container: openclaw-okny-openclaw-1
- VPS: 72.61.127.59 (Hostinger)
- Config: /data/.openclaw/openclaw.json
- Gateway PID: 2275 (check with pgrep -a openclaw)
- Gateway port: 18789
- Docker image digest: sha256:c677c4994dfc34827e99f422f672e7164e0a82716182874fdef5967de02747ea

## Role Change (2026-03-29)
- **Forge = Head Developer**: Owns architecture + building + self-review + deploy. Primary developer for all products.
- **Maks = Secondary/Support**: Only engaged by Nick's explicit request. Not in default pipeline.
- Both agents hardcoded with "Fully Wired Systems Only" P0 rule — no fake data, no dead UI, ever.

## Agents (10 total — Gauntlet added 2026-03-27, routing fixed 2026-03-28)
## Model Change (2026-03-26)
All agents on Sonnet 4.6 except Gauntlet (Opus 4.6 — NON-NEGOTIABLE per Nick).

- main (Maks/⚡) — Sonnet 4.6, @OpenClawVPS2BOT — Builder
- pm (MaksPM/📋) — Sonnet 4.6, @VPSPMClawBot — Orchestrator
- scout (Scout/🔍) — Sonnet 4.6, @ClawScout2Bot — Research
- clawexpert (ClawExpert/🧠) — Sonnet 4.6, @TheOpenClawExpertBot — Ops/COO
- launch (Launch/🚀) — Sonnet 4.6, @PerlantirLaunchBot — Go-to-Market
- forge (Forge/🔥) — Sonnet 4.6, @ForgeVPSBot — Code Review
- pixel (Pixel/🎨) — Sonnet 4.6, @ThePixelCanvasBot — Design
- chain (Chain/⛓️) — Sonnet 4.6, @TheChainVPSBot — Blockchain
- counsel (Counsel/⚖️) — Sonnet 4.6, @TheGeneralCounselBot — Legal Intelligence
- gauntlet (Gauntlet/⚔️) — Opus 4.6, @TheGauntletVPSBot — Challenge Engine (routing fixed 2026-03-28)

## CRITICAL: New Agent Routing Rule (learned 2026-03-28)
Every new agent MUST have an explicit binding in openclaw.json bindings array:
{ "agentId": "AGENT_ID", "match": { "channel": "telegram", "accountId": "ACCOUNT_KEY" } }
Without this, ALL messages route to Maks (main/default agent). This is how all 10 current agents are wired.

## Claude Code
- Installed **INSIDE the container**: `/data/.npm-global/bin/claude` (symlink to cli.js)
- Version: @anthropic-ai/claude-code@2.1.83
- Auth method: **OAuth via Claude Max subscription** (--claudeai flag)
- Credentials stored at: `/data/.claude/.credentials.json` (root:root 644)
- Account: Nick's Claude Max account, Opus 4.6, 1M context
- Auth flow: Run `claude` interactively, select option 1 (Claude subscription), open URL in browser, paste code at `Paste code here if prompted >`
- The prompt DOES appear in interactive mode — it was missed earlier because we used --print mode
- Verify: `claude auth status` or `claude --permission-mode bypassPermissions --print "hello"`
- Usage from ClawExpert: `claude --permission-mode bypassPermissions --print "task"`

## Critical Rules
- openclaw.json schema is Zod .strict() — unknown keys crash gateway
- Stitch MCP via mcporter ONLY — never in openclaw.json
- Valid dmPolicy: open, allowlist, pairing, disabled — NEVER "deny"
- OPENCLAW_GATEWAY_TOKEN env var overrides file token
- Claude Code: --permission-mode bypassPermissions --print (NEVER --dangerously-skip-permissions)
- Config changes: backup → edit → validate JSON → SIGUSR1 to reload

## Auth Token
- Gateway token: R0ddvlV8VIER6QRhJ8KujsOdZfJG7HxM
- Hooks token: hooks_R0ddvlV8VIER6QRhJ8KujsOdZfJG7HxM
- GitHub token: ghp_***REDACTED_SEE_TOOLS_MD*** (rotated 2026-03-29 — old token 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 expired)

## Key Events
- 2026-03-22: Promoted to COO. Chain of command added to all agent SOUL.md files.
- 2026-03-27: Gauntlet agent added (10th agent). Routing was broken — fixed 2026-03-28.
- 2026-03-28: Bouts E2E Gate 3 PASSED (109 checks, 0 real failures). Launch activated. Gauntlet routing fixed (missing binding). Paperclip VPS2 scoped — waiting for Nick to provision. Ballot agent planned.

## Bouts Status (2026-03-28)
- Live: https://agent-arena-roan.vercel.app
- ⚠️ BLOCKED: Migration 00024 partial — challenge_bundles table may not exist. Forge needs to re-call with correct Bearer header.
- GAUNTLET_INTAKE_API_KEY: a86c6d887c15c5bf259d2f9bcfadddf9 (in Vercel)
- Pending Nick: Stripe live keys, Iowa address, bouts.gg domain, ORACLE_WALLET_ADDRESS, BASE_RPC_URL
- First Gauntlet batch ready to go: 2 Blacksite Debug + 2 False Summit + 1 Fog of War (once migration unblocked)

## Paperclip Plan (2026-03-28)
- VPS2 for Paperclip control plane (8GB/2vCPU, Debian 12, Hostinger)
- Architecture: VPS1=OpenClaw execution, VPS2=Paperclip coordination
- 4 core workflows: Gauntlet→Forge→Calibration(Ballot)→Operator approval
- Ballot = new agent to add (calibration/learning feedback loop)
- Status: Waiting on Nick to provision VPS2 and send IP

## Recent Session Logs
See memory/2026-03-28.md for full 2026-03-28 session details
