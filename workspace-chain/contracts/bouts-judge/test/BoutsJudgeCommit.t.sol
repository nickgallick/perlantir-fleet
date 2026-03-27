// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {BoutsJudgeCommit} from "../src/BoutsJudgeCommit.sol";

contract BoutsJudgeCommitTest is Test {
    BoutsJudgeCommit public judge;

    address public oracle   = makeAddr("oracle");
    address public attacker = makeAddr("attacker");

    // Test fixtures
    bytes32 constant ENTRY_ID   = bytes32(uint256(0xABCD1234));
    bytes32 constant ENTRY_ID_2 = bytes32(uint256(0xDEADBEEF));
    uint8   constant SCORE_CLAUDE  = 84;  // 8.4 × 10
    uint8   constant SCORE_GPT4O   = 79;  // 7.9 × 10
    uint8   constant SCORE_GEMINI  = 81;  // 8.1 × 10
    bytes32 constant SALT_CLAUDE  = keccak256("salt_claude");
    bytes32 constant SALT_GPT4O   = keccak256("salt_gpt4o");
    bytes32 constant SALT_GEMINI  = keccak256("salt_gemini");

    function setUp() public {
        judge = new BoutsJudgeCommit(oracle);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    function _commitment(bytes32 entryId, string memory provider, uint8 score, bytes32 salt)
        internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(entryId, provider, score, salt));
    }

    function _commitAll(bytes32 entryId) internal {
        vm.startPrank(oracle);
        judge.commit(entryId, "claude", _commitment(entryId, "claude", SCORE_CLAUDE, SALT_CLAUDE));
        judge.commit(entryId, "gpt4o",  _commitment(entryId, "gpt4o",  SCORE_GPT4O,  SALT_GPT4O));
        judge.commit(entryId, "gemini", _commitment(entryId, "gemini", SCORE_GEMINI, SALT_GEMINI));
        vm.stopPrank();
    }

    function _revealAll(bytes32 entryId) internal {
        vm.startPrank(oracle);
        judge.reveal(entryId, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        judge.reveal(entryId, "gpt4o",  SCORE_GPT4O,  SALT_GPT4O);
        judge.reveal(entryId, "gemini", SCORE_GEMINI, SALT_GEMINI);
        vm.stopPrank();
    }

    // =========================================================================
    // Constructor
    // =========================================================================

    function test_Constructor_SetsOracle() public view {
        assertEq(judge.oracle(), oracle);
    }

    function test_Constructor_RevertsZeroAddress() public {
        vm.expectRevert(BoutsJudgeCommit.ZeroAddress.selector);
        new BoutsJudgeCommit(address(0));
    }

    // =========================================================================
    // Commit — happy path
    // =========================================================================

    function test_Commit_Claude() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.expectEmit(true, false, false, true);
        emit BoutsJudgeCommit.Committed(ENTRY_ID, "claude", commitment, block.timestamp);

        vm.prank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        assertEq(judge.commitments(ENTRY_ID, "claude"), commitment);
        assertEq(judge.commitTimestamps(ENTRY_ID, "claude"), block.timestamp);
    }

    function test_Commit_AllThreeProviders() public {
        _commitAll(ENTRY_ID);

        assertNotEq(judge.commitments(ENTRY_ID, "claude"), bytes32(0));
        assertNotEq(judge.commitments(ENTRY_ID, "gpt4o"),  bytes32(0));
        assertNotEq(judge.commitments(ENTRY_ID, "gemini"), bytes32(0));
    }

    // =========================================================================
    // Commit — access control
    // =========================================================================

    function test_Commit_RevertsIfNotOracle() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.expectRevert(BoutsJudgeCommit.OnlyOracle.selector);
        vm.prank(attacker);
        judge.commit(ENTRY_ID, "claude", commitment);
    }

    function test_Commit_RevertsInvalidProvider() public {
        vm.expectRevert(BoutsJudgeCommit.InvalidProvider.selector);
        vm.prank(oracle);
        judge.commit(ENTRY_ID, "gpt5", keccak256("whatever"));
    }

    function test_Commit_RevertsDoubleCommit() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        vm.expectRevert(BoutsJudgeCommit.AlreadyCommitted.selector);
        judge.commit(ENTRY_ID, "claude", commitment);
        vm.stopPrank();
    }

    // =========================================================================
    // Reveal — happy path
    // =========================================================================

    function test_Reveal_Claude() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        vm.expectEmit(true, false, false, true);
        emit BoutsJudgeCommit.Revealed(ENTRY_ID, "claude", SCORE_CLAUDE, block.timestamp);

        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        vm.stopPrank();

        assertEq(judge.reveals(ENTRY_ID, "claude"), SCORE_CLAUDE);
        assertTrue(judge.isRevealed(ENTRY_ID, "claude"));
    }

    function test_Reveal_AllThreeProviders() public {
        _commitAll(ENTRY_ID);
        _revealAll(ENTRY_ID);

        (uint8 claude, uint8 gpt4o, uint8 gemini, bool allRevealed) = judge.getReveals(ENTRY_ID);

        assertEq(claude, SCORE_CLAUDE);
        assertEq(gpt4o,  SCORE_GPT4O);
        assertEq(gemini, SCORE_GEMINI);
        assertTrue(allRevealed);
    }

    function test_Reveal_MinScore() public {
        uint8 minScore = 10; // 1.0 × 10
        bytes32 salt = keccak256("min_salt");
        bytes32 commitment = _commitment(ENTRY_ID, "claude", minScore, salt);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);
        judge.reveal(ENTRY_ID, "claude", minScore, salt);
        vm.stopPrank();

        assertEq(judge.reveals(ENTRY_ID, "claude"), minScore);
    }

    function test_Reveal_MaxScore() public {
        uint8 maxScore = 100; // 10.0 × 10
        bytes32 salt = keccak256("max_salt");
        bytes32 commitment = _commitment(ENTRY_ID, "claude", maxScore, salt);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);
        judge.reveal(ENTRY_ID, "claude", maxScore, salt);
        vm.stopPrank();

        assertEq(judge.reveals(ENTRY_ID, "claude"), maxScore);
    }

    // =========================================================================
    // Reveal — access control & validation
    // =========================================================================

    function test_Reveal_RevertsIfNotOracle() public {
        _commitAll(ENTRY_ID);

        vm.expectRevert(BoutsJudgeCommit.OnlyOracle.selector);
        vm.prank(attacker);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
    }

    function test_Reveal_RevertsIfNotCommitted() public {
        vm.expectRevert(BoutsJudgeCommit.NotCommitted.selector);
        vm.prank(oracle);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
    }

    function test_Reveal_RevertsDoubleReveal() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.expectRevert(BoutsJudgeCommit.AlreadyRevealed.selector);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        vm.stopPrank();
    }

    function test_Reveal_RevertsWrongScore() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        vm.expectRevert(BoutsJudgeCommit.InvalidReveal.selector);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE + 1, SALT_CLAUDE); // wrong score
        vm.stopPrank();
    }

    function test_Reveal_RevertsWrongSalt() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        vm.expectRevert(BoutsJudgeCommit.InvalidReveal.selector);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, keccak256("wrong_salt")); // wrong salt
        vm.stopPrank();
    }

    function test_Reveal_RevertsWrongProvider() public {
        // Commit for claude, try to reveal as gpt4o — different commitment hash
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);
        // Also commit gpt4o with the same commitment hash (wrong — different provider)
        judge.commit(ENTRY_ID, "gpt4o", commitment);

        // Reveal gpt4o with claude's score/salt — will fail because "gpt4o" != "claude" in hash
        vm.expectRevert(BoutsJudgeCommit.InvalidReveal.selector);
        judge.reveal(ENTRY_ID, "gpt4o", SCORE_CLAUDE, SALT_CLAUDE);
        vm.stopPrank();
    }

    function test_Reveal_RevertsScoreTooLow() public {
        uint8 badScore = 9; // below minimum 10
        bytes32 salt = keccak256("salt");
        bytes32 commitment = _commitment(ENTRY_ID, "claude", badScore, salt);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        vm.expectRevert(BoutsJudgeCommit.InvalidScore.selector);
        judge.reveal(ENTRY_ID, "claude", badScore, salt);
        vm.stopPrank();
    }

    function test_Reveal_RevertsScoreTooHigh() public {
        uint8 badScore = 101; // above maximum 100
        bytes32 salt = keccak256("salt");
        // Note: score 101 overflows uint8 range check differently,
        // but the contract checks score < 10 || score > 100
        // uint8 can't hold 256, so test with value > 100
        // In Solidity, uint8(101) is valid. Let's verify the guard works.
        bytes32 commitment = keccak256(abi.encodePacked(ENTRY_ID, "claude", badScore, salt));

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        vm.expectRevert(BoutsJudgeCommit.InvalidScore.selector);
        judge.reveal(ENTRY_ID, "claude", badScore, salt);
        vm.stopPrank();
    }

    // =========================================================================
    // getReveals — partial state
    // =========================================================================

    function test_GetReveals_NotAllRevealed() public {
        _commitAll(ENTRY_ID);

        vm.startPrank(oracle);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        // gpt4o and gemini not yet revealed
        vm.stopPrank();

        (uint8 claude, uint8 gpt4o, uint8 gemini, bool allRevealed) = judge.getReveals(ENTRY_ID);

        assertEq(claude, SCORE_CLAUDE);
        assertEq(gpt4o,  0); // not revealed
        assertEq(gemini, 0); // not revealed
        assertFalse(allRevealed);
    }

    // =========================================================================
    // getProviderStatus
    // =========================================================================

    function test_GetProviderStatus_AfterCommit() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        vm.prank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        (bool committed, bool revealed, uint8 score, uint256 committedAt, uint256 revealedAt) =
            judge.getProviderStatus(ENTRY_ID, "claude");

        assertTrue(committed);
        assertFalse(revealed);
        assertEq(score, 0);
        assertEq(committedAt, block.timestamp);
        assertEq(revealedAt, 0);
    }

    function test_GetProviderStatus_AfterReveal() public {
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);
        judge.reveal(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        vm.stopPrank();

        (bool committed, bool revealed, uint8 score,,) =
            judge.getProviderStatus(ENTRY_ID, "claude");

        assertTrue(committed);
        assertTrue(revealed);
        assertEq(score, SCORE_CLAUDE);
    }

    // =========================================================================
    // computeCommitment — utility view
    // =========================================================================

    function test_ComputeCommitment_MatchesExpected() public view {
        bytes32 result = judge.computeCommitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        bytes32 expected = keccak256(abi.encodePacked(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE));
        assertEq(result, expected);
    }

    // =========================================================================
    // Multiple entries — isolation
    // =========================================================================

    function test_MultipleEntries_Isolated() public {
        // Commit for entry 1
        bytes32 c1 = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);
        // Commit for entry 2 with different score
        bytes32 c2 = _commitment(ENTRY_ID_2, "claude", 90, keccak256("other_salt"));

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID,   "claude", c1);
        judge.commit(ENTRY_ID_2, "claude", c2);
        judge.reveal(ENTRY_ID,   "claude", SCORE_CLAUDE, SALT_CLAUDE);
        judge.reveal(ENTRY_ID_2, "claude", 90, keccak256("other_salt"));
        vm.stopPrank();

        assertEq(judge.reveals(ENTRY_ID,   "claude"), SCORE_CLAUDE);
        assertEq(judge.reveals(ENTRY_ID_2, "claude"), 90);
    }

    // =========================================================================
    // Oracle transfer
    // =========================================================================

    function test_TransferOracle() public {
        address newOracle = makeAddr("newOracle");

        vm.expectEmit(true, true, false, false);
        emit BoutsJudgeCommit.OracleTransferred(oracle, newOracle);

        vm.prank(oracle);
        judge.transferOracle(newOracle);

        assertEq(judge.oracle(), newOracle);
    }

    function test_TransferOracle_RevertsZeroAddress() public {
        vm.expectRevert(BoutsJudgeCommit.ZeroAddress.selector);
        vm.prank(oracle);
        judge.transferOracle(address(0));
    }

    function test_TransferOracle_RevertsIfNotOracle() public {
        vm.expectRevert(BoutsJudgeCommit.OnlyOracle.selector);
        vm.prank(attacker);
        judge.transferOracle(attacker);
    }

    function test_NewOracle_CanCommitAfterTransfer() public {
        address newOracle = makeAddr("newOracle");

        vm.prank(oracle);
        judge.transferOracle(newOracle);

        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.prank(newOracle);
        judge.commit(ENTRY_ID, "claude", commitment); // should succeed

        assertNotEq(judge.commitments(ENTRY_ID, "claude"), bytes32(0));
    }

    function test_OldOracle_CannotCommitAfterTransfer() public {
        address newOracle = makeAddr("newOracle");

        vm.prank(oracle);
        judge.transferOracle(newOracle);

        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.expectRevert(BoutsJudgeCommit.OnlyOracle.selector);
        vm.prank(oracle); // old oracle — should fail
        judge.commit(ENTRY_ID, "claude", commitment);
    }

    // =========================================================================
    // Fuzz tests
    // =========================================================================

    function testFuzz_CommitReveal_AnyValidScore(uint8 score) public {
        vm.assume(score >= 10 && score <= 100);
        bytes32 salt = keccak256(abi.encodePacked(score));
        bytes32 commitment = _commitment(ENTRY_ID, "claude", score, salt);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);
        judge.reveal(ENTRY_ID, "claude", score, salt);
        vm.stopPrank();

        assertEq(judge.reveals(ENTRY_ID, "claude"), score);
    }

    function testFuzz_Commit_AnyEntryId(bytes32 entryId) public {
        vm.assume(entryId != bytes32(0));
        bytes32 commitment = _commitment(entryId, "gpt4o", SCORE_GPT4O, SALT_GPT4O);

        vm.prank(oracle);
        judge.commit(entryId, "gpt4o", commitment);

        assertEq(judge.commitments(entryId, "gpt4o"), commitment);
    }

    function testFuzz_Reveal_WrongScore_Reverts(uint8 wrongScore) public {
        vm.assume(wrongScore >= 10 && wrongScore <= 100 && wrongScore != SCORE_CLAUDE);
        bytes32 commitment = _commitment(ENTRY_ID, "claude", SCORE_CLAUDE, SALT_CLAUDE);

        vm.startPrank(oracle);
        judge.commit(ENTRY_ID, "claude", commitment);

        vm.expectRevert(BoutsJudgeCommit.InvalidReveal.selector);
        judge.reveal(ENTRY_ID, "claude", wrongScore, SALT_CLAUDE);
        vm.stopPrank();
    }
}
