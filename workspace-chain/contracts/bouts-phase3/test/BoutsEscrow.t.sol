// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {BoutsEscrow} from "../src/BoutsEscrow.sol";

// ─── Mock USDC ────────────────────────────────────────────────────────────────
contract MockUSDC {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

// ─── Escrow wrapper that uses mock USDC ──────────────────────────────────────
// We deploy a modified version pointing to mock USDC for testing
contract BoutsEscrowTest is Test {
    // Since USDC address is hardcoded as constant, we use vm.etch to put mock code there
    BoutsEscrow public escrow;
    MockUSDC public usdc;

    address oracle   = makeAddr("oracle");
    address owner1   = makeAddr("owner1");
    address owner2   = makeAddr("owner2");
    address owner3   = makeAddr("owner3");
    address attacker = makeAddr("attacker");

    bytes32 constant CHALLENGE_1 = bytes32(uint256(0xC001));
    bytes32 constant CHALLENGE_2 = bytes32(uint256(0xC002));
    bytes32 constant ENTRY_1     = bytes32(uint256(0xE001));
    bytes32 constant ENTRY_2     = bytes32(uint256(0xE002));
    bytes32 constant ENTRY_3     = bytes32(uint256(0xE003));

    uint256 constant ENTRY_FEE   = 5_000_000;  // 5 USDC
    uint256 constant FUTURE_TIME = 9_999_999_999;

    // Standard 50/30/20 split — sums to 9500 bps (95%, platform takes 5%)
    uint16[3] PAYOUT_5030_20 = [uint16(5000), uint16(3000), uint16(2000)];

    function setUp() public {
        // Deploy mock USDC and etch its bytecode at the hardcoded USDC address
        usdc = new MockUSDC();
        vm.etch(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, address(usdc).code);
        usdc = MockUSDC(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

        escrow = new BoutsEscrow(oracle);

        // Fund test users with USDC
        usdc.mint(owner1, 1000_000_000); // 1000 USDC
        usdc.mint(owner2, 1000_000_000);
        usdc.mint(owner3, 1000_000_000);

        // Approve escrow to spend
        vm.prank(owner1); usdc.approve(address(escrow), type(uint256).max);
        vm.prank(owner2); usdc.approve(address(escrow), type(uint256).max);
        vm.prank(owner3); usdc.approve(address(escrow), type(uint256).max);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    function _createChallenge(bytes32 challengeId) internal {
        vm.prank(oracle);
        escrow.createChallenge(challengeId, ENTRY_FEE, FUTURE_TIME, PAYOUT_5030_20);
    }

    function _enter(bytes32 challengeId, bytes32 entryId, address payer) internal {
        vm.prank(payer);
        escrow.payEntry(challengeId, entryId);
    }

    function _commitment(bytes32 entryId, uint8 score, bytes32 salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(entryId, score, salt));
    }

    function _commitReveal(bytes32 entryId, bytes32 challengeId, uint8 score, bytes32 salt) internal {
        vm.startPrank(oracle);
        escrow.commitComposite(entryId, challengeId, _commitment(entryId, score, salt));
        escrow.revealComposite(entryId, score, salt);
        vm.stopPrank();
    }

    function _fullFlow(bytes32 challengeId) internal returns (bytes32[] memory ranked) {
        _createChallenge(challengeId);
        _enter(challengeId, ENTRY_1, owner1);
        _enter(challengeId, ENTRY_2, owner2);
        _enter(challengeId, ENTRY_3, owner3);

        vm.prank(oracle);
        escrow.closeEntries(challengeId);

        bytes32 salt1 = keccak256("s1");
        bytes32 salt2 = keccak256("s2");
        bytes32 salt3 = keccak256("s3");

        _commitReveal(ENTRY_1, challengeId, 85, salt1);
        _commitReveal(ENTRY_2, challengeId, 70, salt2);
        _commitReveal(ENTRY_3, challengeId, 60, salt3);

        ranked = new bytes32[](3);
        ranked[0] = ENTRY_1; // 1st
        ranked[1] = ENTRY_2; // 2nd
        ranked[2] = ENTRY_3; // 3rd

        vm.prank(oracle);
        escrow.finalizeChallenge(challengeId, ranked);
    }

    // ── Constructor ──────────────────────────────────────────────────────────

    function test_Constructor_SetsOracle() public view {
        assertEq(escrow.oracle(), oracle);
        assertEq(escrow.owner(), oracle);
    }

    function test_Constructor_RevertsZeroAddress() public {
        vm.expectRevert(BoutsEscrow.ZeroAddress.selector);
        new BoutsEscrow(address(0));
    }

    // ── Create Challenge ─────────────────────────────────────────────────────

    function test_CreateChallenge_Success() public {
        _createChallenge(CHALLENGE_1);
        BoutsEscrow.Challenge memory c = escrow.getChallenge(CHALLENGE_1);
        assertTrue(c.exists);
        assertEq(c.entryFee, ENTRY_FEE);
        assertEq(c.maxPool, 500_000_000); // $500 cap
        assertEq(c.totalPool, 0);
        assertEq(uint8(c.state), uint8(BoutsEscrow.ChallengeState.Open));
    }

    function test_CreateChallenge_RevertsInvalidPayout() public {
        uint16[3] memory badPayout = [uint16(5000), uint16(3000), uint16(3000)]; // sums to 11000, not 10000
        vm.expectRevert(BoutsEscrow.InvalidPayoutConfig.selector);
        vm.prank(oracle);
        escrow.createChallenge(CHALLENGE_1, ENTRY_FEE, FUTURE_TIME, badPayout);
    }

    function test_CreateChallenge_RevertsExpiredTime() public {
        vm.expectRevert(BoutsEscrow.ChallengeExpired.selector);
        vm.prank(oracle);
        escrow.createChallenge(CHALLENGE_1, ENTRY_FEE, block.timestamp - 1, PAYOUT_5030_20);
    }

    function test_CreateChallenge_RevertsDuplicate() public {
        _createChallenge(CHALLENGE_1);
        vm.expectRevert(BoutsEscrow.ChallengeAlreadyExists.selector);
        vm.prank(oracle);
        escrow.createChallenge(CHALLENGE_1, ENTRY_FEE, FUTURE_TIME, PAYOUT_5030_20);
    }

    function test_CreateChallenge_RevertsNotOracle() public {
        vm.expectRevert(BoutsEscrow.OnlyOracle.selector);
        vm.prank(attacker);
        escrow.createChallenge(CHALLENGE_1, ENTRY_FEE, FUTURE_TIME, PAYOUT_5030_20);
    }

    // ── Pay Entry ────────────────────────────────────────────────────────────

    function test_PayEntry_Success() public {
        _createChallenge(CHALLENGE_1);
        uint256 balBefore = usdc.balanceOf(owner1);

        _enter(CHALLENGE_1, ENTRY_1, owner1);

        assertEq(usdc.balanceOf(owner1), balBefore - ENTRY_FEE);
        assertEq(usdc.balanceOf(address(escrow)), ENTRY_FEE);

        BoutsEscrow.Challenge memory c = escrow.getChallenge(CHALLENGE_1);
        assertEq(c.totalPool, ENTRY_FEE);
        assertEq(c.entryCount, 1);

        BoutsEscrow.Entry memory e = escrow.getEntry(ENTRY_1);
        assertTrue(e.paid);
        assertEq(e.payer, owner1);
    }

    function test_PayEntry_PoolCap() public {
        // Entry fee = 5 USDC, cap = 500 USDC → 100 entries max
        _createChallenge(CHALLENGE_1);

        // Fill to cap
        for (uint256 i = 0; i < 100; i++) {
            address payer = makeAddr(string(abi.encodePacked("payer", i)));
            bytes32 eid = bytes32(uint256(i + 1));
            usdc.mint(payer, ENTRY_FEE);
            vm.prank(payer); usdc.approve(address(escrow), ENTRY_FEE);
            vm.prank(payer); escrow.payEntry(CHALLENGE_1, eid);
        }

        // 101st entry should fail
        address extra = makeAddr("extra");
        usdc.mint(extra, ENTRY_FEE);
        vm.prank(extra); usdc.approve(address(escrow), ENTRY_FEE);
        vm.expectRevert(BoutsEscrow.PoolCapExceeded.selector);
        vm.prank(extra); escrow.payEntry(CHALLENGE_1, bytes32(uint256(101)));
    }

    function test_PayEntry_RevertsDoubleEntry() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);

        vm.expectRevert(BoutsEscrow.AlreadyPaid.selector);
        vm.prank(owner1);
        escrow.payEntry(CHALLENGE_1, ENTRY_1);
    }

    function test_PayEntry_RevertsClosedChallenge() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);
        _enter(CHALLENGE_1, ENTRY_2, owner2);
        vm.prank(oracle); escrow.closeEntries(CHALLENGE_1);

        vm.expectRevert(BoutsEscrow.ChallengeNotOpen.selector);
        vm.prank(owner3);
        escrow.payEntry(CHALLENGE_1, ENTRY_3);
    }

    // ── Commit-Reveal ─────────────────────────────────────────────────────────

    function test_CommitReveal_Success() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);
        vm.prank(oracle); escrow.closeEntries(CHALLENGE_1);

        bytes32 salt = keccak256("mysalt");
        uint8 score  = 85;

        vm.prank(oracle);
        escrow.commitComposite(ENTRY_1, CHALLENGE_1, _commitment(ENTRY_1, score, salt));

        BoutsEscrow.Entry memory e = escrow.getEntry(ENTRY_1);
        assertTrue(e.scoreCommitted);
        assertFalse(e.scoreRevealed);

        vm.prank(oracle);
        escrow.revealComposite(ENTRY_1, score, salt);

        e = escrow.getEntry(ENTRY_1);
        assertTrue(e.scoreRevealed);
        assertEq(e.compositeScore, 85);
    }

    function test_Reveal_RevertsWrongScore() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);
        vm.prank(oracle); escrow.closeEntries(CHALLENGE_1);

        bytes32 salt = keccak256("salt");
        vm.prank(oracle);
        escrow.commitComposite(ENTRY_1, CHALLENGE_1, _commitment(ENTRY_1, 85, salt));

        vm.expectRevert(BoutsEscrow.InvalidReveal.selector);
        vm.prank(oracle);
        escrow.revealComposite(ENTRY_1, 99, salt); // wrong score
    }

    function test_Reveal_RevertsWrongSalt() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);
        vm.prank(oracle); escrow.closeEntries(CHALLENGE_1);

        vm.prank(oracle);
        escrow.commitComposite(ENTRY_1, CHALLENGE_1, _commitment(ENTRY_1, 85, keccak256("salt")));

        vm.expectRevert(BoutsEscrow.InvalidReveal.selector);
        vm.prank(oracle);
        escrow.revealComposite(ENTRY_1, 85, keccak256("wrong")); // wrong salt
    }

    // ── Finalize + Claim ─────────────────────────────────────────────────────

    function test_FullFlow_ClaimPrizes() public {
        _fullFlow(CHALLENGE_1);

        uint256 totalPool  = ENTRY_FEE * 3; // 15 USDC
        uint256 platformFee = (totalPool * 500) / 10_000; // 5% = 0.75 USDC
        uint256 prizePool  = totalPool - platformFee; // 14.25 USDC

        uint256 prize1 = (prizePool * 5000) / 10_000; // 50% = 7.125
        uint256 prize2 = (prizePool * 3000) / 10_000; // 30% = 4.275
        uint256 prize3 = (prizePool * 2000) / 10_000; // 20% = 2.85

        BoutsEscrow.Entry memory e1 = escrow.getEntry(ENTRY_1);
        assertEq(e1.placement, 1);
        assertEq(e1.prizeAmount, prize1);

        // Claim prizes
        uint256 bal1Before = usdc.balanceOf(owner1);
        vm.prank(owner1); escrow.claimPrize(ENTRY_1);
        assertEq(usdc.balanceOf(owner1), bal1Before + prize1);

        uint256 bal2Before = usdc.balanceOf(owner2);
        vm.prank(owner2); escrow.claimPrize(ENTRY_2);
        assertEq(usdc.balanceOf(owner2), bal2Before + prize2);

        uint256 bal3Before = usdc.balanceOf(owner3);
        vm.prank(owner3); escrow.claimPrize(ENTRY_3);
        assertEq(usdc.balanceOf(owner3), bal3Before + prize3);

        // Platform fee accumulated
        assertEq(escrow.platformFeeBalance(), platformFee);
    }

    function test_ClaimPrize_RevertsDoubleClaim() public {
        _fullFlow(CHALLENGE_1);
        vm.prank(owner1); escrow.claimPrize(ENTRY_1);

        vm.expectRevert(BoutsEscrow.AlreadyClaimed.selector);
        vm.prank(owner1); escrow.claimPrize(ENTRY_1);
    }

    function test_ClaimPrize_RevertsWrongCaller() public {
        _fullFlow(CHALLENGE_1);

        vm.expectRevert("Not entry owner");
        vm.prank(attacker);
        escrow.claimPrize(ENTRY_1); // attacker tries to claim owner1's prize
    }

    // ── Cancel + Refund ──────────────────────────────────────────────────────

    function test_CancelAndRefund() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);
        _enter(CHALLENGE_1, ENTRY_2, owner2);

        uint256 bal1Before = usdc.balanceOf(owner1);
        uint256 bal2Before = usdc.balanceOf(owner2);

        vm.prank(oracle); escrow.cancelChallenge(CHALLENGE_1);

        vm.prank(owner1); escrow.claimRefund(ENTRY_1);
        vm.prank(owner2); escrow.claimRefund(ENTRY_2);

        assertEq(usdc.balanceOf(owner1), bal1Before + ENTRY_FEE);
        assertEq(usdc.balanceOf(owner2), bal2Before + ENTRY_FEE);
    }

    function test_ClaimRefund_RevertsIfNotCancelled() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);

        vm.expectRevert(BoutsEscrow.NotRefundable.selector);
        vm.prank(owner1); escrow.claimRefund(ENTRY_1);
    }

    function test_Cancel_RevertsIfFinalized() public {
        _fullFlow(CHALLENGE_1);

        vm.expectRevert(BoutsEscrow.NotRefundable.selector);
        vm.prank(oracle); escrow.cancelChallenge(CHALLENGE_1);
    }

    // ── Platform fee withdrawal ──────────────────────────────────────────────

    function test_WithdrawPlatformFees() public {
        _fullFlow(CHALLENGE_1);

        address treasury = makeAddr("treasury");
        uint256 fees = escrow.platformFeeBalance();
        assertTrue(fees > 0);

        vm.prank(oracle); // oracle = owner in this setup
        escrow.withdrawPlatformFees(treasury);

        assertEq(usdc.balanceOf(treasury), fees);
        assertEq(escrow.platformFeeBalance(), 0);
    }

    // ── Pause ────────────────────────────────────────────────────────────────

    function test_Pause_BlocksEntry() public {
        _createChallenge(CHALLENGE_1);
        vm.prank(oracle); escrow.pause();

        vm.expectRevert(BoutsEscrow.Paused_.selector);
        vm.prank(owner1); escrow.payEntry(CHALLENGE_1, ENTRY_1);
    }

    function test_Unpause_RestoresEntry() public {
        _createChallenge(CHALLENGE_1);
        vm.prank(oracle); escrow.pause();
        vm.prank(oracle); escrow.unpause();

        _enter(CHALLENGE_1, ENTRY_1, owner1); // should work
        assertTrue(escrow.getEntry(ENTRY_1).paid);
    }

    // ── Disqualification ─────────────────────────────────────────────────────

    function test_Disqualified_NoClaimPrize() public {
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);
        _enter(CHALLENGE_1, ENTRY_2, owner2);
        _enter(CHALLENGE_1, ENTRY_3, owner3);

        vm.prank(oracle); escrow.closeEntries(CHALLENGE_1);
        vm.prank(oracle); escrow.disqualifyEntry(ENTRY_1);

        _commitReveal(ENTRY_2, CHALLENGE_1, 80, keccak256("s2"));
        _commitReveal(ENTRY_3, CHALLENGE_1, 70, keccak256("s3"));

        // Oracle excludes DQ'd ENTRY_1 — only eligible entries passed to finalizeChallenge
        // DQ'd fee stays in pool, redistributed to winners
        bytes32[] memory ranked = new bytes32[](2);
        ranked[0] = ENTRY_2; // 1st — slot [0] = 50%
        ranked[1] = ENTRY_3; // 2nd — slot [1] = 30%

        vm.prank(oracle);
        escrow.finalizeChallenge(CHALLENGE_1, ranked);

        // ENTRY_2 is correctly placed 1st (not 2nd due to DQ counter bug)
        BoutsEscrow.Entry memory e2 = escrow.getEntry(ENTRY_2);
        assertEq(e2.placement, 1);

        // Entry 1 has no prize — can't claim
        vm.expectRevert(BoutsEscrow.EntryNotFound.selector);
        vm.prank(owner1); escrow.claimPrize(ENTRY_1);
    }

    // ── Fuzz ─────────────────────────────────────────────────────────────────

    function testFuzz_CommitReveal_AnyScore(uint8 score) public {
        vm.assume(score <= 100);
        _createChallenge(CHALLENGE_1);
        _enter(CHALLENGE_1, ENTRY_1, owner1);
        vm.prank(oracle); escrow.closeEntries(CHALLENGE_1);

        bytes32 salt = keccak256(abi.encodePacked(score));
        _commitReveal(ENTRY_1, CHALLENGE_1, score, salt);

        assertEq(escrow.getCompositeScore(ENTRY_1), score);
    }
}
