# RWA Tokenization

## What RWAs Are and Why They Matter
$700T+ in traditional financial assets vs $100B in DeFi. Tokenizing real-world assets bridges this gap — bringing yield, liquidity, and composability to assets that currently require lawyers, brokers, and settlement times measured in days.

## Architecture Layers

```
Real-World Asset (T-bills, real estate, private credit)
         ↓ (Legal wrapper)
SPV (Special Purpose Vehicle) — offshore entity holds the asset
         ↓ (Tokenization)
Token Contract — ERC-20 representing ownership of the SPV/asset
         ↓ (Compliance layer)
Identity Registry — who is allowed to hold this token
         ↓ (Price oracle)
NAV Oracle — reports net asset value on-chain
         ↓ (DeFi integration)
Used as collateral in Aave, Maker, yield protocols
```

## ERC-3643 (T-REX Standard)

The standard for regulated securities on-chain. Every transfer is validated.

```solidity
// Every token transfer triggers compliance check
contract T_REX_Token is ERC20 {
    IIdentityRegistry public identityRegistry;
    ICompliance public compliance;

    function transfer(address to, uint256 amount) public override returns (bool) {
        // Check both sender and receiver are verified
        require(identityRegistry.isVerified(msg.sender), "Sender not verified");
        require(identityRegistry.isVerified(to), "Receiver not verified");

        // Check compliance rules (lock-up periods, max holders, jurisdiction)
        require(compliance.canTransfer(msg.sender, to, amount), "Transfer not compliant");

        return super.transfer(to, amount);
    }

    // Forced transfer (legal seizure/recovery)
    function forcedTransfer(address from, address to, uint256 amount) external onlyAgent {
        _transfer(from, to, amount);
    }

    // Freeze specific address (legal order)
    function freeze(address addr) external onlyAgent {
        frozen[addr] = true;
    }
}

contract IdentityRegistry {
    // Maps address → verified identity (stored as hash of KYC data off-chain)
    mapping(address => bytes32) public identities;
    mapping(address => uint16) public investorCountry; // ISO 3166 country code
    mapping(address => bool) public verified;

    // Identity providers (Fractal, Sumsub, Jumio, etc.) call this
    function registerIdentity(address investor, bytes32 identity, uint16 country) external onlyAgent {
        identities[investor] = identity;
        investorCountry[investor] = country;
        verified[investor] = true;
    }
}
```

## Ondo Finance Model (T-Bill Tokenization)

```
User deposits USDC
      ↓
Ondo OUSG contract mints OUSG tokens
      ↓
Ondo converts USDC → USD (banking partner)
      ↓
USD invested in BlackRock's iShares Short Treasury ETF
      ↓
Daily NAV update: ETF price reported on-chain by oracle
      ↓
User can redeem OUSG → USDC at current NAV (T+1 or T+2 settlement)
```

Key properties:
- **Yield**: ~5% APY (US Treasury rate) — higher than most DeFi stablecoin yields
- **Risk**: US government counterparty risk (lowest in the world)
- **Compliance**: Only accredited investors (>$1M net worth in US)
- **On-chain**: Can be used as collateral in DeFi (MakerDAO, Aave Arc)

## Centrifuge Model (Private Credit)

```
Borrower (real business needing working capital)
      ↓
Creates a pool on Centrifuge
      ↓
Originates loan → asset (invoice, mortgage) backed
      ↓
Senior/Junior tranche tokens (ERC-20)
      ↓
DeFi investors buy tranches
      ↓
Monthly interest payments → token holders
```

Tranche structure:
- **Senior (DROP)**: Lower yield, first to be repaid, protected by junior
- **Junior (TIN)**: Higher yield, first to absorb losses, skin-in-game for originators

**MakerDAO integration**: Maker provides DAI to Centrifuge pools → pool deploys to real businesses → interest paid in DAI → added to Maker's revenue.

## Compliance Patterns for RWA

```solidity
contract RWAComplianceModule {
    // Transfer restrictions
    mapping(address => bool) public whitelist;        // KYC verified
    mapping(address => bool) public blacklist;        // OFAC sanctions
    mapping(address => uint256) public lockupExpiry;  // Vesting lock-up
    uint256 public maxHolders = 2000;                 // Reg D limit (US)
    mapping(uint16 => bool) public allowedCountries;  // Jurisdiction restrictions

    function canTransfer(address from, address to, uint256 amount)
        external view returns (bool, uint16, bytes32)
    {
        if (blacklist[from] || blacklist[to]) return (false, 1, "Sanctioned");
        if (!whitelist[to]) return (false, 2, "Not KYC verified");
        if (block.timestamp < lockupExpiry[from]) return (false, 3, "Lock-up active");
        if (!allowedCountries[investorCountry[to]]) return (false, 4, "Jurisdiction blocked");
        if (holderCount() >= maxHolders && balanceOf[to] == 0) return (false, 5, "Max holders");
        return (true, 0, "");
    }
}
```

## Regulatory Frameworks

| Framework | Jurisdiction | Who It Applies To | Key Restriction |
|-----------|-------------|------------------|-----------------|
| Reg D 506(b) | USA | Private placement | Max 35 non-accredited investors |
| Reg D 506(c) | USA | Private placement, advertised | Only accredited investors |
| Reg S | USA | Foreign investors only | No US persons |
| MiCA | EU | Crypto asset issuers | Comprehensive disclosure, reserves |
| FCA | UK | UK investors | Financial promotion approval |

**For Perlantir/Agent Sparta RWA integration**: Start with Reg D 506(b) for US users (only accredited investors can participate in prize pools >$X), Reg S for international users. Use Ondo or similar for treasury yield on idle prize pool capital.
