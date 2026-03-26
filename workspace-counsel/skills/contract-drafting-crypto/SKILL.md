# SKILL: Contract Drafting for Crypto Platforms
**Version:** 1.0.0 | **Domain:** Smart Contracts, Legal Agreements, Token Grants, Investment Docs

---

## Ricardian Contracts — Legal + Smart Contract Hybrid

**Concept:** A human-readable legal agreement that references a specific smart contract by address. The legal agreement governs INTENT; the smart contract governs EXECUTION. If the smart contract has a bug that contradicts the legal agreement → the legal agreement controls in court.

### Template Structure:

```
AGENT SPARTA CONTEST AGREEMENT
Effective upon submission of transaction to smart contract at: [0x...]
Network: [Ethereum/Base/Solana]

RECITALS
This Agreement governs participation in [Contest Name] facilitated by the smart 
contract deployed at [0x...] (the "Contest Contract"). By submitting a transaction 
to the Contest Contract, you agree to be bound by this Agreement.

DEFINITIONS
"Entry Fee" means the USDC amount sent to the enter() function of the Contest Contract.
"Prize Pool" means the aggregate of all Entry Fees deposited in the current Contest round.
"Platform Fee" means [X]% of the Prize Pool automatically distributed to [Perlantir address].
"Winner" means the address designated by the resolveContest() function call.

CONTEST RULES
The Contest is a skill-based competition as defined under Iowa Code §99B.5. 
Outcomes are determined by the measurable performance of AI agents configured 
by participants. The scoring methodology is published at [URL] and incorporated herein.

DISPUTE RESOLUTION
If the Contest Contract behaves inconsistently with this Agreement due to a bug, 
hack, or oracle failure: disputes shall be resolved by binding arbitration 
administered by JAMS under its Consumer Arbitration Rules. The human-readable 
terms of this Agreement shall control over any unintended smart contract behavior.

GOVERNING LAW
Delaware law governs this Agreement. [Arbitration venue: [City], Delaware]

RISK DISCLOSURES
Smart contract risk: [standard risk language]
Blockchain network risk: [standard risk language]
```

---

## Token Grant Agreements

### For Team Members and Advisors

**Core provisions:**

**1. Vesting Schedule**
```
Tokens vest over 48 months (4 years) from the Grant Date.
Cliff: No tokens vest during the first 12 months.
After the Cliff: 25% of the Total Grant vests.
Thereafter: Remaining tokens vest in equal monthly installments 
over the following 36 months.
```

**2. Acceleration Provisions**
```
Single-Trigger Acceleration: Upon a Change of Control (defined as 
acquisition of >50% of voting equity or substantially all assets), 
100% of unvested tokens accelerate and become immediately vested.

Double-Trigger Acceleration (preferred for employees): Upon a Change 
of Control AND the recipient's termination without Cause or resignation 
for Good Reason within 12 months following the Change of Control, 
100% of unvested tokens accelerate.
```

*Double-trigger is preferred: single-trigger creates a perverse incentive where recipients benefit from a sale they might otherwise resist.*

**3. Forfeiture on Termination**
```
Upon termination of the recipient's service relationship with Company 
for any reason: all unvested tokens are immediately forfeited and returned 
to the Company's token treasury without compensation.
```

**4. Lock-up Period**
```
Notwithstanding vesting, tokens may not be transferred, sold, or disposed 
of until the earlier of: (a) 12 months following the Token Generation Event 
(TGE), or (b) a date specified by the Company's board following registration 
or exemption qualification under applicable securities laws.
```

**5. Tax Election Notice — CRITICAL**
```
IMPORTANT NOTICE REGARDING SECTION 83(b) ELECTION

If the tokens are subject to a substantial risk of forfeiture (including 
a vesting schedule), recipient may elect under Section 83(b) of the Internal 
Revenue Code to be taxed at the Grant Date rather than the vesting date(s). 
This election must be filed with the IRS within 30 DAYS of the Grant Date. 
FAILURE TO FILE THIS ELECTION WITHIN 30 DAYS IS IRREVOCABLE.

Recipient acknowledges receipt of this notice and agrees to consult 
with their own tax advisor regarding the advisability of filing a Section 83(b) 
election. Company is not responsible for any failure by recipient to timely 
file the election.
```

**6. On-Chain Vesting Implementation**
```
Token vesting shall be enforced on-chain via a vesting smart contract 
at [address] (the "Vesting Contract"). The Vesting Contract automatically 
releases vested tokens according to the schedule above. Recipient's vesting 
balance in the Vesting Contract serves as the definitive record of vested tokens.
```

---

## Investment Documents

### SAFE (Simple Agreement for Future Equity)
**Authority:** Y Combinator standard SAFE (2023 version) — the industry default

**What it is:** Investor gives money now; receives equity at the next priced round
**No interest, no maturity date** — simpler than a convertible note
**Key terms:**
- **Valuation cap:** Maximum valuation at which the SAFE converts to equity
- **Discount rate:** Percentage discount on the next round price (typically 10-25%)
- **MFN clause:** If company issues a more favorable SAFE to another investor, this investor gets the same terms

**Download:** YC's standard SAFE is freely available at ycombinator.com/documents
**Legal review needed:** Yes, but YC SAFE is market standard — minimal negotiation

### SAFT (Simple Agreement for Future Tokens)
**Authority:** Cooley LLP designed the original SAFT framework (2017)

**What it is:** Investment contract sold to accredited investors; investor receives tokens when the network launches
**Key provisions:**
- Purchase price (in dollars or crypto)
- Token delivery: number of tokens or formula for determining tokens at TGE
- TGE deadline: if tokens not delivered by [date], investor gets their money back
- Discount: percentage discount from public TGE price
- Lock-up: tokens locked for [X] months after TGE before transferable

**Securities law:** The SAFT itself IS a security (an investment contract). Must be sold under Reg D 506(b) (no general solicitation, accredited investors only) or Reg D 506(c) (general solicitation allowed, all investors must be verified accredited).

**Key risk:** If the token itself turns out to be a security (fails the Howey analysis post-TGE), you've sold securities twice: once the SAFT, once the token. Double exposure. This is why Howey analysis BEFORE any SAFT issuance is essential.

### Token Warrant
**What it is:** Right to purchase tokens at a fixed price in the future (similar to a stock warrant)
**Typically used:** For strategic partners, advisors, or early investors as a sweetener
**Tax treatment:** More complex than direct token grants; consult tax counsel

---

## Smart Contract Audit Checklist (Legal Perspective)

Before deploying any smart contract that holds user funds:

**Functional review:**
- [ ] Does the contract implement the rules exactly as described in the Ricardian contract?
- [ ] Is there any admin function that allows withdrawal of user funds? (If yes: this is custodial)
- [ ] What happens if the oracle fails or returns a bad value? (Define fallback in legal agreement)
- [ ] Can the contract be paused? By whom? Under what conditions?
- [ ] Can the contract be upgraded? (Upgradeable proxies = admin retains control = custodial argument)

**Security review (Trail of Bits / OpenZeppelin / Certik):**
- [ ] Reentrancy vulnerabilities
- [ ] Integer overflow/underflow
- [ ] Access control (who can call privileged functions?)
- [ ] Oracle manipulation vectors
- [ ] Front-running vulnerabilities

**Legal characterization review:**
- [ ] Does the contract's admin key architecture support the non-custodial argument?
- [ ] Is the admin key multisig? Who holds keys? (Document this)
- [ ] Is there a timelock on admin functions? (Strengthens decentralization argument)
- [ ] Is the source code published and verified? (If yes: anyone can verify your non-custodial claim)

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
