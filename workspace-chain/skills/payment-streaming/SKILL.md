# Payment Streaming

## Sablier V2 — Production Integration

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import "@sablier/v2-core/src/interfaces/ISablierV2LockupDynamic.sol";
import "@sablier/v2-core/src/types/DataTypes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SpartaPayments {
    using SafeERC20 for IERC20;

    ISablierV2LockupLinear  public immutable sablierLinear;
    ISablierV2LockupDynamic public immutable sablierDynamic;
    IERC20 public immutable usdc;

    // Stream IDs for tracking
    mapping(address => uint256[]) public userStreams;   // recipient → stream IDs
    mapping(bytes32 => uint256) public challengeStreams; // challengeId → prize stream ID

    event PrizeStreamCreated(bytes32 indexed challengeId, address winner, uint256 streamId);
    event SubscriptionStarted(address indexed subscriber, uint256 streamId);

    constructor(address _linear, address _dynamic, address _usdc) {
        sablierLinear  = ISablierV2LockupLinear(_linear);
        sablierDynamic = ISablierV2LockupDynamic(_dynamic);
        usdc = IERC20(_usdc);
    }

    // ──────── PRIZE DISTRIBUTION ────────

    // Stream prize to winner over 7 days (reduces immediate dump pressure)
    function streamPrize(
        bytes32 challengeId,
        address winner,
        uint256 prizeAmount
    ) external onlyArena returns (uint256 streamId) {
        usdc.safeTransferFrom(msg.sender, address(this), prizeAmount);
        usdc.approve(address(sablierLinear), prizeAmount);

        LockupLinear.CreateWithDurations memory params = LockupLinear.CreateWithDurations({
            sender:      address(this), // Contract is sender — can cancel if fraud detected
            recipient:   winner,
            totalAmount: uint128(prizeAmount),
            asset:       usdc,
            cancelable:  true,          // Admin can cancel within 24h if result is disputed
            transferable: true,         // Winner can sell/transfer the stream NFT
            durations: LockupLinear.Durations({
                cliff: 0,               // Immediate access to first portion
                total: uint40(7 days)   // Full amount released over 7 days
            }),
            broker: Broker(address(0), UD60x18.wrap(0))
        });

        streamId = sablierLinear.createWithDurations(params);
        challengeStreams[challengeId] = streamId;
        userStreams[winner].push(streamId);

        emit PrizeStreamCreated(challengeId, winner, streamId);
    }

    // ──────── SUBSCRIPTION STREAMING ────────

    // User starts a $10/month Pro subscription via streaming
    // User pre-approves contract to transfer USDC
    function startSubscription(
        uint128 monthlyAmount,  // e.g., 10e6 = $10 USDC
        uint8 months
    ) external returns (uint256 streamId) {
        uint128 total = monthlyAmount * months;
        usdc.safeTransferFrom(msg.sender, address(this), total);
        usdc.approve(address(sablierLinear), total);

        LockupLinear.CreateWithDurations memory params = LockupLinear.CreateWithDurations({
            sender:       msg.sender,         // User can cancel their own subscription
            recipient:    address(this),       // Protocol receives the stream
            totalAmount:  total,
            asset:        usdc,
            cancelable:   true,                // Cancel anytime, unstreamed portion returned
            transferable: false,
            durations: LockupLinear.Durations({
                cliff: 0,
                total: uint40(months * 30 days)
            }),
            broker: Broker(address(0), UD60x18.wrap(0))
        });

        streamId = sablierLinear.createWithDurations(params);
        userStreams[msg.sender].push(streamId);

        emit SubscriptionStarted(msg.sender, streamId);
    }

    // Check if user has active subscription
    function hasActiveSubscription(address user) external view returns (bool) {
        uint256[] memory streams = userStreams[user];
        for (uint i = 0; i < streams.length; i++) {
            if (sablierLinear.statusOf(streams[i]) == Lockup.Status.STREAMING) {
                // Check if stream is to protocol (not from protocol to user)
                if (sablierLinear.getRecipient(streams[i]) == address(this)) {
                    return true;
                }
            }
        }
        return false;
    }

    // Withdraw accumulated subscription revenue
    function collectRevenue() external onlyOwner {
        // Withdraw from all active subscription streams
        for (uint i = 0; i < allSubscriptionStreamIds.length; i++) {
            sablierLinear.withdrawMax(allSubscriptionStreamIds[i], address(this));
        }
    }
}
```

## Dynamic Streams (Milestone-Based)

```solidity
// Stream that unlocks faster as milestones are hit
// E.g., grant that pays more when KPIs are met

function createMilestoneStream(
    address grantee,
    uint256 totalGrant,
    uint64[] memory timestamps,    // Milestone unlock timestamps
    uint128[] memory percentages   // Cumulative % unlocked at each milestone
) external onlyDAO returns (uint256 streamId) {
    LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](timestamps.length);

    uint128 allocated;
    for (uint i = 0; i < timestamps.length; i++) {
        uint128 amount = uint128(totalGrant * percentages[i] / 100) - allocated;
        allocated += amount;
        segments[i] = LockupDynamic.Segment({
            amount:   amount,
            exponent: UD2x18.wrap(1e18), // Linear within segment
            timestamp: timestamps[i]
        });
    }

    usdc.approve(address(sablierDynamic), totalGrant);

    streamId = sablierDynamic.createWithMilestones(
        LockupDynamic.CreateWithMilestones({
            sender:      address(this),
            startTime:   uint40(block.timestamp),
            cancelable:  true,
            transferable: false,
            recipient:   grantee,
            totalAmount: uint128(totalGrant),
            asset:       usdc,
            segments:    segments,
            broker:      Broker(address(0), UD60x18.wrap(0))
        })
    );
}
```

## Superfluid (Real-Time Streaming)

```typescript
import { Framework } from "@superfluid-finance/sdk-core";

async function startSuperfluidStream(
    recipientAddress: string,
    flowRatePerSecond: string, // e.g., "3858" = ~$10/month in wei/s
    signer: ethers.Signer
) {
    const sf = await Framework.create({
        chainId: 8453, // Base
        provider: signer.provider!
    });

    const usdcx = await sf.loadSuperToken("USDCx"); // Wrapped USDC that supports streaming

    // Start stream
    const createFlowOp = usdcx.createFlow({
        sender:    await signer.getAddress(),
        receiver:  recipientAddress,
        flowRate:  flowRatePerSecond
    });

    await createFlowOp.exec(signer);
    console.log(`Streaming ${flowRatePerSecond} USDCx/sec to ${recipientAddress}`);
}
```
