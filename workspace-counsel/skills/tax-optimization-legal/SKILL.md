# SKILL: Legal Tax Optimization for Crypto Companies
**Version:** 1.0.0 | **Domain:** Entity Structure, QSBS, CFC Rules, Crypto Tax Planning

---

## Entity Structure for Tax Efficiency

### Option 1: Single Iowa LLC (Current Simple Path)
**Tax treatment:** Pass-through entity — all profits taxed on Nick's personal return

- Iowa individual income tax: **3.8% flat** (Iowa Code §422.5, effective 2026)
- Federal income tax: ordinary income rates up to **37%** (26 U.S.C. § 1)
- Self-employment tax: **15.3%** on first ~$176,100 (2026 FICA threshold); 2.9% above that
- Combined effective rate on $500K of LLC profit: ~55% all-in (federal + Iowa + SE tax)
- **Mitigation:** S-Corp election to reduce SE tax on earnings above "reasonable compensation"
  - Iowa LLC + S-Corp election (Form 2553): pay Nick a "reasonable salary" as W-2; remaining profits distributed as S-Corp distributions (NOT subject to SE tax)
  - Example: $500K profit → $150K salary (SE tax on $150K) + $350K distribution (no SE tax) → save ~$45K in SE tax
  - Risk: IRS scrutinizes low salaries in S-Corps; "reasonable compensation" standard
- Compliance cost: $1K-$5K/year (simple pass-through)

### Option 2: Iowa LLC + Delaware Holding Company
**Structure:**
- Iowa LLC: operating company (customer-facing, employs people, runs platform)
- Delaware LLC or C-Corp: holding company owns intellectual property (platform code, brand, AI models)
- Holding company licenses IP to Iowa LLC via arm's-length royalty agreement
- Royalty payments: reduce Iowa LLC's taxable income; accumulate in Delaware entity

**Tax benefit:**
- Delaware has no income tax on royalties received from out-of-state entities ("Delaware holding company" strategy)
- Iowa taxable income reduced by royalty payments
- Holding company's Delaware income: Delaware doesn't tax passive holding income

**IRS scrutiny:**
- Transfer pricing must be at arm's length (26 U.S.C. § 482)
- Document: comparable uncontrolled royalty rates, business purpose for the structure
- If IRS recharacterizes: back taxes, penalties, interest
- **Get a transfer pricing study** from a qualified CPA before implementing this

**Compliance cost:** $10K-$25K/year (two entities, transfer pricing documentation)

### Option 3: Delaware C-Corporation (When to Use)

**When you MUST use a C-Corp:**
- Raising venture capital from institutional investors (they expect C-Corp; LLCs cause tax complications for tax-exempt investors like university endowments)
- Planning to issue Qualified Small Business Stock (§1202 — see below)
- Issuing traditional ISO stock options to employees
- Planning an eventual IPO

**Tax tradeoff:**
- C-Corp pays: 21% federal corporate income tax + Iowa 5.5% = ~26.5% at entity level
- Dividends to shareholders: taxed again at 20% + 3.8% NIIT + Iowa 3.8% = ~28% at individual level
- Total "double taxation" rate: ~26.5% + (28% of remaining 73.5%) = ~47% all-in
- **BUT:** Retained earnings inside a C-Corp are only taxed once until distributed. Growth inside the corporation compounds at lower rates. Useful if you're reinvesting profits.

---

## Qualified Small Business Stock (QSBS) — Section 1202
**Authority:** 26 U.S.C. § 1202

### The Biggest Tax Break in Tech
- **Exclusion:** Up to **$10 million** (or 10x your basis) in capital gains excluded from federal income tax when you sell qualified small business stock
- Effective capital gains rate on qualifying gains: **0% federal** (still subject to state tax — Iowa doesn't have QSBS preference)
- Example: You sell shares in your C-Corp for $12M after holding for 5 years; your basis was $100K: $10M excluded = ~$2.4M in federal tax saved

### Requirements (ALL must be met):
1. **C-Corporation only** — NOT an LLC, NOT an S-Corp, NOT a partnership
2. **Active business:** The corporation must be in an "active trade or business" in a qualified sector (technology, software, and AI are qualified; financial services, investing, and professional services are NOT)
3. **Gross assets ≤ $50 million** at the time of issuance (and immediately after) — this is the startup window
4. **Original issuance:** Stock must be acquired by the taxpayer directly from the corporation, not in secondary market
5. **Holding period:** Stock must be held for **more than 5 years**
6. **Qualified taxpayer:** Individual or pass-through entity (trusts and corporations cannot claim §1202 exclusion)

### QSBS for Agent Sparta / AI Prediction Market:
- If Nick forms a Delaware C-Corp for the operating entity and issues himself founder shares at incorporation: the 5-year clock starts NOW
- If the business grows and Nick sells in year 5+: potentially $10M of gain is tax-free at the federal level
- **Stack the exclusion:** Nick's spouse, children, and certain trusts can EACH claim up to $10M exclusion if stock is properly gifted before sale = family exclusions stack
- **CRITICAL:** Convert to C-Corp early. The 5-year clock starts at stock issuance. Waiting costs money.

### Iowa QSBS:
- Iowa does NOT have a QSBS exclusion at the state level
- Capital gains from QSBS stock sale: taxable in Iowa at ordinary income rates (3.8% flat)
- State tax cost is relatively low compared to the federal savings

---

## Controlled Foreign Corporation (CFC) Rules — Offshore Entity Tax Reality

**Authority:** 26 U.S.C. §§ 951-965 (Subpart F); 26 U.S.C. § 951A (GILTI)

### The Key Rule
If Nick owns ≥ 10% of a foreign corporation → he is a "U.S. shareholder" → Subpart F and GILTI rules apply.

**Subpart F income:** Certain "passive" income of the CFC (royalties, interest, dividends, some services income) is included in Nick's US taxable income in the year EARNED by the CFC — even if no dividend is paid to Nick.

**GILTI (Global Intangible Low-Taxed Income, § 951A):** Taxes the CFC's "excess returns" (income above 10% of the CFC's tangible assets). Almost all software/IP income in a foreign subsidiary will be GILTI.

