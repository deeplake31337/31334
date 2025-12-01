// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IRainDeployer
 * @notice Interface for the RainDeployer contract.
 */
interface IRainDeployer {
    /* ========================== STRUCTS ======================================= */

    /**
     * @notice Struct to define parameters for creating a RainPool.
     * @param isPublic Indicates whether the pool is public or private.
     * @param resolverIsAI Indicates whether the owner is the pool resolver or not.
     * @param poolOwner The address of the pool owner.
     * @param startTime The timestamp when the pool starts.
     * @param endTime The timestamp when the pool ends.
     * @param numberOfOptions The total number of options available in the pool.
     * @param oracleEndTime The timestamp when oracle results should be finalized.
     * @param ipfsUri The IPFS URI containing metadata for the pool.
     * @param initialLiquidity The amount of initial liquidity added to the pool.
     * @param liquidityPercentages An array representing the percentage allocation of liquidity to each option.
     * @param poolResolver Address of the pool resolver
     */
    struct Params {
        bool isPublic;
        bool resolverIsAI;
        address poolOwner;
        uint256 startTime;
        uint256 endTime;
        uint256 numberOfOptions;
        uint256 oracleEndTime;
        string ipfsUri;
        uint256 initialLiquidity;
        uint256[] liquidityPercentages;
        address poolResolver;
    }

    /* =============================  EVENTS ==================================== */

    /**
     * @notice Emitted when a new pool is created.
     * @param poolAddress The address of the newly created pool.
     * @param poolCreator The address of the pool creator.
     * @param uri The IPFS URI containing pool metadata.
     */
    event PoolCreated(
        address indexed poolAddress,
        address indexed poolCreator,
        string uri
    );

    /* ============================= ERRORS ================================= */

    /**
     * @dev Thrown when an action is attempted by an address that is not a created pool.
     */
    error OnlyCreatedPool();

    /**
     * @dev Thrown when the address is not valid.
     */
    error InvalidAddress();

    /* ============================= FUNCTIONS ================================= */

    /**
     * @notice Returns the address of the Oracle Factory used for creating oracle contracts.
     * @dev This address is set during deployment and used for resolving results.
     * @return The address of the Oracle Factory contract.
     */
    function oracleFactoryAddress() external view returns (address);

    /**
     * @notice Returns the address of the base token used in the pools.
     * @dev The base token is the primary currency used for transactions within the platform.
     * @return The address of the base token contract.
     */
    function baseToken() external view returns (address);

    /**
     * @notice Returns the platform's designated address for receiving fees.
     * @dev All platform fees are transferred to this address.
     * @return The address where platform fees are collected.
     */
    function platformAddress() external view returns (address);

    /**
     * @notice Returns the address for the backend pool result resolver AI.
     * @return The address of the resolver AI.
     */
    function resolverAI() external view returns (address);

    /**
     * @notice Returns the total number of pools created.
     * @dev This value is incremented each time a new pool is deployed.
     * @return The total count of deployed pools.
     */
    function totalPools() external view returns (uint256);

    /**
     * @notice Returns the number of decimals of the base token.
     * @dev This is used to normalize token amounts within the platform.
     * @return The decimal precision of the base token.
     */
    function baseTokenDecimals() external view returns (uint256);

    /**
     * @notice Returns the liquidity fee percentage.
     * @dev The liquidity fee is applied to the total pool funds.
     * @return The liquidity fee percentage.
     */
    function liquidityFee() external view returns (uint256);

    /**
     * @notice Returns the platform fee percentage.
     * @dev This fee is deducted from the total pool funds as a platform charge.
     * @return The platform fee percentage.
     */
    function platformFee() external view returns (uint256);

    /**
     * @notice Returns the fixed fee charged for oracle services.
     * @dev This fee is applied for using an external oracle to resolve pool outcomes.
     * @return The fixed oracle service fee.
     */
    function oracleFixedFee() external view returns (uint256);

    /**
     * @notice Returns the fee percentage allocated to pool creators.
     * @dev Pool creators receive a percentage of the total pool funds as their share.
     * @return The creator fee percentage.
     */
    function creatorFee() external view returns (uint256);

    /**
     * @notice Returns the fee percentage allocated to result resolvers.
     * @dev This fee compensates external resolvers who determine the pool outcome.
     * @return The result resolver fee percentage.
     */
    function resultResolverFee() external view returns (uint256);

    /**
     * @notice Returns the address of the RainPool contract.
     * @dev This is the main contract used for creating pools.
     * @return The address of the RainFactory contract.
     */
    function rainFactory() external view returns (address);

    /**
     * @notice Returns the current pool index for a given user.
     * @dev Each user has a unique pool index that tracks their pool creations.
     * @param user The address of the user.
     * @return The current pool index associated with the user.
     */
    function currentIndex(address user) external view returns (uint256);

    /**
     * @notice Returns the address of a specific pool created by a user.
     * @dev This function allows retrieval of pools based on user address and index.
     * @param user The address of the pool creator.
     * @param index The index of the pool for the user.
     * @return The address of the user's pool at the specified index.
     */
    function userPools(
        address user,
        uint256 index
    ) external view returns (address);

    /**
     * @notice Returns the address of a pool based on its global index.
     * @dev Pools are assigned unique global indices when deployed.
     * @param index The global index of the pool.
     * @return The address of the pool at the specified index.
     */
    function allPools(uint256 index) external view returns (address);

