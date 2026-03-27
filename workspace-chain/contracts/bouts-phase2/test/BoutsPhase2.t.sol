// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {BoutsAgentSBT} from "../src/BoutsAgentSBT.sol";
import {BoutsScoreAggregator} from "../src/BoutsScoreAggregator.sol";

// ─── Mock BoutsJudgeCommit for aggregator tests ───────────────────────────────
contract MockJudgeCommit {
    struct Scores { uint8 claude; uint8 gpt4o; uint8 gemini; bool allRevealed; }
    mapping(bytes32 => Scores) public entries;

    function setScores(bytes32 entryId, uint8 claude, uint8 gpt4o, uint8 gemini, bool revealed) external {
        entries[entryId] = Scores(claude, gpt4o, gemini, revealed);
    }

    function getReveals(bytes32 entryId) external view returns (uint8, uint8, uint8, bool) {
        Scores memory s = entries[entryId];
        return (s.claude, s.gpt4o, s.gemini, s.allRevealed);
    }
}

// =============================================================================
// BoutsAgentSBT Tests
// =============================================================================
contract BoutsAgentSBTTest is Test {
    BoutsAgentSBT public sbt;

    address oracle   = makeAddr("oracle");
    address owner1   = makeAddr("owner1");
    address owner2   = makeAddr("owner2");
    address attacker = makeAddr("attacker");

    string constant AGENT_ID_1 = "550e8400-e29b-41d4-a716-446655440000";
    string constant AGENT_ID_2 = "550e8400-e29b-41d4-a716-446655440001";

    function setUp() public {
        sbt = new BoutsAgentSBT(oracle);
    }

    // ── Constructor ──────────────────────────────────────────────────────────

    function test_Constructor_SetsOracle() public view {
        assertEq(sbt.oracle(), oracle);
    }

    function test_Constructor_RevertsZeroAddress() public {
        vm.expectRevert(BoutsAgentSBT.ZeroAddress.selector);
        new BoutsAgentSBT(address(0));
    }

    // ── Mint ─────────────────────────────────────────────────────────────────

    function test_Mint_Success() public {
        vm.expectEmit(true, true, false, true);
        emit BoutsAgentSBT.AgentMinted(1, AGENT_ID_1, owner1, "contender");

        vm.prank(oracle);
        uint256 tokenId = sbt.mint(owner1, AGENT_ID_1, "contender");

        assertEq(tokenId, 1);
        assertEq(sbt.ownerOf(1), owner1);
        assertEq(sbt.balanceOf(owner1), 1);
        assertEq(sbt.totalSupply(), 1);
        assertTrue(sbt.isMinted(AGENT_ID_1));
        assertEq(sbt.agentIdToTokenId(AGENT_ID_1), 1);
    }

    function test_Mint_ProfileDefaults() public {
        vm.prank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "scrapper");

        BoutsAgentSBT.AgentProfile memory p = sbt.getProfile(1);
        assertEq(p.agentId, AGENT_ID_1);
        assertEq(p.weightClass, "scrapper");
        assertEq(p.owner, owner1);
        assertEq(p.eloRating, 1200);
        assertEq(p.eloPeak, 1200);
        assertEq(p.challengesPlayed, 1);
        assertEq(p.wins, 0);
        assertEq(p.losses, 0);
        assertEq(p.mintedAt, block.timestamp);
    }

    function test_Mint_MultipleAgents() public {
        vm.startPrank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "frontier");
        sbt.mint(owner2, AGENT_ID_2, "scrapper");
        vm.stopPrank();

        assertEq(sbt.totalSupply(), 2);
        assertEq(sbt.ownerOf(1), owner1);
        assertEq(sbt.ownerOf(2), owner2);
    }

    function test_Mint_RevertsNotOracle() public {
        vm.expectRevert(BoutsAgentSBT.OnlyOracle.selector);
        vm.prank(attacker);
        sbt.mint(owner1, AGENT_ID_1, "contender");
    }

    function test_Mint_RevertsZeroAddress() public {
        vm.expectRevert(BoutsAgentSBT.ZeroAddress.selector);
        vm.prank(oracle);
        sbt.mint(address(0), AGENT_ID_1, "contender");
    }

    function test_Mint_RevertsEmptyAgentId() public {
        vm.expectRevert(BoutsAgentSBT.EmptyAgentId.selector);
        vm.prank(oracle);
        sbt.mint(owner1, "", "contender");
    }

    function test_Mint_RevertsDoubleMintt() public {
        vm.startPrank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "contender");

        vm.expectRevert(BoutsAgentSBT.AgentAlreadyMinted.selector);
        sbt.mint(owner2, AGENT_ID_1, "frontier"); // same agentId
        vm.stopPrank();
    }

    // ── Soulbound ────────────────────────────────────────────────────────────

    function test_Locked_ReturnsTrue() public {
        vm.prank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "contender");
        assertTrue(sbt.locked(1));
    }

    function test_TransferFrom_Reverts() public {
        vm.prank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "contender");

        vm.expectRevert(BoutsAgentSBT.Soulbound.selector);
        vm.prank(owner1);
        sbt.transferFrom(owner1, owner2, 1);
    }

    function test_Approve_Reverts() public {
        vm.expectRevert(BoutsAgentSBT.Soulbound.selector);
        vm.prank(owner1);
        sbt.approve(owner2, 1);
    }

    // ── Update Rating ────────────────────────────────────────────────────────

    function test_UpdateRating_Success() public {
        vm.prank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "contender");

        bytes32 commitment = keccak256(abi.encodePacked(AGENT_ID_1, uint16(1350), bytes32("challengeId"), block.timestamp));

        vm.expectEmit(true, false, false, true);
        emit BoutsAgentSBT.RatingUpdated(1, 1200, 1350, commitment);

        vm.prank(oracle);
        sbt.updateRating(1, 1350, 3, 1, 4, commitment);

        BoutsAgentSBT.AgentProfile memory p = sbt.getProfile(1);
        assertEq(p.eloRating, 1350);
        assertEq(p.eloPeak, 1350);
        assertEq(p.wins, 3);
        assertEq(p.losses, 1);
        assertEq(p.challengesPlayed, 4);
        assertEq(p.lastEloCommit, commitment);
    }

    function test_UpdateRating_TracksPeak() public {
        vm.startPrank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "contender");
        sbt.updateRating(1, 1500, 5, 1, 6, bytes32("c1")); // peak = 1500
        sbt.updateRating(1, 1300, 5, 3, 8, bytes32("c2")); // drops to 1300
        vm.stopPrank();

        BoutsAgentSBT.AgentProfile memory p = sbt.getProfile(1);
        assertEq(p.eloRating, 1300);
        assertEq(p.eloPeak, 1500); // peak preserved
    }

    function test_UpdateRating_RevertsInvalidElo_TooLow() public {
        vm.prank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "contender");

        vm.expectRevert(BoutsAgentSBT.InvalidElo.selector);
        vm.prank(oracle);
        sbt.updateRating(1, 399, 0, 1, 1, bytes32(0)); // below 400
    }

    function test_UpdateRating_RevertsInvalidElo_TooHigh() public {
        vm.prank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "contender");

        vm.expectRevert(BoutsAgentSBT.InvalidElo.selector);
        vm.prank(oracle);
        sbt.updateRating(1, 4001, 10, 0, 10, bytes32(0)); // above 4000
    }

    function test_UpdateRating_RevertsTokenNotFound() public {
        vm.expectRevert(BoutsAgentSBT.TokenNotFound.selector);
        vm.prank(oracle);
        sbt.updateRating(999, 1200, 0, 0, 0, bytes32(0));
    }

    // ── GetProfileByAgentId ──────────────────────────────────────────────────

    function test_GetProfileByAgentId() public {
        vm.prank(oracle);
        sbt.mint(owner1, AGENT_ID_1, "frontier");

        (BoutsAgentSBT.AgentProfile memory p, uint256 tokenId) = sbt.getProfileByAgentId(AGENT_ID_1);
        assertEq(tokenId, 1);
        assertEq(p.agentId, AGENT_ID_1);
        assertEq(p.weightClass, "frontier");
    }

    function test_GetProfileByAgentId_RevertsNotFound() public {
        vm.expectRevert(BoutsAgentSBT.TokenNotFound.selector);
        sbt.getProfileByAgentId("nonexistent-uuid");
    }

    // ── Oracle Transfer ──────────────────────────────────────────────────────

    function test_TransferOracle() public {
        address newOracle = makeAddr("newOracle");
        vm.prank(oracle);
        sbt.transferOracle(newOracle);
        assertEq(sbt.oracle(), newOracle);
    }

    function test_TransferOracle_RevertsNotOracle() public {
        vm.expectRevert(BoutsAgentSBT.OnlyOracle.selector);
        vm.prank(attacker);
        sbt.transferOracle(attacker);
    }
}

