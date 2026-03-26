# Privacy Protocols

## The Core Problem
Every transaction on Ethereum is public. Anyone can see: who you are, what you own, what you're trading, and when. For some applications (AI competition platforms, institutional trading, sealed auctions), this is a dealbreaker.

## Stealth Addresses (EIP-5564)

Users can receive payments at one-time addresses that can't be linked to each other.

```
Normal:
  Alice publishes address: 0xAlice
  Bob sends to 0xAlice
  Charlie sees: Bob → 0xAlice (Alice's identity revealed)

Stealth:
  Alice publishes a "stealth meta-address" (her public key)
  Bob computes a unique one-time address for Alice
  Bob sends to that one-time address
  Charlie sees: Bob → 0xRandom (can't link to Alice)
  Only Alice can detect this payment by scanning the chain
```

```solidity
// EIP-5564 implementation
contract ERC5564Messenger {
    event Announcement(
        uint256 indexed schemeId,
        address indexed stealthAddress,
        address indexed caller,
        bytes ephemeralPubKey,  // Bob's random ephemeral key
        bytes metadata          // Encrypted amount + token info
    );

    function announce(
        uint256 schemeId,
        address stealthAddress,
        bytes calldata ephemeralPubKey,
        bytes calldata metadata
    ) external {
        emit Announcement(schemeId, stealthAddress, msg.sender, ephemeralPubKey, metadata);
    }
}

// Off-chain: Alice scans all Announcement events
// For each: compute expectedAddress = hash(alicePrivKey × ephemeralPubKey)
// If expectedAddress matches stealthAddress → this payment is mine
```

**For Agent Sparta**: Competitors can enter challenges through stealth addresses. Other participants can't see who entered or how many entries exist until the challenge closes. Prevents metagaming.

## ZK-Based Privacy (Aztec / Railgun)

### Aztec Network
```
Private account model:
- Users have encrypted notes (like UTXOs but encrypted)
- Transactions prove: "I own a note worth X" without revealing X or which note
- Smart contracts can be "private functions" — inputs/outputs hidden from observers
- Composable with public DeFi (Aave, Uniswap) via "bridges"
```

```typescript
// Aztec SDK (simplified)
import { AztecAddress, Fr, AccountWallet } from '@aztec/aztec.js'

// Deploy private token
const privateToken = await TokenContract.deploy(wallet, 'SpartaEntry', 'SE', 18).send().deployed()

// Private transfer (amount hidden from observers)
await privateToken.methods.transfer(recipient, amount).send()

// Reveal selectively (for compliance)
const viewingKey = wallet.getViewingKey()
// Share viewing key with regulator to prove legitimate use
```

### Tornado Cash Architecture (Academic Study Only — OFAC Sanctioned)

Understanding the ZK mixer pattern (for defensive knowledge):

```
1. Deposit: User sends 1 ETH + submits commitment = hash(secret, nullifier)
   - Commitment stored in Merkle tree
   - User holds secret and nullifier off-chain

2. Withdraw: At new address, user proves:
   - "I know a secret such that hash(secret, nullifier) is in this Merkle tree"
   - "I haven't used this nullifier before"
   - Without revealing WHICH commitment (which deposit)

3. ZK proof:
   - Public inputs: Merkle root, nullifier hash, recipient address
   - Private inputs: secret, nullifier, Merkle path (proof of inclusion)
   - Circuit verifies: commitment = hash(secret, nullifier), path is valid
```

The clever part: nullifier hash prevents double-spending WITHOUT linking to the original deposit. The same nullifier hash appears when you withdraw, but observers can't connect it to a specific commitment in the tree.

## Railgun (Compliant Privacy)

Railgun attempts to solve the "privacy but not for criminals" problem:

```
1. User shields tokens → private balance
2. User transacts privately within Railgun
3. When unshielding: must provide "proof of innocence"
   - Prove your transaction history doesn't involve sanctioned addresses
   - Uses zero-knowledge proofs to prove compliance WITHOUT revealing the transaction history
4. Protocol maintains: privacy for honest users, no privacy for bad actors
```

## Encrypted Mempools (SUAVE / Flashbots)

```
Traditional: All pending txs visible → MEV extraction
Encrypted mempool: Txs encrypted until block is built → no front-running

SUAVE architecture:
1. Users submit encrypted transactions to SUAVE network
2. SUAVE is a blockchain itself with TEE (Trusted Execution Environment)
3. TEEs decrypt and execute txs in a provably fair manner
4. Block is revealed only after finalization
5. Front-running is impossible: no one can see the tx before it's included
```

## Privacy for Agent Sparta — Specific Design

### Problem
Competitors in a challenge can:
1. See who entered (know if serious competitors are in → adjust strategy)
2. If submission are public before judging, copy good answers
3. Track competitor wallets across challenges → build intelligence

### Solution: Sealed Submission Protocol

```solidity
contract SealedChallenge {
    // Phase 1: Commit (public — just a hash, no content revealed)
    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public commitBlock;

    function submitCommitment(bytes32 commitment) external {
        require(challenges[challengeId].state == State.OPEN);
        require(block.timestamp < challenges[challengeId].deadline);
        commitments[msg.sender] = commitment;
        commitBlock[msg.sender] = block.number;
    }

    // Phase 2: Reveal (after deadline — all submissions revealed simultaneously)
    function revealSubmission(string calldata submission, bytes32 salt) external {
        require(challenges[challengeId].state == State.REVEALING);
        require(keccak256(abi.encode(submission, salt)) == commitments[msg.sender]);
        submissions[msg.sender] = submission;
        // Now judges can see submissions, but revealing was simultaneous
        // Nobody could copy because all reveals happen in the same block window
    }
}
```

**Stealth entries**: Use EIP-5564 stealth addresses for entry fees. Competitors can't see the participant list until the challenge closes (commitment count is visible, but not who committed).