### Practical Conclusion for Nick
**An offshore Cayman entity does NOT save US taxes for a US person who controls it.** The income is taxed in the US regardless of where it's earned, under Subpart F/GILTI.

**Legitimate reasons to have an offshore entity (not tax avoidance):**
- Serving non-US users from a non-US entity (operational and regulatory reasons)
- Holding non-US IP that generates genuine non-US revenue
- Separating liability for non-US operations
- Accessing global capital markets

**What actually reduces taxes:**
- §1202 QSBS exclusion (on exit)
- S-Corp election to reduce SE taxes (on ongoing income)
- Timing of income recognition (defer where possible)
- Qualified Business Income (QBI) deduction — §199A: pass-through entities may deduct up to 20% of qualified business income (limitations apply; check with CPA)

---

## Crypto-Specific Tax Planning

### Lot Identification and Cost Basis
- **Specific Identification Method (recommended):** Identify exactly which lots of crypto you're selling → choose lots with highest basis → minimize gain
- **FIFO:** First in, first out — often results in larger gains (you're selling older, lower-basis crypto)
- **LIFO:** Last in, first out — results in smaller gains if prices rose; NOW **DISALLOWED for crypto** under Infrastructure Investment and Jobs Act (2021) → IRS guidance pending; consult CPA

### Wash Sale Rules (Crypto)
- **Infrastructure Investment and Jobs Act (2021) + IRS guidance:** Wash sale rules (26 U.S.C. § 1091) NOW APPLY to crypto (effective 2025 per final IRS guidance)
- Rule: if you sell crypto at a loss and buy substantially identical crypto within 30 days (before or after) → loss is DISALLOWED
- Previously: crypto's wash sale exemption was a major planning opportunity. That window is now closed.

### Staking Rewards
- **IRS Revenue Ruling 2023-14:** Staking rewards are ordinary income when received, valued at fair market value
- Applicable to: Ethereum staking, Solana staking, DeFi liquidity provision
- Subsequent sale: capital gain/loss from the income basis

### DeFi-Specific Issues
| DeFi Activity | Tax Treatment |
|---|---|
| Lending on Aave/Compound (interest received) | Ordinary income when received |
| Providing liquidity on Uniswap (fees received) | Ordinary income when received |
| Impermanent loss on LP position | Capital loss when LP position is withdrawn (realization event) |
| Receiving governance tokens (airdrop or farming) | Ordinary income at FMV when received |
| Token swap on DEX | Capital gain/loss realization event |
| Gas fees paid | Added to basis of acquired asset OR deducted as investment expense |

### FBAR and FATCA
- **FBAR (FinCEN 114):** Required if aggregate value of foreign financial accounts exceeded $10,000 ANY day during the year
  - Crypto on foreign exchanges (non-US companies) = foreign financial accounts
  - File annually by April 15 (extended to October 15); file at bsaefiling.fincen.treas.gov
  - Penalty for non-willful failure: up to $10,000/year; willful failure: up to $100,000 or 50% of account value per year
- **Form 8938 (FATCA):** Similar, different thresholds ($50K/$100K), filed with tax return
- **1040 crypto question:** IRS Form 1040 now asks "At any time during [year], did you receive, sell, exchange, or otherwise dispose of any digital asset?" — Answer truthfully; false answer = perjury

---

## Iowa Tax Filing Obligations

| Tax | Form | Rate | Due Date |
|---|---|---|---|
| Iowa corporate income tax | Iowa Form 1120 | 5.5% flat | April 30 (or extended) |
| Iowa individual income tax | Iowa Form 1040 | 3.8% flat | April 30 |
| Iowa sales/use tax (if applicable) | Iowa ST-101 | 6% state + local | 20th of following month |
| Iowa withholding (employees) | Iowa W-4 / periodic returns | Varies | Semi-monthly, monthly, or quarterly depending on size |
| Iowa annual LLC report | Iowa SOS filing | $60 | April 1 |

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
