// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

/**
 * @title IRainPool
 * @notice Interface for the RainPool contract.
 */
interface IRainPool {
    /* ============================= STRUCTS ====================================== */

    /**
     * @title Params
     * @dev Struct for the params of a rain pool.
     * @notice This struct holds all the necessary information for a rain pool.
     * @param initialLiquidity The initial liquidity amount deposited into the pool, distributed among options.
     * @param liquidityPercentages Percentage distribution of `initialLiquidity` among different options, must sum to 100.
     * @param isPublic Determines if the pool is public (`true`) or private (`false`).
     * @param resolverIsAI Determines if the owner of the pool is also the resolver of the pool.
     * @param deployerContract The address of the deployerContract that created the pool.
     * @param baseToken The address of the base token used in the pool for voting and liquidity contributions.
     * @param poolOwner The address of the owner who controls the pool.
     * @param platformAddress The address of the platform responsible for managing the pool.
     * @param resolver The address of the resolver responsible for selecting the winning option.
     * @param rainToken The address of the Rain token.
     * @param swapRouter The address of the uniswap v3 swap router on mainnet.
     * @param baseTokenDecimals The number of decimals used for the base token.
     * @param startTime The timestamp when the pool becomes active.
     * @param endTime The timestamp when the pool ends.
     * @param numberOfOptions The total number of options available for voting.
     * @param platformFee The fee percentage taken by the platform (e.g., 2.5% is represented as 25).
     * @param liquidityFee The fee percentage allocated to liquidity providers (e.g., 1.4% is represented as 14).
     * @param creatorFee The fee percentage given to the pool creator (e.g., 1% is represented as 10).
     * @param resultResolverFee The fee percentage for resolving the pool results (e.g., 0.1% is represented as 1).
     * @param oracleFixedFee The fixed fee charged for using an oracle.
     * @param oracleEndTime The timestamp when the oracle resolution period ends.
     * @param ipfsUri The IPFS URI storing metadata or additional pool-related information.
     */
    struct Params {
        uint256 initialLiquidity;
        uint256[] liquidityPercentages;
        bool isPublic;
        bool resolverIsAI;
        address deployerContract;
        address baseToken;
        address poolOwner;
        address platformAddress;
        address resolver;
        address rainToken;
        address swapRouter;
        uint256 baseTokenDecimals;
        uint256 startTime;
        uint256 endTime;
        uint256 numberOfOptions;
        uint256 platformFee;
        uint256 liquidityFee;
        uint256 creatorFee;
        uint256 resultResolverFee;
        uint256 oracleFixedFee;
        uint256 oracleEndTime;
        string ipfsUri;
    }

    /// @notice Represents whether an order exists and its index in the linked list.
    struct OrderExists {
        /// @notice True if the order exists in the order book.
        bool exists;
        /// @notice Index of the order in the linked list.
        int256 index;
    }

    /// @notice Represents a dispute struct that records the opener and the winner.
    struct Dispute {
        /// @notice The fee paid by the disputer.
        uint256 disputeFee;
        /// @notice The winner chosen by the AI.
        uint256 disputedWinner;
        /// @notice The address of the disputer.
        address disputer;
        /// @notice The address of the orignal resolver.
        address resolver;
    }

    /* ============================= EVENTS ====================================== */

    /**
     * @dev Emitted when vote synchronization occurs.
     * @param pair The identifier of the pair being synchronized.
     * @param optionVotes The number of votes for a specific option.
     * @param allVotes The total number of votes across all options.
     */
    event Sync(uint256 pair, uint256 optionVotes, uint256 allVotes);

    /**
     * @dev Emitted when a user enters an option position.
     * @param option The identifier of the selected option.
     * @param baseAmount The amount of base asset used to enter the option.
     * @param optionAmount The amount of option asset received.
     * @param wallet The address of the user entering the option.
     */
    event EnterOption(
        uint256 option,
        uint256 baseAmount,
        uint256 optionAmount,
        address indexed wallet
    );

    /**
     * @dev Emitted when a user provides liquidity.
     * @param baseAmount The amount of base asset supplied as liquidity.
     * @param wallet The address of the user providing liquidity.
     */
    event EnterLiquidity(uint256 baseAmount, address indexed wallet);

    /**
     * @dev Emitted when the pool is closed or its status is updated.
     * @param poolStatus The new status of the pool (true if open, false if closed).
     */
    event ClosePool(bool poolStatus);

