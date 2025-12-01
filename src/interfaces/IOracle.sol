// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IOracle {
    function createExternalSource(
        address caller,
        uint256 numberOfOracles,
        uint256 totalReward,
        uint256 fixedFee,
        address creator,
        uint256 endTime,
        uint256 numberOfOptions,
        string calldata externalSourceURI
    ) external returns (address);
}
