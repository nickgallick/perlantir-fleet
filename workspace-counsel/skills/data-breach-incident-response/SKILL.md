# SKILL: Data Breach / Incident Response Legal Protocol

## Purpose
Execute the legal response to a data breach or security incident in the first 72 hours and beyond. Covers state breach notification laws, federal obligations, regulatory notifications, user communications, and liability mitigation.

## Risk Level
🔴 High — Every US state has breach notification laws. Late or defective notification triggers regulatory fines and private lawsuits. A breach that is handled well (fast, transparent, complete) can be survivable. A breach that is mishandled can destroy the company.

---

## Immediate Response Timeline

### First Hour: Contain and Assess
- [ ] Contain the breach: isolate affected systems, revoke compromised credentials
- [ ] Preserve evidence: do NOT delete logs; snapshot affected systems before remediation
- [ ] Identify scope: what data, how many users, which states, what type of data
- [ ] Convene incident response team: CTO + legal + CEO minimum
- [ ] Engage outside counsel: attorney-client privilege protects investigation communications
- [ ] Document everything: timestamps, actions taken, decisions made

### Hours 1–24: Legal Assessment
- [ ] Identify what type of data was exposed (see Data Classification below)
- [ ] Map affected users to states of residence (triggers state notification laws)
- [ ] Check federal regulatory notification obligations (CFTC, FinCEN, FTC)
- [ ] Identify whether law enforcement notification is required or appropriate
- [ ] Assess whether breach is "reportable" under each applicable state law

### Hours 24–72: Notifications Begin
- [ ] User notifications (if required — check state law timing)
- [ ] State AG notifications (where required — varies by state)
- [ ] Federal regulator notifications (where required)
- [ ] Law enforcement notification (FBI IC3 if financial data; optional but recommended)
- [ ] Prepare public statement (if breach is or will become public)
- [ ] Engage cybersecurity forensics firm (Mandiant, CrowdStrike, etc.)

---

## Data Classification — What Was Exposed?

Risk level and notification obligations depend on data type:

