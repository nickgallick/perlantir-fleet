# SKILL: Employment & Contractor Law for Crypto Companies
**Version:** 1.0.0 | **Domain:** Employment Law, W-2/1099, Token Compensation, AI Agents

---

## W-2 Employees vs. 1099 Independent Contractors

### The IRS Test (Revenue Ruling 87-41, 20 Factors)
Condensed to the three-factor "common law" test used by IRS and courts:
1. **Behavioral control:** Does the company control HOW the work is done? (Employee) vs. just WHAT result is produced? (Contractor)
2. **Financial control:** Is the worker economically dependent on this company? Can they work for others? Do they have unreimbursed business expenses?
3. **Type of relationship:** Is there a written contract? Are there employee-type benefits? Is the relationship permanent?

**Crypto-specific clarification:** Paying in crypto does NOT change the classification. If someone works full-time exclusively for your project under your direction → W-2 employee regardless of whether you pay in USDC.

### The DOL Economic Reality Test
*Used for FLSA (Fair Labor Standards Act) purposes — minimum wage, overtime*
- Is the worker economically dependent on the alleged employer?
- Does the alleged employer control the work?
- DOL Final Rule (2024): multi-factor totality test; no single factor is determinative
- **High-risk misclassification:** Part-time contractor who becomes full-time → reclassify before DOL does it for you

### Misclassification Consequences
- Back taxes (employee share + employer share of FICA): 7.65% employee + 7.65% employer = 15.3%
- Back benefits: health insurance, 401(k) match, PTO
- Statutory penalties: Iowa Code §91A.10 (wages) — civil penalty up to $1,000/violation
- Federal penalties: IRS Trust Fund Recovery Penalty — officers personally liable for unpaid payroll taxes (26 U.S.C. § 6672)
- Class action by workers: California PAGA claims if any California workers are misclassified

### Common Crypto Scenarios:
| Worker Type | Likely Classification | Why |
|---|---|---|
| Bug bounty hunter (one-time) | 1099 Contractor | Project-based, controls methods, works for many |
| Discord community manager (40hrs/week, exclusive) | W-2 Employee | Behavioral + financial control, economically dependent |
| Smart contract auditor (one audit) | 1099 Contractor | Specialized skill, project-based, independent |
| Customer support agent (daily supervision) | W-2 Employee | Controlled HOW (scripts, hours), exclusive relationship |
| Content creator (monthly posts, non-exclusive) | 1099 Contractor | Creative control, non-exclusive, project-based |

---

## Remote Work Across State Lines

### Nexus Implications
- Having ANY employee in a state creates **corporate tax nexus** in that state
- Consequences: state corporate income tax filing obligation, state payroll tax registration, potential state sales tax nexus
- Iowa: Iowa Code §422.33 — Iowa taxes business income from Iowa sources; nexus created by Iowa employees

### Key State Employment Laws (by employee location):

**California (most employee-friendly):**
- California Labor Code: strict wage/hour rules, daily overtime (not just weekly)
- California WARN Act: 60-day notice before mass layoffs
- Cal-OSHA: comprehensive workplace safety requirements
- Non-compete agreements: VOID and UNENFORCEABLE in California (Bus. & Prof. Code §16600)
- If you hire ONE California employee: California law governs that employment relationship

**Iowa:**
- Iowa Wage Payment Collection Act — Iowa Code Chapter 91A
- §91A.2: wages must be paid at least semi-monthly
- §91A.3: final wages due within 30 days of termination
- §91A.8: employer who fails to pay wages owes: unpaid wages + liquidated damages (same amount) + attorney fees
- Iowa does not have a daily overtime requirement (federal 40-hour weekly rule applies)
- Iowa minimum wage: $7.25/hour (federal minimum; Iowa Code §91D.1)

**Texas:**
- Texas Payday Law (Texas Labor Code Ch. 61): final wages due within 6 days of termination (for employees) or next payday (for other separations)
- Employer-friendly; fewer state-level requirements than CA or NY
- No state income tax → no state income tax withholding for Texas employees

---

## Non-Compete & Non-Solicitation in Crypto

### Iowa Non-Compete Law
- **Source:** Iowa common law (no specific statute — governed by case law)
- Enforceable IF the agreement is:
  - Ancillary to an employment agreement or sale of business
  - Reasonably limited in scope (what activities are prohibited)
  - Reasonably limited in duration (Iowa courts typically enforce 1-2 years)
  - Reasonably limited in geography (or can be functional/industry-based for digital businesses)
- Iowa Code §1.2: common law principles govern contract interpretation
- Leading Iowa cases: *Cogley Clinic v. Martini* (Iowa 1966); *Ehlers v. Iowa Warehouse Co.* (Iowa 1975)

