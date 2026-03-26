# Launchpad & IDO Platforms

## Bonding Curve Launchpad (Pump.fun Clone on Base)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BondingCurveToken is ERC20 {
    address public immutable launchpad;
    bool public graduated; // True after migration to DEX

    constructor(string memory name, string memory symbol, address _launchpad)
        ERC20(name, symbol)
    {
        launchpad = _launchpad;
        _mint(_launchpad, 1_000_000_000 * 1e18); // All supply to launchpad
    }
}

contract PumpLaunchpad is Ownable {
    IUniswapV2Router02 public immutable router;

    uint256 public constant GRADUATION_MCAP = 69_000e18; // $69K in token terms
    uint256 public constant PLATFORM_FEE_BPS = 100;      // 1% on each trade
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18;

    // Bonding curve: price = BASE_PRICE + (supply * K)
    // This is a linear bonding curve. Quadratic/sigmoid possible.
    uint256 public constant BASE_PRICE = 0.000000027 ether; // Start cheap
    uint256 public constant K = 0.000000000000027 ether;    // Price increase per token sold

    struct TokenPool {
        address creator;
        address token;
        uint256 ethReserve;
        uint256 tokensSold;  // How many bought from curve so far
        bool graduated;
    }

    mapping(address => TokenPool) public pools; // token → pool
    address[] public allTokens;

    event TokenCreated(address indexed token, address indexed creator, string name, string symbol);
    event Trade(address indexed token, address indexed trader, bool isBuy, uint256 ethAmount, uint256 tokenAmount);
    event Graduated(address indexed token, address uniswapPair);

    // ──────── CREATE TOKEN ────────

    function createToken(
        string calldata name,
        string calldata symbol,
        string calldata description,
        string calldata imageUri
    ) external payable returns (address) {
        // Deploy token
        BondingCurveToken token = new BondingCurveToken(name, symbol, address(this));
        address tokenAddr = address(token);

        pools[tokenAddr] = TokenPool({
            creator:    msg.sender,
            token:      tokenAddr,
            ethReserve: 0,
            tokensSold: 0,
            graduated:  false
        });
        allTokens.push(tokenAddr);

        emit TokenCreated(tokenAddr, msg.sender, name, symbol);

        // If creator sends ETH, buy some tokens immediately
        if (msg.value > 0) {
            _buy(tokenAddr, msg.value, 0);
        }

        return tokenAddr;
    }

    // ──────── BUY ────────

    function buy(address token, uint256 minTokens) external payable {
        _buy(token, msg.value, minTokens);
    }

    function _buy(address token, uint256 ethIn, uint256 minTokens) internal {
        TokenPool storage pool = pools[token];
        require(!pool.graduated, "Use DEX");
        require(ethIn > 0, "Zero ETH");

        // Deduct platform fee
        uint256 fee = ethIn * PLATFORM_FEE_BPS / 10_000;
        uint256 netEth = ethIn - fee;
        payable(owner()).transfer(fee);

        // Calculate tokens out using bonding curve integral
        uint256 tokensOut = _getTokensOut(pool.tokensSold, netEth);
        require(tokensOut >= minTokens, "Slippage");
        require(pool.tokensSold + tokensOut <= TOTAL_SUPPLY * 80 / 100, "Reserve 20% for DEX LP");

        pool.ethReserve += netEth;
        pool.tokensSold += tokensOut;

        IERC20(token).transfer(msg.sender, tokensOut);
        emit Trade(token, msg.sender, true, ethIn, tokensOut);

        // Check graduation
        if (_marketCap(pool.tokensSold) >= GRADUATION_MCAP) {
            _graduate(token);
        }
    }

    // ──────── SELL ────────

    function sell(address token, uint256 tokenIn, uint256 minEth) external {
        TokenPool storage pool = pools[token];
        require(!pool.graduated, "Use DEX");

        uint256 ethOut = _getEthOut(pool.tokensSold, tokenIn);
        uint256 fee = ethOut * PLATFORM_FEE_BPS / 10_000;
        uint256 netEth = ethOut - fee;
        require(netEth >= minEth, "Slippage");
        require(pool.ethReserve >= ethOut, "Insufficient reserve");

        IERC20(token).transferFrom(msg.sender, address(this), tokenIn);
        pool.ethReserve -= ethOut;
        pool.tokensSold -= tokenIn;

        payable(owner()).transfer(fee);
        payable(msg.sender).transfer(netEth);

        emit Trade(token, msg.sender, false, netEth, tokenIn);
    }

    // ──────── GRADUATION (migrate to Uniswap) ────────

    function _graduate(address token) internal {
        TokenPool storage pool = pools[token];
        pool.graduated = true;

        // 20% of total supply was reserved for this moment
        uint256 liquidityTokens = TOTAL_SUPPLY * 20 / 100;
        uint256 liquidityEth    = pool.ethReserve;
        pool.ethReserve = 0;

        // Add liquidity to Uniswap V2
        IERC20(token).approve(address(router), liquidityTokens);
        (, , uint256 lpTokens) = router.addLiquidityETH{value: liquidityEth}(
            token,
            liquidityTokens,
            0, 0,
            address(0xdead), // Burn LP tokens → permanent liquidity
            block.timestamp
        );

        address pair = IUniswapV2Factory(router.factory()).getPair(token, router.WETH());
        emit Graduated(token, pair);
    }

    // ──────── BONDING CURVE MATH ────────

    // Linear curve: price(s) = BASE_PRICE + K * s
    // Integral from s0 to s0+t: cost = BASE_PRICE*t + K*(s0*t + t²/2)
    function _getTokensOut(uint256 currentSold, uint256 ethIn) internal pure returns (uint256) {
        // Quadratic formula: K/2 * t² + (BASE_PRICE + K*s0) * t - ethIn = 0
        // Solving for t using quadratic formula
        uint256 a = K / 2;
        uint256 b = BASE_PRICE + K * currentSold;
        // t = (-b + sqrt(b² + 4*a*ethIn)) / (2*a)
        uint256 discriminant = b * b + 4 * a * ethIn;
        uint256 sqrtDisc = _sqrt(discriminant);
        return (sqrtDisc - b) / (2 * a);
    }

    function _getEthOut(uint256 currentSold, uint256 tokensIn) internal pure returns (uint256) {
        uint256 s1 = currentSold;
        uint256 s0 = currentSold - tokensIn;
        return BASE_PRICE * tokensIn + K * (s1 * s1 - s0 * s0) / 2;
    }

    function _marketCap(uint256 tokensSold) internal pure returns (uint256) {
        uint256 currentPrice = BASE_PRICE + K * tokensSold;
        return currentPrice * TOTAL_SUPPLY / 1e18;
    }

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) { y = z; z = (x / z + z) / 2; }
    }

    receive() external payable {}
}
```

## Tier-Based Launchpad (Pinksale Style)

```solidity
contract TieredLaunchpad {
    // Stake SPARTA tokens → earn tier → get guaranteed allocation
    mapping(address => uint256) public stakedAmount;

    struct Tier {
        uint256 minStake;         // Min SPARTA to stake for this tier
        uint256 allocationMultiplier; // e.g., 3 = 3x base allocation
        bool guaranteed;          // True = guaranteed, False = lottery
    }

    Tier[4] public tiers = [
        Tier({ minStake: 0,       allocationMultiplier: 1, guaranteed: false }), // Public (lottery)
        Tier({ minStake: 1_000e18, allocationMultiplier: 2, guaranteed: false }), // Bronze (lottery)
        Tier({ minStake: 5_000e18, allocationMultiplier: 5, guaranteed: true  }), // Silver (guaranteed)
        Tier({ minStake: 20_000e18, allocationMultiplier: 20, guaranteed: true }) // Gold (guaranteed)
    ];

    function getUserAllocation(address user, uint256 baseSizePerTier) external view returns (uint256) {
        uint8 tier = getUserTier(user);
        return baseSizePerTier * tiers[tier].allocationMultiplier;
    }

    function getUserTier(address user) public view returns (uint8) {
        uint256 staked = stakedAmount[user];
        for (uint8 i = 3; i > 0; i--) {
            if (staked >= tiers[i].minStake) return i;
        }
        return 0;
    }
}
```
