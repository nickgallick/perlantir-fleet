# L2 & Multichain Development

## L2 Architecture Overview

### Optimistic Rollups
**How**: Execute transactions off-chain, post batched data to L1. Assume all txs valid. Fraud proofs challenge invalid state transitions.
- **7-day withdrawal delay** (fraud proof window)
- EVM equivalent — same Solidity code, same tooling
- Networks: Arbitrum One, Optimism, Base, Blast, Mode

### ZK Rollups
**How**: Execute transactions off-chain, generate cryptographic validity proof. L1 verifies proof. No fraud proof delay.
- **Minutes to hours withdrawal** (proof generation time)
- Not fully EVM equivalent (varies by implementation)
- Networks: zkSync Era, StarkNet, Polygon zkEVM, Scroll, Linea
- ZK = no trust required — math proves correctness

### Data Availability
- **Pre-Dencun (2024)**: L2s posted data as L1 calldata. Expensive.
- **Post-Dencun (EIP-4844)**: L2s use "blobs" — cheap temporary data. ~10-100x cheaper L2 fees.
- **Danksharding (future)**: Full data sharding for even cheaper L2 data.

## Chain Selection Guide

| Chain | Strengths | Best For | Gas Cost |
|-------|-----------|----------|----------|
| Ethereum | Highest security, most liquidity | High-value DeFi, bridges, settlement | ~$5-50 per tx |
| Base | Coinbase-backed, growing fast, cheap | Consumer apps, games, retail DeFi | ~$0.01-0.10 |
| Arbitrum | Largest L2 TVL, DeFi ecosystem | DeFi protocols, perpetuals | ~$0.05-0.50 |
| Optimism | OP Stack ecosystem, Superchain | Protocol experiments | ~$0.05-0.50 |
| Polygon PoS | Large user base, gaming ecosystem | Gaming, NFTs, mass adoption | ~$0.001-0.01 |
| zkSync Era | ZK proofs, Account Abstraction native | Privacy, AA-first apps | ~$0.01-0.10 |
| Solana | Highest throughput, non-EVM | HFT, high-volume, gaming | ~$0.00025 |

**For Agent Sparta / prediction markets**: Base (cheap, Coinbase ecosystem, growing consumer base)

## Deploying Across Chains

### Deterministic Addresses with CREATE2
Same address on every chain — crucial for cross-chain protocols.
```solidity
bytes32 salt = keccak256(abi.encode("MarketFactory", version));
address factory = address(new MarketFactory{salt: salt}());
// Same salt + same bytecode + same deployer = same address on every chain
```

Use `ImmutableCreate2Factory` (Nick Mudge's) or `CREATE2Deployer` for trustless multi-chain deployment.

### Foundry Multi-Chain Deployment
```bash
# Deploy to Base
forge script script/Deploy.s.sol --rpc-url $BASE_RPC --broadcast --verify

# Deploy to Arbitrum
forge script script/Deploy.s.sol --rpc-url $ARB_RPC --broadcast --verify
```

### Chain-Specific Quirks

**Arbitrum**:
- L1 data gas component: L2 execution gas + L1 calldata pricing
- Block numbers advance fast (~250ms blocks) — don't use for timing
- `block.number` returns L2 number; use `ArbSys.arbBlockNumber()` for L1 anchored block

**Base / Optimism**:
- EVM equivalent — same Solidity compilation
- `block.basefee` reflects L2 base fee, not L1
- EIP-4844 blobs dramatically reduce L2→L1 data costs

**zkSync Era**:
- Some EVM differences: `msg.value` in static context, different `PUSH0` behavior
- Native Account Abstraction — different paymaster/bundler model
- `block.timestamp` resolution is L1 batch time, not individual tx

## Chain IDs (Important for EIP-712 Domain Separators)
```
Ethereum Mainnet: 1
Ethereum Sepolia: 11155111
Base Mainnet: 8453
Base Sepolia: 84532
Arbitrum One: 42161
Optimism: 10
Polygon: 137
zkSync Era: 324
```
Always include `block.chainid` in signed message domains to prevent cross-chain replay.

## Cross-Chain Messaging

### LayerZero V2
```solidity
import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

contract CrossChainMarket is OApp {
    function sendResult(uint32 dstEid, bytes memory payload) external payable {
        _lzSend(
            dstEid,
            payload,
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0),
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    function _lzReceive(Origin calldata, bytes32, bytes calldata payload, address, bytes calldata)
        internal override
    {
        // Handle received message
    }
}
```
- Immutable endpoints on each chain
- OApp (Omnichain Application) framework

### Chainlink CCIP
```solidity
IRouterClient router = IRouterClient(CCIP_ROUTER);

Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
    receiver: abi.encode(receiverAddress),
    data: abi.encode(payload),
    tokenAmounts: new Client.EVMTokenAmount[](0),
    extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
    feeToken: address(linkToken)
});

uint256 fee = router.getFee(destinationChainSelector, message);
IERC20(linkToken).approve(address(router), fee);
router.ccipSend(destinationChainSelector, message);
```
- Most battle-tested cross-chain solution post-Wormhole exploit
- Supports token transfers + arbitrary data
- LINK token for fees (or native gas)

### Bridge Security Principles
1. **Verify message origin** — check source chain selector AND source contract address
2. **Replay protection** — nonces or unique message IDs
3. **Access control** — only authorized senders can trigger state changes
4. **Validate amounts** — never trust user-supplied amounts in bridge messages
5. **Time delays** — consider delays for large cross-chain transfers
6. **Audit everything** — bridges are the highest-value attack target in crypto
