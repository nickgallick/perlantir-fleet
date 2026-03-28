# FLEET-MEMORY.md — Shared Fleet Context
# Maintained by ClawExpert (COO). All agents read this on startup.
# Last updated: 2026-03-26

## Fleet Roster (14 Agents — Current)
1. **Maks** ⚡ — Builder | @OpenClawVPS2BOT | Sonnet 4.6 | workspace: /data/.openclaw/workspace
2. **MaksPM** 📋 — Orchestrator | @VPSPMClawBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-pm
3. **Scout** 🔍 — Research | @ClawScout2Bot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-scout (uses /workspace)
4. **ClawExpert** 🧠 — COO/Ops | @TheOpenClawExpertBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-clawexpert
5. **Forge** 🔥 — Code Review | @ForgeVPSBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-forge
6. **Pixel** 🎨 — Design | @ThePixelCanvasBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-pixel
7. **Launch** 🚀 — Go-to-Market | @PerlantirLaunchBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-launch
8. **Chain** ⛓️ — Blockchain | @TheChainVPSBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-chain
9. **Counsel** ⚖️ — Legal Intelligence | @TheGeneralCounselBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-counsel
10. **Gauntlet** ⚔️ — Challenge Engine | @TheGauntletVPSBot | Opus 4.6 | workspace: /data/.openclaw/workspace-gauntlet
11. **Sentinel** 🛡️ — Runtime QA Auditor | @RuntimeQAAuditorBot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-sentinel
12. **Polish** ✨ — Product Polish Auditor | @ProductPolishAntiAIQABot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-polish
13. **Aegis** 🛡 — Security & Trust Auditor | @STQABot | Sonnet 4.6 | workspace: /data/.openclaw/workspace-aegis
14. **Relay** 🔄 — Playwright Automation Auditor | @PlaywrightautomationQABOT | Sonnet 4.6 | workspace: /data/.openclaw/workspace-relay

## Chain of Command
Nick (CEO) → ClawExpert (COO) → All Agents

## Current Models
- Most agents: `anthropic/claude-sonnet-4-6`
- Chain: `anthropic/claude-opus-4-6` (blockchain architecture tasks)
- Gauntlet: `anthropic/claude-opus-4-6` (NON-NEGOTIABLE — challenge design requires max reasoning)

## Key Fleet Events

### 2026-03-27
- **Gauntlet added** (10th agent): Challenge generation engine for Bouts. @TheGauntletVPSBot. Opus 4.6. 76 skills incoming.
- **Chain upgraded to Opus** for blockchain architecture work on Bouts scoring contracts

### 2026-03-26
- **Counsel added** (9th agent): Legal & regulatory intelligence. @TheGeneralCounselBot. Iowa law specialist. SEC/CFTC/prediction market expert.
- **maks2 removed**: Was leftover agent, not needed.
- **All agents → Sonnet 4.6**: Nick directive. All Opus agents downgraded.
- **Bootstrap files added**: Maks, Forge, Pixel, Chain, Counsel all got BOOTSTRAP.md.
- **Chain audit complete**: 116 skills verified substantive. MEMORY.md, TOOLS.md, AGENTS.md fixed.
- **FLEET-MEMORY.md created**: This file. All agents now read it on startup for shared context.

### 2026-03-22
- **ClawExpert promoted to COO**: Second in command. All agents report to ClawExpert, who reports to Nick.
- **CEO-DIRECTIVE.md**: Permanent directive at /data/.openclaw/CEO-DIRECTIVE.md. All agents must read every session.

### 2026-03-20
- **MaksPM, Launch upgraded to Opus** (now back to Sonnet per 2026-03-26 directive)
- **Forge added** as code review agent
- **Pixel added** as design agent

## Git Repository (Source of Truth)
- **Repo**: https://github.com/nickgallick/perlantir-fleet (private)
- **Auto-commit**: Daily 2 AM KL via `fleet-git-commit` cron — commits all workspace changes automatically
- **Manual commit**: `cd /data/.openclaw && git add -A && git commit -m "message" && git push origin main`
- **What's tracked**: All workspace files, skills, SOUL.md, memory files, openclaw.json
- **What's excluded**: Session transcripts, credentials, cloned repos (too large)
- **Restore/migrate**: `git clone https://TOKEN@github.com/nickgallick/perlantir-fleet.git /data/.openclaw`

## Shared Infrastructure
- **Config**: /data/.openclaw/openclaw.json
- **CEO Directive**: /data/.openclaw/CEO-DIRECTIVE.md (READ EVERY SESSION)
- **Fleet Memory**: /data/.openclaw/FLEET-MEMORY.md (this file — read every session)
- **VPS**: 72.61.127.59 (Hostinger)
- **Container**: openclaw-okny-openclaw-1
- **Gateway port**: 18789

## Products Being Built
- **Agent Arena (Bouts)**: AI agent coding competition platform. Judges: Claude + GPT-4o + Gemini. On-chain prize pools on Base (Phase 1).
- **UberKiwi**: Agency for SMBs
- **OUTBOUND**: Lead gen tool
- **Perlantir AI Studio**: The platform/umbrella

## Cross-Agent Rules
- Counsel reviews ALL products for legal risk before Launch activates
- Chain coordinates with Counsel before any contract deployment
- Forge reviews Maks's code before it ships
- MaksPM coordinates the pipeline — report blockers to MaksPM
- ClawExpert (COO) has authority to direct any agent on process matters
