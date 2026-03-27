// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {BoutsJudgeCommit} from "../src/BoutsJudgeCommit.sol";

/**
 * @title Deploy
 * @notice Deployment script for BoutsJudgeCommit.
 *
 * Usage:
 *   Base Sepolia (test):
 *     forge script script/Deploy.s.sol \
 *       --rpc-url $BASE_SEPOLIA_RPC_URL \
 *       --private-key $DEPLOYER_PRIVATE_KEY \
 *       --broadcast \
 *       --verify \
 *       --etherscan-api-key $BASESCAN_API_KEY \
 *       -vvvv
 *
 *   Base Mainnet:
 *     forge script script/Deploy.s.sol \
 *       --rpc-url $BASE_RPC_URL \
 *       --private-key $DEPLOYER_PRIVATE_KEY \
 *       --broadcast \
 *       --verify \
 *       --etherscan-api-key $BASESCAN_API_KEY \
 *       -vvvv
 *
 * Required env vars:
 *   DEPLOYER_PRIVATE_KEY   — Private key of the oracle/deployer wallet
 *   BASE_RPC_URL           — Alchemy Base mainnet RPC
 *   BASE_SEPOLIA_RPC_URL   — Alchemy Base Sepolia RPC
 *   BASESCAN_API_KEY       — For contract verification
 */
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer / Oracle address:", deployer);
        console2.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        BoutsJudgeCommit judge = new BoutsJudgeCommit(deployer);

        vm.stopBroadcast();

        console2.log("BoutsJudgeCommit deployed at:", address(judge));
        console2.log("Oracle set to:", judge.oracle());
        console2.log("");
        console2.log("Add to Supabase secrets:");
        console2.log("  JUDGE_CONTRACT_ADDRESS =", address(judge));
    }
}
