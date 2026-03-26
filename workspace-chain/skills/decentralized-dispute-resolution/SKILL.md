# Decentralized Dispute Resolution

## The Core Problem
Who decides when the answer is ambiguous? Smart contracts can execute objectively, but "who won?" for a complex challenge or prediction requires human judgment. Decentralized dispute resolution removes the trusted third party.

## Schelling Point Mechanism (Kleros)

The key insight: if everyone expects others to vote honestly, honest voting is the Nash equilibrium.

```
Setup:
- 5 jurors randomly selected from staked PNK holders
- Each juror must vote: A wins, B wins, or Invalid
- Majority decision wins
- Minority voters LOSE their stake (slashing)
- Majority voters GAIN from losing side's stake

Game theory:
- If you think others will vote honestly → vote honestly (matches majority)
- If you think others will vote dishonestly → still vote honestly (because they'll vote what they think is true, which is honest)
- Nash equilibrium = everyone votes according to true belief
```

```solidity
contract Kleros {
    struct Dispute {
        address arbitrated;     // Contract that requested arbitration
        uint256 choices;        // Number of possible rulings
        uint256 createdAt;
        uint256 ruled;          // 0 = not ruled, >0 = ruling
        Round[] rounds;
    }

    struct Round {
        uint256 jurorCount;
        address[] jurors;
        mapping(address => uint256) votes;   // juror → choice
        mapping(uint256 => uint256) voteCounts;
        uint256 totalStaked;
        bool closed;
    }

    // Request arbitration (from prediction market, escrow, etc.)
    function createDispute(uint256 choices, bytes calldata extraData)
        external payable returns (uint256 disputeId)
    {
        require(msg.value >= arbitrationCost(extraData), "Insufficient arbitration fees");
        disputeId = disputes.length;
        disputes.push();
        Dispute storage d = disputes[disputeId];
        d.arbitrated = msg.sender;
        d.choices = choices;
        d.createdAt = block.timestamp;
        // Select jurors randomly from staked pool
        _drawJurors(disputeId, extraData);
    }

    // Juror submits vote (during commit phase — hidden)
    function castVote(uint256 disputeId, uint256 choice, uint256 salt) external {
        // Commit-reveal: submit hash(choice, salt) first
        // Prevents jurors from copying each other's votes
        commitments[disputeId][msg.sender] = keccak256(abi.encode(choice, salt));
    }

    // Reveal phase
    function revealVote(uint256 disputeId, uint256 choice, uint256 salt) external {
        require(keccak256(abi.encode(choice, salt)) == commitments[disputeId][msg.sender]);
        Round storage round = disputes[disputeId].rounds[currentRound(disputeId)];
        round.votes[msg.sender] = choice;
        round.voteCounts[choice]++;
    }

    // Execute ruling after vote period
    function executeRuling(uint256 disputeId) external {
        uint256 ruling = _getMajorityVote(disputeId);
        disputes[disputeId].ruled = ruling;

        // Slash minority jurors, reward majority
        _redistributeStakes(disputeId, ruling);

        // Notify the requesting contract
        IArbitrable(disputes[disputeId].arbitrated).rule(disputeId, ruling);
    }
}
```

## Appeal System (Escalation)

```
Round 1: 3 jurors, $100 stake each → decision
  If losing party appeals: pay higher fee
Round 2: 7 jurors, $500 stake each (2× juror count each round)
Round 3: 15 jurors, $2000 stake each
... (exponentially expensive to keep appealing)
```

```solidity
function appeal(uint256 disputeId) external payable {
    require(msg.value >= appealCost(disputeId), "Insufficient fee");
    require(disputes[disputeId].ruled > 0, "Ruling not yet made");

    // Start new round with doubled juror count
    Round memory prevRound = disputes[disputeId].rounds[disputes[disputeId].rounds.length - 1];
    disputes[disputeId].rounds.push();
    _drawJurors(disputeId, prevRound.jurorCount * 2);

    // Reset ruled
    disputes[disputeId].ruled = 0;
}
```

## Reality.eth Escalation Game

```
1. Question asked on-chain with bond requirement
2. Answerer posts answer + bond (e.g., $50)
3. Wait period (e.g., 24 hours)
4. If no challenge → answer is accepted, answerer gets bond back
5. If challenged → challenger posts 2x bond ($100), replaces answer
6. Counter-challenge: 2x again ($200)
7. Stakes double each round
8. If escalated past threshold → Kleros arbitration (or multisig)
```

