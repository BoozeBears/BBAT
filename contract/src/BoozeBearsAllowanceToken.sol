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
import "./IBoozeBearsErrors.sol";
import "./BoozeBearsAllowanceDelegate.sol";

contract BoozeBearsAllowanceToken is
    ERC721,
    ERC721Pausable,
    AccessControl,
    ERC721Burnable,
    ERC721Royalty,
    ERC721Enumerable,
    ReentrancyGuard,
    IBoozeBearsErrors
{
    using Strings for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant MINT_PHASE_ROLE = keccak256("MINT_PHASE_ROLE");
    bytes32 public constant BURN_PHASE_ROLE = keccak256("BURN_PHASE_ROLE");
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
     * @dev BurnSchedule defines start and end of the burn period
     */
    struct BurnSchedule {
        uint256 start;
        uint256 end;
    }

    /**
     * @notice mintPhaseState defines if the mint phase is active or not
     */
    bool public mintPhaseState;

    /**
     * @notice burnPhaseState defines if the burn phase is active or not
     */
    bool public burnPhaseState;

    /**
     * @notice mintSchedule defines start and end of the mint period.
     */
    MintSchedule public mintSchedule;

    /**
     * @notice burnSchedule defines start and end of the burn period
     */
    BurnSchedule public burnSchedule;

    /**
     * @dev Create new contract
     *
     * @param _name Name of this contract
     * @param _symbol Symbol of this contract
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        _grantRole(MINT_PHASE_ROLE, msg.sender);
        _grantRole(BURN_PHASE_ROLE, msg.sender);
        _grantRole(BURN_ALL_ROLE, msg.sender);
        _grantRole(BURN_ONE_ROLE, msg.sender);
        _grantRole(WITHDRAW_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
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
     * - mint phase must be active
     * - proofs must be verified
     * - destination can't be 0
     */
    function mint(bytes32[][] calldata _proofs, uint256[] calldata _tokenIds, address _vault)
        external
        _isMintPhase
        _requireValidAddress(delegateContractAddress)
    {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len;) {
            if (_vault == address(0)) {
                require(
                    _verifyWhitelist(_proofs[i], _tokenIds[i], msg.sender),
                    BoozeBearsSenderNotWhitelisted(msg.sender, _tokenIds[i])
                );
            } else {
                require(
                    _verifyWhitelist(_proofs[i], _tokenIds[i], _vault),
                    BoozeBearsVaultNotWhitelisted(_vault, _tokenIds[i])
                );

                address delegateAddress = delegateContract.getDelegationReceiver(_vault);
                require(delegateAddress == msg.sender, BoozeBearsNotDelegated(msg.sender, _vault, _tokenIds[i]));
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
     * - burn phase must be active
     * - must be authorized for all tokenIds
     */
    function burnBatchWithHash(uint256[] calldata _tokenIds, bytes32)
        external
        _isBurnPhase
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
        require(_merkleRoot != bytes32(0), BoozeBearsEmptyMerkleRoot(_merkleRoot));
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
     * @dev flip the mint phase state
     */
    function flipMintPhaseState() external onlyRole(MINT_PHASE_ROLE) {
        mintPhaseState = !mintPhaseState;
    }

    /**
     * @dev flip the burn phase state
     */
    function flipBurnPhaseState() external onlyRole(BURN_PHASE_ROLE) {
        burnPhaseState = !burnPhaseState;
    }

    /**
     * @dev check if mint is active
     */
    function isMintActive() external view returns (bool) {
        return _checkSchedule(mintSchedule.start, mintSchedule.end) && mintPhaseState;
    }

    /**
     * @dev check if burn is active
     */
    function isBurnActive() external view returns (bool) {
        return _checkSchedule(burnSchedule.start, burnSchedule.end) && burnPhaseState;
    }

    /**
     * @dev set mint schedule
     *
     * @param _start Timestamp to mark the start
     * @param _end Timestamp to mark the end
     */
    function setMintSchedule(uint256 _start, uint256 _end) external onlyRole(MINT_PHASE_ROLE) {
        require(_end >= _start || _start == 0 || _end == 0, BoozeBearsInvalidMintSchedule(_start, _end));
        mintSchedule.start = _start;
        mintSchedule.end = _end;
    }

    /**
     * @dev set burn schedule
     *
     * @param _start Timestamp to mark the start
     * @param _end Timestamp to mark the end
     */
    function setBurnSchedule(uint256 _start, uint256 _end) external onlyRole(BURN_PHASE_ROLE) {
        require(_end >= _start || _start == 0 || _end == 0, BoozeBearsInvalidBurnSchedule(_start, _end));
        burnSchedule.start = _start;
        burnSchedule.end = _end;
    }

    /**
     * @dev Set delegate contract address
     */
    function setDelegateContractAddress(address addr) external onlyRole(ADMIN_ROLE) {
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
        require(_addr != address(0), BoozeBearsInvalidAddress(_addr));
        _;
    }

    /**
     * @dev check if schedule state
     */
    function _checkSchedule(uint256 _start, uint256 _end) internal view returns (bool) {
        return (_start <= block.timestamp) && (_end >= block.timestamp);
    }

    /**
     * @dev Check if current block.timestamp is within our mint schedule
     */
    modifier _isMintPhase() virtual {
        require(this.isMintActive(), BoozeBearsMintScheduleNotActive());
        _;
    }

    /**
     * @dev Check if current block.timestamp is within our burn schedule
     */
    modifier _isBurnPhase() virtual {
        require(this.isBurnActive(), BoozeBearsBurnScheduleNotActive());
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
                BoozeBearsNotAuthorizedForToken(_tokenIds[i])
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
