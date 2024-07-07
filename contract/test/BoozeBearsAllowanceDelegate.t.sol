// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "@forge-std-1.8.2/src/Test.sol";
import "../src/BoozeBearsAllowanceDelegate.sol";

contract BoozeBearsAllowanceDelegateTest is Test {
    BoozeBearsAllowanceDelegate internal delegationContract;

    address internal delegationSender1 = vm.addr(2);
    address internal delegationSender2 = vm.addr(3);
    address internal delegationReceiver = vm.addr(4);

    function setUp() external {
        delegationContract = new BoozeBearsAllowanceDelegate();

        assertEq(address(0), delegationContract.getDelegationReceiver(delegationSender1));
    }

    function test_setDelegation() external {
        vm.startPrank(delegationSender1);

        delegationContract.setDelegation(delegationReceiver);
        assertEq(delegationReceiver, delegationContract.getDelegationReceiver(delegationSender1));

        vm.stopPrank();
    }

    function test_resetDelegation() external {
        vm.startPrank(delegationSender1);

        delegationContract.setDelegation(delegationReceiver);
        assertEq(delegationReceiver, delegationContract.getDelegationReceiver(delegationSender1));

        delegationContract.resetDelegation();
        assertEq(address(0), delegationContract.getDelegationReceiver(delegationSender1));

        vm.stopPrank();
    }

    function test_getDelegationReceiverMsgSender() external {
        vm.startPrank(delegationSender1);

        delegationContract.setDelegation(delegationReceiver);
        assertEq(delegationReceiver, delegationContract.getDelegationReceiver());

        vm.stopPrank();
    }

    function test_getDelegationSenders() external {
        address[] memory configuredDelegationSenders = new address[](2);
        configuredDelegationSenders[0] = delegationSender1;
        configuredDelegationSenders[1] = delegationSender2;

        for (uint256 i = 0; i < configuredDelegationSenders.length; i++) {
            vm.startPrank(configuredDelegationSenders[i]);
            delegationContract.setDelegation(delegationReceiver);
            vm.stopPrank();
        }

        vm.startPrank(delegationReceiver);
        address[] memory delegationSenders = delegationContract.getDelegationSenders();
        vm.stopPrank();

        for (uint256 i = 0; i < delegationSenders.length; i++) {
            assertEq(configuredDelegationSenders[i], delegationSenders[i]);
        }
    }
}
