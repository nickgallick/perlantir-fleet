# SKILL 65: Regulatory Reporting & Compliance Calendar

## Purpose
Know every filing you must make, to which agency, by which date, and what triggers each obligation. Missing a filing is a violation even if your underlying conduct is compliant.

## Federal Filings

### FinCEN (If MSB — Money Services Business)
| Filing | Trigger | Deadline | Method |
|--------|---------|----------|--------|
| Form 107 (MSB Registration) | Within 180 days of establishing MSB activities | Day 180 | BSA E-Filing (bsaefiling.fincen.treas.gov) |
| MSB Re-registration | Change in location, ownership, or services | Within 180 days of change | BSA E-Filing |
| MSB Renewal | Every 2 years | Before expiration | BSA E-Filing |
| SAR (Suspicious Activity Report) | Detect suspicious activity ≥$2,000 (for MSBs) | Within 30 days of detection (60 if suspect unknown) | BSA E-Filing |
| CTR (Currency Transaction Report) | Cash transaction >$10,000 | By next business day | BSA E-Filing |

### IRS
| Filing | Trigger | Deadline |
|--------|---------|----------|
| 1099-MISC (to recipient) | User wins >$600 in year | January 31 of following year |
| 1099-MISC (to IRS) | Same | February 28 (paper) / March 31 (electronic) |
| W-2 | Employees | January 31 |
| 1120 (C-Corp tax return) | Annually | April 15 (or extended to October 15) |
| Estimated tax payments | Quarterly | April 15, June 15, September 15, January 15 |
| FBAR (FinCEN 114) | Foreign accounts >$10,000 at any time | April 15 (extended to October 15) |
| Form 8938 (FATCA) | Foreign financial assets above threshold | With tax return |

### OFAC
| Obligation | Frequency | Notes |
|-----------|-----------|-------|
| SDN list check (wallet addresses) | Every transaction | Chainalysis Sanctions Oracle or equivalent |
| SDN list updates | Daily | List updates; re-screen all active users monthly |
| Blocked transaction report | Within 10 business days of blocking | If you block a sanctioned user's transaction |

### BIS (Export Controls)
| Filing | Trigger | Notes |
|--------|---------|-------|
| TSU notification (encryption) | Before first export of public crypto code | Email to crypt@bis.doc.gov + enc@nsa.gov |
| No filing for API users | Using Anthropic/OpenAI APIs | They handle their export compliance |

## State Filings

### Iowa
| Filing | Agency | Deadline | Cost |
|--------|--------|----------|------|
| Annual report (LLC) | Iowa SOS | During anniversary month | $60 |
| State income tax return (IA 1120 or pass-through) | Iowa DOR | April 30 | — |
| Skill-based competition registration (if required) | Iowa DIA | Before operating | TBD by DIA |
| Sales tax registration | Iowa DOR | Before first taxable transaction | Free |

### Other States (Registered States)
- Annual reports: in each state where you're registered
- State income tax: in each state with tax nexus (employees, servers, revenue sourcing)
- Foreign qualification: required in each state where you're "doing business"

## Compliance Calendar (Master)

```
JANUARY
  Jan 31: 1099-MISC to recipients
  Jan 31: W-2 to employees

FEBRUARY
  Feb 28: 1099-MISC to IRS (paper); Mar 31 if electronic

MARCH
  Mar 15: S-Corp/Partnership tax return (if applicable)

APRIL
  Apr 15: C-Corp tax return / Individual (+ FBAR deadline)
  Apr 15: Q1 estimated tax payment
  [Anniversary month]: Iowa annual report

JUNE
  Jun 15: Q2 estimated tax payment

SEPTEMBER
  Sep 15: Q3 estimated tax payment

OCTOBER
  Oct 15: Tax return extended deadline (if extended)

NOVEMBER
  [Check: MSB renewal date — renew before expiration]

DECEMBER
  Dec 31: Year-end review — confirm all filings current

ONGOING (monthly)
  - SAR: within 30 days of detection
  - OFAC screening: daily list updates; monthly re-screen of active users
  - State compliance monitoring: legislation and AG action alerts
  - Surveillance records: maintained continuously, 5-year retention

ONGOING (quarterly)
  - Estimated tax payments
  - Proof of reserves (if custodial)
  - Outside counsel check-in: regulatory developments update
```

## Record Retention Requirements
| Record Type | Retention Period | Notes |
|------------|-----------------|-------|
| SAR records | 5 years | From date of filing |
| Transaction records | 5 years | FinCEN requirement for MSBs |
| KYC/AML records | 5 years | From relationship termination |
| Market surveillance records | 5 years | Best practice even if not required |
| Contract/TOS | Indefinitely | Plus 7 years after last relevant dispute |
| Tax records | 7 years | IRS audit window |
| Privileged documents | Indefinitely | Until resolution of related matters |
| Corporate records | Indefinitely | |

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
