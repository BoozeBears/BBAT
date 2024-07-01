// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "@forge-std-1.8.2/src/Test.sol";
import "../src/BoozeBearsAllowanceDelegate.sol";

contract BoozeBearsAllowanceDelegateTest is Test {
    BoozeBearsAllowanceDelegate internal bbar;

    address internal allowanceOwner = vm.addr(2);
    address internal allowanceReceiver = vm.addr(3);

    function setUp() external {
        bbar = new BoozeBearsAllowanceDelegate();

        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 1));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 2));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 3));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 4));
    }

    /**
     * forge-config: default.fuzz.runs = 10000
     * forge-config: default.fuzz.max-test-rejects = 500
     */
    function testFuzz_UpdateRedirectAllTokens(uint16 position) external {
        vm.startPrank(allowanceOwner);

        bbar.updateAllowanceReceiver(allowanceReceiver);

        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, position));

        vm.stopPrank();
    }

    function fixtureTokenIds() external pure returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        return tokenIds;
    }

    /**
     * forge-config: default.fuzz.runs = 10000
     * forge-config: default.fuzz.max-test-rejects = 500
     */
    function testFuzz_UpdateRedirectTokens(uint256[] calldata tokenIds) external {
        vm.startPrank(allowanceOwner);

        bbar.updateAllowanceReceiver(tokenIds, allowanceReceiver);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, tokenIds[i]));
        }
        vm.stopPrank();
    }

    function test_ResetRedirectAllTokens() external {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(allowanceOwner);

        bbar.updateAllowanceReceiver(allowanceReceiver);

        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 1));

        bbar.resetAllowanceReceiver();

        vm.stopPrank();

        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 1));
    }

    function test_ResetRedirectTokensWithResetAll() external {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.startPrank(allowanceOwner);

        bbar.updateAllowanceReceiver(tokenIds, allowanceReceiver);

        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 1));
        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 2));
        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 3));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 4));

        bbar.resetAllowanceReceiver();

        vm.stopPrank();

        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 1));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 2));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 3));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 4));
    }

    function test_ResetRedirectTokensWithResetTokens() external {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        uint256[] memory tokenIds2 = new uint256[](2);
        tokenIds2[0] = 1;
        tokenIds2[1] = 2;

        vm.startPrank(allowanceOwner);

        bbar.updateAllowanceReceiver(tokenIds, allowanceReceiver);

        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 1));
        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 2));
        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 3));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 4));

        bbar.resetAllowanceReceiver(tokenIds2);

        vm.stopPrank();

        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 1));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 2));
        assertEq(allowanceReceiver, bbar.getAllowanceReceiver(allowanceOwner, 3));
        assertEq(address(0), bbar.getAllowanceReceiver(allowanceOwner, 4));
    }
}
