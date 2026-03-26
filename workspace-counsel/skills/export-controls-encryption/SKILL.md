# SKILL 47: Export Controls & Encryption Compliance

## Purpose
Navigate Export Administration Regulations (EAR), OFAC sanctions, and AI model export controls for blockchain/crypto software platforms.

## Export Administration Regulations (EAR) — Bureau of Industry and Security (BIS)

### Encryption Software Classification
- Cryptographic software: controlled under EAR Category 5 Part 2 (Information Security)
- Blockchain software uses cryptography → technically subject to EAR
- **Key exemption**: License Exception TSU (Technology and Software Unrestricted) under 15 C.F.R. §740.13(e)
  - Publicly available encryption source code CAN be exported after notification to BIS
  - Notification: email to crypt@bis.doc.gov AND enc@nsa.gov BEFORE first export
  - Include: URL where the code is publicly available
  - One-time notification covers ongoing exports of that codebase
  - If your smart contracts are on GitHub (public): send the notification → covered

### If Code is NOT Publicly Available (Proprietary)
- More complex analysis required
- May need license or different exception
- Engage export control counsel before distribution to non-US parties

### AI Model Export Controls
- Executive Order 14110 + subsequent BIS rules: advanced AI models above compute thresholds have export restrictions
- Primary target: TRAINING large models, not USING models via API
- Using Claude/GPT via API → Anthropic/OpenAI handle export compliance, not you
- Self-hosting and training models: compute threshold analysis required
- BIS advanced computing rules (October 2023 and subsequent updates): chips used for AI training have export restrictions to certain countries

### Restricted Destinations (Check Before Any Distribution)
- Cuba, Iran, North Korea, Syria, Russia (post-2022 comprehensive sanctions)
- Crimea/Donetsk/Luhansk regions of Ukraine
- BIS Entity List: specific companies/individuals in any country
- Check: bis.gov/compliance/export-controls for current lists

## OFAC Sanctions (Separate from EAR but Overlapping)

### What OFAC Prohibits
- Providing services (including software access) to: sanctioned countries, designated individuals, designated entities
- "Specially Designated Nationals" (SDN) list: freeze assets, no transactions

### Crypto-Specific OFAC Requirements
- Screen ALL wallet addresses against OFAC SDN list before allowing transactions
- Tornado Cash sanctions (2022): OFAC sanctioned smart contract addresses, not just individuals
- Coinbase v. SDN screening: platforms that interacted with Tornado Cash faced OFAC exposure
- Tool: Chainalysis Sanctions Oracle (on-chain), Elliptic (API), TRM Labs (API)

### Geo-Blocking Requirements
- Platform must geo-block sanctioned countries: Cuba, Iran, North Korea, Syria, Crimea region
- Use: IP geolocation + self-certification at registration ("I am not a resident of...")
- VPN bypass: you cannot fully prevent VPN use, but reasonable efforts (IP block + self-cert) constitute "good faith compliance"
- OFAC has acknowledged that "reasonable screening" is the standard, not perfect enforcement

## Practical Compliance Steps
1. **Send BIS/NSA notification**: for any public cryptographic code you publish (one-time)
2. **Geo-block OFAC sanctioned countries**: IP-based at platform level
3. **Wallet address screening**: Chainalysis Sanctions Oracle for all crypto deposits/withdrawals
4. **User self-certification**: "I am not located in or subject to the laws of [sanctioned countries]" at signup
5. **If self-hosting AI models**: check compute thresholds against current BIS advanced computing rules
6. **Deemed exports**: if hiring developers in controlled countries, sharing technical information can be an "export" — check EAR 15 C.F.R. §734.13

## Deemed Export Rule (Hiring Risk)
- Sharing controlled technical information with a foreign national IN THE US = "deemed export" to their home country
- If their home country is sanctioned or controlled: potential EAR violation
- Practical: for most software development, this risk is low for US-based foreign national employees
- High risk: sharing AI model training data or advanced cryptographic algorithm implementation with nationals of China, Russia, Iran

## Risk Levels
- Public open-source code without BIS notification: 🟡 Medium (low risk but technically required)
- Providing services to OFAC sanctioned parties: ⚫ Existential (criminal liability + massive civil fines)
- Failing to screen wallet addresses: 🔴 High (OFAC enforcement trend)
- Self-hosting AI without compute threshold analysis: 🟡 Medium (depends on model size)

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
