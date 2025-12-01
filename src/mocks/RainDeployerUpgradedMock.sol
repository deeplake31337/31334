// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {RainDeployer} from "../RainDeployer.sol";
import {RainPool} from "../RainPool.sol";

contract RainPoolUpgraded {
    constructor() {}
}

contract RainDeployerUpgraded is RainDeployer {
    uint256 public dummyValue;

    function setDummy() public returns (address) {
        dummyValue = 1;
        RainPoolUpgraded pool = new RainPoolUpgraded();
        return address(pool);
    }
}
