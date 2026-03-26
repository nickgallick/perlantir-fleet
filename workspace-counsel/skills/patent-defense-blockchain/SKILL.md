# SKILL 41: Patent Defense — Blockchain & Fintech

## Purpose
Defend against patent trolls targeting blockchain/fintech products. Know when to fight, when to settle, and how to build defensively.

## The Patent Troll Landscape in Crypto
- Multiple trolls hold broad blockchain/fintech patents on: "method for exchanging digital assets," "system for peer-to-peer transactions," "decentralized oracle network," "escrow using distributed ledger"
- Common targets: exchanges, DeFi protocols, NFT platforms, payment processors, prediction markets
- Typical demand: $50K–$500K licensing fee or face litigation ($1M+ defense costs)
- Average patent litigation through trial: $2–5M. Most cases settle for significantly less.

## Defensive Strategies (Build These Now)
1. **Prior art search**: Before building any novel feature, search Google Patents, USPTO PAIR, Espacenet
2. **Defensive publication**: Publish novel ideas publicly BEFORE anyone can patent them. Blog post, whitepaper, GitHub commit creates prior art.
3. **Patent pledge**: Commit to non-offensive patent assertions (Twitter's Innovator's Patent Agreement model)
4. **Open Invention Network (OIN)**: Defensive patent pool for open-source software — free membership
5. **LOT Network**: If a member's patents transfer to a troll, all other members get automatic licenses

## If You Receive a Patent Demand Letter

### IMMEDIATE DO NOTs
- Do NOT ignore it (ignoring → willful infringement → treble damages)
- Do NOT respond without patent counsel
- Do NOT admit infringement

### IMMEDIATE DOs
- Note receipt date (response deadlines start running)
- Preserve all communications
- Retain patent counsel immediately
- Pull the patent from USPTO.gov and read the claims carefully

### Evaluation Framework (Patent Counsel Will Run)
1. **Is the patent valid?** Prior art, obviousness (KSR International v. Teleflex, 550 U.S. 398 (2007)), written description
2. **Do you actually infringe?** Claim-by-claim comparison to your implementation
3. **Is there prior art?** Blockchain has deep open-source history — Bitcoin whitepaper (2008), Ethereum (2015), academic papers, GitHub repos
4. **Is the troll a Patent Assertion Entity (PAE)?** If yes, they rely on settlement economics — often will settle for $20–50K

### Options
- **Design around**: Modify your implementation to avoid the patent claims
- **Inter partes review (IPR)**: Challenge patent validity at USPTO. Cost: $50K–$100K. Success rate: ~70% for petitions granted. Filed within 1 year of service.
- **Ex parte reexamination**: Cheaper (~$12K), but petitioner has less involvement
- **Negotiate license**: If patent is valid and you infringe, a reasonable royalty is often cheaper than litigation
- **Litigate**: Only if the patent is clearly invalid and the troll's demand is unreasonable

## Specific to Blockchain Escrow Patents
- **Key prior art sources**: Bitcoin scripting (P2SH, multisig, 2011+), Ethereum smart contracts (2015+), OpenBazaar (2014), early Ethereum EIPs, academic papers pre-2015
- **Obviousness argument**: Any blockchain escrow system is obvious to POSITA (Person of Ordinary Skill in the Art) given Bitcoin multisig + smart contract concepts
- **Alice Corp. v. CLS Bank International, 573 U.S. 208 (2014)**: Abstract ideas + generic computer = NOT patentable. Many broad blockchain patents are invalid under Alice.
- **Post-Alice invalidity rate**: Courts have invalidated ~60% of challenged software patents under Alice

## SBIR/STTR Government Grants (Related Opportunity)
- NSF SBIR: up to $275K Phase I, $1M Phase II for innovative technology
- DARPA: funds novel AI/blockchain research
- Iowa Economic Development Authority: state-level grants and tax incentives for tech companies
- Agent Sparta, prediction market: potentially qualify under "AI evaluation methodology" or "novel competition platform"
- No equity given up. Application is free. Timeline: 3–6 months.

## Risk Levels
- Valid patent + clear infringement: 🔴 High (settle or design around)
- Broad software patent (pre-Alice): 🟡 Medium (strong invalidity arguments)
- PAE with weak patent demanding <$50K: 🟡 Medium (evaluate IPR vs. nuisance settlement)
- Defensive publication in place: 🟢 Low for future claims

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