    /**
     * @notice Emitted when a winning option is finalized for the pool.
     * @param winnerOption The option number that has been chosen as the winner.
     * @param platformShare The amount of base tokens allocated to the platform.
     * @param liquidityShare The amount of base tokens allocated to liquidity providers.
     * @param winningShare The amount of base tokens distributed among users who voted for the winning option.
     */
    event ChooseWinner(
        uint256 winnerOption,
        uint256 platformShare,
        uint256 liquidityShare,
        uint256 winningShare
    );

    /**
     * @dev Emitted when a user claims their rewards.
     * @param wallet The address of the user claiming the rewards.
     * @param winnerOption The identifier of the winning option.
     * @param liquidityReward The portion of the reward allocated from liquidity.
     * @param reward The user's individual reward.
     * @param totalReward The total reward received, including all shares.
     */
    event Claim(
        address indexed wallet,
        uint256 winnerOption,
        uint256 liquidityReward,
        uint256 reward,
        uint256 totalReward
    );

    /**
     * @dev Emitted when a new oracle contract is created.
     * @param creatorContract The address of the contract that created the oracle.
     * @param createdContract The address of the newly created oracle contract.
     */
    event CreateOracle(
        address indexed creatorContract,
        address indexed createdContract
    );

    /**
     * @notice Emitted when the platform claims its share of the pool funds.
     * @param wallet The address of the platform wallet receiving the funds.
     * @param amount The amount claimed by the platform.
     */
    event PlatformClaim(address indexed wallet, uint256 amount);

    /**
     * @notice Emitted when the creator of the pool claims their share.
     * @param wallet The address of the pool creator.
     * @param amount The amount claimed by the creator.
     */
    event CreatorClaim(address indexed wallet, uint256 amount);

    /**
     * @notice Emitted when the resolver claims their share for resolving the outcome.
     * @param wallet The address of the resolver.
     * @param amount The amount claimed by the resolver.
     */
    event ResolverClaim(address indexed wallet, uint256 amount);

    /**
     * @dev Emitted when a new oracle contract is created.
     * @param resolver The address of the resolver.
     */
    event ResolverSet(address indexed resolver);

    /**
     * @notice Emitted when a new sell order is placed.
     * @param orderOption The option the order is placed for.
     * @param orderPrice The price at which the option is being sold.
     * @param orderAmount The number of option tokens being sold.
     * @param orderID A unique identifier for the order.
     * @param maker The address of the user placing the order.
     */
    event PlaceSellOrder(
        uint256 orderOption,
        uint256 orderPrice,
        uint256 orderAmount,
        uint256 orderID,
        address indexed maker
    );

    /**
     * @notice Emitted when a new sell order is placed.
     * @param orderOption The option the order is placed for.
     * @param orderPrice The price at which the option is being bought.
     * @param orderAmount The number of option tokens being bought.
     * @param orderID A unique identifier for the order.
     * @param maker The address of the user placing the order.
     */
    event PlaceBuyOrder(
        uint256 orderOption,
        uint256 orderPrice,
        uint256 orderAmount,
        uint256 orderID,
        address indexed maker
    );

    /**
     * @notice Emitted when a sell order is fulfilled and the option tokens are bought.
     * @param orderOption The option being purchased.
     * @param orderPrice The price at which the order was fulfilled.
     * @param optionAmount The number of option tokens bought.
     * @param baseAmount The amount of base asset used to buy the option tokens.
     * @param orderID The unique identifier of the fulfilled order.
     * @param maker The address of the user who placed the sell order.
     * @param taker The address of the user who bought the option tokens.
     */
    event ExecuteSellOrder(
        uint256 orderOption,
        uint256 orderPrice,
        uint256 optionAmount,
        uint256 baseAmount,
        uint256 orderID,
        address indexed maker,
        address indexed taker
    );

    /**
     * @notice Emitted when a buy order is fulfilled and the option tokens are bought.
     * @param orderOption The option being purchased.
     * @param orderPrice The price at which the order was fulfilled.
     * @param optionAmount The number of option votes bought.
     * @param baseAmount The amount of base asset used to buy the option tokens.
     * @param orderID The unique identifier of the fulfilled order.
     * @param maker The address of the user who placed the buy order.
     * @param taker The address of the user who sold the option votes.
     */
    event ExecuteBuyOrder(
        uint256 orderOption,
        uint256 orderPrice,
        uint256 optionAmount,
        uint256 baseAmount,
        uint256 orderID,
        address indexed maker,
        address indexed taker
    );

