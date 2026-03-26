# Intent-Based Architecture

## Overview

Intent-based architecture represents a fundamental paradigm shift in how users interact with blockchain systems. Rather than specifying exact execution paths (imperative transactions), users declare desired outcomes (intents) and delegate execution to competitive third parties called solvers or fillers. The system selects the solver that best satisfies the intent, improving execution quality, reducing user complexity, and enabling MEV protection.

---

## 1. Intents vs Transactions — The Paradigm Shift

### Imperative (Transaction) Model

Traditional blockchain interaction requires users to specify every step:

```
User → signs tx → specifies: exact route, slippage, gas price, nonce, exact calldata
     → submits → mempool → miner/validator executes exactly as specified
```

Problems:
- Users bear execution risk (price changes between sign and execution)
- Suboptimal routing — user must know best path
- MEV exposure — front-running, sandwich attacks on public mempool
- Failed transactions still cost gas
- Cross-chain operations require multiple coordinated transactions

### Declarative (Intent) Model

```
User → signs intent → specifies: input token, output token, minimum output, deadline
     → propagates to solver network → competitive off-chain solving
     → best solver executes on-chain → settlement contract verifies output constraint
```

Benefits:
- Users specify *what*, not *how*
- Solvers compete on execution quality → better prices
- MEV protection through solver competition and surplus sharing
- Cross-chain atomicity becomes feasible
- Failed solving has no gas cost for users (in most designs)

### Declarative vs Imperative Comparison

| Dimension | Imperative (Tx) | Declarative (Intent) |
|---|---|---|
| User burden | High — must specify route | Low — specify outcome |
| MEV exposure | High — public mempool | Low — private solving |
| Execution quality | Fixed at signing | Competitive, improving |
| Cross-chain | Sequential, fragile | Atomic possible |
| Gas on failure | Yes | No (typically) |
| Composability | High (on-chain) | Evolving (ERC-7683) |

---

## 2. Intent Lifecycle

### Phase 1: Creation

User constructs a typed intent object specifying constraints:
- Input asset and amount
- Output asset and minimum amount
- Deadline (timestamp or block)
- Exclusivity conditions (optional)
- Additional data (hooks, callbacks)

### Phase 2: Signing (EIP-712)

Intents are signed off-chain using EIP-712 structured data. The signature commits the user to the constraints without broadcasting a transaction.

```typescript
import { ethers } from "ethers";

const DUTCH_ORDER_TYPEHASH = ethers.utils.id(
  "DutchOrder(OrderInfo info,uint256 decayStartTime,uint256 decayEndTime," +
  "address exclusiveFiller,uint256 exclusivityOverrideBps,DutchInput input," +
  "DutchOutput[] outputs)" +
  "DutchInput(address token,uint256 startAmount,uint256 endAmount)" +
  "DutchOutput(address token,uint256 startAmount,uint256 endAmount,address recipient)" +
  "OrderInfo(address reactor,address swapper,uint256 nonce,uint256 deadline," +
  "address additionalValidationContract,bytes additionalValidationData)"
);

const domain = {
  name: "UniswapX",
  chainId: 1,
  verifyingContract: REACTOR_ADDRESS,
};

const types = {
  DutchOrder: [
    { name: "info", type: "OrderInfo" },
    { name: "decayStartTime", type: "uint256" },
    { name: "decayEndTime", type: "uint256" },
    { name: "exclusiveFiller", type: "address" },
    { name: "exclusivityOverrideBps", type: "uint256" },
    { name: "input", type: "DutchInput" },
    { name: "outputs", type: "DutchOutput[]" },
  ],
  OrderInfo: [
    { name: "reactor", type: "address" },
    { name: "swapper", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
    { name: "additionalValidationContract", type: "address" },
    { name: "additionalValidationData", type: "bytes" },
  ],
  DutchInput: [
    { name: "token", type: "address" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
  ],
  DutchOutput: [
    { name: "token", type: "address" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
    { name: "recipient", type: "address" },
  ],
};

async function signDutchOrder(signer: ethers.Signer, order: DutchOrder) {
  // ethers v5 _signTypedData
  const signature = await (signer as any)._signTypedData(domain, types, order);
  return signature;
}

// Reconstruct signer from signature for verification
function recoverSigner(order: DutchOrder, signature: string): string {
  const digest = ethers.utils._TypedDataEncoder.hash(domain, types, order);
  return ethers.utils.recoverAddress(digest, signature);
}
```

### Phase 3: Propagation

Signed intents are broadcast to:
- Protocol-specific APIs (UniswapX order endpoint, CoW Protocol API)
- Peer-to-peer solver networks
- Public order books (permissionless)

### Phase 4: Solving (Off-Chain)

Solvers receive intents and compute execution strategies:
1. Check validity (deadline, nonce not spent, sufficient user balance/allowance)
2. Simulate execution paths (on-chain simulation, off-chain price modeling)
3. Determine if profitable to fill
4. Submit fill transaction (competing with other solvers)

### Phase 5: Settlement (On-Chain)

Reactor/settlement contract:
1. Validates signature
2. Checks nonce not spent (marks nonce as used)
3. Pulls input tokens from user (via permit2 or direct allowance)
4. Calls solver's fill logic
5. Verifies output constraints are satisfied
6. If output insufficient, reverts entire transaction

### Phase 6: Verification

Post-settlement verification:
- Event emission for off-chain indexers
- Nonce invalidation prevents replay
- Output token balance check is the atomic guarantee

---

## 3. UniswapX

### Architecture

UniswapX separates concerns across three layers:

**Reactor Layer** — on-chain settlement contracts that enforce constraints
**Solver Layer** — off-chain competitive actors that find execution
**Order Book** — off-chain signed order propagation (UniswapX API)

```
User → signs order → UniswapX API → solver network
                                         ↓
                              solver picks best order
                                         ↓
                              solver executes fill tx
                                         ↓
                         Reactor validates & settles
```

### Core Reactor Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IReactor} from "./interfaces/IReactor.sol";
import {IReactorCallback} from "./interfaces/IReactorCallback.sol";
import {SignedOrder, ResolvedOrder, OutputToken, InputToken} from "./base/ReactorStructs.sol";
import {Permit2Lib} from "./lib/Permit2Lib.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

