# CDP & Stablecoin Systems (MakerDAO)

## MakerDAO Core Architecture (Vat System)

```
Vat ← Core accounting (internal units, no external token calls)
 ├── Jug ← Stability fee accrual (drip)
 ├── Spot ← Price feed + liquidation trigger
 ├── Dog ← Initiates liquidations (bark)
 └── Clipper ← Dutch auction engine (take)

Join Adapters ← Convert external tokens to internal "gem"
 ├── GemJoin ← For ERC-20 collateral (WBTC, USDC, etc.)
 ├── ETHJoin ← For ETH
 └── DaiJoin ← For DAI (convert internal debt to ERC-20 DAI)

Pot ← DAI Savings Rate (DSR)
End ← Emergency shutdown
Cure ← Recovery after shutdown
```

## Vat: Core Accounting

```solidity
contract Vat {
    // All amounts in RAY (1e27) precision

    // Collateral: ilk (collateral type) → urn (vault) → collateral amount
    mapping(bytes32 => mapping(address => Urn)) public urns;

    // ilk parameters
    mapping(bytes32 => Ilk) public ilks;

    struct Urn {
        uint256 ink; // Collateral balance (in gem units)
        uint256 art; // Normalized debt (actual debt = art × ilk.rate)
    }

    struct Ilk {
        uint256 Art;  // Total normalized debt
        uint256 rate; // Accumulated stability fee (starts at 1e27, grows over time)
        uint256 spot; // Price × liquidation ratio
        uint256 line; // Debt ceiling
        uint256 dust; // Minimum vault size
    }

    // Open/modify vault
    function frob(
        bytes32 ilk,        // Collateral type (e.g., "ETH-A")
        address u,          // Urn owner
        address v,          // Collateral source
        address w,          // Dai destination
        int256 dink,        // Collateral delta (positive = add, negative = remove)
        int256 dart         // Debt delta (positive = borrow, negative = repay)
    ) external {
        Urn memory urn = urns[ilk][u];
        Ilk memory ilk_ = ilks[ilk];

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk_.Art = _add(ilk_.Art, dart);

        // Validate: collateral × spot ≥ debt × rate
        // spot = (price / liquidation_ratio), so this checks collateral ratio
        uint256 tab = ilk_.rate * urn.art; // actual debt value
        require(tab <= urn.ink * ilk_.spot, "Vat/not-safe");

        urns[ilk][u] = urn;
        ilks[ilk] = ilk_;
    }

    // Liquidate: seize collateral from unsafe vault
    function grab(bytes32 ilk, address u, address v, address w, int256 dink, int256 dart) external auth {
        // Used by Dog contract to initiate liquidation
        // Transfers ink to auction, creates bad debt
    }
}
```

## Jug: Stability Fee Accrual

```solidity
contract Jug {
    Vat public vat;

    struct Ilk {
        uint256 duty; // Per-second fee (e.g., 1.000000005782 ≈ 2% APY)
        uint256 rho;  // Last drip time
    }

    mapping(bytes32 => Ilk) public ilks;
    uint256 public base; // Global base rate

    // Called every time someone interacts with a vault
    // (or can be called by keeper bots to keep rates current)
    function drip(bytes32 ilk) public returns (uint256 rate) {
        Ilk storage i = ilks[ilk];
        require(block.timestamp >= i.rho, "Jug/invalid-now");

        // Compound the rate since last drip
        // rate = old_rate × (base + duty)^(time_elapsed)
        // Simplified: rate × (1 + (base + duty - 1) × elapsed)
        uint256 elapsed = block.timestamp - i.rho;
        rate = vat.ilks(ilk).rate * _rpow(base + i.duty, elapsed, 1e27) / 1e27;

        vat.fold(ilk, vow, int256(rate) - int256(vat.ilks(ilk).rate));
        i.rho = block.timestamp;
    }
}
```

## Dog + Clipper: Liquidation 2.0 (Dutch Auction)

```solidity
contract Dog {
    Vat public vat;
    mapping(bytes32 => Ilk) public ilks;

    struct Ilk {
        address clip;  // Auction contract for this collateral
        uint256 chop;  // Liquidation penalty (e.g., 1.13e18 = 13%)
        uint256 hole;  // Max debt auctioned per ilk at one time
        uint256 dirt;  // Current debt being auctioned
    }

    // Initiate liquidation of an unsafe vault
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id) {
        Vat.Urn memory u = vat.urns(ilk, urn);
        Vat.Ilk memory i = vat.ilks(ilk);

        // Check vault is unsafe
        require(u.ink * i.spot < u.art * i.rate, "Dog/not-unsafe");

        uint256 dart = u.art; // All debt to liquidate
        uint256 dink = u.ink; // All collateral

        // Seize collateral from vault
        vat.grab(ilk, urn, address(clip), address(vow), -int256(dink), -int256(dart));

        // Start Dutch auction
        uint256 tab = (dart * i.rate * ilks[ilk].chop) / 1e27; // debt × penalty
        id = Clipper(ilks[ilk].clip).kick(tab, dink, urn, kpr);
    }
}

contract Clipper {
    // Dutch auction: price starts HIGH and DECREASES over time
    // Anyone can buy at any time — they just wait for price they like

    struct Sale {
        uint256 pos;    // Index in active auctions array
        uint256 tab;    // Total DAI to raise
        uint256 lot;    // Collateral available
        address usr;    // Original vault owner
        uint96  tic;    // Auction start time
        uint256 top;    // Starting price
    }

    // Buy collateral at current auction price
    function take(
        uint256 id,       // Auction ID
        uint256 amt,      // Max collateral to buy
        uint256 max,      // Max acceptable price (slippage protection)
        address who,      // Collateral recipient
        bytes calldata data // Flash callback data
    ) external {
        Sale memory sale = sales[id];
        uint256 price = calc.price(sale.top, block.timestamp - sale.tic);
        require(price <= max, "Clipper/too-expensive");

        // Flash loan pattern: send collateral first, receive DAI after callback
        if (data.length > 0) {
            vat.flux(ilk, address(this), who, slice);
            ClipperCallee(who).clipperCall(msg.sender, owe, slice, data);
        }

        // Collect DAI payment
        vat.move(who, vow, owe);
    }
}
```

