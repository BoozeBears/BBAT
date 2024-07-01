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
import "./BoozeBearsAllowanceDelegate.sol";

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
     * @notice Token redirect contract
     */
    address public delegateContractAddress;

    /**
     * @notice Reference to BoozeBearsAllowanceDelegate.sol contract
     */
    BoozeBearsAllowanceDelegate private delegateContract;

    /**
     * @dev MintSchedule defines start and end of the mint period
     */
    struct MintSchedule {
        uint256 start;
        uint256 end;
    }

    /**
     * @dev ClaimSchedule defines start and end of the claim period
     */
    struct ClaimSchedule {
        uint256 start;
        uint256 end;
    }

    /**
     * @notice mintSchedule defines start and end of the mint period.
     */
    MintSchedule public mintSchedule;

    /**
     * @notice claimSchedule defines start and end of the claim period
     */
    ClaimSchedule public claimSchedule;

    /**
     * @dev Create new contract
     *
     * @param _name Name of this contract
     * @param _symbol Symbol of this contract
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
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
     * @param _proofs Merkle proof for whitelist verification for each tokenId.
     * @param _tokenIds The tokens which should be minted.
     * @param _vault Wallet address which owns the token.
     *
     * Requirements:
     * - block.timestamp must within mint schedule
     * - proofs must be verified
     * - destination can't be 0
     */
    function mint(bytes32[][] calldata _proofs, uint256[] calldata _tokenIds, address _vault)
        external
        _checkMintActive
        _checkMintSchedule
        _requireValidAddress(delegateContractAddress)
    {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len;) {
            if (_vault == address(0)) {
                require(
                    _verifyWhitelist(_proofs[i], _tokenIds[i], msg.sender),
                    Errors.SenderNotWhitelisted(msg.sender, _tokenIds[i])
                );
            } else {
                require(_verifyWhitelist(_proofs[i], _tokenIds[i], _vault), Errors.VaultNotWhitelisted(_vault, _tokenIds[i]));

                address delegateAddress = delegateContract.getAllowanceReceiver(_vault, _tokenIds[i]);
                require(delegateAddress == msg.sender, Errors.NotDelegated(msg.sender, _vault, _tokenIds[i]));
            }
            _safeMint(msg.sender, _tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Burn multiple tokens
     *
     * @param _tokenIds TokenIds which should be burned
     *
     * Requirements:
     * - must be authorized for all tokenIds
     */
    function burnWithHash(uint256[] calldata _tokenIds, bytes32)
        external
        _checkClaimSchedule
        _checkAuthorizations(_tokenIds)
    {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len;) {
            super._burn(_tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Burn one token
     *
     * @param _tokenId TokenId to burn
     */
    function burnOne(uint256 _tokenId) external onlyRole(BURN_ONE_ROLE) {
        _burn(_tokenId);
    }

    /**
     * @dev Burn all tokens
     */
    function burnAll() external onlyRole(BURN_ALL_ROLE) {
        uint256 totalSupply = totalSupply();
        for (uint256 i = totalSupply; i > 0;) {
            uint256 tokenId = tokenByIndex(i - 1);
            _burn(tokenId);

            unchecked {
                --i;
            }
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
     * @param _baseURI_ baseURI to persist
     */
    function setBaseURI(string calldata _baseURI_) external onlyRole(ADMIN_ROLE) {
        baseURI = _baseURI_;
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
     *
     * @param _tokenId Token ID
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(_tokenId);
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
     * @dev set claim schedule
     *
     * @param _start Timestamp to mark the start
     * @param _end Timestamp to mark the end
     */
    function setClaimSchedule(uint256 _start, uint256 _end) external onlyRole(ADMIN_ROLE) {
        require(_end >= _start || _start == 0 || _end == 0, Errors.InvalidClaimSchedule(_start, _end));
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
     * @dev Set redirect contract address
     */
    function setRedirectContractAddress(address addr) external onlyRole(ADMIN_ROLE) {
        delegateContractAddress = addr;
        delegateContract = BoozeBearsAllowanceDelegate(addr);
    }

    /**
     * @dev Verify whitelist for msg.sender
     *
     * @param _proof Proof for MerkleTree
     * @param _tokenId tokenId which should be verified
     * @param _address address which should be verified
     */
    function _verifyWhitelist(bytes32[] calldata _proof, uint256 _tokenId, address _address)
        internal
        view
        returns (bool)
    {
        if (_verify(_proof, _getLeaf(_address, _tokenId))) {
            return true;
        }
        return false;
    }

    /**
     * @dev Check if address is valid ( != 0 )
     */
    modifier _requireValidAddress(address _addr) virtual {
        require(_addr != address(0), Errors.InvalidAddress(_addr));
        _;
    }

    /**
     * @dev Check if mint is active
     */
    modifier _checkMintActive() virtual {
        require(isMintActive, Errors.MintIsNotActive());
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
     * @dev Check if current block.timestamp is within our claim schedule
     */
    modifier _checkClaimSchedule() virtual {
        require(
            (claimSchedule.start == 0 || claimSchedule.start <= block.timestamp)
                && (claimSchedule.end == 0 || claimSchedule.end >= block.timestamp),
            Errors.ClaimScheduleIsNotActive()
        );
        _;
    }

    /**
     * @dev Check if msg.sender is owner or Authorized
     */
    modifier _checkAuthorizations(uint256[] calldata _tokenIds) virtual {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len;) {
            require(
                _isAuthorized(_ownerOf(_tokenIds[i]), msg.sender, _tokenIds[i]),
                Errors.NotAuthorizedForToken(_tokenIds[i])
            );
            unchecked {
                ++i;
            }
        }
        _;
    }

    /**
     * @dev Verify MerkleProof
     *
     * @param _proof Proof to verify
     * @param _leaf Precalculated leaf to verify against proof
     */
    function _verify(bytes32[] calldata _proof, bytes32 _leaf) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /**
     * @dev Calculate MerkleProof leaf
     *
     * @param _owner Owner used to calculate the leaf
     * @param _tokenId TokenID used to calculate the leaf
     */
    function _getLeaf(address _owner, uint256 _tokenId) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(_owner, _tokenId))));
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
