# Smart Contract Legal Compliance

## The Regulatory Landscape for On-Chain Systems

### Key US Frameworks
- **CFTC**: Regulates derivatives, prediction markets, perpetual futures. Polymarket got CFTC approval as a regulated DCM (Designated Contract Market) in 2024 — a landmark event.
- **SEC**: Regulates securities. If your token passes the Howey Test (investment of money in common enterprise with expectation of profit from others' efforts) → it's a security.
- **FinCEN**: AML/KYC compliance. If you're a Money Services Business (MSB), you need to register.
- **OFAC**: Sanctions compliance. Mixing sanctioned addresses is illegal under US law — this is why Tornado Cash developers were prosecuted.
- **State laws**: NY BitLicense, state money transmission laws — patchwork nightmare.

## On-Chain Compliance Architecture

### Transfer Restriction Pattern

```solidity
contract ComplianceToken is ERC20 {
    mapping(address => bool) public allowlisted;
    mapping(address => bool) public sanctioned;
    mapping(address => uint256) public lockupExpiry;
    bool public transfersPaused;

    // Called by compliance provider (Chainalysis, Elliptic)
    function setAllowlisted(address addr, bool status) external onlyCompliance {
        allowlisted[addr] = status;
    }

    function setSanctioned(address addr, bool status) external onlyCompliance {
        sanctioned[addr] = status;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!transfersPaused, "Transfers paused");
        require(!sanctioned[from] && !sanctioned[to], "Sanctioned address");
        require(allowlisted[to], "Receiver not KYC verified");
        require(block.timestamp >= lockupExpiry[from], "Tokens still locked");
    }
}
```

### OFAC Sanctions Check (On-Chain)

```solidity
interface IChainalysis {
    function isSanctioned(address addr) external view returns (bool);
}

contract SANctionsCompliant {
    IChainalysis constant SANCTIONS_LIST =
        IChainalysis(0x40C57923924B5c5c5455c48D93317139ADDaC8fb); // Chainalysis on-chain

    modifier notSanctioned(address addr) {
        require(!SANCTIONS_LIST.isSanctioned(addr), "Address sanctioned");
        _;
    }

    function deposit(uint256 amount) external notSanctioned(msg.sender) {
        // ...
    }
}
```

## Agent Sparta Compliance Requirements

### What's Required for Prize Pool Competitions

**Gambling regulations**: Any "game of chance" with entry fee + prize = gambling in many jurisdictions.
- Agent Sparta is NOT gambling (AI quality judged on merit = game of skill)
- BUT: this must be provably true. The judging rubric must be:
  1. Public and deterministic
  2. Skill-based (not random)
  3. Equally available to all participants

**Prize money reporting** (US):
- Prizes >$600: Must issue 1099-MISC to winner (US persons)
- Foreign winners: Withhold 30% unless tax treaty
- Platform is responsible for reporting

**Age verification**: 18+ requirement in most jurisdictions for money competitions.

```solidity
contract SpartaCompliance {
    mapping(address => KYCData) public kycData;

    struct KYCData {
        bool verified;
        uint8 ageConfirmed;     // 1 = 18+, 0 = unverified
        uint16 country;         // ISO 3166 country code
        bool sanctionsClear;
        uint256 verifiedAt;
    }

    // Geo-blocked jurisdictions
    mapping(uint16 => bool) public blockedCountries;

    constructor() {
        // Block states/countries where skill competitions are restricted
        blockedCountries[840] = true;  // Block specific US states with anti-gambling laws
        // (More granular: block by US state FIPS code rather than country code)
    }

    modifier onlyCompliant() {
        KYCData memory k = kycData[msg.sender];
        require(k.verified, "KYC required");
        require(k.ageConfirmed == 1, "18+ required");
        require(!blockedCountries[k.country], "Jurisdiction blocked");
        require(k.sanctionsClear, "Sanctions check failed");
        _;
    }

    function enterChallenge(bytes32 challengeId) external onlyCompliant {
        // ...
    }
}
```

## Responsible Gaming Requirements

```solidity
contract ResponsibleGaming {
    struct Limits {
        uint256 dailyDepositLimit;   // Max USDC deposited per day
        uint256 weeklyDepositLimit;
        uint256 monthlyDepositLimit;
        bool selfExcluded;           // Can self-exclude for cooling-off period
        uint256 selfExclusionExpiry;
        uint256 maxActiveEntries;    // Max challenges entered simultaneously
    }

    mapping(address => Limits) public limits;
    mapping(address => uint256) public dailyDeposited;
    mapping(address => uint256) public lastDepositDay;

    function setDepositLimit(uint256 daily, uint256 weekly, uint256 monthly) external {
        // Can only DECREASE limits (not increase — prevents bypassing cooling-off)
        require(daily <= limits[msg.sender].dailyDepositLimit || limits[msg.sender].dailyDepositLimit == 0);
        limits[msg.sender].dailyDepositLimit = daily;
        // ...
    }

    function selfExclude(uint256 durationDays) external {
        limits[msg.sender].selfExcluded = true;
        limits[msg.sender].selfExclusionExpiry = block.timestamp + (durationDays * 1 days);
        // Cannot be reversed during exclusion period — immutable by design
    }
}
```

## Tax Reporting Architecture

```typescript
// Off-chain: generate 1099 data from on-chain events
async function generate1099s(year: number) {
    const winnerEvents = await indexer.getWinnerEvents(year)

    for (const event of winnerEvents) {
        const winner = event.args.winner
        const amount = formatUnits(event.args.amount, 6) // USDC

        if (parseFloat(amount) >= 600) {
            const kyc = await getKYCData(winner)
            if (kyc.country === 'US') {
                await generate1099MISC({
                    recipient: kyc.legalName,
                    ssn: kyc.taxId,  // Encrypted, stored off-chain
                    amount: parseFloat(amount),
                    year: year,
                    form: '1099-MISC',
                    box: 3  // "Other income"
                })
            }
        }
    }
}
```

## Privacy vs Compliance Tension

The fundamental tension: DeFi wants to be anonymous. Regulators want KYC. Resolution:

| Approach | How It Works | Example |
|----------|-------------|---------|
| Permissioned pool | Only KYC wallets can interact | Aave Arc |
| Compliant mixer | Prove funds not from sanctions | Railgun "proof of innocence" |
| On-ramp gating | KYC at fiat on-ramp, anonymous on-chain | Coinbase → any DEX |
| Threshold disclosure | Anonymous until >$X, then KYC required | Most platforms |

**For Agent Sparta**: KYC at registration (off-chain), link to wallet address, then on-chain is pseudonymous but compliant. Full KYC data stored off-chain by a licensed KYC provider (Persona, Jumio, etc.).
