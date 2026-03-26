# DAO & Governance

## OpenZeppelin Governor

### Core Components
```solidity
contract PredictionMarketDAO is
    Governor,
    GovernorSettings,
    GovernorCompatibilityBravo,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    constructor(IVotes _token, TimelockController _timelock)
        Governor("PredictionMarketDAO")
        GovernorSettings(
            7200,    // votingDelay: 1 day in blocks (~12s/block)
            50400,   // votingPeriod: 7 days
            100e18   // proposalThreshold: 100 governance tokens to propose
        )
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)  // 4% of total supply for quorum
        GovernorTimelockControl(_timelock)
    {}
}
```

### Proposal Lifecycle
```
1. propose(targets, values, calldatas, description)
     → ProposalCreated event
     → proposalId = hash of all proposal data
     → State: Pending

2. Wait votingDelay (e.g., 1 day)
     → State: Active

3. castVote(proposalId, support)  // 0=Against, 1=For, 2=Abstain
   castVoteWithReason(proposalId, support, reason)
   castVoteBySig(proposalId, support, v, r, s)  // Gasless voting
     → VoteCast event

4. Wait votingPeriod (e.g., 7 days)
     → If quorum met + majority For → State: Succeeded
     → If quorum not met or majority Against → State: Defeated

5. queue(targets, values, calldatas, descriptionHash)
     → State: Queued (in Timelock)

6. Wait timelockDelay (e.g., 48 hours)

7. execute(targets, values, calldatas, descriptionHash)
     → ProposalExecuted event
     → State: Executed
```

### Voting Strategies
- **Token-weighted**: 1 token = 1 vote. Plutocracy risk.
- **Quadratic voting**: Cost = votes². 4 votes costs 16 tokens. Reduces whale dominance.
- **Conviction voting**: Vote weight increases over time held. Rewards long-term alignment.
- **Snapshot (off-chain)**: Vote off-chain, execute on-chain via multisig or optimistic execution.

### Delegation
```solidity
// Token holders must delegate to themselves to vote
// (Prevents voting with newly acquired tokens in the same block as purchase)
governanceToken.delegate(msg.sender);  // Self-delegate
governanceToken.delegate(trustedRepresentative);  // Delegate to someone else

// Check current delegate
governanceToken.delegates(holderAddress);

// Check voting power at a specific block
governanceToken.getPastVotes(holderAddress, proposalSnapshotBlock);
```

### Timelock Controller
```solidity
TimelockController timelock = new TimelockController(
    172800,         // minDelay: 48 hours (seconds)
    proposers,      // Can queue proposals (should be Governor contract)
    executors,      // Can execute after delay (address(0) = anyone can execute)
    address(0)      // Admin: set to 0 after setup (irrevocable)
);

// Grant Governor the PROPOSER_ROLE
timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
// Renounce deployer's admin role after setup
timelock.renounceRole(timelock.TIMELOCK_ADMIN_ROLE(), deployer);
```

## Governance Attack Vectors

### Flash Loan Governance Attack
Attack: Borrow 51% of governance tokens, vote on proposal, return tokens — all in one tx.
Prevention: **Snapshot voting power at proposal creation block**, not at vote time.
OpenZeppelin Governor does this automatically via `getPastVotes()`.

### Low Quorum Attack
Attack: Pass proposals when voter participation is low (holiday periods, low-activity chains).
Prevention: High quorum requirement (4-10% of total supply), off-chain voting alerts.

### Governance Griefing
Attack: Spam proposals to exhaust voter attention and treasury (proposal thresholds are too low).
Prevention: High proposal threshold (must own/delegate significant tokens), proposal deposit.

### Long Timelock Bypass (Emergency)
Problem: 48-hour timelock means you can't respond to exploits quickly.
Solution: Guardian multisig with emergency pause power. Separate from governance for speed.

## Minimal Viable Governance (For Early Protocols)

For small protocols (<$1M TVL), full on-chain governance is overkill:
```
Phase 1: Multisig (3/5 Safe) — fast decisions, trusted team
Phase 2: Add timelock — community gets exit window
Phase 3: Add governance token voting — progressive decentralization
Phase 4: Full DAO — governance token holders control everything
```

**Don't decentralize before you're ready.** Premature decentralization creates gridlock and governance attacks.

## Snapshot (Off-Chain Voting)
Most DAOs use Snapshot for off-chain voting + multisig for execution:
1. Snapshot vote: no gas, EIP-712 signed messages, any token/NFT/strategy
2. Results tallied off-chain
3. Multisig executes if vote passes (trust assumption: multisig acts honestly)
4. Optimistic execution: propose on-chain, execute if no veto within N days

For prediction market governance: Snapshot is appropriate for parameter changes (fees, oracle selection). On-chain governor for critical upgrades.
