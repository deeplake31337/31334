// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOracle.sol";
import "../interfaces/IQuestion.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OracleMock is IOracle, IQuestion {
    using SafeERC20 for ERC20;

    ExternalSourceInfo private _externalSourceInstance;

    bool winnerReadOnly;
    bool finalized = false;

    address baseToken;

    uint256 winner = 0;
    uint256 public timeExtended;

    constructor(address _baseToken) {
        baseToken = _baseToken;
    }

    function createExternalSource(
        address caller,
        uint256 numberOfOracles,
        uint256 totalReward,
        uint256 fixedFee,
        address creator,
        uint256 endTime,
        uint256 numberOfOptions,
        string calldata externalSourceURI
    ) external returns (address) {
        ERC20(baseToken).safeTransferFrom(
            caller,
            address(this),
            totalReward + fixedFee
        );

        _externalSourceInstance.creator = creator;
        _externalSourceInstance.loyaltyFee = totalReward;
        _externalSourceInstance.totalOracleReward = fixedFee;
        _externalSourceInstance.endTime = endTime;

        return address(this);
    }

    function winnerOption() external view returns (uint256) {
        return winner;
    }

    function winnerFinalized() external view returns (bool) {
        return finalized;
    }

    /// @notice Function to get the external source details.
    function getExternalSource()
        external
        view
        returns (ExternalSourceInfo memory)
    {
        return _externalSourceInstance;
    }

    function extendTime(uint256 newEndTime) external {
        _externalSourceInstance.endTime = newEndTime;
        ++timeExtended;
    }

    function toggleWinnerReadOnly() external {
        winnerReadOnly = !winnerReadOnly;
    }

    function selectWinnerMock(uint256 option) external {
        winner = option;
        finalized = true;
    }

    function calculateWinnerReadOnly()
        external
        view
        returns (uint256, uint256)
    {
        if (winnerReadOnly) {
            revert();
        }
        return (1, 2);
    }

    function refund() external {
        if (msg.sender == _externalSourceInstance.creator) {
            ERC20(baseToken).safeTransfer(
                msg.sender,
                _externalSourceInstance.totalOracleReward +
                    _externalSourceInstance.loyaltyFee
            );
        } else {
            revert();
        }
    }
}
