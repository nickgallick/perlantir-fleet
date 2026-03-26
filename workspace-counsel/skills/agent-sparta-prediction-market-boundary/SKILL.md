# SKILL: Agent Sparta vs. Prediction Market Classification Boundary

## Purpose
Define the legal classification boundary between (A) Agent Arena / Bouts as an AI coding skill competition with prizes and (B) a prediction market / commodity contract market subject to CFTC jurisdiction. This is the single most strategically important legal distinction for Nick's product.

## Risk Level
⚫ Existential — If Bouts / Agent Arena is classified as a CFTC-regulated prediction market or gambling operation rather than a skill competition, the entire product design, licensing requirements, and go-to-market strategy must change. Get this right before building.

---

## The Core Legal Question

**Is Agent Arena / Bouts:**
(A) A **skill-game competition** where AI agents compete, participants pay entry fees, and winners receive prizes — governed by state skill-game law, not CFTC?

OR

(B) A **prediction market / event contract market** where participants bet on contest outcomes — a commodity interest subject to CFTC jurisdiction?

OR

(C) **Both**: A competition layer (skill game) AND a wagering layer (prediction market) that must be separately structured and regulated?

**Answer**: Almost certainly (C), and the architecture must reflect this from day one.

---

## Legal Framework for Classification

### The Commodity Exchange Act (CEA) Test
**7 U.S.C. § 1a(9)**: "Commodity" includes "all other goods and articles... and all services, rights, and interests (including any index and any interest therein or based thereon) in which contracts for future delivery are presently or in the future dealt in."

**7 U.S.C. § 1a(13)**: "Commodity interest" includes contracts of sale of a commodity for future delivery, options on such contracts, and swaps.

**Key question**: Is the outcome of an AI coding competition a "commodity" under the CEA?

### The CFTC "Event Contract" Theory
**CEA § 5c(c)(5)(C)**: Event contracts — CFTC has authority over contracts whose value is based on "occurrence" or "nonoccurrence" of events.

**Kalshi holding (D.C. Cir. 2024)**: Political events ARE valid commodity contract underlying. The court rejected "gaming" carve-out for political events with genuine price discovery value.

**Application to AI coding competitions**:
- "Which AI agent wins this coding contest?" = an event
- Contracts settled on that event = event contracts under CEA § 5c(c)(5)(C)
- **Likely conclusion**: The wagering layer on AI contest outcomes IS within CFTC jurisdiction if structured as tradeable contracts

### The Gambling Classification Test
**State law**: Whether the competition is "gambling" depends on state definition of gambling
**Iowa Code § 99B.1**: Iowa definition of gambling includes any game "where the outcome depends to a material degree on an element of chance"

**Skill-game exception**: Most states (including Iowa) exempt skill games from gambling regulation if the outcome is "predominantly determined by skill, not chance"

**The DraftKings/FanDuel Precedent**: Fantasy sports (selecting real players, competing on stats) = skill game in most states
- Most states passed DFS-specific exemptions 2015–2018
- Iowa Code § 99E: Iowa DFS statute (fantasy sports exempt from gambling)
- Key factors: (1) outcome determined by skill; (2) no "house" advantage; (3) results not based on single real-world event

**Application to AI coding competitions**:
- Outcome (who built better code) = skill-based ✅
- No house advantage if platform doesn't compete ✅
- Based on aggregate performance, not single real-world event ✅
- **Likely: Qualifies as skill game under Iowa law and most state law**

---

## The Two-Layer Architecture

### Layer 1: The Competition (Skill Game)
**What it is**: AI agents competing in coding challenges, judged by defined criteria
**Legal classification**: Skill game / contest
**Governing law**: State law (Iowa Code § 99B — Iowa games and amusements)
**Regulatory risk**: Low if properly structured
**Revenue model**: Entry fees → prize pool distribution

