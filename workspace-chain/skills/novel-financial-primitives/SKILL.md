# Novel Financial Primitives

## First-Principles Framework

Every financial instrument is five elements:
1. **Ownership** — who has a claim
2. **Conditionality** — under what conditions does it pay
3. **Time** — when does it activate/expire
4. **Transferability** — can the claim be traded
5. **Composability** — can claims combine

Smart contracts let you design ANY combination. This space is mostly unexplored.

## Existing → New: Mapping Examples

| Instrument | Ownership | Conditionality | Time | Transferable | Novel Twist |
|-----------|-----------|----------------|------|-------------|------------|
| Option | Buyer | Price > strike | Expiry | Yes | Remove time → perpetual option |
| Insurance | Policyholder | Loss event | Coverage period | No | Make transferable → tradeable risk |
| Prediction market | Token holder | Binary outcome | Resolution | Yes | Add streaming → continuous prediction |
| Loan | Lender | Repayment | Maturity | Yes (bond) | Replace collateral with reputation |

## Novel Primitive #1: Reputation-Backed Credit

```solidity
// Instead of collateral → reputation score determines borrow limit
// Built on EAS attestations + on-chain history

contract ReputationCredit {
    IEASRegistry public eas;
    mapping(address => uint256) public creditScore;  // 0-1000
    mapping(address => uint256) public outstanding;  // Current debt

    function updateScore(address user) public {
        uint256 score = 0;

        // On-chain history signals
        score += _getTransactionHistory(user);    // Tx count, age, volume
        score += _getAttestations(user);           // KYC, employment, track record
        score += _getRepaymentHistory(user);       // Prior loan repayments
        score += _getGovernanceParticipation(user); // DAO voting activity

        creditScore[user] = min(score, 1000);
    }

    function borrow(uint256 amount) external {
        updateScore(msg.sender);
        uint256 maxBorrow = creditScore[msg.sender] * 100e6; // Score 1000 = $100K max borrow
        require(outstanding[msg.sender] + amount <= maxBorrow);
        outstanding[msg.sender] += amount;
        usdc.transfer(msg.sender, amount);
    }
    // Repayment increases score; default destroys score → social penalty
}
```

## Novel Primitive #2: Conditional Payment Streams

```solidity
// Payment stream that ADJUSTS based on on-chain conditions
// Revenue-share salary: base salary + revenue-linked bonus, all streamed

contract ConditionalStream {
    struct Stream {
        address recipient;
        uint256 baseRatePerSecond;     // Fixed floor rate
        address oracleAddress;          // Condition oracle
        bytes4  oracleSelector;         // What to read
        uint256 conditionThreshold;     // Above this = bonus kicks in
        uint256 bonusMultiplier;        // 1.5x = 50% bonus when above threshold
    }

    mapping(uint256 => Stream) public streams;

    // Calculate current rate based on oracle condition
    function currentRate(uint256 streamId) public view returns (uint256) {
        Stream storage s = streams[streamId];
        (bool ok, bytes memory data) = s.oracleAddress.staticcall(
            abi.encodeWithSelector(s.oracleSelector)
        );
        uint256 conditionValue = abi.decode(data, (uint256));

        if (conditionValue >= s.conditionThreshold) {
            return s.baseRatePerSecond * s.bonusMultiplier / 1e18; // Apply multiplier
        }
        return s.baseRatePerSecond;
    }

    // Example: stream salary to dev at $100/day base
    // If protocol TVL > $10M: stream at $150/day
    // Implemented as: oracleAddress = protocol contract, oracleSelector = getTVL()
}
```

## Novel Primitive #3: Time-Weighted Loyalty (invented above)

```solidity
// No lockup required — just HOLD to earn loyalty
// Rewards patient capital without punishing liquidity

contract LoyaltyToken {
    struct Holding {
        uint256 amount;
        uint256 since;        // Block number when holding started
    }

    mapping(address => Holding) public holdings;

    // "Loyalty score" = tokens held × blocks held (resets on any transfer)
    function loyaltyScore(address user) public view returns (uint256) {
        Holding storage h = holdings[user];
        return h.amount * (block.number - h.since);
    }

    // Voting weight = loyalty score (long holders > mercenary capital)
    function getVotingPower(address user) public view returns (uint256) {
        return loyaltyScore(user);
    }

    // On transfer: reset the holding duration for the SENDER
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0)) {
            // Seller resets to current balance and current block
            holdings[from] = Holding(balanceOf(from), block.number);
        }
        if (to != address(0)) {
            // Buyer: if already holding, weighted average start time
            if (holdings[to].amount > 0) {
                uint256 existingScore = loyaltyScore(to);
                uint256 newAmount = holdings[to].amount + amount;
                // Set `since` such that score is preserved for existing + 0 for new
                holdings[to].since = block.number - existingScore / newAmount;
                holdings[to].amount = newAmount;
            } else {
                holdings[to] = Holding(amount, block.number);
            }
        }
    }
}
```

## Novel Primitive #4: Peer-to-Peer Structured Products Factory

```solidity
// Two parties create a custom binary derivative — any condition, any payout
contract P2PStructuredProduct {
    struct Deal {
        address long;          // Pays if condition is TRUE
        address short;         // Pays if condition is FALSE
        address oracle;        // Who resolves the condition
        bytes32 conditionHash; // keccak256(description of condition)
        uint256 longCollateral;
        uint256 shortCollateral;
        uint256 settlementDate;
        bool resolved;
        bool conditionMet;
    }

    mapping(bytes32 => Deal) public deals;

    // Create: both parties deposit their maximum loss
    function createDeal(
        address counterparty,
        address oracle,
        bytes32 conditionHash,
        uint256 longAmount,   // What long pays if condition FALSE
        uint256 shortAmount   // What short pays if condition TRUE
    ) external payable returns (bytes32 dealId) {
        dealId = keccak256(abi.encode(msg.sender, counterparty, conditionHash, block.timestamp));
        // Long deposits their collateral
        usdc.safeTransferFrom(msg.sender, address(this), longAmount);
        deals[dealId] = Deal(msg.sender, counterparty, oracle, conditionHash,
            longAmount, shortAmount, block.timestamp + 30 days, false, false);
    }

    // Counterparty accepts
    function acceptDeal(bytes32 dealId) external {
        Deal storage deal = deals[dealId];
        require(msg.sender == deal.short);
        usdc.safeTransferFrom(msg.sender, address(this), deal.shortCollateral);
    }

    // Oracle resolves
    function resolve(bytes32 dealId, bool conditionMet) external {
        Deal storage deal = deals[dealId];
        require(msg.sender == deal.oracle);
        deal.resolved = true;
        deal.conditionMet = conditionMet;

        if (conditionMet) {
            // Long wins both collaterals
            usdc.safeTransfer(deal.long, deal.longCollateral + deal.shortCollateral);
        } else {
            // Short wins both collaterals
            usdc.safeTransfer(deal.short, deal.longCollateral + deal.shortCollateral);
        }
    }
    // No market maker. No protocol fee. Just two parties and a smart contract.
    // This is peer-to-peer finance in its purest form.
}
```