abstract contract BaseReactor is IReactor {
    using Permit2Lib for ResolvedOrder;

    IPermit2 public immutable permit2;

    error InvalidSigner();
    error DeadlinePassed();
    error InsufficientOutput(
        uint256 actualAmount,
        uint256 expectedAmount
    );

    constructor(IPermit2 _permit2) {
        permit2 = _permit2;
    }

    /// @notice Execute a single order
    function execute(SignedOrder calldata order) external payable override {
        ResolvedOrder[] memory resolvedOrders = new ResolvedOrder[](1);
        resolvedOrders[0] = resolve(order);
        _fill(resolvedOrders, msg.sender, bytes(""));
    }

    /// @notice Execute with callback for complex filling strategies
    function executeWithCallback(
        SignedOrder calldata order,
        bytes calldata callbackData
    ) external payable override {
        ResolvedOrder[] memory resolvedOrders = new ResolvedOrder[](1);
        resolvedOrders[0] = resolve(order);
        _fill(resolvedOrders, msg.sender, callbackData);
    }

    /// @notice Execute batch of orders atomically
    function executeBatch(SignedOrder[] calldata orders) external payable override {
        ResolvedOrder[] memory resolvedOrders = new ResolvedOrder[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            resolvedOrders[i] = resolve(orders[i]);
        }
        _fill(resolvedOrders, msg.sender, bytes(""));
    }

    function _fill(
        ResolvedOrder[] memory orders,
        address filler,
        bytes memory callbackData
    ) internal {
        // Pull input tokens from swappers via permit2
        for (uint256 i = 0; i < orders.length; i++) {
            orders[i].transferInputTokens(permit2);
        }

        // Callback to filler to provide output tokens
        if (callbackData.length > 0) {
            IReactorCallback(filler).reactorCallback(orders, callbackData);
        }

        // Verify all outputs are satisfied
        for (uint256 i = 0; i < orders.length; i++) {
            _verify(orders[i]);
            emit Fill(
                keccak256(orders[i].sig),
                orders[i].info.swapper,
                orders[i].info.nonce,
                filler
            );
        }
    }

    function _verify(ResolvedOrder memory order) internal view {
        for (uint256 i = 0; i < order.outputs.length; i++) {
            OutputToken memory output = order.outputs[i];
            uint256 balance = output.token.balanceOf(output.recipient);
            // Check balance satisfies minimum output
            // (simplified — real impl uses pre/post balance tracking)
            if (balance < output.amount) {
                revert InsufficientOutput(balance, output.amount);
            }
        }
    }

    /// @dev Subclasses implement order-specific resolution (Dutch decay, etc.)
    function resolve(SignedOrder calldata order)
        internal
        virtual
        returns (ResolvedOrder memory);
}
```

### Dutch Auction Orders

Price decays from a start (favorable to filler) to an end (minimum acceptable to user). Fillers are incentivized to fill early (better margin), but competition drives them to fill at the best price for the user.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct OrderInfo {
    address reactor;
    address swapper;
    uint256 nonce;
    uint256 deadline;
    address additionalValidationContract;
    bytes additionalValidationData;
}

struct DutchInput {
    address token;
    uint256 startAmount; // amount at decayStartTime (favorable to filler)
    uint256 endAmount;   // amount at decayEndTime (minimum user provides)
}

struct DutchOutput {
    address token;
    uint256 startAmount; // amount at decayStartTime (user receives most)
    uint256 endAmount;   // amount at decayEndTime (minimum user receives)
    address recipient;
}

struct DutchOrder {
    OrderInfo info;
    uint256 decayStartTime;
    uint256 decayEndTime;
    address exclusiveFiller; // address(0) if no exclusivity
    uint256 exclusivityOverrideBps; // basis points penalty if non-exclusive filler fills early
    DutchInput input;
    DutchOutput[] outputs;
}

library DutchDecayLib {
    /// @notice Calculates decayed amount at current block.timestamp
    /// @param startAmount Amount at decayStartTime
    /// @param endAmount Amount at decayEndTime
    /// @param decayStartTime Start of decay period
    /// @param decayEndTime End of decay period
    function decay(
        uint256 startAmount,
        uint256 endAmount,
        uint256 decayStartTime,
        uint256 decayEndTime
    ) internal view returns (uint256) {
        if (decayEndTime <= decayStartTime) revert("InvalidDecay");
        if (block.timestamp >= decayEndTime) return endAmount;
        if (block.timestamp <= decayStartTime) return startAmount;

        uint256 elapsed = block.timestamp - decayStartTime;
        uint256 duration = decayEndTime - decayStartTime;

        if (endAmount < startAmount) {
            // Decaying downward (output token: user gets less over time)
            uint256 decayAmount = startAmount - endAmount;
            return startAmount - (decayAmount * elapsed) / duration;
        } else {
            // Decaying upward (input token: user provides more over time)
            uint256 decayAmount = endAmount - startAmount;
            return startAmount + (decayAmount * elapsed) / duration;
        }
    }
}

contract DutchOrderReactor is BaseReactor {
    using DutchDecayLib for uint256;

    bytes32 constant DUTCH_ORDER_TYPEHASH = keccak256(
        "DutchOrder(OrderInfo info,uint256 decayStartTime,uint256 decayEndTime,"
        "address exclusiveFiller,uint256 exclusivityOverrideBps,DutchInput input,"
        "DutchOutput[] outputs)"
        "DutchInput(address token,uint256 startAmount,uint256 endAmount)"
        "DutchOutput(address token,uint256 startAmount,uint256 endAmount,address recipient)"
        "OrderInfo(address reactor,address swapper,uint256 nonce,uint256 deadline,"
        "address additionalValidationContract,bytes additionalValidationData)"
    );

    error NotExclusiveFiller(address filler, address exclusiveFiller);
    error OrderExpired();

    constructor(IPermit2 _permit2) BaseReactor(_permit2) {}

    function resolve(SignedOrder calldata signedOrder)
        internal
        override
        returns (ResolvedOrder memory)
    {
        DutchOrder memory order = abi.decode(signedOrder.order, (DutchOrder));

        if (block.timestamp > order.info.deadline) revert OrderExpired();

        // Verify signature
        bytes32 orderHash = _hashOrder(order);
        address signer = ECDSA.recover(orderHash, signedOrder.sig);
        if (signer != order.info.swapper) revert InvalidSigner();

        // Check exclusivity
        if (
            order.exclusiveFiller != address(0) &&
            block.timestamp < order.decayStartTime &&
            msg.sender != order.exclusiveFiller
        ) {
            // Non-exclusive filler can still fill but must provide override bonus
            revert NotExclusiveFiller(msg.sender, order.exclusiveFiller);
        }

        // Resolve decayed amounts
        uint256 inputAmount = DutchDecayLib.decay(
            order.input.startAmount,
            order.input.endAmount,
            order.decayStartTime,
            order.decayEndTime
        );

        OutputToken[] memory outputs = new OutputToken[](order.outputs.length);
        for (uint256 i = 0; i < order.outputs.length; i++) {
            outputs[i] = OutputToken({
                token: order.outputs[i].token,
                amount: DutchDecayLib.decay(
                    order.outputs[i].startAmount,
                    order.outputs[i].endAmount,
                    order.decayStartTime,
                    order.decayEndTime
                ),
                recipient: order.outputs[i].recipient
            });
        }

        return ResolvedOrder({
            info: order.info,
            input: InputToken({
                token: order.input.token,
                amount: inputAmount,
                maxAmount: order.input.endAmount
            }),
            outputs: outputs,
            sig: signedOrder.sig,
            hash: orderHash
        });
    }

    function _hashOrder(DutchOrder memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DUTCH_ORDER_TYPEHASH,
            // ... encode all fields
            order.decayStartTime,
            order.decayEndTime,
            order.exclusiveFiller,
            order.exclusivityOverrideBps,
            keccak256(abi.encode(order.input)),
            keccak256(_encodeOutputs(order.outputs))
        ));
    }
}
```

### Exclusive Fillers

Exclusive fillers have a time window where only they can fill the order (e.g., market makers who committed off-chain). After exclusivity expires, any solver can fill with a penalty bonus to the user.

### Cross-Chain UniswapX

