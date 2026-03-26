# SKILL: Compliance Automation & Tooling
**Version:** 1.0.0 | **Domain:** On-Chain Compliance, KYC/AML Infrastructure, Compliance-as-Code

---

## On-Chain Compliance Tools

### Chainalysis Sanctions Oracle
**What it does:** On-chain API that returns whether a wallet address is on the OFAC SDN list. Call it from your smart contract before processing any transaction.

**Solidity implementation:**
```solidity
interface ISanctionsOracle {
    function isSanctioned(address addr) external view returns (bool);
}

contract AgentSpartaEscrow {
    address constant CHAINALYSIS_ORACLE = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb; // Ethereum mainnet
    
    ISanctionsOracle oracle = ISanctionsOracle(CHAINALYSIS_ORACLE);
    
    function enterContest(uint256 contestId) external {
        require(!oracle.isSanctioned(msg.sender), "Address is sanctioned");
        // ... rest of entry logic
    }
}
```

**Legal effect:** Integrating the Chainalysis oracle into your smart contract is documented evidence that you implemented OFAC compliance at the protocol level. If a sanctioned address somehow transacts, your defense is: "We implemented automated sanctions screening; this was a failure of the oracle, not willful blindness." This is the difference between strict liability civil violation and a criminal prosecution.

**Deployment addresses:**
- Ethereum mainnet: 0x40C57923924B5c5c5455c48D93317139ADDaC8fb
- Base: verify at chainalysis.com/blog/chainalysis-oracle
- Cost: free to call; Chainalysis charges for the oracle service itself (contact for enterprise pricing)

---

### Coinbase Verifications (On-Chain Identity Attestations)
**What it does:** Coinbase issues on-chain attestations for verified users. An attestation can certify: user is 18+, user is a US person (or non-US), user has completed KYC.

**EAS (Ethereum Attestation Service) integration:**
```solidity
interface IAttestationService {
    function getAttestation(bytes32 uid) external view returns (Attestation memory);
}

// Check if user has Coinbase "verified account" attestation
// Schema UID for Coinbase "Verified Account": 
// 0xf8b05c79f090979bf4a80270aba232dff11a10d9ca55c4f88de95317970f0de9
```

**Legal effect:** Requiring a Coinbase attestation before allowing contest entry means:
- Age verification: Coinbase verifies 18+ at account creation
- KYC completion: Coinbase verified the user's identity
- You're relying on a licensed, regulated entity's KYC — not operating your own KYC program
- Strong defense against "you didn't verify your users" regulatory claims

**Alternatives:**
- Worldcoin (World ID): proof of unique personhood (one wallet per person); age verification limited
- Gitcoin Passport: aggregated identity verification; less robust for financial compliance

---

### Geographic Restriction (On-Chain Limitation)
**Problem:** On-chain geo-blocking is imperfect — IP addresses are off-chain data.

**Best practice hybrid approach:**
1. **Frontend (off-chain):** Use MaxMind GeoIP2 or IPinfo to block users from prohibited states. No user from Washington can even load the contest entry page.
2. **Smart contract (on-chain):** Require user to provide a signed attestation from your backend confirming they passed the geo-check. Your backend only signs for users who passed the frontend geo-check.
3. **TOS (legal):** User represents they are not in a prohibited jurisdiction.

```solidity
mapping(address => bool) public geoVerified;
mapping(bytes32 => bool) public usedNonces;

function verifyGeo(bytes32 nonce, bytes memory signature) external {
    // Verify the backend signed this address + nonce (off-chain geo check passed)
    bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, nonce));
    address signer = recoverSigner(messageHash, signature);
    require(signer == GEO_VERIFIER_ADDRESS, "Invalid geo verification");
    require(!usedNonces[nonce], "Nonce already used");
    usedNonces[nonce] = true;
    geoVerified[msg.sender] = true;
}

function enterContest(uint256 contestId) external {
    require(geoVerified[msg.sender], "Geo verification required");
    require(!oracle.isSanctioned(msg.sender), "Sanctioned address");
    // ... entry logic
}
```

**Legal effect:** Three-layer geo enforcement (MaxMind + backend signing + smart contract check) → documented evidence you made genuine technical efforts to exclude prohibited jurisdictions.

---

## Off-Chain Compliance Infrastructure

### KYC/Identity Verification Providers

| Provider | Best For | Cost | Notes |
|---|---|---|---|
| **Persona** (withpersona.com) | US-focused, developer-friendly | $1.50-$4/verification | Strong ID + selfie verification; good API; recommended for Phase 2 |
| **Jumio** (jumio.com) | Enterprise, global coverage | $3-$8/verification | Industry standard; used by major exchanges |
| **Onfido** (onfido.com) | EU/global focus | $2-$6/verification | Strong UK/EU; GDPR-native design |
| **Sumsub** (sumsub.com) | Crypto-native | $1.50-$5/verification | Purpose-built for crypto platforms; good AML integration |
| **Socure** (socure.com) | US identity + fraud prevention | Custom pricing | Best for US users; strong database matching |

