# SKILL: Administrative Law & Fighting Regulators
**Version:** 1.0.0 | **Domain:** CFTC Enforcement, SEC Enforcement, Administrative Procedure Act

---

## CFTC Enforcement Process — Step by Step

### Step 1: Investigation (You May Not Know)
- CFTC Division of Enforcement opens investigation based on: tips, market surveillance, referrals from other agencies, news coverage
- **Formal Order of Investigation (OFI):** Grants staff subpoena power. You may not receive a copy initially.
- **Document requests/subpoenas:** Staff issues Civil Investigative Demands (CIDs) for documents; testimonial subpoenas for interviews
- CFTC can subpoena: exchanges (Coinbase, Kraken) for wallet-to-identity links, blockchain analytics firms, banks for financial records
- **Blockchain analytics:** Chainalysis, TRM Labs, Elliptic — these firms routinely provide data to CFTC and DOJ
- **Duration:** Investigations run 1-5 years before action is filed. You may be under investigation right now and not know.

**What to do if you receive a subpoena:**
1. Do NOT respond without counsel. Call a CFTC defense attorney within 24 hours.
2. Immediately implement a litigation hold — preserve ALL documents (email, Slack, Discord, Telegram, on-chain records, code repositories)
3. Do NOT destroy, alter, or delete any documents. Obstruction of justice (18 U.S.C. § 1519) is a federal crime — up to 20 years.
4. Do NOT tip off other witnesses about the investigation.

### Step 2: Wells Notice Equivalent (Pre-Enforcement)
- CFTC staff sends a letter stating they intend to recommend enforcement action
- Similar to SEC Wells notice: gives you the opportunity to respond
- **This is a CRITICAL moment** — your response can change the outcome
- Staff recommendations are not final — the full Commission votes on whether to authorize an action

**Wells/Pre-Enforcement Response strategy:**
- Hire a former CFTC enforcement attorney (they know the staff, the process, and what arguments work)
- Arguments to make: (a) your structure doesn't violate the CEA, (b) even if it does, you acted in good faith, (c) enforcement is disproportionate to the conduct, (d) you've already remediated
- Include: detailed legal analysis of your structure, evidence of good faith compliance efforts, written legal opinions you obtained before launch
- Offer to settle if you have significant exposure — early settlement terms are always better than post-litigation

### Step 3: Filing — Federal Court vs. Administrative

**Federal Court (Civil Action):**
- CFTC files complaint in U.S. District Court
- Full procedural protections: Article III judge, discovery rules, motion practice
- **Jury trial:** Post-*Jarkesy* (2024), you may have Seventh Amendment right to jury trial for civil penalties
- CFTC typically files in: S.D.N.Y. (most common for crypto), N.D. Ill. (Chicago, CFTC HQ), or district where violations occurred
- If you're an Iowa entity: push CFTC to file in S.D. Iowa where you can litigate on your home turf with the 8th Circuit on appeal

**Administrative Proceeding (ALJ):**
- CFTC brings proceeding before one of its own Administrative Law Judges
- **Critical weakness for respondents:** CFTC ALJs are employed by the CFTC — structural conflict of interest
- Post-*Jarkesy*: demand federal court proceedings when civil penalties are sought
- *Lucia v. SEC*, 585 U.S. 237 (2018): SEC ALJs are "Officers of the United States" subject to Appointments Clause — their appointments must be proper. CFTC ALJs face the same challenge.
- Discovery: more limited than federal court. Depositions harder to take.
- Timelines: faster (typically 14 months to ALJ decision) but less favorable for respondents

### Step 4: Consent Order (Settlement)
- The vast majority of CFTC cases settle. The agency has limited litigation resources.
- **Polymarket:** $1.4M fine, agreed to wind down US operations, no admit/no deny of findings — *CFTC Docket No. 22-09 (2022)*
- **BitMEX:** $100M fine, structural changes — *CFTC v. HDR Global Trading Ltd., No. 20-cv-8132 (S.D.N.Y.)*
- **Negotiation leverage:** How strong is CFTC's case? Cost of litigation to both sides? How high-profile is this?
- **What you can negotiate:**
  - Fine amount (dramatically different from initial demand)
  - Admit vs. no-admit/no-deny of wrongdoing (affects future civil litigation exposure)
  - Scope of injunction (what you can and cannot do going forward)
  - Compliance monitor vs. no monitor
  - Voluntary disgorgement amount

---

## SEC Enforcement Process

**Same general structure as CFTC with these differences:**

**Wells Notice process:**
- More formalized than CFTC; standard practice for SEC
- 30-day response period (can be extended)
- Submit written Wells submission: legal arguments + factual record + mitigating factors

**Post-*Jarkesy* impact:**
- *SEC v. Jarkesy*, 603 U.S. ___ (2024): defendants have Seventh Amendment right to jury trial when SEC seeks civil penalties for fraud-type claims
- **Demand jury trial in writing** if SEC files administrative proceeding for civil penalties
- SEC has begun filing more cases in federal court as a result

**SEC enforcement trends (2024-2026):**
- 2022-2024: aggressive crypto enforcement posture under Chair Gensler (resigned Jan. 2025)
- Post-2025: potential enforcement softening under new administration; watch for policy shifts
- Stay current: SEC enforcement releases at https://www.sec.gov/litigation/litreleases.htm