Extends the model to cross-chain swaps:
- User signs intent specifying input on chain A, output on chain B
- Solver fills on destination chain, proving via cross-chain messaging
- Reactor on origin chain releases funds to solver after proof

---

## 4. CoW Protocol

### Architecture

CoW Protocol (formerly Gnosis Protocol) uses batch auctions with coincidence of wants (CoW) detection.

```
Users → submit limit orders to CoW API
     → batch auction runs every ~30 seconds
     → solver competition: find optimal settlement
     → best solver submits settlement tx
     → GPv2Settlement executes all trades atomically
```

### Coincidence of Wants

When two users' orders can be matched directly (A sells ETH for USDC, B sells USDC for ETH), no AMM liquidity is needed — surplus is shared between both parties.

```
Without CoW:
  Alice: 1 ETH → 2000 USDC (uses Uniswap, pays 0.3% fee + MEV)
  Bob: 2100 USDC → 1 ETH (uses Uniswap, pays 0.3% fee + MEV)

With CoW:
  Alice gets 2050 USDC (better than market)
  Bob gets 1 ETH for 2050 USDC (better than market)
  Solver gets 50 USDC surplus for finding the CoW
```

### GPv2Settlement Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Simplified GPv2Settlement structure
contract GPv2Settlement {
    // Domain separator for EIP-712 signing
    bytes32 public immutable domainSeparator;

    // Reentrancy guard
    uint256 private reentrancyStatus = 1;

    struct GPv2Trade {
        uint256 sellTokenIndex;   // index in tokens array
        uint256 buyTokenIndex;    // index in tokens array
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;        // limit price denominator
        uint32 validTo;           // order expiry
        bytes32 appData;          // arbitrary metadata hash
        uint256 feeAmount;        // protocol fee
        uint256 flags;            // isPartiallyFillable, isSell, etc.
        uint256 executedAmount;   // actual fill amount
        bytes signature;
    }

    struct GPv2Interaction {
        address target;
        uint256 value;
        bytes callData;
    }

    event Trade(
        address indexed owner,
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 feeAmount,
        bytes32 orderUid
    );

    event Settlement(address indexed solver);

    /// @notice Settle a batch of trades
    /// @param tokens Unique token list referenced by trade indices
    /// @param clearingPrices Price vector: clearingPrices[i] = price of tokens[i] in batch unit
    /// @param trades All trades in this batch
    /// @param interactions Pre/intra/post settlement interactions (AMM calls, etc.)
    function settle(
        address[] calldata tokens,
        uint256[] calldata clearingPrices,
        GPv2Trade[] calldata trades,
        GPv2Interaction[][3] calldata interactions
    ) external nonReentrant {
        // Pre-settlement interactions (e.g., flashloans)
        _executeInteractions(interactions[0]);

        // Transfer sell tokens from traders to settlement contract
        for (uint256 i = 0; i < trades.length; i++) {
            _transferSellTokenIn(tokens, clearingPrices, trades[i]);
        }

        // Intra-settlement interactions (e.g., AMM swaps to fill gaps)
        _executeInteractions(interactions[1]);

        // Transfer buy tokens to traders
        for (uint256 i = 0; i < trades.length; i++) {
            _transferBuyTokenOut(tokens, clearingPrices, trades[i]);
        }

        // Post-settlement interactions
        _executeInteractions(interactions[2]);

        emit Settlement(msg.sender);
    }

    function _transferSellTokenIn(
        address[] calldata tokens,
        uint256[] calldata prices,
        GPv2Trade calldata trade
    ) internal {
        address sellToken = tokens[trade.sellTokenIndex];
        // Verify order signature, check limit price, transfer
        // Actual amount transferred = executedAmount
        IERC20(sellToken).transferFrom(
            recoverOrderSigner(trade),
            address(this),
            trade.executedAmount
        );
    }

    function _executeInteractions(GPv2Interaction[] calldata interactions) internal {
        for (uint256 i = 0; i < interactions.length; i++) {
            (bool success,) = interactions[i].target.call{value: interactions[i].value}(
                interactions[i].callData
            );
            require(success, "Interaction failed");
        }
    }
}
```

### Solver Competition

Solvers submit solutions off-chain. The CoW Protocol backend selects the solution that maximizes surplus for traders. Solvers are bonded — slashable if they submit invalid settlements on-chain.

```typescript
// Solver solution submission (off-chain API)
interface SolverSolution {
  prices: Record<string, string>;  // token address -> clearing price
  trades: Array<{
    order: SignedOrder;
    executedSellAmount: string;
    executedBuyAmount: string;
    executedFeeAmount: string;
  }>;
  interactions: {
    pre: Interaction[];
    intra: Interaction[];
    post: Interaction[];
  };
  // Objective value: surplus extracted for traders
  objectiveValue: string;
}

async function submitSolution(solution: SolverSolution): Promise<void> {
  const response = await fetch(`${COW_API}/api/v1/solver/solve`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(solution),
  });
  if (!response.ok) throw new Error(`Solver submission failed: ${response.statusText}`);
}
```

---

## 5. ERC-7683 — Cross-Chain Intent Standard

ERC-7683 defines a standardized interface for cross-chain intents, enabling interoperability between protocols.

### CrossChainOrder Struct

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ERC-7683: Cross-Chain Intents Standard
/// @notice Standardized order types and settlement interfaces for cross-chain intents

/// @notice Tokens that are interacted with during a cross-chain order
struct Output {
    bytes32 token;    // ERC-7683 uses bytes32 to support non-EVM chains
    uint256 amount;
    bytes32 recipient;
    uint32 chainId;
}

struct Input {
    address token;
    uint256 amount;
}

/// @notice The top-level cross-chain order type
struct CrossChainOrder {
    address settlementContract; // The settlement contract on origin chain
    address swapper;            // The user placing the order
    uint256 nonce;              // Unique nonce per swapper
    uint32 originChainId;       // Chain where order is placed
    uint32 initiateDeadline;    // Order must be initiated by this time
    uint32 fillDeadline;        // Order must be filled by this time on destination
    bytes orderData;            // Arbitrary data for the settlement contract
}

/// @notice Data returned after resolving a cross-chain order
struct ResolvedCrossChainOrder {
    address settlementContract;
    address swapper;
    uint256 nonce;
    uint32 originChainId;
    uint32 initiateDeadline;
    uint32 fillDeadline;
    Input[] maxSpent;   // Max tokens spent from swapper on origin
    Output[] minReceived; // Min tokens received by swapper on destination
    FillInstruction[] fillInstructions;
}

/// @notice Instructions for filling on destination chain
struct FillInstruction {
    uint64 destinationChainId;
    bytes32 destinationSettler;  // Settlement contract on destination
    bytes originData;             // Data to pass to destination settler
}

/// @notice ERC-7683 Origin Chain Interface
interface IOriginSettler {
    event Open(bytes32 indexed orderId, ResolvedCrossChainOrder resolvedOrder);

    /// @notice Opens a cross-chain order
    function open(CrossChainOrder calldata order, bytes calldata signature) external payable;

    /// @notice Resolves a cross-chain order into standard types
    function resolve(CrossChainOrder calldata order, bytes calldata fillerData)
        external
        view
        returns (ResolvedCrossChainOrder memory);
}

/// @notice ERC-7683 Destination Chain Interface
interface IDestinationSettler {
    /// @notice Fills a cross-chain order on destination chain
    /// @param orderId Unique identifier for the order
    /// @param originData Data emitted from origin chain Open event
    /// @param fillerData Additional data provided by filler
    function fill(
        bytes32 orderId,
        bytes calldata originData,
        bytes calldata fillerData
    ) external payable;
}
```

