# SKILL 63: Cross-Border User Management

## Purpose
Serve users in multiple countries legally. Know where you need licenses, where you need to geo-block, and what your obligations are for sanctions, KYC, and tax reporting for international users.

## Jurisdiction Matrix

| Jurisdiction | Prediction Markets | Crypto | KYC | Geo-block? |
|-------------|-------------------|--------|-----|-----------|
| US | CFTC/DCM or skill-based (state) | MSB/state MTL | Yes (if MSB) | State-by-state (see SKILL 54) |
| UK | FCA / Gambling Commission depending on structure | FCA registered | Yes | If licensed, serve |
| EU | MiCA for crypto; gambling varies by member state | MiCA license | Yes | Block until MiCA compliant |
| Japan | Strictly regulated; most prediction markets illegal | FSA registered | Yes | Block initially |
| China | All crypto banned; all gambling banned | Banned | N/A | MUST block |
| Singapore | MAS regulated | MAS DPT license | Yes | If MAS licensed, serve |
| Australia | AFS license potentially required | ASIC/AUSTRAC | Yes | If licensed, serve |
| Canada | Provincial gambling; crypto under CSA | MSB registration | Yes | Provincial analysis |
| South Korea | Strict crypto regulation; gambling heavily restricted | VASP registration | Yes | Block initially |
| India | Gray area; state-by-state gambling | Uncertain | Yes | Evaluate |

## OFAC Sanctions (Non-Negotiable)

### Must Block Entirely
- Cuba, Iran, North Korea, Syria, Crimea/Donetsk/Luhansk (Russia-controlled regions)
- Screen ALL users regardless of jurisdiction

### Implementation
- **IP geolocation**: MaxMind GeoIP2 or Cloudflare's geo-blocking. Block at application layer.
- **VPN detection**: flag known VPN exit nodes; require additional verification for flagged IPs
- **Self-certification**: "I am not located in or subject to the laws of [sanctioned countries]" at signup
- **Wallet screening**: Chainalysis Sanctions Oracle for all deposits/withdrawals
- **Legal standard**: you must make "reasonable efforts" to exclude prohibited users. Perfect enforcement is impossible and not legally required.

## Geo-Blocking Architecture
```
User → IP Check → Sanctioned country? → Block
                → Tier 4 US state? → Block
                → Restricted jurisdiction? → Show restricted message + geo-block
                → Permitted jurisdiction? → Continue to self-certification
                                         → Continue to KYC tier
```

### Your Legal Protection Stack
1. IP-based geo-blocking (technical barrier)
2. TOS prohibition ("by using this platform, you represent you are not in a prohibited jurisdiction")
3. Self-certification at registration
4. KYC verification (at Tier 2/3)
5. Wallet address OFAC screening

Together, these constitute "reasonable efforts" — the legal standard.

## International Tax Reporting

### US Winners (Regardless of Their Location if US Person)
- W-9 required at Tier 3 KYC for US persons
- 1099-MISC for winnings >$600/year
- 24% backup withholding if user refuses to provide W-9

### Non-US Winners
- W-8BEN required (certifies non-US status)
- 30% withholding on US-source income (can be reduced by tax treaty)
- If your entity is offshore AND the winning user is non-US: generally no US tax reporting obligation
- If your entity has US nexus: US tax reporting may apply regardless

### Crypto Prize Tax Treatment
- IRS: crypto prizes are ordinary income at fair market value on date of receipt
- Users must report; platform's obligation is 1099-MISC if threshold met

## MiCA (EU Markets in Crypto-Assets Regulation, effective 2024-2025)
- Applies to: crypto-asset service providers (CASPs) serving EU users
- Requirements: authorization from EU member state, capital requirements, conduct of business rules
- **Practical guidance**: until MiCA compliance is in place → geo-block EU
- Cost of MiCA compliance: significant. Priority after US market is established.

## Language Requirements
- TOS must be available in the user's language if actively marketing in that jurisdiction
- Risk disclosures must be in the user's language and prominently displayed
- Strategy: English-only TOS + no active marketing in non-English-speaking countries = reduces obligation to translate and reduces non-US regulatory exposure

## Priority Launch Jurisdictions
- Phase 1 (launch): US only (with state-by-state geo-blocking per SKILL 54)
- Phase 2 (6 months): Canada, Australia, UK — common law jurisdictions with similar frameworks
- Phase 3 (12 months): evaluate EU MiCA compliance; Singapore MAS license
- Permanently block: China, Iran, North Korea, Cuba, Syria, Crimea

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
