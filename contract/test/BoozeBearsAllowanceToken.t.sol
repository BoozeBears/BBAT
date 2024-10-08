// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "@forge-std-1.8.2/src/Test.sol";
import {BoozeBearsAllowanceToken} from "../src/BoozeBearsAllowanceToken.sol";
import {BoozeBearsAllowanceDelegate} from "../src/BoozeBearsAllowanceDelegate.sol";
import {Utils} from "./utils/Utils.sol";
import {Pausable} from "@openzeppelin-contracts-5.0.2/utils/Pausable.sol";
import {IBoozeBearsErrors} from "../src/IBoozeBearsErrors.sol";
import {IERC721Errors} from "@openzeppelin-contracts-5.0.2/interfaces/draft-IERC6093.sol";

contract BoozeBearsAllowanceTokenTest is Test, Pausable {
    Utils internal utils;
    BoozeBearsAllowanceToken internal bbat;
    BoozeBearsAllowanceDelegate internal bbad;

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

        bbad = new BoozeBearsAllowanceDelegate();

        bbat.setDelegateContractAddress(address(bbad));
        bbat.setMerkleRoot(merkleRoot);

        vm.stopPrank();
    }

    function test_construct() external {
        vm.startPrank(admin);
        BoozeBearsAllowanceToken testContract = new BoozeBearsAllowanceToken("BoozeBearsAllowanceToken", "BBAT");
        assertTrue(testContract.hasRole(keccak256("ADMIN_ROLE"), admin));
        assertTrue(testContract.hasRole(keccak256("MINT_PHASE_ROLE"), admin));
        assertTrue(testContract.hasRole(keccak256("BURN_PHASE_ROLE"), admin));
        assertTrue(testContract.hasRole(keccak256("BURN_ALL_ROLE"), admin));
        assertTrue(testContract.hasRole(keccak256("BURN_ONE_ROLE"), admin));
        assertTrue(testContract.hasRole(keccak256("WITHDRAW_ROLE"), admin));
        assertTrue(testContract.hasRole(keccak256("PAUSER_ROLE"), admin));
        vm.stopPrank();
    }

    function test_BaseURI() external {
        vm.startPrank(admin);
        bbat.setBaseURI("https://boozebears.io/");
        vm.stopPrank();

        withinMintSchedule();

        mintToken(1);

        assertEq(bbat.baseURI(), "https://boozebears.io/");
        assertEq(bbat.tokenURI(mints[1].tokenIds[0]), "https://boozebears.io/253.json");
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
        bbad.setDelegation(address(123));
        vm.stopPrank();

        mintTokenWithDelegation(0, address(123), mints[0].owner);
    }

    function test_ExpectRevert_MintTwice() external {
        withinMintSchedule();

        mintToken(1);
        vm.expectRevert(
            abi.encodeWithSelector(IBoozeBearsErrors.BoozeBearsTokenAlreadyMinted.selector, mints[1].tokenIds[0])
        );
        mintToken(1);
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

        vm.expectRevert(IBoozeBearsErrors.BoozeBearsMintScheduleNotActive.selector);
        mintToken(0);
    }

    function test_ExpectRevert_MintAfterMintScheduleStart() external {
        afterMintSchedule();

        vm.expectRevert(IBoozeBearsErrors.BoozeBearsMintScheduleNotActive.selector);
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

        withinBurnSchedule();
        vm.startPrank(mints[0].owner);
        bbat.burnBatchWithHash(mints[0].tokenIds, bytes32("Some Hash"));
        vm.stopPrank();
    }

    function test_ExpectRevert_BurnOwnedAndMintAgain() external {
        withinMintSchedule();
        mintToken(0);

        withinBurnSchedule();
        vm.startPrank(mints[0].owner);
        bbat.burnBatchWithHash(mints[0].tokenIds, bytes32("Some Hash"));
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(IBoozeBearsErrors.BoozeBearsTokenAlreadyMinted.selector, mints[0].tokenIds[0])
        );
        mintToken(0);
    }

    function test_burnOne() external {
        withinMintSchedule();
        mintToken(0);

        withinBurnSchedule();
        vm.startPrank(admin);
        bbat.burnOne(mints[0].tokenIds[0]);
        vm.stopPrank();
    }

    function test_ExpectRevert_BurnNonOwned() external {
        withinMintSchedule();
        mintToken(0);

        withinBurnSchedule();

        vm.startPrank(mints[1].owner);
        vm.expectRevert(
            abi.encodeWithSelector(IBoozeBearsErrors.BoozeBearsNotAuthorizedForToken.selector, mints[0].tokenIds[0])
        );
        bbat.burnBatchWithHash(mints[0].tokenIds, bytes32("Some Hash"));
        vm.stopPrank();
    }

    function test_ExpectRevert_BoozeBearsNoTokensToMint() external {
        withinMintSchedule();

        vm.startPrank(address(123), address(123));
        vm.expectRevert(IBoozeBearsErrors.BoozeBearsInvalidProofsTokenIds.selector);
        bbat.mint(mints[1].proofs, mints[0].tokenIds, address(0));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintNotOnAllowlist() external {
        withinMintSchedule();

        mints[0].proofs[0].pop();
        bytes32[][] memory proofs = mints[0].proofs;

        vm.startPrank(address(123), address(123));
        vm.expectRevert(
            abi.encodeWithSelector(
                IBoozeBearsErrors.BoozeBearsSenderNotWhitelisted.selector, address(123), mints[0].tokenIds[0]
            )
        );
        bbat.mint(proofs, mints[0].tokenIds, address(0));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintVaultNotOnAllowlist() external {
        withinMintSchedule();

        vm.startPrank(address(123), address(123));
        vm.expectRevert(
            abi.encodeWithSelector(
                IBoozeBearsErrors.BoozeBearsVaultNotWhitelisted.selector, address(12345), mints[0].tokenIds[0]
            )
        );
        bbat.mint(mints[0].proofs, mints[0].tokenIds, address(12345));
        vm.stopPrank();
    }

    function test_ExpectRevert_MintNotDelegated() external {
        withinMintSchedule();

        vm.startPrank(address(123), address(123));
        vm.expectRevert(
            abi.encodeWithSelector(
                IBoozeBearsErrors.BoozeBearsNotDelegated.selector, address(123), mints[1].owner, mints[1].tokenIds[0]
            )
        );
        bbat.mint(mints[1].proofs, mints[1].tokenIds, mints[1].owner);
        vm.stopPrank();
    }

    function test_ExpectRevert_InvalidMintSchedule() external {
        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(IBoozeBearsErrors.BoozeBearsInvalidMintSchedule.selector, 1706778000, 1704099600)
        );
        bbat.setMintSchedule(1706778000, 1704099600);
        vm.stopPrank();
    }

    function test_ExpectRevert_InvalidBurnSchedule() external {
        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(IBoozeBearsErrors.BoozeBearsInvalidBurnSchedule.selector, 1706778000, 1704099600)
        );
        bbat.setBurnSchedule(1706778000, 1704099600);
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
        bbat.flipMintPhaseState();
        skip(1705222800);
        vm.stopPrank();
    }

    function beforeMintSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setMintSchedule(1704099600, 1706778000);
        bbat.flipMintPhaseState();
        skip(1701421200);
        vm.stopPrank();
    }

    function afterMintSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setMintSchedule(1704099600, 1706778000);
        bbat.flipMintPhaseState();
        skip(1709283600);
        vm.stopPrank();
    }

    function withinBurnSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setBurnSchedule(1704099600, 1706778000);
        bbat.flipBurnPhaseState();
        skip(1705222800);
        vm.stopPrank();
    }

    function beforeBurnSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setBurnSchedule(1704099600, 1706778000);
        bbat.flipBurnPhaseState();
        skip(1701421200);
        vm.stopPrank();
    }

    function afterBurnSchedule() internal {
        vm.startPrank(admin);
        vm.warp(0);
        bbat.setBurnSchedule(1704099600, 1706778000);
        bbat.flipBurnPhaseState();
        skip(1709283600);
        vm.stopPrank();
    }
}
