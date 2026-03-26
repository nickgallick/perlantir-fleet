---
name: threat-modeling
description: Adversarial security review — think like an attacker to find exploit chains that checklists miss.
---

# Threat Modeling Protocol

## Mindset Shift
Checklist reviewing asks: "Does this code follow best practices?"
Threat modeling asks: "If I wanted to steal data, steal money, crash the system, or escalate privileges — how would I use this code to do it?"

This is a fundamentally different lens. Apply it AFTER the standard 8-point review, as a 9th phase.

## The 5 Attack Personas

For every piece of code, think through these attacker types:

### 1. The Outsider (unauthenticated)
- Can I access this endpoint without logging in?
- Can I enumerate resources (user IDs, account numbers)?
- Can I cause a denial of service (infinite loops, memory bombs, disk fills)?
- Can I inject malicious content that other users will see (XSS, stored injection)?

### 2. The Insider (authenticated, low privilege)
- Can I access other users' data by changing IDs in requests?
- Can I escalate my role (change myself to admin)?
- Can I perform actions outside my permission level?
- Can I manipulate my own data in ways that affect others?

### 3. The Race Condition Exploiter
- Can I fire the same request twice and get double the effect?
- Can I exploit time-of-check to time-of-use gaps?
- Can I interleave requests to create impossible states?
- Is there a window between validation and execution I can exploit?

### 4. The Data Poisoner
- Can I submit data that breaks other users' experience?
- Can I submit extremely large inputs to consume storage or memory?
- Can I submit data that will cause errors when OTHER code processes it later?
- Can I manipulate cached data to affect other users?

### 5. The Reconnaissance Agent
- What can I learn about the system from error messages?
- What internal structure is revealed by API responses?
- Can I map the database schema from the API surface?
- Are there timing differences that reveal existence of resources?

## Exploit Chain Analysis
Don't just find individual issues — think about how they COMBINE:
- Weak validation + no rate limiting = automated account enumeration
- Missing ownership check + predictable IDs = mass data exfiltration
- Race condition + financial operation = double-spending
- XSS + admin panel = full account takeover chain

## Threat Model Output Format
Add this section to reviews when threats are found:

### Threat Model

**Attack surface:** [What's exposed]
**Highest-risk scenario:** [The worst thing an attacker could do with this code]
**Exploit chain:** [Step-by-step how they'd do it]
**Likelihood:** [Low/Medium/High — based on how easy the exploit is]
**Impact:** [Low/Medium/High/Critical — based on what they'd gain]
**Risk score:** [Likelihood × Impact]

## STRIDE Framework (for architecture-level reviews)
When reviewing entire systems or features, apply STRIDE:
- **S**poofing — Can someone pretend to be someone else?
- **T**ampering — Can someone modify data they shouldn't?
- **R**epudiation — Can someone deny they performed an action?
- **I**nformation Disclosure — Can someone see data they shouldn't?
- **D**enial of Service — Can someone break the system for others?
- **E**levation of Privilege — Can someone gain higher access?

## Financial Code Special Rules
For any code handling money, balances, transactions, or payments:
- ALWAYS model the double-spend attack
- ALWAYS check for negative amount exploits
- ALWAYS verify atomic transactions (no partial state)
- ALWAYS check integer overflow/underflow on balances
- ALWAYS verify idempotency (what if the same request runs twice?)
- ALWAYS check for floating point precision issues with currency

## API Endpoint Special Rules
For every API endpoint:
- What happens if I send 1000 requests per second?
- What happens if I send a 100MB request body?
- What happens if I send valid auth but with someone else's resource ID?
- What happens if I replay a previous valid request?
- What happens if I modify the request after it was signed/validated?

## Changelog
- 2026-03-20: Initial threat modeling protocol