```solidity
contract Reality {
    struct Question {
        bytes32 questionId;
        address arbitrator;     // Kleros or multisig
        uint32 timeout;
        uint256 openingTimestamp;
        bytes32 contentHash;
        bytes32 bestAnswer;
        uint256 bond;           // Current bond size
        uint256 finalizationTimestamp;
    }

    function submitAnswer(bytes32 questionId, bytes32 answer, uint256 maxPrevious) external payable {
        Question storage q = questions[questionId];

        // Must post 2x current bond
        require(msg.value >= q.bond * 2, "Insufficient bond");

        q.bestAnswer = answer;
        q.bond = msg.value;
        q.finalizationTimestamp = block.timestamp + q.timeout;

        // Return previous answerer's bond
        // Previous answerer loses if they were wrong, wins if finalized
    }

    function claimWinnings(bytes32 questionId, bytes32[] calldata history) external {
        require(block.timestamp > questions[questionId].finalizationTimestamp, "Not finalized");
        // Distribute bonds to those who answered correctly
    }
}
```

## UMA Optimistic Oracle (Deep Dive)

```solidity
contract OptimisticOracleV3 {
    struct Assertion {
        address asserter;
        address callbackRecipient;
        address escalationManager;
        uint256 bond;
        uint64 expirationTime;
        bool settled;
        bool settlementResolution; // true = assertion correct
        bytes claim;               // What is being asserted
    }

    // Proposer asserts a claim (e.g., "YES won the market")
    function assertTruth(
        bytes calldata claim,
        address asserter,
        address callbackRecipient,
        address escalationManager,
        uint64 liveness,           // Challenge window (e.g., 2 hours)
        IERC20 currency,
        uint256 bond,
        bytes32 identifier,
        bytes32 domainId
    ) external returns (bytes32 assertionId) {
        // Transfer bond from asserter
        currency.safeTransferFrom(asserter, address(this), bond);

        assertionId = keccak256(abi.encode(block.timestamp, msg.sender, nonce++));
        assertions[assertionId] = Assertion({
            asserter: asserter,
            callbackRecipient: callbackRecipient,
            escalationManager: escalationManager,
            bond: bond,
            expirationTime: uint64(block.timestamp + liveness),
            settled: false,
            settlementResolution: false,
            claim: claim
        });
    }

    // Dispute (must post equal bond)
    function disputeAssertion(bytes32 assertionId, address disputer) external {
        Assertion storage a = assertions[assertionId];
        require(block.timestamp < a.expirationTime, "Assertion expired");

        bondCurrency.safeTransferFrom(disputer, address(this), a.bond);

        // Escalate to UMA DVM for token holder vote
        _requestDvmVote(assertionId, a.claim);
    }

    // If not disputed within liveness period, settle in asserter's favor
    function settleAssertion(bytes32 assertionId) external {
        Assertion storage a = assertions[assertionId];
        require(!a.settled);

        if (a.disputeHash == bytes32(0)) {
            // No dispute — asserter wins, gets bond back
            require(block.timestamp >= a.expirationTime, "Not expired");
            a.settlementResolution = true;
            bondCurrency.safeTransfer(a.asserter, a.bond);
        }

        a.settled = true;

        // Notify callback recipient (the prediction market)
        IOptimisticOracleV3CallbackRecipient(a.callbackRecipient)
            .assertionResolvedCallback(assertionId, a.settlementResolution);
    }
}
```

## Agent Sparta Dispute Resolution Design

### Recommended Architecture
```
Challenge Judge = Anthropic API (fast, centralized, for MVP)
     │
     ├── If result contested by participant:
     │    └── Human Review Panel (3 of 5 committee vote)
     │         │
     │         └── If still contested (>$1K prize):
     │              └── Reality.eth escalation → Kleros subcourt
     │
     └── For large prizes (>$10K): UMA Optimistic Oracle from start

Smart contract enforces:
- 48-hour dispute window after result announced
- Dispute requires staking 10% of prize pool (skin in the game)
- If dispute succeeds: stake returned + share of protocol fee
- If dispute fails: stake burned (prevents frivolous disputes)
```

```solidity
contract SpartaDispute {
    uint256 constant DISPUTE_WINDOW = 48 hours;
    uint256 constant DISPUTE_STAKE_BPS = 1000; // 10% of prize

    function disputeResult(bytes32 challengeId) external payable {
        Challenge storage c = challenges[challengeId];
        require(c.state == State.RESOLVED, "Not resolved");
        require(block.timestamp < c.resolvedAt + DISPUTE_WINDOW, "Window closed");

        uint256 requiredStake = c.totalPool * DISPUTE_STAKE_BPS / 10_000;
        require(msg.value >= requiredStake, "Insufficient dispute stake");

        // Mark as disputed, pause payouts
        c.state = State.DISPUTED;
        c.disputer = msg.sender;
        c.disputeStake = msg.value;

        // Escalate to committee or oracle
        _initiateReview(challengeId);
    }
}
```
