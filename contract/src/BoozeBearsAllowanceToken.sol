// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin-contracts-5.0.2/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin-contracts-5.0.2/access/AccessControl.sol";
import "@openzeppelin-contracts-5.0.2/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin-contracts-5.0.2/utils/cryptography/MerkleProof.sol";
import "@openzeppelin-contracts-5.0.2/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin-contracts-5.0.2/token/ERC721/ERC721.sol";
import "@openzeppelin-contracts-5.0.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin-contracts-5.0.2/utils/ReentrancyGuard.sol";
import "./Errors.sol";

contract BoozeBearsAllowanceToken is
    ERC721,
    ERC721Pausable,
    AccessControl,
    ERC721Burnable,
    ERC721Royalty,
    ERC721Enumerable,
    ReentrancyGuard
{
    using Strings for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BURN_ALL_ROLE = keccak256("BURN_ALL_ROLE");
    bytes32 public constant BURN_ONE_ROLE = keccak256("BURN_ONE_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @notice Holds the merkle root
     */
    bytes32 public merkleRoot;

    /**
     * @notice Holds the base URI for token metadata
     */
    string public baseURI;

    /**
     * @notice Holds the mint active state
     */
    bool public isMintActive = false;

    /**
     * @dev MintSchedule defines start and end of the mint period
     */
    struct MintSchedule {
        uint256 start;
        uint256 end;
    }

    /**
     * @notice MintSchedule defines start and end of the mint period.
     */
    MintSchedule public mintSchedule;



    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BURN_ALL_ROLE, msg.sender);
        _grantRole(BURN_ONE_ROLE, msg.sender);
        _grantRole(WITHDRAW_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Mint a new token.
     *
     * @param proofs Merkle proof for whitelist verification for each tokenId.
     * @param tokenIds The tokens which should be minted.
     * @param to The address to mint the token to.
     *
     * Requirements:
     * - block.timestamp must within mint schedule
     * - proofs must be verified
     * - destination can't be 0
     */
    function mint(bytes32[][] calldata proofs, uint256[] calldata tokenIds, address to)
        external
        payable
        _checkMintActive
        _checkMintSchedule
        _verifyProof(proofs, tokenIds, to)
    {
        require(to != address(0), Errors.DestinationAddressRequired(to));

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i]);
        }
    }

    /**
     * @notice Burn multiple tokens
     *
     * @param tokenIds TokenIds which should be burned
     *
     * Requirements:
     * - must be authorized for all tokenIds
     */
    function burnWithHash(uint256[] calldata tokenIds, bytes32) external _checkAuthorizations(tokenIds) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            super._burn(tokenIds[i]);
        }
    }

    /**
     * @dev Burn all tokens
     */
    function burnAll() external onlyRole(BURN_ALL_ROLE) {
        for (uint256 i = totalSupply(); i > 0; i--) {
            uint256 tokenId = tokenByIndex(i - 1);
            _burn(tokenId);
        }
    }

    /**
     * @dev Set MerkleRoot
     *
     * @param _merkleRoot MerkleRoot to persist
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE) {
        require(_merkleRoot != bytes32(0), Errors.EmptyMerkleRoot(_merkleRoot));
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Set BaseURI
     *
     * @param baseURI_ baseURI to persist
     */
    function setBaseURI(string calldata baseURI_) external onlyRole(ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    /**
     * @dev Withdraw native token funds
     */
    function withdraw() external onlyRole(WITHDRAW_ROLE) nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Get token metadata URI
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    /**
     * @dev set mint schedule
     *
     * @param _start Timestamp to mark the start
     * @param _end Timestamp to mark the end
     */
    function setMintSchedule(uint256 _start, uint256 _end) external onlyRole(ADMIN_ROLE) {
        require(_end >= _start || _start == 0 || _end == 0, Errors.InvalidMintSchedule(_start, _end));
        mintSchedule.start = _start;
        mintSchedule.end = _end;
    }

    /**
     * @dev flip mint active state
     */
    function flipMintActiveState() external onlyRole(ADMIN_ROLE) {
        isMintActive = !isMintActive;
    }

    /**
     * @dev Check if mint is active
     */
    modifier _checkMintActive() virtual {
        require(isMintActive, Errors.MintIsNotActive());
        _;
    }

    /**
     * @dev Verify proof for either msg.sender or the to address
     *
     * @param proofs Proof for each tokenId
     * @param tokenIds tokenIds which should be verified
     * @param to Address which should receive the Tokens
     */
    modifier _verifyProof(bytes32[][] calldata proofs, uint256[] calldata tokenIds, address to) virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _verify(proofs[i], _leaf(msg.sender, tokenIds[i])) || _verify(proofs[i], _leaf(to, tokenIds[i])),
              Errors.NotWhitelisted(msg.sender, to, tokenIds[i])
            );
        }
        _;
    }

    /**
     * @dev Check if current block.timestamp is within our mint schedule
     */
    modifier _checkMintSchedule() virtual {
        require(
            (mintSchedule.start == 0 || mintSchedule.start <= block.timestamp)
                && (mintSchedule.end == 0 || mintSchedule.end >= block.timestamp),
          Errors.MintScheduleIsNotActive()
        );
        _;
    }

    /**
     * @dev Check if msg.sender is owner or Authorized
     */
    modifier _checkAuthorizations(uint256[] calldata tokenIds) virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_isAuthorized(_ownerOf(tokenIds[i]), msg.sender, tokenIds[i]), Errors.NotAuthorizedForToken(tokenIds[i]));
        }
        _;
    }

    /**
     * @dev Verify MerkleProof
     *
     * @param proof Proof to verify
     * @param leaf Precalculated leaf to verify against proof
     */
    function _verify(bytes32[] calldata proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev Calculate MerkleProof leaf
     *
     * @param owner Owner used to calculate the leaf
     * @param tokenId TokenID used to calculate the leaf
     */
    function _leaf(address owner, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(owner, tokenId))));
    }

    /**
     * @dev Override _baseURI to return our baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
