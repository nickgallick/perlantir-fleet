// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PumpLaunchpad — Pump.fun Clone on Base
 * @notice Bonding curve token launch → auto-migration to Uniswap V2 at graduation
 *
 * MECHANISM:
 *   1. Anyone creates a token (free, or small creation fee)
 *   2. Token launches on a linear bonding curve held entirely by this contract
 *   3. Users buy/sell against the curve. Price rises on buys, falls on sells.
 *   4. When virtual market cap reaches GRADUATION_MCAP:
 *      → All ETH reserve + 20% token reserve → Uniswap LP
 *      → LP tokens burned permanently
 *      → Token is now a real DEX token
 *
 * PRICE FORMULA (Linear Curve):
 *   price(s) = BASE_PRICE + SLOPE * s
 *   Cost to buy t tokens from supply s:
 *     ∫[s→s+t] price(x)dx = BASE_PRICE*t + SLOPE*(s*t + t²/2)
 *
 * ANTI-RUG:
 *   - All ETH is locked in this contract (not a wallet)
 *   - Creator gets no special allocation (fair launch)
 *   - Graduation is automatic and trustless
 *   - LP burned on graduation = permanent liquidity
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

// ─── Minimal ERC-20 for bonding curve tokens ────────────────────────────────

contract CurveToken is ERC20 {
    address public immutable launchpad;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        launchpad = msg.sender;
        // All supply minted to launchpad — launchpad manages distribution
        _mint(msg.sender, 1_000_000_000 * 1e18);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == launchpad, "Only launchpad");
        _burn(from, amount);
    }
}

// ─── Main launchpad ─────────────────────────────────────────────────────────