### ERC-7683 Settlement Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CrossChainSettler is IOriginSettler, IDestinationSettler {
    mapping(bytes32 => OrderStatus) public orderStatus;
    mapping(bytes32 => address) public orderFiller;

    enum OrderStatus { None, Opened, Filled, Refunded }

    error OrderAlreadyOpened();
    error OrderExpired();
    error InvalidSignature();
    error OrderNotFound();

    /// @notice Open order on origin chain — lock user funds
    function open(
        CrossChainOrder calldata order,
        bytes calldata signature
    ) external payable override {
        bytes32 orderId = _computeOrderId(order);

        if (orderStatus[orderId] != OrderStatus.None) revert OrderAlreadyOpened();
        if (block.timestamp > order.initiateDeadline) revert OrderExpired();

        // Verify EIP-712 signature
        _verifySignature(order, signature);

        // Pull input tokens
        ResolvedCrossChainOrder memory resolved = _resolve(order, bytes(""));
        for (uint256 i = 0; i < resolved.maxSpent.length; i++) {
            IERC20(resolved.maxSpent[i].token).transferFrom(
                order.swapper,
                address(this),
                resolved.maxSpent[i].amount
            );
        }

        orderStatus[orderId] = OrderStatus.Opened;
        emit Open(orderId, resolved);
    }

    /// @notice Fill order on destination chain — send output tokens to user
    function fill(
        bytes32 orderId,
        bytes calldata originData,
        bytes calldata fillerData
    ) external payable override {
        FillInstruction memory instruction = abi.decode(originData, (FillInstruction));
        Output[] memory outputs = abi.decode(fillerData, (Output[]));

        for (uint256 i = 0; i < outputs.length; i++) {
            if (outputs[i].chainId == block.chainid) {
                address token = address(uint160(uint256(outputs[i].token)));
                address recipient = address(uint160(uint256(outputs[i].recipient)));

                if (token == address(0)) {
                    payable(recipient).transfer(outputs[i].amount);
                } else {
                    IERC20(token).transferFrom(msg.sender, recipient, outputs[i].amount);
                }
            }
        }

        orderFiller[orderId] = msg.sender;
        // Emit proof event for origin chain relay
        emit Filled(orderId, msg.sender, outputs);
    }

    function _computeOrderId(CrossChainOrder calldata order) internal pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }
}
```

---

## 6. 1inch Fusion

### Architecture

1inch Fusion uses a Dutch auction with resolver (solver) competition. Key innovation: resolvers must hold 1INCH stake to participate.

### Dutch Auction Decay

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct FusionOrder {
    address makerAsset;
    address takerAsset;
    uint256 makingAmount;   // Input from maker (user)
    uint256 takingAmount;   // Minimum output to maker
    address maker;
    uint256 salt;           // Encodes auction params
    bytes makerTraits;      // Encoded deadline, nonce, flags
    bytes extension;        // Auction timing, resolver whitelist, fees
}

library AuctionLib {
    struct AuctionDetails {
        uint32 startTime;
        uint24 duration;
        uint32 initialRateBump; // Initial bonus rate above market (in 1e5 units)
        bytes pointsAndTimeDeltas; // Auction decay curve points
    }

    /// @notice Calculate current rate bump based on auction progress
    function getCurrentRateBump(
        AuctionDetails memory auction
    ) internal view returns (uint256 rateBump) {
        uint256 currentTime = block.timestamp;

        if (currentTime <= auction.startTime) {
            return auction.initialRateBump;
        }

        uint256 endTime = auction.startTime + auction.duration;
        if (currentTime >= endTime) {
            return 0; // No bonus — at minimum acceptable rate
        }

        // Linear interpolation (simplified — real implementation uses points curve)
        uint256 elapsed = currentTime - auction.startTime;
        rateBump = auction.initialRateBump * (auction.duration - elapsed) / auction.duration;
    }

    /// @notice Calculate taking amount with rate bump applied
    function calcTakingAmount(
        uint256 orderTakingAmount,
        uint256 makingAmount,
        uint256 requestedMakingAmount,
        AuctionDetails memory auction
    ) internal view returns (uint256) {
        uint256 rateBump = getCurrentRateBump(auction);
        // takingAmount = orderTakingAmount * requestedMakingAmount / makingAmount * (1 + rateBump)
        uint256 base = orderTakingAmount * requestedMakingAmount / makingAmount;
        return base * (1e5 + rateBump) / 1e5;
    }
}
```

### Resolver Whitelist & Fee Structure

```solidity
contract FusionSettlement {
    mapping(address => uint256) public resolverStake;
    uint256 public constant MIN_STAKE = 100_000e18; // 100k 1INCH

    struct ResolverFee {
        uint256 protocolFeeRate;  // basis points
        uint256 integratorFeeRate;
        address integratorFeeRecipient;
    }

    error InsufficientStake(uint256 actual, uint256 required);
    error NotWhitelistedResolver();

    modifier onlyResolver() {
        if (resolverStake[msg.sender] < MIN_STAKE) {
            revert InsufficientStake(resolverStake[msg.sender], MIN_STAKE);
        }
        _;
    }

    function fillOrder(
        FusionOrder calldata order,
        bytes calldata signature,
        uint256 makingAmount,
        uint256 takingAmount
    ) external onlyResolver {
        // Verify order signature (EIP-712)
        _verifyOrderSignature(order, signature);

        // Transfer maker asset from user to resolver
        IERC20(order.makerAsset).transferFrom(order.maker, msg.sender, makingAmount);

        // Resolver provides taker asset to user
        IERC20(order.takerAsset).transferFrom(msg.sender, order.maker, takingAmount);

        // Collect protocol fee
        uint256 fee = takingAmount * 2 / 10000; // 2 bps
        IERC20(order.takerAsset).transferFrom(msg.sender, FEE_RECIPIENT, fee);
    }
}
```

---

## 7. Across Protocol — Intent-Based Bridging

### Architecture

Across uses an intent model where relayers (solvers) pre-fund destination chain transfers and are repaid on origin chain via optimistic verification.

```
User on Chain A:
  1. Signs cross-chain intent (input: ETH on Ethereum, output: ETH on Arbitrum)
  2. Calls SpokePool.depositV3() — locks funds, emits DepositV3 event

Relayer:
  3. Detects DepositV3 event
  4. Immediately fills on destination (SpokePool.fillRelay())
  5. User receives funds on destination within ~2-10 seconds

Optimistic Verification:
  6. Relayer submits repayment claim to HubPool on Ethereum
  7. 2-hour challenge window (anyone can dispute invalid fills)
  8. If unchallenged, relayer receives repayment + LP fees
```

