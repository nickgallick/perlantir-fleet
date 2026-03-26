# Staking Rewards Contracts

## Production StakingRewards with Anti-Gaming Protections

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title SpartaStaking
/// @notice Stake SPARTA tokens, earn REWARD tokens over time
/// @dev Synthetix StakingRewards pattern with anti-flash-loan protections
contract SpartaStaking is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ── Tokens ────────────────────────────────────────────────────────────────
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    // ── Timing ───────────────────────────────────────────────────────────────
    uint256 public constant DURATION = 30 days;
    uint256 public constant MIN_STAKE_DURATION = 1 days;   // Anti-flash-loan
    uint256 public constant MIN_STAKE_AMOUNT   = 100e18;   // Anti-dust attacks

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    // ── User State ────────────────────────────────────────────────────────────
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public stakeTimestamp;  // When user last staked

    uint256 public totalSupply;

    // ── Events ────────────────────────────────────────────────────────────────
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);

    constructor(
        address _stakingToken,
        address _rewardsToken,
        address _owner
    ) Ownable(_owner) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    // ── Core Math ─────────────────────────────────────────────────────────────

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /// @notice Accumulated reward per staked token (scaled by 1e18)
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (
            (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / totalSupply
        );
    }

    /// @notice How much reward a user can currently claim
    function earned(address account) public view returns (uint256) {
        return (
            balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18
        ) + rewards[account];
    }

    // ── State Update Modifier ─────────────────────────────────────────────────

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime       = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account]              = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // ── User Actions ──────────────────────────────────────────────────────────

    /// @notice Stake tokens to start earning rewards
    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount >= MIN_STAKE_AMOUNT, "Below minimum stake");

        totalSupply           += amount;
        balanceOf[msg.sender] += amount;
        stakeTimestamp[msg.sender] = block.timestamp; // Reset lock on each stake

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice Withdraw staked tokens
    /// @dev Requires MIN_STAKE_DURATION has passed since last stake
    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        // ── ANTI-FLASH-LOAN PROTECTION ────────────────────────────────────────
        // Prevents: stake → claim accumulated rewards → withdraw in same block/tx
        require(
            block.timestamp >= stakeTimestamp[msg.sender] + MIN_STAKE_DURATION,
            "MIN_STAKE_DURATION not met"
        );

        totalSupply           -= amount;
        balanceOf[msg.sender] -= amount;

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Claim earned rewards
    function getReward()
        public
        nonReentrant
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    /// @notice Withdraw all staked tokens and claim rewards in one tx
    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    // ── Owner Actions ─────────────────────────────────────────────────────────

    /// @notice Start a new reward period or extend the current one
    /// @param reward Total reward tokens for the upcoming period
    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            // Starting fresh period
            rewardRate = reward / DURATION;
        } else {
            // Extending — add remaining rewards to new total
            uint256 remaining = (periodFinish - block.timestamp) * rewardRate;
            rewardRate = (reward + remaining) / DURATION;
        }

        require(rewardRate > 0, "Reward rate = 0");
        require(
            rewardRate <= rewardsToken.balanceOf(address(this)) / DURATION,
            "Reward too large for balance"
        );

        lastUpdateTime = block.timestamp;
        periodFinish   = block.timestamp + DURATION;
        emit RewardAdded(reward);
    }

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /// @notice Recover accidentally sent tokens (not staking or rewards token)
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(stakingToken),  "Cannot recover staking token");
        require(tokenAddress != address(rewardsToken),  "Cannot recover rewards token");
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }
}
```

## Boosted Staking (veToken Multiplier)

```solidity
/// @notice Curve-style boost: 1x to 2.5x based on veToken balance
function boostedBalance(address account) public view returns (uint256) {
    uint256 rawBalance = balanceOf[account];
    if (rawBalance == 0 || veTotal == 0) return rawBalance;

    // Curve formula: min(bal, bal*0.4 + total*veShare*0.6)
    uint256 veShare = veBalance[account] * 1e18 / veTotal;
    uint256 boosted = rawBalance * 40 / 100 +
                      totalSupply * veShare * 60 / 100 / 1e18;

    return rawBalance < boosted ? rawBalance : boosted;
    // Max 2.5x: veShare = 100% → boosted = 0.4*bal + 0.6*bal = bal (1x base, up to 2.5x with more bal)
}
```

## Multi-Reward Staking

```solidity
/// @notice Stake once, earn multiple reward tokens simultaneously
contract MultiRewardStaking {
    struct Reward {
        address rewardsToken;
        uint256 rewardRate;
        uint256 periodFinish;
        uint256 rewardPerTokenStored;
        uint256 lastUpdateTime;
    }

    address[] public rewardTokens;
    mapping(address => Reward) public rewardData;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid; // token => user => paid
    mapping(address => mapping(address => uint256)) public rewards; // token => user => earned

    function addReward(address rewardsToken, uint256 rewardRate) external onlyOwner {
        rewardTokens.push(rewardsToken);
        rewardData[rewardsToken] = Reward({
            rewardsToken: rewardsToken,
            rewardRate: rewardRate,
            periodFinish: block.timestamp + DURATION,
            rewardPerTokenStored: 0,
            lastUpdateTime: block.timestamp
        });
    }

    function earned(address account, address rewardsToken) public view returns (uint256) {
        Reward memory r = rewardData[rewardsToken];
        uint256 rpt = r.rewardPerTokenStored + (
            (_lastApplicable(r) - r.lastUpdateTime) * r.rewardRate * 1e18 / totalSupply
        );
        return balanceOf[account] * (rpt - userRewardPerTokenPaid[rewardsToken][account]) / 1e18
               + rewards[rewardsToken][account];
    }

    function getReward() external {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 reward = rewards[token][msg.sender];
            if (reward > 0) {
                rewards[token][msg.sender] = 0;
                IERC20(token).safeTransfer(msg.sender, reward);
            }
        }
    }
}
```

## Foundry Tests

```solidity
// test/SpartaStaking.t.sol
contract SpartaStakingTest is Test {
    function testFlashLoanProtection() public {
        // Stake
        vm.startPrank(alice);
        stakingToken.approve(address(staking), 1000e18);
        staking.stake(1000e18);

        // Try to withdraw immediately — should revert
        vm.expectRevert("MIN_STAKE_DURATION not met");
        staking.withdraw(1000e18);
        vm.stopPrank();

        // Wait 1 day
        vm.warp(block.timestamp + 1 days);

        // Now withdrawal works
        vm.prank(alice);
        staking.withdraw(1000e18);
    }

    function testRewardAccrual() public {
        // Notify rewards: 1M tokens over 30 days
        rewardsToken.transfer(address(staking), 1_000_000e18);
        staking.notifyRewardAmount(1_000_000e18);

        // Alice stakes half supply
        vm.startPrank(alice);
        stakingToken.approve(address(staking), 500_000e18);
        staking.stake(500_000e18);
        vm.stopPrank();

        // Advance 15 days (half the period)
        vm.warp(block.timestamp + 15 days);

        // Alice should have ~500,000 tokens (50% of supply * 50% of period)
        uint256 earned = staking.earned(alice);
        assertApproxEqRel(earned, 500_000e18, 0.001e18); // within 0.1%
    }
}
```
