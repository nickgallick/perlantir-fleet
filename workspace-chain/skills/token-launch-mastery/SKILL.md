# Token Launch Mastery

## Meme Coin Contract — Production Pattern

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract MemeCoin is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Supply
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18; // 1B tokens

    // Anti-bot limits (removed after launch)
    uint256 public maxTxAmount = TOTAL_SUPPLY * 1 / 100;     // 1% max tx
    uint256 public maxWalletAmount = TOTAL_SUPPLY * 2 / 100; // 2% max wallet
    bool public limitsActive = true;

    // Trading
    bool public tradingEnabled = false;
    mapping(address => bool) public isBot;
    mapping(address => uint256) public lastTxBlock;

    // Launch tax (decays to normal after LAUNCH_BLOCKS)
    uint256 public launchBlock;
    uint256 public constant LAUNCH_BLOCKS = 5; // High tax for first 5 blocks
    uint256 public constant LAUNCH_TAX = 25;   // 25% during launch
    uint256 public constant BUY_TAX = 5;
    uint256 public constant SELL_TAX = 5;

    // Tax distribution (basis points, sums to 100)
    uint256 public marketingShare = 40;  // 40% of tax to marketing
    uint256 public liquidityShare = 40;  // 40% to auto-liquidity
    uint256 public burnShare = 20;       // 20% burned

    address public marketingWallet;
    uint256 public tokensForTax;
    uint256 public swapThreshold = TOTAL_SUPPLY * 5 / 10000; // 0.05% triggers swap
    bool private _swapping;

    // Exemptions
    mapping(address => bool) public isExempt; // from fees and limits

    event TradingEnabled(uint256 blockNumber);
    event LimitsRemoved();
    event BotBlacklisted(address indexed bot, bool status);
    event TaxSwapped(uint256 tokens, uint256 ethAmount);

    constructor(address _marketing, address _router) ERC20("MemeCoin", "MEME") {
        marketingWallet = _marketing;

        uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        isExempt[owner()] = true;
        isExempt[address(this)] = true;
        isExempt[address(0xdead)] = true;
        isExempt[marketingWallet] = true;

        _mint(msg.sender, TOTAL_SUPPLY);
    }

    // Owner enables trading AFTER adding liquidity
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        tradingEnabled = true;
        launchBlock = block.number;
        emit TradingEnabled(block.number);
    }

    function removeLimits() external onlyOwner {
        limitsActive = false;
        emit LimitsRemoved();
    }

    function blacklistBot(address bot, bool status) external onlyOwner {
        require(bot != uniswapV2Pair && bot != address(uniswapV2Router));
        isBot[bot] = status;
        emit BotBlacklisted(bot, status);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!isBot[from] && !isBot[to], "Blacklisted");

        if (!isExempt[from] && !isExempt[to]) {
            require(tradingEnabled, "Trading not enabled");

            // Anti-sandwich: max 1 tx per block from same address
            require(lastTxBlock[from] < block.number, "Sandwich protection");
            lastTxBlock[from] = block.number;

            if (limitsActive) {
                if (from == uniswapV2Pair) { // Buy
                    require(amount <= maxTxAmount, "Max tx exceeded");
                    require(balanceOf(to) + amount <= maxWalletAmount, "Max wallet exceeded");
                } else if (to == uniswapV2Pair) { // Sell
                    require(amount <= maxTxAmount, "Max tx exceeded");
                }
            }

            // Calculate tax
            uint256 tax = _getTaxRate(from, to);
            if (tax > 0) {
                uint256 taxAmount = amount * tax / 100;
                tokensForTax += taxAmount;

                // Auto-swap accumulated tax
                if (
                    !_swapping &&
                    to == uniswapV2Pair &&
                    tokensForTax >= swapThreshold
                ) {
                    _swapping = true;
                    _swapAndDistribute(tokensForTax);
                    tokensForTax = 0;
                    _swapping = false;
                }

                super._transfer(from, address(this), taxAmount);
                amount -= taxAmount;
            }
        }

        super._transfer(from, to, amount);
    }

    function _getTaxRate(address from, address to) internal view returns (uint256) {
        // Launch phase: max tax
        if (block.number <= launchBlock + LAUNCH_BLOCKS) return LAUNCH_TAX;

        bool isBuy = from == uniswapV2Pair;
        bool isSell = to == uniswapV2Pair;

        if (isBuy) return BUY_TAX;
        if (isSell) return SELL_TAX;
        return 0; // wallet-to-wallet: no tax
    }

    function _swapAndDistribute(uint256 tokenAmount) internal {
        uint256 liquidityTokens = tokenAmount * liquidityShare / 100 / 2; // Half for LP
        uint256 tokensToSwap = tokenAmount - liquidityTokens;

        // Swap tokens for ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uint256 ethBefore = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap, 0, path, address(this), block.timestamp
        );
        uint256 ethGained = address(this).balance - ethBefore;

        // Split ETH
        uint256 ethForMarketing = ethGained * marketingShare / (100 - liquidityShare / 2);
        uint256 ethForLiquidity = ethGained - ethForMarketing;
        uint256 burnAmount = tokenAmount * burnShare / 100;

        // Send marketing
        payable(marketingWallet).transfer(ethForMarketing);

        // Add auto-liquidity
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            uniswapV2Router.addLiquidityETH{value: ethForLiquidity}(
                address(this), liquidityTokens, 0, 0, address(0xdead), block.timestamp
            );
        }

        // Burn
        if (burnAmount > 0) _burn(address(this), burnAmount);

        emit TaxSwapped(tokenAmount, ethGained);
    }

    receive() external payable {}
}
```

## Pump.fun Bonding Curve Pattern

```solidity
contract BondingCurveLaunch {
    // Price formula: price = INITIAL_PRICE * (1 + supply/SCALE)
    uint256 public constant INITIAL_PRICE = 0.000001 ether;
    uint256 public constant SCALE = 1_000_000 * 1e18;
    uint256 public constant MIGRATION_MCAP = 69_000 * 1e18; // $69K MCAP triggers migration
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    uint256 public currentSupply;
    uint256 public ethReserve;
    bool public migrated;
    IUniswapV2Router02 public router;
    IERC20 public token;

    function buy(uint256 minTokens) external payable {
        require(!migrated, "Migrated to DEX");
        uint256 tokens = _ethToTokens(msg.value);
        require(tokens >= minTokens, "Slippage");

        currentSupply += tokens;
        ethReserve += msg.value;

        token.transfer(msg.sender, tokens);

        // Check if should migrate
        if (_marketCap() >= MIGRATION_MCAP) {
            _migrateToUniswap();
        }
    }

    function sell(uint256 tokenAmount, uint256 minEth) external {
        require(!migrated, "Migrated to DEX");
        uint256 eth = _tokensToEth(tokenAmount);
        require(eth >= minEth, "Slippage");

        token.transferFrom(msg.sender, address(this), tokenAmount);
        currentSupply -= tokenAmount;
        ethReserve -= eth;

        payable(msg.sender).transfer(eth);
    }

    function _ethToTokens(uint256 ethAmount) internal view returns (uint256) {
        // Integrate price curve from currentSupply to currentSupply + tokens
        // price(s) = INITIAL_PRICE * (1 + s/SCALE)
        // Simplified linear approximation:
        uint256 avgPrice = INITIAL_PRICE * (1 + currentSupply / SCALE);
        return ethAmount * 1e18 / avgPrice;
    }

    function _tokensToEth(uint256 tokenAmount) internal view returns (uint256) {
        uint256 avgPrice = INITIAL_PRICE * (1 + (currentSupply - tokenAmount/2) / SCALE);
        return tokenAmount * avgPrice / 1e18;
    }

    function _marketCap() internal view returns (uint256) {
        uint256 price = INITIAL_PRICE * (1 + currentSupply / SCALE);
        return price * MAX_SUPPLY / 1e18;
    }

    function _migrateToUniswap() internal {
        migrated = true;
        // Add all ETH + remaining tokens as LP
        // Burn LP tokens (permanent liquidity)
        token.approve(address(router), token.balanceOf(address(this)));
        router.addLiquidityETH{value: ethReserve}(
            address(token),
            token.balanceOf(address(this)),
            0, 0,
            address(0xdead), // LP tokens burned → permanent liquidity
            block.timestamp
        );
    }
}
```

## Fair Launch vs Stealth Launch vs Presale

| Mode | Trust | Risk | Best For |
|------|-------|------|---------|
| Fair Launch | Highest | Low | Community tokens |
| Stealth | Medium | Medium | Organic discovery plays |
| Presale | Lowest | High | Funded teams with KPIs |

## Security Checklist Before Renouncing Ownership

- [ ] No hidden mint functions
- [ ] Ownership renounced or behind multisig
- [ ] LP locked 6+ months or burned
- [ ] Tax ≤ 10% (both buy and sell)
- [ ] No blacklist(pair) function that stops selling
- [ ] Contract verified on Etherscan
- [ ] Anti-bot limits have removal mechanism
