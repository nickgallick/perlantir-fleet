# SKILL: Iowa State Law — Complete Reference
**Version:** 1.0.0 | **Domain:** Iowa Gambling, Corporate, Money Transmission, Data Privacy, Tax

---

## Iowa Gambling Law

### Iowa Code Chapter 99B — Games, Amusements, and Contests

**§99B.1 — Definitions**
- "Game of skill": an activity in which the outcome is determined predominantly by the skill of the participants
- "Game of chance": an activity in which the outcome is determined predominantly by chance
- "Contest": any competition between persons for prizes or recognition

**§99B.5 — Contests of Skill — EXPLICITLY LEGAL**
- §99B.5(1): Contests of skill are lawful in Iowa
- §99B.5(2): Contests of skill may offer prizes. **Registration required with the Iowa Department of Inspections and Appeals (DIA) if prize value exceeds $500 in a single contest**
- §99B.5(3): Entry fees ARE permitted for contests of skill
- **Iowa DIA registration**: file with Iowa Department of Inspections and Appeals, Lucas State Office Building, Des Moines, IA 50319; www.dia.iowa.gov
- Iowa has NOT passed specific DFS legislation — DFS operates under §99B's general skill-game provisions

**§99B.6 — Promotional Contests**
- Businesses may conduct promotional contests without a license IF:
  - No purchase is necessary to enter (no consideration)
  - Prizes are predetermined
- Relevant if building a free-to-play marketing sweepstakes layer

**Key statutory distinction:**
- Skill → Chapter 99B (legal with registration)
- Chance → Chapter 99F (illegal without IRGC license)

---

### Iowa Code Chapter 99F — Gambling

**§99F.1(16)** — "Gambling game" means any game of chance. The definition expressly includes: slot machines, roulette, keno, and any other game where outcome is substantially determined by chance.

**§99F.3** — Iowa Racing and Gaming Commission (IRGC) regulates ALL gambling in Iowa. Commission contact: www.iowa.gov/irgc; 1300 Des Moines St., Des Moines, IA 50309.

**§99F.9** — Only licensed casinos (Class A, B, C, or D licenses) may operate gambling games. Operating an unlicensed gambling game = criminal violation.

**§99F.12** — Criminal penalties for unlicensed gambling: Class D felony (up to 5 years imprisonment, up to $7,500 fine).

**Prediction markets with chance elements:** If a prediction market outcome is substantially determined by chance → regulated as gambling under 99F. Must have IRGC license. Do NOT operate without one.

---

### Iowa Code Chapter 99G — Iowa Lottery
- §99G.1 through §99G.42: Iowa Lottery Authority operations
- Lottery = three elements: consideration + chance + prize
- **If your contest has all three → lottery → illegal unless you're the Iowa Lottery Authority**
- Remove ONE element: (a) no purchase required (no consideration), (b) skill determines outcome (no chance), or (c) no monetary prize → breaks the lottery definition

---

### Iowa Code Chapter 99E — Pari-Mutuel Wagering
- §99E.1 through §99E.32: covers horse and greyhound racing
- Pari-mutuel = pooled bets, odds determined by relative amount bet on each outcome
- **Not directly applicable to AI competitions or prediction markets**
- However: regulators may try to analogize a prediction market to pari-mutuel wagering (pooled bets on outcomes). Study the structure to anticipate and rebut this argument.

---

### Iowa Sports Betting (Added 2019 — SF 617)
- Iowa legalized sports betting via Senate File 617 (2019), amending Chapter 99F
- **§99F.4D** — Sports wagering authorized at licensed casinos and via mobile apps
- **§99F.4D(2)** — License required from IRGC (only entities affiliated with a licensed casino may receive this license)
- **§99F.4D(8)** — "Sporting event" defined as professional or collegiate athletic events
  - **Does NOT include:** prediction markets, AI competitions, esports (as of current statute)
- Mobile sports betting: geo-fenced to Iowa's borders. Operators must verify user is physically in Iowa.
- **Implication:** Iowa's sports betting law is narrowly written. AI competitions and prediction markets don't fall under it — they fall under 99B (skill) or 99F (chance).

---

## Iowa Money Transmission Law

### Iowa Code Chapter 533C — Iowa Uniform Money Services Act

**§533C.102 — Definitions**
- "Money transmission" means: (i) selling or issuing payment instruments, (ii) selling or issuing stored value, or (iii) **receiving money or monetary value for transmission**
- Broad definition — accepting funds from users and distributing them to winners likely qualifies

**§533C.201 — License Required**
- Any person engaged in money transmission in Iowa must hold a license issued by the Iowa Superintendent of Banking
- Iowa Division of Banking: www.idob.iowa.gov; 200 E. Grand Ave., Suite 300, Des Moines, IA 50309