### SpokePool Intent Deposit

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SpokePool {
    struct DepositData {
        address depositor;
        address recipient;       // Recipient on destination chain
        address inputToken;
        address outputToken;
        uint256 inputAmount;
        uint256 outputAmount;    // Minimum output (intent constraint)
        uint256 destinationChainId;
        address exclusiveRelayer; // Optional: exclusive relayer for period
        uint32 quoteTimestamp;   // Timestamp used to price LP fee
        uint32 fillDeadline;
        uint32 exclusivityDeadline;
        bytes message;           // Arbitrary execution data on destination
    }

    event V3FundsDeposited(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 indexed destinationChainId,
        uint32 indexed depositId,
        uint32 quoteTimestamp,
        uint32 fillDeadline,
        uint32 exclusivityDeadline,
        address indexed depositor,
        address recipient,
        address exclusiveRelayer,
        bytes message
    );

    event FilledV3Relay(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 repaymentChainId,
        uint256 indexed originChainId,
        uint32 indexed depositId,
        uint32 fillDeadline,
        uint32 exclusivityDeadline,
        address exclusiveRelayer,
        address indexed relayer,
        address depositor,
        address recipient,
        bytes message,
        V3RelayExecutionEventInfo relayExecutionInfo
    );

    uint32 public numberOfDeposits;

    /// @notice User deposits and expresses intent
    function depositV3(
        address depositor,
        address recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 destinationChainId,
        address exclusiveRelayer,
        uint32 quoteTimestamp,
        uint32 fillDeadline,
        uint32 exclusivityDeadline,
        bytes calldata message
    ) external payable {
        uint32 depositId = numberOfDeposits++;

        // Pull input tokens
        if (inputToken == WETH && msg.value > 0) {
            WETH.deposit{value: msg.value}();
        } else {
            IERC20(inputToken).safeTransferFrom(depositor, address(this), inputAmount);
        }

        emit V3FundsDeposited(
            inputToken, outputToken, inputAmount, outputAmount,
            destinationChainId, depositId, quoteTimestamp,
            fillDeadline, exclusivityDeadline, depositor,
            recipient, exclusiveRelayer, message
        );
    }

    /// @notice Relayer fills intent on destination chain
    function fillV3Relay(
        DepositData calldata depositData,
        uint256 repaymentChainId
    ) external {
        bytes32 relayHash = _getRelayHash(depositData);
        require(!fillStatus[relayHash], "Already filled");
        require(block.timestamp <= depositData.fillDeadline, "Fill deadline passed");

        // Check exclusivity
        if (
            depositData.exclusiveRelayer != address(0) &&
            block.timestamp <= depositData.exclusivityDeadline &&
            msg.sender != depositData.exclusiveRelayer
        ) {
            revert("Exclusive relayer period active");
        }

        fillStatus[relayHash] = true;

        // Relayer pays output tokens to recipient
        IERC20(depositData.outputToken).safeTransferFrom(
            msg.sender,
            depositData.recipient,
            depositData.outputAmount
        );

        // Execute arbitrary message if present
        if (depositData.message.length > 0) {
            AcrossMessageHandler(depositData.recipient).handleAcrossMessage(
                depositData.outputToken,
                depositData.outputAmount,
                msg.sender,
                depositData.message
            );
        }

        emit FilledV3Relay(/*...*/);
    }
}
```

### Relayer Implementation (Off-Chain)

```typescript
import { ethers } from "ethers";

class AcrossRelayer {
  private originProvider: ethers.providers.Provider;
  private destProvider: ethers.providers.Provider;
  private signer: ethers.Signer;

  constructor(config: RelayerConfig) {
    this.originProvider = new ethers.providers.JsonRpcProvider(config.originRpc);
    this.destProvider = new ethers.providers.JsonRpcProvider(config.destRpc);
    this.signer = new ethers.Wallet(config.privateKey, this.destProvider);
  }

  async listen(): Promise<void> {
    const originSpokePool = new ethers.Contract(
      ORIGIN_SPOKE_POOL,
      SpokePoolABI,
      this.originProvider
    );

    originSpokePool.on("V3FundsDeposited", async (
      inputToken, outputToken, inputAmount, outputAmount,
      destinationChainId, depositId, quoteTimestamp,
      fillDeadline, exclusivityDeadline, depositor,
      recipient, exclusiveRelayer, message, event
    ) => {
      if (destinationChainId.toNumber() !== DEST_CHAIN_ID) return;

      const profitable = await this.isProfitable({
        inputToken, outputToken, inputAmount, outputAmount,
        fillDeadline: fillDeadline.toNumber(),
      });

      if (!profitable) return;

      await this.fill({
        depositor, recipient, inputToken, outputToken,
        inputAmount, outputAmount, destinationChainId,
        exclusiveRelayer, quoteTimestamp, fillDeadline,
        exclusivityDeadline, message,
        depositId: depositId.toNumber(),
      });
    });
  }

  async isProfitable(params: FillParams): Promise<boolean> {
    // Calculate LP fee from HubPool
    const lpFeeRate = await this.getLpFee(params.inputToken, params.quoteTimestamp);

    // Output = inputAmount * (1 - lpFeeRate) - relayerFee
    const expectedRepayment = params.inputAmount
      .mul(1e18 - lpFeeRate).div(1e18);

    // Profitable if repayment > outputAmount (what we pay)
    return expectedRepayment.gt(params.outputAmount);
  }

  async fill(depositData: DepositData): Promise<void> {
    const destSpokePool = new ethers.Contract(
      DEST_SPOKE_POOL,
      SpokePoolABI,
      this.signer
    );

    // Approve output token
    const outputToken = new ethers.Contract(depositData.outputToken, ERC20ABI, this.signer);
    await outputToken.approve(DEST_SPOKE_POOL, depositData.outputAmount);

    // Fill the relay
    const tx = await destSpokePool.fillV3Relay(
      depositData,
      ORIGIN_CHAIN_ID // repayment chain
    );

    console.log(`Filled deposit ${depositData.depositId} in tx ${tx.hash}`);
  }
}
```

---

## 8. Solver/Filler Architecture

### Solver Components

```
┌─────────────────────────────────────────────────────────┐
│                    SOLVER ARCHITECTURE                   │
├─────────────────┬───────────────────┬───────────────────┤
│   Order Intake  │   Solving Engine  │  Execution Layer  │
│                 │                   │                   │
│ - API polling   │ - Price feeds     │ - Tx construction │
│ - WebSocket     │ - Route finding   │ - Gas estimation  │
│ - P2P orders    │ - Simulation      │ - MEV protection  │
│ - Mempool watch │ - Profitability   │ - Flashloans      │
└─────────────────┴───────────────────┴───────────────────┘
```

### Solver Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Solver contract — implements IReactorCallback for UniswapX
contract ExampleSolver is IReactorCallback {
    ISwapRouter public immutable uniswapRouter;
    address public immutable owner;

    error OnlyOwner();
    error OnlyReactor();

    constructor(ISwapRouter _router) {
        uniswapRouter = _router;
        owner = msg.sender;
    }

    /// @notice Fill via direct token transfer (solver holds inventory)
    function fillDirect(
        IReactor reactor,
        SignedOrder calldata order,
        address outputToken,
        uint256 outputAmount
    ) external {
        if (msg.sender != owner) revert OnlyOwner();

        IERC20(outputToken).approve(address(reactor), outputAmount);
        reactor.execute(order);
    }

    /// @notice Fill via callback — solver gets input tokens, must provide output
    function fillWithCallback(
        IReactor reactor,
        SignedOrder calldata order,
        bytes calldata callbackData
    ) external {
        if (msg.sender != owner) revert OnlyOwner();
        reactor.executeWithCallback(order, callbackData);
    }

    /// @notice Called by reactor after pulling input tokens — must provide outputs
    function reactorCallback(
        ResolvedOrder[] calldata resolvedOrders,
        bytes calldata callbackData
    ) external override {
        // Only callable by known reactor
        // In production: maintain whitelist of trusted reactors

        (address[] memory route, bytes memory swapData) = abi.decode(
            callbackData,
            (address[], bytes)
        );

        for (uint256 i = 0; i < resolvedOrders.length; i++) {
            ResolvedOrder calldata order = resolvedOrders[i];

            // Swap input token (received from reactor) for output token
            IERC20(order.input.token).approve(address(uniswapRouter), order.input.amount);

            ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                path: swapData,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: order.input.amount,
                amountOutMinimum: 0 // Reactor will verify minimum
            });

            uint256 amountOut = uniswapRouter.exactInput(params);

            // Transfer output to each recipient
            for (uint256 j = 0; j < order.outputs.length; j++) {
                IERC20(order.outputs[j].token).transfer(
                    order.outputs[j].recipient,
                    order.outputs[j].amount
                );
            }

            // Keep any surplus as solver profit
        }
    }

    /// @notice Withdraw profits
    function withdraw(address token, uint256 amount) external {
        if (msg.sender != owner) revert OnlyOwner();
        IERC20(token).transfer(owner, amount);
    }

    receive() external payable {}
}
```

