# Liquid Staking Architecture

## stETH Rebasing Mechanics

```solidity
contract StETH is ERC20 {
    // KEY INVARIANT: shares stay constant, balance grows
    // balanceOf = shares × (totalPooledEther / totalShares)

    mapping(address => uint256) private _shares;
    uint256 private _totalShares;
    uint256 public totalPooledEther; // Updated by oracle after each rebase

    function balanceOf(address account) public view override returns (uint256) {
        return getPooledEthByShares(_shares[account]);
    }

    function totalSupply() public view override returns (uint256) {
        return totalPooledEther;
    }

    function sharesOf(address account) external view returns (uint256) {
        return _shares[account];
    }

    function getPooledEthByShares(uint256 sharesAmount) public view returns (uint256) {
        if (_totalShares == 0) return 0;
        return sharesAmount * totalPooledEther / _totalShares;
    }

    function getSharesByPooledEth(uint256 ethAmount) public view returns (uint256) {
        if (totalPooledEther == 0) return ethAmount; // First deposit
        return ethAmount * _totalShares / totalPooledEther;
    }

    // Called by oracle with new total (includes rewards accrued)
    function _rebase(uint256 newTotalPooledEther) internal {
        emit TokenRebased(
            block.timestamp,
            totalPooledEther,
            _totalShares,
            newTotalPooledEther,
            _totalShares  // Shares unchanged — only ETH amount changes
        );
        totalPooledEther = newTotalPooledEther;
    }
}
```

## wstETH (Non-Rebasing Wrapper)

```solidity
contract WstETH is ERC20 {
    IStETH public immutable stETH;

    // Wrap: deposit stETH → receive wstETH
    function wrap(uint256 stETHAmount) external returns (uint256 wstETHAmount) {
        stETH.transferFrom(msg.sender, address(this), stETHAmount);
        wstETHAmount = stETH.getSharesByPooledEth(stETHAmount);
        _mint(msg.sender, wstETHAmount);
    }

    // Unwrap: deposit wstETH → receive stETH
    function unwrap(uint256 wstETHAmount) external returns (uint256 stETHAmount) {
        _burn(msg.sender, wstETHAmount);
        stETHAmount = stETH.getPooledEthByShares(wstETHAmount);
        stETH.transfer(msg.sender, stETHAmount);
    }

    // wstETH appreciates vs ETH over time
    // stETHPerToken() increases every rebase
    function stEthPerToken() external view returns (uint256) {
        return stETH.getPooledEthByShares(1e18);
    }

    function tokensPerStEth() external view returns (uint256) {
        return stETH.getSharesByPooledEth(1e18);
    }
}
```

## Staking Pool Contract

```solidity
contract LidoStakingPool {
    IStETH public stETH;
    INodeOperatorRegistry public registry;
    IWithdrawalQueue public withdrawalQueue;
    uint256 public bufferedEther; // ETH waiting to be staked

    // User deposits ETH, receives stETH
    function submit(address referral) external payable returns (uint256 shares) {
        require(msg.value > 0, "Zero deposit");

        // Mint stETH shares to user
        shares = stETH.getSharesByPooledEth(msg.value);
        stETH.mintShares(msg.sender, shares);

        bufferedEther += msg.value;

        // When enough accumulated, create validator(s)
        if (bufferedEther >= 32 ether) {
            _depositToBeaconChain();
        }

        emit Submitted(msg.sender, msg.value, referral);
    }

    // Create validator when 32 ETH buffered
    function _depositToBeaconChain() internal {
        // Get next available node operator and their validator keys
        (address operator, bytes memory pubkey, bytes memory withdrawal_credentials, bytes memory signature, bytes32 deposit_data_root)
            = registry.getNextValidatorKeys();

        // Deposit 32 ETH to Ethereum deposit contract
        IDepositContract(BEACON_DEPOSIT_CONTRACT).deposit{value: 32 ether}(
            pubkey, withdrawal_credentials, signature, deposit_data_root
        );

        bufferedEther -= 32 ether;
    }
}
```

## Oracle System (Reporting Validator Balances)

