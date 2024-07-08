// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBoozeBearsErrors {
    /**
     * @param _addr Destination Address
     */
    error BoozeBearsInvalidAddress(address _addr);

    error BoozeBearsEmptyMerkleRoot(bytes32 _merkleRoot);

    error BoozeBearsInvalidMintSchedule(uint256 _start, uint256 _end);
    error BoozeBearsInvalidBurnSchedule(uint256 _start, uint256 _end);
    error BoozeBearsMintPhaseNotActive();
    error BoozeBearsMintScheduleNotActive();
    error BoozeBearsBurnPhaseNotActive();
    error BoozeBearsBurnScheduleNotActive();
    error BoozeBearsSenderNotWhitelisted(address _sender, uint256 _tokenId);
    error BoozeBearsVaultNotWhitelisted(address _vault, uint256 _tokenId);
    error BoozeBearsNotDelegated(address _sender, address _vault, uint256 _tokenId);
    error BoozeBearsNotAuthorizedForToken(uint256 _tokenId);
    error BoozeBearsNoCallsFromOtherContract();
    error BoozeBearsInvalidProofsTokenIds();
    error BoozeBearsTokenAlreadyMinted(uint256 _tokenId);
}
