# DAO Treasury Management

## Safe Multisig — Production Setup

```typescript
import Safe, { EthersAdapter } from "@safe-global/protocol-kit";
import { ethers } from "ethers";

async function deployTreasury(ownerAddresses: string[], threshold: number) {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const signer   = new ethers.Wallet(process.env.DEPLOYER_KEY!, provider);

    const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: signer });

    const safeFactory = await SafeFactory.create({ ethAdapter });

    const safeAccountConfig = {
        owners:    ownerAddresses,      // e.g., ["0xNick", "0xAdvisor1", "0xAdvisor2"]
        threshold: threshold            // e.g., 2 (2-of-3 multisig)
    };

    const safe = await safeFactory.deploySafe({ safeAccountConfig });
    console.log("Treasury deployed at:", await safe.getAddress());
    return safe;
}

// Structure for Perlantir DAO:
// Treasury Safe:    3-of-5 multisig (Nick + 2 core team + 2 community reps)
// Operations Safe:  2-of-3 multisig (Nick + 2 core team) — day-to-day spending
// Grants Committee: 2-of-3 multisig (community members) — small grants <$5K
```

## Timelock Controller

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/governance/TimelockController.sol";

// Deploy timelock with 2-day delay
// Safe (proposer) → proposes → 2-day wait → Safe (executor) can execute
// 2-day window allows community to react to suspicious proposals
contract SpartaTimelock is TimelockController {
    constructor(
        address[] memory proposers,  // Safe address
        address[] memory executors,  // Safe address (or address(0) = anyone can execute after delay)
        address admin
    )
        TimelockController(
            2 days,      // minimum delay
            proposers,
            executors,
            admin
        )
    {}
}
```

## Token Buyback & Burn

```solidity
contract BuybackBurner {
    IUniswapV2Router02 public immutable router;
    IERC20 public immutable token;
    IERC20 public immutable usdc;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // Minimum USDC accumulated before triggering buyback
    uint256 public threshold = 10_000e6; // $10K

    event Buyback(uint256 usdcSpent, uint256 tokensBurned);

    function executeBuyback() external {
        uint256 usdcBalance = usdc.balanceOf(address(this));
        require(usdcBalance >= threshold, "Below threshold");

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(token);

        usdc.approve(address(router), usdcBalance);

        // TWAP execution: split into 10 smaller buys over 10 blocks to reduce impact
        uint256 amountPerTx = usdcBalance / 10;
        uint256 totalBurned;

        for (uint i = 0; i < 10; i++) {
            uint256[] memory amounts = router.swapExactTokensForTokens(
                amountPerTx, 0, path, DEAD, block.timestamp // Send directly to dead address
            );
            totalBurned += amounts[1];
        }

        emit Buyback(usdcBalance, totalBurned);
    }
}
```

## Sablier Payment Streaming

```solidity
// For team salaries and grant streaming
import "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";

contract TreasuryPayroll {
    ISablierV2LockupLinear public immutable sablier;
    IERC20 public immutable usdc;

    // Stream $5K/month salary to team member
    function streamSalary(
        address recipient,
        uint256 monthlyAmount,
        uint128 durationMonths
    ) external returns (uint256 streamId) {
        uint256 totalAmount = monthlyAmount * durationMonths;
        usdc.approve(address(sablier), totalAmount);

        LockupLinear.CreateWithDurations memory params = LockupLinear.CreateWithDurations({
            sender:      address(this),
            recipient:   recipient,
            totalAmount: uint128(totalAmount),
            asset:       usdc,
            cancelable:  true,           // Treasury can cancel if team member leaves
            transferable: false,         // Non-transferable stream NFT
            durations:   LockupLinear.Durations({
                cliff:  0,               // No cliff — starts streaming immediately
                total:  uint40(durationMonths * 30 days)
            }),
            broker:      Broker(address(0), ud60x18(0))
        });

        streamId = sablier.createWithDurations(params);
    }

    // Cancel salary stream (upon termination)
    function cancelStream(uint256 streamId) external onlyMultisig {
        sablier.cancel(streamId);
        // Unstreamed funds return to treasury automatically
    }
}
```

## Treasury Asset Allocation Strategy

```
OPERATIONAL TREASURY (6-month runway in stablecoins)
├── USDC: 70% → Aave/Maker DSR for yield (~5% APY)
├── ETH: 20% → Strategic reserve
└── Protocol token: 10% → Incentive programs

RESERVE TREASURY (long-term)
├── US T-Bills via Ondo Finance: 50%
├── ETH: 30%
└── BTC: 20%

GRANTS TREASURY
└── Protocol tokens, released monthly based on milestones

BURN ADDRESS (permanent token reduction)
└── 50% of all protocol revenue
```

## On-Chain Governance Proposal

```solidity
// Standard Governor.sol proposal
function proposeGrantAllocation(
    address grantee,
    uint256 usdcAmount,
    string calldata description
) external returns (uint256 proposalId) {
    address[] memory targets = new address[](1);
    uint256[] memory values  = new uint256[](1);
    bytes[]   memory calldatas = new bytes[](1);

    targets[0]    = address(usdc);
    values[0]     = 0;
    calldatas[0]  = abi.encodeWithSignature(
        "transfer(address,uint256)", grantee, usdcAmount
    );

    return governor.propose(targets, values, calldatas, description);
}
// Proposal lifecycle: propose → 2-day voting delay → 5-day voting period → 2-day timelock → execute
```
