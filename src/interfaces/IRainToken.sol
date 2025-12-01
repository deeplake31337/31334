// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

interface IRainToken {
    /**
     * @notice This function burns the amount of tokens from the caller.
     * @param amount The amount of tokens to be burned.
     */
    function burn(uint256 amount) external;
}
