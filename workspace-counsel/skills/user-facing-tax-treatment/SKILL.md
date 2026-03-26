# SKILL: User-Facing Tax Treatment

## Purpose
Understand and communicate the tax treatment of prediction market / skill-game winnings to users. Covers platform reporting obligations (1099 forms), user disclosure requirements, IRS guidance, and product design implications.

## Risk Level
🟡 Medium — Incorrect tax handling creates IRS penalties for the platform, user confusion that erodes trust, and potential FTC/state AG issues if tax obligations are misrepresented. Get this right in product design, not after launch.

---

## Platform Reporting Obligations (What You Must File)

### Form 1099-MISC (Prizes and Awards)
**When required**: Prize winnings of **$600 or more** in a calendar year from a single recipient
**IRC authority**: 26 U.S.C. § 6041; IRS Publication 525
**Filing deadline**: January 31 (to recipient); February 28 paper / March 31 electronic (to IRS)
**Threshold**: $600 cumulative per user per calendar year

**Applies to**:
- AI coding competition prize payouts (Agent Arena / Bouts)
- Prediction market winnings if structured as prizes

**Does NOT apply to**:
- Crypto payouts (see 1099-DA below)
- Small winnings under $600 threshold

### Form 1099-DA (Digital Asset Proceeds) — NEW for 2025
**When required**: Digital asset (crypto/stablecoin) dispositions for brokers
**IRC authority**: 26 U.S.C. § 6045; IRS Rev. Proc. 2024-28
**Effective**: Reporting year 2025 (filed January 2026)
**Threshold**: ALL transactions (no de minimis)

**Critical for Bouts/Agent Arena**: If prize pools are in USDC, ETH, or any digital asset:
- Platform MAY be classified as a "digital asset broker" under new IRS rules
- Must collect user KYC (name, address, TIN/SSN) before any digital asset transactions
- Must issue 1099-DA for all digital asset proceeds

**Uncertainty**: IRS has not fully clarified whether prediction market platforms using crypto are "brokers" — treat as likely YES for compliance planning.

### Form W-9 (TIN Collection)
**When required**: Before any reportable payment
**What it is**: User self-certification of name, address, TIN (SSN or EIN)
**Backup withholding**: If user fails to provide W-9, must withhold 24% of payments
**Practice**: Collect W-9 equivalent at KYC/onboarding for any user eligible for prizes

### Form W-8BEN (Non-US Users)
**When required**: For non-US users receiving prize payments
**What it is**: Foreign user certification; establishes treaty withholding rate
**Withholding rate**: 30% default on US-source income; reduced by tax treaty
**Practice**: Collect W-8BEN at onboarding for foreign users

---

## How Winnings Are Taxed (User-Facing)

### Prediction Market / Event Contract Winnings
**Tax treatment**: Depends on contract classification
- **Section 1256 contracts** (if CFTC-regulated futures/options): 60% long-term / 40% short-term capital gain blended rate — FAVORABLE for users
- **Non-Section 1256**: Ordinary income (up to 37% federal rate)
- **Kalshi**: Explicitly structured as Section 1256 contracts — key user benefit
- **PredictIt winnings**: Historically reported as gambling income (ordinary income) pending final CFTC characterization

**IRS guidance**: Notice 2007-78 and PLR 200532003 suggest prediction contracts may be Section 1256; not definitively settled outside DCM-registered platforms

### Skill-Game Prize Winnings (If Not CFTC Contracts)
**Tax treatment**: Ordinary income — reported as "other income" on Schedule 1
**IRS authority**: IRC § 74 (prizes and awards); IRC § 61 (gross income)
**User obligation**: Report winnings even if no 1099 received
**Net losses**: Users generally cannot deduct skill-game losses against income (different from gambling losses under IRC § 165(d))

### Gambling Winnings (If Platform Classified as Gambling)
**Tax treatment**: Ordinary income
**Deduction**: Gambling losses deductible only to extent of gambling gains (IRC § 165(d))
**W-2G required**: For winnings over $1,200 (slots/bingo) or $5,000 (poker tournaments) — thresholds don't cleanly apply to prediction markets
**Practical**: If platform is classified as gambling by IRS, different forms and higher user burden

