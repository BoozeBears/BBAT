// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Errors {
  /**
   * Destination Address must not be zero
   *
   * @param _to Destination Address
     */
  error DestinationAddressRequired(address _to);

  error EmptyMerkleRoot(bytes32 _merkleRoot);

  error InvalidMintSchedule(uint256 _start, uint256 _end);
  error MintIsNotActive();
  error MintScheduleIsNotActive();
  error NotWhitelisted(address _sender, address _to, uint256 _tokenId);
  error NotAuthorizedForToken(uint256 _tokenId);
}
