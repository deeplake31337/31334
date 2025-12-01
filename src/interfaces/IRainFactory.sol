// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IRainPool } from "./IRainPool.sol"; // Ensure this path is correct

/// @title IRainFactory
/// @notice Interface for the RainFactory responsible for creating new RainPool instances.
interface IRainFactory {
    /**
     * @notice Creates a new RainPool contract with the given parameters.
     * @dev The caller must ensure that the `poolParams` provided are valid and conform to the expected structure.
     * @param poolParams The configuration parameters used to initialize the RainPool.
     * @return The address of the newly created RainPool contract.
     */
    function createPool(
        IRainPool.Params memory poolParams
    ) external returns (address);
}
