// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MemeCoin — Production-Ready Launch Contract
 * @notice Anti-bot, auto-liquidity tax, sandwich protection
 * @dev Deploy → addLiquidity → enableTrading → removeLimits → renounceOwnership
 *
 * SECURITY CHECKLIST before renouncing ownership:
 *  ✅ No hidden mint()
 *  ✅ LP locked/burned with proof
 *  ✅ Tax ≤ 10% after launch phase
 *  ✅ maxTx/maxWallet removable by owner (not permanent restrictions)
 *  ✅ blacklist() cannot target the Uniswap pair
 *  ✅ Verified on Etherscan
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract MemeCoin is ERC20, Ownable {
    // ─── Supply ────────────────────────────────────────────────────────────
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18; // 1 billion

    // ─── Uniswap ───────────────────────────────────────────────────────────
    IUniswapV2Router02 public immutable router;
    address public immutable pair;

    // ─── Anti-bot limits (removed post-launch) ────────────────────────────
    uint256 public maxTxAmount      = TOTAL_SUPPLY / 100;   // 1%
    uint256 public maxWalletAmount  = TOTAL_SUPPLY * 2 / 100; // 2%
    bool    public limitsActive     = true;

    // ─── Trading gate ──────────────────────────────────────────────────────
    bool    public tradingEnabled;
    uint256 public launchBlock;
    uint256 public constant LAUNCH_BLOCKS = 3;  // High-tax for first 3 blocks
    uint256 public constant LAUNCH_TAX    = 30; // 30% launch tax (punishes snipe bots)

    // ─── Normal taxes (basis points: 100 = 1%) ────────────────────────────
    uint256 public buyTaxBps  = 500; // 5%
    uint256 public sellTaxBps = 500; // 5%

    // ─── Tax distribution splits (sum must = 100) ─────────────────────────
    uint256 public constant MARKETING_SHARE  = 40; // 40% → marketingWallet
    uint256 public constant LIQUIDITY_SHARE  = 40; // 40% → auto-liquidity (BOTH tokens + ETH)
    uint256 public constant BURN_SHARE       = 20; // 20% → 0xdead

    address public marketingWallet;

    // ─── Tax swap ─────────────────────────────────────────────────────────
    uint256 public tokensAccumulated;
    uint256 public swapThreshold = TOTAL_SUPPLY / 2000; // 0.05% triggers swap
    bool    private _swapping;

    // ─── Sandwich protection ──────────────────────────────────────────────
    // One transaction per address per block (stops multi-tx sandwich in same block)
    mapping(address => uint256) public lastTxBlock;

    // ─── Exemptions & blacklist ───────────────────────────────────────────
    mapping(address => bool) public isExempt;   // No tax, no limits
    mapping(address => bool) public isBlacklist; // Blocked (snipers caught at launch)

    // ─── Events ───────────────────────────────────────────────────────────
    event TradingEnabled(uint256 blockNumber);
    event LimitsRemoved();
    event OwnershipRenounced();
    event TaxSwap(uint256 tokensSwapped, uint256 ethReceived, uint256 liquidityAdded);
    event BlacklistUpdated(address indexed account, bool status);
    event TaxesUpdated(uint256 buyBps, uint256 sellBps);

    // ─── Constructor ──────────────────────────────────────────────────────
    constructor(
        address _router,      // Uniswap V2 router address
        address _marketing    // Marketing wallet (NOT deployer)
    ) ERC20("MemeCoin", "MEME") {
        require(_router    != address(0), "zero router");
        require(_marketing != address(0), "zero marketing");

        router          = IUniswapV2Router02(_router);
        marketingWallet = _marketing;

        // Create pair
        pair = IUniswapV2Factory(router.factory())
            .createPair(address(this), router.WETH());

        // Exemptions
        isExempt[owner()]           = true;
        isExempt[address(this)]     = true;
        isExempt[address(0xdead)]   = true;
        isExempt[_marketing]        = true;

        // Mint full supply to deployer
        // Deployer immediately adds liquidity, then calls enableTrading()
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    // ──────────────────────────── ADMIN ───────────────────────────────────

    /// @notice Call AFTER adding initial liquidity. Bots can't buy before this.
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        tradingEnabled = true;
        launchBlock    = block.number;
        emit TradingEnabled(block.number);
    }

    /// @notice Remove max tx / max wallet limits. Call after 1-24h of stable trading.
    function removeLimits() external onlyOwner {
        limitsActive = false;
        emit LimitsRemoved();
    }

    /// @notice Reduce taxes over time to build community trust. Both values in bps.
    function setTaxes(uint256 _buyBps, uint256 _sellBps) external onlyOwner {
        require(_buyBps <= 1000 && _sellBps <= 1000, "Max 10%"); // Hard cap: can't rug with taxes
        buyTaxBps  = _buyBps;
        sellTaxBps = _sellBps;
        emit TaxesUpdated(_buyBps, _sellBps);
    }

    /// @notice Blacklist wallets caught sniping. CANNOT blacklist the pair.
    function setBlacklist(address account, bool status) external onlyOwner {
        require(account != pair && account != address(router), "Cannot blacklist DEX");
        isBlacklist[account] = status;
        emit BlacklistUpdated(account, status);
    }

    function setExempt(address account, bool status) external onlyOwner {
        isExempt[account] = status;
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0));
        marketingWallet = newWallet;
    }

    function setSwapThreshold(uint256 amount) external onlyOwner {
        swapThreshold = amount;
    }

    // ──────────────────────────── TRANSFER ────────────────────────────────

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // ── Sanity ──────────────────────────────────────────────
        require(from != address(0) && to != address(0), "Zero address");
        require(!isBlacklist[from] && !isBlacklist[to], "Blacklisted");
        if (amount == 0) { super._transfer(from, to, 0); return; }

        bool isBuy  = from == pair;
        bool isSell = to   == pair;
        bool takeTax = !isExempt[from] && !isExempt[to];

        // ── Trading gate ────────────────────────────────────────
        if (takeTax) {
            require(tradingEnabled, "Trading not enabled");

            // ── Anti-sandwich: 1 tx per address per block ───────
            if (isBuy || isSell) {
                require(lastTxBlock[from] < block.number, "Sandwich protection");
                lastTxBlock[from] = block.number;
            }

            // ── Limits (active until removeLimits()) ────────────
            if (limitsActive) {
                if (isBuy) {
                    require(amount <= maxTxAmount, "Exceeds maxTx");
                    require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds maxWallet");
                } else if (isSell) {
                    require(amount <= maxTxAmount, "Exceeds maxTx");
                }
            }
        }

        // ── Auto tax-swap (only on sells, not when already swapping) ──
        bool canSwap = !_swapping
            && isSell
            && !isExempt[from]
            && tokensAccumulated >= swapThreshold;

        if (canSwap) {
            _swapping = true;
            _swapAndDistribute(tokensAccumulated);
            tokensAccumulated = 0;
            _swapping = false;
        }

        // ── Calculate and deduct tax ─────────────────────────────
        uint256 taxAmount;
        if (takeTax && (isBuy || isSell)) {
            uint256 taxRate = _getCurrentTaxRate(isBuy);
            if (taxRate > 0) {
                taxAmount = amount * taxRate / 100;
                tokensAccumulated += taxAmount;
                super._transfer(from, address(this), taxAmount);
                amount -= taxAmount;
            }
        }

        super._transfer(from, to, amount);
    }

    function _getCurrentTaxRate(bool isBuy) internal view returns (uint256) {
        // Launch phase: punish snipers
        if (block.number <= launchBlock + LAUNCH_BLOCKS) return LAUNCH_TAX;
        // Normal taxes (bps → percent: divide by 100)
        return isBuy ? buyTaxBps / 100 : sellTaxBps / 100;
    }

    // ──────────────────────────── TAX SWAP ────────────────────────────────

    function _swapAndDistribute(uint256 totalTokens) internal {
        // Split: half of liquidity share kept as tokens, rest swapped to ETH
        uint256 liquidityTokenHalf = totalTokens * LIQUIDITY_SHARE / 100 / 2;
        uint256 tokensToSwap       = totalTokens - liquidityTokenHalf; // marketing + liq ETH + burn

        // Burn portion: send directly to dead (don't need to swap)
        uint256 burnTokens = totalTokens * BURN_SHARE / 100;
        if (burnTokens > 0) {
            super._transfer(address(this), address(0xdead), burnTokens);
            tokensToSwap -= burnTokens;
        }

        // Swap remaining to ETH
        uint256 ethBefore = address(this).balance;
        _swapTokensForEth(tokensToSwap);
        uint256 ethGained = address(this).balance - ethBefore;

        // Split ETH: marketing vs liquidity
        // Liquidity share is 40% of original (minus burn+marketing), 
        // marketing is 40% of original. Ratios relative to (marketing+liq) split.
        uint256 ethForMarketing  = ethGained * MARKETING_SHARE / (MARKETING_SHARE + LIQUIDITY_SHARE);
        uint256 ethForLiquidity  = ethGained - ethForMarketing;

        // Send marketing ETH
        if (ethForMarketing > 0) {
            (bool ok,) = marketingWallet.call{value: ethForMarketing}("");
            require(ok, "Marketing transfer failed");
        }

        // Add auto-liquidity
        if (liquidityTokenHalf > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokenHalf, ethForLiquidity);
        }

        emit TaxSwap(totalTokens, ethGained, liquidityTokenHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,           // accept any ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,                    // min tokens (slippage OK for auto-liq)
            0,                    // min ETH
            address(0xdead),      // LP tokens → dead address = permanent liquidity
            block.timestamp
        );
    }

    // ──────────────────────────── MISC ────────────────────────────────────

    /// @dev Accepts ETH from Uniswap router during tax swaps
    receive() external payable {}

    /// @notice Emergency: recover non-MEME tokens accidentally sent to contract
    function rescueTokens(address token) external onlyOwner {
        require(token != address(this), "Cannot rescue MEME");
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    /// @notice View current effective tax rate
    function currentTaxRate(bool isBuy) external view returns (uint256 pct) {
        if (!tradingEnabled) return 0;
        return _getCurrentTaxRate(isBuy);
    }
}