### Flashloan-Powered Solver

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Solver using Balancer flashloans for capital efficiency
contract FlashloanSolver is IReactorCallback, IFlashLoanRecipient {
    IBalancerVault public immutable vault;
    IReactor public immutable reactor;

    struct FlashCallbackData {
        SignedOrder[] orders;
        address[] tokens;
        uint256[] amounts;
        bytes swapData;
    }

    function fillWithFlashloan(
        SignedOrder[] calldata orders,
        address[] calldata loanTokens,
        uint256[] calldata loanAmounts,
        bytes calldata swapData
    ) external {
        bytes memory userData = abi.encode(FlashCallbackData({
            orders: orders,
            tokens: loanTokens,
            amounts: loanAmounts,
            swapData: swapData
        }));

        // Flash loan provides capital upfront
        vault.flashLoan(this, loanTokens, loanAmounts, userData);
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(vault));

        FlashCallbackData memory data = abi.decode(userData, (FlashCallbackData));

        // Now have tokens — fill orders via reactor
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(address(reactor), type(uint256).max);
        }

        // Execute batch — reactor will call our reactorCallback
        SignedOrder[] memory orders = data.orders;
        reactor.executeBatch(orders);

        // Repay flashloan + fees
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).transfer(address(vault), amounts[i] + feeAmounts[i]);
        }
    }

    function reactorCallback(
        ResolvedOrder[] calldata resolvedOrders,
        bytes calldata callbackData
    ) external override {
        // Swap received input tokens to output tokens via AMMs
        // (implementation depends on route)
    }
}
```

---

## 9. Order Types

### Limit Orders

Fixed price orders that execute at or better than specified price. Foundational primitive.

```solidity
struct LimitOrder {
    OrderInfo info;
    InputToken input;
    OutputToken[] outputs;
    // No decay — fixed amounts
}
```

### Dutch Auction Orders

Price starts favorable to the filler and decays toward minimum acceptable over time. Optimal for market orders without fixed price.

```solidity
// Decay config: input grows (user provides more), output decays (user receives less)
DutchOrder({
    decayStartTime: block.timestamp + 12,      // 1 block from now
    decayEndTime: block.timestamp + 120,        // 10 blocks from now
    input: DutchInput({
        token: WETH,
        startAmount: 1 ether,    // Favorable to filler (they get 1 ETH)
        endAmount: 1.02 ether,   // At end: user provides 1.02 ETH (their max)
    }),
    outputs: [DutchOutput({
        token: USDC,
        startAmount: 2100e6,     // User receives 2100 USDC initially
        endAmount: 2000e6,       // At end: user receives minimum 2000 USDC
        recipient: user
    })]
})
```

### RFQ (Request for Quote)

Market makers provide firm quotes off-chain; user signs acceptance. Zero-decay, immediate execution.

```typescript
// Off-chain RFQ flow
async function getRFQQuote(
  inputToken: string,
  outputToken: string,
  inputAmount: bigint
): Promise<RFQQuote> {
  // Broadcast to multiple market makers
  const quotes = await Promise.allSettled(
    MARKET_MAKERS.map(mm => mm.getQuote({ inputToken, outputToken, inputAmount }))
  );

  // Select best quote
  return quotes
    .filter(q => q.status === "fulfilled")
    .map(q => (q as PromiseFulfilledResult<RFQQuote>).value)
    .sort((a, b) => Number(b.outputAmount - a.outputAmount))[0];
}
```

### Sealed-Bid Auctions

Fillers submit encrypted bids; revealed after deadline. Prevents frontrunning of solver strategies.

### Batch Auctions (CoW Protocol)

All orders in a time window are settled simultaneously at uniform clearing prices, enabling coincidence of wants.

---

## 10. MEV Protection Through Intents

### Traditional MEV Attack Surface

```
User submits swap tx to public mempool
  → Searcher detects pending tx
  → Searcher front-runs: buy token before user (price goes up)
  → User's tx executes at worse price
  → Searcher back-runs: sell token after user
  → Result: sandwich attack, user loses ~0.5-2%
```

### Intent MEV Protection

```
User signs intent (never hits public mempool)
  → Private propagation to solver network
  → Solvers compete off-chain — no public visibility
  → Winning solver submits single tx (atomic, no frontrun gap)
  → Result: no sandwich attack possible
```

### Surplus Sharing

Solvers extract MEV from their routing strategies. Protocols can enforce surplus return to users:

```solidity
// CoW Protocol: surplus goes to trader, not solver
// Surplus = (executedBuyAmount / orderBuyAmount - 1) * orderSellAmount
// Solvers compete to maximize surplus → user benefits

// UniswapX: any output above minimum is solver's profit
// BUT Dutch auction decay: if price is good, solver fills early
// → competitive pressure drives solver to fill at best price
```

### Quantifying MEV Protection

```typescript
// Compare execution quality: intent vs direct swap
interface ExecutionReport {
  intendedAmount: bigint;   // What user specified as minimum
  executedAmount: bigint;   // What user actually received
  marketAmount: bigint;     // What AMM would have given (including MEV)
  surplus: bigint;          // executedAmount - marketAmount (>0 = user won)
  savingVsMarket: number;   // Percentage saved
}

function analyzeExecution(report: ExecutionReport): string {
  const savingBps = Number(report.surplus * 10000n / report.marketAmount);
  return `User received ${savingBps} bps better than direct AMM execution`;
}
```

---

## 11. Cross-Chain Intents

### Multi-Hop Solving

Single intent can be filled across multiple chains and bridges:

```
User: 1000 USDC on Ethereum → MATIC on Polygon

Solver route (off-chain computed):
  1. Ethereum: USDC → WETH (Uniswap V3)
  2. Ethereum → Polygon: bridge WETH (Across relayer)
  3. Polygon: WETH → MATIC (QuickSwap)

