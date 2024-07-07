// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin-contracts-5.0.2/utils/structs/EnumerableMap.sol";

contract BoozeBearsAllowanceDelegate {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    /**
     * Mapping for the RedirectConfig to a specific owner
     */
    struct AllowanceConfig {
        mapping(address => RedirectConfig) ownerToRedirect;
        mapping(address => RedirectConfig) allowanceMapping;
    }

    /**
     * Holds the redirect for one owner or specific tokens from one owner
     */
    struct RedirectConfig {
        address redirectAllReceiver;
        EnumerableMap.UintToAddressMap redirectTokens;
    }

    /**
     * Holds the AllowanceRedirectConfig
     */
    AllowanceConfig internal allowanceConfig;

    constructor() {}

    /**
     * @notice Update allowance receiver for msg.sender who should receive all allowances
     *
     * @param receiver address of the receiver
     */
    function updateAllowanceReceiver(address receiver) external {
        allowanceConfig.allowanceMapping[msg.sender].redirectAllReceiver = receiver;
    }

    /**
     * @notice Update allowance receiver for specific tokenIds
     *
     * @param tokenIds token id list which should be redirected
     * @param receiver address of the receiver
     */
    function updateAllowanceReceiver(uint256[] calldata tokenIds, address receiver) external {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            allowanceConfig.allowanceMapping[msg.sender].redirectTokens.set(tokenIds[i], receiver);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Reset all allowance receivers for msg.sender
     */
    function resetAllowanceReceiver() external {
        allowanceConfig.allowanceMapping[msg.sender].redirectAllReceiver = address(0);
        uint256 len = allowanceConfig.allowanceMapping[msg.sender].redirectTokens.length();
        uint256[] memory tokenIds = new uint256[](len);
        for (uint256 i = 0; i < len;) {
            (uint256 tokenId,) = allowanceConfig.allowanceMapping[msg.sender].redirectTokens.at(i);
            tokenIds[i] = tokenId;

            unchecked {
                ++i;
            }
        }

        len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            allowanceConfig.allowanceMapping[msg.sender].redirectTokens.remove(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Reset allowance receiver for specific tokenIds
     *
     * @param tokenIds List of tokenIds which should be reset
     */
    function resetAllowanceReceiver(uint256[] calldata tokenIds) external {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            allowanceConfig.allowanceMapping[msg.sender].redirectTokens.remove(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get allowance receiver for a specific tokenId
     *
     * @param owner Token Owner
     * @param tokenId Token Id
     */
    function getAllowanceReceiver(address owner, uint256 tokenId) external view returns (address) {
        address tokenAllowanceReceiver = allowanceConfig.allowanceMapping[owner].redirectAllReceiver;
        if (tokenAllowanceReceiver != address(0)) {
            return tokenAllowanceReceiver;
        }
        (, tokenAllowanceReceiver) = allowanceConfig.allowanceMapping[owner].redirectTokens.tryGet(tokenId);
        return tokenAllowanceReceiver;
    }
}
