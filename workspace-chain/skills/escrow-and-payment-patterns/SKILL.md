# Escrow & Payment Patterns

## Simple Escrow
```solidity
contract Escrow {
    IERC20 public immutable token;
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public amount;
    bool public released;

    enum State { AWAITING_DEPOSIT, AWAITING_DELIVERY, COMPLETE, REFUNDED }
    State public state;

    function deposit(uint256 _amount) external {
        require(state == State.AWAITING_DEPOSIT);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        amount = _amount;
        depositor = msg.sender;
        state = State.AWAITING_DELIVERY;
    }

    function release() external {
        require(msg.sender == arbiter || msg.sender == depositor);
        require(state == State.AWAITING_DELIVERY);
        state = State.COMPLETE;
        token.safeTransfer(beneficiary, amount);
    }

    function refund() external {
        require(msg.sender == arbiter || msg.sender == beneficiary);
        require(state == State.AWAITING_DELIVERY);
        state = State.REFUNDED;
        token.safeTransfer(depositor, amount);
    }
}
```

## Prize Pool Pattern (Agent Sparta)
```solidity
contract ChallengePool {
    IERC20 public immutable usdc;

    struct Challenge {
        uint256 entryFee;
        uint256 totalPool;
        uint256 deadline;
        uint256 resolutionDeadline;
        State state;
        mapping(address => bool) entered;
        address[] participants;
        mapping(address => uint256) claimed;
    }

    enum State { OPEN, LOCKED, RESOLVED, CANCELLED }

    mapping(bytes32 => Challenge) public challenges;

    uint256 public constant PLATFORM_RAKE_BPS = 500; // 5%
    uint256 public constant CLAIM_WINDOW = 30 days;
    address public treasury;
    address public operator; // Can resolve challenges

    // --- ENTRY ---
    function enter(bytes32 challengeId) external {
        Challenge storage c = challenges[challengeId];
        require(c.state == State.OPEN, "Not open");
        require(block.timestamp < c.deadline, "Deadline passed");
        require(!c.entered[msg.sender], "Already entered");

        usdc.safeTransferFrom(msg.sender, address(this), c.entryFee);
        c.entered[msg.sender] = true;
        c.participants.push(msg.sender);
        c.totalPool += c.entryFee;
    }

    // --- RESOLUTION ---
    // Winners array + their share percentages (must sum to 10000 bps)
    function resolve(
        bytes32 challengeId,
        address[] calldata winners,
        uint256[] calldata sharesBps  // e.g., [6000, 3000, 1000] for 60/30/10
    ) external onlyOperator {
        Challenge storage c = challenges[challengeId];
        require(c.state == State.LOCKED, "Not locked");
        require(winners.length == sharesBps.length, "Length mismatch");

        uint256 totalBps;
        for (uint i = 0; i < sharesBps.length; i++) totalBps += sharesBps[i];
        require(totalBps == 10_000, "Shares must sum to 100%");

        // Take platform rake
        uint256 rake = (c.totalPool * PLATFORM_RAKE_BPS) / 10_000;
        usdc.safeTransfer(treasury, rake);
        uint256 prizePool = c.totalPool - rake;

        // Record winner shares (pull pattern — they claim later)
        for (uint i = 0; i < winners.length; i++) {
            c.claimed[winners[i]] = (prizePool * sharesBps[i]) / 10_000;
        }

        c.state = State.RESOLVED;
    }

    // --- CLAIM (Pull Pattern) ---
    function claim(bytes32 challengeId) external {
        Challenge storage c = challenges[challengeId];
        require(c.state == State.RESOLVED, "Not resolved");
        require(block.timestamp < c.resolutionDeadline + CLAIM_WINDOW, "Claim window expired");

        uint256 payout = c.claimed[msg.sender];
        require(payout > 0, "Nothing to claim");

        c.claimed[msg.sender] = 0; // Effects before interaction
        usdc.safeTransfer(msg.sender, payout); // Interaction last
    }

    // --- UNCLAIMED (Treasury sweep after claim window) ---
    function sweepUnclaimed(bytes32 challengeId) external {
        Challenge storage c = challenges[challengeId];
        require(c.state == State.RESOLVED);
        require(block.timestamp > c.resolutionDeadline + CLAIM_WINDOW, "Claim window active");
        uint256 remaining = usdc.balanceOf(address(this)); // Simplified
        usdc.safeTransfer(treasury, remaining);
    }

    // --- CANCELLATION (Full refunds) ---
    function cancel(bytes32 challengeId) external onlyOperator {
        Challenge storage c = challenges[challengeId];
        require(c.state == State.OPEN || c.state == State.LOCKED);
        c.state = State.CANCELLED;
        // Refunds via pull pattern
        for (uint i = 0; i < c.participants.length; i++) {
            c.claimed[c.participants[i]] = c.entryFee;
        }
    }
}
```

## Payment Splitting
```solidity
// OpenZeppelin PaymentSplitter (push model)
// Better to use pull pattern for large recipient sets

contract PullSplitter {
    mapping(address => uint256) public shares;
    mapping(address => uint256) public released;
    uint256 public totalShares;
    uint256 public totalReleased;

    IERC20 public token;

    constructor(address[] memory payees, uint256[] memory _shares) {
        for (uint i = 0; i < payees.length; i++) {
            shares[payees[i]] = _shares[i];
            totalShares += _shares[i];
        }
    }

    function release(address account) external {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased;
        uint256 payment = (totalReceived * shares[account] / totalShares) - released[account];
        require(payment > 0, "Nothing due");
        released[account] += payment;
        totalReleased += payment;
        token.safeTransfer(account, payment);
    }
}
```

## Time-Locked Escrow
```solidity
contract TimeLocked {
    mapping(address => uint256) public lockTime;
    mapping(address => uint256) public balance;

    function deposit(uint256 lockPeriod) external payable {
        balance[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + lockPeriod;
    }

    function withdraw() external {
        require(block.timestamp >= lockTime[msg.sender], "Still locked");
        uint256 amount = balance[msg.sender];
        balance[msg.sender] = 0;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok);
    }
}
```

## Key Patterns
1. **Pull over Push**: Never iterate over recipients to push payments. Let them claim.
2. **CEI in claims**: Zero out balance BEFORE transfer (prevents reentrancy).
3. **Separate accounting from balances**: Track `claimed` separately from `address(this).balance` — forced ETH via selfdestruct can inflate balance.
4. **Claim windows**: Define when unclaimed funds expire → treasury. Prevents permanent lock.
5. **SafeERC20**: Never bare `token.transfer()` — use OpenZeppelin SafeERC20.
