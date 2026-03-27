// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {BoutsAgentSBT} from "../src/BoutsAgentSBT.sol";
import {BoutsScoreAggregator} from "../src/BoutsScoreAggregator.sol";

contract Deploy is Script {
    // BoutsJudgeCommit already deployed on Base mainnet
    address constant JUDGE_COMMIT = 0x267837dEB1ae92Eb4F321De99F893802B20AAD9a;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer / Oracle:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("JudgeCommit address:", JUDGE_COMMIT);

        vm.startBroadcast(deployerPrivateKey);

        BoutsAgentSBT sbt = new BoutsAgentSBT(deployer);
        BoutsScoreAggregator aggregator = new BoutsScoreAggregator(deployer, JUDGE_COMMIT);

        vm.stopBroadcast();

        console2.log("");
        console2.log("BoutsAgentSBT deployed at:         ", address(sbt));
        console2.log("BoutsScoreAggregator deployed at:  ", address(aggregator));
        console2.log("");
        console2.log("Add to Supabase secrets:");
        console2.log("  BOUTS_SBT_ADDRESS        =", address(sbt));
        console2.log("  BOUTS_AGGREGATOR_ADDRESS =", address(aggregator));
    }
}