Atomic from user perspective: sign one intent, receive MATIC
```

### Liquidity Fragmentation Solutions

```
Problem: ETH liquidity is split across:
  Ethereum L1, Arbitrum, Optimism, Base, Polygon, ...

Intent solution:
  Solver aggregates cross-chain liquidity off-chain
  Single fill transaction sources from optimal locations
  User sees unified liquidity pool
```

### Cross-Chain Nonce Management

```solidity
// Prevent replay across chains
struct CrossChainNonce {
    uint256 nonce;
    uint256 originChainId;
    uint256 destinationChainId;
}

mapping(address => mapping(bytes32 => bool)) public usedNonces;

function _validateNonce(address user, CrossChainNonce memory nonceData) internal {
    bytes32 nonceHash = keccak256(abi.encode(nonceData));
    require(!usedNonces[user][nonceHash], "Nonce already used");
    usedNonces[user][nonceHash] = true;
}
```

### Optimistic vs ZK Cross-Chain Verification

| Method | Latency | Security | Cost |
|---|---|---|---|
| Optimistic (Across) | ~2 hours finality | Economic bonds | Low |
| Light client (zkBridge) | Minutes | Cryptographic | High |
| Native messaging (LayerZero) | Minutes | Decentralized oracles | Medium |
| Relay + rebalance | Seconds (user) | Relayer bond | Very low (per tx) |

---

## 12. Building Intent-Based Applications

### Order Signing (EIP-712) — Complete Implementation

```typescript
import { ethers, TypedDataDomain, TypedDataField } from "ethers";

// ============ Type Definitions ============

interface OrderInfo {
  reactor: string;
  swapper: string;
  nonce: bigint;
  deadline: number;
  additionalValidationContract: string;
  additionalValidationData: string;
}

interface DutchInput {
  token: string;
  startAmount: bigint;
  endAmount: bigint;
}

interface DutchOutput {
  token: string;
  startAmount: bigint;
  endAmount: bigint;
  recipient: string;
}

interface DutchOrderData {
  info: OrderInfo;
  decayStartTime: number;
  decayEndTime: number;
  exclusiveFiller: string;
  exclusivityOverrideBps: bigint;
  input: DutchInput;
  outputs: DutchOutput[];
}

// ============ EIP-712 Domain & Types ============

const UNISWAPX_DOMAIN: TypedDataDomain = {
  name: "UniswapX",
  chainId: 1,
  verifyingContract: "0x6000da47483062A0D734Ba3dc7576Ce6A0B645C4", // Mainnet reactor
};

const DUTCH_ORDER_TYPES: Record<string, TypedDataField[]> = {
  DutchOrder: [
    { name: "info", type: "OrderInfo" },
    { name: "decayStartTime", type: "uint256" },
    { name: "decayEndTime", type: "uint256" },
    { name: "exclusiveFiller", type: "address" },
    { name: "exclusivityOverrideBps", type: "uint256" },
    { name: "input", type: "DutchInput" },
    { name: "outputs", type: "DutchOutput[]" },
  ],
  OrderInfo: [
    { name: "reactor", type: "address" },
    { name: "swapper", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
    { name: "additionalValidationContract", type: "address" },
    { name: "additionalValidationData", type: "bytes" },
  ],
  DutchInput: [
    { name: "token", type: "address" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
  ],
  DutchOutput: [
    { name: "token", type: "address" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
    { name: "recipient", type: "address" },
  ],
};

// ============ Order Builder ============

class DutchOrderBuilder {
  private chainId: number;
  private reactorAddress: string;

  constructor(chainId: number, reactorAddress: string) {
    this.chainId = chainId;
    this.reactorAddress = reactorAddress;
  }

  buildMarketOrder(params: {
    swapper: string;
    nonce: bigint;
    inputToken: string;
    outputToken: string;
    inputAmount: bigint;
    minOutputAmount: bigint;
    maxOutputAmount: bigint;
    deadlineSeconds?: number;
    decayDurationSeconds?: number;
  }): DutchOrderData {
    const now = Math.floor(Date.now() / 1000);
    const deadline = now + (params.deadlineSeconds ?? 120);
    const decayDuration = params.decayDurationSeconds ?? 60;

    return {
      info: {
        reactor: this.reactorAddress,
        swapper: params.swapper,
        nonce: params.nonce,
        deadline,
        additionalValidationContract: ethers.constants.AddressZero,
        additionalValidationData: "0x",
      },
      decayStartTime: now + 12,       // ~1 block from now
      decayEndTime: now + decayDuration,
      exclusiveFiller: ethers.constants.AddressZero,
      exclusivityOverrideBps: 0n,
      input: {
        token: params.inputToken,
        startAmount: params.inputAmount,
        endAmount: params.inputAmount, // Input doesn't decay for market orders
      },
      outputs: [{
        token: params.outputToken,
        startAmount: params.maxOutputAmount, // User gets max at start
        endAmount: params.minOutputAmount,   // User gets min at end
        recipient: params.swapper,
      }],
    };
  }

  async sign(
    signer: ethers.Signer,
    order: DutchOrderData
  ): Promise<{ order: DutchOrderData; signature: string; orderHash: string }> {
    const domain = { ...UNISWAPX_DOMAIN, chainId: this.chainId };
    const signature = await signer._signTypedData(domain, DUTCH_ORDER_TYPES, order);
    const orderHash = ethers.utils._TypedDataEncoder.hash(domain, DUTCH_ORDER_TYPES, order);

    return { order, signature, orderHash };
  }
}

// ============ Usage Example ============

async function createAndSubmitIntent(
  signer: ethers.Signer,
  provider: ethers.providers.Provider
) {
  const chainId = (await provider.getNetwork()).chainId;
  const builder = new DutchOrderBuilder(chainId, REACTOR_ADDRESS);

  // Get current nonce from permit2
  const permit2 = new ethers.Contract(PERMIT2_ADDRESS, Permit2ABI, provider);
  const { nonce } = await permit2.allowance(
    await signer.getAddress(),
    WETH_ADDRESS,
    REACTOR_ADDRESS
  );

  const order = builder.buildMarketOrder({
    swapper: await signer.getAddress(),
    nonce: BigInt(nonce),
    inputToken: WETH_ADDRESS,
    outputToken: USDC_ADDRESS,
    inputAmount: ethers.utils.parseEther("1"),
    minOutputAmount: ethers.utils.parseUnits("1950", 6),  // Minimum 1950 USDC
    maxOutputAmount: ethers.utils.parseUnits("2100", 6),  // Best case 2100 USDC
  });

  const { signature, orderHash } = await builder.sign(signer, order);

  // Submit to UniswapX API
  const response = await fetch("https://api.uniswap.org/v2/orders", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      encodedOrder: encodeOrder(order),
      signature,
      chainId,
      orderStatus: "open",
    }),
  });

  const { hash } = await response.json();
  console.log(`Order submitted: ${hash}`);
  return hash;
}
```

### Permit2 Integration

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// UniswapX uses Permit2 for gasless token approvals
// User approves Permit2 once, then signs per-order permits

interface IPermit2 {
    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}

library Permit2Lib {
    function transferInputTokens(
        ResolvedOrder memory order,
        IPermit2 permit2
    ) internal {
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({
                token: order.input.token,
                amount: order.input.maxAmount
            }),
            nonce: order.info.nonce,
            deadline: order.info.deadline
        });

        IPermit2.SignatureTransferDetails memory transferDetails =
            IPermit2.SignatureTransferDetails({
                to: address(this), // Reactor receives input
                requestedAmount: order.input.amount
            });

        permit2.permitTransferFrom(
            permit,
            transferDetails,
            order.info.swapper,
            order.sig
        );
    }
}
```