// =============================================================================
// BoutsScoreAggregator Tests
// =============================================================================
contract BoutsScoreAggregatorTest is Test {
    BoutsScoreAggregator public aggregator;
    MockJudgeCommit public mockJudge;

    address oracle   = makeAddr("oracle");
    address attacker = makeAddr("attacker");

    bytes32 constant ENTRY_1     = bytes32(uint256(0xA1));
    bytes32 constant ENTRY_2     = bytes32(uint256(0xA2));
    bytes32 constant CHALLENGE_1 = bytes32(uint256(0xC1));

    function setUp() public {
        mockJudge  = new MockJudgeCommit();
        aggregator = new BoutsScoreAggregator(oracle, address(mockJudge));
    }

    // ── Constructor ──────────────────────────────────────────────────────────

    function test_Constructor_SetsOracle() public view {
        assertEq(aggregator.oracle(), oracle);
    }

    function test_Constructor_RevertsZeroOracle() public {
        vm.expectRevert(BoutsScoreAggregator.ZeroAddress.selector);
        new BoutsScoreAggregator(address(0), address(mockJudge));
    }

    // ── Rule 1: Consensus (all within 10pts) ─────────────────────────────────

    function test_Aggregate_Consensus_ExactMedian() public {
        // 80, 82, 85 → spread = 5 → consensus → median = 82
        mockJudge.setScores(ENTRY_1, 80, 82, 85, true);

        vm.prank(oracle);
        (uint8 score, BoutsScoreAggregator.AggregationResult result) =
            aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        assertEq(score, 82);
        assertEq(uint8(result), uint8(BoutsScoreAggregator.AggregationResult.Consensus));
    }

    function test_Aggregate_Consensus_IdenticalScores() public {
        // 75, 75, 75 → spread = 0 → consensus → median = 75
        mockJudge.setScores(ENTRY_1, 75, 75, 75, true);

        vm.prank(oracle);
        (uint8 score,) = aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);
        assertEq(score, 75);
    }

    function test_Aggregate_Consensus_ExactlyAtThreshold() public {
        // 70, 75, 80 → spread = 10 → exactly at threshold → consensus → median = 75
        mockJudge.setScores(ENTRY_1, 70, 75, 80, true);

        vm.prank(oracle);
        (uint8 score, BoutsScoreAggregator.AggregationResult result) =
            aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        assertEq(score, 75);
        assertEq(uint8(result), uint8(BoutsScoreAggregator.AggregationResult.Consensus));
    }

    // ── Rule 2: Outlier discarded ─────────────────────────────────────────────

    function test_Aggregate_OutlierDiscarded_HighOutlier() public {
        // 80, 82, 40 → median=80, 40 is >15pts off → discard 40 → avg(80,82)=81
        mockJudge.setScores(ENTRY_1, 80, 82, 40, true);

        vm.prank(oracle);
        (uint8 score, BoutsScoreAggregator.AggregationResult result) =
            aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        assertEq(score, 81);
        assertEq(uint8(result), uint8(BoutsScoreAggregator.AggregationResult.OutlierDiscarded));
    }

    function test_Aggregate_OutlierDiscarded_LowOutlier() public {
        // 50, 100, 52 → median=52, 100 is >15pts off → discard 100 → avg(50,52)=51
        mockJudge.setScores(ENTRY_1, 50, 100, 52, true);

        vm.prank(oracle);
        (uint8 score, BoutsScoreAggregator.AggregationResult result) =
            aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        assertEq(score, 51);
        assertEq(uint8(result), uint8(BoutsScoreAggregator.AggregationResult.OutlierDiscarded));
    }

    function test_Aggregate_OutlierDiscarded_FirstProvider() public {
        // claude=20, gpt4o=80, gemini=82 → median=80, claude >15pts off → discard → avg(80,82)=81
        mockJudge.setScores(ENTRY_1, 20, 80, 82, true);

        vm.prank(oracle);
        (uint8 score,) = aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);
        assertEq(score, 81);
    }

    // ── Rule 3: All disagree → disputed ──────────────────────────────────────

    function test_Aggregate_Disputed() public {
        // 30, 60, 90 → spread=60, all far apart → disputed
        mockJudge.setScores(ENTRY_1, 30, 60, 90, true);

        vm.expectEmit(true, true, false, true);
        emit BoutsScoreAggregator.DisputeFlagged(ENTRY_1, CHALLENGE_1, 30, 60, 90);

        vm.prank(oracle);
        (uint8 score, BoutsScoreAggregator.AggregationResult result) =
            aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        assertEq(score, 0); // blocked
        assertEq(uint8(result), uint8(BoutsScoreAggregator.AggregationResult.Disputed));
        assertTrue(aggregator.isDisputed(ENTRY_1));
    }

    // ── Reverts ──────────────────────────────────────────────────────────────

    function test_Aggregate_RevertsNotOracle() public {
        mockJudge.setScores(ENTRY_1, 80, 82, 84, true);

        vm.expectRevert(BoutsScoreAggregator.OnlyOracle.selector);
        vm.prank(attacker);
        aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);
    }

    function test_Aggregate_RevertsNotAllRevealed() public {
        mockJudge.setScores(ENTRY_1, 80, 82, 84, false); // not revealed

        vm.expectRevert(BoutsScoreAggregator.ScoresNotAllRevealed.selector);
        vm.prank(oracle);
        aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);
    }

    function test_Aggregate_RevertsAlreadyAggregated() public {
        mockJudge.setScores(ENTRY_1, 80, 82, 84, true);

        vm.startPrank(oracle);
        aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        vm.expectRevert(BoutsScoreAggregator.AlreadyAggregated.selector);
        aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);
        vm.stopPrank();
    }

    // ── Resolve dispute ──────────────────────────────────────────────────────

    function test_ResolveDispute_Success() public {
        mockJudge.setScores(ENTRY_1, 30, 60, 90, true);
        vm.prank(oracle);
        aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        vm.prank(oracle);
        aggregator.resolveDispute(ENTRY_1, 60, "Manual review: used average of Claude and GPT-4o");

        assertEq(aggregator.getFinalScore(ENTRY_1), 60);
        assertFalse(aggregator.isDisputed(ENTRY_1));
    }

    function test_ResolveDispute_RevertsNotDisputed() public {
        mockJudge.setScores(ENTRY_1, 80, 82, 84, true);
        vm.prank(oracle);
        aggregator.aggregateScores(ENTRY_1, CHALLENGE_1); // consensus, not disputed

        vm.expectRevert(BoutsScoreAggregator.NotDisputed.selector);
        vm.prank(oracle);
        aggregator.resolveDispute(ENTRY_1, 80, "not disputed");
    }

    // ── Multiple entries isolation ────────────────────────────────────────────

    function test_MultipleEntries_Isolated() public {
        mockJudge.setScores(ENTRY_1, 80, 82, 84, true); // consensus
        mockJudge.setScores(ENTRY_2, 30, 60, 90, true); // disputed

        vm.startPrank(oracle);
        (uint8 score1,) = aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);
        (uint8 score2,) = aggregator.aggregateScores(ENTRY_2, CHALLENGE_1);
        vm.stopPrank();

        assertEq(score1, 82);
        assertEq(score2, 0);
        assertFalse(aggregator.isDisputed(ENTRY_1));
        assertTrue(aggregator.isDisputed(ENTRY_2));
    }

    // ── Fuzz ─────────────────────────────────────────────────────────────────

    function testFuzz_Aggregate_NeverReverts(uint8 a, uint8 b, uint8 c) public {
        vm.assume(a >= 10 && a <= 100);
        vm.assume(b >= 10 && b <= 100);
        vm.assume(c >= 10 && c <= 100);

        mockJudge.setScores(ENTRY_1, a, b, c, true);

        vm.prank(oracle);
        (uint8 score, BoutsScoreAggregator.AggregationResult result) =
            aggregator.aggregateScores(ENTRY_1, CHALLENGE_1);

        // Score is always valid or 0 (disputed)
        assertTrue(score == 0 || (score >= 10 && score <= 100));
        // If disputed, score must be 0
        if (result == BoutsScoreAggregator.AggregationResult.Disputed) {
            assertEq(score, 0);
        }
    }
}
