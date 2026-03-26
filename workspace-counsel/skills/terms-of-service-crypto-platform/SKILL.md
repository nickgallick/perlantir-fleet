# SKILL: Terms of Service & Legal Documents for Crypto/Competition Platforms
**Version:** 1.0.0 | **Domain:** Contract Law, Consumer Protection, Platform Compliance

---

## Terms of Service: Critical Clauses

### 1. Arbitration Clause (MUST BE PROMINENT)
```
BINDING ARBITRATION NOTICE: ALL DISPUTES ARISING OUT OF OR RELATED TO 
THIS AGREEMENT SHALL BE RESOLVED BY BINDING INDIVIDUAL ARBITRATION 
ADMINISTERED BY [JAMS/AAA] UNDER ITS CONSUMER ARBITRATION RULES. 
YOU WAIVE YOUR RIGHT TO A JURY TRIAL AND YOUR RIGHT TO PARTICIPATE 
IN ANY CLASS ACTION OR REPRESENTATIVE PROCEEDING.
```
- **Why:** Protects against class action lawsuits; enforced under FAA if properly disclosed
- **Requirement:** Must be conspicuous — buried TOS do NOT hold up (*Berkson v. Gogo*, *Nguyen v. Barnes & Noble*)
- **Venue:** Neutral venue (Delaware or NYC for arbitration proceedings)
- **Exception carve-out:** Small claims court exception (required for FTC compliance)

### 2. Geographic Restrictions Clause

**Model Language — Covers All 50 States:**
```
Geographic Restrictions. The Services are not available to persons 
located in the following jurisdictions: Washington, Arizona, Louisiana, 
Montana, and such other jurisdictions as may be designated from time 
to time on our Restricted Jurisdictions list available at [URL]. 

By accessing the Services, you represent and warrant that you are not 
located in, and are not a citizen or resident of, any Restricted 
Jurisdiction. If we determine that you have provided false information 
regarding your location, we reserve the right to immediately terminate 
your account, forfeit any pending prizes or balances, and take any 
other action permitted by law.

Your representation regarding your location is a material term of 
this Agreement. We reserve the right to require additional verification 
of your location at any time and to update the Restricted Jurisdictions 
list without prior notice. It is your responsibility to monitor for 
changes to the Restricted Jurisdictions list.
```

**Implementation requirement:** Maintain live Restricted Jurisdictions page at a static URL; document every change with date.

### 3. Risk Disclosures

**Crypto Asset Risks:**
```
Digital Asset Risk. The value of digital assets, including any digital 
assets used on the Platform, can fluctuate significantly and may 
decrease to zero. You acknowledge that you may lose all funds 
associated with your account. Past performance does not guarantee 
future results.

Smart Contract Risk. The Platform operates using smart contracts deployed 
on public blockchains. Smart contracts may contain bugs, errors, or 
vulnerabilities that could result in the partial or complete loss of 
your funds. The Platform does not guarantee the security or functionality 
of any smart contract.

Regulatory Risk. The regulatory status of digital assets and 
prediction markets is unsettled and subject to change. Regulatory 
actions may affect the availability or functionality of the Platform 
in your jurisdiction without notice.
```

**Competition/Skill Risk:**
```
Competition Risk. Entry fees paid to participate in contests are 
non-refundable except as expressly provided in these Terms. 
Participation in contests does not guarantee any prize. Skill-based 
competition results depend on many factors, including the skill and 
judgment of participants and AI model performance.
```

### 4. User Representations (Compliance Checklist)
```
By accessing the Platform, you represent and warrant that:
(a) you are at least 18 years of age (or the age of majority in 
    your jurisdiction, if higher);
(b) you are not located in a Restricted Jurisdiction;
(c) you are not a person or entity subject to sanctions administered 
    by OFAC, the EU, or the UN Security Council;
(d) all funds used on the Platform are derived from lawful sources;
(e) you understand and accept the risks described in these Terms;
(f) your participation in contests complies with all laws applicable 
    to you in your jurisdiction;
(g) you are not acting as an agent for any third party in using 
    the Platform.
```

### 5. Not Investment/Legal/Financial Advice
```
No Advice. Nothing on the Platform constitutes investment advice, 
financial advice, trading advice, legal advice, or any other form 
of professional advice. The Platform does not recommend that any 
digital asset should be bought, sold, or held. You should conduct 
your own due diligence and consult your advisors before making 
any decisions.
```