    /**
     * @notice Emitted when a sell order is cancelled.
     * @param orderOption The option associated with the cancelled order.
     * @param orderAmount The number of shares that were listed in the cancelled order.
     * @param orderPrice The price at which the order was listed.
     * @param orderID The unique identifier for the cancelled order.
     * @param orderCreator The address of the user who created and cancelled the order.
     */
    event CancelSellOrder(
        uint256 orderOption,
        uint256 orderAmount,
        uint256 orderPrice,
        uint256 orderID,
        address indexed orderCreator
    );

    /**
     * @notice Emitted when a buy order is cancelled.
     * @param orderOption The option associated with the cancelled order.
     * @param orderAmount The number of base tokens that were listed in the cancelled order.
     * @param orderPrice The price at which the order was listed.
     * @param orderID The unique identifier for the cancelled order.
     * @param orderCreator The address of the user who created and cancelled the order.
     */
    event CancelBuyOrder(
        uint256 orderOption,
        uint256 orderAmount,
        uint256 orderPrice,
        uint256 orderID,
        address indexed orderCreator
    );

    /**
     * @dev Emittted when a Dispute is opened.
     * @param caller The address of the function caller.
     * @param currentWinner The current winner of the pool.
     * @param disputeFee The fee paid by the user if it's not the resolver for dispute.
     */
    event OpenDispute(
        address indexed caller,
        uint256 currentWinner,
        uint256 disputeFee
    );

    /**
     * @dev Emiited when rain tokens are burned.
     * @param amountBurned The amount of rain tokens burned.
     */
    event RainTokenBurned(uint256 amountBurned);

    /* ========================== ERRORS ======================================= */

    /**
     * @dev Error thrown when no token is set.
     */
    error NoTokenSet();

    /**
     * @dev Error thrown when no owner is set.
     */
    error NoOwnerSet();

    /**
     * @dev Error thrown when the start time of a sale has already ended.
     */
    error StartTimeEnded();

    /**
     * @dev Error thrown when the end time is less than the start time.
     */
    error EndTImeLessThanStartTime();

    /**
     * @dev Error thrown when fewer than two options are provided.
     */
    error MinimumOptionsShouldBeTwo();

    /**
     * @dev Error thrown when the sale is not live.
     */
    error SaleNotLive();

    /**
     * @dev Error thrown when the sale is still live.
     */
    error SaleStillLive();

    /**
     * @dev Error thrown when no platform is set.
     */
    error NoPlatformSet();

    /**
     * @dev Error thrown when only the owner can perform the action.
     */
    error OnlyOwner();

    /**
     * @dev Error thrown when only authorized users can perform the action.
     */
    error OnlyAuthority();

    /**
     * @dev Error thrown when only resolver users can perform the action.
     */
    error OnlyResolver();

    /**
     * @dev Error thrown when the pool is closed.
     */
    error PoolClosed();

    /**
     * @dev Error thrown when the pool is open.
     */
    error PoolOpen();

    /**
     * @dev Error thrown when an action has already been claimed.
     */
    error AlreadyClaimed();

    /**
     * @dev Error thrown when the user is ineligible to claim.
     */
    error IneligibleToClaim();

    /**
     * @dev Error thrown when the pool is not yet closed.
     */
    error PoolNotClosed();

    /**
     * @dev Error thrown when the winner option is out of the valid range.
     */
    error WinnerOutOfBound();

    /**
     * @dev Error thrown when the liquidity percentage is invalid.
     */
    error InvalidLiquidityPercentage();

    /**
     * @dev Error thrown when the initial liquidity amount is invalid.
     */
    error InvalidInitialLiquidity();

    /**
     * @dev Error thrown when the amount is not sufficient.
     */
    error InsufficientAmount();

    /**
     * @dev Error thrown if the provided option is not valid.
     */
    error InvalidOption();

    /**
     * @dev Error thrown if the provided price is not within the allowed range or format.
     */
    error InvalidPrice();

    /**
     * @dev Error thrown if the provided amount is zero or otherwise considered invalid.
     */
    error InvalidAmount();

    /**
     * @dev Error thrown if the number of options exceeds the maximum allowed limit.
     */
    error MaximumOptionsExceeded();

    /**
     * @dev Thrown when the user does not have enough votes to complete the action.
     */
    error InsufficientUserVotes();

    /**
     * @dev Thrown when a caller tries to cancel an order they did not create.
     */
    error CallerNotOrderPlacer();

