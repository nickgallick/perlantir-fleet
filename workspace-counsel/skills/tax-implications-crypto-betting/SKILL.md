# SKILL: Tax Implications for Crypto Betting & Competition Platforms
**Version:** 1.0.0 | **Domain:** Tax Law, IRS, 1099, Crypto Tax

---

## For Platform Operators (Perlantir / Agent Sparta)

### Revenue Classification
- Revenue from rake/contest fees: **ordinary business income**
- US entity: subject to US federal corporate tax (~21%) + state tax
- Offshore entity: only US-source income is taxable (if properly structured — "not effectively connected" with US trade or business)

### 1099 Obligations (US Entity)
| Winner Type | Form | Threshold | Timing |
|---|---|---|---|
| US person, prize winner | 1099-MISC | >$600 per year | By Jan 31 following tax year |
| US person, gambling winnings | W-2G | >$600 (gambling) | By Jan 31 |
| Non-US person | W-8BEN required | Varies by treaty | Report via 1042-S |

**Current IRS thresholds:** Verify annually at IRS.gov — thresholds for third-party payment network reporting changed in 2024.

### Backup Withholding
- 24% withholding required if US winner does NOT provide valid W-9
- Practical implication: require W-9 BEFORE paying any prize >$600; block payout until received
- Non-US winners: withhold 30% (unless reduced by tax treaty) unless W-8BEN provided

### State Tax Obligations
- Withholding on prizes may also be required at the state level (varies by state)
- States with aggressive withholding: CA, NY, PA (withhold on winnings >$5,000 or lower)

### Platform Tax Accounting Considerations
- Entry fees received: recognize as revenue when contest closes (accrual basis) or when received (cash basis)
- Prize payouts: deductible business expenses
- USDC/crypto received: recognize at fair market value at time of receipt
- USDC/crypto paid out: deductible at fair market value at time of payout

---

## For Users / Winners

### Competition Winnings
- **Tax classification: ordinary income** (not capital gains)
- Reported on Form 1040, Schedule 1 (Line 8, "Other Income")
- Not subject to self-employment tax UNLESS user is a professional player (extremely rare)
- **Gambling vs. skill game distinction:** If classified as gambling → gambling rules apply (see below). If skill contest → ordinary income rules.

### If Platform Classified as Gambling:
- Winnings reported on Form W-2G (if >$600)
- Losses deductible ONLY up to winnings (can't create a net loss from gambling)
- Deduction only available if itemizing (Schedule A)
- Professional gambler status: allowed to deduct losses beyond winnings IF it's a trade or business — very high bar to establish

### If Platform Classified as Skill Competition:
- Winnings: ordinary income (reported on 1040, Line 8)
- Entry fees paid: potentially deductible as hobby expenses or (if professional) business expenses on Schedule C
- Losses: limited by hobby loss rules (IRC § 183) unless user is a professional

### Crypto Received as Prize
1. **At receipt:** Fair market value in USD = ordinary income (report on 1040)
2. **Subsequent sale:** Capital gain/loss calculated from the income basis (step 1 value)
   - Held <12 months: short-term capital gain (taxed at ordinary income rates)
   - Held >12 months: long-term capital gain (0%, 15%, or 20% depending on income)

### USDC Specifics
- USDC is pegged to $1 and generally treated as $1 FMV
- Receiving $100 USDC prize = $100 ordinary income
- Swapping USDC for ETH = taxable event (realize gain/loss on USDC disposition)
- Keeping USDC = no additional tax until disposed

---

## Crypto-Specific Tax Issues

### Every Trade/Swap Is a Taxable Event
- USDC → entry fee → USDC winnings: each transfer is tracked; generally basis = $1 for USDC
- ETH → USDC swap before deposit: taxable disposition of ETH at time of swap
- Gas fees: deductible as transaction costs (added to basis of acquired asset)

### Common Crypto Tax Events
| Event | Tax Treatment |
|---|---|
| Receive crypto prize | Ordinary income at FMV |
| Sell/swap crypto | Capital gain/loss from basis |
| Pay gas fees | Deductible as transaction cost |
| Receive airdrop | Ordinary income at FMV when received |
| DeFi yields/staking rewards | Ordinary income at FMV when received |
| Lost/stolen crypto | Potentially casualty loss — limited by IRS guidance; consult counsel |
| Hard fork new tokens | Ordinary income — *Jarrett v. United States* (pending IRS guidance) |

### IRS Crypto Reporting Infrastructure
- **Form 8949:** Report every crypto sale/exchange (basis, proceeds, gain/loss)
- **Schedule D:** Summary of capital gains/losses from Form 8949
- **FBAR (FinCEN 114):** If crypto held on foreign exchanges with aggregate >$10,000 any day during year
- **Form 8938 (FATCA):** If foreign crypto accounts exceed $50K/$100K thresholds
- **1040 crypto question:** IRS asks on 1040 front page: "At any time during [year], did you receive, sell, exchange, or otherwise dispose of any digital asset?" — ANSWER TRUTHFULLY

---

## Recommended Tax Infrastructure for Nick's Platforms

### For the Platform (Operator):
1. **Accounting software:** QuickBooks or Xero + crypto module (Cryptoworth, TaxBit for Business)
2. **Track all contests:** Start date, end date, total entry fees, total prizes paid, fee revenue
3. **Generate 1099s:** TaxBit, Taxjar, or tax counsel generates 1099-MISC from your payout records
4. **Collect W-9/W-8BEN:** Required before payout of any prize >$600 per year per user
5. **Annual tax filing:** Work with CPA familiar with crypto platform accounting
6. **Quarterly estimated taxes:** If profitable, make quarterly estimated payments (avoid underpayment penalty)

### For Users (Provide These Tools to Improve UX):
- Transaction history export (CSV with: date, amount in USD, type: entry fee / prize / platform fee)
- Integration with crypto tax tools (TaxBit, Koinly, CoinTracker) via API or export
- Year-end summary: Total entry fees paid, total prizes received, net P&L (for their CPA)
- **This is a differentiator** — most crypto gaming platforms provide zero tax support

---

## Iowa Tax Considerations
- Iowa corporate income tax rate: 8.4% (flat rate as of 2024; Iowa has been reducing rates)
- Iowa individual income tax: 4.4% flat (2026) on prizes won by Iowa residents
- Iowa has NOT adopted specific crypto tax guidance — follow federal treatment
- Iowa Department of Revenue: revenue.iowa.gov — confirm current rates before filing

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