**Requirements for skill-game protection**:
- Outcome must be materially determined by skill (coding ability of AI agent)
- Transparent, consistent judging criteria (not arbitrary)
- No "house" competition advantage (platform doesn't compete against users)
- Results based on agent performance, not external events
- Prize pool must come entirely from entry fees (not house funds — avoids house-banked game classification)

### Layer 2: The Prediction Market / Wagering (If Any)
**What it is**: Third parties wagering on which agent wins the competition
**Legal classification**: Event contract / prediction market
**Governing law**: Federal (CEA, CFTC jurisdiction)
**Regulatory risk**: 🔴 High without CFTC authorization
**Revenue model**: Spread, fees on wagers, market-making

**Options for the wagering layer**:
1. **No wagering layer** (safest): Keep it pure skill competition; no betting on outcomes
2. **Restricted to participants**: Only contest entrants can "bet" via entry fees; eliminates third-party market
3. **CFTC no-action letter**: Seek no-action for a limited prediction market on AI contest outcomes
4. **DCM registration**: Full CFTC registration; permits open wagering
5. **Token-based outcome resolution**: Use on-chain settlement that may or may not trigger CEA (unsettled)

---

## The "Agent" Distinction: Contestants vs. Bettors

This is Nick's unique situation. The product involves:
- **AI agents** as contestants (they compete)
- **Humans** (and potentially other agents) as bettors on outcomes
- **Platform** as market organizer

**Critical legal distinctions**:

| Role | Legal Classification | Regulatory Treatment |
|------|---------------------|---------------------|
| Contest participant (runs agent) | Player in skill game | State skill-game law |
| Contest sponsor (funds prize pool) | Investor in contest | Minimal regulation |
| Bettor on contest outcome | Market participant | CFTC jurisdiction (if event contract) |
| Market maker for outcome contracts | Commodity intermediary | CFTC registration (CTA, CPO, or DCM) |
| Platform operator | Exchange / facilitator | CFTC registration if DCM / exchange |

**Insider trading wall**: Participants who know their agent's performance cannot bet on their own contest without violating insider trading principles. Must be structurally separated.

---

## Entity Structure Implications

### Option A: Pure Skill Competition (No Wagering Layer)
**Entity**: Single LLC (Iowa or Delaware)
**Regulatory burden**: Low
**Revenue model**: Entry fees, subscription to competition access, sponsorships
**Limitation**: No wagering economics; lower potential upside

**Iowa entity advantage**: Iowa LLC operating a skill competition; Iowa Code § 99B exemption analysis applies locally; Iowa AG is the relevant enforcement authority (not CFTC)

### Option B: Competition + Restricted Participant Market
**Structure**: Participants can wager against each other (like DFS)
**Entity**: Single LLC with DFS-style structure
**Model**: Iowa Code § 99E DFS exemption analysis — extend to AI competitions
**Risk**: Iowa DFS statute only covers "fantasy sports" — AI competitions may not fit squarely; need legislative clarity or AG opinion

### Option C: Competition + Open Prediction Market (Separate Entity)
**Structure**: 
- Entity A: Competition platform (skill game LLC)
- Entity B: Prediction market (seeks CFTC no-action or DCM registration)
**Rationale**: Clean separation reduces regulatory risk to competition entity
**Risk**: Entity B faces full CFTC framework
**Upside**: Maximizes product potential if both layers succeed

### Option D: Competition Layer Only + Oracle-Fed External Markets
**Structure**: Agent Arena runs pure competition; licenses outcome data to external prediction markets (Kalshi, Polymarket) as oracle
**Revenue**: Data licensing fees
**Risk**: Minimal for Agent Arena; external markets bear CFTC burden
**Interesting**: This may be the most creative near-term path — become the data provider for AI competition markets

---

## The PredictIt Blueprint Applied to Agent Arena

PredictIt CFTC no-action letter (2014) succeeded because:
1. Academic/research framing (run by George Washington University)
2. Limited market size ($850 max position per participant)
3. US-only topic area (elections)
4. Not-for-profit structure (at least nominally)
5. Genuine research/educational value claimed

**For Agent Arena**:
- Academic framing possible: "AI performance research" / "algorithmic coding benchmarking"
- Limited market size: Start with small prize pools
- Iowa connection: University of Iowa's Iowa Electronic Markets history = legitimate academic precedent for Iowa-based research market
- Research value: Genuine — AI agent performance data has academic value
- Structure: Could partner with Iowa institution for academic legitimacy

**This may be the no-action pathway**: "Research platform studying AI agent performance, with limited real-money participation, operated by Iowa-based entity"

---

## Immediate Legal Action Items

### Before Building
1. ✅ Decide: Competition only, or competition + wagering layer?
2. ✅ If wagering layer: Engage CFTC-specialized counsel NOW
3. ✅ Draft the structural separation between contest layer and market layer
4. ✅ Insider trading policy: Separate contest participants from market participants

### Before Launch (Competition Layer)
5. ✅ Iowa skill-game legal analysis (contest = skill game under Iowa Code § 99B)
6. ✅ Jurisdictional blocking: Identify states where entry fees + prizes create gambling issues
7. ✅ Contest rules: Must demonstrate skill-predominance (objective judging criteria)

### Before Launch (Wagering Layer, If Any)
8. ✅ CFTC no-action or DCM pathway decision
9. ✅ No-action counsel engagement
10. ✅ Academic partnership for research framing (Iowa angle)

---

## Key Cases and Statutes
- CEA § 5c(c)(5)(C): Event contracts authority
- Kalshi Inc. v. CFTC, No. 23-cv-03257 (D.D.C.): Political prediction markets = valid event contracts
- CFTC v. Polymarket (2022): Unregistered prediction market enforcement
- Iowa Code § 99B.1: Iowa gambling definition
- Iowa Code § 99E: Iowa DFS statute (skill game exemption for fantasy sports)
- PredictIt CFTC No-Action Letter 14-130 (2014): Academic prediction market safe harbor
- Humphrey's Executor v. US (1935) + Loper Bright (2024): CFTC regulatory authority limits post-Chevron

---

## Iowa Angle
- Iowa Electronic Markets (University of Iowa): The original US prediction market; academic framing worked for decades
- Iowa Code § 99E: DFS statute provides skill-game framework Nick could advocate to extend to AI competitions
- Iowa-based operation: Iowa AG, not CFTC, is primary enforcement authority for pure skill games
- Iowa's congressional delegation: Potentially useful for advocacy on AI competition regulatory clarity
- **Iowa is the optimal home jurisdiction** for an AI skill competition that wants to operate with minimal federal regulatory interference

---

## Summary Decision Matrix

| If Bouts is... | Primary regulator | Risk level | Required action |
|----------------|------------------|------------|-----------------|
| Pure skill competition (no wagering) | Iowa AG / State | 🟢 Low | Skill-game compliance |
| DFS-style (participants bet on themselves) | Iowa + CFTC gray area | 🟡 Medium | Iowa legal analysis + CFTC counsel |
| Open prediction market on contest outcomes | CFTC | 🔴 High | No-action letter or DCM registration |
| On-chain smart contract prediction market | CFTC + SEC gray area | 🔴 High | CFTC + securities counsel |
| Oracle/data provider to external markets | Minimal | 🟢 Low | Licensing agreement only |

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
