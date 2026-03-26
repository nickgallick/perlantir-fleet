# SKILL: White Collar Criminal Exposure — The Lines You Never Cross
**Version:** 1.0.0 | **Domain:** Federal Criminal Law, Fraud, Money Laundering, Tax

---

## The Fundamental Distinction: Civil vs. Criminal

**Civil violations:** Fines, disgorgement, injunctions, registration requirements. The company (and sometimes officers) pay money and change behavior.

**Criminal violations:** Federal prison. Forfeiture of ALL assets. Reputational destruction. The CEO personally goes to prison.

**The word that separates them: WILLFULLY**

Most federal criminal statutes require that you **KNOWINGLY and WILLFULLY** violated the law. This is why written legal opinions from qualified counsel are your most important asset — they establish that you acted in good faith, not with criminal intent.

---

## Wire Fraud — 18 U.S.C. § 1343

**Elements:**
1. A scheme or artifice to defraud (or to obtain money/property by false pretenses)
2. Use of wire communications (internet, email, phone) to execute it
3. Intent to defraud

**Penalty:** Up to **20 years per count** + forfeiture + fines

**Why every crypto prosecution includes this charge:**
- Anything done online automatically meets the wire communications element
- "Scheme to defraud" is interpreted extremely broadly by federal prosecutors
- Each communication can be a separate count → 20 charges = 400 years exposure

**What triggers wire fraud in crypto:**
- ❌ Claiming your platform is "fully regulated" or "CFTC-approved" when it's not
- ❌ Fabricating trading volume or liquidity ("wash trading")
- ❌ Making promises about returns that you know are false
- ❌ Misrepresenting your team's background or credentials
- ❌ Operating a rug pull (collecting user funds with no intent to deliver the product)
- ❌ Making material misrepresentations in marketing materials
- ❌ Telling investors the company is profitable when you know it's not

**What does NOT trigger wire fraud (if done with good faith):**
- ✅ Launching a novel product with genuine uncertainty about regulatory classification
- ✅ Making business projections that turn out to be wrong (forward-looking statements with disclaimers)
- ✅ Building a product that fails or loses user funds due to market conditions or bugs (not fraud, assuming you disclosed risks)

**Practical rule:** NEVER put anything in writing — email, Slack, Telegram, Discord — that could be read as promising something you can't deliver or misrepresenting something material.

---

## Money Laundering — 18 U.S.C. § 1956

**Elements (Section 1956(a)(1)):**
1. Financial transaction
2. Involving proceeds of "specified unlawful activity" (SUA)
3. With knowledge that the property represents proceeds of some unlawful activity
4. AND one of: intent to promote the SUA, intent to conceal the origin, or intent to evade taxes

**Penalty:** Up to **20 years per count** + forfeiture of all laundered property

**The "specified unlawful activities" list (18 U.S.C. § 1956(c)(7)) includes:**
- Wire fraud, bank fraud, securities fraud
- Drug trafficking
- Computer fraud (hacking)
- Any felony under state law

**How this hits crypto platforms:**
- If your platform knowingly accepts funds from drug traffickers, hackers, or fraudsters → money laundering, even if you didn't commit the underlying crime
- "Knowing" is established if you SHOULD have known (deliberate ignorance doctrine) → why AML/KYC is critical
- Tornado Cash: OFAC sanctioned it; now interacting with it is potentially money laundering because the proceeds are from sanctioned activity

**Structuring ("smurfing") — 31 U.S.C. § 5324:**
- Breaking up transactions specifically to avoid the $10K CTR reporting threshold
- Penalty: up to 10 years. No intent to launder needed — just intent to evade reporting.
- Don't structure transactions. If a user sends $9,500 repeatedly to avoid a $10K report, file a SAR and tell them to stop.

---

## Operating Unlicensed Money Transmitting Business — 18 U.S.C. § 1960

**Elements:**
1. Conducting a money transmitting business
2. Without a state license (where required)
3. OR knowing the business was used to promote unlawful activity

**Penalty:** Up to **5 years**

**Why this is more dangerous than people think:**
- It does NOT require intent to commit money laundering or fraud — just operating without a license
- The government doesn't need to prove you knew you needed a license (in some circuits)
- *United States v. Murgio*: Bitcoin exchange operator convicted under § 1960

