# On-Chain Insurance

## Nexus Mutual Model

```solidity
contract CoverPool {
    struct Cover {
        address coveredProtocol;
        address coverBuyer;
        uint256 coverAmount;
        uint256 premiumPaid;
        uint256 expiry;
        bool active;
    }

    // Underwriters stake NXM → earn premiums → lose stake if claims are paid
    mapping(address => mapping(address => uint256)) public stakedCapital; // protocol → staker → amount

    // Pricing: basePrice × capacityFactor × timeFactor
    function getCoverPrice(
        address protocol,
        uint256 coverAmount,
        uint256 durationDays
    ) external view returns (uint256 premium) {
        uint256 stakedCapacity = getTotalStaked(protocol);
        uint256 utilizationRatio = getActiveCovers(protocol) * 1e18 / stakedCapacity;

        // Higher utilization → higher price
        uint256 baseRate = 0.02e18; // 2% annual
        uint256 capacityMultiplier = 1e18 + utilizationRatio; // 1x-2x

        premium = coverAmount * baseRate * durationDays * capacityMultiplier / (365 * 1e36);
    }

    // Claim submission
    function submitClaim(uint256 coverId, bytes calldata evidence) external {
        Cover memory cover = covers[coverId];
        require(cover.coverBuyer == msg.sender);
        require(cover.active && block.timestamp < cover.expiry);

        claimsQueue.push(Claim({
            coverId: coverId,
            claimant: msg.sender,
            evidence: evidence,
            submittedAt: block.timestamp,
            status: ClaimStatus.PENDING
        }));
    }

    // Claims assessors vote
    function voteOnClaim(uint256 claimId, bool accept, uint256 stake) external {
        // Vote weighting by NXM stake
        // After voting period, majority decision wins
        // Accepted → payout from staked capital pool
        // Rejected → claimant loses nothing
    }
}
```

## Sherlock Model (Audit + Coverage)

Sherlock aligns auditor incentives with protocol security:

```
Protocol pays Sherlock:
  - Audit fee ($50K-$500K depending on scope)
  - Coverage premium (ongoing, tied to TVL)

Sherlock pays:
  - Auditors for the audit work
  - Claims if protocol is exploited within scope

Sherlock is funded by:
  - Underwriters who deposit USDC to earn yield
  - Coverage premiums from protocols

If exploit occurs within audit scope:
  - Sherlock pays the claim (capped at coverage amount)
  - Underwriter capital is at risk (this is why underwriters do due diligence)
```

Why this is better than traditional audits:
- Traditional audit: auditor gets paid regardless of finding bugs
- Sherlock: auditor has economic skin in the game — if they miss a critical bug, Sherlock pays the claim which reduces their earnings

## Parametric Insurance

```solidity
// Payout triggered automatically — no claims process
contract ETHCrashInsurance {
    address public immutable priceFeed; // Chainlink ETH/USD
    uint256 public constant TRIGGER_THRESHOLD = 50; // 50% drop
    uint256 public referencePrice; // Price at policy start
    mapping(address => uint256) public coverageAmount;
    mapping(address => bool) public claimed;

    function buy(uint256 coverage) external payable {
        uint256 premium = coverage * 2 / 100; // 2% premium
        require(msg.value >= premium, "Insufficient premium");
        coverageAmount[msg.sender] = coverage;
        if (referencePrice == 0) {
            referencePrice = getPrice();
        }
    }

    function claim() external {
        require(!claimed[msg.sender]);
        require(coverageAmount[msg.sender] > 0);

        uint256 currentPrice = getPrice();
        uint256 dropPct = (referencePrice - currentPrice) * 100 / referencePrice;
        require(dropPct >= TRIGGER_THRESHOLD, "No trigger event");

        claimed[msg.sender] = true;
        uint256 payout = coverageAmount[msg.sender];
        payable(msg.sender).transfer(payout);
    }
}
```

## Insurance for Agent Sparta Prize Pools

### Smart Contract Risk Coverage
Buy Nexus Mutual or Sherlock coverage on the prize pool contract:
- If prize pool contract is exploited → insurance pays out to participants
- Premium: ~2-5% of TVL per year → on $100K pool = $200-500/year
- Makes the platform safer and more trustworthy for large prizes

### Prize Guarantee Insurance
```solidity
// Novel concept: insure against prize pool operator insolvency
// Underwriters: earn yield from idle prize pool funds
// Claimants: winners who don't receive their prize within N days

contract PrizePoolInsurance {
    mapping(bytes32 => uint256) public guaranteedPrizes;

    // Operator pre-commits prize amounts to insurance
    function guaranteePrize(bytes32 challengeId, uint256 amount) external {
        USDC.safeTransferFrom(msg.sender, address(this), amount * 5 / 100); // 5% premium
        guaranteedPrizes[challengeId] = amount;
        // Idle funds deployed to Aave to earn yield for underwriters
        aave.supply(address(USDC), amount * 5 / 100, address(this), 0);
    }

    // If winner not paid within 7 days → claim
    function claimUnpaidPrize(bytes32 challengeId, address winner) external {
        require(block.timestamp > resolvedAt[challengeId] + 7 days);
        require(winner == verifiedWinner[challengeId]);
        require(!prizePaid[challengeId]);
        USDC.safeTransfer(winner, guaranteedPrizes[challengeId]);
    }
}
```
