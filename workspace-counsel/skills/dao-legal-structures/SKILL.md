# SKILL: DAO Legal Structures
**Version:** 1.0.0 | **Domain:** DAO Law, Wyoming DAO LLC, Foundation Structures, CFTC v. Ooki DAO

---

## The Core Problem: Unincorporated DAO = Unlimited Liability

Without a legal wrapper, a DAO operating as an unincorporated association is treated in most states as a **general partnership** under common law.

**General partnership consequences:**
- Every member (token holder) is **personally liable** for the DAO's debts and legal obligations
- Joint and several liability: a creditor can sue ANY member for the full amount
- No entity-level protection whatsoever

**CFTC v. Ooki DAO, No. 22-cv-5416 (N.D. Cal. 2022-2023):**
- CFTC sued Ooki DAO (formerly bZeroX) directly — served process on the DAO's online governance forum
- DAO did not appear (no legal entity to appear on its behalf)
- Court entered **default judgment against the DAO** — the DAO owed civil penalties
- Court found: DAO token holders who voted on governance proposals ARE members of an unincorporated association → **personally liable**
- **Impact:** If you vote on a DAO governance proposal, you may be personally liable for the DAO's regulatory violations. This is existential for DeFi governance.

---

## Legal Entity Options

### Option 1: Wyoming DAO LLC
**Authority:** Wyoming Revised Statutes §§ 17-31-101 through 17-31-115 (Wyoming DAO Supplement, effective July 1, 2021)

**How it works:**
- File a Certificate of Organization with Wyoming Secretary of State that designates the LLC as a "decentralized autonomous organization"
- Specify whether: "member-managed" (token holders govern) or "algorithmically managed" (smart contract governs)
- Smart contract address is filed with the state and becomes part of the public record
- Limited liability for members (token holders) — same protection as a traditional LLC

**Requirements:**
- Registered agent in Wyoming (e.g., National Registered Agents, Inc. or Wyoming-specific agent)
- Articles of Organization stating the DAO nature
- Operating Agreement (can reference the smart contract as the governance mechanism)
- Annual report: $60/year

**Cost:** ~$100 filing + $200-500/year registered agent + $60 annual report

**Critical limitations:**
- **Untested in federal courts** — no federal appellate court has yet ruled on whether Wyoming DAO LLC effectively shields members from federal regulatory liability
- Other states may not respect the limited liability (if DAO operates nationally)
- **Most important:** the Wyoming DAO LLC provides entity-level registration but does NOT immunize the DAO from federal regulatory compliance (CFTC, SEC, FinCEN still have jurisdiction)

**Formation:**
1. Choose a name including "DAO," "LAO," or "DAO LLC"
2. File Certificate of Organization online at wyobiz.wyo.gov ($100 filing fee)
3. Include the smart contract address in the filing
4. Appoint a Wyoming registered agent
5. Create the Operating Agreement
6. File annual report each year

---

### Option 2: Marshall Islands DAO LLC
**Authority:** Marshall Islands Business Corporations Act (amended 2022); Non-Profit Entities (Amendment) Act 2022

**How it works:** Offshore DAO registration with legal personhood; can enter contracts, hold property, sue and be sued

**Used by:** Several DeFi protocols including dYdX Foundation-adjacent entities

**Advantages:**
- Offshore jurisdiction
- 0% corporate tax
- Legal recognition

**Critical disadvantages:**
- Enforceability in US courts: **uncertain** — a Marshall Islands DAO LLC may not be recognized by US courts as having the same liability protection as a domestic entity
- Very little legal precedent
- US regulators may pierce the structure

**Best use:** In combination with a US legal entity, not as a standalone

---

### Option 3: Cayman Foundation Company
**Authority:** Cayman Islands Foundation Companies Act, 2017

**How it works:**
- A foundation company is limited by guarantee (no shareholders/members, unlike a standard company)
- Governed by a charter (the "foundation's constitution") rather than a standard articles of incorporation
- Can have: supervisors (equivalent to directors), beneficiaries (optional), an enforcer
- Directors can be bound by charter to follow token holder votes → governance mechanism

