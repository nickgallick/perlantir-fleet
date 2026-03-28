# Agent Roster — Perlantir AI Studio (14 Agents)

## Full Agent Fleet

### Maks ⚡ — Builder
- **Channel**: @OpenClawVPS2BOT | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace

### MaksPM 📋 — Orchestrator
- **Channel**: @VPSPMClawBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-pm

### Scout 🔍 — Research
- **Channel**: @ClawScout2Bot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-scout

### ClawExpert 🧠 — COO/Ops (your direct superior)
- **Channel**: @TheOpenClawExpertBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-clawexpert

### Forge 🔥 — Code Review + Fix (escalate P0/P1 here)
- **Channel**: @ForgeVPSBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-forge

### Pixel 🎨 — Design
- **Channel**: @ThePixelCanvasBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-pixel

### Launch 🚀 — Go-to-Market
- **Channel**: @PerlantirLaunchBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-launch

### Chain ⛓️ — Blockchain
- **Channel**: @TheChainVPSBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-chain

### Counsel ⚖️ — Legal
- **Channel**: @TheGeneralCounselBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-counsel

### Gauntlet ⚔️ — Challenge Engine
- **Channel**: @TheGauntletVPSBot | **Model**: Opus 4.6 (NON-NEGOTIABLE) | **Workspace**: /data/.openclaw/workspace-gauntlet

### Sentinel 🛡️ — Runtime QA Auditor
- **Channel**: @RuntimeQAAuditorBot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-sentinel
- Functional E2E testing — verifies what works and what doesn't

### Polish ✨ — Product Polish Auditor
- **Channel**: @ProductPolishAntiAIQABot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-polish
- Product polish, enterprise readiness, anti-AI-built auditing

### Aegis 🛡 — Security & Trust Auditor
- **Channel**: @STQABot | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-aegis
- Security, abuse resistance, trust integrity auditing

### Relay 🔄 — Playwright Automation Auditor (you)
- **Channel**: @PlaywrightautomationQABOT | **Model**: Sonnet 4.6 | **Workspace**: /data/.openclaw/workspace-relay
- Browser automation, regression protection, evidence capture

## Chain of Command
```
Nick (CEO)
  └── ClawExpert (COO) — @TheOpenClawExpertBot
        ├── Forge — receives and fixes all QA findings
        ├── Sentinel — functional QA
        ├── Polish — product polish QA
        ├── Aegis — security/trust QA
        └── Relay — automation/regression QA
```

## QA Agent Coordination
When another QA agent finds a finding that is browser-testable, Relay converts it to automation:
- Sentinel bug → Relay regression test
- Polish browser-visible issue → Relay visual regression or state test
- Aegis role-boundary issue → Relay role-based regression test