## Peg Stability Module (PSM)

```solidity
contract DssPsm {
    Vat public vat;
    GemJoin public gemJoin;
    DaiJoin public daiJoin;

    uint256 public tin;  // Fee for selling gem (USDC) to get DAI
    uint256 public tout; // Fee for buying gem with DAI

    // Swap USDC → DAI (1:1 minus tin fee)
    function sellGem(address usr, uint256 gemAmt) external {
        uint256 gemAmt18 = gemAmt * 1e12; // Scale USDC (6 dec) to 18 dec
        uint256 fee = gemAmt18 * tin / 1e18;
        uint256 daiAmt = gemAmt18 - fee;

        // Pull USDC from user
        gemJoin.gem().transferFrom(msg.sender, address(gemJoin), gemAmt);
        gemJoin.join(address(this), gemAmt);

        // Mint DAI from the vault
        vat.frob(ilk, address(this), address(this), address(this), int256(gemAmt18), int256(gemAmt18));
        daiJoin.exit(usr, daiAmt);

        // Fee goes to vow (MakerDAO treasury)
        if (fee > 0) daiJoin.exit(address(vow), fee);
    }

    // Swap DAI → USDC (1:1 minus tout fee)
    function buyGem(address usr, uint256 gemAmt) external {
        uint256 gemAmt18 = gemAmt * 1e12;
        uint256 fee = gemAmt18 * tout / 1e18;
        uint256 daiAmt = gemAmt18 + fee;

        daiJoin.dai().transferFrom(msg.sender, address(this), daiAmt);
        daiJoin.join(address(this), daiAmt);
        vat.frob(ilk, address(this), address(this), address(this), -int256(gemAmt18), -int256(gemAmt18));
        gemJoin.exit(usr, gemAmt);
    }
}
```

## DAI Savings Rate (DSR)

```solidity
contract Pot {
    Vat public vat;

    mapping(address => uint256) public pie;  // Normalized DSR balance
    uint256 public Pie;   // Total normalized DSR balance
    uint256 public dsr;   // DAI savings rate per second (e.g., 1.000000012857 ≈ 5% APY)
    uint256 public chi;   // Cumulative rate (starts at 1e27)
    uint256 public rho;   // Last drip time

    // Compound chi based on elapsed time
    function drip() public returns (uint256) {
        require(block.timestamp >= rho, "Pot/invalid-now");
        uint256 tmp = _rpow(dsr, block.timestamp - rho, 1e27) * chi / 1e27;
        vat.suck(address(0), address(this), (tmp - chi) * Pie); // Mint interest
        chi = tmp;
        rho = block.timestamp;
        return chi;
    }

    // Deposit DAI into DSR
    function join(uint256 wad) external {
        drip();
        uint256 normalized = wad * 1e27 / chi;
        pie[msg.sender] += normalized;
        Pie += normalized;
        vat.move(msg.sender, address(this), wad * 1e27);
    }

    // Withdraw DAI from DSR (with accrued interest)
    function exit(uint256 wad) external {
        drip();
        uint256 normalized = wad * 1e27 / chi;
        pie[msg.sender] -= normalized;
        Pie -= normalized;
        vat.move(address(this), msg.sender, wad * 1e27);
    }

    function balance(address user) external view returns (uint256) {
        return pie[user] * chi / 1e27;  // Current value including interest
    }
}
```

## Oracle Security Module (OSM)

```solidity
// Delays price updates by 1 hour — governance can pause if oracle is attacked
contract OSM {
    address public src; // Underlying oracle (Chainlink/Medianizer)

    struct Feed {
        uint128 val;
        uint128 has;
    }

    Feed public cur; // Current active price
    Feed public nxt; // Next price (delayed)
    uint256 public zzz; // Time when nxt becomes cur

    // Anyone can "poke" to advance the price
    function poke() external {
        require(block.timestamp >= zzz, "OSM/not-passed");
        uint256 nextPrice = IOracle(src).read();
        cur = nxt;
        nxt = Feed(uint128(nextPrice), 1);
        zzz = block.timestamp + 1 hours; // Next update in 1 hour

        // If oracle is hacked and tries to set weird price,
        // governance has 1 hour to call void() and stop the update
    }

    function void() external auth {
        cur = nxt = Feed(0, 0); // Clear both prices → stops liquidations
    }
}
```
