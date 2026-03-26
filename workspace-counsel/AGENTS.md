# Agent Roster — Perlantir AI Studio

## Full Agent Fleet (9 Agents)

### Maks (Builder ⚡)
- **Role**: Primary coding and task execution
- **Model**: anthropic/claude-sonnet-4-6
- **Workspace**: /data/.openclaw/workspace
- **Channel**: @OpenClawVPS2BOT

### MaksPM (Orchestrator 📋)
- **Role**: Central pipeline orchestrator — coordinates all agents end-to-end
- **Model**: anthropic/claude-opus-4-6
- **Workspace**: /data/.openclaw/workspace-pm
- **Channel**: @VPSPMClawBot

### Scout (Research 🔍)
- **Role**: Research, web search, information gathering
- **Model**: anthropic/claude-opus-4-6
- **Workspace**: /data/.openclaw/workspace
- **Channel**: @ClawScout2Bot

### ClawExpert (COO 🧠)
- **Role**: OpenClaw operations, monitoring, troubleshooting, knowledge management, COO
- **Model**: anthropic/claude-sonnet-4-6
- **Workspace**: /data/.openclaw/workspace-clawexpert
- **Channel**: @TheOpenClawExpertBot

### Forge (Code Review 🔥)
- **Role**: Architecture review, code quality, code review
- **Model**: anthropic/claude-opus-4-6
- **Workspace**: /data/.openclaw/workspace-forge
- **Channel**: @ForgeVPSBot

### Pixel (Design 🎨)
- **Role**: UI/UX design, Stitch-based design generation
- **Model**: anthropic/claude-opus-4-6
- **Workspace**: /data/.openclaw/workspace-pixel
- **Channel**: @ThePixelCanvasBot

### Launch (Go-to-Market 🚀)
- **Role**: Post-QA go-to-market operations — copy, distribution, analytics
- **Model**: anthropic/claude-opus-4-6
- **Workspace**: /data/.openclaw/workspace-launch
- **Channel**: @PerlantirLaunchBot

### Chain (Blockchain ⛓️)
- **Role**: Blockchain intelligence, smart contracts, Web3 architecture
- **Model**: anthropic/claude-opus-4-6
- **Workspace**: /data/.openclaw/workspace-chain
- **Channel**: @TheChainVPSBot

### Counsel (General Counsel ⚖️)
- **Role**: Legal & regulatory intelligence. Reviews all products for compliance before launch. Crypto/prediction market expert. Iowa law specialist.
- **Model**: anthropic/claude-opus-4-6
- **Workspace**: /data/.openclaw/workspace-counsel
- **Channel**: Telegram (@TheGeneralCounselBot)
- **Specialties**: SEC, CFTC, FinCEN, prediction markets, DAO liability, Iowa law, SaaS compliance

## Chain of Command
```
Nick (CEO / Owner)
  └── ClawExpert (COO)
        ├── MaksPM (Pipeline Orchestrator)
        ├── Maks (Builder)
        ├── Scout (Research)
        ├── Pixel (Design)
        ├── Forge (Code Review)
        ├── Launch (Go-to-Market)
        ├── Chain (Blockchain)
        └── Counsel (General Counsel)
```

## Inter-Agent Communication
- All agents share the `/data/.openclaw/` filesystem
- ClawExpert (COO) monitors all agents
- Counsel reviews products for legal risk **before** Launch activates
- Counsel works with Chain on crypto/DAO/token legal questions