**§533C.202 — License Application Requirements**
- Surety bond: minimum $100,000 (Superintendent may require up to $500,000)
- Financial statements: audited or reviewed by CPA
- Background check: all principals and key individuals
- Business plan: describe money transmission activities
- Filing fee: $1,000 application fee

**§533C.301 — Exemptions**
- §533C.301(1): Banks, trust companies, savings associations — exempt
- §533C.301(2): Credit unions — exempt
- §533C.301(3): Agents of licensed money transmitters acting within scope of agency agreement — exempt (use this for payment processor partnerships)
- §533C.301(7): "A person that provides clearance or settlement services pursuant to a registration or exemption under federal securities law" — potentially relevant for certain crypto structures

**Crypto/non-custodial question in Iowa:**
- Iowa has NOT issued specific guidance on crypto-to-crypto transmission
- Iowa follows FinCEN federal guidance as a baseline
- Non-custodial platforms (user wallet → smart contract → user wallet, platform never controls funds): strongest argument for exemption from Iowa MTL
- This argument is NOT tested in Iowa courts — get an Iowa-specific legal opinion before relying on it

---

## Iowa Corporate Law

### Iowa Code Chapter 489 — Iowa Revised Uniform LLC Act

**Formation:**
- File Certificate of Organization with Iowa Secretary of State
- Fee: $50 (online filing)
- Filing: www.sos.iowa.gov
- Effective: upon filing (same day for online)

**Operating Agreement:**
- Not required to be filed, but MUST exist for proper governance
- Multi-member LLCs: always have a written operating agreement
- Single-member: still advisable for liability protection purposes

**Series LLC:**
- Iowa does NOT authorize series LLCs
- If you need series LLC structure (separate liability cells): use Delaware LLC or consider Nevada

**Annual Report:**
- Due: April 1 each year
- Fee: $60 for LLCs, $45 for corporations
- File with Iowa Secretary of State

**Iowa Corporate Income Tax:**
- Current rate (2026): **5.5% flat rate** (Iowa significantly reformed its corporate tax structure, reducing from graduated rates of up to 9.8%)
- Source: Iowa Code §422.33

**Iowa Individual Income Tax:**
- Current rate (2026): **3.8% flat rate** (reduced from prior graduated rates under Iowa's multi-year tax reform)
- Pass-through LLC income: taxed at Nick's individual rate
- Source: Iowa Code §422.5

**Note:** Iowa has no state-level capital gains preference — capital gains taxed as ordinary income at individual rates.

---

## Iowa Consumer Protection

### Iowa Code Chapter 714 — Fraud and Deception

**§714.16 — Iowa Consumer Fraud Act**
- Prohibits: "unfair practice, deception, fraud, false pretense, false promise, or misrepresentation, or the concealment, suppression, or omission of any material fact"
- Applies to: all consumer transactions, including digital products and platform services
- Enforcement: Iowa Attorney General has authority to investigate and sue; civil penalties up to $40,000 per violation
- Private right of action: YES — consumers can sue individually (unlike ICDPA)
- All marketing materials, TOS, pricing disclosures must comply

---

## Iowa Data Privacy

### Iowa Code Chapter 715D — Iowa Consumer Data Protection Act (ICDPA)
**Effective: January 1, 2025**

**Threshold — Applies if:**
- Controls/processes personal data of **100,000+ Iowa consumers** annually, OR
- Controls/processes personal data of **25,000+ consumers** AND derives **more than 50% of gross revenue from sale of personal data**

**Consumer Rights:**
- Right to access personal data
- Right to deletion
- Right to data portability
- Right to opt out of: targeted advertising, sale of personal data, profiling for significant decisions

**No private right of action** — Iowa AG enforcement only. AG may bring civil action; no individual lawsuits under ICDPA.

**For Nick's platforms:** If prediction market reaches 100K Iowa users, full ICDPA compliance required. Build data governance infrastructure early — it's much harder to retrofit.

---

## Iowa-Specific Regulatory Recommendations

| Action | Authority | Timing |
|---|---|---|
| Form Iowa LLC for operating entity | Iowa SOS (§489) | Before launch |
| Register skill contests with DIA (if prize >$500) | Iowa DIA (§99B.5(2)) | Before first paid contest |
| Confirm skill-based classification with Iowa gaming attorney | Iowa Code §99B | Before launch |
| Iowa MTL application (if custodial) | Iowa Division of Banking (§533C.201) | 3-6 months before launch |
| ICDPA compliance assessment | Iowa Code §715D | Before 100K users |
| Iowa AG consumer protection review of marketing | Iowa Code §714.16 | Before any advertising |

**Iowa AG contact for voluntary compliance inquiries:** www.iowaattorneygeneral.gov/for-consumers

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