### Reactor Pattern — Extensibility

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Custom reactor for protocol-specific orders
/// @dev Inherit BaseReactor, implement resolve()
contract ProtocolSpecificReactor is BaseReactor {
    struct ProtocolOrder {
        OrderInfo info;
        // Protocol-specific fields
        uint256 twapPeriod;          // TWAP-based pricing
        address priceOracle;          // Oracle for reference price
        uint256 maxSlippageBps;       // Max deviation from oracle
        InputToken input;
        OutputToken[] outputs;
    }

    constructor(IPermit2 _permit2) BaseReactor(_permit2) {}

    function resolve(SignedOrder calldata signedOrder)
        internal
        override
        returns (ResolvedOrder memory)
    {
        ProtocolOrder memory order = abi.decode(signedOrder.order, (ProtocolOrder));

        // Validate deadline
        if (block.timestamp > order.info.deadline) revert OrderExpired();

        // Get TWAP price from oracle
        uint256 twapPrice = ITWAPOracle(order.priceOracle).getTWAP(
            order.input.token,
            order.outputs[0].token,
            order.twapPeriod
        );

        // Calculate maximum output based on oracle + slippage
        uint256 maxOutput = order.input.amount * twapPrice *
            (10000 + order.maxSlippageBps) / 10000 / 1e18;

        return ResolvedOrder({
            info: order.info,
            input: order.input,
            outputs: _applyOracleConstraint(order.outputs, maxOutput),
            sig: signedOrder.sig,
            hash: keccak256(signedOrder.order)
        });
    }
}
```

### Nonce Management & Cancellation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Nonce management — orders can be cancelled before filling
contract NonceManager {
    // word -> bit map (each bit = one nonce, 256 nonces per word)
    mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

    event NonceInvalidation(
        address indexed owner,
        uint256 word,
        uint256 mask
    );

    function _useNonce(address user, uint256 nonce) internal {
        uint256 word = nonce >> 8;          // Which 256-bit word
        uint256 bit = 1 << (nonce & 0xff);  // Which bit in that word
        uint256 bitmap = nonceBitmap[user][word];
        require(bitmap & bit == 0, "Nonce already used");
        nonceBitmap[user][word] = bitmap | bit;
    }

    /// @notice Cancel specific nonces before they're filled
    function cancelOrders(uint256[] calldata nonces) external {
        for (uint256 i = 0; i < nonces.length; i++) {
            uint256 word = nonces[i] >> 8;
            uint256 bit = 1 << (nonces[i] & 0xff);
            nonceBitmap[msg.sender][word] |= bit;
        }
    }

    /// @notice Cancel a range by invalidating entire word
    function cancelOrdersInWord(uint256 wordIndex, uint256 mask) external {
        nonceBitmap[msg.sender][wordIndex] |= mask;
        emit NonceInvalidation(msg.sender, wordIndex, mask);
    }

    function isNonceUsed(address user, uint256 nonce) external view returns (bool) {
        uint256 word = nonce >> 8;
        uint256 bit = 1 << (nonce & 0xff);
        return nonceBitmap[user][word] & bit != 0;
    }
}
```

### Monitoring & Indexing Intent Settlement

```typescript
import { ethers } from "ethers";

// Index Fill events for settlement tracking
class IntentIndexer {
  private provider: ethers.providers.Provider;
  private reactor: ethers.Contract;

  async indexFills(fromBlock: number, toBlock: number) {
    const fillFilter = this.reactor.filters.Fill();
    const events = await this.reactor.queryFilter(fillFilter, fromBlock, toBlock);

    return events.map(event => ({
      orderHash: event.args!.orderHash,
      swapper: event.args!.swapper,
      nonce: event.args!.nonce.toBigInt(),
      filler: event.args!.filler,
      blockNumber: event.blockNumber,
      txHash: event.transactionHash,
    }));
  }

  async watchForFill(orderHash: string, timeoutMs: number = 120_000): Promise<FillEvent> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error("Fill timeout")), timeoutMs);

      this.reactor.once(
        this.reactor.filters.Fill(orderHash),
        (hash, swapper, nonce, filler, event) => {
          clearTimeout(timeout);
          resolve({ hash, swapper, nonce, filler, event });
        }
      );
    });
  }
}
```

---

## Key Invariants and Security Considerations

### Critical Invariants

1. **Output constraint is sacred** — reactor MUST verify user received at least the specified minimum output. If this check is bypassable, the entire model collapses.

2. **Nonce is single-use** — double-spend prevention is mandatory. Use bitmap nonces for gas efficiency.

3. **Deadline enforced on-chain** — off-chain deadline checks are advisory only; on-chain check is the guarantee.

4. **Signature covers all order fields** — partial hash omissions allow substitution attacks where solver modifies order fields.

5. **Reentrancy during callback** — solver callback executes between input pull and output verification. Must prevent solver from re-entering reactor to manipulate state.

### Common Vulnerabilities

```
1. Signature malleability — use EIP-712, not raw hash signing
2. Missing slippage check — always verify output >= minimum in settlement
3. Stale oracle price — use time-bounded TWAP, not spot
4. Exclusive filler bypass — check exclusivity window server-side AND on-chain
5. Cross-chain replay — include chainId in intent hash
6. Callback reentrancy — use checks-effects-interactions or reentrancy guard
7. Permit2 nonce collision — nonces must be globally unique per user per reactor
```

### Gas Optimization for Solvers

```solidity
// Batch multiple orders in single transaction (significant gas savings)
// Each additional order in batch costs ~30-50% less than standalone

// Use transient storage (EIP-1153) for solver context during callback
// assembly { tstore(SLOT_CURRENT_FILLER, caller()) }

// Pre-compute order hashes off-chain — avoid redundant on-chain computation
// Calldata optimization: pack struct fields to minimize calldata cost
```

---

## Protocol Comparison

| Protocol | Auction Type | Solver Selection | MEV Return | Cross-Chain |
|---|---|---|---|---|
| UniswapX | Dutch auction | First valid filler | Implicit (competition) | Yes (V2) |
| CoW Protocol | Batch auction | Best surplus | Explicit (surplus sharing) | Partial |
| 1inch Fusion | Dutch auction | Staked resolvers | Implicit | No |
| Across | First-price | First relayer | Relayer profit | Yes (native) |
| 0x RFQ | Fixed quote | Best quote | Quote spread | No |

---

## References

- UniswapX whitepaper and reactor contracts: github.com/Uniswap/UniswapX
- CoW Protocol: docs.cow.fi/cow-protocol/concepts
- ERC-7683: eips.ethereum.org/EIPS/eip-7683
- Across Protocol: docs.across.to
- 1inch Fusion: docs.1inch.io/docs/fusion-swap
- Permit2: github.com/Uniswap/permit2
