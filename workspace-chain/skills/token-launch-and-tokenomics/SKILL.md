# Token Launch & Tokenomics

## Tokenomics Design Framework

### Supply Design
- **Fixed supply**: Max cap set at deployment (Bitcoin model). Deflationary if tokens burned.
- **Inflationary**: New tokens minted over time (staking rewards, team vesting). Must justify inflation with value creation.
- **Deflationary**: Burn mechanism. Revenue → buy + burn. Creates buy pressure.
- **Elastic**: Supply adjusts to maintain price target (algorithmic stablecoins — extremely risky).

### Distribution (Typical SaaS/Protocol Token)
```
Community/Ecosystem:  40-50%  (airdrops, liquidity mining, grants)
Team:                 15-20%  (4yr vest, 1yr cliff)
Investors (seed):      5-10%  (2yr vest, 6mo cliff)
Investors (series):    5-10%
Treasury:             20-25%  (DAO-controlled, for future use)
Liquidity:             5-10%  (initial DEX liquidity)
```
Red flags: >30% team allocation, no vesting, no cliff, team can dump on day 1.

### Vesting Contracts
```solidity
// OpenZeppelin VestingWallet
contract TeamVesting is VestingWallet {
    constructor(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds  // Linear vesting period
    ) VestingWallet(beneficiary, startTimestamp, durationSeconds) {}
    // cliff: add require(block.timestamp > startTimestamp + cliffDuration) override
}

// Release vested tokens
vestingWallet.release(address(token));

// Check available amount
uint256 releasable = vestingWallet.releasable(address(token));
```

### Cliff + Linear Vesting
```
12-month cliff: No tokens released for first year
48-month linear: After cliff, 1/36 of remaining released per month

Month 0-12:  0% released
Month 13:    25% released (cliff unlocks)
Month 14-48: +2.08% per month until 100%
```

## Token Utility Design
A token with no utility is a security risk (regulatory) and will trend to $0.

### Sustainable Utility Options
- **Governance**: Vote on protocol parameters. Weak utility alone — no price support.
- **Fee payment**: Pay protocol fees in token. Strong utility if protocol generates real fees.
- **Staking**: Lock token for share of protocol revenue. Must have revenue first.
- **Collateral**: Use token as collateral in protocol. Creates demand, but reflexive risk.
- **Access**: Hold token to access premium features. Works if features are valuable.
- **Work token**: Must stake token to provide service (earn rewards). Slashing for misbehavior.

**The trap**: Tokens whose only utility is "stake to earn more tokens" are Ponzis.

## Token Launch Mechanisms

### Liquidity Bootstrapping Pool (LBP) — Recommended
```
Start: 96% TOKEN / 4% USDC  → implied high price
Over 3 days: weights shift to 50%/50% → price naturally falls
Demand from buyers: offsets the price fall
Result: price discovery, anti-bot (bots can't front-run a falling price)
```
Used by: Balancer, Copium Protocol, many DeFi launches.

### Fair Launch
No pre-mine, no VCs. Mine/earn tokens through participation.
Maximum credibility but slow distribution and underfunded development.

### IDO (Initial DEX Offering)
Launch on Uniswap/PancakeSwap directly. Add liquidity, announce, let market discover price.
Simple but vulnerable to bots sniping launch.

### Merkle Airdrop
Efficient distribution to many addresses:
```solidity
contract MerkleAirdrop {
    bytes32 public immutable merkleRoot;
    mapping(address => bool) public claimed;

    function claim(address account, uint256 amount, bytes32[] calldata proof) external {
        require(!claimed[account], "Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        claimed[account] = true;
        token.transfer(account, amount);
    }
}
```
Generate Merkle tree off-chain (use @openzeppelin/merkle-tree). Publish root on-chain. Users claim with proof.

### Points → Tokens (Hyperliquid Model)
1. Run protocol, award points for activity
2. TGE: Convert points to tokens at defined ratio
3. No token speculation during growth phase
4. Reward real users, not farmers

## Value Accrual Mechanisms

### Buyback & Burn
Protocol revenue → buy token on DEX → burn → reduces supply → price appreciation.
```solidity
function buybackAndBurn(uint256 usdcAmount) external onlyOwner {
    // Swap USDC for governance token
    uint256 tokensBought = swapExactInputSingle(usdc, govToken, usdcAmount);
    // Burn the purchased tokens
    ERC20Burnable(govToken).burn(tokensBought);
}
```

### Fee Distribution (xToken Model)
Stake TOKEN → receive xTOKEN → xTOKEN represents pro-rata share of fee pool.
```solidity
// Stake: deposit TOKEN, receive xTOKEN
function enter(uint256 amount) external {
    uint256 totalToken = token.balanceOf(address(this));
    uint256 totalShares = totalSupply();
    uint256 xTokenAmount = totalShares == 0 ? amount : amount * totalShares / totalToken;
    _mint(msg.sender, xTokenAmount);
    token.safeTransferFrom(msg.sender, address(this), amount);
}

// Withdraw: burn xTOKEN, receive TOKEN + accrued fees
function leave(uint256 xTokenAmount) external {
    uint256 tokenAmount = xTokenAmount * token.balanceOf(address(this)) / totalSupply();
    _burn(msg.sender, xTokenAmount);
    token.safeTransfer(msg.sender, tokenAmount);
}
```

## Tokenomics Red Flags
- Team allocation >30% with no vesting
- "Burn" mechanism with no revenue to fund buybacks
- Governance utility only (no economic value)
- Inflationary rewards funded by more token emissions (infinite loop)
- Fully diluted valuation (FDV) >> circulating market cap (hidden supply overhang)
- Whale concentration: top 10 wallets hold >50% of circulating supply
