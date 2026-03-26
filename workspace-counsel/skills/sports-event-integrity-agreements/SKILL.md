# SKILL: Sports and Event Integrity Agreements

## Purpose
Understand sports and event integrity agreements, why they matter for prediction markets, what leagues demand, and whether they're relevant for AI-focused competition platforms. This skill covers the legal landscape, known enforcement actions, and strategic guidance.

## Risk Level
🟡 Medium for traditional sports prediction markets / 🟢 Low for AI-focused coding competitions — Sports leagues have lobbied aggressively for integrity agreements as a condition of prediction market operation. For AI coding competitions, this is lower priority but understanding the framework matters for future sports-adjacent products.

---

## What Are Integrity Agreements?

**Definition**: Contractual arrangements between prediction market operators (or sportsbooks) and professional sports leagues/governing bodies that provide:
1. Access to official league data (for settlement purposes)
2. League consent to list contests/events on the platform
3. Data sharing of suspicious betting patterns
4. Revenue share to the league ("integrity fee")

**Who demands them**:
- NBA, MLB, NHL, PGA Tour — most aggressive on data/integrity requirements
- NFL — less aggressive; more focused on protecting brand
- NCAA — has sought prohibitions on college sports betting markets
- MLS, WNBA — following NBA lead

---

## Legislative History

### Pre-PASPA Era (Before 2018)
- PASPA (Professional and Amateur Sports Protection Act) prohibited most sports betting nationwide
- No integrity agreements needed because market was largely illegal

### Post-Murphy v. NCAA (2018) — PASPA Struck Down
- **Murphy v. NCAA, 584 U.S. 453 (2018)**: PASPA unconstitutional (anti-commandeering doctrine)
- States can now legalize sports betting
- Leagues immediately pivoted from opposing legalization to demanding integrity agreements + data mandates

### State-Level Integrity Fee Battles (2018–2022)
- Leagues sought 0.25–1% integrity fee on all sports betting handle
- Most states rejected mandatory integrity fees
- Some states adopted "official data" requirements (must use league-approved data for in-play betting)
- Iowa: Iowa Code § 99F sports betting provisions — no mandatory integrity fee; optional official data use

### CFTC and Sports Event Contracts (2024–2025)
- After Kalshi victory on political event contracts, platforms filed for sports event contracts
- NFL, NBA, MLB, NHL, MLB filed emergency petitions to CFTC asking for sports event contract prohibition
- CFTC proposed rule in September 2024: Would prohibit sports event contracts on most major US sports
- Trump administration CFTC (2025): May be more favorable to prediction markets; sports contract rule status uncertain
- **As of Q1 2026**: Sports event contracts on CFTC platforms remain in legal limbo

---

## Relevant Statutes and Regulations

### Federal
- **CEA § 5c(c)(5)(C)**: CFTC authority over event contracts; sports events potentially prohibited under "gaming" carve-out
- **CFTC Proposed Rule on Sports Event Contracts** (Sept 2024): Would prohibit most sports prediction contracts on DCMs — check current status before any sports product

### State (Iowa)
- **Iowa Code § 99F.7A**: Iowa sports wagering — legal under Iowa Racing and Gaming Commission
- Iowa sports betting requires IRGC license; commercial sports books operate under IRGC approval
- Iowa does NOT require official data use (optional; some operators use it)
- Iowa does NOT mandate integrity fee payments to leagues
- Iowa AG has not taken action requiring integrity agreements for non-licensed prediction markets

---

## Integrity Agreement Components (When Required)

If a platform does decide to offer sports event contracts or sports prediction markets, integrity agreements typically contain:

### 1. Official Data License
- Platform must use league-provided official data for settlement of in-play/live markets
- Official data providers: Sportradar (NFL, NBA, NHL), Stats Perform (MLB), Genius Sports (NFL alternate)
- Cost: $50K–$500K+/year depending on sports and tier
- Iowa DFS operators: Official data use is optional; commercial sportsbooks negotiate separately

