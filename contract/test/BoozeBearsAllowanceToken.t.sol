// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "@forge-std-1.8.2/src/Test.sol";
import {BoozeBearsAllowanceToken} from "../src/BoozeBearsAllowanceToken.sol";
import {BoozeBearsAllowanceDelegate} from "../src/BoozeBearsAllowanceDelegate.sol";
import {Utils} from "./utils/Utils.sol";
import {Pausable} from "@openzeppelin-contracts-5.0.2/utils/Pausable.sol";
import "../src/Errors.sol";

contract BoozeBearsAllowanceTokenTest is Test, Pausable {
    Utils internal utils;
    BoozeBearsAllowanceToken internal bbat;
    BoozeBearsAllowanceDelegate internal bbar;

    struct Mint {
        address owner;
        bytes32[][] proofs;
        uint256[] tokenIds;
    }

    Mint[] internal mints;

    address internal admin = vm.addr(1);

    function setUp() external {
        vm.chainId(80002);

        utils = new Utils();

        bytes32 merkleRoot = bytes32(vm.parseJson(vm.readFile("./test/fixtures/merkle-root.json")));
        assertEq(merkleRoot, 0x653cd4c8c2208a0e5c176b4a6e333273ec10a49db48a8f6c6bdc2f7e12766153);

        mints = abi.decode(vm.parseJson(vm.readFile("./test/fixtures/merkle-mints.json")), (Mint[]));

        vm.startPrank(admin);

        bbat = new BoozeBearsAllowanceToken("BoozeBearsAllowanceToken", "BBAT");
        assertEq(bbat.name(), "BoozeBearsAllowanceToken");
        assertEq(bbat.symbol(), "BBAT");

        bbar = new BoozeBearsAllowanceDelegate();

        bbat.setRedirectContractAddress(address(bbar));
        bbat.setMerkleRoot(merkleRoot);

        vm.stopPrank();
    }

    function test_BaseURI() external {
        vm.startPrank(admin);
        bbat.setBaseURI("https://boozebears.io/");
        vm.stopPrank();

        assertEq(bbat.baseURI(), "https://boozebears.io/");
    }

    /**
     * forge-config: default.fuzz.runs = 3333
     * forge-config: default.fuzz.max-test-rejects = 500
     */
    function testFuzz_Mint(uint16 position) external {
        vm.assume(position < mints.length);

        withinMintSchedule();

        mintToken(position);
    }

    function test_MintAll() external {
        withinMintSchedule();

        for (uint256 i = 0; i < mints.length; i++) {
            mintToken(i);
        }
    }

    function test_BurnAll() external {
        withinMintSchedule();

        for (uint256 i = 0; i < mints.length; i++) {
            mintToken(i);
        }
        assertEq(3333, bbat.totalSupply());

        vm.startPrank(admin);
        bbat.burnAll();
        vm.stopPrank();

        assertEq(0, bbat.totalSupply());
    }

    function test_MintWithDelegation() external {
        withinMintSchedule();

        vm.startPrank(mints[0].owner, mints[0].owner);
        bbar.updateAllowanceReceiver(address(123));
        vm.stopPrank();

        mintTokenWithDelegation(0, address(123), mints[0].owner);
    }

    function test_ExpectRevert_MintPaused() external {
        withinMintSchedule();
        pauseContract();

        vm.expectRevert(EnforcedPause.selector);
        mintToken(0);

        unpauseContract();
    }

    function test_ExpectRevert_MintBeforeMintScheduleStart() external {
        beforeMintSchedule();

        vm.expectRevert(Errors.MintScheduleIsNotActive.selector);
        mintToken(0);
    }

    function test_ExpectRevert_MintAfterMintScheduleStart() external {
        afterMintSchedule();

        vm.expectRevert(Errors.MintScheduleIsNotActive.selector);
        mintToken(0);
    }

    function test_MintScheduleActive() external {
        withinMintSchedule();

        mintToken(0);
    }

    function test_TotalSupply() external {
        assertEq(0, bbat.totalSupply());
        withinMintSchedule();
        mintToken(0);

        assertEq(3, bbat.totalSupply());
    }

    function test_BurnOwned() external {
        withinMintSchedule();
        mintToken(0);

        withinClaimSchedule();
        vm.startPrank(mints[0].owner);
        bbat.burnWithHash(mints[0].tokenIds, bytes32("Some Hash"));
        vm.stopPrank();
    }

    function test_burnOne() external {
        withinMintSchedule();
        mintToken(0);

        withinClaimSchedule();
        vm.startPrank(admin);
        bbat.burnOne(mints[0].tokenIds[0]);
        vm.stopPrank();
    }

    function test_ExpectRevert_BurnNonOwned() external {
        withinMintSchedule();
        mintToken(0);

        withinClaimSchedule();

        vm.startPrank(mints[1].owner);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotAuthorizedForToken.selector, mints[0].tokenIds[0]));
        bbat.burnWithHash(mints[0].tokenIds, bytes32("Some Hash"));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintWithInvalidProofs() external {
        withinMintSchedule();

        vm.startPrank(mints[0].owner, mints[0].owner);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SenderNotWhitelisted.selector, mints[0].owner, mints[0].tokenIds[0])
        );
        bbat.mint(mints[1].proofs, mints[0].tokenIds, address(0));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintNotOnAllowlist() external {
        withinMintSchedule();

        vm.startPrank(address(123), address(123));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SenderNotWhitelisted.selector, address(123), mints[0].tokenIds[0])
        );
        bbat.mint(mints[1].proofs, mints[0].tokenIds, address(0));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintVaultNotOnAllowlist() external {
        withinMintSchedule();

        vm.startPrank(address(123), address(123));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.VaultNotWhitelisted.selector, address(12345), mints[0].tokenIds[0])
        );
        bbat.mint(mints[1].proofs, mints[0].tokenIds, address(12345));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintNotDelegated() external {
        withinMintSchedule();

        vm.startPrank(address(123), address(123));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.NotDelegated.selector, address(123), mints[1].owner, mints[1].tokenIds[0])
        );
        bbat.mint(mints[1].proofs, mints[1].tokenIds, mints[1].owner);
        vm.stopPrank();
    }

    function test_ExpectRevert_InvalidMintSchedule() external {
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidMintSchedule.selector, 1706778000, 1704099600));
        bbat.setMintSchedule(1706778000, 1704099600);
        vm.stopPrank();
    }

    function test_ExpectRevert_InvalidClaimSchedule() external {
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidClaimSchedule.selector, 1706778000, 1704099600));
        bbat.setClaimSchedule(1706778000, 1704099600);
        vm.stopPrank();
    }

    function unpauseContract() internal {
        vm.startPrank(admin);
        bbat.unpause();
        vm.stopPrank();
    }

    function pauseContract() internal {
        vm.startPrank(admin);
        bbat.pause();
        vm.stopPrank();
    }

    function mintToken(uint256 position) internal {
        vm.startPrank(mints[position].owner, mints[position].owner);
        bbat.mint(mints[position].proofs, mints[position].tokenIds, address(0));
        vm.stopPrank();
    }

    function mintTokenWithDelegation(uint256 position, address sender, address _vault) internal {
        vm.startPrank(sender, sender);
        bbat.mint(mints[position].proofs, mints[position].tokenIds, _vault);
        vm.stopPrank();
    }

    function withinMintSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setMintSchedule(1704099600, 1706778000);
        skip(1705222800);
        bbat.flipMintActiveState();
        vm.assertTrue(bbat.isMintActive());
        vm.stopPrank();
    }

    function beforeMintSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setMintSchedule(1704099600, 1706778000);
        skip(1701421200);
        bbat.flipMintActiveState();
        vm.assertTrue(bbat.isMintActive());
        vm.stopPrank();
    }

    function afterMintSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setMintSchedule(1704099600, 1706778000);
        skip(1709283600);
        bbat.flipMintActiveState();
        vm.assertTrue(bbat.isMintActive());
        vm.stopPrank();
    }

    function withinClaimSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setClaimSchedule(1704099600, 1706778000);
        skip(1705222800);
        vm.stopPrank();
    }

    function beforeClaimSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setClaimSchedule(1704099600, 1706778000);
        skip(1701421200);
        vm.stopPrank();
    }

    function afterClaimSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setClaimSchedule(1704099600, 1706778000);
        skip(1709283600);
        vm.stopPrank();
    }
}
