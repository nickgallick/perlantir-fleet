# Social Tokens & Creator Economy

## Friend.tech Bonding Curve (Exact Mechanism)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Friend.tech uses a cubic bonding curve: price = supply^2 / 16000
// Keys = shares of a person's social token
contract SharesV1 {
    // subjectAddress → keyHolder → keyBalance
    mapping(address => mapping(address => uint256)) public sharesBalance;
    mapping(address => uint256) public sharesSupply;

    uint256 public protocolFeePercent = 5e16;  // 5%
    uint256 public subjectFeePercent  = 5e16;  // 5%
    address public protocolFeeDestination;

    event Trade(
        address indexed trader,
        address indexed subject,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 supply
    );

    // Price formula: sum of (supply_i)^2 / 16000 for i in [start, end)
    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1) * supply * (2 * supply - 1) / 6;
        uint256 sum2 = (supply + amount - 1) * (supply + amount) * (2 * (supply + amount) - 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getBuyPrice(address subject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[subject], amount);
    }

    function getSellPrice(address subject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[subject] - amount, amount);
    }

    function getBuyPriceAfterFee(address subject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(subject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee  = price * subjectFeePercent  / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function buyShares(address subject, uint256 amount) external payable {
        uint256 supply = sharesSupply[subject];
        // First key must be bought by subject themselves (can't buy keys for new subject)
        require(supply > 0 || subject == msg.sender, "Only the subject can buy the first share");

        uint256 price       = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee  = price * subjectFeePercent  / 1 ether;

        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");

        sharesBalance[subject][msg.sender] += amount;
        sharesSupply[subject] = supply + amount;

        emit Trade(msg.sender, subject, true, amount, price, supply + amount);

        // Distribute fees
        (bool success1,) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2,) = subject.call{value: subjectFee}("");
        require(success1 && success2, "Fee transfer failed");
    }

    function sellShares(address subject, uint256 amount) external {
        uint256 supply = sharesSupply[subject];
        require(supply > amount, "Cannot sell the last share"); // Subject always holds 1

        uint256 price       = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee  = price * subjectFeePercent  / 1 ether;

        require(sharesBalance[subject][msg.sender] >= amount, "Insufficient shares");

        sharesBalance[subject][msg.sender] -= amount;
        sharesSupply[subject] = supply - amount;

        emit Trade(msg.sender, subject, false, amount, price, supply - amount);

        uint256 netProceeds = price - protocolFee - subjectFee;
        (bool s1,) = msg.sender.call{value: netProceeds}("");
        (bool s2,) = protocolFeeDestination.call{value: protocolFee}("");
        (bool s3,) = subject.call{value: subjectFee}("");
        require(s1 && s2 && s3, "Transfer failed");
    }
}
```

## Token-Gated Access

```solidity
contract TokenGatedContent {
    IERC20 public immutable creatorToken;
    IERC721 public immutable creatorNFT;

    // Tier 1: Hold 100+ creator tokens → access public content
    // Tier 2: Hold 1,000+ tokens → access premium content
    // Tier 3: Hold specific NFT → 1-on-1 access

    enum Tier { None, Public, Premium, Elite }

    function getUserTier(address user) public view returns (Tier) {
        if (creatorNFT.balanceOf(user) > 0) return Tier.Elite;
        uint256 balance = creatorToken.balanceOf(user);
        if (balance >= 1_000 * 1e18) return Tier.Premium;
        if (balance >= 100   * 1e18) return Tier.Public;
        return Tier.None;
    }

    modifier requireTier(Tier minTier) {
        require(uint8(getUserTier(msg.sender)) >= uint8(minTier), "Insufficient tier");
        _;
    }

    function accessPremiumContent(bytes32 contentId) external requireTier(Tier.Premium) returns (string memory) {
        // Return IPFS CID of decrypted content, or a signed URL
        return contentRegistry[contentId];
    }
}
```

## Creator Revenue Model

```
PRIMARY REVENUE
  Keys/Share Trading: 5% of every trade (compounding as trading volume grows)
  Content Sales: fixed price per gated post/video
  Subscription: streaming USDC/month for exclusive channel access

SECONDARY REVENUE
  Referrals: 1% of trades from referred users
  Curation: take % when creator's tokens are featured in discovery feed
  Launchpad: fee when creator launches their own token

TOKEN APPRECIATION
  Creator holds 10% of their own token supply
  As community grows, token price appreciates (bonding curve)
  Creator's bag worth more as they become popular

ANTI-PUMP-AND-DUMP DESIGN
  Creator must hold 1 key at all times (skin in the game)
  Large sells broadcast publicly (transparent — community can see)
  Vesting on creator's allocation: can only sell 10% per month
  Reputational penalty: community knows if creator dumps on them
```