contract PumpLaunchpad is Ownable, ReentrancyGuard {

    // ─── Constants ──────────────────────────────────────────────────────────
    uint256 public constant TOTAL_SUPPLY      = 1_000_000_000 * 1e18; // 1B tokens
    uint256 public constant DEX_RESERVE_PCT   = 20;   // 20% of supply reserved for DEX LP
    uint256 public constant CURVE_SUPPLY      = TOTAL_SUPPLY * 80 / 100; // 80% sold on curve

    // Bonding curve parameters
    // Linear: price(s) = BASE_PRICE + SLOPE * s
    // At s=0: price ≈ $0.000001 ETH
    // At s=800M (full curve): price ≈ $0.000086 ETH (~86x from start)
    uint256 public constant BASE_PRICE = 27e9;        // 0.000000027 ETH per token (wei)
    uint256 public constant SLOPE      = 73e0;        // wei increase per token (tiny)

    // Graduation: when ETH raised ≈ $69K equivalent (uses token market cap proxy)
    // At ETH=3000, graduation ETH ≈ 23 ETH ≈ $69K
    uint256 public constant GRADUATION_ETH = 23 ether;

    // Fees
    uint256 public constant PLATFORM_FEE_BPS = 100;  // 1% on every trade
    uint256 public constant CREATION_FEE     = 0.01 ether; // Optional creation fee

    // ─── Storage ────────────────────────────────────────────────────────────
    struct Pool {
        address creator;
        address token;
        uint256 ethReserve;     // ETH currently held by curve
        uint256 tokensSold;     // Tokens sold from curve so far
        bool    graduated;      // Has migrated to DEX?
        string  name;
        string  symbol;
        string  imageUri;
        string  description;
        uint256 createdAt;
    }

    mapping(address => Pool) public pools;   // token → pool
    address[] public allTokens;
    address public immutable router;
    address public treasury;

    // ─── Events ──────────────────────────────────────────────────────────────
    event TokenCreated(
        address indexed token,
        address indexed creator,
        string name,
        string symbol,
        string imageUri
    );
    event Trade(
        address indexed token,
        address indexed trader,
        bool    isBuy,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 newSupply,
        uint256 newEthReserve
    );
    event Graduated(
        address indexed token,
        address indexed uniswapPair,
        uint256 ethAdded,
        uint256 tokensAdded
    );

    // ─── Constructor ──────────────────────────────────────────────────────────
    constructor(address _router, address _treasury) {
        router   = _router;
        treasury = _treasury;
    }

    // ─── Create Token ─────────────────────────────────────────────────────────

    function createToken(
        string calldata name,
        string calldata symbol,
        string calldata imageUri,
        string calldata description
    ) external payable nonReentrant returns (address tokenAddr) {
        require(msg.value >= CREATION_FEE, "Creation fee required");
        require(bytes(name).length > 0 && bytes(symbol).length <= 8, "Invalid name/symbol");

        // Deploy token (all supply to launchpad)
        CurveToken token = new CurveToken(name, symbol);
        tokenAddr = address(token);

        pools[tokenAddr] = Pool({
            creator:     msg.sender,
            token:       tokenAddr,
            ethReserve:  0,
            tokensSold:  0,
            graduated:   false,
            name:        name,
            symbol:      symbol,
            imageUri:    imageUri,
            description: description,
            createdAt:   block.timestamp
        });

        allTokens.push(tokenAddr);
        emit TokenCreated(tokenAddr, msg.sender, name, symbol, imageUri);

        // Forward creation fee to treasury
        (bool ok,) = treasury.call{value: CREATION_FEE}("");
        require(ok, "Treasury transfer failed");

        // If creator sent extra ETH, use it to buy initial tokens (optional)
        uint256 buyEth = msg.value - CREATION_FEE;
        if (buyEth > 0) {
            _buy(tokenAddr, buyEth, 0);
        }
    }

    // ─── Buy ──────────────────────────────────────────────────────────────────

    function buy(address token, uint256 minTokens) external payable nonReentrant {
        require(msg.value > 0, "Send ETH to buy");
        _buy(token, msg.value, minTokens);
    }

    function _buy(address token, uint256 ethIn, uint256 minTokens) internal {
        Pool storage pool = pools[token];
        require(pool.token != address(0), "Unknown token");
        require(!pool.graduated, "Token graduated — use DEX");

        // Platform fee
        uint256 fee    = ethIn * PLATFORM_FEE_BPS / 10_000;
        uint256 netEth = ethIn - fee;
        _sendFee(fee);

        // How many tokens does netEth buy?
        uint256 tokensOut = _getTokensForEth(pool.tokensSold, netEth);
        require(tokensOut >= minTokens, "Slippage exceeded");
        require(pool.tokensSold + tokensOut <= CURVE_SUPPLY, "Curve exhausted");

        // Update state
        pool.ethReserve += netEth;
        pool.tokensSold += tokensOut;

        // Transfer tokens to buyer
        IERC20(token).transfer(msg.sender, tokensOut);

        emit Trade(token, msg.sender, true, ethIn, tokensOut, pool.tokensSold, pool.ethReserve);

        // Graduation check
        if (pool.ethReserve >= GRADUATION_ETH) {
            _graduate(token);
        }
    }

    // ─── Sell ─────────────────────────────────────────────────────────────────

    function sell(address token, uint256 tokenIn, uint256 minEth) external nonReentrant {
        require(tokenIn > 0, "Zero token amount");
        Pool storage pool = pools[token];
        require(!pool.graduated, "Token graduated — use DEX");

        // How much ETH do these tokens yield?
        uint256 ethOut = _getEthForTokens(pool.tokensSold, tokenIn);
        require(ethOut > 0, "Zero ETH out");

        uint256 fee    = ethOut * PLATFORM_FEE_BPS / 10_000;
        uint256 netEth = ethOut - fee;
        require(netEth >= minEth, "Slippage exceeded");
        require(pool.ethReserve >= ethOut, "Insufficient reserve");

        // Pull tokens from seller
        IERC20(token).transferFrom(msg.sender, address(this), tokenIn);

        // Update state
        pool.ethReserve -= ethOut;
        pool.tokensSold -= tokenIn;

        // Send fee + ETH to seller
        _sendFee(fee);
        (bool ok,) = msg.sender.call{value: netEth}("");
        require(ok, "ETH transfer failed");

        emit Trade(token, msg.sender, false, netEth, tokenIn, pool.tokensSold, pool.ethReserve);
    }

    // ─── Graduation ───────────────────────────────────────────────────────────

    function _graduate(address tokenAddr) internal {
        Pool storage pool = pools[tokenAddr];
        pool.graduated = true;

        // DEX gets: all ETH reserve + 20% token supply
        uint256 dexTokens = TOTAL_SUPPLY * DEX_RESERVE_PCT / 100;
        uint256 dexEth    = pool.ethReserve;
        pool.ethReserve   = 0;

        // Add liquidity to Uniswap V2
        IUniswapV2Router02 uniRouter = IUniswapV2Router02(router);
        IERC20(tokenAddr).approve(router, dexTokens);

        (, , uint256 lpAmount) = uniRouter.addLiquidityETH{value: dexEth}(
            tokenAddr,
            dexTokens,
            0,                      // Accept any token amount
            0,                      // Accept any ETH amount
            address(0xdead),        // ← LP tokens burned = PERMANENT LIQUIDITY
            block.timestamp + 30
        );

        // Burn remaining curve tokens (the 80% that wasn't fully sold, if any)
        uint256 remainingCurveTokens = IERC20(tokenAddr).balanceOf(address(this));
        if (remainingCurveTokens > 0) {
            CurveToken(tokenAddr).burn(address(this), remainingCurveTokens);
        }

        address uniPair = IUniswapV2Factory(uniRouter.factory()).getPair(
            tokenAddr, uniRouter.WETH()
        );

        emit Graduated(tokenAddr, uniPair, dexEth, dexTokens);
    }

    // ─── Bonding Curve Math ───────────────────────────────────────────────────

    /**
     * @notice How many tokens can you buy with `ethIn` wei given current supply `s`?
     * @dev Solves: ethIn = BASE_PRICE*t + SLOPE*(s*t + t²/2) for t
     *      Quadratic: (SLOPE/2)*t² + (BASE_PRICE + SLOPE*s)*t - ethIn = 0
     *      t = [ -b + sqrt(b² + 4*(SLOPE/2)*ethIn) ] / (2*(SLOPE/2))
     *        = [ -b + sqrt(b² + 2*SLOPE*ethIn) ] / SLOPE
     *      where b = BASE_PRICE + SLOPE*s
     */
    function _getTokensForEth(uint256 currentSold, uint256 ethIn) internal pure returns (uint256) {
        // b = BASE_PRICE + SLOPE * currentSold
        uint256 b = BASE_PRICE + (SLOPE * currentSold / 1e18);

        // discriminant = b² + 2*SLOPE*ethIn
        uint256 disc = b * b + 2 * SLOPE * ethIn / 1e18;
        uint256 sqrtDisc = _sqrt(disc);

        // t = (sqrt(disc) - b) / SLOPE  [in tokens, scaled by 1e18]
        require(sqrtDisc >= b, "Math underflow");
        return (sqrtDisc - b) * 1e18 / SLOPE;
    }

    /**
     * @notice How much ETH do you get for selling `tokenAmount` tokens given supply `s`?
     * @dev ETH = integral from (s - tokenAmount) to s of price(x)dx
     *         = BASE_PRICE*t + SLOPE*(s² - s0²)/2
     *     where s0 = s - t
     */
    function _getEthForTokens(uint256 currentSold, uint256 tokenAmount) internal pure returns (uint256) {
        require(tokenAmount <= currentSold, "Cannot sell more than minted");
        uint256 s1 = currentSold;
        uint256 s0 = currentSold - tokenAmount;
        // BASE_PRICE * tokenAmount + SLOPE * (s1² - s0²) / 2
        uint256 base = BASE_PRICE * tokenAmount / 1e18;
        uint256 slop = SLOPE * (s1 * s1 - s0 * s0) / 2 / 1e36;
        return base + slop;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    function _sendFee(uint256 amount) internal {
        if (amount > 0) {
            (bool ok,) = treasury.call{value: amount}("");
            require(ok, "Fee transfer failed");
        }
    }

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) { y = z; z = (x / z + z) / 2; }
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Current token price in ETH wei
    function getPrice(address token) external view returns (uint256) {
        Pool storage pool = pools[token];
        return BASE_PRICE + SLOPE * pool.tokensSold / 1e18;
    }

    /// @notice ETH cost to buy `amount` tokens right now
    function getBuyQuote(address token, uint256 amount) external view returns (uint256 ethCost) {
        Pool storage pool = pools[token];
        uint256 s = pool.tokensSold;
        uint256 base = BASE_PRICE * amount / 1e18;
        uint256 slop = SLOPE * (2 * s * amount + amount * amount) / 2 / 1e36;
        uint256 gross = base + slop;
        uint256 fee = gross * PLATFORM_FEE_BPS / 10_000;
        return gross + fee;
    }

    /// @notice ETH received for selling `amount` tokens right now
    function getSellQuote(address token, uint256 amount) external view returns (uint256 ethOut) {
        Pool storage pool = pools[token];
        uint256 gross = _getEthForTokens(pool.tokensSold, amount);
        uint256 fee   = gross * PLATFORM_FEE_BPS / 10_000;
        return gross - fee;
    }

    /// @notice Progress toward graduation (0-100%)
    function graduationProgress(address token) external view returns (uint256 pct) {
        Pool storage pool = pools[token];
        if (pool.graduated) return 100;
        return pool.ethReserve * 100 / GRADUATION_ETH;
    }

    function allTokensLength() external view returns (uint256) { return allTokens.length; }

    receive() external payable {}
}
