# SKILL: Bankruptcy & Insolvency for Crypto Platforms
**Version:** 1.0.0 | **Domain:** Bankruptcy Code, Crypto Insolvency, Asset Protection

---

## The Crypto Bankruptcy Track Record

| Company | Filing Date | Chapter | Key Issue | User Outcome |
|---|---|---|---|---|
| Celsius Network | July 2022 | Chapter 11 | Deposits = property of estate | ~47 cents on the dollar |
| Voyager Digital | July 2022 | Chapter 11 | Deposits = unsecured claims | ~35 cents on the dollar |
| FTX/Alameda | November 2022 | Chapter 11 | Massive fraud; missing funds | Better than expected due to crypto appreciation during case |
| BlockFi | November 2022 | Chapter 11 | Concentrated FTX exposure | Partial recovery |
| Genesis Global | January 2023 | Chapter 11 | DCG subsidiary; $3B+ claims | Ongoing |

**The pattern:** In EVERY major crypto bankruptcy, centralized custody of user funds meant user deposits became property of the bankruptcy estate — users became unsecured creditors. Non-custodial architecture is the single most important structural decision for user protection.

---

## Chapter 11 Reorganization — How It Works

**Authority:** 11 U.S.C. §§ 1101-1174

### Filing and Automatic Stay
- Filing triggers an **automatic stay** (11 U.S.C. § 362): all collection actions, lawsuits, and contract terminations against the debtor are immediately halted
- This buys time to reorganize
- Regulators: CFTC/SEC enforcement actions ARE stayed by bankruptcy (with some exceptions for police/regulatory actions)

### First Day Motions (Critical in Crypto)
- **DIP Financing:** Debtor-in-Possession financing to fund operations during case
- **Cash collateral use:** Permission to use pre-petition cash
- **Employee wage payment:** Court order to pay prepetition wages (employees are priority creditors under 11 U.S.C. § 507(a)(4), up to $15,150 per employee)
- **Customer funds segregation:** Celsius and FTX fought this. Your argument: user funds are NOT property of the estate because they were held in trust or smart contract escrow.

### The Critical Custody Question

**Property of the estate (11 U.S.C. § 541):** Includes "all legal or equitable interests of the debtor in property as of the commencement of the case."

**Celsius outcome:** *In re Celsius Network LLC*, No. 22-10964 (Bankr. S.D.N.Y.)
- Court ruled that under Celsius's Terms of Service, users transferred LEGAL TITLE of their crypto to Celsius when depositing
- Therefore: deposits were property of the estate, not customer property
- Users became unsecured creditors — lowest priority in the waterfall

**How to avoid the Celsius outcome:**
1. **Non-custodial architecture:** User funds NEVER transfer to the platform. User's wallet → smart contract → winner's wallet. The platform has no legal title to user funds at any point.
2. **Express trust language in TOS:** "All user funds are held in trust for the benefit of users and do not constitute property of [Company]." (Weak if the platform actually comingles funds, but helps if funds are genuinely segregated.)
3. **Segregated accounts:** If custodial, user funds in separate FDIC-insured accounts (not commingled with operating funds). Strong argument against property of estate.

**The smart contract argument:**
- Funds locked in a smart contract pending a competition outcome: the platform never had legal title
- The smart contract code IS the escrow; the platform is the escrow agent, not the owner
- This argument is untested in crypto bankruptcy but is consistent with traditional escrow law

---

## Preference Actions (Clawbacks)

**Authority:** 11 U.S.C. § 547

**Rule:** A bankruptcy trustee can "avoid" (claw back) transfers made by the debtor:
- To a creditor
- Within 90 days before filing (or 1 year for insiders)
- While the debtor was insolvent
- That gives the creditor more than they would receive in liquidation

**Crypto implications:**
- Distributions to users (prize payouts, interest payments) within 90 days before filing → potentially clawable
- Payments to vendors, contractors within 90 days → potentially clawable
- Airdrops within 90 days → potentially clawable