**Used by:**
- Uniswap Foundation (governs Uniswap protocol treasury, grants)
- Ethereum Foundation (though Swiss, not Cayman)
- Multiple DeFi protocols

**Advantages:**
- No members/shareholders → no one owns it → it's truly "foundation-held"
- Can hold IP, manage treasury, employ staff
- Cayman law is familiar to sophisticated international investors
- 0% corporate tax in Cayman

**Cost:** $10K-$25K setup + $5K-$10K/year maintenance + registered agent fees

**Best use:** Protocol governance, treasury management, IP holding for decentralized protocols

---

### Option 4: Swiss Foundation (Stiftung)
**Authority:** Swiss Civil Code, Arts. 80-89a

**How it works:**
- Foundation supervised by Swiss Federal Supervisory Authority for Foundations (FSAF)
- No members or shareholders — governed by a foundation board
- Established purpose (e.g., "to develop and maintain the [Protocol Name] protocol")
- Ethereum Foundation model

**Advantages:**
- "Gold standard" for foundation legitimacy internationally
- Swiss legal system is respected globally
- Strong regulatory framework → gives comfort to institutional partners
- Zug canton ("Crypto Valley"): favorable environment, experienced crypto counsel, government engagement

**Cost:** $30K-$50K+ setup + $10K-$20K/year ongoing + foundation board compensation

**Best use:** If building a protocol intended to be genuinely long-lived and globally legitimate (Ethereum-level ambition)

---

### Option 5: Unincorporated Nonprofit Association (UNA)
**Authority:** Uniform Unincorporated Nonprofit Association Act, adopted by multiple states (CA, CO, DC, TX, and others); Iowa has NOT adopted the UUNAA

**How it works:**
- Lightweight entity for community-governed organizations
- Some limited liability for members (varies by state)
- Very low cost and maintenance burden

**Limitations:**
- Weaker liability protection than LLC
- Iowa does NOT have UNA enabling legislation → don't use for Iowa operations
- Federal regulatory agencies don't care whether you're a UNA — they'll still treat you as a general partnership for enforcement purposes

---

## The Key Question: How Decentralized Is It REALLY?

**The CFTC/SEC look-through test:**

If, despite a DAO wrapper, the following is true → the entity is the operator for regulatory purposes:
- A small group (the founding team) controls admin keys to the smart contracts
- The founding team can upgrade, pause, or destroy the protocol unilaterally
- The founding team controls the treasury and how funds are spent
- Token governance is dominated by the founding team's token holdings (supermajority)
- The founding team can veto governance votes through technical means

**The genuine decentralization test:**
- Admin keys are held by a multisig with independent signers (not all on the founding team)
- Smart contracts have timelocks on governance actions (users can exit before changes take effect)
- The founding team's token holdings are below the threshold to control votes unilaterally
- The protocol can operate without the founding team (docs, code, RPC nodes all public)
- Treasury is governed by token holder vote with adequate participation

**For Nick's projects:**
- Agent Sparta (MVP): Iowa LLC is more honest and simpler than a DAO wrapper. You control it. Call it what it is.
- If decentralizing governance later: Wyoming DAO LLC (cheap, simple, available now) or Cayman Foundation (more robust, more expensive)
- **Don't create a DAO wrapper for a product you actually control** — it's both dishonest and provides less protection than you'd think (regulators pierce it)

---

## DAO Tax Treatment

**IRS position:** A DAO is typically a partnership for US tax purposes (no IRS guidance specifically on DAOs as of 2025).

**Consequences:**
- DAO income is "passed through" to token holders in proportion to their governance rights
- Token holders may owe US tax on DAO income even if they never received a distribution
- This is the same problem as an offshore partnership with US members

**If the DAO has a Cayman Foundation:** The Foundation is a separate taxpayer (foreign corporation for US tax purposes). US members who own >10% may have CFC obligations (Subpart F income, GILTI). Work with international tax counsel.

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