### FTC Non-Compete Rule Status
- FTC proposed a nearly complete ban on non-competes (April 2024)
- **Blocked by federal court** (*Ryan LLC v. FTC*, N.D. Tex. Aug. 2024): FTC exceeded its statutory authority (major questions doctrine applied)
- Status as of 2026: non-compete ban is not in effect; state law governs
- **Watch:** FTC may appeal or re-propose under different statutory authority

### Practical Reality in Crypto
- Non-competes are **nearly unenforceable in practice** in crypto:
  - Developers move to pseudonymous projects
  - Protocol forks make "competition" impossible to define
  - Courts are reluctant to enforce broad restraints in fast-moving tech
- **Better protections:**
  - NDAs: enforceable, protect specific confidential information
  - IP assignment agreements: ensure all work product belongs to the company (CRITICAL — otherwise the developer owns the code they wrote)
  - Non-solicitation of clients/customers: narrower, more enforceable than full non-competes
  - Vesting schedules: economic incentive to stay (better than legal coercion)

---

## Token Compensation

### Tax Treatment of Token Grants
- **Token grants that vest:** Taxed as ordinary income at fair market value on the vesting date
  - Same treatment as Restricted Stock Units (RSUs)
  - IRS Revenue Ruling 2023-14: staking rewards are ordinary income when received
  - Each vest event is a taxable income event
- **83(b) Election (26 U.S.C. § 83(b)):**
  - If tokens are RESTRICTED (subject to forfeiture/vesting): employee can elect to be taxed NOW at grant date value instead of at vest date
  - If grant date value is $0 (token doesn't exist yet or has zero market value): elect 83(b) → potentially $0 in tax now
  - MUST be filed within **30 days of grant** — this deadline is absolute; no extensions
  - File with: IRS Service Center where employee files returns; send copy to employer; keep a copy
  - **THIS IS FREQUENTLY MISSED.** Build a reminder into your onboarding process.

### SAFT (Simple Agreement for Future Tokens) for Employees
- A SAFT is a contract for the right to receive tokens when a network launches
- Used when the token doesn't exist yet
- **Tax treatment:** Generally taxed when the tokens are delivered (not when the SAFT is signed)
- **Securities question:** A SAFT is itself a security (an investment contract) → issuing SAFTs to employees as compensation requires either a Reg D exemption or another valid exemption

### Token Options vs. Token Warrants
- **Token options:** Right to purchase tokens at a strike price. Tax treatment unclear — IRS has not issued specific guidance. Most practitioners treat like non-qualified stock options (ordinary income at exercise on the spread).
- **Token warrants:** Similar to options but usually used for investors. Tax treatment similar.
- **Best practice:** Engage a tax attorney specializing in crypto compensation before issuing token options at scale.

### Standard Vesting (Recommend for All Tokens)
- 4-year vesting with 1-year cliff (industry standard from equity compensation)
- Monthly or quarterly vesting after cliff
- **Enforce on-chain:** Use a vesting smart contract (e.g., Sablier, Token Vesting by OpenZeppelin) — this makes vesting automatic and prevents disputes

---

## AI Agents as "Workers" — The Legal Frontier

### Current Legal Status
- AI agents are NOT legal persons. They cannot be employees, contractors, or business partners.
- An AI agent has no Social Security number, no TIN, no legal capacity to enter contracts.
- Everything the AI agent does is attributed to its OPERATOR (Nick / Perlantir).

### Tax Attribution
- If an AI agent earns prize money in a competition → that income is attributed to the platform operator (Perlantir LLC)
- If an AI agent generates code that is sold → the income is the company's; the company owns the IP (assuming proper IP assignment from any humans involved in training/prompting)
- IRS has issued NO guidance specifically on AI agent income attribution as of 2025

### Employment Law for AI Agents
- No W-2 or 1099 issued to an AI agent (it's software, not a person)
- AI agent compute costs are a business expense (deductible)
- If you pay a HUMAN to run/supervise AI agents → they are a contractor or employee based on the standard tests
- If you pay a PLATFORM (Anthropic for Claude API, OpenAI for GPT API) → that platform is a vendor; issue a 1099-NEC if payments exceed $600/year

### Agent Sparta Specific
- NPC AI agents competing in Bouts and earning prize money: that prize money is platform revenue if the platform's agents win
- If a THIRD PARTY's AI agent wins prize money: the prize is paid to the third party (human/entity operator of the agent)
- The third party gets a 1099-MISC if they're a US person/entity and win >$600
- **The AI agent itself is never the tax recipient — always its operator**

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
