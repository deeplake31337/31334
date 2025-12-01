// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {LinkedListStorage} from "../interfaces/LinkedListStorage.sol";

/**
 * @title LinkedListLogic
 * @notice A FIFO queue implementation for order-book style use cases.
 */
library LinkedListLogic {
    /* ====================== INITIALIZATION ====================== */

    /**
     * @dev Initializes an empty doubly-linked list with head and tail sentinels.
     */
    function initialize(LinkedListStorage.LinkedList storage list) internal {
        int256 head = type(int256).min;
        int256 tail = type(int256).max;
        list.headIndex = head;
        list.tailIndex = tail;
        list.nodes[head].nextIndex = tail;
        list.nodes[tail].prevIndex = head;
        list.count = 0;
        list.isInitialized = true;
    }

    /* ========================= APPEND ========================= */

    /**
     * @dev Appends a new order node to the tail of the list (FIFO push).
     * @return idx The new node's index.
     */
    function append(LinkedListStorage.LinkedList storage list, LinkedListStorage.Order memory order)
        internal
        returns (int256 idx)
    {
        require(list.isInitialized, "List not initialized");
        // use current count as new index
        list.count++;
        idx = list.count;
        int256 tail = list.tailIndex;
        int256 prev = list.nodes[tail].prevIndex;
        // link new node
        LinkedListStorage.Node storage node = list.nodes[idx];
        node.data = order;
        node.prevIndex = prev;
        node.nextIndex = tail;
        // bridge neighbors
        list.nodes[prev].nextIndex = idx;
        list.nodes[tail].prevIndex = idx;
    }

    /**
     * @dev Alias for append, for backward compatibility.
     */
    function insert(LinkedListStorage.LinkedList storage list, LinkedListStorage.Order memory order)
        internal
        returns (int256)
    {
        return append(list, order);
    }

    /* ========================= REMOVE ========================= */

    /**
     * @dev Removes the node at idx. idx must not be a sentinel.
     */
    function remove(LinkedListStorage.LinkedList storage list, int256 idx) internal {
        require(list.isInitialized, "List not initialized");
        require(idx != list.headIndex && idx != list.tailIndex, "Cannot remove sentinel");
        LinkedListStorage.Node storage node = list.nodes[idx];
        int256 prev = node.prevIndex;
        int256 nextIdx = node.nextIndex;
        // bridge over
        list.nodes[prev].nextIndex = nextIdx;
        list.nodes[nextIdx].prevIndex = prev;
        // clear
        delete list.nodes[idx];
    }

    /**
     * @dev Pops the oldest order (FIFO) and returns its data.
     */
    function pop(LinkedListStorage.LinkedList storage list) internal returns (LinkedListStorage.Order memory order) {
        require(!isEmpty(list), "List empty");
        int256 firstIdx = list.nodes[list.headIndex].nextIndex;
        order = list.nodes[firstIdx].data;
        remove(list, firstIdx);
    }

    /* ========================= TRAVERSAL ========================= */

    /**
     * @dev Returns the first real node index, or tailIndex if empty.
     */
    function first(LinkedListStorage.LinkedList storage list) internal view returns (int256) {
        return list.nodes[list.headIndex].nextIndex;
    }

    /**
     * @dev Returns the next node index after idx.
     */
    function next(LinkedListStorage.LinkedList storage list, int256 idx) internal view returns (int256) {
        return list.nodes[idx].nextIndex;
    }

    /**
     * @dev Returns true if no real nodes exist.
     */
    function isEmpty(LinkedListStorage.LinkedList storage list) internal view returns (bool) {
        return list.nodes[list.headIndex].nextIndex == list.tailIndex;
    }

    /* ========================= GETTERS ========================= */

    function getData(LinkedListStorage.LinkedList storage list, int256 idx)
        internal
        view
        returns (LinkedListStorage.Order memory)
    {
        return list.nodes[idx].data;
    }

    function getAmount(LinkedListStorage.LinkedList storage list, int256 idx) internal view returns (uint256) {
        return list.nodes[idx].data.amount;
    }

    function getMaker(LinkedListStorage.LinkedList storage list, int256 idx) internal view returns (address) {
        return list.nodes[idx].data.maker;
    }

    function getOrderID(LinkedListStorage.LinkedList storage list, int256 idx) internal view returns (uint256) {
        return list.nodes[idx].data.orderID;
    }

    function getTimestamp(LinkedListStorage.LinkedList storage list, int256 idx) internal view returns (uint256) {
        return list.nodes[idx].data.timestamp;
    }

    /**
     * @dev Number of nodes inserted so far (next index).
     */
    function size(LinkedListStorage.LinkedList storage list) internal view returns (uint256) {
        return uint256(list.count);
    }
}
