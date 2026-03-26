# SKILL: US Prediction Market Regulation
**Version:** 1.0.0 | **Domain:** CFTC, Gambling Law, Event Contracts

---

## Primary Regulator: CFTC

### Jurisdiction Basis
- Event contracts (binary options on future events) = "swaps" under the Commodity Exchange Act (CEA)
- Dodd-Frank Act (2010) explicitly granted CFTC jurisdiction over prediction markets
- Platform facilitating trading of event contracts must register as:
  - **Designated Contract Market (DCM)** — full exchange (Kalshi model)
  - **Swap Execution Facility (SEF)**
  - Or operate under CFTC exemption/no-action letter

### Key Statute
- CEA §5c(c)(5)(C) — "contrary to public interest" provision for event contracts
- 7 U.S.C. § 1 et seq. — Commodity Exchange Act base authority

---

## Critical Precedents

### Kalshi v. CFTC (2023-2024) — LANDMARK
- **What happened:** Kalshi sued CFTC after CFTC rejected their congressional election contracts
- **Outcome:** Court ruled in Kalshi's favor — CFTC CANNOT prohibit election event contracts under its "contrary to public interest" authority
- **Impact:** Opened the door for political prediction markets in the US under DCM registration
- **Docket:** ForecastEx LLC v. CFTC, No. 23-cv-3112 (D.D.C.)

### Polymarket Consent Order (2022)
- **What happened:** Polymarket paid $1.4M fine for operating unregistered trading facility for US persons
- **Outcome:** Polymarket moved offshore (Cayman), geo-blocked US users
- **Reality:** US users still access via VPN; platform doesn't use KYC to enforce geo-block
- **Citation:** CFTC Docket No. 22-09 (2022)

### PredictIt CFTC No-Action Letter 14-130 (2014)
- **What it allowed:** Academic prediction market with: 5,000 trader max per market, $850 max position
- **2023:** CFTC revoked the letter; PredictIt sued, got temporary stay
- **Iowa connection:** Operated for Victoria University of Wellington; Iowa Electronic Markets is the academic blueprint
- **Full text:** https://www.cftc.gov/sites/default/files/idc/groups/public/@lrlettergeneral/documents/letter/14-130.pdf

### CFTC v. Ooki DAO (2022) — CRITICAL FOR DEFI
- **What happened:** CFTC pursued enforcement against a DAO with no legal entity
- **Outcome:** CFTC won — decentralization does NOT exempt you from CFTC enforcement
- **Impact:** Smart contracts executing event contracts = operating an unregistered trading facility
- **Docket:** CFTC v. Ooki DAO, 22-cv-5416 (N.D. Cal.)

### Intrade (2013)
- Shut down after CFTC enforcement for offering off-exchange binary options to US persons
- Enforcement action: CFTC v. Trade Exchange Network, 12-cv-1902 (D.D.C.)

---

## Legal Operating Models

### The Kalshi Model (Full Regulation)
- Register as DCM with the CFTC
- **Cost:** $1-5M in legal fees, 12-18 months to approval
- **Ongoing:** Compliance team, surveillance, reporting, margin requirements
- **Benefit:** Legally clear, can serve all US customers
- **Limitation:** CFTC can still reject specific contract types (though courts limited this post-Kalshi ruling)

### The Polymarket Model (Offshore)
- Incorporate offshore (Cayman entity)
- Geo-block US users (IP blocking + TOS prohibition)
- Do NOT register with CFTC
- **Risk:** CFTC CAN still pursue enforcement (proved by $1.4M consent order)
- **Reality:** Largest prediction market in the world operates under this model; the fine was a cost of doing business

### "Not a Prediction Market" Structures

#### Structure 1: Skill-Based Competition (DFS Analog)
- Outcome determined by skill → NOT gambling in most states
- Precedent: DraftKings, FanDuel — "skill-based contests"
- For AI: agent capability determines outcome, not random chance
- **Risky states:** Arizona, Louisiana, Montana, Washington (classified as gambling regardless)

#### Structure 2: Research/Academic Tool
- Frame as calibrating AI model accuracy, not betting on events
- Iowa Electronic Markets precedent: CFTC no-action letter for academic research
- **Critical requirement:** If real money + payout based on future event → regulators pierce the framing

#### Structure 3: Free-to-Play (Zero Legal Risk)
- No consideration = no gambling under any state law
- Revenue: advertising, data licensing, premium analytics
- Users compete for leaderboard rankings or platform-funded prizes
- Lowest risk, lowest revenue ceiling; viable as Phase 1 launch

---

## State-by-State Risk

### ~40 States: Legal with compliance
### Prohibited/Restricted (~10 states):
- **Washington:** Class C FELONY for all online gambling including skill games — ALWAYS GEO-BLOCK
- **Arizona:** Requires specific licensing
- **Louisiana:** Prohibited outside licensed venues
- **Montana:** Limited
- **Iowa:** Requires licensing (important for Nick's home jurisdiction)
- **Connecticut:** Requires licensing
- **Tennessee:** Sports betting legal; skill games gray

### Required Compliance Regardless of State:
- Age verification (18+ minimum, 21+ in some jurisdictions)
- Responsible gaming disclosures
- Geo-blocking for prohibited states

---

## Post-Loper Bright Implication
*Loper Bright v. Raimondo, 603 U.S. ___ (2024) — Chevron deference overruled*
- CFTC regulatory guidance on prediction markets is now **persuasive, not binding**
- Courts must independently interpret the CEA — aggressive structures are more contestable
- This cuts BOTH ways: CFTC can't rely on deference for expansive interpretation of "swap," but neither can platforms rely on informal agency tolerance

---

## Iowa-Specific Notes
- Iowa Electronic Markets (IEM): University of Iowa has operated prediction markets under CFTC no-action letters since 1988 — the blueprint for academic exemption
- Iowa Code Ch. 725 (Gambling): Requires "consideration," "chance," and "prize" — skill games may be carved out
- Iowa requires licensing for real-money skill competitions — consult Iowa AG guidance before launching in Iowa
- Nick is Iowa-based: Iowa AG may be first regulator to take interest in any Iowa-operated prediction platform

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
