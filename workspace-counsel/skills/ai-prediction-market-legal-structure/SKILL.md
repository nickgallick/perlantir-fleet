# SKILL: AI Prediction Market Legal Structure
**Version:** 1.0.0 | **Domain:** CFTC, Gambling Law, Product Architecture

---

## The Concept
- AI models publish predictions on future events (Fed decisions, election outcomes, sports, crypto prices)
- Users bet on whether the AI's prediction is correct or incorrect
- Payout based on real-world outcome matching/not matching the AI's prediction

---

## Legal Characterization — Four Interpretations

### Interpretation 1: Binary Option on Future Event (CFTC Jurisdiction) 🔴 HIGH RISK
**The economic substance argument:**
- "Will the Fed raise rates?" is an event contract regardless of AI framing
- The AI prediction is a wrapper — the underlying bet is still on a real-world event outcome
- A CFTC enforcement attorney looks at economic substance, not product naming
- **Strength:** HIGH — this is how the CFTC would characterize it
- **Precedent:** CFTC v. Polymarket — economic substance of binary outcome on future event = event contract

### Interpretation 2: Bet on AI Performance 🟡 MEDIUM RISK
**The AI evaluation argument:**
- Reframe: "Is this AI model calibrated?" — a question about the AI, not the underlying event
- The "event" is AI accuracy, not the Fed's decision
- **Critical design factor:**
  - If users CHOOSE which prediction to bet on → they're selecting the underlying event → looks like Interp. 1
  - If platform ASSIGNS predictions in batches → stronger argument for Interp. 2
- Weaker legal argument but viable if product is designed around AI evaluation, not event speculation

### Interpretation 3: Research Instrument 🟢 LOW RISK (if structured correctly)
- Frame as measuring AI calibration — a research tool
- Users participate in "calibration studies" compensated for evaluating AI predictions
- Iowa Electronic Markets precedent: CFTC allowed academic prediction markets under no-action letters
- **Requirements:** Genuine research purpose, academic affiliation or partnership, limited scale
- **Risk:** If real money + payout scale → regulators pierce academic framing

### Interpretation 4: Fantasy AI League (DFS Analog) 🟢-🟡 LOW-MEDIUM RISK
- Structure like DraftKings but for AI models instead of athletes
- Users build "portfolios" of AI models, scored on prediction accuracy over a season
- "Pick the best AI models" = skill-based selection activity
- DFS legal in ~40 states under skill-game carve-outs
- **Strongest argument for avoiding gambling classification**
- **Trade-off:** Diverges from pure prediction market concept; may reduce monetization ceiling

---

## Critical Design Decisions That Affect Classification

| Design Choice | Risk Direction |
|---|---|
| Binary outcome (yes/no) | → Looks like binary option → CFTC jurisdiction |
| Multi-outcome scoring (portfolio) | → Looks like DFS → skill game framework |
| Real-world event as underlying | → CFTC regardless of AI framing |
| AI capability as underlying | → Potentially novel, outside existing CFTC precedent |
| Entry fee + prize pool | → Gaming/contest regulation |
| Continuous market with order book | → Looks like exchange → DCM requirement |
| Users select which AI to bet on | → They're selecting the event → CFTC |
| Platform assigns predictions randomly | → Stronger AI evaluation argument |

---

## Recommended Phased Structure

### Phase 1: Free-to-Play with Reputation (ZERO Legal Risk)
**Duration:** 3-6 months
- No real money wagering
- Users earn points/reputation for correctly evaluating AI predictions
- Leaderboard, streaks, badges — gamification without gambling
- **Revenue:** Data licensing (AI labs pay for calibration data), advertising, analytics subscriptions
- **Why:** Build user base, establish track record, collect data for academic partnership applications
- **Legal risk:** ZERO — no money changes hands based on event outcomes

### Phase 2: Entry-Fee Competitions (DFS Model) 🟢-🟡 LOW-MEDIUM
**Duration:** Launch after Phase 1 establishes user behavior data
- Users pay entry fees to join prediction contests
- Structured as skill-based competitions (analyzing AI models is a skill)
- Agent Sparta legal analysis applies: 40+ states allow this
- **Required:** Geo-block prohibited states, age verification, responsible gaming
- **Revenue:** 10-15% rake on entry fees
- **Critical:** DO NOT structure as binary bet on a single future event; structure as portfolio/season-long scoring

### Phase 3: Full Prediction Market (Contingent on Regulatory Clarity)
**Triggers:** (a) CFTC provides clear path for AI-prediction event contracts, OR (b) offshore entity with US geo-block
- Monitor Kalshi's expansion and CFTC rulemaking post-2024 court decisions
- Option A: Register as DCM (Kalshi model) — expensive but fully legal for US users
- Option B: Cayman entity, geo-block US (Polymarket model) — faster, cheaper, accepts enforcement risk

---

## The Howey Overlay for Any Token
If you add a token layer to this platform:
- If users buy token expecting platform success to increase token value → likely a security
- Safer: utility token used ONLY for entry fees, no secondary market
- Safest: no token; use USDC for all payments

---

## What a CFTC Enforcement Attorney Focuses On
1. **Economic substance:** Can I map this to a binary option on a real-world event? (Almost always yes for prediction markets)
2. **Who benefits from the outcome:** Is there a clear winner/loser based on a future event? → swap
3. **Order book or market structure:** Does it look like an exchange? → DCM requirement
4. **US persons:** Are US users accessing despite geo-blocks? → enforcement jurisdiction still exists
5. **Custody of funds:** Does the platform control funds pending outcome? → money transmission + MSB

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