```solidity
contract LidoOracle {
    uint256 constant QUORUM = 5; // Need 5 of 9 oracles to agree
    address[] public oracleMembers;

    mapping(bytes32 => uint256) public reportCount;
    mapping(uint256 => mapping(address => bytes32)) public memberReports; // epoch → oracle → report hash

    struct OracleReport {
        uint256 epoch;
        uint256 totalValidators;
        uint256 totalBalance;     // Sum of all validator balances
        uint256 withdrawalVaultBalance;
        int256 clRewardsDelta;   // Net staking rewards this period
        uint256 elRewardsVaultBalance;
        uint256[] withdrawalFinalizationBatches;
        bool isBunkerMode;
    }

    function submitReport(OracleReport calldata report) external onlyOracleMember {
        bytes32 reportHash = keccak256(abi.encode(report));
        uint256 epoch = report.epoch;

        // Prevent duplicate reports from same oracle
        require(memberReports[epoch][msg.sender] == bytes32(0), "Already reported");
        memberReports[epoch][msg.sender] = reportHash;
        reportCount[reportHash]++;

        if (reportCount[reportHash] >= QUORUM) {
            // Consensus reached — apply the report
            _applyReport(report);
        }
    }

    function _applyReport(OracleReport memory report) internal {
        uint256 newTotalPooledEther = report.totalBalance
            + report.withdrawalVaultBalance
            + report.elRewardsVaultBalance
            + stakingPool.bufferedEther();

        // Apply fees before rebase
        uint256 rewards = newTotalPooledEther - stETH.totalPooledEther();
        if (rewards > 0) {
            _distributeFees(rewards);
        }

        stETH.rebase(newTotalPooledEther);
        withdrawalQueue.finalizeWithdrawals(report.withdrawalFinalizationBatches);
    }
}
```

## Withdrawal Queue

```solidity
contract WithdrawalQueue is ERC721 {
    struct WithdrawalRequest {
        uint256 amountOfStETH;
        uint256 amountOfShares;
        address owner;
        uint256 timestamp;
        bool claimed;
    }

    mapping(uint256 => WithdrawalRequest) public requests;
    uint256 public lastRequestId;
    uint256 public lastFinalizedRequestId;

    // User requests withdrawal
    function requestWithdrawals(
        uint256[] calldata amounts,
        address owner
    ) external returns (uint256[] memory requestIds) {
        requestIds = new uint256[](amounts.length);
        for (uint i = 0; i < amounts.length; i++) {
            // Burns stETH, creates NFT representing queue position
            stETH.transferFrom(msg.sender, address(this), amounts[i]);
            lastRequestId++;
            uint256 shares = stETH.getSharesByPooledEth(amounts[i]);
            requests[lastRequestId] = WithdrawalRequest(amounts[i], shares, owner, block.timestamp, false);
            _mint(owner, lastRequestId); // NFT = proof of queue position
            requestIds[i] = lastRequestId;
        }
    }

    // Oracle finalizes batches when ETH available
    function finalize(uint256 lastRequestIdToFinalize) external onlyOracle {
        lastFinalizedRequestId = lastRequestIdToFinalize;
    }

    // User claims after finalization
    function claimWithdrawals(uint256[] calldata requestIds, uint256[] calldata hints) external {
        for (uint i = 0; i < requestIds.length; i++) {
            uint256 id = requestIds[i];
            require(id <= lastFinalizedRequestId, "Not finalized");
            require(requests[id].owner == msg.sender, "Not owner");
            require(!requests[id].claimed, "Already claimed");

            requests[id].claimed = true;
            _burn(id); // Burn the NFT

            // Send ETH to user
            payable(msg.sender).transfer(requests[id].amountOfStETH);
        }
    }
}
```

## DVT (Distributed Validator Technology)

### Why DVT
- Standard validator: one machine holds the validator key → single point of failure
- DVT: validator key split across N operators using threshold secret sharing
- Requires M-of-N operators to sign (e.g., 4-of-6 Obol cluster)
- No single operator can sign alone → no single point of failure

### Integration (Obol Network)
```solidity
// Lido + Obol: node operators can use DVT clusters instead of single machines
// From smart contract perspective: same interface, different key management
// The validator pubkey maps to a multi-party key shared across cluster members

// Lido's Node Operator Registry records:
struct Operator {
    string name;
    address rewardAddress;
    uint256 totalSigningKeys;
    uint256 usedSigningKeys;
    bool active;
    // Each key is either:
    // - Traditional: single operator's key
    // - DVT: shared key managed by Obol/SSV cluster
}
```

## Fee Distribution
```
Staking rewards (net yield ~3.5% APY)
        │
        ├── 90% → stETH holders (auto-rebases into their balance)
        │
        ├── 5% → Node operators (for running validators)
        │
        └── 5% → Lido DAO treasury
                  └── Used for: protocol development, insurance fund, grants
```

## Rocket Pool Differences
| Feature | Lido | Rocket Pool |
|---------|------|------------|
| Node operators | Curated whitelist | Permissionless (8 ETH + RPL) |
| Liquid token | stETH (rebasing) | rETH (exchange rate) |
| Decentralization | 30+ operators | 3000+ node operators |
| Minimum deposit | Any amount | Any amount |
| Insurance | Socialized | RPL stake per operator |
| Governance | LDO token, Lido DAO | RPL token, oDAO + protocol DAO |