---

## State AG Enforcement

**Iowa AG (Iowa Department of Justice):**
- Enforces Iowa Consumer Fraud Act (§714.16) — no specific crypto enforcement history as of 2025
- Iowa AG has CID authority similar to federal agencies
- Less resource-intensive than federal enforcement — more likely to settle quickly
- Contact: www.iowaattorneygeneral.gov; 1305 E. Walnut St., Des Moines, IA 50319
- Proactive: introduce yourself to the Iowa AG's office before launching a novel product. They prefer engagement over surprise.

**New York AG:**
- Most aggressive state AG on crypto (sued Gemini, Genesis, DCG, KuCoin)
- *People v. Gemini Trust Co.* (2023): NYAG sued for fraud related to Gemini Earn
- If you have significant NY users: treat NYAG as seriously as SEC

**California AG:**
- Active on data privacy (CCPA enforcement) and consumer protection
- Less aggressive on crypto regulation specifically (deferred to SEC)

**Federal preemption argument against state AGs:**
- If you're registered as a CFTC DCM: argue that federal law preempts state enforcement
- If you're not registered: preemption argument is weaker; you're subject to both federal and state enforcement

---

## APA — The Administrative Procedure Act (5 U.S.C. §§ 551-706)

**Your primary legal tool for challenging agency action:**

**§706 — Grounds for overturning agency action:**
- Arbitrary, capricious, abuse of discretion — the most commonly used ground
- Contrary to constitutional right (First, Fourth, Fifth, Seventh Amendments)
- In excess of statutory authority
- Procedural violation

**Arbitrary and Capricious standard (*Motor Vehicle Manufacturers Assn. v. State Farm*, 463 U.S. 29 (1983)):**
- Agency must: examine relevant data, articulate a satisfactory explanation, consider important aspects of the problem, offer a rational connection between the facts and its conclusion
- **Kalshi used this:** CFTC's "public interest" determination was arbitrary and capricious — the court agreed
- **How to build this argument:** Document the CFTC's inconsistencies. Where have they approved similar contracts? Where have they allowed similar structures? Point to every inconsistency.

**Notice-and-Comment Rulemaking (§553):**
- Agencies must publish proposed rules, accept public comments, and respond to significant comments before finalizing
- If CFTC issues a rule without proper notice-and-comment: challenge it under the APA
- Emergency rules: agencies can sometimes skip notice-and-comment. Challenge whether the emergency justification was proper.

---

## Proactive Regulatory Engagement Strategy

### CFTC LabCFTC
- Contact: LabCFTC@cftc.gov
- Request a "TechAdvisory" meeting — informal staff meeting to discuss your business model
- This is NOT a legal opinion or no-action letter. But it gets you:
  - Staff's informal reaction to your structure
  - Information about what registration category they'd recommend
  - A record that you tried to engage proactively (useful in any later enforcement defense)
- Prepare: executive summary of your business model, legal analysis of why you believe you're compliant or what registration you're seeking

### CFTC No-Action Letter Request
- Filed with: Division of Market Oversight (most prediction market questions) or Division of Clearing and Risk
- Process: submit request, CFTC staff reviews, may request additional information, issues a no-action letter (or declines)
- Timeline: 3-12 months
- Cost: $20K-$50K in legal fees to prepare a proper request
- **Precedent:** CFTC Letter No. 14-130 (PredictIt, 2014) — the template. Read the full letter at https://www.cftc.gov/sites/default/files/idc/groups/public/@lrlettergeneral/documents/letter/14-130.pdf
- **Iowa angle:** The PredictIt no-action letter was granted for a market operated for an academic institution (Victoria University of Wellington). If Nick partners with the University of Iowa (which operates the Iowa Electronic Markets) → strongest possible argument for a similar no-action letter.

### FinCEN Requests
- FinCEN Business Line: request an administrative ruling on whether your activity constitutes money transmission
- Much slower and less responsive than CFTC LabCFTC
- Better approach: get a written legal opinion from AML counsel on your specific architecture

---

## How to Prepare BEFORE Enforcement

**Document your compliance analysis (this is your criminal defense):**
1. Written legal opinion from qualified counsel BEFORE launch (CFTC-specialized attorney)
2. Internal compliance memo describing your analysis and conclusions
3. All regulatory engagement records (LabCFTC meeting notes, any informal guidance)
4. State registration records
5. AML program documentation
6. TOS, privacy policy, geo-blocking implementation records

**Budget for enforcement defense:**
- Initial subpoena response: $50K-$100K
- Full federal court litigation: $1M-$5M
- Administrative proceeding: $200K-$500K
- Settlement: fine + legal fees (often comparable to litigation)
- **Cyber insurance / D&O insurance may cover some legal fees** — see insurance skill

**Maintain a pre-negotiated relationship with an enforcement defense firm:**
- When you receive a subpoena: you should already know who to call
- Recommended firm types: former CFTC enforcement staff (they know the staff, the playbook), crypto-specialized litigation firms
- Examples: K&L Gates (crypto regulatory), Willkie Farr & Gallagher (CFTC defense), Debevoise & Plimpton (SEC defense)

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