### 6. Limitation of Liability
```
LIMITATION OF LIABILITY. TO THE MAXIMUM EXTENT PERMITTED BY 
APPLICABLE LAW, [COMPANY]'S AGGREGATE LIABILITY TO YOU FOR ANY 
CLAIM ARISING OUT OF OR RELATED TO THIS AGREEMENT SHALL NOT EXCEED 
THE TOTAL AMOUNT DEPOSITED BY YOU ON THE PLATFORM DURING THE 
12-MONTH PERIOD IMMEDIATELY PRECEDING THE CLAIM.

[COMPANY] SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, 
CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, 
OR GOODWILL, ARISING FROM: (i) SMART CONTRACT BUGS OR FAILURES; 
(ii) BLOCKCHAIN NETWORK FAILURES OR DELAYS; (iii) REGULATORY CHANGES; 
(iv) THIRD-PARTY SERVICE FAILURES; (v) CYBERATTACKS OR UNAUTHORIZED 
ACCESS TO SMART CONTRACTS.
```

### 7. Intellectual Property
```
Platform IP. The Platform, including all software, designs, content, 
trademarks, and brand assets, are owned by [Company] or its licensors. 
You receive a limited, non-exclusive, non-transferable license to 
access the Platform for personal, non-commercial use.

AI-Generated Content. Predictions and analyses generated by AI models 
on the Platform are the property of [Company]. No AI-generated output 
on the Platform constitutes financial advice or a guarantee of accuracy.

Open-Source Acknowledgment. Certain components of the Platform use 
open-source software licensed under the terms specified at [URL].
```

---

## Privacy Policy: Critical Elements

### Data Collected
- Wallet addresses (public by blockchain design — disclose this)
- KYC data if applicable (name, government ID, address)
- Usage data: IP address, device info, browsing behavior, session data
- Transaction history on the platform
- Communications (support tickets, dispute records)

### Data Sharing Disclosure
- Law enforcement: "We may disclose data in response to valid legal process, including court orders, subpoenas, and law enforcement requests"
- Blockchain transparency: "Transactions on public blockchains are inherently visible to anyone. We cannot make blockchain transactions private."
- Analytics providers: anonymized usage data only
- NEVER sell KYC/identity data to third parties

### GDPR Requirements (EU Users)
- Right to access, rectification, erasure, portability
- Lawful basis for each processing activity (contract performance, legitimate interest, consent)
- Data Protection Officer designation (if processing at scale)
- Cross-border transfer safeguards (Standard Contractual Clauses if transferring EU data to US)
- 72-hour breach notification requirement

### CCPA Requirements (California Users)
- Right to know, right to delete, right to opt-out of sale
- "Do Not Sell My Personal Information" link required
- Categories of personal information collected: list all categories
- Annual privacy reporting if >100K California users

---

## Responsible Gaming / Responsible Participation Disclosures

**Include these even if not legally required — shows regulators good faith:**

```
Responsible Participation. We are committed to safe and responsible 
participation. You may:
• Set daily, weekly, or monthly deposit limits in your account settings
• Set a maximum loss threshold
• Request a cooling-off period (24 hours, 7 days, or 30 days)
• Request permanent self-exclusion from the Platform

If you believe you have a problem with gambling or compulsive spending, 
please contact:
• National Council on Problem Gambling: 1-800-522-4700
• National Problem Gambling Helpline: ncpgambling.org/help-treatment/

By creating an account, you confirm that you are participating for 
entertainment purposes and can afford any potential losses.
```

---

## DMCA Policy
```
Copyright Policy. [Company] respects intellectual property rights. 
To submit a DMCA takedown notice:
• Email: [copyright@company.com]
• Include: identification of copyrighted work, identification of 
  infringing material, your contact information, statement of good 
  faith belief, statement of accuracy under penalty of perjury, 
  physical or electronic signature.
Counter-notices: [address per 17 U.S.C. § 512(g)]
```

---

## TOS Implementation Requirements

1. **Clickwrap (not browsewrap):** User must affirmatively click "I Agree" — do NOT use passive "by using this site you agree" language
2. **Version control:** Timestamp every TOS version; log which version each user agreed to
3. **Change notification:** Email users 30 days before material changes; maintain TOS changelog
4. **Accessibility:** Plain language summary alongside legal text
5. **Mobile display:** TOS must be readable on mobile before account creation is complete

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
