// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "@forge-std-1.8.2/src/Test.sol";
import {BoozeBearsAllowanceToken} from "../src/BoozeBearsAllowanceToken.sol";
import {Utils} from "./utils/Utils.sol";
import {Pausable} from "@openzeppelin-contracts-5.0.2/utils/Pausable.sol";
import "../src/Errors.sol";

contract BoozeBearsAllowanceTokenTest is Test, Pausable {
    Utils internal utils;
    BoozeBearsAllowanceToken internal bbat;

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

        bbat.setMerkleRoot(merkleRoot);

        bbat.flipMintActiveState();

        vm.stopPrank();
    }

    function test_BaseURI() external {
        vm.startPrank(admin);
        bbat.setBaseURI("https://boozebears.io/");
        vm.stopPrank();

        assertEq(bbat.baseURI(), "https://boozebears.io/");
    }

    function test_MintAll() external {
        enableMintSchedule();

        for (uint256 i = 0; i < mints.length; i++) {
            mintToken(i);
        }
    }

    function test_BurnAll() external {
        enableMintSchedule();

        for (uint256 i = 0; i < mints.length; i++) {
            mintToken(i);
        }
        assertEq(3333, bbat.totalSupply());

        vm.startPrank(admin);
        bbat.burnAll();
        vm.stopPrank();

        assertEq(0, bbat.totalSupply());
    }

    function test_ExpectRevert_MintPaused() external {
        enableMintSchedule();
        pauseContract();

        vm.expectRevert(EnforcedPause.selector);
        mintToken(0);
    }

    function test_ExpectRevert_MintBeforeMintScheduleStart() external {
        setMintSchedule();

        vm.expectRevert(Errors.MintScheduleIsNotActive.selector);
        mintToken(0);
    }

    function test_ExpectRevert_AfterBeforeMintScheduleStart() external {
        setMintSchedule();

        vm.expectRevert(Errors.MintScheduleIsNotActive.selector);
        mintToken(0);
    }

    function test_MintScheduleActive() external {
        enableMintSchedule();

        mintToken(0);
    }

    function test_TotalSupply() external {
        assertEq(0, bbat.totalSupply());
        enableMintSchedule();
        mintToken(0);

        assertEq(3, bbat.totalSupply());
    }

    function test_MintOnlyToOwner() external {
        enableMintSchedule();

        vm.startPrank(mints[1].owner, mints[1].owner);
        bbat.mint(mints[0].proofs, mints[0].tokenIds, mints[0].owner);
        vm.stopPrank();
    }

    function test_BurnOwned() external {
        enableMintSchedule();

        mintToken(0);
        vm.startPrank(mints[0].owner);
        bbat.burnWithHash(mints[0].tokenIds, bytes32("Some Hash"));
        vm.stopPrank();
    }

    function test_ExpectRevert_BurnNonOwned() external {
        enableMintSchedule();

        mintToken(0);
        vm.startPrank(mints[1].owner);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotAuthorizedForToken.selector, mints[0].tokenIds[0]));
        bbat.burnWithHash(mints[0].tokenIds, bytes32("Some Hash"));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintNotToOwner() external {
        enableMintSchedule();

        vm.startPrank(mints[1].owner, mints[1].owner);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotWhitelisted.selector, mints[1].owner, mints[1].owner, mints[0].tokenIds[0]));
        bbat.mint(mints[0].proofs, mints[0].tokenIds, mints[1].owner);
        vm.stopPrank();
    }

    function test_ExpectRevert_MintWithInvalidProofs() external {
        enableMintSchedule();

        vm.startPrank(mints[0].owner, mints[0].owner);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotWhitelisted.selector, mints[0].owner, mints[0].owner, mints[0].tokenIds[0]));
        bbat.mint(mints[1].proofs, mints[0].tokenIds, mints[0].owner);
        vm.stopPrank();
    }

    function setMintSchedule() internal {
        setMintSchedule(1718661600, 1721253600);
    }

    function setMintSchedule(uint256 _start, uint256 _end) internal {
        vm.startPrank(admin);
        bbat.setMintSchedule(_start, _end);
        vm.stopPrank();
    }

    function enableMintSchedule() internal {
        setMintSchedule();
        skip(1718661601);
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
        /*for (uint256 i = 0; i < mints[position].tokenIds.length; i++) {
      console.log("Owner: %s | TokenId: %d", mints[position].owner, mints[position].tokenIds[i]);
      for (uint256 j = 0; j < mints[position].proofs[i].length; j++){
        console.logBytes32(mints[position].proofs[i][j]);
      }
    }*/

        //uint256 totalSupply = bbat.totalSupply();

        vm.startPrank(mints[position].owner, mints[position].owner);
        bbat.mint(mints[position].proofs, mints[position].tokenIds, mints[position].owner);
        vm.stopPrank();

        //assertEq(totalSupply + mints[position].tokenIds.length, bbat.totalSupply());
    }
}
