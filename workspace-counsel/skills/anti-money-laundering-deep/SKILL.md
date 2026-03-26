# SKILL: AML/CFT Compliance — Complete Program Design
**Version:** 1.0.0 | **Domain:** BSA, FinCEN, OFAC, Travel Rule, Transaction Monitoring

---

## BSA/AML Program: The Five Pillars
**Authority:** Bank Secrecy Act, 31 U.S.C. §§ 5311-5336; 31 C.F.R. Part 1022 (MSB rules)

For a registered Money Services Business, your AML program MUST include all five pillars. Failure to implement = criminal violation (31 U.S.C. § 5322).

1. **Written AML policies and procedures** — documented, specific to your business
2. **Designated BSA Compliance Officer** — named individual, responsible for the program
3. **Ongoing employee training** — annual at minimum; document who was trained and when
4. **Independent testing/audit** — annual review by someone not responsible for running the program (external auditor or qualified internal auditor who doesn't run compliance day-to-day)
5. **Customer Due Diligence (CDD)** — including beneficial ownership for legal entity customers

---

## Customer Due Diligence (CDD)

### Individual Customers
Collect and verify at onboarding:
- Full legal name
- Date of birth
- Residential address
- Government-issued ID number (SSN for US persons; foreign equivalent for non-US)

**Verification methods:**
- Document verification (ID scan): verify government ID is genuine and matches the person
- Database verification: check against identity databases (LexisNexis RiskView, Socure, Jumio, Onfido)
- Cost: $0.50-$3.00 per verification depending on provider and depth

**Understanding the customer relationship:**
- What is the purpose of the account?
- What level of activity is expected?
- This allows you to set a "baseline" for transaction monitoring

### Legal Entity Customers (if applicable)
**FinCEN Beneficial Ownership Rule (31 C.F.R. § 1010.230):**
- Collect information on all individuals owning ≥25% of the entity AND one individual with significant management control
- Verify their identities under the same CDD procedures
- Applies when opening accounts for corporations, LLCs, partnerships, etc.

### Enhanced Due Diligence (EDD)

**Triggers for EDD:**
- Transaction above $10,000 (CTR threshold)
- Customer is a Politically Exposed Person (PEP): current or former government official, senior executive of state-owned enterprise, or family member/close associate of same
- Customer is from a high-risk jurisdiction (FATF grey/blacklist: Iran, North Korea, Myanmar, currently listed jurisdictions at www.fatf-gafi.org/en/topics/high-risk-and-other-monitored-jurisdictions.html)
- Unusual transaction pattern inconsistent with stated purpose

**EDD requirements:**
- Source of funds: where does the money come from?
- Source of wealth: how did they accumulate their overall wealth?
- Enhanced monitoring: more frequent review, lower suspicious activity thresholds
- Senior management approval to maintain the relationship

**PEP screening tools:**
- World-Check (Refinitiv/LSEG): industry standard; comprehensive PEP and adverse media database
- Dow Jones Watchlist: similar coverage
- LexisNexis WorldCompliance: good for US-centric businesses
- Cost: $500-$5,000/month depending on volume

---

## OFAC Sanctions Compliance

**Authority:** International Emergency Economic Powers Act (IEEPA), 50 U.S.C. §§ 1701-1708; Trading with the Enemy Act (TWEA)

### The SDN List
- OFAC Specially Designated Nationals and Blocked Persons List: www.treasury.gov/ofac/downloads/sdnlist.txt
- Over 13,000 names (individuals, entities, vessels, aircraft)
- Also screen: Consolidated Sanctions List (includes all OFAC lists), Sectoral Sanctions (CAATSA targets in Russia, etc.)

### Screening Obligations
- **At onboarding:** Screen every new customer before activating their account
- **Every transaction:** Screen sender and receiver of every transaction
- **Periodic rescreening:** Daily rescreening of existing customer base (SDN list updates frequently)
- **Wallet screening:** Screen blockchain wallet addresses against OFAC's crypto-specific designations

### Crypto Wallet Designations
**Tornado Cash (August 2022):** OFAC sanctioned the smart contracts themselves — not just the operators. Any interaction with the designated Tornado Cash contracts = potential OFAC violation.
- *Van Loon v. Department of Treasury* (5th Cir. 2024): Court ruled OFAC CANNOT sanction immutable smart contract code under IEEPA (the code is not "property" of a person). BUT: OFAC may relist under different authority, and the case is ongoing.
- **Current risk:** Unclear. Until fully resolved, avoid any interaction with Tornado Cash-associated addresses.

**If a match is found:**
1. Immediately freeze/block the account — do NOT process any transaction
2. Do NOT tell the customer you've blocked them (tipping off = potential criminal liability; OFAC requires confidentiality)
3. File a blocking report with OFAC within **10 business days** at ofac.treas.gov
4. Preserve ALL records related to the blocked transaction
5. Consult OFAC counsel before unfreezing or releasing any blocked funds

**Penalty for violations:**
- Civil: up to $20 million per transaction under IEEPA (50 U.S.C. § 1705(b))
- Criminal: up to $1 million per violation + 20 years imprisonment
- **Strict liability:** No knowledge or intent required for civil OFAC violations. If you transact with an SDN, you're liable even if you didn't know.

**Compliance tools:**
- Chainalysis Sanctions Oracle: on-chain, real-time screening of wallet addresses against OFAC designations. Integrates directly into smart contracts.
- Elliptic Lens: similar; good for multi-chain coverage
- TRM Labs: blockchain risk intelligence; covers OFAC + AML risk scoring
- Comply Advantage: comprehensive sanctions screening for traditional + crypto

---

## Suspicious Activity Reports (SARs)

**Authority:** 31 U.S.C. § 5318(g); 31 C.F.R. § 1022.320

### Filing Requirement
- If you know, suspect, or have reason to suspect a transaction involves funds from illegal activity, is designed to evade BSA reporting, or has no lawful purpose → file a SAR
- **Threshold:** No minimum dollar threshold for SARs (unlike CTRs, which are $10K+)
- **Deadline:** File within **30 calendar days** of initial detection of suspicious activity
- If no suspect can be identified at 30 days: 60-day extension available

### SAR Confidentiality — CRITICAL
- 31 U.S.C. § 5318(g)(2): It is a federal crime to notify any person involved in the suspicious activity that a SAR has been filed
- **NEVER tell a customer:** "We filed a suspicious activity report on your account" or "Your account is under investigation" or anything that suggests SAR filing
- This includes: refusing to answer questions, deflecting with generic policy language
- If a customer asks why their account is restricted: "We are unable to discuss the status of any regulatory filings" — no more

### SAR Content Requirements
- **Narrative:** The most important part. Describe specifically: what happened, when, how much, why it's suspicious, what you found in your investigation
- Supporting data: all identifiers (wallet addresses, transaction hashes, IP addresses, user ID, KYC records)
- Financial summary: total amounts involved
- The SAR is reviewed by FinCEN's Financial Intelligence Unit — a good narrative gets read; a bad one gets filed and forgotten

**File SARs at:** BSA E-Filing System — bsaefiling.fincen.treas.gov

---

## Currency Transaction Reports (CTRs)

**Authority:** 31 U.S.C. § 5313; 31 C.F.R. § 1022.310

- Required for cash transactions exceeding **$10,000** in a single business day
- **Crypto context:** Cash means fiat currency. Crypto-to-crypto transactions: CTR not required (but SAR may be if suspicious)
- If you accept fiat deposits (bank wires, ACH, debit cards): track per-customer daily totals
- Aggregation rule: multiple transactions on the same day by the same customer = aggregated for CTR purposes

---

## Transaction Monitoring

### Automated Rules to Implement
**High-value transactions:**
- Flag any single transaction >$3,000 (Travel Rule threshold)
- Flag cumulative daily volume >$10,000 per user (CTR consideration)

**Behavioral flags:**
- Rapid deposit/withdrawal ("in-out") pattern with minimal platform activity (layering indicator)
- Sudden large transaction inconsistent with user's established pattern
- Multiple accounts from same IP/device
- User attempts to evade transaction limits by breaking into smaller amounts (structuring)

**Blockchain-specific flags:**
- Incoming transaction from: known mixer/tumbler address (Tornado Cash, Wasabi Wallet outputs)
- Incoming transaction from: exchange associated with dark web markets
- Incoming transaction from: newly created wallet with large balance and no transaction history
- Outgoing transaction to: OFAC-sanctioned address (should be blocked, not just flagged)

**Tools:**
- Chainalysis KYT (Know Your Transaction): real-time blockchain transaction monitoring; assigns risk scores; used by Coinbase, major banks
- Elliptic Navigator: similar; good multi-chain coverage
- TRM Labs: transaction monitoring + compliance workflows
- Cost: varies by transaction volume; typically $2,000-$20,000/month for growing platforms

---

## Travel Rule Compliance

**Authority:** FATF Recommendation 16; 31 C.F.R. § 1010.410(f) (wire transfer recordkeeping rule, threshold $3,000)

### What It Requires
When a VASP (Virtual Asset Service Provider) transmits crypto:
- **Originator information:** Name, account (wallet address), physical address OR national ID OR customer ID number, date/place of birth
- **Beneficiary information:** Name and account (wallet address)
- Must be transmitted TO the beneficiary's VASP simultaneously with the transaction

### Who It Applies To
- VASPs that transmit crypto on behalf of customers
- **Non-custodial platforms:** If users interact directly with your smart contract and you never transmit on their behalf → strong argument Travel Rule doesn't apply
- **Custodial platforms:** Almost certainly applies; you are transmitting crypto on behalf of users

### Implementation Protocols
- **TRISA (Travel Rule Information Sharing Architecture):** www.trisa.io — open protocol for VASP-to-VASP Travel Rule data exchange
- **Sygna Bridge:** Proprietary Travel Rule solution from CoolBitX; widely used in Asia
- **Notabene:** Travel Rule compliance platform; supports TRISA and other protocols; used by Coinbase, Crypto.com
- **VerifyVASP:** Another protocol option

**The "Sunrise Problem":** Not all VASPs are Travel Rule compliant. If you send to a VASP that can't receive Travel Rule data → some jurisdictions allow you to send anyway with a record; others require you to withhold the transaction. Know your jurisdiction's rules.

---

## AML Record Retention

**Authority:** 31 C.F.R. § 1022.410

- All KYC records: **minimum 5 years** from account closure
- All transaction records: **minimum 5 years**
- SAR filings: 5 years from date of filing
- CTR filings: 5 years from date of filing
- AML program documentation: 5 years
- Training records: 5 years

**Storage:** Encrypted, access-controlled. Two separate backups minimum. Accessible to authorized compliance personnel and to law enforcement with proper legal process.

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
