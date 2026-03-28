# Agent Roster — Perlantir AI Studio (13 Agents)

## Full Agent Fleet

### Maks ⚡ — Builder
- **Role**: Primary coding and task execution
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @OpenClawVPS2BOT
- **Workspace**: /data/.openclaw/workspace

### MaksPM 📋 — Orchestrator
- **Role**: Central pipeline orchestrator
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @VPSPMClawBot
- **Workspace**: /data/.openclaw/workspace-pm

### Scout 🔍 — Research
- **Role**: Research, web search, information gathering
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ClawScout2Bot
- **Workspace**: /data/.openclaw/workspace-scout

### ClawExpert 🧠 — COO/Ops
- **Role**: OpenClaw operations, monitoring, COO — your direct superior
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheOpenClawExpertBot
- **Workspace**: /data/.openclaw/workspace-clawexpert

### Forge 🔥 — Code Review + Builder
- **Role**: Architecture review, code quality, bug fixes — escalate P0/P1 findings here
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ForgeVPSBot
- **Workspace**: /data/.openclaw/workspace-forge

### Pixel 🎨 — Design
- **Role**: UI/UX design
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ThePixelCanvasBot
- **Workspace**: /data/.openclaw/workspace-pixel

### Launch 🚀 — Go-to-Market
- **Role**: Post-QA go-to-market operations
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @PerlantirLaunchBot
- **Workspace**: /data/.openclaw/workspace-launch

### Chain ⛓️ — Blockchain
- **Role**: Blockchain intelligence, smart contracts, Web3 architecture
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheChainVPSBot
- **Workspace**: /data/.openclaw/workspace-chain

### Counsel ⚖️ — Legal Intelligence
- **Role**: Legal & regulatory intelligence. Iowa law specialist.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheGeneralCounselBot
- **Workspace**: /data/.openclaw/workspace-counsel

### Gauntlet ⚔️ — Challenge Engine
- **Role**: Challenge generation engine for Bouts
- **Model**: anthropic/claude-opus-4-6 (NON-NEGOTIABLE)
- **Channel**: @TheGauntletVPSBot
- **Workspace**: /data/.openclaw/workspace-gauntlet

### Sentinel 🛡️ — Runtime QA Auditor
- **Role**: Functional E2E testing — verifies what works and what doesn't
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @RuntimeQAAuditorBot
- **Workspace**: /data/.openclaw/workspace-sentinel

### Polish ✨ — Product Polish Auditor
- **Role**: Product polish, enterprise readiness, anti-AI-built auditing
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ProductPolishAntiAIQABot
- **Workspace**: /data/.openclaw/workspace-polish

### Aegis 🛡 — Security & Trust Auditor
- **Role**: Security, abuse resistance, trust integrity auditing
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @STQABot
- **Workspace**: /data/.openclaw/workspace-aegis

## Chain of Command
```
Nick (CEO)
  └── ClawExpert (COO)
        ├── MaksPM (Pipeline)
        ├── Maks (Builder)
        ├── Forge (Code Review + Fix)  ← QA agents escalate P0/P1 here
        ├── Sentinel (Runtime QA)
        ├── Polish (Product Polish QA)
        └── Aegis (Security QA)
```

## QA Agent Coordination
- **Sentinel** = functional testing (does it work?)
- **Polish** = product quality (does it feel premium and real?)
- **Aegis** = security/abuse/trust (is it safe and resistant to abuse?)
- **Forge** = receives and fixes all QA findings
- **ClawExpert** = COO, receives escalations, coordinates QA gate decisions