    /**
     * @dev Thrown when the caller is not the part of the pool.
     */
    error InvalidCaller();

    /**
     * @dev Thrown when a dispute is already opened.
     */
    error DisputeAlreadyOpened();

    /**
     * @dev Thrown when an order with the given ID does not exist in the system.
     */
    error OrderDoesNotExist();

    /**
     * @dev Thrown when trying to place an order that already exists with the given ID.
     */
    error OrderAlreadyExists();

    /**
     * @dev Thrown when trying to buy an order that does not exist or if the orderBook linked list is not initalized.
     */
    error LinkedListNotInitalized();

    /**
     * @dev Thrown when the array length does not match.
     */
    error ArrayLengthMismatch();

    /**
     * @dev Thrown when the winner has already been decided.
     */
    error WinnerAlreadyFinalized();

    /**
     * @dev Thrown when the user tries to claim their rewards with existing sell orders.
     */
    error UserSellOrderExist();

    /**
     * @dev Thrown when the user tries to claim their rewards with existing Buy orders.
     */
    error UserBuyOrderExist();

    /**
     * @dev Thrown when the pool is in an invalid state for the attempted operation.
     */
    error InvalidPoolState();

    /**
     * @dev Thrown when the specified end price is below the allowed minimum.
     */
    error EndPriceTooLow();

    /**
     * @dev Thrown when the specified end price exceeds the allowed maximum.
     */
    error EndPriceTooHigh();

    /**
     * @dev Thrown when the attempted increase is not necessary or is redundant.
     */
    error NoIncreaseNeeded();

    /**
     * @dev Thrown when a user tries to open a dispute after the dispute window has ended.
     */
    error DisputeWindowEnded();

    /**
     * @dev Thrown when a user tries to claim before the dispute window has ended for a public pool.
     */
    error DisputeWindowNotEnded();

    /**
     * @dev Error thrown when the oracle has not been finalized.
     */
    error OracleNotFinalized();

    /**
     * @dev Error thrown when the oracle has ended the voting and the winner is still `0`.
     */
    error VotingEnded();

    /**
     * @dev Error thrown when the oracle fixed fee is `0`.
     */
    error InvalidOracleFixedFee();

    /* ============================ FUNCTIONS ===================================== */

    /**
     * @notice Returns the price magnification factor.
     * @return The price magnification factor as a uint256 value.
     */
    function PRICE_MAGNIFICATION() external view returns (uint256);

    /**
     * @notice Returns the fee magnification factor.
     * @return The fee magnification factor as a uint256 value.
     */
    function FEE_MAGNIFICATION() external view returns (uint256);

    /**
     * @notice Returns whether the pool is public.
     * @return True if the pool is public, false if private.
     */
    function isPublic() external view returns (bool);

    /**
     * @notice Returns whether the owner is the resolver or not.
     * @return True if the owner is the resolver, false if not.
     */
    function resolverIsAI() external view returns (bool);

    /**
     * @notice Returns whether the pool is disputed or not.
     * @return True if the pool is disputed, false if not.
     */
    function isDisputed() external view returns (bool);

    /**
     * @notice Returns whether the first claim has been made.
     * @return True if the claim has been made, false if not.
     */
    function firstClaim() external view returns (bool);

    /**
     * @notice Returns whether the pool has been finalized.
     * @return True if the pool is finalized, false if not.
     */
    function poolFinalized() external view returns (bool);

    /**
     * @notice Returns the IPFS URI associated with the pool.
     * @return The IPFS URI as a string.
     */
    function ipfsUri() external view returns (string memory);

    /**
     * @notice Returns the address of the contract factory.
     * @return The factory address.
     */
    function FACTORY() external view returns (address);

    /**
     * @notice Returns the address of the rain token.
     * @return The rain token address.
     */
    function rainToken() external view returns (address);

    /**
     * @notice Returns the address of the base token used in the pool.
     * @return The base token address.
     */
    function baseToken() external view returns (address);

    /**
     * @notice Returns the address of the pool owner.
     * @return The pool owner's address.
     */
    function poolOwner() external view returns (address);

    /**
     * @notice Returns the address of the platform.
     * @return The platform address.
     */
    function platformAddress() external view returns (address);

    /**
     * @notice Returns the address of the resolver.
     * @return The resolver address.
     */
    function resolver() external view returns (address);

    /**
     * @notice Returns the total number of votes.
     * @return The total votes as a uint256 value.
     */
    function allVotes() external view returns (uint256);

