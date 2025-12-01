// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { _revert } from "./utils/Globals.sol";

import { IOracle } from "./interfaces/IOracle.sol";
import { IRainDeployer } from "./interfaces/IRainDeployer.sol";
import { IRainPool } from "./interfaces/IRainPool.sol";
import { IRainFactory } from "./interfaces/IRainFactory.sol";

/**
 * @title RainDeployer
 * @notice Provides functionality for deploying RainPools.
 */
contract RainDeployer is
    IRainDeployer,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /// @inheritdoc IRainDeployer
    uint256 public totalPools;

    /// @inheritdoc IRainDeployer
    mapping(address => uint256) public currentIndex;

    /// @inheritdoc IRainDeployer
    mapping(address => mapping(uint256 => address)) public userPools;

    /// @inheritdoc IRainDeployer
    mapping(uint256 => address) public allPools;

    /// @inheritdoc IRainDeployer
    mapping(address => bool) public createdPools;

    /// @inheritdoc IRainDeployer
    address public oracleFactoryAddress;

    /// @inheritdoc IRainDeployer
    address public baseToken;

    /// @inheritdoc IRainDeployer
    uint256 public baseTokenDecimals;

    /// @inheritdoc IRainDeployer
    address public platformAddress;

    /// @inheritdoc IRainDeployer
    address public resolverAI;

    /// @inheritdoc IRainDeployer
    uint256 public liquidityFee;

    /// @inheritdoc IRainDeployer
    uint256 public platformFee;

    /// @inheritdoc IRainDeployer
    uint256 public oracleFixedFee;

    /// @inheritdoc IRainDeployer
    uint256 public creatorFee;

    /// @inheritdoc IRainDeployer
    uint256 public resultResolverFee;

    /// @inheritdoc IRainDeployer
    address public rainFactory;

    /// @inheritdoc IRainDeployer
    address public rainToken;

    /// @inheritdoc IRainDeployer
    address public swapRouter;

    /* =============================== INITALIZER ====================================== */

    /**
     * @inheritdoc IRainDeployer
     */
    function initialize(
        address _rainFactory,
        address _oracleFactoryAddress,
        address _baseToken,
        address _platformAddress,
        address _resolverAI,
        address _rainToken,
        address _swapRouter,
        uint256 _baseTokenDecimals,
        uint256 _liquidityFee,
        uint256 _platformFee,
        uint256 _oracleFixedFee,
        uint256 _creatorFee,
        uint256 _resultResolverFee
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        if (
            _rainFactory == address(0) ||
            _oracleFactoryAddress == address(0) ||
            _baseToken == address(0) ||
            _platformAddress == address(0) ||
            _resolverAI == address(0)
        ) {
            _revert(InvalidAddress.selector);
        }

        rainFactory = _rainFactory;
        oracleFactoryAddress = _oracleFactoryAddress;
        baseToken = _baseToken;
        platformAddress = _platformAddress;
        resolverAI = _resolverAI;
        rainToken = _rainToken;
        swapRouter = _swapRouter;

        baseTokenDecimals = _baseTokenDecimals;
        liquidityFee = _liquidityFee;
        platformFee = _platformFee;
        oracleFixedFee = _oracleFixedFee;
        creatorFee = _creatorFee;
        resultResolverFee = _resultResolverFee;
    }

    /* =============================== FUNCTIONS ====================================== */

    /**
     * @inheritdoc IRainDeployer
     */
    function createPool(
        IRainDeployer.Params memory params
    ) public returns (address poolInstance) {
        IRainPool.Params memory poolParams = IRainPool.Params({
            initialLiquidity: params.initialLiquidity,
            liquidityPercentages: params.liquidityPercentages,
            isPublic: params.isPublic,
            resolverIsAI: params.resolverIsAI,
            deployerContract: address(this),
            baseToken: baseToken,
            baseTokenDecimals: baseTokenDecimals,
            poolOwner: params.poolOwner,
            platformAddress: platformAddress,
            resolver: params.isPublic && params.resolverIsAI
                ? resolverAI
                : params.poolResolver,
            rainToken: rainToken,
            swapRouter: swapRouter,
            startTime: params.startTime,
            endTime: params.endTime,
            numberOfOptions: params.numberOfOptions,
            platformFee: platformFee,
            liquidityFee: liquidityFee,
            creatorFee: creatorFee,
            resultResolverFee: resultResolverFee,
            oracleFixedFee: oracleFixedFee,
            oracleEndTime: params.oracleEndTime,
            ipfsUri: params.ipfsUri
        });

        poolInstance = IRainFactory(rainFactory).createPool(poolParams);
        IERC20(baseToken).safeTransferFrom(
            msg.sender,
            poolInstance,
            oracleFixedFee
        );

        // Minimum $`0 initial liquidity required
        if (params.initialLiquidity > 0) {
            IERC20(baseToken).safeTransferFrom(
                msg.sender,
                poolInstance,
                params.initialLiquidity
            );
        }
        userPools[msg.sender][currentIndex[msg.sender]] = poolInstance;
        ++currentIndex[msg.sender];
        allPools[totalPools] = poolInstance;
        totalPools++;
        createdPools[poolInstance] = true;
        emit PoolCreated(poolInstance, msg.sender, params.ipfsUri);
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function createOracle(
        uint256 numberOfOracles,
        uint256 oracleReward,
        uint256 fixedFee,
        address creator,
        uint256 endTime,
        uint256 totalNumberOfOptions,
        string memory questionUri
    ) public returns (address) {
        if (createdPools[msg.sender] != true) {
            _revert(IRainDeployer.OnlyCreatedPool.selector);
        }
        IERC20(baseToken).approve(
            oracleFactoryAddress,
            oracleReward + fixedFee
        );
        address oracle = IOracle(oracleFactoryAddress).createExternalSource(
            address(this),
            numberOfOracles,
            oracleReward,
            fixedFee,
            creator,
            endTime,
            totalNumberOfOptions,
            questionUri
        );
        return oracle;
    }

    /* =============================== SETTERS ====================================== */

    function setRainToken(address newRainToken) external onlyOwner {
        if (newRainToken == rainToken || newRainToken == address(0)) {
            _revert(InvalidAddress.selector);
        }
        rainToken = newRainToken;
    }

    function setSwapRouter(address newSwapRouter) external onlyOwner {
        if (newSwapRouter == swapRouter || newSwapRouter == address(0)) {
            _revert(InvalidAddress.selector);
        }
        swapRouter = newSwapRouter;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setResolverAI(address newResolverAI) external onlyOwner {
        if (newResolverAI == resolverAI || newResolverAI == address(0)) {
            _revert(InvalidAddress.selector);
        }
        resolverAI = newResolverAI;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setOracleFactoryAddress(
        address newOracleFactoryAddress
    ) public onlyOwner {
        oracleFactoryAddress = newOracleFactoryAddress;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setBaseToken(
        address newBaseToken,
        uint256 newBaseTokenDecimals
    ) public onlyOwner {
        baseToken = newBaseToken;
        baseTokenDecimals = newBaseTokenDecimals;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setOracleFixedFee(uint256 newOracleFixedFee) public onlyOwner {
        oracleFixedFee = newOracleFixedFee;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setCreatorFee(uint256 newCreatorFee) public onlyOwner {
        creatorFee = newCreatorFee;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setResultResolverFee(
        uint256 newResultResolverFee
    ) public onlyOwner {
        resultResolverFee = newResultResolverFee;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setPlatformAddress(address newPlatformAddress) public onlyOwner {
        platformAddress = newPlatformAddress;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setLiquidityFee(uint256 newLiquidityFee) public onlyOwner {
        liquidityFee = newLiquidityFee;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setPlatformFee(uint256 newPlatformFee) public onlyOwner {
        platformFee = newPlatformFee;
    }

    /**
     * @inheritdoc IRainDeployer
     */
    function setRainFactory(address newRainFactory) public onlyOwner {
        rainFactory = newRainFactory;
    }

    /* ================================ INTERNAL FUNCTION ================================= */

    /**
     * @notice Authorizes the upgrade of the contract to a new implementation.
     * @dev This function is required for UUPS (Upgradeable Proxy) pattern.
     *      Only the contract owner can authorize an upgrade.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /// @dev Upgrade slot variable.
    uint256[47] private __gap;
}
