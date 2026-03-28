# Agent Roster — Perlantir AI Studio (14 Agents)

## Full Agent Fleet

### Maks ⚡ — Builder
- **Role**: Primary coding and task execution. Builds apps from specs.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @OpenClawVPS2BOT
- **Workspace**: /data/.openclaw/workspace

### MaksPM 📋 — Pipeline Orchestrator
- **Role**: Central pipeline orchestrator — coordinates all agents end-to-end
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @VPSPMClawBot
- **Workspace**: /data/.openclaw/workspace-pm

### Scout 🔍 — Research
- **Role**: Research, web search, market intelligence, information gathering
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ClawScout2Bot
- **Workspace**: /data/.openclaw/workspace-scout

### ClawExpert 🧠 — COO & OpenClaw Ops
- **Role**: Chief Operating Officer. OpenClaw operations, monitoring, troubleshooting, knowledge management.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheOpenClawExpertBot
- **Workspace**: /data/.openclaw/workspace-clawexpert

### Forge 🔥 — Code Review & Architecture
- **Role**: Architecture specs, code review, technical quality gate. Receives and fixes all QA findings.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ForgeVPSBot
- **Workspace**: /data/.openclaw/workspace-forge

### Pixel 🎨 — Design
- **Role**: UI/UX design, Stitch-based design generation, implementation-grade specs
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ThePixelCanvasBot
- **Workspace**: /data/.openclaw/workspace-pixel

### Launch 🚀 — Go-to-Market
- **Role**: Post-QA go-to-market operations. Launch copy, distribution, analytics, GTM strategy.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @PerlantirLaunchBot
- **Workspace**: /data/.openclaw/workspace-launch

### Chain ⛓️ — Blockchain
- **Role**: Blockchain intelligence, smart contracts, Web3 architecture
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheChainVPSBot
- **Workspace**: /data/.openclaw/workspace-chain

### Counsel ⚖️ — Legal Intelligence
- **Role**: Legal & regulatory intelligence. Iowa law specialist. Compliance reviews before launch.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheGeneralCounselBot
- **Workspace**: /data/.openclaw/workspace-counsel

### Gauntlet ⚔️ — Challenge Engine
- **Role**: Challenge generation engine for Bouts. Designs, calibrates, and publishes challenges.
- **Model**: anthropic/claude-opus-4-6 (NON-NEGOTIABLE — challenge design requires maximum reasoning)
- **Channel**: @TheGauntletVPSBot
- **Workspace**: /data/.openclaw/workspace-gauntlet

### Sentinel 🛡️ — Runtime QA Auditor
- **Role**: Functional E2E testing. Verifies Bouts works from the outside in. Tests every role and route.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @RuntimeQAAuditorBot
- **Workspace**: /data/.openclaw/workspace-sentinel

### Polish ✨ — Product Polish Auditor
- **Role**: Product polish, enterprise readiness, anti-AI-built auditing. Scores product quality 1-10 across 8 dimensions.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ProductPolishAntiAIQABot
- **Workspace**: /data/.openclaw/workspace-polish

### Aegis 🛡 — Security & Trust Auditor
- **Role**: Security, abuse resistance, and trust integrity auditing. Tests access control, abuse cases, data leakage.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @STQABot
- **Workspace**: /data/.openclaw/workspace-aegis

### Relay 🔄 — Playwright Automation Auditor
- **Role**: Browser automation, regression protection, evidence capture. Makes Bouts hard to silently break.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @PlaywrightautomationQABOT
- **Workspace**: /data/.openclaw/workspace-relay

## Chain of Command
```
Nick (CEO / Owner) — @VPSClaw (Telegram ID: 7474858103)
  └── ClawExpert 🧠 (COO) — @TheOpenClawExpertBot
        ├── MaksPM 📋 (Pipeline Orchestrator)
        │     ├── Scout 🔍 → Pixel 🎨 → Maks ⚡ → Forge 🔥 → QA → Launch 🚀
        │     ├── Chain ⛓️ (blockchain features)
        │     └── Counsel ⚖️ (legal reviews)
        ├── Gauntlet ⚔️ (challenge generation for Bouts)
        └── QA Fleet
              ├── Sentinel 🛡️ (functional QA)
              ├── Polish ✨ (product quality QA)
              ├── Aegis 🛡 (security/trust QA)
              └── Relay 🔄 (automation/regression QA)
```

## Key Rules
- Forge receives and fixes ALL QA findings from Sentinel, Polish, Aegis, and Relay
- ClawExpert is COO — escalate blockers, inter-agent issues, and operational problems here
- Gauntlet uses Opus 4.6 (NON-NEGOTIABLE) — never downgrade
- All agents read CEO-DIRECTIVE.md and FLEET-MEMORY.md on every session start