**Key cases:**
- *United States v. Harmon* (Bitcoin Fog): Roman Sterlingov sentenced to **12.5 years** for operating Bitcoin Fog as an unlicensed money transmitting business + money laundering. He didn't steal from users — he just operated the service without a license.
- *United States v. Costanzo* (LocalBitcoins): informal Bitcoin exchange operator convicted of § 1960
- *Roman Storm* (Tornado Cash developer): indicted under § 1960 for writing code that became an unlicensed money transmitting business — THE defining case for non-custodial developers. Defense: writing code is not "operating" a money transmitting business.

**Protection:**
- Non-custodial architecture: strongest legal argument that you're not operating a money transmitting business
- FinCEN registration: if you ARE a money transmitter, register immediately. Unregistered is the crime. Registered is compliance.
- Written legal opinion: establishes good faith

---

## Securities Fraud — 15 U.S.C. § 78j(b) + Rule 10b-5

**Elements:**
1. A security (token, stock, investment contract)
2. Material misstatement or omission
3. In connection with the purchase or sale of a security
4. Intent to defraud (scienter)
5. Reliance by the victim
6. Economic harm

**Penalty:** Up to **20 years** + criminal forfeiture

**What triggers securities fraud in crypto:**
- ❌ Making false statements about your token's utility, adoption, or team
- ❌ Insider trading (selling your own tokens on non-public information that the price will crash)
- ❌ Wash trading to create fake volume for your token
- ❌ Coordinated pump-and-dump schemes
- ❌ "Rug pulls" where founders sell all tokens after raising

**The *Do Kwon* lesson:** Creating a token that collapses due to flawed tokenomics is NOT by itself fraud. Creating a token you know will collapse while telling investors it's safe = fraud. The distinction is what you KNEW and what you SAID.

---

## Tax Evasion — 26 U.S.C. § 7201

**Elements:**
1. Tax deficiency (you owed taxes)
2. Affirmative act of evasion (filing false returns, hiding income, structuring)
3. Willfulness (knowing and intentional violation)

**Penalty:** Up to **5 years per count** + full repayment of taxes, penalties, and interest

**Offshore structure ≠ tax evasion if done correctly:**
- A properly structured foreign entity with documented business reasons + proper FBAR/FATCA reporting = legal
- An offshore entity created SOLELY to hide income from the IRS + no FBAR filing = tax evasion

**Crypto-specific IRS enforcement:**
- IRS Criminal Investigation (IRS-CI) has a dedicated crypto unit
- They traced Silk Road Bitcoin, identified the Colonial Pipeline attackers from Bitcoin transactions, and recovered billions in crypto
- The IRS can see your blockchain activity. Assume they can match your wallet to your identity.
- FBAR (FinCEN 114): required for foreign accounts >$10K in aggregate. This INCLUDES crypto held on foreign exchanges.
- Failure to file FBAR: civil penalties up to 50% of account value per year; criminal penalties up to $500K + 10 years.

---

## The "Advice of Counsel" Defense

**How it works:** If you rely on a written legal opinion from qualified counsel who had full knowledge of the facts, you have a complete or partial defense to any criminal charge requiring "willfulness."

**Requirements for the defense to work:**
1. The attorney was **qualified** in the relevant area (not just any lawyer — a crypto regulatory specialist)
2. You provided **complete and accurate information** (no hiding facts from counsel)
3. The opinion was **in writing** (verbal advice is almost impossible to prove)
4. You **actually followed** the advice
5. You relied on it **before** engaging in the conduct (not after)

**What this means practically:**
- Get a written legal opinion from a CFTC-specialized attorney before launching any prediction market or competition platform with real money
- Get a written legal opinion from an AML attorney before operating any platform that processes user funds
- Get a written legal opinion from a securities attorney before any token launch
- These opinions cost $10K-$50K each. They are your criminal defense.

---

## Career-Ending Red Lines (Summary)

| Action | Criminal Statute | Prison |
|---|---|---|
| Lie about regulatory status in marketing | Wire Fraud (§1343) | 20 years/count |
| Fake trading volume / wash trade | Wire Fraud + Securities Fraud | 20 years/count |
| Accept known criminal proceeds | Money Laundering (§1956) | 20 years/count |
| Break up transactions to avoid reporting | Structuring (§5324) | 10 years |
| Operate money transmitter without license | §1960 | 5 years |
| Sell unregistered securities with fraud | Securities Fraud (§78j) | 20 years |
| Hide offshore income from IRS | Tax Evasion (§7201) | 5 years/count |
| Destroy documents after subpoena | Obstruction (§1519) | 20 years |

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
