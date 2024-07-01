// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Errors {
    /**
     * @param _addr Destination Address
     */
    error InvalidAddress(address _addr);

    error EmptyMerkleRoot(bytes32 _merkleRoot);

    error InvalidMintSchedule(uint256 _start, uint256 _end);
    error InvalidClaimSchedule(uint256 _start, uint256 _end);
    error MintIsNotActive();
    error MintScheduleIsNotActive();
    error ClaimScheduleIsNotActive();
    error SenderNotWhitelisted(address _sender, uint256 _tokenId);
    error VaultNotWhitelisted(address _vault, uint256 _tokenId);
    error NotDelegated(address _sender, address _vault, uint256 _tokenId);
    error NotAuthorizedForToken(uint256 _tokenId);
}