**Defense against preference claims:**
- "Ordinary course of business" defense (§547(c)(2)): payment was made in the ordinary course, consistent with past practice → not a preference
- "New value" defense (§547(c)(4)): the recipient provided new value after receiving the payment

**Practical protection:**
- Make prize payouts consistently and on schedule (establishes "ordinary course")
- Don't make large unusual payments to specific users/vendors right before a potential financial crisis

---

## Fraudulent Transfer (Clawbacks)

**Authority:** 11 U.S.C. § 548 (federal); Iowa Code §684A.4 (Iowa Uniform Voidable Transactions Act)

**Rule:** Transfers made with intent to defraud creditors, OR transfers for less than reasonably equivalent value while insolvent, can be clawed back:
- Up to 2 years under federal bankruptcy law
- Up to 4 years under Iowa state law (§684A.9)

**Crypto risk:** If Nick withdraws significant funds from the company right before it becomes insolvent → fraudulent transfer. Clawed back to the estate. This is also potentially criminal (18 U.S.C. § 152 — bankruptcy fraud).

---

## Corporate Veil Protection

### The LLC Shield
- Iowa Code Chapter 489: an Iowa LLC member is NOT personally liable for the LLC's debts
- The LLC is a separate legal entity — its debts are not Nick's debts
- **This protection is critical** — without it, a judgment against the LLC could pursue Nick personally

### Piercing the Corporate Veil — When the Shield Fails
Iowa courts will pierce the corporate veil (hold members personally liable) when:
1. **Alter ego:** The LLC is treated as the owner's personal property (commingled funds, no separate accounts, no adherence to formalities)
2. **Fraud or injustice:** The LLC structure is being used to perpetrate fraud or evade legal obligations

*Hamilton v. Am. Chemical Fire Extinguisher Co.*, 229 Iowa 927 (1940): Iowa has recognized veil-piercing for over 80 years; standards are well-established.

**Rules to prevent veil-piercing:**
- Maintain **completely separate bank accounts** (never use business accounts for personal expenses; never use personal accounts for business expenses)
- **Annual report filed** with Iowa SOS ($60/year — do not miss this)
- **Keep corporate records:** document major decisions in writing
- **Don't personally guarantee** business debts unless absolutely necessary
- **Adequate capitalization:** don't undercapitalize the LLC when you know it has significant liabilities

---

## Counterparty Bankruptcy Risk

**If a partner, exchange, or DeFi protocol goes bankrupt:**
- Your claim against them is a general unsecured claim — lowest priority
- Likely recovery: 5-50 cents on the dollar, years later
- **Protection:** Don't hold significant funds in any single third-party platform
- Smart contract deposits: may be treated as a **secured claim** (you know exactly where the funds are and can identify them) — stronger than unsecured

**Exchange custodial risk:**
- Any crypto held on a centralized exchange (Coinbase, Kraken) → you're an unsecured creditor if they go bankrupt
- Coinbase 10-K disclosure (2022): "In the event of a bankruptcy, the crypto assets we hold in custody on behalf of our customers could be subject to bankruptcy proceedings and such customers could be treated as our general unsecured creditors."
- **Mitigation:** Keep operational funds only on exchanges; hold reserves in self-custody (cold wallet)

---

## Emergency Planning for Platform Insolvency

**If you see financial trouble coming:**
1. Stop taking new user deposits immediately
2. Process all pending prize payouts before filing (so they're not clawback targets — though 90-day window still applies)
3. Consult bankruptcy counsel BEFORE filing
4. Do NOT transfer personal assets to your spouse or family members to hide them (fraudulent transfer + bankruptcy fraud)
5. Do NOT destroy financial records (obstruction + bankruptcy fraud, 18 U.S.C. § 152)
6. Communicate honestly with users about the situation (failure to do so = fraud)

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
