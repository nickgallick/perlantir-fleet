# Chainlink CCIP — Cross-Chain Interoperability Protocol

## USDC Bridge: Ethereum → Arbitrum (Single User Transaction)

### Architecture

```
User calls USDCBridge.bridgeUSDC() on Ethereum
    → Contract pulls USDC from user (transferFrom)
    → Contract approves CCIP Router for USDC
    → Contract calls Router.ccipSend() with USDC + receiver
    → CCIP DON observes the message (~3-20 minutes)
    → Receiver contract on Arbitrum gets the USDC automatically
    → USDC appears in user's Arbitrum wallet
```

### Source Contract (Ethereum)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract USDCBridgeSource is Ownable {
    using SafeERC20 for IERC20;

    // Mainnet addresses
    IRouterClient public constant ROUTER =
        IRouterClient(0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D); // Ethereum CCIP Router
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);        // Ethereum USDC
    IERC20 public constant LINK =
        IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);        // LINK token for fees
    uint64 public constant ARBITRUM_CHAIN_SELECTOR = 4949039107694359620;

    address public receiverOnArbitrum; // Set after deploying receiver

    event BridgeInitiated(
        bytes32 indexed messageId,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 fee
    );

    constructor(address _receiver) Ownable(msg.sender) {
        receiverOnArbitrum = _receiver;
    }

    /// @notice Bridge USDC from Ethereum to Arbitrum
    /// @param amount Amount of USDC (6 decimals) to bridge
    /// @param recipient Address on Arbitrum to receive USDC
    function bridgeUSDC(uint256 amount, address recipient) external returns (bytes32 messageId) {
        require(amount > 0, "Amount must be > 0");
        require(recipient != address(0), "Invalid recipient");

        // 1. Pull USDC from user
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        // 2. Build the CCIP message
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(USDC),
            amount: amount
        });

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverOnArbitrum),
            data: abi.encode(recipient),   // Pass desired recipient in message data
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            feeToken: address(LINK)        // Pay fee in LINK (alternative: address(0) for ETH)
        });

        // 3. Get fee estimate
        uint256 fee = ROUTER.getFee(ARBITRUM_CHAIN_SELECTOR, message);

        // 4. Approve router to spend LINK (fee) + USDC (token transfer)
        LINK.safeApprove(address(ROUTER), fee);
        USDC.safeApprove(address(ROUTER), amount);

        // 5. Send the cross-chain message
        messageId = ROUTER.ccipSend(ARBITRUM_CHAIN_SELECTOR, message);

        emit BridgeInitiated(messageId, msg.sender, recipient, amount, fee);
    }

    /// @notice Estimate the LINK fee before calling bridgeUSDC
    function estimateFee(uint256 amount, address recipient) external view returns (uint256 fee) {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({ token: address(USDC), amount: amount });

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverOnArbitrum),
            data: abi.encode(recipient),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(LINK)
        });

        return ROUTER.getFee(ARBITRUM_CHAIN_SELECTOR, message);
    }

    // Fund contract with LINK for fees (owner deposits, users don't need LINK)
    function fundWithLink(uint256 amount) external {
        LINK.safeTransferFrom(msg.sender, address(this), amount);
    }

    function setReceiver(address _receiver) external onlyOwner {
        receiverOnArbitrum = _receiver;
    }
}
```

### Receiver Contract (Arbitrum)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract USDCBridgeReceiver is CCIPReceiver {
    using SafeERC20 for IERC20;

    // Arbitrum addresses
    IERC20 public constant USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8); // Arbitrum USDC.e
    uint64 public constant ETHEREUM_CHAIN_SELECTOR = 5009297550715157269;

    // Only accept messages from our source contract on Ethereum
    address public allowedSourceContract;

    event USDCReceived(
        bytes32 indexed messageId,
        address indexed recipient,
        uint256 amount
    );

    constructor(
        address _router,          // Arbitrum CCIP Router: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8
        address _sourceContract   // Our USDCBridgeSource on Ethereum
    ) CCIPReceiver(_router) {
        allowedSourceContract = _sourceContract;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // Security: verify message is from our source contract on Ethereum
        require(
            message.sourceChainSelector == ETHEREUM_CHAIN_SELECTOR,
            "Wrong source chain"
        );
        require(
            abi.decode(message.sender, (address)) == allowedSourceContract,
            "Unauthorized sender"
        );

        // Decode the intended recipient
        address recipient = abi.decode(message.data, (address));

        // USDC arrived at this contract automatically (CCIP token transfer)
        // Get the amount from the message
        uint256 amount = message.destTokenAmounts[0].amount;

        // Forward USDC to the intended recipient
        USDC.safeTransfer(recipient, amount);

        emit USDCReceived(message.messageId, recipient, amount);
    }
}
```

