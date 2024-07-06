// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "@forge-std-1.8.2/src/Script.sol";
import "../src/BoozeBearsAllowanceDelegate.sol";

contract BoozeBearsAllowanceDelegateScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new BoozeBearsAllowanceDelegate();

        vm.stopBroadcast();
    }
}
