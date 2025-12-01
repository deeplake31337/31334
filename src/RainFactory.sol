// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {RainPool, IRainPool} from "./RainPool.sol";

/// @title RainFactory
/// @notice Factory contract for deploying new RainPool instances.
/// @dev This contract allows external callers to deploy new RainPool contracts using specified initialization parameters.
contract RainFactory {
    /**
     * @notice Deploys a new RainPool contract with the provided parameters.
     * @dev The caller should ensure that `poolParams` is properly constructed and validated off-chain or within the RainPool constructor.
     * @param poolParams The parameters used to initialize the RainPool instance.
     * @return The address of the newly deployed RainPool contract.
     */
    function createPool(IRainPool.Params memory poolParams) external returns (address) {
        RainPool instance = new RainPool(poolParams);
        return address(instance);
    }
}