### Deployment Script

```bash
# 1. Deploy receiver on Arbitrum first
forge create src/USDCBridgeReceiver.sol:USDCBridgeReceiver \
  --rpc-url $ARBITRUM_RPC \
  --private-key $DEPLOYER_KEY \
  --constructor-args \
    "0x141fa059441E0ca23ce184B6A78bafD2A517DdE8" \  # Arbitrum CCIP Router
    "0x0000000000000000000000000000000000000001"     # Placeholder — update after step 2

# 2. Deploy source on Ethereum with receiver address
forge create src/USDCBridgeSource.sol:USDCBridgeSource \
  --rpc-url $ETHEREUM_RPC \
  --private-key $DEPLOYER_KEY \
  --constructor-args $RECEIVER_ADDRESS

# 3. Update receiver with actual source address
cast send $RECEIVER_ADDRESS \
  "constructor update..." \  # Or use a setAllowedSource() function
  --rpc-url $ARBITRUM_RPC

# 4. Fund source contract with LINK for fees (~5 LINK per bridge operation)
cast send $SOURCE_ADDRESS "fundWithLink(uint256)" 50000000000000000000 \  # 50 LINK
  --rpc-url $ETHEREUM_RPC --private-key $DEPLOYER_KEY
```

### Frontend Integration

```typescript
import { parseUnits, encodeFunctionData } from "viem";

// Before calling: user approves source contract to spend USDC
const approveData = encodeFunctionData({
  abi: erc20Abi,
  functionName: "approve",
  args: [SOURCE_CONTRACT_ADDRESS, parseUnits("1000", 6)], // 1000 USDC
});

// Get fee estimate (display to user)
const fee = await publicClient.readContract({
  address: SOURCE_CONTRACT_ADDRESS,
  abi: bridgeAbi,
  functionName: "estimateFee",
  args: [parseUnits("1000", 6), userArbitrumAddress],
});
console.log(`Bridge fee: ${formatUnits(fee, 18)} LINK`);

// Execute bridge
const txHash = await walletClient.writeContract({
  address: SOURCE_CONTRACT_ADDRESS,
  abi: bridgeAbi,
  functionName: "bridgeUSDC",
  args: [parseUnits("1000", 6), userArbitrumAddress],
});

// Track message status
// https://ccip.chain.link/ — enter tx hash to see cross-chain status
// Or poll: https://api.chain.link/ccip/v1/messages?transactionHash=0x...
```

### Chain Selectors Reference

```
Ethereum Mainnet:  5009297550715157269
Arbitrum One:      4949039107694359620
Base:              15971525489660198786
Optimism:          3734403246176062136
Polygon:           4051577828743386545
Avalanche:         6433500567565415381
```

### CCIP Router Addresses

```
Ethereum:  0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D
Arbitrum:  0x141fa059441E0ca23ce184B6A78bafD2A517DdE8
Base:      0x881e3A65B4d4a04dD529061dd0071cf975F58bCD
Optimism:  0x3206695CaE29952f4b0c22a169725a865bc8Ce0f
```
