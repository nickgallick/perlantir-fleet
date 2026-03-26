# SKILL: Insurance & Liability Management for Crypto Platforms
**Version:** 1.0.0 | **Domain:** D&O Insurance, Cyber Insurance, Smart Contract Cover

---

## Directors & Officers (D&O) Insurance

**What it covers:**
- Personal liability of directors and officers for decisions made on behalf of the company
- Defense costs (attorney fees) for regulatory investigations, securities claims, breach of fiduciary duty
- Settlements and judgments (subject to policy limits)

**Why it's critical:**
- SEC/CFTC enforcement against founders personally (not just the company)
- Securities class actions against directors for misstatements
- Investor lawsuits against officers for breach of fiduciary duty

**Crypto-specific challenges:**
- Most traditional D&O underwriters (AIG, Chubb, Travelers) exclude crypto companies or charge very high premiums
- Crypto-specialized D&O underwriters:
  - **Evertas:** Crypto-native insurance; specializes in digital asset companies
  - **Relm Insurance:** Fintech and crypto D&O coverage
  - **Coalition:** Cyber + D&O bundling; some crypto coverage
  - **Nexus Mutual:** Decentralized; covers smart contracts, not D&O per se

**Cost estimate:**
- Early-stage crypto startup: $10K-$50K/year
- Platform with >$1M in TVL or >$10M in revenue: $50K-$200K+/year
- Price depends on: business model (DeFi vs. CeFi), regulatory status (registered vs. unregistered), prior incidents, financials

**Coverage structure:**
- **Side A:** Covers directors/officers personally when the company cannot indemnify (e.g., company is insolvent)
- **Side B:** Reimburses the company when it does indemnify directors/officers
- **Side C (Entity coverage):** Covers the company itself for securities claims

**Critical exclusions to review:**
- ❌ Intentional fraud or criminal conduct (standard exclusion — but criminal prosecution defense costs ARE often covered until a final criminal conviction)
- ❌ Claims by one insured against another (insured vs. insured exclusion — negotiate this for management vs. company claims)
- ❌ Regulatory fines and penalties (some states allow D&O to cover this; others prohibit it as against public policy; Iowa: uncertain)
- ❌ Prior pending litigation (known claims at policy inception are excluded)

---

## Cyber Insurance

**What it covers:**
- Data breaches: costs of breach response, notification, credit monitoring for affected users
- Ransomware: ransom payments (some policies) and recovery costs
- Business interruption: lost revenue during a cybersecurity incident
- Third-party liability: claims by users/partners arising from the breach

**Crypto-specific exclusions (CRITICAL — READ CAREFULLY):**
- **"Voluntary transactions" exclusion:** If an attacker tricks your system into making what appears to be a legitimate transaction (social engineering, oracle manipulation, flash loan attacks) → INSURER MAY DENY. The transaction was "voluntary" by your systems.
- **Smart contract exploit exclusion:** Many policies exclude losses from bugs in smart contracts
- **"War" exclusion:** Nation-state cyberattacks (increasingly relevant for crypto as a target of state-sponsored hackers like North Korea's Lazarus Group)
- **Hot wallet vs. cold wallet:** Some policies only cover cold wallet losses; hot wallet losses (more common in hacks) may not be covered

**Crypto-specialized cyber underwriters:**
- **Evertas:** Purpose-built for crypto; actually covers smart contract exploits and digital asset custody losses
- **At-Bay:** Strong cyber insurer; some crypto coverage
- **Cowbell:** SMB-focused; may not cover complex DeFi risks
- **Coalition:** Active insurance + security scanning; check crypto exclusions

**Cost estimate:** $5K-$50K/year depending on platform size and security posture

---

## Smart Contract Cover (DeFi Insurance)

### Nexus Mutual
**Website:** https://nexusmutual.io

**How it works:**
- Decentralized mutual insurance pool (technically a mutual, not an insurance company)
- Token holders (NXM) are the risk pool
- Users buy "cover" against specific smart contract exploits
- Claims assessed by NXM members (decentralized claims process)

**Cover types relevant to Nick's platforms:**
- Protocol cover: covers losses from smart contract bugs or oracle manipulation in a specific protocol
- Custody cover: covers crypto held at centralized custodians

**Strategy for Agent Sparta:** List your smart contracts on Nexus Mutual to allow users to buy cover against exploits. This signals confidence in your security and reduces user risk (increases trust).

**Strategy for self-protection:** Buy cover on your own protocol's smart contracts. If you're exploited, Nexus pays out (up to coverage limit). This is limited but better than nothing.

---

### InsurAce Protocol
**Website:** https://www.insurace.io

**Similar to Nexus Mutual:** Decentralized insurance for DeFi protocols. Lower minimum premiums. More protocol coverage options.

---

## Errors & Omissions (E&O) / Professional Liability

**Trigger for prediction market / AI scoring platforms:**
- Your platform declares a prediction resolved incorrectly → user claims they would have won but for the error → E&O claim
- Your AI judge incorrectly scores a challenge in Agent Sparta → losing party claims they actually won → E&O claim
- You publish AI prediction accuracy data that is wrong → user relies on it to make a bet → loses money → claims against you

**E&O coverage:** Pays defense costs and settlements for claims that your professional services were negligent or erroneous.

**E&O for AI platforms:** Still an evolving product category. Most traditional E&O underwriters don't yet have specialized AI E&O products. Check with specialty insurers (Evertas, Markel).

**Contractual risk mitigation (cheaper than insurance):**
- TOS limitation of liability: cap your liability at the amount the user deposited in the last 12 months
- Dispute resolution mechanism in TOS: define exactly how contest results will be resolved, what happens on oracle failure, what the appeals process is
- If the TOS is comprehensive and users agreed to it: E&O exposure is significantly reduced

---

## Key Exclusion Checklist (For Every Policy)

Before purchasing any crypto-related insurance policy, confirm in writing how the policy handles:

| Risk | Question to Ask |
|---|---|
| Smart contract exploit | Does the policy cover losses from bugs in your own smart contracts? |
| Social engineering / phishing | If an employee is tricked into sending funds → covered? |
| Oracle manipulation | If an attacker manipulates price feeds causing incorrect payouts → covered? |
| Flash loan attacks | Covered as a cybersecurity incident? |
| Regulatory investigation defense costs | Are legal fees for responding to CFTC/SEC subpoenas covered? |
| Criminal defense costs | Are legal fees for criminal investigation covered (until conviction)? |
| Regulatory fines | Covered? (state law may prohibit) |
| Hot wallet losses | Covered at same level as cold wallet? |
| Insider threat (employee theft) | Covered under crime policy or cyber? |
| DAO liability (if applicable) | Does coverage extend to DAO members? |

---

## Insurance Timeline Recommendations

| Stage | Action | Approximate Cost |
|---|---|---|
| Formation | D&O quote (even if you don't buy yet — understand what's available) | $0 |
| Before beta launch | Cyber insurance (even basic) | $5K-$15K/year |
| Before accepting user funds | D&O insurance | $10K-$50K/year |
| Before significant TVL ($1M+) | Smart contract audit + Nexus Mutual cover | $20K-$50K audit + cover premium |
| Before institutional investors | Full insurance stack (D&O, Cyber, E&O) | $50K-$150K+/year |

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
