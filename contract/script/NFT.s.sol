// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "@forge-std-1.8.2/src/Script.sol";
import "../src/BoozeBearsAllowanceToken.sol";

contract NFTScript is Script {
    function setUp() public {}

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    BoozeBearsAllowanceToken bbat = new BoozeBearsAllowanceToken("BoozeBearsAllowanceToken-H1/2024", "BBAT-H1-2024");

    vm.stopBroadcast();
  }
}