### Tier 1: Maximum Risk — Notify Immediately
- Social Security Numbers (SSN)
- Government-issued ID numbers (driver's license, passport)
- Financial account numbers + access credentials
- Payment card numbers (PCI DSS scope)
- Medical/health information (HIPAA scope)
- **Biometric data** (liveness check photos, fingerprints)
- Usernames + passwords in plaintext

### Tier 2: High Risk — Notify Within Applicable Deadline
- Name + email + phone combination
- Name + address + DOB combination
- Tax identification numbers (ITIN, EIN)
- KYC verification data (ID document images)
- Transaction history + prize amounts (financial data)

### Tier 3: Medium Risk — Assess Notification Requirement
- Email addresses alone (most states: not a standalone trigger)
- Username without password
- Anonymized betting/contest data

### Tier 4: Low Risk — Likely No Notification Required
- Publicly available information
- Aggregated, de-identified data
- IP addresses alone (some states include, most don't)

---

## State Breach Notification Laws

### Universal Requirements
**All 50 states + DC + Puerto Rico + USVI** have breach notification laws. Key commonalities:
- Notice must be "expedient" or within a specified timeframe
- Must notify affected individuals AND state AG (in most states)
- Must specify what data was exposed
- Must provide recommended protective measures

### States with Strictest Requirements (Must Know)

**California (CCPA + California Breach Notification — CA Civ. Code § 1798.82)**:
- Timeline: "Expedient time" — in practice, 45 days is the expected standard
- AG notification: If >500 California residents affected
- Content: Specific required elements in notification
- Private right of action: YES — $100–$750 per consumer per incident

**New York (SHIELD Act — N.Y. Gen. Bus. Law § 899-aa)**:
- Timeline: "Expedient time" without unreasonable delay
- AG notification: If New York residents affected (no threshold)
- Most stringent definition of "private information" — includes biometrics, username + security Q&A

**Texas (Texas Bus. & Com. Code § 521.053)**:
- Timeline: 60 days from discovery
- AG notification: If >250 Texas residents affected

**Colorado (C.R.S. § 6-1-716)**:
- Timeline: **30 days** — one of shortest in US
- AG notification: If >500 Colorado residents affected
- Also notify credit reporting agencies if >1,000 residents affected

**Florida (Florida Statutes § 501.171)**:
- Timeline: **30 days** for most breaches
- AG notification: If >500 Florida residents affected
- Fines: Up to $500,000 for failure to notify

**Iowa (Iowa Code § 715C)**:
- Timeline: Expedient time, no specified maximum
- AG notification: Required (Iowa AG breach notification portal)
- Scope: "Personal information" = name + SSN, financial account number, driver's license, or username + password
- Iowa AG: https://iowaattorneygeneral.gov/for-consumers/consumer-protection/data-breach-notification
- **Iowa-specific**: As Iowa-based company, Iowa AG notification is first priority

**Washington (RCW 19.255.010)**:
- Timeline: 30 days
- AG notification: If >500 Washington residents — but note you should have Washington geo-blocked

### Fastest Notification Requirements Summary
| State | Deadline | AG Threshold |
|-------|----------|--------------|
| Colorado | 30 days | >500 residents |
| Florida | 30 days | >500 residents |
| Washington | 30 days | >500 residents |
| New York | Expedient | Any |
| Iowa | Expedient | Any |
| California | 45 days (practical) | >500 residents |
| Texas | 60 days | >250 residents |

---

## Federal Notification Obligations

### FTC (Safeguards Rule — 16 CFR Part 314)
- **Who it applies to**: "Financial institutions" under GLB Act — fintech/prediction market platforms handling financial data likely qualify
- **What's required**: Notify FTC within **30 days** if security event affects >500 consumers
- **Filing**: FTC online portal (implemented in 2023)
- **New rule**: FTC Safeguards Rule updated in 2023; covers "non-bank financial institutions"

### FinCEN / BSA
- No specific breach notification statute for MSBs
- BUT: Material security incident affecting BSA records must be reported in SAR if it involves suspected money laundering
- Practical: Notify FinCEN via SAR if breach compromises AML/KYC data

### CFTC (If DCM-Registered)
- DCM Core Principle 7: Must notify CFTC of "any material event" that affects operations
- Security breach affecting user funds or trading data = reportable
- No specific timeline stated; reasonable standard applies
- Contact: DMO@cftc.gov

### SEC (If Securities-Related)
- Cybersecurity Incident Disclosure Rules (adopted 2023): Public companies must disclose material cybersecurity incidents within **4 business days** on Form 8-K
- Private companies (Nick's situation): SEC rules don't apply directly; but if seeking investment, disclosure to investors required

---

## User Notification Content (Required Elements)

Most state laws require notification to include:

1. **Description of the incident**: What happened, when discovered
2. **Data exposed**: What specific types of personal information were involved
3. **What you're doing**: Steps taken to address the breach, protect users
4. **What users can do**: Recommended protective steps (credit freeze, password change, etc.)
5. **Contact information**: Who users can call/email with questions
6. **Credit monitoring offer**: Best practice; required in some states for SSN breaches
7. **Identity theft resources**: FTC IdentityTheft.gov; 1-877-ID-THEFT

**Template breach notice structure**:
```
Subject: Important Security Notice Regarding Your [Platform] Account

Dear [User],

We are writing to inform you of a security incident that may have affected your 
[Platform] account. On [date], we discovered that [description of incident]. 
We immediately [actions taken to contain].

What information was involved: [specific data types]

What we are doing: [remediation steps, security improvements]

What you can do: [change password, monitor accounts, credit freeze instructions]

We sincerely apologize for this incident. Your security is our highest priority.

For questions, contact: [email/phone]
```

---

## Attorney-Client Privilege Protection

**Critical**: Communications about the breach investigation should go through outside legal counsel to preserve privilege.

- Hire outside counsel BEFORE conducting internal breach investigation
- Investigation should be conducted "at the direction of counsel"
- Internal reports should be addressed to legal counsel (not directly to engineering)
- Do NOT put breach details in Slack/email without privilege protection
- Privilege does NOT cover: notices sent to regulators or users; operational documents

**Why this matters**: In litigation, plaintiff's counsel will seek all internal breach communications. Privileged communications are protected from discovery.

---

## Insurance Coverage — Know What You Have

### Cyber Liability Insurance
- Covers: Breach notification costs, credit monitoring, forensic investigation, legal fees, regulatory fines (some), third-party liability
- **Check your policy NOW** — don't wait for a breach
- Typical coverage: $1M–$10M for early-stage SaaS
- Providers: Coalition, Corvus, At-Bay (startup-friendly cyber insurers)

### Notification Requirements to Insurer
- Most cyber policies require notification **within 24–72 hours** of breach discovery
- Failure to timely notify insurer = coverage denial
- **Day 1 action**: Notify your cyber insurer simultaneously with starting internal response

---

## Liability Mitigation Checklist

Before a breach happens (proactive):
- [ ] Data minimization: Don't collect data you don't need; delete data you no longer need
- [ ] Encryption at rest: PII, financial data, KYC documents
- [ ] Access controls: Minimum necessary access; no engineer has prod database admin
- [ ] Incident response plan: Written, tested, accessible
- [ ] Cyber insurance: In place before launch
- [ ] Vendor due diligence: SOC 2 Type II from all data processors
- [ ] Privacy policy: Accurate description of data practices (FTC liability if wrong)

---

## Iowa Breach Notification Specifics

**Iowa Code § 715C.2**: Notification required when:
- Unauthorized acquisition of "personal information" likely to cause loss or injury to Iowa residents
- "Personal information" = name + (SSN, driver's license number, financial account number, or username + security Q&A)

**Iowa AG notification**: Required; no specific threshold
- Iowa AG Breach Portal: https://iowaattorneygeneral.gov/for-consumers/consumer-protection/data-breach-notification
- Iowa AG contact: 515-281-5926

**Iowa timeline**: "Expedient time" without unreasonable delay — aim for 45 days maximum

**Iowa-specific safe harbor**: No safe harbor in Iowa for encrypted data (unlike some states); if data was encrypted, still notify if keys were also exposed

---

## Quick Reference Card

```
FIRST HOUR:
1. Contain breach
2. Preserve evidence  
3. Call outside counsel (privilege protection)
4. Notify cyber insurer

WITHIN 24 HOURS:
5. Scope assessment (data type + states)
6. Legal assessment (notification required?)
7. Forensics firm engaged

WITHIN 30 DAYS (hardest deadline):
8. User notifications
9. Colorado/Florida/Washington AG notifications
10. FTC Safeguards Rule notification (if >500 affected)
11. Iowa AG notification

ONGOING:
12. Document everything
13. Cooperate with regulators
14. Credit monitoring for affected users
```

---

## Key Resources
- FTC Safeguards Rule: https://www.ftc.gov/business-guidance/privacy-security/gramm-leach-bliley-act/safeguards-rule
- Iowa AG breach notification: https://iowaattorneygeneral.gov/for-consumers/consumer-protection/data-breach-notification
- FTC breach notification portal: https://www.ftc.gov/datasecurity
- Multi-state breach notification tracker: https://www.ncsl.org/research/telecommunications-and-information-technology/security-breach-notification-laws.aspx
- FBI IC3 (internet crime reporting): https://ic3.gov

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
