# Bridge & Cross-Chain Development

## Core Concepts

### Message Passing Model
All bridges follow the same pattern:
1. **Source chain**: Lock/burn assets or emit message
2. **Off-chain relay**: Observe source event, construct proof/attestation
3. **Destination chain**: Verify proof, mint/unlock assets or execute message

The security question: who are the validators of the off-chain relay, and what happens if they're compromised?

## LayerZero V2

### OApp (Omnichain Application)
```solidity
import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract OmniMarket is OApp {
    using OptionsBuilder for bytes;

    // Endpoint IDs: 30101 = Ethereum, 30184 = Base, 30110 = Arbitrum
    mapping(uint32 => address) public remoteMarkets; // eid → contract address

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) {}

    // Send market result cross-chain
    function propagateResult(uint32 dstEid, bytes32 questionId, bool result) external payable {
        bytes memory payload = abi.encode(questionId, result);
        bytes memory options = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(200_000, 0); // gasLimit, nativeGasDrop

        _lzSend(
            dstEid,
            payload,
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    // Receive and handle cross-chain message
    function _lzReceive(
        Origin calldata origin,
        bytes32 guid,
        bytes calldata payload,
        address executor,
        bytes calldata extraData
    ) internal override {
        // ALWAYS verify source chain and sender
        require(remoteMarkets[origin.srcEid] == address(uint160(uint256(origin.sender))), "Unauthorized");

        (bytes32 questionId, bool result) = abi.decode(payload, (bytes32, bool));
        _handleResult(questionId, result);
    }

    // Quote the gas cost before sending
    function quote(uint32 dstEid, bytes memory payload) external view returns (uint256 fee) {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);
        MessagingFee memory msgFee = _quote(dstEid, payload, options, false);
        return msgFee.nativeFee;
    }
}
```

### OFT (Omnichain Fungible Token)
```solidity
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";

// Token that exists on multiple chains simultaneously
contract PlatformToken is OFT {
    constructor(address _endpoint, address _owner)
        OFT("PlatformToken", "PLT", _endpoint, _owner) {}
}

// Burn on source, mint on destination — same total supply across all chains
```

## Chainlink CCIP

### Token Transfer + Message
```solidity
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract CCIPSender {
    IRouterClient public immutable router;
    IERC20 public immutable linkToken;

    // Chain selectors: Ethereum=5009297550715157269, Base=15971525489660198786
    function sendTokensAndMessage(
        uint64 destinationChainSelector,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32 messageId) {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: token, amount: amount});

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: data,
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300_000})),
            feeToken: address(linkToken)
        });

        uint256 fee = router.getFee(destinationChainSelector, message);
        linkToken.approve(address(router), fee);
        IERC20(token).approve(address(router), amount);

        return router.ccipSend(destinationChainSelector, message);
    }
}

contract CCIPReceiver is IAny2EVMMessageReceiver {
    address public immutable router;

    function ccipReceive(Client.Any2EVMMessage calldata message) external {
        require(msg.sender == router, "Not router");
        // Verify source chain selector + source contract address
        require(allowedSenders[message.sourceChainSelector][abi.decode(message.sender, (address))], "Unauthorized");

        // Process message
        (bytes32 questionId, bool result) = abi.decode(message.data, (bytes32, bool));
        _handleResult(questionId, result);
    }
}
```

## Bridge Security Principles

### The Trust Hierarchy
```
Best (trustless): Native bridges (Ethereum ↔ L2 via rollup mechanism)
Good (semi-trusted): CCIP, LayerZero (multi-party validation)
Risky: Single-validator bridges, proprietary bridges
Never: Unknown bridges with no audit history
```

### Security Checklist for Bridge Integrations
- [ ] Verify source chain selector in every `_lzReceive`/`ccipReceive`
- [ ] Verify source contract address (not just source chain)
- [ ] Nonce/replay protection on all messages
- [ ] Max message size validation
- [ ] Retry/revert handling for failed deliveries
- [ ] Amount validation (can't trust user-provided amounts in messages)
- [ ] Rate limiting on large cross-chain transfers
- [ ] Multi-sig on bridge configuration changes

## Famous Bridge Exploits (Study These)
| Exploit | Loss | Root Cause |
|---------|------|------------|
| Wormhole 2022 | $320M | Signature verification bypass |
| Ronin 2022 | $620M | Validator key compromise |
| Nomad 2022 | $190M | Flawed message verification (trusted 0x0 root) |
| Multichain 2023 | $126M | Centralized control, CEO arrested |

**Lesson**: Bridges are the highest-value attack surface in crypto. Never build a novel bridge. Use audited, battle-tested infrastructure.
