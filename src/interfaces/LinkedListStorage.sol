// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LinkedListStorage.
 * @author CFI team.
 * @notice Linked list storage interface.
 */
interface LinkedListStorage {
    /* ========== ERRORS ========== */

    /// @dev Thrown when the LinkedList has not been initalized.
    error LinkedListNotInitalized();

    /* ========== STORAGE ========== */

    /// @dev Data pertaining to each node. Struct is contract specific. NOTE: Must be
    /// the same as the data type of {data} in {Node}.
    struct Order {
        uint256 orderID;
        uint256 timestamp;
        uint256 amount;
        address maker;
    }

    /// @dev Storage of each node. Linked list specific struct.
    struct Node {
        int256 nextIndex;
        int256 prevIndex;
        /// @dev Change the data type of {data} as required.
        Order data;
    }

    /// @dev Storage logic for the linked list. Linked list specific struct.
    struct LinkedList {
        mapping(int256 => Node) nodes;
        int256 headIndex;
        int256 tailIndex;
        int256 count;
        bool isInitialized;
    }
}