    /**
     * @notice Checks if a given address corresponds to a deployed pool.
     * @dev This function verifies if a pool was created using the deployer contract.
     * @param pool The address of the pool to check.
     * @return True if the pool exists, false otherwise.
     */
    function createdPools(address pool) external view returns (bool);

    /**
     * @notice Returns the address of a pool based on its global index.
     * @return The address of the rain token.
     */
    function rainToken() external view returns (address);

    /**
     * @notice Returns the address of a pool based on its global index.
     * @return The address of the pool mainnet uniswap v3 swaprouter .
     */
    function swapRouter() external view returns (address);

    /**
     * @notice Initializes the Rain Deployer contract with required parameters.
     * @dev This function sets the core addresses and fee structures for the contract.
     * It should only be called once during contract deployment.
     * @param _rainFactory The address of the RainFactory contract.
     * @param _oracleFactoryAddress The address of the Oracle Factory contract.
     * @param _baseToken The address of the base token used for transactions.
     * @param _platformAddress The address where platform fees are collected.
     * @param _resolverAI The address of the pool result resolver AI.
     * @param _rainToken The address of the Rain Token.
     * @param _swapRouter The address of the uniswap v3 Swap Router.
     * @param _baseTokenDecimals The number of decimals of the base token.
     * @param _liquidityFee The percentage fee allocated for liquidity providers.
     * @param _platformFee The percentage fee collected by the platform.
     * @param _oracleFixedFee The fixed fee for using an oracle service.
     * @param _creatorFee The percentage fee allocated to pool creators.
     * @param _resultResolverFee The percentage fee paid to result resolvers.
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
    ) external;

    /**
     * @notice Creates a new RainPool contract instance with the given parameters.
     * @dev Deploys a new RainPool contract and transfers the necessary base tokens
     * for initial liquidity and oracle fees if applicable.
     * @param params A struct containing all required parameters for pool creation.
     * @return The address of the newly created RainPool contract.
     */
    function createPool(
        IRainDeployer.Params memory params
    ) external returns (address);

    /**
     * @notice Creates an external oracle for resolving a pool's outcome.
     * @dev This function deploys a new oracle via the oracle factory contract.
     * @param numberOfOracles The number of oracle nodes to be created.
     * @param oracleReward The total reward distributed among the oracle nodes.
     * @param fixedFee A fixed fee for oracle creation.
     * @param creator The address of the pool creator.
     * @param endTime The timestamp when the oracle's result should be finalized.
     * @param totalNumberOfOptions The number of possible outcomes the oracle will validate.
     * @param questionUri A reference URI (e.g., IPFS) containing the event details.
     * @return The address of the newly created oracle.
     */
    function createOracle(
        uint256 numberOfOracles,
        uint256 oracleReward,
        uint256 fixedFee,
        address creator,
        uint256 endTime,
        uint256 totalNumberOfOptions,
        string memory questionUri
    ) external returns (address);

    /* =========================== SETTERS ====================================== */

    function setRainToken(address newRainToken) external;

    function setSwapRouter(address newSwapRouter) external;

    /**
     * @notice Updates the address of the resolver AI EOA.
     * @dev Can only be called by the contract owner.
     * @param newResolverAI The new resolver AI EOA address.
     */
    function setResolverAI(address newResolverAI) external;

    /**
     * @notice Updates the address of the Oracle Factory contract.
     * @dev Can only be called by the contract owner.
     * @param newOracleFactoryAddress The new oracle factory address.
     */
    function setOracleFactoryAddress(address newOracleFactoryAddress) external;

    /**
     * @notice Updates the base token and its decimal precision.
     * @dev Can only be called by the contract owner.
     * @param newBaseToken The address of the new base token.
     * @param newBaseTokenDecimals The decimal precision of the new base token.
     */
    function setBaseToken(
        address newBaseToken,
        uint256 newBaseTokenDecimals
    ) external;

    /**
     * @notice Updates the fixed fee required for oracle creation.
     * @dev Can only be called by the contract owner.
     * @param newOracleFixedFee The new oracle fixed fee.
     */
    function setOracleFixedFee(uint256 newOracleFixedFee) external;

    /**
     * @notice Updates the fee allocated to pool creators.
     * @dev Can only be called by the contract owner.
     * @param newCreatorFee The new creator fee.
     */
    function setCreatorFee(uint256 newCreatorFee) external;

    /**
     * @notice Updates the fee allocated to the result resolver.
     * @dev Can only be called by the contract owner.
     * @param newResultResolverFee The new result resolver fee.
     */
    function setResultResolverFee(uint256 newResultResolverFee) external;

    /**
     * @notice Updates the platform's treasury address.
     * @dev Can only be called by the contract owner.
     * @param newPlatformAddress The new platform address.
     */
    function setPlatformAddress(address newPlatformAddress) external;

    /**
     * @notice Updates the liquidity fee percentage.
     * @dev Can only be called by the contract owner.
     * @param newLiquidityFee The new liquidity fee percentage.
     */
    function setLiquidityFee(uint256 newLiquidityFee) external;

    /**
     * @notice Updates the platform fee percentage.
     * @dev Can only be called by the contract owner.
     * @param newPlatformFee The new platform fee percentage.
     */
    function setPlatformFee(uint256 newPlatformFee) external;

    /**
     * @notice Updates the address of the RainFactory contract.
     * @dev Can only be called by the contract owner.
     * @param newRainFactory The new RainFactory address.
     */
    function setRainFactory(address newRainFactory) external;
}