    /**
     * @notice Returns the total funds in the pool.
     * @return The total funds as a uint256 value.
     */
    function allFunds() external view returns (uint256);

    /**
     * @notice Returns the share of the winning pool.
     * @return The winning pool share as a uint256 value.
     */
    function winningPoolShare() external view returns (uint256);

    /**
     * @notice Returns the share of liquidity.
     * @return The liquidity share as a uint256 value.
     */
    function liquidityShare() external view returns (uint256);

    /**
     * @notice Returns the share allocated to the platform.
     * @return The platform share as a uint256 value.
     */
    function platformShare() external view returns (uint256);

    /**
     * @notice Returns the share allocated to the creator.
     * @return The creator share as a uint256 value.
     */
    function creatorShare() external view returns (uint256);

    /**
     * @notice Returns the share allocated to the resolver.
     * @return The resolver share as a uint256 value.
     */
    function resolverShare() external view returns (uint256);

    /**
     * @notice Returns the total liquidity in the pool.
     * @return The total liquidity as a uint256 value.
     */
    function totalLiquidity() external view returns (uint256);

    /**
     * @notice Returns the start time of the pool.
     * @return The start time as a uint256 timestamp.
     */
    function startTime() external view returns (uint256);

    /**
     * @notice Returns the end time of the pool.
     * @return The end time as a uint256 timestamp.
     */
    function endTime() external view returns (uint256);

    /**
     * @notice Returns the number of options in the pool.
     * @return The number of options as a uint256 value.
     */
    function numberOfOptions() external view returns (uint256);

    /**
     * @notice Returns the winner option.
     * @return The winner option ID as a uint256 value.
     */
    function winner() external view returns (uint256);

    /**
     * @notice Returns the platform fee.
     * @return The platform fee as a uint256 value.
     */
    function platformFee() external view returns (uint256);

    /**
     * @notice Returns the liquidity fee.
     * @return The liquidity fee as a uint256 value.
     */
    function liquidityFee() external view returns (uint256);

    /**
     * @notice Returns the creator fee.
     * @return The creator fee as a uint256 value.
     */
    function creatorFee() external view returns (uint256);

    /**
     * @notice Returns the result resolver fee.
     * @return The result resolver fee as a uint256 value.
     */
    function resultResolverFee() external view returns (uint256);

    /**
     * @notice Returns the fixed fee for the oracle.
     * @return The oracle fixed fee as a uint256 value.
     */
    function oracleFixedFee() external view returns (uint256);

    /**
     * @notice Returns the end time for the oracle.
     * @return The oracle end time as a uint256 timestamp.
     */
    function oracleEndTime() external view returns (uint256);

    /**
     * @notice Returns the total number of orders that have been added.
     * @return The number of added orders.
     */
    function ordersAdded() external view returns (uint256);

    /**
     * @notice Returns the total number of orders that have been removed.
     * @return The number of removed orders.
     */
    function ordersRemoved() external view returns (uint256);

    /**
     * @notice Returns the deciamls for the base token.
     */
    function baseTokenDecimals() external view returns (uint256);

    /**
     * @notice Returns the constant tick spacing used for price granularity.
     * @return The tick spacing value.
     */
    function TICK_SPACING() external view returns (uint256);

    /**
     * @notice Returns the constant tick spacing used for price granularity.
     * @return The tick spacing value.
     */
    function ORDER_EXECUTION_FEE() external view returns (uint256);

    /**
     * @notice Gets the discount percentage on fee if totalFunds in the pool are greater or equal to tier one.
     * @dev Represents a 90% discount on fee.
     * @return The discount on fee percentage for tier one.
     */
    function DISCOUNT_FEE_TIER_ONE() external view returns (uint256);

    /**
     * @notice Gets the discount percentage on fee if totalFunds in the pool are greater or equal to tier two.
     * @dev Represents a 75% discount on fee.
     * @return The discount on fee percentage for tier two.
     */
    function DISCOUNT_FEE_TIER_TWO() external view returns (uint256);

    /**
     * @notice Gets the discount percentage on fee if totalFunds in the pool are greater or equal to tier three.
     * @dev Represents a 60% discount on fee.
     * @return The discount on fee percentage for tier three.
     */
    function DISCOUNT_FEE_TIER_THREE() external view returns (uint256);

    /**
     * @notice The time during which a user cannot open a dispute.
     * @dev Represents the time in seconds.
     * @return The dispute window time.
     */
    function DISPUTE_WINDOW() external view returns (uint256);