### 2. Suspicious Activity Reporting (SAR for Sports)
- Platform must report unusual betting patterns to league within defined timeframe
- Threshold usually: significant deviations from historical patterns on specific events
- INTEGRITY hotline numbers for each league
- Platform must cooperate with league investigations

### 3. Revenue Share / Royalty
- Most states did not mandate this; leagues negotiate commercially
- Range: 0.1–0.25% of handle where agreed
- Most major US platforms pay zero integrity fee (leagues lost this fight legislatively)

### 4. Brand and Trademark License
- Use of league marks, player names, team names in markets
- Critical for fantasy-sports-style products
- Not needed for prediction markets that only use event names (not player names/images)

### 5. Geographic Restrictions
- Cannot offer markets in jurisdictions where league prohibits or regulations are unclear
- NCAA: Most aggressive — often seeks prohibition on college player markets

---

## Application to Agent Arena / Bouts

### Current Product (AI Coding Competitions)
**Integrity agreements needed**: ❌ No
- No sports events involved
- AI agent performance ≠ sports event
- No league data needed for settlement
- **Conclusion**: Sports/event integrity agreements not applicable to current product

### Future Product Consideration: Sports Prediction Layer
If Agent Arena ever wants to add sports prediction markets:
- Must navigate CFTC proposed rule on sports event contracts (check current status)
- May need: Iowa Code § 99F sports wagering license (if classifiable as sports betting)
- Integrity agreements: Negotiable; Iowa doesn't mandate; commercial decision
- **Risk level would jump to 🔴 High** — require separate legal analysis at that time

### Tangentially Related: AI Agent Sports Prediction
If Bouts hosts AI agents that predict sports outcomes:
- The CONTEST itself (AI predicts sports outcome) = skill game
- WAGERING on which AI agent predicts best = prediction market on AI performance
- Still two-layer structure; sports integrity agreements apply to the underlying sports data use, not the AI competition meta-layer
- **Nuanced**: Would need sports data license even if framed as "AI competition" if using official sports data as inputs

---

## Competitive Intelligence

### Who Has Integrity Agreements
- **DraftKings**: Full integrity agreements with NFL, NBA, MLB, NHL, MLS
- **FanDuel**: Same; extensive league data partnerships
- **Kalshi**: Has NOT offered sports event contracts pending CFTC resolution
- **PredictIt**: Political markets only; no sports; no integrity agreements needed
- **Sporttrade**: CFTC-registered DCM focused on sports; has integrity agreements

### The CFTC Sports Contract Decision
**Critical pending issue**: CFTC's proposed rule on sports event contracts (September 2024) would:
- Prohibit DCMs from listing contracts on most major US sports
- If finalized: Kalshi, Sporttrade, others cannot offer sports prediction markets
- **Under Trump CFTC (2025+)**: Rule may be withdrawn; sports contracts may be permitted
- **Monitor**: CFTC docket for sports event contract rulemaking before any sports product

---

## Conclusion for Agent Arena

1. ✅ Sports/event integrity agreements are **not required** for current AI coding competition product
2. ✅ Revisit if adding sports prediction markets or using official sports data as AI contest inputs
3. ✅ Monitor CFTC sports event contract rulemaking for future sports product planning
4. ✅ Iowa does not mandate integrity agreements or official data use; favorable jurisdiction for sports products if ever pursued

---

## Key Resources
- CFTC Sports Event Contract Proposed Rule: CFTC RIN 3038-AF24
- Iowa Code § 99F.7A: Sports wagering in Iowa
- Murphy v. NCAA, 584 U.S. 453 (2018) — PASPA struck down
- Sportradar integrity services: https://sportradar.com/integrity-services
- IRGC sports wagering licenses: https://irgc.iowa.gov

---

## Iowa Angle
- Iowa was an early sports betting legalizer (2019); IRGC has mature framework
- Iowa does NOT mandate integrity fees (leagues lost this fight in Iowa legislature)
- Iowa's DFS statute (§ 99E) + sports betting statute (§ 99F) together create a favorable skill-game / sports prediction framework
- Iowa IRGC: Proactive regulator; early engagement recommended if sports products ever pursued

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
