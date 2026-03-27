# Agent Roster — Perlantir AI Studio (10 Agents)

## Full Agent Fleet

### Maks ⚡ — Builder
- **Role**: Primary coding and task execution
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @OpenClawVPS2BOT
- **Workspace**: /data/.openclaw/workspace

### MaksPM 📋 — Orchestrator
- **Role**: Central pipeline orchestrator — coordinates all agents end-to-end
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @VPSPMClawBot
- **Workspace**: /data/.openclaw/workspace-pm

### Scout 🔍 — Research
- **Role**: Research, web search, information gathering
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ClawScout2Bot
- **Workspace**: /data/.openclaw/workspace-scout

### ClawExpert 🧠 — COO/Ops
- **Role**: OpenClaw operations, monitoring, COO
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheOpenClawExpertBot
- **Workspace**: /data/.openclaw/workspace-clawexpert

### Forge 🔥 — Code Review
- **Role**: Architecture review, code quality, code review
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @ForgeVPSBot
- **Workspace**: /data/.openclaw/workspace-forge

### Pixel 🎨 — Design
- **Role**: UI/UX design, Stitch-based design generation
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
- **Model**: anthropic/claude-opus-4-6
- **Channel**: @TheChainVPSBot
- **Workspace**: /data/.openclaw/workspace-chain

### Counsel ⚖️ — Legal Intelligence
- **Role**: Legal & regulatory intelligence. Iowa law specialist.
- **Model**: anthropic/claude-sonnet-4-6
- **Channel**: @TheGeneralCounselBot
- **Workspace**: /data/.openclaw/workspace-counsel

### Gauntlet ⚔️ — Challenge Engine
- **Role**: Challenge generation engine for Bouts. Designs, calibrates, and publishes challenges. Creates adversarial test suites and scoring rubrics.
- **Model**: anthropic/claude-opus-4-6 (NON-NEGOTIABLE)
- **Channel**: @TheGauntletVPSBot
- **Workspace**: /data/.openclaw/workspace-gauntlet

## Chain of Command
```
Nick (CEO)
  └── ClawExpert (COO)
        ├── MaksPM (Pipeline Orchestrator)
        ├── Maks (Builder)
        ├── Scout (Research)
        ├── Pixel (Design)
        ├── Forge (Code Review)
        ├── Launch (GTM)
        ├── Chain (Blockchain)
        ├── Counsel (Legal)
        └── Gauntlet (Challenge Engine)
```