**Implementation for Agent Sparta:**
- Phase 1 (free-to-play): No KYC required (no money at stake)
- Phase 2 (paid contests): KYC required before first deposit
  - Minimum: age verification (18+) + ID scan + liveness check
  - Collect: W-9 (US persons) or W-8BEN (non-US) at account creation, before any prize payout

### AML/Transaction Monitoring

| Tool | Function | Cost |
|---|---|---|
| **Chainalysis KYT** | Real-time risk scoring for wallet addresses; flags high-risk counterparties | Enterprise pricing |
| **Elliptic Lens** | Multi-chain wallet risk scoring | Enterprise pricing |
| **TRM Labs** | Blockchain risk intelligence; broad chain coverage | Enterprise pricing |
| **Chainalysis Reactor** | Forensic investigation; trace funds through complex paths | Enterprise pricing |

**For early-stage Agent Sparta (Phase 2):**
- Use Chainalysis KYT (most widely accepted by regulators) + Sanctions Oracle (free, on-chain)
- Budget: $2,000-$5,000/month at startup volume
- Document every screening decision (log: wallet address, timestamp, risk score, action taken)

### Tax Reporting Tools

| Tool | Function |
|---|---|
| **TaxBit** (taxbit.com) | Enterprise crypto tax + 1099 generation; used by Coinbase, Gemini |
| **CoinTracker** (cointracker.io) | Portfolio + tax; user-facing tool |
| **ZenLedger** (zenledger.io) | Good for DeFi transaction history |
| **Cryptoworth** (cryptoworth.com) | Business-focused accounting for crypto platforms |

**Implementation:** Integrate TaxBit Enterprise to automatically generate 1099-MISC for US winners >$600/year. Export user transaction history at year end. File with IRS and send to users by January 31.

---

## Compliance-as-Code: Smart Contract Rules

### Self-Exclusion Enforcement
```solidity
mapping(address => uint256) public selfExclusionUntil;

function selfExclude(uint256 durationDays) external {
    require(durationDays >= 1 && durationDays <= 365, "Invalid duration");
    uint256 exclusionEnd = block.timestamp + (durationDays * 1 days);
    // Can only EXTEND exclusion, never shorten it
    if (exclusionEnd > selfExclusionUntil[msg.sender]) {
        selfExclusionUntil[msg.sender] = exclusionEnd;
        emit SelfExcluded(msg.sender, exclusionEnd);
    }
}

modifier notExcluded() {
    require(block.timestamp > selfExclusionUntil[msg.sender], "Account self-excluded");
    _;
}

function enterContest(uint256 contestId) external notExcluded {
    // ... entry logic
}
```

**Legal effect:** Self-exclusion is on-chain and irreversible for the duration. The user cannot "change their mind" and re-enter during the exclusion period. This is stronger than most casino self-exclusion programs. Shows Iowa DIA and any gaming regulator that responsible gaming is technically enforced, not just promised in TOS.

### Daily Deposit Limits
```solidity
mapping(address => uint256) public dailyDepositLimit;
mapping(address => uint256) public dailyDepositUsed;
mapping(address => uint256) public lastDepositDay;

function setDailyLimit(uint256 limitInUSDC) external {
    // Users can lower their limit immediately, but can only raise it after 24 hours
    if (limitInUSDC < dailyDepositLimit[msg.sender]) {
        dailyDepositLimit[msg.sender] = limitInUSDC;
    } else {
        // Queue the increase for 24 hours
        pendingLimitIncrease[msg.sender] = LimitIncrease(limitInUSDC, block.timestamp + 1 days);
    }
}
```

### Contest Entry Logging (For Regulatory Examination)
```solidity
event ContestEntered(
    address indexed participant,
    uint256 indexed contestId,
    uint256 entryFeeUSDC,
    uint256 timestamp,
    bytes32 geoVerificationNonce
);

event PrizeDistributed(
    address indexed winner,
    uint256 indexed contestId,
    uint256 prizeAmountUSDC,
    uint256 timestamp
);
```

**Legal effect:** All events are permanently recorded on-chain. This is your immutable audit log. Any regulator can verify: who entered, when, how much, who won, how much was paid. Transparency is a compliance asset.

---

## Compliance Monitoring Stack (Recommended Architecture)

```
User Interaction Layer
    │
    ├── Frontend: MaxMind GeoIP2 → block prohibited states
    ├── Backend: Persona KYC → verify identity before first deposit  
    ├── Backend: OFAC SDN check (off-chain) → block sanctioned users
    │
Smart Contract Layer
    ├── Chainalysis Sanctions Oracle → on-chain OFAC screening
    ├── Backend-signed geo verification → confirm frontend check passed
    ├── Self-exclusion registry → enforce responsible gaming on-chain
    └── Event logging → immutable audit trail
    │
Post-Transaction Layer
    ├── Chainalysis KYT → ongoing transaction risk monitoring
    ├── TaxBit → 1099 generation for US winners
    └── Compliance dashboard → SAR review queue, screening logs
```

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
