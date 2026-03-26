# SKILL: Regulatory Strategy Playbook — Nick's Products
**Version:** 1.0.0 | **Domain:** Product Launch Strategy, Regulatory Sequencing, Compliance Roadmap

---

## The Master Framework

Every product goes through four regulatory gates before launch:

1. **Classification gate:** What is this, legally? (Gambling? Securities? Money transmission? None of the above?)
2. **Jurisdiction gate:** Which states/countries can we legally serve on Day 1?
3. **Licensing gate:** What registrations/licenses are required before serving any paying users?
4. **Documentation gate:** What legal documents must exist before launch?

If you can't pass all four gates with confidence, you don't launch that version of the product. You revise the design until you can.

---

## AGENT SPARTA / BOUTS — Skill-Based Competition

### Legal Risk Rating: 🟢 LOW (with compliance)

### Classification Analysis
- **What it is:** AI agents compete on defined tasks (coding challenges, research tasks). Outcomes determined by agent capability and the human's skill in selecting/configuring agents.
- **Applicable law:** Iowa Code §99B.5 (contests of skill); DFS-model common law in ~40 states
- **What it is NOT:** A prediction market (no bet on future real-world events); a lottery (skill predominates, not chance); a security (no investment, no expectation of profits from others' efforts)
- **Critical design requirement:** The outcome must be MEASURABLY skill-determined. You need an objective scoring rubric that demonstrates skill predominance. This is your legal defense in any state action.

### Jurisdiction Gate (Day 1 — ABSOLUTE GEO-BLOCKS)
| State | Block? | Why | Statute |
|---|---|---|---|
| Washington | ✅ YES — MANDATORY | Class C felony | RCW 9.46.0237 |
| Arizona | ✅ YES | Requires state licensing first | A.R.S. §13-3301 |
| Louisiana | ✅ YES | Prohibited outside licensed venues | La. R.S. 14:90 |
| Montana | ✅ YES | Limited skill game authorization | MCA §23-5-802 |
| Iowa | ⚠️ DIA FIRST | Register with Iowa DIA; §99B.5(2) requires registration if prize >$500 | Iowa Code §99B.5 |
| Connecticut | ⚠️ CONSULT | Gray area; DFS operators have varying success | CGS §53-278a |
| Tennessee | ⚠️ CONSULT | Sports betting legal; skill games statute unsettled | TCA §39-17-501 |

**All other states (~43):** Legal with standard compliance (age verification, responsible gaming, TOS)

### Licensing Gate — Action Items Before Accepting Entry Fees
1. **Iowa DIA registration** (if offering in Iowa, prizes >$500 per contest):
   - Iowa Department of Inspections and Appeals, Lucas State Office Building, 321 E. 12th St., Des Moines, IA 50319
   - Fee: TBD (contact DIA for current fee schedule)
   - Timeline: 2-4 weeks

2. **Written legal opinion** from gaming attorney confirming skill-based classification:
   - Specifically address Iowa Code §99B.5 and the multi-state skill game analysis
   - Cost: $10K-$25K
   - This opinion is also your AML/criminal defense document

3. **FinCEN MSB registration** (if using custodial payment architecture):
   - Free; file Form 107 at bsaefiling.fincen.treas.gov
   - Or: use non-custodial USDC smart contract architecture → no MSB registration needed

4. **State DFS registrations** where required:
   - New York: must register with NYSDFS and meet requirements under Racing, Pari-Mutuel Wagering and Breeding Law §1400-1420
   - Tennessee: registration under ITMA (though applicability to AI competitions is uncertain)
   - Consult gaming counsel for current state registration list

### Documentation Gate — Before Launch
- [ ] Terms of Service with: arbitration clause, class action waiver, geographic restrictions, skill-based competition disclosure, risk disclosures, age representation
- [ ] Privacy Policy: Iowa ICDPA compliant, GDPR compliant (if EU users), CCPA compliant (if CA users)
- [ ] Responsible Participation disclosures: self-exclusion, deposit limits, NCPG hotline (1-800-522-4700)
- [ ] Age verification: 18+ minimum; technical implementation before any account creation
- [ ] Geo-blocking: IP-level blocking for prohibited states (not just TOS prohibition)
- [ ] KYC: if custodial payments; 1099 collection workflow for US winners >$600/year

### Revenue Model (Compliant)
- Entry fees (10-15% rake): compliant as operator margin in skill competitions
- Subscription to premium analytics: zero regulatory issues
- Data licensing (AI lab calibration): zero regulatory issues
- Advertising: zero regulatory issues

---

## AI vs. HUMAN PREDICTION MARKET

### Legal Risk Rating: Varies by Phase (🟢 → 🟡 → 🔴)

### PHASE 1: Free-to-Play — 🟢 ZERO LEGAL RISK

**Launch this NOW. No legal blockers.**

**Structure:**
- Iowa LLC (file at wyobiz.sos.iowa.gov — $50, same day)
- Platform: users evaluate AI model predictions; earn reputation points, badges, leaderboard rankings
- No real money wagering whatsoever
- Revenue: data licensing to AI labs (they need this calibration data), analytics subscriptions, advertising

**Documentation Gate for Phase 1:**
- [ ] Standard Terms of Service (no gambling provisions needed)
- [ ] Privacy Policy (collect user behavior data; comply with ICDPA)
- [ ] Data licensing agreement template (for AI lab customers)
- [ ] Subscription terms (for analytics product)

**Why this matters strategically:**
- Build 6-12 months of user behavior data
- Establish the "research" framing BEFORE any money is involved
- Create a track record that supports a CFTC no-action letter application (Iowa Electronic Markets analog)
- Build the user base that Phase 2 monetizes

**Iowa Electronic Markets angle:** Contact the University of Iowa Tippie College of Business (Iowa Electronic Markets team) about a research partnership. An academic affiliation for the AI calibration research → strongest possible foundation for a CFTC no-action letter application.

---

### PHASE 2: Entry-Fee Competitions (DFS Model) — 🟡 LOW-MEDIUM RISK

**Launch 3-6 months after Phase 1; requires legal opinion and compliance setup**

**Structure:**
- Season-long AI model portfolio contests (NOT binary yes/no bets on single events)
- Entry fees in USDC via non-custodial smart contracts
- Prizes distributed directly from smart contract to winner wallets
- US-focused with geo-blocks

**Critical legal opinion needed:**
- "Is selecting and scoring AI model prediction accuracy a skill-based activity under [state law]?"
- This is NOVEL — no court has ruled on this exact question
- The legal opinion must analogize to DFS (DraftKings/FanDuel): "selecting which AI models will be most accurate is as skill-based as selecting which athletes will perform best"
- Engage gaming counsel with DFS experience: Jon Kessler (ex-FanDuel legal), Ifrah Law, or gaming-specialized firms

**Jurisdiction gate for Phase 2:**
- Same geo-blocks as Agent Sparta PLUS: more conservative state list (prediction market connotations are harder to defend than pure skill competition)
- Iowa: DIA registration required if prizes >$500

**Budget:** $25K-$50K for legal opinions + state registrations + compliance infrastructure

**Non-custodial USDC architecture (mandatory):**
```
User wallet → smart contract (entry fee escrow) → winner wallet
Platform never touches funds
```
- Avoids FinCEN MSB registration
- Avoids state MTL requirements
- Protects users in event of platform insolvency (funds in smart contract, not platform)

---

### PHASE 3: Full Prediction Market — 🔴 HIGH RISK (Do Not Launch Without $1M+ Legal Budget)

**Two paths — CFTC registration or offshore**

**Path A: Kalshi Model (Full US Regulation)**
- Register as CFTC Designated Contract Market
- Engage: Willkie Farr & Gallagher, K&L Gates, or Sullivan & Cromwell (all have CFTC regulatory practices)
- Budget: $1-5M in legal fees, 12-18 months
- Timeline: 18+ months from engagement to first US users
- Ongoing: compliance team, surveillance, CFTC reporting, $500K+/year in compliance costs
- **Trigger:** Only pursue when Phase 2 is generating $1M+/year in revenue and you have institutional investor backing

**Path B: Offshore (Polymarket Model)**
- Form Cayman operating entity (Cayman Islands Monetary Authority registration)
- US entity: marketing/tech only — NO financial operations
- Geo-block US users at IP level + TOS prohibition
- Accept: some US VPN users will access; TOS prohibits it; enforcement risk is proportional to scale
- Budget: $50K-$150K to set up; $100K-$200K/year in ongoing compliance
- **Risk:** $1.4M fine is the baseline (Polymarket); larger operations face larger fines. This is a business decision about cost of doing business.

**Trigger for Phase 3:** $500K+ in Phase 2 revenue AND clear product-market fit AND either investor backing or cash to fund legal budget.

---

## TOKEN LAUNCH (IF EVER)

### Legal Risk Rating: 🔴 HIGH (if not done correctly) → 🟢 LOW (if structured properly)

### The Decision Tree
```
Does the token have:
├── Secondary market trading? → Likely a security if other prongs met
├── Profit expectations communicated by team? → Almost certainly a security
├── Financial rights (fee distributions, yields)? → Strong securities argument
└── ONLY utility (pay platform fees, no other rights)? → Weaker securities argument
```

**Nick's safest path:**
1. **Build first, token later** — Product with genuine utility must exist before any token
2. **Never sell tokens to US persons** — Distribute only via usage rewards and airdrops
3. **Governance only** — No financial rights in the token (no fee distribution, no staking yields)
4. **Engage securities counsel** for a Howey analysis memo before ANY public token communication
5. **Get Reg D in place** if any investor wants tokens (accredited investors only)

### SAFT Structure (if raising capital with token promise)
- Simple Agreement for Future Tokens: sell investment contract to accredited investors now
- Deliver utility tokens when the network is live
- Reg D 506(c) exemption (allows general solicitation if all buyers verified as accredited)
- Cost: $75K-$150K in legal fees for SAFT documentation
- **This is still a security sale** — just an exempt one

---

## PROACTIVE REGULATORY RELATIONSHIPS — BUILD BEFORE YOU NEED THEM

### Iowa (Priority 1 — Home Jurisdiction)
1. **Iowa DIA:** Call before registering skill contests. Introduce the product, ask for guidance. This builds goodwill.
2. **Iowa Racing and Gaming Commission:** Not your primary regulator for skill games, but know who they are. If IRGC ever asserts jurisdiction over AI competitions, you want to have met them already.
3. **Iowa AG Consumer Protection Division:** They enforce §714.16. A proactive call about your marketing practices builds goodwill.
4. **Iowa Division of Banking:** If you ever get to custodial payments, you need an MTL. Know the process now.

### Federal (Priority 2 — Long Game)
1. **CFTC LabCFTC:** Email within 3 months of Phase 1 launch. Present your concept. Get on their radar as a cooperative company.
2. **University of Iowa IEM Partnership:** Explore this before approaching CFTC for a no-action letter. Academic partnership is the PredictIt blueprint.
3. **SEC FinHub:** Only when/if you're considering a token. Meet them before any public token discussion.

---

## COMPLIANCE CALENDAR

| Milestone | Regulatory Action | Cost | Timeline |
|---|---|---|---|
| Phase 1 launch | Form Iowa LLC, basic TOS/Privacy Policy | $500-$2K | Week 1 |
| 1,000 users | Iowa ICDPA compliance assessment | $2K-$5K | Month 2-3 |
| Phase 2 pre-launch | Gaming attorney legal opinion | $10K-$25K | Month 3-5 |
| Phase 2 pre-launch | Iowa DIA registration | $500-$2K | Month 3-5 |
| Phase 2 pre-launch | KYC/geo-blocking implementation | $5K-$15K | Month 4-5 |
| Phase 2 launch | FinCEN MSB registration (if custodial) | $0 + $5K legal | Month 5 |
| 10K users | State gaming commission registrations | $10K-$50K | Month 6-12 |
| $500K ARR | CFTC LabCFTC engagement | $5K-$20K legal | Month 9-12 |
| Phase 3 trigger | Cayman entity OR CFTC DCM engagement | $50K-$500K | Year 2+ |

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
