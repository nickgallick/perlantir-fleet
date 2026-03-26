# SKILL: Responsible Gaming Program

## Purpose
Design and implement responsible gaming (RG) programs for prediction market and skill-game platforms. Covers regulatory requirements, industry standards, product design mandates, and enforcement posture.

## Risk Level
🟡 Medium — Required for any platform involving wagering mechanics. Regulators and payment processors increasingly mandate RG programs as table stakes for legitimacy. Absence of a program is a red flag in enforcement actions.

---

## Core Legal Framework

### Federal Requirements
- No single federal responsible gaming statute for prediction markets
- **Unlawful Internet Gambling Enforcement Act (UIGEA)** (31 U.S.C. §§ 5361–5367): Does not require RG programs but interacts — legitimate skill game exemptions look better with RG infrastructure
- **FTC Act § 5**: Deceptive/unfair practices — marketing to vulnerable populations without RG protections can trigger FTC scrutiny
- **CFPB**: Monitoring fintech for predatory practices including addictive product design

### State Requirements (Key States)
- **New Jersey** (N.J.A.C. 13:69O): Most detailed online gaming RG requirements in US; DFS operators must comply with self-exclusion registry
- **Michigan** (MGCB Rules)**: Mandatory self-exclusion, responsible gaming plans required for iGaming licensees
- **Iowa** (Iowa Code Ch. 99F): Iowa Racing and Gaming Commission mandates self-exclusion for licensed gaming; does NOT explicitly cover prediction markets but is the reference framework
- **Pennsylvania**: Mandatory $100 annual deposit limit notices, self-exclusion integration
- **Colorado, Indiana, Tennessee**: DFS-specific RG requirements in their DFS statutes

### Industry Standards (Non-Binding but Influential)
- **National Council on Problem Gambling (NCPG)** iCEPS certification — increasingly expected by payment processors and institutional partners
- **Responsible Gambling Council** standards
- **GamCare** (UK-based, but relevant for international)
- **RG Check Accreditation** — industry certification program

---

## Core Program Components

### 1. Self-Exclusion
**What it is**: Users voluntarily ban themselves from the platform.
**Legal requirement**: Mandatory in licensed gaming states; best practice for unlicensed prediction markets
**Implementation**:
- Self-exclusion form accessible without logging in
- Minimum exclusion periods: 1 year, 5 years, lifetime
- Link to state self-exclusion registries (NJ, MI, IA, etc.)
- Must honor other states' self-exclusion lists if operating in those states
- No marketing to self-excluded users — EVER

### 2. Deposit Limits
**What it is**: Users set daily/weekly/monthly deposit caps
**Legal requirement**: Required in most licensed jurisdictions; best practice elsewhere
**Implementation**:
- Limits take effect immediately
- Increases require 72-hour cooling-off period (best practice; legally required in some jurisdictions)
- Decreases take effect immediately
- Cannot be overridden by promotional offers

### 3. Reality Checks / Session Limits
**What it is**: Notifications of time and money spent
**Legal requirement**: Required in UK, best practice in US
**Implementation**:
- Configurable intervals (30 min, 1 hour, etc.)
- Show: time on platform, amount wagered, net P&L for session
- Mandatory "take a break" prompt after extended sessions

### 4. Cool-Down / Time-Out Periods
**What it is**: Temporary break from platform (1 day to 6 weeks)
**Legal requirement**: Best practice; some states require
**Implementation**:
- Accessible from account settings
- During timeout: no wagering, no deposits, can still withdraw
- Cannot be cancelled once set

### 5. Age Verification
**What it is**: Confirm users are 18+ (or 21+ where required)
**Legal requirement**: UIGEA compliance; state-specific; COPPA (no under-13 data collection)
**Implementation**:
- At minimum: DOB attestation with T&C agreement
- Better: ID verification via Jumio, Persona, or similar KYC provider
- Credit card billing address verification as secondary check
- Iowa requires 18+ for most gaming activities

### 6. Problem Gambling Resources
**What it is**: Links and information for users showing signs of problem gambling
**Legal requirement**: Required in licensed states; best practice always
**Implementation**:
- Footer on all wagering pages: "If you or someone you know has a gambling problem, call 1-800-GAMBLER"
- 1-800-522-4700 (NCPG hotline)
- Iowa specific: 1-800-BETSOFF (Iowa's problem gambling helpline)
- Link to NCPG resources

### 7. Responsible Gaming Policy (Published)
**What it is**: Public-facing document describing all RG tools and commitments
**Legal requirement**: Required in licensed jurisdictions; best practice
**Must include**: Self-exclusion process, deposit limit mechanics, contact for problem gambling, how to close account, data retention after exclusion

---

## Payment Processor Requirements
Payment processors increasingly require RG programs:
- **Visa/Mastercard**: Merchant code (MCC) determines scrutiny level; high-risk MCCs require demonstrated RG compliance
- **PaySafe, Nuvei, PaymentCloud**: RG program documentation required for account approval
- **Stripe**: Will terminate accounts for gambling-adjacent products without proper licensing + RG documentation

**Practical**: Having a documented, implemented RG program significantly improves payment processing approval odds for prediction market / skill-game platforms.

---

## Iowa-Specific Analysis
- Iowa Code § 99F.17: Iowa problem gambling treatment fund — funded by gaming tax revenue
- Iowa Gambling Treatment Program: State-run; requires awareness promotion
- **Iowa connection for prediction markets**: Not legally required to comply with IRGC rules if not a licensed gaming operator, but voluntarily adopting RG standards demonstrates good faith and aligns with PredictIt's approach (academic/nonprofit framing + user protections)
- Iowa Electronic Markets has no wagering — avoids RG requirement entirely; Agent Arena/Bouts may need to decide whether to follow IEM model or PredictIt model

---

## Minimum Viable RG Program (Pre-Launch)
For a prediction market / skill-game platform not seeking full gaming licensure:

1. ✅ Self-exclusion with minimum 1-year option
2. ✅ Deposit limits (user-set, immediately effective)
3. ✅ Problem gambling resources on every wagering page
4. ✅ 1-800-GAMBLER and 1-800-BETSOFF displayed prominently
5. ✅ Age verification (18+) at registration
6. ✅ Published Responsible Gaming Policy page
7. ✅ Account closure on demand (no friction)

**Optional but high-value**:
- NCPG iCEPS certification (legitimacy signal)
- Integration with state self-exclusion registries
- Automated risk-score triggers for intervention

---

## Red Flags That Attract Regulatory Attention
- No self-exclusion mechanism
- Promotional bonuses with no RG messaging
- Marketing to users who have shown problem gambling indicators
- No age verification
- Resistance to account closure requests
- Bonus structures that encourage chasing losses

---

## Competitive Intelligence
- **Kalshi**: Has RG page, 1-800-GAMBLER link, self-exclusion form
- **PredictIt**: Limited RG program (academic framing reduces scrutiny)
- **Polymarket**: Crypto-native; minimal RG (offshore/non-US focus)
- **DraftKings**: Full state-by-state RG compliance as licensed DFS/sportsbook operator
- **Standard to beat**: DraftKings-level RG signals legitimacy to regulators and payment processors

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
