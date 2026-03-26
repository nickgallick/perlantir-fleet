# SKILL 74: Cap Table & Equity Management

## Purpose
Track, manage, and protect equity from founding through exit. A clean cap table is a prerequisite for fundraising, acquisition, and IPO.

## Cap Table Basics
- Tracks: who owns what percentage, what type of security, and on what terms
- **Tools**: Carta (industry standard), Pulley (cheaper alternative), AngelList
- **Pre-seed**: spreadsheet is acceptable, but migrate to Carta before any external investment
- **Rule**: every share issued must have a corresponding board resolution and stock certificate or digital equivalent

## Authorized vs. Issued Shares

| Concept | Definition | Typical Number (Delaware C-Corp) |
|---------|-----------|----------------------------------|
| Authorized shares | Total the company is allowed to issue | 10,000,000 at incorporation |
| Issued to founders | Given to founders at founding | 8,000,000 (80%) |
| Option pool | Reserved for employees/advisors | 1,000,000 (10%) |
| Unissued/authorized | Available for future rounds | 1,000,000 (10%) |

- **Common stock**: founders and employees (voting rights, lowest liquidation priority)
- **Preferred stock**: investors (special rights — liquidation preference, anti-dilution, board seats)

## Option Pool

### Structure
- Reserve 10–20% of fully diluted shares for future employees/advisors (create BEFORE fundraising)
- Standard option plan: 2022 Equity Incentive Plan (free template from NVCA or YC)
- The option pool gets created from EXISTING shareholders' dilution (founders dilute first before investors in a well-structured raise)

### 409A Valuation
- **What it is**: independent third-party valuation of the company's common stock
- **When required**: before issuing any stock options (or face catastrophic IRS penalties)
- **Frequency**: annually, or after any "material event" (new funding round, acquisition offer, significant revenue milestone)
- **Cost**: $5–15K per valuation
- **Who does it**: Carta (built in), Preferred Return, Andersen Tax, independent valuation firms
- **Strike price**: option exercise price MUST equal the 409A FMV at grant date. Options granted below FMV → Section 409A penalties (20% additional tax + interest on option holder)
- **If you skip it**: IRS can deem all options were granted below FMV → massive tax liability for every option holder

### Stock Options
- **ISOs (Incentive Stock Options)**: favorable tax treatment for employees; cannot be granted to non-employees; $100K per year limit on ISO value
- **NSOs (Non-Qualified Stock Options)**: for contractors, advisors, anyone who can't receive ISOs; taxed as ordinary income at exercise
- **83(b) election**: for restricted stock grants (not options). File within 30 DAYS of grant. NEVER MISSABLE.
  - What it does: elect to be taxed on current FMV (likely near zero at founding) rather than FMV at vesting
  - Without 83(b): pay income tax on the appreciated value when each tranche vests
  - With 83(b): pay income tax once on the low founding-day value; pay capital gains (lower rate) when shares are sold
  - **Calendar reminder**: set the day of every restricted stock grant. 30-day window is ABSOLUTE.

## Dilution Math — How It Actually Works

| Stage | Event | Nick's Ownership |
|-------|-------|-----------------|
| Founding | 100% of 10M shares | 100% |
| Create 20% option pool | Dilution from existing shares | 80% |
| Seed ($2M SAFE, $10M cap) | SAFE converts to 20% of company | ~64% (80% × 80%) |
| Series A ($5M at $25M pre-money) | New shares issued to VC | ~51% (64% × 80%) |
| Series B | Further dilution | ~35–40% |

**Key principle**: raise only what you need. Higher valuation = less dilution. Unnecessary capital = unnecessary dilution.

## Token Allocation (Separate Track)
Token allocation is SEPARATE from the equity cap table. Track both.

| Category | Typical % | Vesting |
|---------|----------|---------|
| Team/founders | 15–20% | 4-year, 1-year cliff |
| Investors | 15–25% | 12–24 month lockup, then monthly |
| Community/ecosystem | 25–40% | Airdrops, rewards, grants, liquidity |
| Treasury | 15–25% | DAO/multi-sig governed |
| Advisors | 2–5% | 2-year monthly |

## Cap Table Hygiene
- **Never grant equity informally** — no handshakes, no emails saying "you'll get 5%"
- **Document every grant**: board resolution + stock purchase agreement/option grant agreement
- **Update on every event**: new grant, exercise, transfer, conversion, new round
- **Fully diluted count**: always model the cap table on a fully-diluted basis (all options and SAFEs converted)
- **Quarterly review**: verify Carta/Pulley matches actual agreements on file

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
