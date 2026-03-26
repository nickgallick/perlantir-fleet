# DePIN Infrastructure

## Core Architecture Pattern

```
Physical Layer:   Hardware devices contribute resources
Proof Layer:      Protocol verifies contributions happened
Token Layer:      Contributors earn tokens; users burn tokens
Data Layer:       The generated data/service is the product

Burn-and-mint equilibrium:
  - Users pay to use the network → tokens burned (deflationary pressure)
  - Contributors earn new tokens → tokens minted (inflationary pressure)
  - Equilibrium: when usage demand = supply contributions
  - At equilibrium: token price stable, network sustainable indefinitely
```

## Proof of Physical Work

The hard problem: how do you verify a physical device is actually running and contributing honestly?

```solidity
contract ProofOfCoverage {
    // Helium-style: beacons and witnesses
    struct Beacon {
        address transmitter;
        bytes32 nonce;
        uint256 timestamp;
        int256 lat;      // Fixed-point latitude (7 decimal places)
        int256 lng;      // Fixed-point longitude
    }

    // Transmitter emits a beacon. Nearby witnesses observe and attest.
    // Fraud: colluding witnesses can fake coverage (major Helium weakness)
    // Defense: geographic distance checks, timing analysis, cross-reference with
    //          real-world usage (actual data transfers = proof network is useful)

    mapping(bytes32 => Beacon) public beacons;
    mapping(bytes32 => address[]) public witnesses; // beaconId → witnessing devices

    function submitBeacon(bytes32 nonce, int256 lat, int256 lng) external {
        bytes32 beaconId = keccak256(abi.encode(msg.sender, nonce, block.timestamp));
        beacons[beaconId] = Beacon(msg.sender, nonce, block.timestamp, lat, lng);
    }

    function witnessBeacon(bytes32 beaconId, bytes calldata signedBeaconData) external {
        // Verify the witness actually received the beacon's radio signal
        // (verified by checking signature from the beacon device on the witness data)
        require(_verifyRadioSignature(beaconId, signedBeaconData), "Invalid witness");
        witnesses[beaconId].push(msg.sender);
    }

    function claimRewards(bytes32 beaconId) external {
        Beacon storage beacon = beacons[beaconId];
        require(msg.sender == beacon.transmitter);

        uint256 witnessCount = witnesses[beaconId].length;
        uint256 transmitterReward = BASE_REWARD * 2 / 3;  // 67% to transmitter
        uint256 witnessReward = witnessCount > 0
            ? BASE_REWARD / 3 / witnessCount              // 33% split among witnesses
            : 0;

        token.mint(msg.sender, transmitterReward);
        for (uint i = 0; i < witnessCount; i++) {
            token.mint(witnesses[beaconId][i], witnessReward);
        }
    }
}
```

## Burn-and-Mint Token Economics

```solidity
contract DePINToken {
    // Emission schedule: decays over time (like Bitcoin halving but continuous)
    uint256 public constant INITIAL_EPOCH_REWARD = 100_000 * 1e18; // Per epoch
    uint256 public constant DECAY_RATE = 9900;  // 99% of previous epoch (1% decay)
    uint256 public epochReward;
    uint256 public epochStart;
    uint256 public constant EPOCH_DURATION = 30 days;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        epochReward = INITIAL_EPOCH_REWARD;
        epochStart  = block.timestamp;
    }

    // Called by proof contract to reward contributors
    function mintReward(address contributor, uint256 share) external onlyProofContract {
        _advanceEpoch();
        uint256 amount = epochReward * share / 1e18; // share is a fraction (1e18 = 100%)
        _mint(contributor, amount);
    }

    // Users pay for network services → tokens burned
    function payForService(uint256 tokenAmount) external {
        _burn(msg.sender, tokenAmount);
        emit ServicePurchased(msg.sender, tokenAmount);
    }

    function _advanceEpoch() internal {
        while (block.timestamp >= epochStart + EPOCH_DURATION) {
            epochReward = epochReward * DECAY_RATE / 10_000;
            epochStart += EPOCH_DURATION;
        }
    }
}
```

## Major DePIN Protocols — Key Learnings

| Protocol | Resource | Proof Method | Key Lesson |
|---------|---------|-------------|-----------|
| Helium | Wireless coverage | Beacon/witness | Sybil fraud is real; needs stronger PoW |
| Render | GPU compute | Task completion + validation | Compute verification is easier than coverage |
| Filecoin | Storage | Proof of spacetime (PoSt) | Cryptographic proofs work for verifiable resources |
| Hivemapper | Mapping data | Image quality + GPS proof | Real-world data quality hard to verify on-chain |
| DIMO | Vehicle data | OBD-II device attestation | Hardware attestation + TEE is most robust |

## Unit Economics Template

```
Device cost: $200
Monthly earnings at 50% utilization: $30/month
Break-even: 6.7 months
If token price 2x: break-even 3.4 months → rush to deploy → network grows → more utility

Key insight: device economics determine network growth rate.
If break-even > 12 months → slow growth.
If break-even < 3 months → exponential deployment.
Token price IS the network growth lever.

Design for your target break-even time in bull market conditions.
The token model needs to sustain contributions even in bear markets.
```
