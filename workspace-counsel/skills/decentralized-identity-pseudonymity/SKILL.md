# SKILL 55: Decentralized Identity & Pseudonymity

## Purpose
Balance crypto culture's pseudonymity with regulatory KYC/AML requirements. Design progressive identity systems that minimize friction while maintaining compliance.

## The Core Tension
- Crypto culture: users interact via wallet addresses, not legal names
- Regulatory requirement: FinCEN CDD Rule, state gambling KYC, tax reporting all require identity
- Solution: progressive KYC — more identity required as financial stakes increase

## When KYC IS Required

### Federal FinCEN Triggers
- If you're a Money Services Business (MSB): KYC/AML required on all customers
- Customer Due Diligence (CDD) Rule (31 C.F.R. §1020.210): know your customer, understand their expected transaction behavior
- If non-custodial architecture: may avoid MSB designation (see SKILL 5 — money transmission)

### Tax Reporting Triggers
- Prize winnings ≥ $600 in a calendar year: require W-9 (US person) or W-8BEN (non-US person) for 1099 filing
- Gambling winnings ≥ $1,200 (slots) / $1,500 (keno) / $5,000 (poker tournaments): W-2G required
- Crypto prizes: 1099-MISC or 1099-NEC at $600 threshold; apply regardless of payment method
- **Practical implication**: any user winning $600+ in a year needs name + SSN before you can pay them

### State Licensing Triggers
- DFS licenses (NY, NJ, etc.): age verification required at registration
- State gambling license: full KYC typically required

### OFAC Sanctions Screening
- ALL users: wallet addresses must be screened against OFAC SDN list
- Wallet screening ≠ full KYC, but it IS required regardless of KYC tier
- Tool: Chainalysis Sanctions Oracle (on-chain event), Elliptic API (off-chain, pre-transaction)

## When KYC is NOT Required
- Free-to-play: no financial transactions → no KYC requirement
- Non-custodial platform below MSB threshold: wallet address only may suffice
- Information/analysis only: no money changes hands → no KYC
- **Note**: even without formal KYC, OFAC wallet screening is always required for crypto platforms

## Progressive KYC Architecture (Recommended)

### Tier 0 — Anonymous (Wallet Only)
- Connect wallet address
- OFAC screen the wallet address
- Can: view content, browse markets, participate in free contests, earn reputation/points
- Cannot: pay entry fees, receive cash prizes

### Tier 1 — Light KYC (Email + Age Verification)
- Email address + date of birth (age verification: 18+)
- Cryptographic age proof or third-party age verification service
- Can: enter paid contests up to $100/day, receive prizes up to $600/year
- Cannot: exceed $100/day or $600/year prize threshold (triggers tax reporting)

### Tier 2 — Full KYC (Government ID + Address)
- Government-issued photo ID (passport, driver's license)
- Address verification
- Use a KYC provider: Persona, Jumio, Onfido (they handle BIPA compliance for you)
- Can: unlimited participation, all withdrawals, prize winnings >$600/year
- Required: before any prize payment that triggers 1099 reporting

### Tier 3 — Enhanced Due Diligence (EDD)
- For: politically exposed persons (PEPs), high-volume users, users flagged by OFAC screening
- Additional: source of funds verification, enhanced OFAC/sanctions screening
- Managed: on a case-by-case basis

## Right to Be Forgotten vs. Blockchain Immutability

### The GDPR Problem
- GDPR Article 17: right to erasure ("right to be forgotten")
- Blockchain transactions: permanent and immutable
- Apparent conflict: user wants data deleted, but it's on-chain forever

### The Solution (EU-Accepted Approach)
1. Store ALL PII (name, email, government ID, address) OFF-CHAIN in deletable database (Supabase)
2. Store ONLY wallet addresses ON-CHAIN
3. When user requests deletion: delete ALL off-chain PII → wallet address on-chain becomes pseudonymous (no longer linked to any identity)
4. Legal basis: GDPR Article 17 is satisfied when the LINK between on-chain data and identity is destroyed, even if on-chain data itself remains
5. EU regulators and data protection authorities have accepted pseudonymized on-chain data as satisfying erasure requirements

**Implementation**: wallet address is the on-chain identifier. The wallet-to-identity mapping lives ONLY in your off-chain database. Delete the mapping = effective erasure.

## Privacy-Preserving Compliance Tools (Advanced)
- **Zero-knowledge age proofs**: prove age is ≥18 without revealing exact birthdate or identity (Worldcoin, Polygon ID, zk-SNARK implementations)
- **zk-KYC**: prove compliance with KYC requirements using zero-knowledge proofs without revealing identity to the platform
- **Selective disclosure**: reveal only what's required (prove you're not in a sanctioned country without revealing which country you're in)
- **Status**: emerging technology, not yet battle-tested in US regulatory context; use as supplement to, not replacement for, traditional KYC

## COPPA (Under-13) Compliance
- Age verification at Tier 1 blocks under-13 users
- If a user under 13 is discovered: delete ALL their data immediately, document the deletion
- Keep record of: when the underage user was identified, when data was deleted (demonstrates good faith)

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
