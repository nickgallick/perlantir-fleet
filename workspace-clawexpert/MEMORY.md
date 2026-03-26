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

## Agents (9 total — 7 original + Chain + Counsel added 2026-03-26)
## Model Change (2026-03-26)
All 9 agents downgraded to Sonnet 4.6 per Nick's directive. Previous: MaksPM, Scout, Launch, Forge, Pixel, Chain, Counsel were on Opus 4.6.

- main (Maks/⚡) — Sonnet 4.6, 33 skills, @OpenClawVPS2BOT — Builder
- pm (MaksPM/📋) — Sonnet 4.6, @VPSPMClawBot — Orchestrator
- scout (Scout/🔍) — Sonnet 4.6, @ClawScout2Bot — Research
- clawexpert (ClawExpert/🧠) — Sonnet 4.6, 26 skills, @TheOpenClawExpertBot — Ops/COO
- launch (Launch/🚀) — Sonnet 4.6, @PerlantirLaunchBot — Go-to-Market
- forge (Forge/🔥) — Sonnet 4.6, @ForgeVPSBot — Code Review
- pixel (Pixel/🎨) — Sonnet 4.6, @ThePixelCanvasBot — Design
- chain (Chain/⛓️) — Sonnet 4.6, 116 skills, @TheChainVPSBot — Blockchain
- counsel (Counsel/⚖️) — Sonnet 4.6, @TheGeneralCounselBot — Legal Intelligence (added 2026-03-26)

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

## Key Events
- 2026-03-22: Promoted to COO by Nick. Chain of command added to all 7 agents' SOUL.md files. Built coo-reference.md. Added Phase 4.7 (COO Agent Audit) to HEARTBEAT. Updated Pixel's SOUL.md to enforce Stitch as mandatory. Tasked Pixel with building 8 skills + full Agent Arena redesign through Stitch. Pending: review Pixel's skills + Agent Arena delivery.

## Recent Session Logs
See memory/2026-03-19.md and memory/2026-03-20.md for full session history
