// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IQuestion {
    /**
     * @dev Struct representing an external source.
     * @member noOfOracles The number of oracles involved in the external source.
     * @member rewardPerOracle The reward allocated for each oracle.
     * @member loyaltyFee The loyalty fee associated with the external source.
     * @member totalExternalSourceCost The total cost of the external source.
     * @member totalOracleReward The total reward for all oracles.
     * @member startTime The start time of the external source.
     * @member endTime The end time of the external source.
     * @member numberOfOptions The total number of options available for the external source.
     * @member externalSourceURI The URI containing the external source details.
     * @member creator The address of the creator of the external source.
     */
    struct ExternalSourceInfo {
        uint256 noOfOracles;
        uint256 rewardPerOracle;
        uint256 loyaltyFee;
        uint256 totalExternalSourceCost;
        uint256 totalOracleReward;
        uint256 startTime;
        uint256 endTime;
        uint256 numberOfOptions;
        string externalSourceURI;
        address creator;
    }

    function winnerOption() external returns (uint256);

    function timeExtended() external returns (uint256);

    function winnerFinalized() external returns (bool);

    function getExternalSource()
        external
        view
        returns (ExternalSourceInfo memory);

    function calculateWinnerReadOnly()
        external
        view
        returns (uint256 option, uint256 reward);

    function refund() external;
}