    /**
     * @notice Gets the amount threshold required for tier one.
     * @dev Pool must hold at least 500 base tokens to qualify.
     * @return The minimum token amount required for tier one fee discount.
     */
    function AMOUNT_TIER_ONE() external view returns (uint256);

    /**
     * @notice Gets the amount threshold required for tier two.
     * @dev Pool must hold at least 100 base tokens to qualify.
     * @return The minimum token amount required for tier two fee discount.
     */
    function AMOUNT_TIER_TWO() external view returns (uint256);

    /**
     * @notice Gets the amount threshold required for tier three.
     * @dev Pool must hold at least 1500 base tokens to qualify.
     * @return The minimum token amount required for tier three fee discount.
     */
    function AMOUNT_TIER_THREE() external view returns (uint256);

    /**
     * @notice Returns the number of votes a user has for a specific option.
     * @param optionId The ID of the option.
     * @param user The address of the user.
     * @return The number of votes the user has for the option.
     */
    function userVotes(
        uint256 optionId,
        address user
    ) external view returns (uint256);

    /**
     * @notice Returns the linked list of sell orders for a specific option and price.
     * @param option The option index.
     * @param price The price point.
     * @return The linked list of sell orders.
     */
    function sellOrders(
        uint256 option,
        uint256 price
    ) external view returns (int256, int256, int256, bool);

    /**
     * @notice Returns the linked list of buy orders for a specific option and price.
     * @param option The option index.
     * @param price The price point.
     * @return The linked list of buy orders.
     */
    function buyOrders(
        uint256 option,
        uint256 price
    ) external view returns (int256, int256, int256, bool);

    /**
     * @notice Returns whether a specific order exists for a given option, price, and order ID.
     * @param option The option index.
     * @param price The price point.
     * @param orderID The ID of the order.
     * @return The Struct containing order existence details.
     */
    function orderBook(
        uint256 option,
        uint256 price,
        uint256 orderID
    ) external view returns (bool, int256);

    /**
     * @notice Returns the amount of liquidity a user has provided.
     * @param user The address of the user.
     * @return The amount of liquidity the user has provided.
     */
    function userLiquidity(address user) external view returns (uint256);

    /**
     * @notice Returns whether a user has already claimed their rewards.
     * @param user The address of the user.
     * @return True if the user has claimed, false otherwise.
     */
    function claimed(address user) external view returns (bool);

    /**
     * @notice Returns the total number of shares for a specific option.
     * @param optionId The ID of the option.
     * @return The total number of votes for the option.
     */
    function totalVotes(uint256 optionId) external view returns (uint256);

    /**
     * @notice Returns the total amount of funds for a specific option.
     * @param optionId The ID of the option.
     * @return The total amount of funds for the option.
     */
    function totalFunds(uint256 optionId) external view returns (uint256);

    /**
     * @notice Returns the total number of sell orders for a user.
     * @param user The address of the user.
     * @return The total number of orders for the user.
     */
    function userActiveSellOrders(address user) external view returns (uint256);

    /**
     * @notice Returns the total number of buy orders for a user.
     * @param user The address of the user.
     * @return The total number of orders for the user.
     */
    function userActiveBuyOrders(address user) external view returns (uint256);

    /**
     * @notice Returns the number of shares a user put up for sale for a specific option.
     * @param optionId The ID of the option.
     * @param user The address of the user.
     * @return The number of shares a user put up for sale for a specific option.
     */
    function userVotesInEscrow(
        uint256 optionId,
        address user
    ) external view returns (uint256);

    /**
     * @notice Returns the amount of base token a user put up for buy for a specific option.
     * @param optionId The ID of the option.
     * @param user The address of the user.
     * @return The number of base token a user put up for buy for a specific option.
     */
    function userAmountInEscrow(
        uint256 optionId,
        address user
    ) external view returns (uint256);

    /**
     * @notice Returns the smallest price at which a sell order has been placed.
     * @param option The ID of the option.
     * @return The smallest price at which a sell order has been placed.
     */
    function firstSellOrderPrice(
        uint256 option
    ) external view returns (uint256);

    /**
     * @notice Returns the largest price at which a buy order has been placed.
     * @param option The ID of the option.
     * @return The largest price at which a buy order has been placed.
     */
    function firstBuyOrderPrice(uint256 option) external view returns (uint256);

