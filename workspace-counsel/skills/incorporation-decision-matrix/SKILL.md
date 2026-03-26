# SKILL 70: Incorporation Decision Matrix

## Purpose
Know exactly where to incorporate, what entity type to use, and why — for every type of product Nick builds.

## Decision Tree

### Question 1: Will you raise VC/institutional investment?
- **YES** → Delaware C-Corp (virtually all VC firms require this)
- **NO** (bootstrapped) → proceed to Question 2

### Question 2: Do you want pass-through taxation?
- **YES** → LLC (taxed as partnership by default, or elect S-Corp)
- **NO** (planning to reinvest profits, fine with corporate tax) → C-Corp

### Question 3: Where to form?

## Entity Options

### Delaware C-Corp — Default for Fundable Startups
- **Why**: most developed corporate law, Court of Chancery (specialized business court with no jury), VC-standard equity structure, universally understood governance
- **Cost**: $89 filing + $300/year franchise tax minimum + $50–150/year registered agent
- **Iowa operation**: must also register as foreign entity in Iowa ($100) where Nick operates
- **When to use**: any product you might raise money for, sell, or take public; Agent Sparta if raising within 12 months
- **Downside**: franchise tax (minimum $300/year, can be much higher based on authorized shares); must qualify in Iowa

### Iowa LLC — Default for Bootstrapped Operations
- **Why**: cheapest, simplest, pass-through taxation, no franchise tax, Nick's home state
- **Cost**: $50 filing + $60/year annual report
- **Iowa corporate tax**: 5.5% flat rate (C-Corp) OR pass-through to individual (LLC)
- **Iowa individual income tax**: 3.8% flat rate
- **When to use**: initial testing entities, side projects, UberKiwi-style bootstrapped products
- **Limitation**: VCs will not invest in Iowa LLC; requires conversion to Delaware C-Corp before raising

### Wyoming LLC — Specific Purposes
- **Why**: DAO LLC recognition (first state to recognize DAOs), no state income tax, strongest asset protection (charging order is exclusive remedy)
- **Cost**: $100 filing + $60/year
- **Note**: Nick still pays Iowa individual income tax as Iowa resident regardless
- **When to use**: DAO wrapper for decentralized protocol, asset protection for crypto holdings

### Delaware LLC — Holding Company
- **Series LLC**: available (Iowa doesn't have this) — multiple series with separate liability
- **Cost**: $90 filing + $300/year
- **When to use**: holding company structure with multiple product subsidiaries

### Cayman Islands Foundation
- **Why**: protocol governance, non-profit structure for DAO, no beneficial owner (ideal for decentralized protocol)
- **Cost**: $10–25K setup + $5–10K/year maintenance
- **When to use**: global protocol governance for prediction market (Phase 3); NOT for tax avoidance (Nick is a US person — CFC rules apply)

### Singapore Pte. Ltd.
- **Why**: Asia-Pacific operations, 17% corporate tax, well-regulated crypto jurisdiction (MAS)
- **Cost**: $5–10K setup
- **When to use**: serving Singapore/SEA users, MAS DPT license application

### BVI Business Company
- **Why**: simplest offshore structure, 0% local corporate tax, privacy
- **Cost**: $5–15K setup
- **Note**: Nick is a US person — still pays US tax on controlled foreign corporations (CFC rules, Subpart F income)
- **When to use**: holding non-US IP, non-US operational entity for global users

## Nick's Recommended Structures by Product

### Agent Sparta (Skill-Based AI Competition)
- **Bootstrapping → raising later**: Iowa LLC now → convert to Delaware C-Corp when raising (costs $5–15K in legal fees)
- **Planning to raise within 12 months**: Delaware C-Corp from day one, register as foreign entity in Iowa
- **Rationale**: Iowa LLC avoids unnecessary cost if raise is uncertain; Delaware C-Corp eliminates conversion friction if raise is imminent

### AI Prediction Market
- **Phase 1 (free-to-play, US only)**: sub-entity under Agent Sparta's entity — no separate entity needed
- **Phase 2 (paid, US)**: Delaware C-Corp subsidiary or separate Delaware entity for liability isolation
- **Phase 3 (global, decentralized)**: Cayman Foundation for protocol governance + US Delaware C-Corp for US frontend/services + offshore entity for non-US users

### AI Agent Token
- **US-accessible tokens**: Delaware C-Corp issues token warrants alongside equity SAFEs
- **Non-US token launch**: Cayman Foundation controls protocol; offshore entity handles token distribution to non-US persons; US entity handles US operations only

### Perlantir Holdings Structure
```
Perlantir Holdings LLC (Delaware) — IP holding, intercompany licensing
    │
    ├── Agent Sparta Inc. (Delaware C-Corp) — skill competition platform
    │
    ├── [Prediction Market] Inc. (Delaware C-Corp) — US prediction market operations
    │
    └── [Protocol] Foundation (Cayman) — global protocol governance, token
```
- Each product is a separate subsidiary → liability isolation between products
- Holdings LLC owns IP → licenses to operating subsidiaries → centralizes IP ownership
- Separation protects: if one product has a regulatory problem, it doesn't take down the others

## Conversion Paths
- **Iowa LLC → Delaware C-Corp**: form Delaware C-Corp, merge Iowa LLC into it (or asset transfer). Legal cost: $5–15K.
- **Single entity → multi-entity**: form subsidiaries as needed. Transfer assets via inter-company agreements with arm's-length pricing.
- **LLC → C-Corp for VC**: standard conversion, your attorney handles the paperwork. VCs expect this.

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
