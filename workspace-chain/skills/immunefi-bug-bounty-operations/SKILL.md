# Immunefi Bug Bounty Operations

## Complete Scope Document: Lending Protocol (3 Core Contracts)

---

# [Protocol Name] Bug Bounty Program

**Total Rewards Available**: Up to $500,000 USDC  
**Platform**: Immunefi (immunefi.com/bounty/protocol-name)  
**KYC Required**: Yes for rewards >$20,000  

---

## In Scope — Smart Contracts

| Contract | Address | Network | Description |
|---|---|---|---|
| LendingPool.sol | 0x... | Ethereum Mainnet | Core deposit/borrow/liquidate logic |
| PriceOracle.sol | 0x... | Ethereum Mainnet | Chainlink + TWAP price feeds |
| InterestRateModel.sol | 0x... | Ethereum Mainnet | Borrow rate calculations |

**Source code**: github.com/your-org/protocol (tag: v1.2.0)  
**Audit reports**: Available at docs.protocol.com/audits

All proxy contracts and their current implementations are in scope. If a proxy points to an implementation at a different address, both are in scope.

---

## Reward Tiers

### Critical — Up to $500,000

Direct theft of user funds at scale, permanent freezing of funds, or complete protocol insolvency.

**Examples:**
- Direct drain of depositor funds without authorization
- Permanent freeze of all borrows and withdrawals
- Minting unbacked debt positions
- Complete bypassing of liquidation logic allowing protocol insolvency
- Oracle manipulation enabling theft >$50,000

**Requirements:**
- Working proof of concept on a mainnet fork (Foundry or Hardhat)
- Demonstrated actual fund loss in the PoC
- PoC submitted with the report

### High — $10,000 to $50,000

Theft of yield, temporary freezing of funds (>24 hours), manipulation of interest rates to user detriment.

**Examples:**
- Draining accrued interest from the protocol treasury
- Freezing withdrawals for >24 hours via griefing
- Manipulating interest rate calculation to extract excess yield
- Flash loan attack that briefly manipulates prices but doesn't cause full drain
- Governance manipulation that puts funds at indirect risk

**Requirements:**
- Detailed description of attack path
- PoC concept or pseudocode demonstrating feasibility

### Medium — $1,000 to $10,000

Griefing attacks (attacker spends more than they gain), non-critical DoS, limited fund loss.

**Examples:**
- Permanently DoS a specific user's position (not all users)
- Force bad debt accumulation under highly specific market conditions
- Block liquidations for a single block causing minor slippage

### Low — $500 to $2,000

Minor issues with no direct fund risk.

**Examples:**
- Incorrect event emission
- View function returning incorrect data under edge case
- Non-exploitable logic error

---

## Impact Definitions

```
CRITICAL requires ALL of:
  □ Attacker profits OR users lose principal
  □ Requires no external preconditions (no governance attack, no oracle compromise)
  □ Exploitable on current mainnet state without waiting for special conditions

HIGH requires:
  □ Attacker profits OR users lose yield/access
  □ May require specific market conditions but those conditions are reasonably likely
  □ Attack is reproducible

MEDIUM: No profit for attacker, or attacker spends more than gained
LOW:    Cosmetic or informational, no fund risk
```

---

## Out of Scope

The following are explicitly out of scope. Reports about these will be closed immediately.

```
□ Issues already known or previously reported (see Known Issues below)
□ Issues in third-party protocols we interact with (Chainlink, Uniswap, Aave)
□ Issues requiring a compromised admin/owner private key
□ Issues requiring 51% governance voting power
□ Issues requiring the attacker to control validator/sequencer ordering
□ Theoretical attacks with no working PoC for Critical/High claims
□ Gas optimization reports
□ Best practices recommendations without a concrete exploit path
□ Issues in test files or deployment scripts (not deployed on mainnet)
□ "The protocol could be more decentralized"
□ Frontend issues that do not lead to fund loss
□ Centralization risks already documented in our docs
□ Issues with UI/UX
□ Spam or phishing attacks
```

### Known Issues (Do Not Report)

```
1. Owner can pause the protocol — this is an accepted centralization risk documented in our docs
2. Interest rate model can be updated by governance — accepted governance risk
3. [Link to accepted finding from last audit]
```

---

## Severity Escalation Rules

```
A finding is NOT Critical if:
  - It requires compromised oracle AND compromised governance simultaneously
  - It requires waiting for a specific market condition (price at exact level)
  - The attacker loses more than they gain
  - It affects <$10,000 in funds under normal conditions

A finding IS Critical even if:
  - It requires a flash loan (flash loans are freely available)
  - It requires multiple transactions (as long as they're atomic or sequential without special timing)
  - It was not found in previous audits
```

---

## Triage Process

### Step 1: Initial Review (within 24 hours)

```typescript
// Internal checklist for every incoming report
const triage = {
  inScope: "Is the affected contract in our scope list?",
  duplicate: "Has this exact vulnerability been reported before?",
  realImpact: "Does the reported impact actually occur on a mainnet fork?",
  hasPOC: "For Critical/High: is there a working PoC?",
  severityAccurate: "Does the claimed severity match the actual impact?",
};

// Response template for out-of-scope:
`Thank you for your report. After review, this issue falls outside our current
scope because [specific reason]. We appreciate your effort and encourage you
to review our scope page at [link] before submitting future reports.`
```

### Step 2: Validation (within 48 hours for Critical)

```bash
# Reproduce on mainnet fork
forge test --fork-url $RPC --match-test testReproduceExploit -vvvv

# If PoC succeeds: confirm the impact
# If PoC fails: request clarification from researcher
```

### Step 3: Fix Development

```
Rule: develop the fix in a PRIVATE branch
Rule: do NOT deploy until researcher is informed
Rule: get the fix reviewed by a security researcher NOT on your core team
Rule: schedule deployment with researcher's knowledge (coordinate disclosure)
```

### Step 4: Payment and Disclosure

```
Timeline after fix deployed:
  Day 0:  Fix deployed on mainnet
  Day 1:  Notify researcher — provide tx hash of fix deployment
  Day 7:  Pay bounty via Immunefi platform
  Day 30: Coordinate public disclosure with researcher
  Day 30: Publish post-mortem on blog

Disclosure: researcher gets credit (unless they request anonymity)
Post-mortem must include: what was vulnerable, how we fixed it, what we learned
```

---

## Setup on Immunefi

```
1. Apply at immunefi.com/bounty/apply
2. Provide: team info, TVL, audit reports, GitHub repo
3. Immunefi onboarding: 1-2 week review
4. Deposit bounty funds into Immunefi's vault (they hold the rewards)
5. Set up webhook for new report notifications → PagerDuty or Slack

Ongoing:
  - Update scope when you deploy new contracts
  - Update "Known Issues" when you accept a finding as low risk
  - Respond to every report within 24 hours (Immunefi monitors SLA)
  - Poor response times hurt your program reputation — researchers stop submitting
```