    /**
     * @notice Returns the current dispute details.
     * @return disputeFee The fee paid by the disputer.
     * @return disputedWinner The winner selected by the AI.
     * @return disputer The address of the disputer.
     * @return resolver The address of the resolver.
     */
    function dispute()
        external
        view
        returns (
            uint256 disputeFee,
            uint256 disputedWinner,
            address disputer,
            address resolver
        );

    /**
     * @notice Returns the total number of active or created orders in the system.
     * @return The total number of orders.
     */
    function totalOrders() external returns (uint256);

    /**
     * @notice Allows a user to enter a voting option by depositing tokens.
     * @dev Transfers the specified `amount` of `baseToken` from the user to the contract and updates vote tallies.
     * Requires a valid signature and that the sale is live.
     * @param option The option ID the user is voting for.
     * @param amount The amount of `baseToken` being contributed.
     * @notice The signature must be valid and not expired.
     * @notice Emits an `EnterOption` event upon a successful contribution.
     * @notice Emits a `Sync` event for all options to update total funds.
     */
    function enterOption(uint256 option, uint256 amount) external;

    /**
     * @notice Allows a user to provide liquidity to the pool.
     * @dev Transfers the specified amount of base tokens from the user to the contract.
     *      Requires a valid signature for authentication.
     *      Updates user liquidity, total liquidity, and vote/fund distributions.
     * @param totalAmount The total amount of base tokens the user is adding as liquidity.
     * @notice The function reverts if the pool sale is not live.
     * @notice Emits an `EnterLiquidity` event for the liquidity addition.
     * @notice Emits an `EnterOption` event for each option's fund and vote update.
     * @notice Emits a `Sync` event for each option to reflect the updated pool state.
     */
    function enterLiquidity(uint256 totalAmount) external;

    /**
     * @notice Closes the pool and finalizes the distribution of funds.
     * @dev This function can only be called after the sale has ended.
     *      It distributes funds based on whether the pool is public or private.
     *      The function also creates an oracle if the pool is public.
     * @notice If the pool is already closed, the function reverts.
     * @notice The pool's end time is set to the current block timestamp.
     * @notice In public pools, an oracle is created for result resolution.
     * @notice Emits a `ClosePool` event when the pool is successfully closed.
     */
    function closePool() external;

    /**
     * @notice Starts a dispute if a user has an issue with the winner that has been selected.
     * @dev This function can only be called after a certain time after the  the pool has been
     *     closed. It takes a fee from the user to start a dispute. The amount is only returned
     *     to the user incase the oracle selects the winning option provided by the user. The
     *     max amount allowed is $1000.
     */
    function openDispute() external;

    /**
     * @notice Allows the selection of a winning option for a private pool.
     * @dev Only applicable to private pools that have been finalized.
     *      Requires a valid signature for authentication.
     * @param option The winning option ID.
     * @notice The function reverts if called on a public pool.
     * @notice The function reverts if the pool is not finalized.
     * @notice Emits a `ChooseWinner` event with the winning option and reward distributions.
     */
    function chooseWinner(uint256 option) external;

    /**
     * @notice Allows users to claim their winnings or liquidity rewards after the pool has closed.
     * @dev This function verifies whether the winner has been determined.
     *      - In public pools, it ensures the oracle has finalized the winner.
     *      - The function checks if the caller has already claimed their rewards.
     *      - Rewards are calculated based on liquidity contribution and votes.
     * @notice Reverts if:
     *      - The winner has not been determined.
     *      - The pool is still open.
     *      - The user has already claimed rewards.
     *      - The user is not eligible to claim any rewards.
     * @notice Emits a `Claim` event upon successful reward distribution.
     */
    function claim() external;

    /**
     * @notice Places a sell order for a specific option at a given price and amount.
     * @dev Allows a user to list their shares for sale in the order book.
     * @param option The ID of the option to sell shares for.
     * @param price The price per share at which to sell.
     * @param votes The total number of votes to sell.
     * @return orderID The unique identifier of the created order.
     */
    function placeSellOrder(
        uint256 option,
        uint256 price,
        uint256 votes
    ) external returns (uint256 orderID);

    /**
     * @notice Places a buy order for a specific option at a given price and amount of base token.
     * @dev Allows a user to list a buy order in the order book.
     * @param option The ID of the option to buy shares for.
     * @param price The price per share at which to sell.
     * @param amount The total amount in terms of base token.
     * @return orderID The unique identifier of the created order.
     */
    function placeBuyOrder(
        uint256 option,
        uint256 price,
        uint256 amount
    ) external returns (uint256 orderID);

