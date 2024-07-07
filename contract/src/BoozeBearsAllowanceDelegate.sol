// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin-contracts-5.0.2/utils/structs/EnumerableSet.sol";
import "./IBoozeBearsErrors.sol";

contract BoozeBearsAllowanceDelegate is IBoozeBearsErrors {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * msg.sender => receiver
     */
    mapping(address => address) public delegationSenderReceiverMapping;

    /**
     * receiver => AddressSet
     */
    mapping(address => EnumerableSet.AddressSet) private delegationReceiverSendersMapping;

    constructor() {}

    /**
     * @notice Set delegation for msg.sender to receiver
     *
     * @param receiver address for delegation
     */
    function setDelegation(address receiver) external noContractCalls {
        delegationSenderReceiverMapping[msg.sender] = receiver;
        delegationReceiverSendersMapping[receiver].add(msg.sender);
    }

    /**
     * @notice Reset delegation
     */
    function resetDelegation() external noContractCalls {
        address delegatedTo = delegationSenderReceiverMapping[msg.sender];

        delete delegationSenderReceiverMapping[msg.sender];
        delegationReceiverSendersMapping[delegatedTo].remove(msg.sender);
    }

    /**
     * @notice Get delegation receiver for sender
     *
     * @param sender address
     */
    function getDelegationReceiver(address sender) external view returns (address) {
        return delegationSenderReceiverMapping[sender];
    }

    /**
     * @notice Get delegation receiver for msg.sender
     */
    function getDelegationReceiver() external view returns (address) {
        return delegationSenderReceiverMapping[msg.sender];
    }

    /**
     * @notice Get delegation senders for receiver
     *
     * @param receiver address
     */
    function getDelegationSenders(address receiver) external view returns (address[] memory) {
        return delegationReceiverSendersMapping[receiver].values();
    }

    /**
     * @notice Get delegation senders for msg.sender
     */
    function getDelegationSenders() external view returns (address[] memory) {
        return delegationReceiverSendersMapping[msg.sender].values();
    }

    /**
     * @dev do not allow to be called from another contract
     */
    modifier noContractCalls() virtual {
        require(msg.sender == tx.origin, BoozeBearsNoCallsFromOtherContract());
        _;
    }
}