### Crypto Prize Winnings
**Tax treatment**: TWO taxable events
1. Receipt of crypto prize: Ordinary income at FMV on date received (IRC § 83; IRS Notice 2014-21)
2. Subsequent sale/trade of crypto: Capital gain/loss based on holding period
**User education required**: Users often don't know crypto prizes are taxable at receipt, not just sale

---

## Product Design Implications

### KYC / Tax ID Collection
- **Must collect SSN/EIN** from users before first reportable payment
- Design KYC flow to collect W-9 information during onboarding (not at first payout — too late)
- Gate prize payouts on tax ID verification
- Non-US users: collect W-8BEN; implement withholding

### $600 Threshold Strategy
- Some platforms historically designed around $600 threshold — IRS has proposed eliminating this threshold (Congress has delayed, but watch)
- Do not design product to keep users below $600 to avoid 1099s — aggressive and risky
- Track cumulative annual winnings per user in your data model

### Tax Year-End Operations
- **December 15 deadline**: Must have all user tax information collected to meet January 31 deadline
- **January 31**: 1099s due to users
- **March 31**: Electronic 1099 filing with IRS
- Build this into your operational calendar from day one

### User-Facing Tax Disclosures
**Must include in Terms of Service / Help Center**:
- Winnings are taxable income
- Platform will issue 1099-MISC for winnings ≥ $600
- Crypto prizes are taxable at FMV on receipt
- Users are responsible for reporting all winnings regardless of 1099 receipt
- Backup withholding at 24% if TIN not provided

### Prize Structure Considerations
**Lump sum vs. installments**: Tax treatment is generally the same; lump sum preferred by users
**Crypto vs. fiat prizes**: Crypto creates additional tax complexity for users — may reduce appeal; disclose clearly
**International prizes**: Heavy withholding (30% default) unless treaty applies; may need to restrict prize eligibility by country

---

## State Tax Considerations

### Iowa
- Iowa income tax rate: 3.8% (2025, flat rate per 2022 tax reform fully phased in by 2026)
- Iowa taxes gambling winnings as ordinary income (Iowa Code § 422.7)
- Prediction market/skill-game winnings: Same treatment as federal (ordinary income)
- Iowa does NOT have a separate form for gambling/prize income — reported on Iowa 1040

### Other Key States
- **California**: No deduction for gambling losses; treats all prize income as ordinary income
- **New York**: Taxes gambling/prize income; lottery winnings taxed even if won in another state
- **Nevada**: No state income tax; prize winners may claim Nevada domicile
- **Florida**: No state income tax; popular for high-volume prediction market users

---

## Minimum Viable Tax Compliance (Pre-Launch)
1. ✅ W-9 collection at KYC/onboarding (before any payout capability)
2. ✅ Cumulative annual winnings tracking per user in data model
3. ✅ 1099-MISC issuance for $600+ calendar year winners
4. ✅ Backup withholding (24%) capability if no TIN
5. ✅ Tax disclosure in Terms of Service
6. ✅ Help center article on tax treatment
7. ✅ Tax calendar integrated into ops calendar (January 31 / March 31 deadlines)

**For crypto prize pools — additional**:
8. ✅ FMV documentation at time of prize distribution
9. ✅ 1099-DA readiness (2025 requirement)
10. ✅ W-8BEN collection for international users + withholding capability

---

## IRS Resources
- IRS Publication 525 (Taxable and Nontaxable Income): https://www.irs.gov/pub/irs-pdf/p525.pdf
- IRS Notice 2014-21 (Crypto taxation): https://www.irs.gov/pub/irs-drop/n-14-21.pdf
- Form W-9: https://www.irs.gov/forms-pubs/about-form-w-9
- Form 1099-MISC instructions: https://www.irs.gov/forms-pubs/about-form-1099-misc
- Form 1099-DA (digital assets): https://www.irs.gov/forms-pubs/about-form-1099-da

---

## Iowa Angle
- Iowa's flat income tax rate (3.8% as of 2026) makes Iowa one of the lower-tax states for prize income
- Iowa does not have separate gambling tax forms — all goes through standard Iowa 1040
- Iowa-based company issuing 1099s must comply with Iowa Department of Revenue reporting requirements
- Iowa DOR: https://tax.iowa.gov

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
