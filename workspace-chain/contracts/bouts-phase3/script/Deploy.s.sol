// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {BoutsEscrow} from "../src/BoutsEscrow.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer / Oracle:", deployer);
        console2.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);
        BoutsEscrow escrow = new BoutsEscrow(deployer);
        vm.stopBroadcast();

        console2.log("BoutsEscrow deployed at:", address(escrow));
        console2.log("");
        console2.log("Add to Supabase secrets:");
        console2.log("  BOUTS_ESCROW_ADDRESS =", address(escrow));
    }
}