    /**
     * @notice Cancels multiple sell orders in the pool.
     * @dev Cancels orders based on the provided option, price, amount, and orderID arrays.
     *      All arrays must be of equal length and correspond to each other by index.
     * @param option Array of option IDs associated with each order to cancel.
     * @param price Array of price values at which the orders were placed.
     * @param orderID Array of order IDs to be cancelled.
     */
    function cancelSellOrders(
        uint256[] memory option,
        uint256[] memory price,
        uint256[] memory orderID
    ) external;

    /**
     * @notice Cancels multiple Buy orders in the pool.
     * @dev Cancels orders based on the provided option, price, amount, and orderID arrays.
     *      All arrays must be of equal length and correspond to each other by index.
     * @param option Array of option IDs associated with each order to cancel.
     * @param price Array of price values at which the orders were placed.
     * @param orderID Array of order IDs to be cancelled.
     */
    function cancelBuyOrders(
        uint256[] memory option,
        uint256[] memory price, //1e18
        uint256[] memory orderID
    ) external;

    /**
     * @notice Calculates the number of shares a user will receive when entering an option.
     * @dev This function determines the share amount based on the impacted price.
     * @param option The option in which the user wants to enter.
     * @param amount The amount of base tokens the user is contributing.
     * @return The number of shares the user will receive.
     */
    function getReturnedShares(
        uint256 option,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice Calculates the shares and amounts allocated to each option when adding liquidity.
     * @dev This function distributes the total liquidity proportionally based on the existing funds in each option.
     * @param totalAmount The total amount of base tokens being added as liquidity.
     * @return returnedShares An array containing the number of shares allocated to each option.
     * @return returnedAmounts An array containing the amount of base tokens allocated to each option.
     */
    function getReturnedLiquidity(
        uint256 totalAmount
    ) external view returns (uint256[] memory, uint256[] memory);

    /**
     * @notice Retrieves the current price of an option based on its total funds.
     * @dev The price is calculated as the ratio of the total funds for the option
     *      to the overall pool funds, scaled by `PRICE_MAGNIFICATION`.
     * @param option The index of the option for which the price is being queried.
     * @return The current price of the specified option.
     */
    function getCurrentPrice(uint256 option) external view returns (uint256);

    /**
     * @notice Computes the price impact when a new amount is added to an option.
     * @dev The impacted price is recalculated based on the new funds, considering
     *      the additional amount being added to both the option and total pool funds.
     * @param option The index of the option being evaluated.
     * @param amount The amount being added to the option.
     * @return The impacted price of the option after adding the specified amount.
     */
    function getImpactedPrice(
        uint256 option,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice Calculates the additional amount of funds required to adjust the end price
     *         of an option pool to the desired target.
     * @dev Uses a derived formula to compute the required amount based on pool state and pricing.
     *      Reverts if the current state is invalid or no additional funds are needed.
     * @param currentPrice The current price of the option.
     * @param endPrice The desired end price to reach.
     * @param totalOptionFunds The total amount of funds allocated to this option.
     * @param _allFunds The total amount of all funds in the pool.
     * @return requiredAmount The minimum additional funds required to move the price to `endPrice`.
     */
    function getAmountRequired(
        uint256 currentPrice,
        uint256 endPrice,
        uint256 totalOptionFunds,
        uint256 _allFunds
    ) external view returns (uint256 requiredAmount);

    /**
     * @notice Computes the amount of shares retured on the given amount for the specified option.
     * @dev The returned shares are calculated based on the `sellOrders` existing in the order book,
     *       the price impace and the additional amount being added to both the option and total pool funds.
     * @param option The index of the option being evaluated.
     * @param amount The amount being added to the option.
     * @return returnedShares retured shares of the option after adding the specified amount.
     * @return expectedReward retured expected rewards in terms of baseToken after adding the specified amount.
     */
    function getEntryShares(
        uint256 option,
        uint256 amount
    ) external view returns (uint256 returnedShares, uint256 expectedReward);

    /**
     * @notice Calculates the dynamic payout amount for a specific user.
     * @dev This is a view function and does not modify the contract state.
     * @param user The address of the user to calculate the dynamic payout for.
     * @return dynamicPayout The amount of dynamic payout the user is eligible to receive.
     */
    function getDynamicPayout(
        address user
    ) external view returns (uint256[] memory dynamicPayout);
}
