// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { _revert } from "./utils/Globals.sol";

import { LinkedListLogic } from "./libraries/LinkedList.sol";
import { LinkedListStorage } from "./interfaces/LinkedListStorage.sol";

import { IQuestion } from "./interfaces/IQuestion.sol";

import { IRainDeployer } from "./interfaces/IRainDeployer.sol";
import { IRainPool } from "./interfaces/IRainPool.sol";
import { IRainToken } from "./interfaces/IRainToken.sol";

import { ISwapRouter } from "./interfaces/ISwapRouter.sol";

/**
 * @title RainPool
 * @notice Provides functionality for RainPool automated prediction market (APM).
 */
contract RainPool is IRainPool, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using LinkedListLogic for LinkedListStorage.LinkedList;

    /// @inheritdoc IRainPool
    uint256 public PRICE_MAGNIFICATION = 10 ** 18;

    /// @inheritdoc IRainPool
    uint256 public FEE_MAGNIFICATION = 10 ** 3;

    /// @dev Uniswap v3 RAIN-WETH Pool Fee
    uint24 private _RAIN_WETH_FEE = 10_000;

    /// @inheritdoc IRainPool
    string public ipfsUri;

    /// @inheritdoc IRainPool
    address public immutable FACTORY;

    /// @inheritdoc IRainPool
    address public baseToken;

    /// @inheritdoc IRainPool
    address public rainToken;

    /// @inheritdoc IRainPool
    address public poolOwner;

    /// @inheritdoc IRainPool
    address public platformAddress;

    /// @inheritdoc IRainPool
    address public resolver;

    /// @dev Address of the uniswap v3 Swap Router.
    address private _swapRouter;

    /// @inheritdoc IRainPool
    bool public isPublic;

    /// @inheritdoc IRainPool
    bool public resolverIsAI;

    /// @inheritdoc IRainPool
    bool public isDisputed;

    /// @inheritdoc IRainPool
    bool public firstClaim;

    /// @inheritdoc IRainPool
    bool public poolFinalized = false;

    /// @inheritdoc IRainPool
    uint256 public allVotes;

    /// @inheritdoc IRainPool
    uint256 public allFunds;

    /// @inheritdoc IRainPool
    uint256 public winningPoolShare;

    /// @inheritdoc IRainPool
    uint256 public liquidityShare;

    /// @inheritdoc IRainPool
    uint256 public platformShare;

    /// @inheritdoc IRainPool
    uint256 public creatorShare;

    /// @inheritdoc IRainPool
    uint256 public resolverShare;

    /// @inheritdoc IRainPool
    uint256 public totalLiquidity;

    /// @inheritdoc IRainPool
    uint256 public startTime = block.timestamp;

    /// @inheritdoc IRainPool
    uint256 public endTime;

    /// @inheritdoc IRainPool
    uint256 public numberOfOptions = 2;

    /// @inheritdoc IRainPool
    uint256 public winner;

    /// @inheritdoc IRainPool
    uint256 public platformFee = 25; // i.e. 2.5%

    /// @inheritdoc IRainPool
    uint256 public liquidityFee = 12; // i.e. 1.2%

    /// @inheritdoc IRainPool
    uint256 public creatorFee = 12; // i.e. 1.2%

    /// @inheritdoc IRainPool
    uint256 public resultResolverFee = 1; // i.e 0.1%

    /// @inheritdoc IRainPool
    uint256 public oracleFixedFee;

    /// @inheritdoc IRainPool
    uint256 public oracleEndTime;

    /// @inheritdoc IRainPool
    uint256 public ordersAdded;

    /// @inheritdoc IRainPool
    uint256 public ordersRemoved;

    /// @inheritdoc IRainPool
    uint256 public baseTokenDecimals;

    /// @inheritdoc IRainPool
    uint256 public constant TICK_SPACING = 0.01 ether;

    /// @inheritdoc IRainPool
    uint256 public constant ORDER_EXECUTION_FEE = 25; //i.e. 2.5%

    /// @inheritdoc IRainPool
    uint256 public constant DISCOUNT_FEE_TIER_ONE = 20; // i.e. 2%

    /// @inheritdoc IRainPool
    uint256 public constant DISCOUNT_FEE_TIER_TWO = 15; // i.e. 1.5%

    /// @inheritdoc IRainPool
    uint256 public constant DISCOUNT_FEE_TIER_THREE = 10; // i.e. 1%

    /// @inheritdoc IRainPool
    uint256 public immutable DISPUTE_WINDOW;

    /// @inheritdoc IRainPool
    uint256 public immutable AMOUNT_TIER_ONE;

    /// @inheritdoc IRainPool
    uint256 public immutable AMOUNT_TIER_TWO;

    /// @inheritdoc IRainPool
    uint256 public immutable AMOUNT_TIER_THREE;

    /// @inheritdoc IRainPool
    mapping(uint256 option => uint256 votes) public totalVotes;

    /// @inheritdoc IRainPool
    mapping(uint256 option => uint256 funds) public totalFunds;

    /// @inheritdoc IRainPool
    mapping(uint256 option => mapping(address user => uint256 votes))
        public userVotes;

    /// @inheritdoc IRainPool
    mapping(address user => uint256 liquidity) public userLiquidity;

    /// @inheritdoc IRainPool
    mapping(address user => bool claimed) public claimed;

    /// @inheritdoc IRainPool
    mapping(uint256 option => mapping(uint256 price => LinkedListStorage.LinkedList orderID))
        public sellOrders;

    /// @inheritdoc IRainPool
    mapping(uint256 option => mapping(uint256 price => LinkedListStorage.LinkedList orderID))
        public buyOrders;

    /// @inheritdoc IRainPool
    mapping(uint256 option => mapping(uint256 price => mapping(uint256 orderID => OrderExists orderExists)))
        public orderBook;

    /// @inheritdoc IRainPool
    mapping(address user => uint256 activeOrders) public userActiveSellOrders;

    /// @inheritdoc IRainPool
    mapping(address user => uint256 activeOrders) public userActiveBuyOrders;

    /// @inheritdoc IRainPool
    mapping(uint256 option => mapping(address user => uint256 votes))
        public userVotesInEscrow;

    /// @inheritdoc IRainPool
    mapping(uint256 option => mapping(address user => uint256 amount))
        public userAmountInEscrow;

    /// @inheritdoc IRainPool
    mapping(uint256 option => uint256 firstSellOrderPrice)
        public firstSellOrderPrice;

    /// @inheritdoc IRainPool
    mapping(uint256 option => uint256 firstBuyOrderPrice)
        public firstBuyOrderPrice;

    /// @inheritdoc IRainPool
    Dispute public dispute;

    /* ============================ MODIFIERS ===================================== */

    /**
     * @notice Ensures that the sale is currently live.
     * NOTE: The sale is considered live only if the current time is between `startTime` and `endTime`.
     */
    modifier saleIsLive() {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            _revert(SaleNotLive.selector);
        }
        _;
    }

    /**
     * @notice Ensures that the sale has ended.
     * NOTE: Allows execution if the current time is past `endTime` or if the caller is the `poolOwner` or 'resolver'.
     */
    modifier saleEnded() {
        if (block.timestamp > endTime) {
            _;
        } else {
            if (msg.sender == poolOwner || msg.sender == resolver) {
                _;
            } else {
                _revert(SaleStillLive.selector);
            }
        }
    }

    /* ============================ CONSTRCUTOR  ===================================== */

    /**
     * @dev Initializes the Rain Pool contract with the provided parameters.
     * Also Performs validation on input values and sets the initial state.
     * @param params The struct containing all necessary parameters for initialization.
     */
    constructor(Params memory params) {
        if (params.baseToken == address(0) || params.rainToken == address(0)) {
            _revert(NoTokenSet.selector);
        }
        if (params.poolOwner == address(0)) {
            _revert(NoOwnerSet.selector);
        }
        if (params.platformAddress == address(0)) {
            _revert(NoPlatformSet.selector);
        }
        if (params.startTime <= block.timestamp) {
            _revert(StartTimeEnded.selector);
        }
        if (params.endTime <= params.startTime) {
            _revert(EndTImeLessThanStartTime.selector);
        }
        if (params.numberOfOptions < 2) {
            _revert(MinimumOptionsShouldBeTwo.selector);
        }
        if (params.numberOfOptions > 50) {
            _revert(MaximumOptionsExceeded.selector);
        }
        if (params.oracleFixedFee == 0) {
            _revert(InvalidOracleFixedFee.selector);
        }
        isPublic = params.isPublic;
        resolverIsAI = params.resolverIsAI;
        FACTORY = params.deployerContract;
        baseToken = params.baseToken;
        poolOwner = params.poolOwner;
        resolver = params.resolver;

        emit ResolverSet({ resolver: resolver });

        startTime = params.startTime;
        endTime = params.endTime;
        numberOfOptions = params.numberOfOptions;
        platformAddress = params.platformAddress;
        platformFee = params.platformFee;
        rainToken = params.rainToken;
        _swapRouter = params.swapRouter;
        liquidityFee = params.liquidityFee;
        creatorFee = params.creatorFee;
        resultResolverFee = params.resultResolverFee;
        oracleFixedFee = params.oracleFixedFee;
        oracleEndTime = params.oracleEndTime;
        ipfsUri = params.ipfsUri;
        baseTokenDecimals = 10 ** params.baseTokenDecimals;

        DISPUTE_WINDOW = 60 minutes;

        AMOUNT_TIER_ONE = 1_000_000 * baseTokenDecimals;
        AMOUNT_TIER_TWO = 5_000_000 * baseTokenDecimals;
        AMOUNT_TIER_THREE = 10_000_000 * baseTokenDecimals;

        uint256 liquidityPercentageSum = 0;
        uint256 i = 0;
        for (; i < params.liquidityPercentages.length; ) {
            liquidityPercentageSum += params.liquidityPercentages[i];
            unchecked {
                ++i;
            }
        }
        if (liquidityPercentageSum != 100) {
            _revert(InvalidLiquidityPercentage.selector);
        }

        if (params.initialLiquidity > 0) {
            uint256 fee;
            i = 1;
            for (; i <= numberOfOptions; ) {
                totalFunds[i] =
                    (params.initialLiquidity *
                        params.liquidityPercentages[i - 1]) /
                    100;
                totalVotes[i] = params.initialLiquidity; // initial price is same as percentage weight hence (totalAmount * weight) / weight = totalAmount of votes
                allVotes += totalVotes[i];
                allFunds += totalFunds[i];
                userVotes[i][poolOwner] += totalVotes[i];
                emit EnterOption(
                    i,
                    totalFunds[i],
                    totalVotes[i],
                    params.poolOwner
                );

                firstSellOrderPrice[i] = 0.99 ether;
                firstBuyOrderPrice[i] = 0.01 ether;

                unchecked {
                    ++i;
                }
            }
            totalLiquidity += params.initialLiquidity;
            userLiquidity[poolOwner] += params.initialLiquidity;

            fee = (totalLiquidity * platformFee) / FEE_MAGNIFICATION;
            platformShare += fee;

            emit EnterLiquidity(params.initialLiquidity, params.poolOwner);
        } else {
            _revert(InvalidInitialLiquidity.selector);
        }
        i = 1;
        for (; i <= numberOfOptions; ) {
            emit Sync(i, totalFunds[i], allFunds);
            unchecked {
                ++i;
            }
        }
    }

    /* =============================== FUNCTIONS  ===================================== */

    /**
     * @inheritdoc IRainPool
     */
    function enterOption(uint256 option, uint256 amount) public nonReentrant {
        if (block.timestamp < startTime) {
            _revert(SaleNotLive.selector);
        }
        if (winner != 0) {
            _revert(WinnerAlreadyFinalized.selector);
        }
        if (option == 0 || option > numberOfOptions) {
            _revert(InvalidOption.selector);
        }
        if (amount <= 0) {
            _revert(InsufficientAmount.selector);
        }

        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee;

        if (allFunds + amount >= AMOUNT_TIER_THREE) {
            fee = (amount * DISCOUNT_FEE_TIER_THREE) / FEE_MAGNIFICATION;
        } else if (allFunds + amount >= AMOUNT_TIER_TWO) {
            fee = (amount * DISCOUNT_FEE_TIER_TWO) / FEE_MAGNIFICATION;
        } else if (allFunds + amount >= AMOUNT_TIER_ONE) {
            fee = (amount * DISCOUNT_FEE_TIER_ONE) / FEE_MAGNIFICATION;
        } else {
            fee = (amount * platformFee) / FEE_MAGNIFICATION;
        }

        platformShare += fee;

        uint256 usedAmount; // local cache: used amount for each order book purchase
        uint256 sharesReceived; // local cache: shares recived for each order book purchase
        uint256 totalAmountUsed; // function cache: total sum amount used
        uint256 totalSharesRecieved; // function cache: total sum of shares recived

        int256 idx;
        uint256 head = firstSellOrderPrice[option];
        uint256 currentPrice = getCurrentPrice(option);
        // Drain on-chain book up to currentPrice
        for (; head > 0 && head <= currentPrice && amount > 1; ) {
            LinkedListStorage.LinkedList storage linkedList = sellOrders[
                option
            ][head];

            if (linkedList.isInitialized && !linkedList.isEmpty()) {
                // iterate FIFO
                idx = linkedList.first();
                while (idx != linkedList.tailIndex && amount > 0) {
                    LinkedListStorage.Order memory order = linkedList.getData(
                        idx
                    );
                    idx = linkedList.next(idx);
                    (usedAmount, sharesReceived) = _executeSellOrder(
                        option,
                        head,
                        amount,
                        order.orderID,
                        msg.sender
                    );
                    amount -= usedAmount;
                }
            }

            // advance pointer if linkedList emptied
            if (linkedList.isEmpty()) {
                head += TICK_SPACING;
                firstSellOrderPrice[option] = head;
            } else {
                break;
            }
        }

        if (block.timestamp > endTime && winner == 0) {
            uint256 stoppingPrice;
            uint256 stoppingPriceRemainder;

            currentPrice = getCurrentPrice(option);
            stoppingPriceRemainder =
                (currentPrice + TICK_SPACING) %
                TICK_SPACING;
            stoppingPrice =
                currentPrice +
                TICK_SPACING -
                stoppingPriceRemainder;

            while (amount > 0 && stoppingPrice <= 0.99 ether) {
                // check orderbook now
                LinkedListStorage.LinkedList storage linkedList = sellOrders[
                    option
                ][stoppingPrice];

                if (linkedList.isInitialized && !linkedList.isEmpty()) {
                    // iterate FIFO
                    idx = linkedList.first();
                    while (idx != linkedList.tailIndex && amount > 0) {
                        LinkedListStorage.Order memory order = linkedList
                            .getData(idx);
                        idx = linkedList.next(idx);
                        (usedAmount, sharesReceived) = _executeSellOrder(
                            option,
                            stoppingPrice,
                            amount,
                            order.orderID,
                            msg.sender
                        );
                        amount -= usedAmount;
                    }
                }

                // advance pointer if linkedList emptied
                if (linkedList.isEmpty()) {
                    firstSellOrderPrice[option] = stoppingPrice + TICK_SPACING;
                }

                unchecked {
                    stoppingPrice += TICK_SPACING;
                }
            }

            if (amount > 0) {
                IERC20(baseToken).safeTransfer(msg.sender, amount);
            }
        } else if (amount > 1 && block.timestamp < endTime) {
            uint256 stoppingPrice;
            uint256 stoppingPriceRemainder;
            uint256 requiredFunds;
            uint256 usedFunds;
            while (amount > 0) {
                currentPrice = getCurrentPrice(option);
                if (currentPrice >= 0.99 ether) {
                    sharesReceived = getReturnedShares(option, amount);

                    allVotes += sharesReceived;
                    allFunds += amount;
                    userVotes[option][msg.sender] += sharesReceived;
                    totalVotes[option] += sharesReceived;
                    totalFunds[option] += amount;

                    totalSharesRecieved += sharesReceived;
                    totalAmountUsed += amount;

                    break;
                }

                stoppingPriceRemainder =
                    (currentPrice + TICK_SPACING) %
                    TICK_SPACING;
                stoppingPrice =
                    currentPrice +
                    TICK_SPACING -
                    stoppingPriceRemainder;

                requiredFunds = getAmountRequired(
                    currentPrice,
                    stoppingPrice,
                    totalFunds[option],
                    allFunds
                );
                usedFunds = requiredFunds >= amount ? amount : requiredFunds;
                sharesReceived = getReturnedShares(option, usedFunds);

                allVotes += sharesReceived;
                allFunds += usedFunds;
                userVotes[option][msg.sender] += sharesReceived;
                totalVotes[option] += sharesReceived;
                totalFunds[option] += usedFunds;

                totalSharesRecieved += sharesReceived;
                totalAmountUsed += usedFunds;

                amount -= usedFunds;

                if (amount == 0) {
                    break;
                }

                // check orderbook now
                LinkedListStorage.LinkedList storage linkedList = sellOrders[
                    option
                ][stoppingPrice];

                if (linkedList.isInitialized && !linkedList.isEmpty()) {
                    // iterate FIFO
                    idx = linkedList.first();
                    while (idx != linkedList.tailIndex && amount > 0) {
                        LinkedListStorage.Order memory order = linkedList
                            .getData(idx);
                        idx = linkedList.next(idx);
                        (usedAmount, sharesReceived) = _executeSellOrder(
                            option,
                            stoppingPrice,
                            amount,
                            order.orderID,
                            msg.sender
                        );
                        amount -= usedAmount;
                    }
                }
                // advance pointer if linkedList emptied
                if (linkedList.isEmpty()) {
                    firstSellOrderPrice[option] = stoppingPrice + TICK_SPACING;
                }
            }
        }

        emit EnterOption({
            option: option,
            baseAmount: totalAmountUsed,
            optionAmount: totalSharesRecieved,
            wallet: msg.sender
        });

        uint256 i = 1;
        for (; i <= numberOfOptions; ) {
            emit Sync(i, totalFunds[i], allFunds);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function enterLiquidity(
        uint256 totalAmount
    ) public saleIsLive nonReentrant {
        IERC20(baseToken).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );

        // Scope to avoid stack too deep errors
        {
            uint256 fee;

            if (allFunds + totalAmount >= AMOUNT_TIER_THREE) {
                fee =
                    (totalAmount * DISCOUNT_FEE_TIER_THREE) /
                    FEE_MAGNIFICATION;
            } else if (allFunds + totalAmount >= AMOUNT_TIER_TWO) {
                fee = (totalAmount * DISCOUNT_FEE_TIER_TWO) / FEE_MAGNIFICATION;
            } else if (allFunds + totalAmount >= AMOUNT_TIER_ONE) {
                fee = (totalAmount * DISCOUNT_FEE_TIER_ONE) / FEE_MAGNIFICATION;
            } else {
                fee = (totalAmount * platformFee) / FEE_MAGNIFICATION;
            }

            platformShare += fee;
        }
        (
            uint256[] memory sharesReceived,
            uint256[] memory amountReceived
        ) = getReturnedLiquidity(totalAmount);

        totalLiquidity += totalAmount;
        userLiquidity[msg.sender] += totalAmount;

        uint256 i = 1;
        for (; i <= numberOfOptions; ) {
            allVotes += sharesReceived[i];
            allFunds += amountReceived[i];
            userVotes[i][msg.sender] += sharesReceived[i];
            totalVotes[i] += sharesReceived[i];
            totalFunds[i] += amountReceived[i];
            emit EnterOption(
                i,
                amountReceived[i],
                sharesReceived[i],
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
        emit EnterLiquidity(totalAmount, msg.sender);

        i = 1;
        for (; i <= numberOfOptions; ) {
            emit Sync(i, totalFunds[i], allFunds);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function closePool() public saleEnded nonReentrant {
        if (poolFinalized) {
            _revert(PoolClosed.selector);
        }
        poolFinalized = true;
        endTime = block.timestamp;
        uint256 totalBaseTokens = allFunds;
        if (isPublic) {
            liquidityShare =
                (totalBaseTokens * liquidityFee) /
                FEE_MAGNIFICATION;
            creatorShare = (totalBaseTokens * creatorFee) / FEE_MAGNIFICATION;
            resolverShare =
                (totalBaseTokens * resultResolverFee) /
                FEE_MAGNIFICATION;
            winningPoolShare =
                totalBaseTokens -
                platformShare -
                liquidityShare -
                creatorShare -
                resolverShare;
        } else {
            liquidityShare =
                (totalBaseTokens * liquidityFee) /
                FEE_MAGNIFICATION;
            resolverShare =
                (totalBaseTokens * resultResolverFee) /
                FEE_MAGNIFICATION;
            creatorShare = (totalBaseTokens * creatorFee) / FEE_MAGNIFICATION;
            resolverShare =
                (totalBaseTokens * resultResolverFee) /
                FEE_MAGNIFICATION;
            winningPoolShare =
                totalBaseTokens -
                platformShare -
                liquidityShare -
                creatorShare -
                resolverShare;
        }

        _swapAndBurn(platformShare);
        IERC20(baseToken).safeTransfer(poolOwner, creatorShare);

        emit PlatformClaim(platformAddress, platformShare);
        emit CreatorClaim(poolOwner, creatorShare);
        emit ClosePool(poolFinalized);
    }

    /**
     * @inheritdoc IRainPool
     */
    function chooseWinner(uint256 option) public nonReentrant {
        if (msg.sender != resolver) {
            _revert(OnlyResolver.selector);
        }
        if (winner != 0) {
            _revert(WinnerAlreadyFinalized.selector);
        }
        if (!poolFinalized) {
            _revert(PoolOpen.selector);
        }
        if (option <= 0 || option > numberOfOptions) {
            _revert(InvalidOption.selector);
        }

        endTime = block.timestamp;
        winner = option;

        emit ChooseWinner(
            option,
            platformShare,
            liquidityShare,
            winningPoolShare
        );
    }

    /**
     * @inheritdoc IRainPool
     */
    function openDispute() external nonReentrant {
        uint256 disputeFee = (allFunds * 10) / FEE_MAGNIFICATION;

        // Max $1000 dispute fee allowed if > 0.1% of pool liquidity.
        if (disputeFee > 1000 * 1e6) {
            dispute.disputeFee = 1000 * 1e6;
        } else {
            dispute.disputeFee = disputeFee;
        }

        if (endTime + DISPUTE_WINDOW < block.timestamp) {
            _revert(DisputeWindowEnded.selector);
        }
        if (isDisputed) {
            _revert(DisputeAlreadyOpened.selector);
        }
        if (!poolFinalized || winner == 0) {
            _revert(PoolNotClosed.selector);
        }

        bool isParticipant;

        uint256 i = 1;
        for (; i <= numberOfOptions; ) {
            if (userVotes[i][msg.sender] > 0) {
                isParticipant = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!isParticipant) {
            _revert(InvalidCaller.selector);
        }

        IERC20(baseToken).safeTransferFrom(
            msg.sender,
            address(this),
            dispute.disputeFee
        );

        IERC20(baseToken).safeTransfer(FACTORY, resolverShare + oracleFixedFee);

        dispute.resolver = resolver;

        resolver = IRainDeployer(FACTORY).createOracle(
            _calculateNumberOfOracles(resolverShare),
            resolverShare,
            oracleFixedFee,
            address(this),
            (block.timestamp + oracleEndTime),
            numberOfOptions,
            ipfsUri
        );

        emit ResolverSet({ resolver: resolver });
        emit CreateOracle({
            creatorContract: address(this),
            createdContract: resolver
        });
        emit ResolverClaim(resolver, resolverShare + oracleFixedFee);

        emit OpenDispute({
            caller: msg.sender,
            currentWinner: winner,
            disputeFee: dispute.disputeFee
        });

        dispute.disputedWinner = winner;
        dispute.disputer = msg.sender;
        winner = 0;
        isDisputed = true;
    }

    /**
     * @inheritdoc IRainPool
     */
    function claim() public nonReentrant {
        if (!firstClaim) {
            if (endTime + DISPUTE_WINDOW > block.timestamp) {
                if (!isDisputed) {
                    _revert(DisputeWindowNotEnded.selector);
                }
            }

            if (isDisputed && winner == 0) {
                if (IQuestion(resolver).winnerFinalized()) {
                    winner = IQuestion(resolver).winnerOption();
                    if (winner <= 0 || winner > numberOfOptions) {
                        _revert(WinnerOutOfBound.selector);
                    }
                    if (winner != dispute.disputedWinner) {
                        IERC20(baseToken).safeTransfer(
                            dispute.disputer,
                            dispute.disputeFee
                        );
                    } else {
                        IERC20(baseToken).safeTransfer(
                            dispute.resolver,
                            dispute.disputeFee
                        );
                    }
                    emit ChooseWinner(
                        winner,
                        platformShare,
                        liquidityShare,
                        winningPoolShare
                    );
                } else if (
                    IQuestion(resolver).timeExtended() == 7 &&
                    !IQuestion(resolver).winnerFinalized()
                ) {
                    try IQuestion(resolver).calculateWinnerReadOnly() {
                        _revert(VotingEnded.selector);
                    } catch {
                        IQuestion.ExternalSourceInfo
                            memory externalSourceInfo = IQuestion(resolver)
                                .getExternalSource();
                        if (block.timestamp < externalSourceInfo.endTime) {
                            _revert(OracleNotFinalized.selector);
                        }
                        winner = dispute.disputedWinner;
                    }
                    IQuestion(resolver).refund();
                    IERC20(baseToken).safeTransfer(
                        dispute.resolver,
                        resolverShare + oracleFixedFee
                    );
                    IERC20(baseToken).safeTransfer(
                        dispute.disputer,
                        dispute.disputeFee
                    );
                } else {
                    _revert(OracleNotFinalized.selector);
                }
            }
            if (!isDisputed) {
                IERC20(baseToken).safeTransfer(
                    resolver,
                    resolverShare + oracleFixedFee
                );
                emit ResolverClaim(resolver, resolverShare + oracleFixedFee);
            }
            firstClaim = true;
        }

        if (claimed[msg.sender]) {
            _revert(AlreadyClaimed.selector);
        }
        claimed[msg.sender] = true;

        if (winner == 0) {
            _revert(PoolNotClosed.selector);
        }

        if (userVotesInEscrow[winner][msg.sender] > 0) {
            _revert(UserSellOrderExist.selector);
        }

        uint256 i = 1;
        for (; i <= numberOfOptions; ) {
            if (userAmountInEscrow[i][msg.sender] > 0) {
                _revert(UserBuyOrderExist.selector);
            }
            unchecked {
                ++i;
            }
        }

        uint256 liquidityReward;
        if (totalLiquidity > 0) {
            liquidityReward =
                (liquidityShare * userLiquidity[msg.sender]) /
                totalLiquidity;
        }
        uint256 reward;
        if (totalVotes[winner] > 0) {
            reward =
                (userVotes[winner][msg.sender] * winningPoolShare) /
                totalVotes[winner];
        }
        uint256 totalReward = liquidityReward + reward;

        if (totalReward == 0) {
            _revert(IneligibleToClaim.selector);
        }

        IERC20(baseToken).safeTransfer(msg.sender, totalReward);

        emit Claim(msg.sender, winner, liquidityReward, reward, totalReward);
    }

    /**
     * @inheritdoc IRainPool
     */
    function placeSellOrder(
        uint256 option,
        uint256 price, // 1e18
        uint256 votes
    ) external nonReentrant returns (uint256 orderID) {
        if (option == 0 || option > numberOfOptions) {
            _revert(InvalidOption.selector);
        }
        if (
            price < TICK_SPACING ||
            price > 0.99 ether ||
            price % TICK_SPACING != 0
        ) {
            _revert(InvalidPrice.selector);
        }

        if ((votes * price) / (PRICE_MAGNIFICATION) == 0) {
            _revert(InvalidPrice.selector);
        }

        uint256 userVotesAvbForSale = userVotes[option][msg.sender] -
            userVotesInEscrow[option][msg.sender];

        if (votes <= 0 || userVotesAvbForSale < votes) {
            _revert(InsufficientUserVotes.selector);
        }

        uint256 sharesReceived;
        uint256 usedAmount;

        int256 idx;
        uint256 head = firstBuyOrderPrice[option];

        for (; price <= head && votes > 1; ) {
            LinkedListStorage.LinkedList storage linkedListBuy = buyOrders[
                option
            ][head];

            if (!linkedListBuy.isEmpty()) {
                idx = linkedListBuy.first();
                while (idx != linkedListBuy.tailIndex && votes > 0) {
                    LinkedListStorage.Order memory order = linkedListBuy
                        .getData(idx);

                    idx = linkedListBuy.next(idx);

                    (usedAmount, sharesReceived) = _executeBuyOrder(
                        option,
                        head,
                        votes,
                        order.orderID,
                        msg.sender
                    );

                    votes -= sharesReceived;
                }
            }
            unchecked {
                head -= TICK_SPACING;
            }
            if (linkedListBuy.isEmpty()) {
                firstBuyOrderPrice[option] = head;
            }
        }

        if (votes > 1) {
            orderID = uint256(
                keccak256(
                    abi.encodePacked(
                        price,
                        block.number, // or block.timestamp if you really want time
                        ordersAdded,
                        msg.sender
                    )
                )
            );

            if (orderBook[option][price][orderID].exists == true) {
                _revert(OrderAlreadyExists.selector);
            }

            LinkedListStorage.LinkedList storage linkedList = sellOrders[
                option
            ][price];

            if (!linkedList.isInitialized) {
                linkedList.initialize();
            }

            LinkedListStorage.Order memory newOrder = LinkedListStorage.Order({
                orderID: orderID,
                timestamp: block.timestamp,
                amount: votes,
                maker: msg.sender
            });

            idx = linkedList.append(newOrder);
            orderBook[option][price][orderID].exists = true;
            orderBook[option][price][orderID].index = idx;

            userActiveSellOrders[msg.sender]++;
            userVotesInEscrow[option][msg.sender] += votes;
            ++ordersAdded;

            // head-of-book must be the *cheapest* outstanding price
            if (price < firstSellOrderPrice[option]) {
                firstSellOrderPrice[option] = price;
            }

            emit PlaceSellOrder({
                orderOption: option,
                orderPrice: price,
                orderAmount: votes,
                orderID: orderID,
                maker: msg.sender
            });
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function placeBuyOrder(
        uint256 option,
        uint256 price, // 1e18
        uint256 amount
    ) external nonReentrant returns (uint256 orderID) {
        if (option == 0 || option > numberOfOptions) {
            _revert(InvalidOption.selector);
        }
        if (
            price < TICK_SPACING ||
            price > 0.99 ether ||
            price % TICK_SPACING != 0
        ) {
            _revert(InvalidPrice.selector);
        }

        if ((amount * PRICE_MAGNIFICATION) / price == 0) {
            _revert(InvalidAmount.selector);
        }

        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);

        uint256 sharesReceived;
        uint256 usedAmount;
        int256 idx;
        uint256 head = firstSellOrderPrice[option];
        for (; head <= price && amount > 1; ) {
            LinkedListStorage.LinkedList storage linkedListSell = sellOrders[
                option
            ][head];

            if (!linkedListSell.isEmpty()) {
                idx = linkedListSell.first();
                while (idx != linkedListSell.tailIndex && amount > 0) {
                    LinkedListStorage.Order memory order = linkedListSell
                        .getData(idx);
                    idx = linkedListSell.next(idx);
                    (usedAmount, sharesReceived) = _executeSellOrder(
                        option,
                        head,
                        amount,
                        order.orderID,
                        msg.sender
                    );
                    amount -= usedAmount;
                }
            }
            unchecked {
                head += TICK_SPACING;
            }

            if (linkedListSell.isEmpty()) {
                firstSellOrderPrice[option] = head;
            }
        }

        if (amount > 1) {
            orderID = uint256(
                keccak256(
                    abi.encodePacked(
                        price,
                        block.number, // or block.timestamp if you really want time
                        ordersAdded,
                        msg.sender
                    )
                )
            );

            if (orderBook[option][price][orderID].exists == true) {
                _revert(OrderAlreadyExists.selector);
            }

            LinkedListStorage.LinkedList storage linkedList = buyOrders[option][
                price
            ];

            if (!linkedList.isInitialized) {
                linkedList.initialize();
            }

            LinkedListStorage.Order memory newOrder = LinkedListStorage.Order({
                orderID: orderID,
                timestamp: block.timestamp,
                amount: amount,
                maker: msg.sender
            });

            idx = linkedList.append(newOrder);
            orderBook[option][price][orderID].exists = true;
            orderBook[option][price][orderID].index = idx;

            userActiveBuyOrders[msg.sender]++;
            userAmountInEscrow[option][msg.sender] += amount;
            ++ordersAdded;

            // head-of-book must be the *cheapest* outstanding price
            if (price > firstBuyOrderPrice[option]) {
                firstBuyOrderPrice[option] = price;
            }

            emit PlaceBuyOrder({
                orderOption: option,
                orderPrice: price,
                orderAmount: amount,
                orderID: orderID,
                maker: msg.sender
            });
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function cancelSellOrders(
        uint256[] memory option,
        uint256[] memory price, //1e18
        uint256[] memory orderID
    ) external nonReentrant {
        if (price.length != orderID.length || orderID.length != option.length) {
            _revert(ArrayLengthMismatch.selector);
        }

        uint256 i = 0;
        for (; i < orderID.length; ) {
            if (option[i] == 0 || option[i] > numberOfOptions) {
                _revert(InvalidOption.selector);
            }
            if (
                price[i] == 0 ||
                price[i] > 0.99 ether ||
                price[i] % TICK_SPACING != 0
            ) {
                _revert(InvalidPrice.selector);
            }

            _cancelSellOrder(option[i], price[i], orderID[i], msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function cancelBuyOrders(
        uint256[] memory option,
        uint256[] memory price, //1e18
        uint256[] memory orderID
    ) external nonReentrant {
        if (price.length != orderID.length || orderID.length != option.length) {
            _revert(ArrayLengthMismatch.selector);
        }

        uint256 i = 0;
        for (; i < orderID.length; ) {
            if (option[i] == 0 || option[i] > numberOfOptions) {
                _revert(InvalidOption.selector);
            }
            if (
                price[i] == 0 ||
                price[i] > 0.99 ether ||
                price[i] % TICK_SPACING != 0
            ) {
                _revert(InvalidPrice.selector);
            }

            _cancelBuyOrder(option[i], price[i], orderID[i], msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function getReturnedShares(
        uint256 option,
        uint256 amount
    ) public view returns (uint256) {
        return _getReturnedShares(amount, totalFunds[option], allFunds);
    }

    /**
     * @inheritdoc IRainPool
     */
    function getReturnedLiquidity(
        uint256 totalAmount
    )
        public
        view
        returns (
            uint256[] memory returnedShares,
            uint256[] memory returnedAmounts
        )
    {
        returnedShares = new uint256[](numberOfOptions + 1);
        returnedAmounts = new uint256[](numberOfOptions + 1);
        uint256 i = 1;
        for (; i <= numberOfOptions; ) {
            returnedAmounts[i] = (totalAmount * totalFunds[i]) / allFunds;
            returnedShares[i] = getReturnedShares(i, returnedAmounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function getCurrentPrice(uint256 option) public view returns (uint256) {
        return (totalFunds[option] * PRICE_MAGNIFICATION) / allFunds;
    }

    /**
     * @inheritdoc IRainPool
     */
    function getImpactedPrice(
        uint256 option,
        uint256 amount
    ) public view returns (uint256) {
        return
            ((totalFunds[option] + amount) * PRICE_MAGNIFICATION) /
            (allFunds + amount);
    }

    /**
     * @inheritdoc IRainPool
     */
    function getAmountRequired(
        uint256 currentPrice,
        uint256 endPrice,
        uint256 totalOptionFunds,
        uint256 _allFunds
    ) public view returns (uint256 requiredAmount) {
        uint256 y = totalOptionFunds;
        uint256 b = _allFunds;
        uint256 M = PRICE_MAGNIFICATION;
        uint256 p = endPrice;

        if (y <= 0 || b <= 0) {
            _revert(InvalidPoolState.selector);
        }
        if (p < currentPrice) {
            _revert(EndPriceTooLow.selector);
        }
        if (p >= M) {
            _revert(EndPriceTooHigh.selector);
        }

        // derive:   p = (y+z)*M/(b+z)
        // →   numerator   = p*b - M*y
        //      denominator = M - p
        uint256 pb = p * b;
        uint256 My = M * y;
        if (pb <= My) {
            _revert(NoIncreaseNeeded.selector);
        }

        uint256 numerator = pb - My;
        uint256 denominator = M - p;

        // **CEILING** so even tiny moves require at least 1 wei
        requiredAmount = (numerator + denominator - 1) / denominator;
    }

    /**
     * @inheritdoc IRainPool
     */
    function totalOrders() external view returns (uint256) {
        return ordersAdded - ordersRemoved;
    }

    /**
     * @inheritdoc IRainPool
     */
    function getEntryShares(
        uint256 option,
        uint256 amount
    ) external view returns (uint256 returnedShares, uint256 expectedPayout) {
        if (option == 0 || option > numberOfOptions) {
            _revert(InvalidOption.selector);
        }

        if (amount <= 0) {
            _revert(InsufficientAmount.selector);
        }

        uint256 optionFunds = totalFunds[option];
        uint256 totalAmount = allFunds;

        uint256 usedAmount; // local cache: used amount for each order book purchase
        uint256 sharesReceived; // local cache: shares recived for each order book purchase
        uint256 totalAmountUsed; // function cache: total sum amount used
        uint256 totalSharesRecieved; // function cache: total sum of shares recived

        int256 idx;
        uint256 head = firstSellOrderPrice[option];
        uint256 currentPrice = getCurrentPrice(option);
        // Drain on-chain book up to currentPrice
        for (; head > 0 && head <= currentPrice && amount > 1; ) {
            LinkedListStorage.LinkedList storage linkedList = sellOrders[
                option
            ][head];

            if (linkedList.isInitialized && !linkedList.isEmpty()) {
                // iterate FIFO
                idx = linkedList.first();
                while (idx != linkedList.tailIndex && amount > 0) {
                    LinkedListStorage.Order memory order = linkedList.getData(
                        idx
                    );
                    idx = linkedList.next(idx);
                    (usedAmount, sharesReceived) = _getSellOrderAmounts(
                        option,
                        head,
                        amount,
                        order.orderID
                    );
                    amount -= usedAmount;
                    totalAmountUsed += usedAmount;
                    totalSharesRecieved += sharesReceived;
                }
            }

            unchecked {
                head += TICK_SPACING;
            }
        }

        if (poolFinalized && winner == 0) {
            uint256 stoppingPrice;
            uint256 stoppingPriceRemainder;

            currentPrice = getCurrentPrice(option);
            stoppingPriceRemainder =
                (currentPrice + TICK_SPACING) %
                TICK_SPACING;
            stoppingPrice =
                currentPrice +
                TICK_SPACING -
                stoppingPriceRemainder;

            while (amount > 1 && stoppingPrice <= 0.99 ether) {
                // check orderbook now
                LinkedListStorage.LinkedList storage linkedList = sellOrders[
                    option
                ][stoppingPrice];

                if (linkedList.isInitialized && !linkedList.isEmpty()) {
                    // iterate FIFO
                    idx = linkedList.first();
                    while (idx != linkedList.tailIndex && amount > 0) {
                        LinkedListStorage.Order memory order = linkedList
                            .getData(idx);
                        idx = linkedList.next(idx);
                        (usedAmount, sharesReceived) = _getSellOrderAmounts(
                            option,
                            stoppingPrice,
                            amount,
                            order.orderID
                        );
                        amount -= usedAmount;
                        totalAmountUsed += usedAmount;
                        totalSharesRecieved += sharesReceived;
                    }
                }

                unchecked {
                    stoppingPrice += TICK_SPACING;
                }
            }
        } else if (amount > 1 && !poolFinalized) {
            uint256 stoppingPrice;
            uint256 stoppingPriceRemainder;
            uint256 requiredFunds;
            uint256 usedFunds;
            while (amount > 0) {
                currentPrice =
                    (optionFunds * PRICE_MAGNIFICATION) /
                    totalAmount;
                if (currentPrice >= 0.99 ether) {
                    sharesReceived = _getReturnedShares(
                        amount,
                        optionFunds,
                        totalAmount
                    );

                    optionFunds += amount;
                    totalAmount += amount;

                    totalSharesRecieved += sharesReceived;
                    totalAmountUsed += amount;

                    amount = 0;

                    break;
                }

                stoppingPriceRemainder =
                    (currentPrice + TICK_SPACING) %
                    TICK_SPACING;
                stoppingPrice =
                    currentPrice +
                    TICK_SPACING -
                    stoppingPriceRemainder;

                requiredFunds = getAmountRequired(
                    currentPrice,
                    stoppingPrice,
                    optionFunds,
                    totalAmount
                );

                usedFunds = requiredFunds >= amount ? amount : requiredFunds;

                sharesReceived = _getReturnedShares(
                    usedFunds,
                    optionFunds,
                    totalAmount
                );

                optionFunds += usedFunds;
                totalAmount += usedFunds;

                totalSharesRecieved += sharesReceived;
                totalAmountUsed += usedFunds;

                amount -= usedFunds;

                if (amount == 0) {
                    break;
                }

                // check orderbook now
                LinkedListStorage.LinkedList storage linkedList = sellOrders[
                    option
                ][stoppingPrice];

                if (linkedList.isInitialized && !linkedList.isEmpty()) {
                    // iterate FIFO
                    idx = linkedList.first();
                    while (idx != linkedList.tailIndex && amount > 0) {
                        LinkedListStorage.Order memory order = linkedList
                            .getData(idx);
                        idx = linkedList.next(idx);
                        (usedAmount, sharesReceived) = _getSellOrderAmounts(
                            option,
                            stoppingPrice,
                            amount,
                            order.orderID
                        );
                        amount -= usedAmount;
                        totalAmountUsed += usedAmount;
                        totalSharesRecieved += sharesReceived;
                    }
                }
            }
        }

        returnedShares = totalSharesRecieved;

        //Scope to avoid stack too deep errors
        {
            uint256 fee = (totalAmount *
                (liquidityFee + creatorFee + resultResolverFee)) /
                FEE_MAGNIFICATION;
            fee += platformShare;

            expectedPayout =
                (returnedShares * PRICE_MAGNIFICATION) /
                (returnedShares + totalVotes[option]);

            expectedPayout = expectedPayout * (totalAmount - fee);
            expectedPayout = (expectedPayout / PRICE_MAGNIFICATION);
        }
    }

    /**
     * @inheritdoc IRainPool
     */
    function getDynamicPayout(
        address user
    ) external view returns (uint256[] memory dynamicPayout) {
        dynamicPayout = new uint256[](numberOfOptions + 1);
        uint256 totalBaseTokens = allFunds;
        uint256 fee = (totalBaseTokens *
            (liquidityFee + creatorFee + resultResolverFee)) /
            FEE_MAGNIFICATION;
        fee += platformShare;

        uint256 liquidityReward;
        if (totalLiquidity > 0) {
            uint256 liquidityPayout = (totalBaseTokens * liquidityFee) /
                FEE_MAGNIFICATION;
            liquidityReward =
                (liquidityPayout * userLiquidity[user]) /
                totalLiquidity;
        }
        uint256 rewardPayout;
        uint256 i = 1;
        for (; i <= numberOfOptions; ) {
            if (totalVotes[i] > 0) {
                rewardPayout =
                    (userVotes[i][user] * PRICE_MAGNIFICATION) /
                    (totalVotes[i]);

                rewardPayout = rewardPayout * (allFunds - fee);
                rewardPayout = rewardPayout / PRICE_MAGNIFICATION;

                dynamicPayout[i] = rewardPayout + liquidityReward;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Checks the values for the `amountExecuted` and `shareAmount` against a specific sell order in the order book.
     * Validates the order ID, order existence, price tick spacing, and updates or removes the order accordingly.
     * @param option The index of the option being bought.
     * @param price The price per unit for the sell order.
     * @param fundsAmount The amount of funds user provides to buy the order.
     * @param orderID The unique identifier of the sell order to be fulfilled.
     * @return amountExecuted The amount in baseToken recieved by the seller.
     * @return shareAmount The amount of shares recieved by the buyer.
     */
    function _getSellOrderAmounts(
        uint256 option,
        uint256 price, // 1e18
        uint256 fundsAmount,
        uint256 orderID
    ) private view returns (uint256 amountExecuted, uint256 shareAmount) {
        LinkedListStorage.LinkedList storage linkedList = sellOrders[option][
            price
        ];

        int256 nodeIndex = orderBook[option][price][orderID].index;

        uint256 orderAmount = LinkedListLogic.getAmount(linkedList, nodeIndex);

        shareAmount = ((fundsAmount * (PRICE_MAGNIFICATION)) / price);

        if (orderAmount > shareAmount) {
            orderAmount = shareAmount;
        } else {
            shareAmount = orderAmount;
        }

        amountExecuted = (orderAmount * price) / (PRICE_MAGNIFICATION);
    }

    /**
     * @dev Executes a specific sell order in the order book.
     * Validates the order ID, order existence, price tick spacing, and updates or removes the order accordingly.
     * @param option The index of the option being bought.
     * @param price The price per unit for the sell order.
     * @param fundsAmount The amount of funds user provides to buy the order.
     * @param orderID The unique identifier of the sell order to be fulfilled.
     * @param buyerAddress THe address of the buyer executing the order.
     * @return amountExecuted The amount in baseToken recieved by the seller.
     * @return shareAmount The amount of shares recieved by the buyer.
     */
    function _executeSellOrder(
        uint256 option,
        uint256 price, // 1e18
        uint256 fundsAmount,
        uint256 orderID,
        address buyerAddress
    ) private returns (uint256 amountExecuted, uint256 shareAmount) {
        LinkedListStorage.LinkedList storage linkedList = sellOrders[option][
            price
        ];

        int256 nodeIndex = orderBook[option][price][orderID].index;

        uint256 orderAmount = LinkedListLogic.getAmount(linkedList, nodeIndex);
        address sellerAddress = LinkedListLogic.getMaker(linkedList, nodeIndex);

        shareAmount = ((fundsAmount * (PRICE_MAGNIFICATION)) / price);

        if (orderAmount <= shareAmount) {
            linkedList.remove(nodeIndex);
            orderBook[option][price][orderID].exists = false;
            orderBook[option][price][orderID].index = 0;
            userActiveSellOrders[sellerAddress]--;
            ++ordersRemoved;
            shareAmount = orderAmount;
        } else {
            sellOrders[option][price]
                .nodes[nodeIndex]
                .data
                .amount -= shareAmount;
            orderAmount = shareAmount;
        }

        userVotesInEscrow[option][sellerAddress] -= orderAmount;

        uint256 userAmount = (orderAmount * price) / (PRICE_MAGNIFICATION);
        amountExecuted = userAmount;

        uint256 fee = (userAmount * ORDER_EXECUTION_FEE) / FEE_MAGNIFICATION;
        userAmount -= fee;

        uint256 feeCreator = (userAmount * creatorFee) / FEE_MAGNIFICATION;
        userAmount -= feeCreator;

        userVotes[option][buyerAddress] += orderAmount;

        userVotes[option][sellerAddress] -= orderAmount;

        platformShare += fee;

        IERC20(baseToken).safeTransfer(sellerAddress, userAmount);

        emit ExecuteSellOrder({
            orderOption: option,
            orderPrice: price,
            optionAmount: orderAmount,
            baseAmount: amountExecuted,
            orderID: orderID,
            maker: sellerAddress,
            taker: buyerAddress
        });

        IERC20(baseToken).safeTransfer(poolOwner, feeCreator);

        emit CreatorClaim({ wallet: poolOwner, amount: feeCreator });
    }

    /**
     * @dev Executes a specific buy order in the order book.
     * Validates the order ID, order existence, price tick spacing, and updates or removes the order accordingly.
     * @param option The index of the option being bought.
     * @param price The price per unit for the buy order.
     * @param shareAmount The amount of shares user provides to sell.
     * @param orderID The unique identifier of the buy order to be fulfilled.
     * @param sellerAddress THe address of the seller executing the order.
     * @return amountExecuted The amount in baseToken recieved by the seller.
     * @return sharesFilled The amount of shares recieved by the buyer.
     */
    function _executeBuyOrder(
        uint256 option,
        uint256 price, // 1e18
        uint256 shareAmount,
        uint256 orderID,
        address sellerAddress
    ) private returns (uint256 amountExecuted, uint256 sharesFilled) {
        LinkedListStorage.LinkedList storage linkedList = buyOrders[option][
            price
        ];

        int256 nodeIndex = orderBook[option][price][orderID].index;

        uint256 orderAmount = LinkedListLogic.getAmount(linkedList, nodeIndex);
        address buyerAddress = LinkedListLogic.getMaker(linkedList, nodeIndex);

        sharesFilled = (orderAmount * PRICE_MAGNIFICATION) / price;

        if (shareAmount >= sharesFilled) {
            linkedList.remove(nodeIndex);
            orderBook[option][price][orderID].exists = false;
            orderBook[option][price][orderID].index = 0;
            userActiveBuyOrders[buyerAddress]--;
            ++ordersRemoved;
            amountExecuted = orderAmount;
        } else {
            amountExecuted = ((shareAmount * price) / PRICE_MAGNIFICATION);
            buyOrders[option][price]
                .nodes[nodeIndex]
                .data
                .amount -= amountExecuted;
            sharesFilled = shareAmount;
        }

        userAmountInEscrow[option][buyerAddress] -= amountExecuted;

        uint256 userAmount = amountExecuted;

        uint256 fee = (userAmount * ORDER_EXECUTION_FEE) / FEE_MAGNIFICATION;
        userAmount -= fee;

        uint256 feeCreator = (userAmount * creatorFee) / FEE_MAGNIFICATION;
        userAmount -= feeCreator;

        userVotes[option][buyerAddress] += sharesFilled;

        userVotes[option][sellerAddress] -= sharesFilled;

        platformShare += fee;

        IERC20(baseToken).safeTransfer(sellerAddress, userAmount);

        emit ExecuteBuyOrder({
            orderOption: option,
            orderPrice: price,
            optionAmount: sharesFilled,
            baseAmount: amountExecuted,
            orderID: orderID,
            maker: buyerAddress,
            taker: sellerAddress
        });

        IERC20(baseToken).safeTransfer(poolOwner, feeCreator);

        emit CreatorClaim({ wallet: poolOwner, amount: feeCreator });
    }

    /**
     * @notice Cancels a specific sell order in the order book.
     * @dev Reverts if the order ID is invalid or the caller is not the order's creator.
     *      Emits a {CancelSellOrder} event upon successful cancellation.
     * @param option The option index for which the order was placed.
     * @param price The price at which the order was placed.
     * @param orderID The unique identifier of the order to cancel.
     * @param caller The address of the user calling the function.
     */
    function _cancelSellOrder(
        uint256 option,
        uint256 price, // 1e18
        uint256 orderID,
        address caller
    ) private {
        if (orderBook[option][price][orderID].exists == false) {
            _revert(OrderDoesNotExist.selector);
        }

        LinkedListStorage.LinkedList storage linkedList = sellOrders[option][
            price
        ];

        if (!linkedList.isInitialized) {
            _revert(LinkedListNotInitalized.selector);
        }

        int256 nodeIndex = orderBook[option][price][orderID].index;
        uint256 orderAmount = LinkedListLogic.getAmount(linkedList, nodeIndex);
        address sellerAddress = LinkedListLogic.getMaker(linkedList, nodeIndex);

        linkedList.remove(nodeIndex);
        orderBook[option][price][orderID].exists = false;
        orderBook[option][price][orderID].index = 0;

        userActiveSellOrders[caller]--;
        userVotesInEscrow[option][caller] -= orderAmount;
        ++ordersRemoved;

        emit CancelSellOrder({
            orderOption: option,
            orderPrice: price,
            orderAmount: orderAmount,
            orderID: orderID,
            orderCreator: sellerAddress
        });
    }

    /**
     * @notice Cancels a specific Buy order in the order book.
     * @dev Reverts if the order ID is invalid or the caller is not the order's creator.
     *      Emits a {CancelBuyOrder} event upon successful cancellation.
     * @param option The option index for which the order was placed.
     * @param price The price at which the order was placed.
     * @param orderID The unique identifier of the order to cancel.
     * @param caller The address of the user calling the function.
     */
    function _cancelBuyOrder(
        uint256 option,
        uint256 price, // 1e18
        uint256 orderID,
        address caller
    ) private {
        if (orderBook[option][price][orderID].exists == false) {
            _revert(OrderDoesNotExist.selector);
        }

        LinkedListStorage.LinkedList storage linkedList = buyOrders[option][
            price
        ];

        if (!linkedList.isInitialized) {
            _revert(LinkedListNotInitalized.selector);
        }

        int256 nodeIndex = orderBook[option][price][orderID].index;
        uint256 orderAmount = LinkedListLogic.getAmount(linkedList, nodeIndex);
        address buyerAddress = LinkedListLogic.getMaker(linkedList, nodeIndex);

        if (caller != buyerAddress) {
            _revert(CallerNotOrderPlacer.selector);
        }

        linkedList.remove(nodeIndex);
        orderBook[option][price][orderID].exists = false;
        orderBook[option][price][orderID].index = 0;

        userActiveBuyOrders[caller]--;
        userAmountInEscrow[option][caller] -= orderAmount;
        ++ordersRemoved;

        IERC20(baseToken).safeTransfer(caller, orderAmount);

        emit CancelBuyOrder({
            orderOption: option,
            orderPrice: price,
            orderAmount: orderAmount,
            orderID: orderID,
            orderCreator: buyerAddress
        });
    }

    /**
     * @dev Implements the {getReturnedShares} logic.
     */
    function _getReturnedShares(
        uint256 amount,
        uint256 optionFunds,
        uint256 totalAmount
    ) private view returns (uint256 shares) {
        uint256 price = ((optionFunds + amount) * PRICE_MAGNIFICATION) /
            (totalAmount + amount);
        shares = ((amount * PRICE_MAGNIFICATION) / price);
    }

    /**
     * @notice Calculates the number of oracles based on the allocated amount.
     * @dev Ensures the number of oracles remains within a defined range.
     *      The base number of oracles is 3, and additional oracles are determined
     *      by dividing the amount by 20 times the base token's decimal factor.
     *      The maximum number of oracles allowed is 100.
     * @param amount The amount allocated for oracle services.
     * @return The calculated number of oracles, constrained within the min-max range.
     */
    function _calculateNumberOfOracles(
        uint256 amount
    ) internal view returns (uint256) {
        uint256 baseOracles = numberOfOptions + 1; // Minimum number of oracles
        uint256 maxOracles = 100; // Maximum number of oracles

        // Calculate additional oracles based on the amount
        uint256 additionalOracles = (amount) / (10 * (baseTokenDecimals));

        // Calculate the total number of oracles
        uint256 totalOracles = baseOracles + additionalOracles;

        // Ensure the total oracles do not exceed the maximum
        if (totalOracles > maxOracles) {
            totalOracles = maxOracles;
        }

        return totalOracles;
    }

    /**
     * @dev Calculates the amount of Rain recieved with the given amount of base token.
     * @param amountInBaseToken The amount of base token to be exchanged.
     * @return amountRain The amount of Rain recieved with the given amount of base token.
     */
    function _swapAndBurn(
        uint256 amountInBaseToken
    ) private returns (uint256 amountRain) {
        if (amountInBaseToken == 0) {
            _revert(InvalidAmount.selector);
        }

        IERC20(baseToken).forceApprove(address(_swapRouter), amountInBaseToken);

        address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

        bytes memory path = abi.encodePacked(
            baseToken,
            uint24(3000),
            WETH,
            _RAIN_WETH_FEE,
            rainToken
        );
        ISwapRouter.ExactInputParams memory swapParams = ISwapRouter
            .ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp + 2 minutes,
                amountIn: amountInBaseToken,
                amountOutMinimum: 0
            });

        try ISwapRouter(_swapRouter).exactInput(swapParams) {
            amountRain = IERC20(rainToken).balanceOf(address(this));
            if (amountRain > 0) {
                IRainToken(rainToken).burn(amountRain);
                emit RainTokenBurned(amountRain);
            }
        } catch {
            IERC20(baseToken).safeTransfer(platformAddress, amountInBaseToken);
        }
    }
}
