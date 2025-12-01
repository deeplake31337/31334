// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Mock } from "../src/mocks/ERC20Mock.sol";

import { OracleMock } from "../src/mocks/OracleMock.sol";
import { RainFactory } from "../src/RainFactory.sol";
import { RainDeployer, IRainDeployer, UUPSUpgradeable } from "../src/RainDeployer.sol";
import { RainPool, IRainPool } from "../src/RainPool.sol";

import { RainDeployerUpgraded } from "../src/mocks/RainDeployerUpgradedMock.sol";

contract RainPoolTest is Test {
    using MessageHashUtils for bytes32;

    OracleMock oracleFactory;
    RainFactory rainFactory;
    RainDeployer rainDeployer;
    RainPool rainPool;
    RainPool rainPoolPublic;

    ERC20Mock baseToken;

    address public poolOwner;
    uint256 public key;
    address public nonOwner = address(0x4);
    address public addr1;
    address public resolverPool;
    address public resolverAI;
    address public rainToken;
    address public swapRouter;

    uint256 public baseTokenDecimals = 6;
    uint256 public liquidityFee = 12;
    uint256 public platformFee = 25;
    uint256 public creatorFee = 12;
    uint256 public resultResolverFee = 1;
    uint256 public oracleFixedFee = 15 * (10 ** baseTokenDecimals);
    uint256 public initalLiquidity = 10 * (10 ** baseTokenDecimals);

    uint256[] public liquidityPercentages = new uint256[](2);

    function setUp() public {
        liquidityPercentages[0] = 30;
        liquidityPercentages[1] = 70;

        poolOwner = makeAddr("poolOwner");
        addr1 = makeAddr("addr1");
        resolverPool = makeAddr("resolverPool");
        resolverAI = makeAddr("resolverAI");

        rainToken = 0x25118290e6A5f4139381D072181157035864099d;
        swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        baseToken = ERC20Mock(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

        deal(address(baseToken), address(this), 10000000000 * 1e16);

        // Deploy base token (ERC20 mock)
        // baseToken = new ERC20Mock(
        //     "Base Token",
        //     "BTK",
        //     10000000000 * (10 ** baseTokenDecimals)
        // );

        oracleFactory = new OracleMock(address(baseToken));

        rainFactory = new RainFactory();

        RainDeployer rainDeployerImplementation = new RainDeployer();

        bytes memory rainDeployerParams = abi.encodeWithSelector(
            RainDeployer.initialize.selector,
            address(rainFactory),
            address(oracleFactory),
            address(baseToken),
            poolOwner,
            resolverAI,
            rainToken,
            swapRouter,
            baseTokenDecimals,
            liquidityFee,
            platformFee,
            oracleFixedFee,
            creatorFee,
            resultResolverFee
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(rainDeployerImplementation),
            rainDeployerParams
        );

        rainDeployer = RainDeployer(address(proxy));

        IRainDeployer.Params memory params = IRainDeployer.Params({
            isPublic: false,
            resolverIsAI: true,
            poolOwner: address(poolOwner),
            startTime: block.timestamp + 1 seconds,
            endTime: block.timestamp + 30 minutes,
            numberOfOptions: 2,
            oracleEndTime: block.timestamp + 60 minutes,
            ipfsUri: "QmXxDV1vyGC2mCdqUJcq1sW9vjbi3ieA9jvmBv6Bmm4Non",
            initialLiquidity: initalLiquidity,
            liquidityPercentages: liquidityPercentages,
            poolResolver: address(resolverPool)
        });

        baseToken.approve(
            address(rainDeployer),
            initalLiquidity + rainDeployer.oracleFixedFee()
        );

        address poolAddress = rainDeployer.createPool(params);
        rainPool = RainPool(poolAddress);

        IRainDeployer.Params memory paramsPublic = IRainDeployer.Params({
            isPublic: true,
            resolverIsAI: true,
            poolOwner: address(poolOwner),
            startTime: block.timestamp + 1 seconds,
            endTime: block.timestamp + 32 minutes,
            numberOfOptions: 2,
            oracleEndTime: block.timestamp + 60 minutes,
            ipfsUri: "QmXxDV1vyGC2mCdqUJcq1sW9vjbi3ieA9jvmBv6Bmm4Non",
            initialLiquidity: initalLiquidity,
            liquidityPercentages: liquidityPercentages,
            poolResolver: resolverPool
        });

        baseToken.approve(
            address(rainDeployer),
            initalLiquidity + rainDeployer.oracleFixedFee()
        );
        address poolAddressPublic = rainDeployer.createPool(paramsPublic);
        rainPoolPublic = RainPool(poolAddressPublic);

        vm.label(address(rainToken), "RainToken");
        vm.label(address(baseToken), "USDT");
    }

    function test_Set_BaseToken() public {
        address newBaseToken = address(0x5);

        // Test as owner
        rainDeployer.setBaseToken(newBaseToken, baseTokenDecimals);
        assertEq(
            rainDeployer.baseToken(),
            newBaseToken,
            "Base token update failed"
        );

        // Test as non-owner
        vm.prank(nonOwner);
        vm.expectRevert();
        rainDeployer.setBaseToken(newBaseToken, baseTokenDecimals);
    }

    function test_Set_PlatformAddress() public {
        address newPlatformAddress = address(0x6);

        // Test as owner
        rainDeployer.setPlatformAddress(newPlatformAddress);
        assertEq(
            rainDeployer.platformAddress(),
            newPlatformAddress,
            "Platform address update failed"
        );

        // Test as non-owner
        vm.prank(nonOwner);
        vm.expectRevert();
        rainDeployer.setPlatformAddress(newPlatformAddress);
    }

    function test_Set_LiquidityFee() public {
        uint256 newLiquidityFee = 15;

        // Test as owner
        rainDeployer.setLiquidityFee(newLiquidityFee);
        assertEq(
            rainDeployer.liquidityFee(),
            newLiquidityFee,
            "Liquidity fee update failed"
        );

        // Test as non-owner
        vm.prank(nonOwner);
        vm.expectRevert();
        rainDeployer.setLiquidityFee(newLiquidityFee);
    }

    function test_Set_PlatformFee() public {
        uint256 newPlatformFee = 25;

        // Test as owner
        rainDeployer.setPlatformFee(newPlatformFee);
        assertEq(
            rainDeployer.platformFee(),
            newPlatformFee,
            "Platform fee update failed"
        );

        // Test as non-owner
        vm.prank(nonOwner);
        vm.expectRevert();
        rainDeployer.setPlatformFee(newPlatformFee);
    }

    function test_Constructor_RainDeployer() public {
        //This test case does not assert anything.
        //This is purely for testing the event emission of `PoolCreated` that signifies
        //successful creation of `RainPool` instance.

        RainDeployer rainDeployerImplementation = new RainDeployer();

        bytes memory rainDeployerParams = abi.encodeWithSelector(
            RainDeployer.initialize.selector,
            address(rainFactory),
            address(oracleFactory),
            address(baseToken),
            poolOwner,
            resolverAI,
            rainToken,
            swapRouter,
            baseTokenDecimals,
            liquidityFee,
            platformFee,
            oracleFixedFee,
            creatorFee,
            resultResolverFee
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(rainDeployerImplementation),
            rainDeployerParams
        );

        RainDeployer rainDeployerTest = RainDeployer(address(proxy));

        IRainDeployer.Params memory params = IRainDeployer.Params({
            isPublic: false,
            resolverIsAI: true,
            poolOwner: address(poolOwner),
            startTime: block.timestamp + 1 days,
            endTime: block.timestamp + 30 days,
            numberOfOptions: 2,
            oracleEndTime: block.timestamp + 35 days,
            ipfsUri: "QmXxDV1vyGC2mCdqUJcq1sW9vjbi3ieA9jvmBv6Bmm4Non",
            initialLiquidity: initalLiquidity,
            liquidityPercentages: liquidityPercentages,
            poolResolver: resolverPool
        });

        baseToken.approve(
            address(rainDeployerTest),
            initalLiquidity + rainDeployerTest.oracleFixedFee()
        );

        address poolAddress = rainDeployerTest.createPool(params);

        assertTrue(poolAddress != address(0), "Pool not initialized.");
    }

    function test_UpgradeRainDeployer() public {
        RainDeployerUpgraded rainDeployerNewImplementation = new RainDeployerUpgraded();
        RainDeployerUpgraded rainDeployerUpdated = RainDeployerUpgraded(
            address(rainDeployer)
        );
        UUPSUpgradeable(address(rainDeployer)).upgradeToAndCall(
            address(rainDeployerNewImplementation),
            ""
        );

        rainDeployerUpdated.setDummy();
        assert(rainDeployerUpdated.dummyValue() > 0);
    }

    function test_Constructor_RainPool() public view {
        assertEq(
            rainPool.baseToken(),
            address(baseToken),
            "Base token not set correctly."
        );
        assertEq(
            rainPool.platformAddress(),
            poolOwner,
            "Platform address not set correctly."
        );
        assertEq(
            rainPool.liquidityFee(),
            liquidityFee,
            "Liquidity fee not set correctly."
        );
        assertEq(
            rainPool.platformFee(),
            platformFee,
            "Platform fee not set correctly."
        );
    }

    function test_Constructor_Fails_WithInvalidToken() public {
        IRainPool.Params memory params = IRainPool.Params({
            initialLiquidity: initalLiquidity,
            liquidityPercentages: liquidityPercentages,
            isPublic: false,
            resolverIsAI: true,
            deployerContract: address(rainDeployer),
            baseToken: address(0),
            baseTokenDecimals: baseTokenDecimals,
            poolOwner: address(poolOwner),
            platformAddress: address(poolOwner),
            resolver: address(poolOwner),
            rainToken: rainToken,
            swapRouter: swapRouter,
            startTime: block.timestamp + 1 seconds,
            endTime: block.timestamp + 30 minutes,
            numberOfOptions: 2,
            platformFee: 10,
            liquidityFee: 10,
            creatorFee: 10,
            resultResolverFee: 10,
            oracleFixedFee: 10,
            oracleEndTime: block.timestamp + 60 minutes,
            ipfsUri: "QmXxDV1vyGC2mCdqUJcq1sW9vjbi3ieA9jvmBv6Bmm4Non"
        });

        vm.expectRevert(IRainPool.NoTokenSet.selector);
        new RainPool(params);
    }

    function test_Constructor_Fails_WithInvalidTime() public {
        IRainPool.Params memory params = IRainPool.Params({
            initialLiquidity: initalLiquidity,
            liquidityPercentages: liquidityPercentages,
            isPublic: false,
            resolverIsAI: true,
            deployerContract: address(rainDeployer),
            baseToken: address(baseToken),
            baseTokenDecimals: baseTokenDecimals,
            poolOwner: address(poolOwner),
            platformAddress: address(poolOwner),
            resolver: address(poolOwner),
            rainToken: rainToken,
            swapRouter: swapRouter,
            startTime: block.timestamp,
            endTime: block.timestamp + 30 minutes,
            numberOfOptions: 2,
            platformFee: 10,
            liquidityFee: 10,
            creatorFee: 10,
            resultResolverFee: 10,
            oracleFixedFee: 10,
            oracleEndTime: block.timestamp + 60 minutes,
            ipfsUri: "QmXxDV1vyGC2mCdqUJcq1sW9vjbi3ieA9jvmBv6Bmm4Non"
        });

        vm.expectRevert(IRainPool.StartTimeEnded.selector);
        new RainPool(params);
    }

    function test_Constructor_Fails_WithLessThanMinimumOptions() public {
        IRainPool.Params memory params = IRainPool.Params({
            initialLiquidity: initalLiquidity,
            liquidityPercentages: liquidityPercentages,
            isPublic: false,
            resolverIsAI: true,
            deployerContract: address(rainDeployer),
            baseToken: address(baseToken),
            baseTokenDecimals: baseTokenDecimals,
            poolOwner: address(poolOwner),
            platformAddress: address(poolOwner),
            resolver: address(poolOwner),
            rainToken: rainToken,
            swapRouter: swapRouter,
            startTime: block.timestamp + 1 seconds,
            endTime: block.timestamp + 30 minutes,
            numberOfOptions: 1,
            platformFee: 10,
            liquidityFee: 10,
            creatorFee: 10,
            resultResolverFee: 10,
            oracleFixedFee: 10,
            oracleEndTime: block.timestamp + 60 minutes,
            ipfsUri: "QmXxDV1vyGC2mCdqUJcq1sW9vjbi3ieA9jvmBv6Bmm4Non"
        });

        vm.expectRevert(IRainPool.MinimumOptionsShouldBeTwo.selector);
        new RainPool(params);
    }

    function test_CorrectDeployment() public view {
        assertEq(
            rainPool.baseToken(),
            address(baseToken),
            "Base Token not correctly set."
        );
    }

    function test_SaleIsLive_Fails_BeforeStart() public {
        vm.startPrank(addr1);
        vm.expectRevert(IRainPool.SaleNotLive.selector);

        rainPool.enterOption(1, 100);
        vm.stopPrank();
    }

    function test_SaleIsLive_Fails_WinnerFinalized() public {
        vm.warp(block.timestamp + 11 days);

        vm.startPrank(rainPool.resolver());

        rainPool.closePool();
        rainPool.chooseWinner(2);

        vm.stopPrank();

        vm.startPrank(addr1);
        vm.expectRevert(IRainPool.WinnerAlreadyFinalized.selector);

        rainPool.enterOption(1, 100);
        vm.stopPrank();
    }

    function test_SaleIsLive_Succeeds_DuringSale() public {
        vm.warp(block.timestamp + 30 minutes);
        uint256 amount = 10 * 11 * (10 ** baseTokenDecimals);
        baseToken.transfer(addr1, amount);
        vm.startPrank(addr1);
        baseToken.approve(address(rainPool), 1000 ether);
        rainPool.enterOption(1, 100);

        vm.stopPrank();
    }

    function test_Enter_Liquidity() public {
        vm.warp(block.timestamp + 30 minutes);
        uint256 amount = 10 * 11 * (10 ** baseTokenDecimals);
        baseToken.transfer(addr1, amount);
        vm.startPrank(addr1);
        baseToken.approve(address(rainPool), amount);
        rainPool.enterLiquidity(amount);
        assertEq(rainPool.totalLiquidity(), amount + initalLiquidity);

        vm.warp(rainPool.endTime() + 1);
        rainPool.closePool();
        vm.stopPrank();

        vm.warp(block.timestamp + 15 minutes);

        vm.startPrank(rainPool.resolver());
        rainPool.chooseWinner(1);
        vm.stopPrank();

        vm.warp(block.timestamp + 61 minutes);

        vm.startPrank(addr1);
        rainPool.claim();
        vm.stopPrank();
    }

    function test_Enter_LiquidityDistribution() public {
        vm.warp(block.timestamp + 30 minutes);
        uint256 totalAmount = 10 * 11 * (10 ** baseTokenDecimals);
        baseToken.transfer(addr1, totalAmount);
        vm.startPrank(addr1);
        // uint256 noOfOptions = rainPool.numberOfOptions(); // Number of options
        // uint256 expectedPerOption = totalAmount / noOfOptions;

        // User enters liquidity
        baseToken.approve(address(rainPool), totalAmount);
        rainPool.enterLiquidity(totalAmount);

        // // Assert total user liquidity is the total amount
        assertEq(
            rainPool.userLiquidity(addr1),
            totalAmount,
            "User liquidity should match the total amount"
        );

        // Assert total liquidity in the pool matches the user liquidity
        assertEq(
            rainPool.totalLiquidity(),
            totalAmount + initalLiquidity,
            "Total pool liquidity should match the user liquidity"
        );
        vm.stopPrank();
    }

    function test_Enter_Option() public {
        vm.warp(block.timestamp + 20 minutes);
        uint256 amount = 10e6;
        // Transfer base tokens to addr1 and approve the RainPool contract
        baseToken.transfer(addr1, amount * 2);

        vm.startPrank(addr1);
        baseToken.approve(address(rainPool), amount * 2);

        rainPool.enterOption(1, amount);

        uint256 totalVotes = rainPool.totalVotes(1);
        vm.stopPrank();

        vm.startPrank(addr1);
        vm.warp(block.timestamp + 5 minutes);

        rainPool.enterOption(1, amount);

        totalVotes = rainPool.totalVotes(1);
        vm.stopPrank();

        vm.warp(rainPool.endTime() + 1);
        vm.startPrank(rainPool.resolver());
        rainPool.closePool();
        rainPool.chooseWinner(1);
        vm.stopPrank();

        vm.warp(block.timestamp + 61 minutes);

        vm.startPrank(addr1);
        rainPool.claim();
        vm.stopPrank();
    }

    function test_EndToEndFlow_Private() public {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS

        approveAndEnterOptionPrivate(addr1, 1, 10);

        approveAndEnterOptionPrivate(user2, 2, 1000);

        approveAndEnterOptionPrivate(user3, 2, 15000);

        approveAndEnterOptionPrivate(user4, 2, 50);

        approveAndEnterOptionPrivate(user5, 1, 40);

        approveAndEnterLiquidityPrivate(user6, 95);

        vm.warp(block.timestamp + 8 hours);
        vm.startPrank(poolOwner);

        rainPool.closePool();
        vm.stopPrank();

        vm.warp(block.timestamp + 15 minutes);

        vm.startPrank(addr1);
        vm.expectRevert(IRainPool.OnlyResolver.selector);
        rainPool.chooseWinner(2);

        vm.stopPrank();

        vm.startPrank(rainPool.resolver());
        rainPool.chooseWinner(2);
        vm.stopPrank();

        vm.warp(block.timestamp + 61 minutes);

        vm.expectRevert();
        claimRewardsFromPoolPrivate(addr1);
        claimRewardsFromPoolPrivate(user2);
        claimRewardsFromPoolPrivate(user3);
        claimRewardsFromPoolPrivate(user4);
        vm.expectRevert();
        claimRewardsFromPoolPrivate(user5);
        claimRewardsFromPoolPrivate(user6);

        claimRewardsFromPoolPrivate(poolOwner);
    }

    function test_EndToEndFlow_Public() public {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS
        approveAndEnterOptionPublic(addr1, 1, 20000);
        approveAndEnterOptionPublic(user2, 2, 10000);
        approveAndEnterOptionPublic(user3, 2, 15000);
        approveAndEnterOptionPublic(user4, 2, 50000);
        approveAndEnterOptionPublic(user5, 1, 40000);
        approveAndEnterLiquidityPublic(user6, 95000);

        vm.warp(block.timestamp + 8 hours + 30 minutes);
        vm.startPrank(poolOwner);
        rainPoolPublic.closePool();
        vm.stopPrank();

        vm.expectRevert();
        claimRewardsFromPoolPublic(user2);

        vm.startPrank(resolverAI);
        rainPoolPublic.chooseWinner(2);

        vm.expectRevert();
        claimRewardsFromPoolPublic(user2);

        vm.warp(block.timestamp + 61 minutes);

        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);
        claimRewardsFromPoolPublic(user2);
        claimRewardsFromPoolPublic(user3);
        claimRewardsFromPoolPublic(user4);
        vm.expectRevert();
        claimRewardsFromPoolPublic(user5);
        claimRewardsFromPoolPublic(user6);
    }

    function test_ClosePool_Resolver() external {
        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS
        approveAndEnterOptionPublic(addr1, 1, 20000);
        approveAndEnterOptionPublic(user2, 2, 10000);
        approveAndEnterOptionPublic(user3, 2, 15000);
        approveAndEnterOptionPublic(user4, 2, 50000);
        approveAndEnterOptionPublic(user5, 1, 40000);
        approveAndEnterLiquidityPublic(user6, 95000);

        vm.expectRevert(IRainPool.SaleStillLive.selector);
        vm.prank(user2);
        rainPoolPublic.closePool();

        vm.prank(poolOwner);
        rainPoolPublic.closePool();
    }

    function test_FeeTierAmounts() external {
        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        uint256 fee = (returnInEther(10) * platformFee) / 1000;

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS
        approveAndEnterOptionPublic(addr1, 1, 200000);
        fee += (returnInEther(200000) * platformFee) / 1000;
        assertEq(rainPoolPublic.platformShare(), fee);

        approveAndEnterOptionPublic(user2, 2, 10000);
        fee += (returnInEther(10000) * platformFee) / 1000;
        assertEq(rainPoolPublic.platformShare(), fee);

        approveAndEnterOptionPublic(user3, 2, 15000);
        fee += (returnInEther(15000) * platformFee) / 1000;
        assertEq(rainPoolPublic.platformShare(), fee);

        approveAndEnterOptionPublic(user4, 2, 50000);
        fee += (returnInEther(50000) * platformFee) / 1000;
        assertEq(rainPoolPublic.platformShare(), fee);

        approveAndEnterOptionPublic(user5, 1, 40000);
        fee += (returnInEther(40000) * platformFee) / 1000;
        assertEq(rainPoolPublic.platformShare(), fee);

        approveAndEnterLiquidityPublic(user6, 95000);
        fee += (returnInEther(95000) * platformFee) / 1000;
        assertEq(rainPoolPublic.platformShare(), fee);
    }

    function test_OrderBook() external {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS

        approveAndEnterOptionPublic(addr1, 1, 20);

        approveAndEnterOptionPublic(user2, 2, 10);

        approveAndEnterOptionPublic(user3, 2, 15);

        approveAndEnterOptionPublic(user4, 2, 50);

        approveAndEnterOptionPublic(user5, 1, 40);

        approveAndEnterLiquidityPublic(user6, 95);

        placeSellOrderPublic(
            user2,
            2,
            0.01 ether,
            rainPoolPublic.userVotes(2, user2)
        );

        assertEq(
            rainPoolPublic.userVotesInEscrow(2, user2),
            rainPoolPublic.userVotes(2, user2),
            "user2 vote should be in escrow."
        );
        assertEq(
            rainPoolPublic.userActiveSellOrders(user2),
            1,
            "user2 should have active sell orders."
        );

        placeSellOrderPublic(
            user3,
            2,
            0.9 ether,
            rainPoolPublic.userVotes(2, user3)
        );

        assertEq(
            rainPoolPublic.userVotesInEscrow(2, user3),
            rainPoolPublic.userVotes(2, user3),
            "user3 vote should be in escrow."
        );
        assertEq(
            rainPoolPublic.userActiveSellOrders(user3),
            1,
            "user3 should have active sell orders."
        );

        approveAndEnterOptionPublic(user2, 2, 1000);

        assertEq(
            rainPoolPublic.userVotesInEscrow(2, user3),
            0,
            "user3 vote should be in escrow."
        );
        assertEq(
            rainPoolPublic.userVotes(2, user3),
            0,
            "user3 vote should be in escrow."
        );
        assertEq(
            rainPoolPublic.userActiveSellOrders(user3),
            0,
            "user3 should have active sell orders."
        );

        uint256 i = 0;
        for (; i < 50; ) {
            placeSellOrderPublic(
                user6,
                2,
                0.99 ether,
                (rainPoolPublic.userVotes(2, user6) % 100000) + 1
            );
            unchecked {
                ++i;
            }
        }

        assertEq(
            rainPoolPublic.userVotesInEscrow(2, user6),
            3081850,
            "user6 vote should be in escrow."
        );
        assertEq(
            rainPoolPublic.userActiveSellOrders(user6),
            50,
            "user6 should have active sell orders."
        );

        approveAndEnterOptionPublic(user2, 2, 10000);

        assertEq(
            rainPoolPublic.userVotesInEscrow(2, user6),
            0,
            "user6 vote should not be in escrow."
        );
        assertEq(
            rainPoolPublic.userActiveSellOrders(user6),
            0,
            "user6 should not have any active sell orders."
        );

        vm.warp(block.timestamp + 8 hours);

        vm.prank(poolOwner);
        rainPoolPublic.closePool();

        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);

        vm.startPrank(resolverAI);
        rainPoolPublic.chooseWinner(2);

        vm.warp(block.timestamp + 61 minutes);

        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);
        claimRewardsFromPoolPublic(user2);
        vm.expectRevert();
        claimRewardsFromPoolPublic(user3);
        claimRewardsFromPoolPublic(user4);
        vm.expectRevert();
        claimRewardsFromPoolPublic(user5);
        claimRewardsFromPoolPublic(user6);
    }

    function test_OrderBook_After_PoolFinalized() external {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS

        approveAndEnterOptionPublic(addr1, 1, 20);

        approveAndEnterOptionPublic(user2, 2, 10);

        approveAndEnterOptionPublic(user3, 2, 15);

        approveAndEnterOptionPublic(user4, 2, 50);

        approveAndEnterOptionPublic(user5, 1, 40);

        approveAndEnterLiquidityPublic(user6, 95);

        vm.warp(block.timestamp + 8 hours);

        vm.prank(poolOwner);
        rainPoolPublic.closePool();

        placeSellOrderPublic(
            user3,
            2,
            0.55 ether,
            rainPoolPublic.userVotes(2, user3)
        );

        assertEq(
            rainPoolPublic.userVotes(2, user3),
            rainPoolPublic.userVotesInEscrow(2, user3),
            "User 3 votes should be in escrow."
        );

        uint256 i = 0;
        for (; i < 50; ) {
            placeSellOrderPublic(
                user6,
                2,
                0.56 ether,
                (rainPoolPublic.userVotes(2, user6) % 1000000) + 1
            );
            unchecked {
                ++i;
            }
        }

        assertEq(
            rainPoolPublic.userVotesInEscrow(2, user6),
            33081850,
            "user6 vote should be in escrow."
        );
        assertEq(
            rainPoolPublic.userActiveSellOrders(user6),
            50,
            "user6 should have active sell orders."
        );

        approveAndEnterOptionPublic(user2, 2, 1000);

        assertEq(
            rainPoolPublic.userVotesInEscrow(2, user6),
            0,
            "user6 vote should not be in escrow."
        );
        assertEq(
            rainPoolPublic.userActiveSellOrders(user6),
            0,
            "user6 should not have any active sell orders."
        );

        approveAndEnterOptionPublic(user2, 2, 1000);

        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);

        vm.startPrank(resolverAI);
        rainPoolPublic.chooseWinner(2);

        vm.warp(block.timestamp + 61 minutes);

        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);
        claimRewardsFromPoolPublic(user2);
        vm.expectRevert();
        claimRewardsFromPoolPublic(user3);
        claimRewardsFromPoolPublic(user4);
        vm.expectRevert();
        claimRewardsFromPoolPublic(user5);
        claimRewardsFromPoolPublic(user6);
    }

    function test_OrderBook_BuyOrders() external {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS

        approveAndEnterOptionPublic(addr1, 1, 2000);
        approveAndEnterOptionPublic(user2, 2, 10000);
        approveAndEnterOptionPublic(user3, 2, 15);
        approveAndEnterOptionPublic(user4, 2, 50);
        approveAndEnterOptionPublic(user5, 1, 40);
        approveAndEnterLiquidityPublic(user6, 95);

        // buy orders

        placeBuyOrderPublic(user2, 1, 0.55 ether, returnInEther(10));
        placeBuyOrderPublic(user2, 1, 0.56 ether, returnInEther(10));
        placeBuyOrderPublic(user3, 1, 0.55 ether, returnInEther(100));

        placeSellOrderPublic(
            addr1,
            1,
            0.5 ether,
            rainPoolPublic.userVotes(1, addr1)
        );
        uint256 orderID2 = placeSellOrderPublic(
            user2,
            2,
            0.5 ether,
            rainPoolPublic.userVotes(2, user2)
        );
        uint256 orderID = placeSellOrderPublic(
            user3,
            1,
            0.5 ether,
            rainPoolPublic.userVotes(1, user3)
        );

        cancelSellOrdersPublic(user3, 1, 0.5 ether, orderID);

        placeBuyOrderPublic(user2, 1, 0.6 ether, returnInEther(10));

        placeBuyOrderPublic(user2, 1, 0.6 ether, returnInEther(10));

        placeBuyOrderPublic(user2, 1, 0.6 ether, returnInEther(10));

        orderID = placeBuyOrderPublic(
            user2,
            1,
            0.6 ether,
            returnInEther(10000)
        );

        vm.warp(block.timestamp + 8 hours);

        vm.prank(poolOwner);
        rainPoolPublic.closePool();

        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);

        vm.startPrank(resolverAI);
        rainPoolPublic.chooseWinner(2);

        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);

        cancelSellOrdersPublic(user2, 2, 0.5 ether, orderID2);
        cancelBuyOrdersPublic(user2, 1, 0.6 ether, orderID);

        vm.warp(block.timestamp + 60 minutes);

        claimRewardsFromPoolPublic(user2);
        // vm.expectRevert();
        claimRewardsFromPoolPublic(user3);
        claimRewardsFromPoolPublic(user4);
        vm.expectRevert();
        claimRewardsFromPoolPublic(user5);
        claimRewardsFromPoolPublic(user6);
    }

    function test_OrderBook_ExtraWei() external {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS

        approveAndEnterOptionPublic(poolOwner, 1, 200);

        placeSellOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(2));

        placeSellOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(2));

        placeBuyOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(1));

        placeSellOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(2));

        placeBuyOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(2));

        placeSellOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(2));

        placeBuyOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(3));

        placeSellOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(21));

        placeBuyOrderPublic(poolOwner, 1, 0.7 ether, returnInEther(7));

        vm.warp(block.timestamp + 8 hours);

        vm.prank(poolOwner);
        rainPoolPublic.closePool();

        vm.startPrank(resolverAI);
        rainPoolPublic.chooseWinner(2);

        vm.warp(block.timestamp + 60 minutes);

        claimRewardsFromPoolPublic(poolOwner);
    }

    function test_User_Dispute() external {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS

        approveAndEnterOptionPublic(addr1, 1, 2000);
        approveAndEnterOptionPublic(user2, 2, 10000);
        approveAndEnterOptionPublic(user3, 2, 15);
        approveAndEnterOptionPublic(user4, 2, 50);
        approveAndEnterOptionPublic(user5, 1, 40);
        approveAndEnterLiquidityPublic(user6, 95);

        vm.warp(block.timestamp + 33 minutes);

        vm.prank(poolOwner);
        rainPoolPublic.closePool();

        vm.prank(resolverAI);
        rainPoolPublic.chooseWinner(1);

        uint256 collateralFee = (rainPoolPublic.allFunds() * 10) / 1000;

        deal(address(baseToken), user2, collateralFee);

        vm.prank(user2);
        baseToken.approve(address(rainPoolPublic), collateralFee);

        vm.prank(user2);
        rainPoolPublic.openDispute();

        vm.warp(block.timestamp + 60 minutes);

        vm.expectRevert();
        vm.prank(user2);
        rainPoolPublic.openDispute();

        oracleFactory.selectWinnerMock(2);
        vm.expectRevert();
        claimRewardsFromPoolPublic(addr1);
        claimRewardsFromPoolPublic(user2);
        claimRewardsFromPoolPublic(user3);
        claimRewardsFromPoolPublic(user4);
        vm.expectRevert();
        claimRewardsFromPoolPublic(user5);
        claimRewardsFromPoolPublic(user6);
    }

    function test_Oracle_Fails() external {
        // Warp the time to start sale
        vm.warp(block.timestamp + 5 minutes);

        // Create 5 new users
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");

        // ENTER ALL THE USERS IN SOME OR BOTH OPTIONS

        approveAndEnterOptionPublic(addr1, 1, 2000);
        approveAndEnterOptionPublic(user2, 2, 10000);
        approveAndEnterOptionPublic(user3, 2, 15);
        approveAndEnterOptionPublic(user4, 2, 50);
        approveAndEnterOptionPublic(user5, 1, 40);
        approveAndEnterLiquidityPublic(user6, 95);

        vm.warp(block.timestamp + 33 minutes);

        vm.prank(poolOwner);
        rainPoolPublic.closePool();

        vm.prank(resolverAI);
        rainPoolPublic.chooseWinner(1);

        uint256 collateralFee = (rainPoolPublic.allFunds() * 10) / 1000;

        deal(address(baseToken), user2, collateralFee);

        vm.prank(user2);
        baseToken.approve(address(rainPoolPublic), collateralFee);

        vm.prank(user2);
        rainPoolPublic.openDispute();

        vm.warp(block.timestamp + 15 minutes);

        vm.expectRevert();
        vm.prank(user2);
        rainPoolPublic.openDispute();

        oracleFactory.selectWinnerMock(2);
    }

    function test_Fee() external {
        uint256 arbitrumFork = vm.createFork("https://arb1.arbitrum.io/rpc");
        vm.selectFork(arbitrumFork);

        RainPool feeRainPool = RainPool(
            0x15dBd4Ff232CfBCE5a936ee566070528CcAE6aAA
        );

        address caller = 0x260bd45Be7d44c4631BFE661586E8aaD393266e1;

        vm.startPrank(caller);

        uint256[] memory payouts = feeRainPool.getDynamicPayout(caller);

        console.log(payouts[1], payouts[2]);
    }

    // NOTE: Function for live testing only. Keep commented unless needed.
    // function test_Live_Prod() external {
    //     RainPool rainPoolLive = RainPool(
    //         0x9F2Ccd32Ef9d60Ea1E484030a2D8bb73D0b9985A
    //     );
    //     address testWallet = 0x5F11429D88a978a9a7ad793F73b8F24A0a6163e2;

    //     IERC20 USDC = IERC20(0xAa359e618220c247dce867164305f2eb737C646D);

    //     vm.startPrank(testWallet);

    //     USDC.approve(address(rainPoolLive), returnInEther(10));

    //     rainPoolLive.placeBuyOrder(1, 0.6 ether, returnInEther(7));

    //     vm.stopPrank();
    // }

    /* ======================== HELPER FUNCTIONS ======================== */

    function approveAndEnterOptionPrivate(
        address user,
        uint256 option,
        uint256 amount
    ) internal {
        baseToken.transfer(user, returnInEther(amount));
        vm.startPrank(user);
        baseToken.approve(address(rainPool), returnInEther(amount));
        assertEq(baseToken.balanceOf(user), returnInEther(amount));
        rainPool.enterOption(option, returnInEther(amount));
        vm.stopPrank();
    }

    function approveAndEnterOptionPublic(
        address user,
        uint256 option,
        uint256 amount
    ) internal {
        baseToken.transfer(user, returnInEther(amount));
        vm.startPrank(user);
        baseToken.approve(address(rainPoolPublic), returnInEther(amount));
        rainPoolPublic.enterOption(option, returnInEther(amount));
        vm.stopPrank();
    }

    function approveAndEnterLiquidityPrivate(
        address user,
        uint256 amount
    ) internal {
        baseToken.transfer(user, returnInEther(amount));
        vm.startPrank(user);
        baseToken.approve(address(rainPool), returnInEther(amount));
        assertEq(baseToken.balanceOf(user), returnInEther(amount));

        rainPool.enterLiquidity(returnInEther(amount)); //User adds liquidity in both options
        vm.stopPrank();
    }

    function approveAndEnterLiquidityPublic(
        address user,
        uint256 amount
    ) internal {
        baseToken.transfer(user, returnInEther(amount));
        vm.startPrank(user);
        baseToken.approve(address(rainPoolPublic), returnInEther(amount));
        assertEq(baseToken.balanceOf(user), returnInEther(amount));
        rainPoolPublic.enterLiquidity(returnInEther(amount));

        vm.stopPrank();
    }

    function placeSellOrderPublic(
        address user,
        uint256 option,
        uint256 price,
        uint256 amount // Number of shares to sell
    ) internal returns (uint256 orderID) {
        vm.startPrank(user);

        orderID = rainPoolPublic.placeSellOrder(option, price, amount);

        vm.stopPrank();
    }

    function placeBuyOrderPublic(
        address user,
        uint256 option,
        uint256 price,
        uint256 amount // Amount in USDT for the order
    ) internal returns (uint256 orderID) {
        deal(address(baseToken), user, amount);

        vm.startPrank(user);
        baseToken.approve(address(rainPoolPublic), amount);

        orderID = rainPoolPublic.placeBuyOrder(option, price, amount);

        vm.stopPrank();
    }

    function cancelSellOrdersPublic(
        address user,
        uint256 option,
        uint256 price,
        uint256 orderID
    ) internal {
        vm.startPrank(user);

        uint256[] memory options = new uint256[](1);
        options[0] = option;

        uint256[] memory prices = new uint256[](1);
        prices[0] = price;

        uint256[] memory orderIDs = new uint256[](1);
        orderIDs[0] = orderID;

        rainPoolPublic.cancelSellOrders(options, prices, orderIDs);
        vm.stopPrank();
    }

    function cancelBuyOrdersPublic(
        address user,
        uint256 option,
        uint256 price,
        uint256 orderID
    ) internal {
        vm.startPrank(user);

        uint256[] memory options = new uint256[](1);
        options[0] = option;

        uint256[] memory prices = new uint256[](1);
        prices[0] = price;

        uint256[] memory orderIDs = new uint256[](1);
        orderIDs[0] = orderID;

        // baseToken.approve(address(rainPoolPublic), price * amount);

        rainPoolPublic.cancelBuyOrders(options, prices, orderIDs);
        vm.stopPrank();
    }

    function claimRewardsFromPoolPrivate(address user) internal {
        vm.startPrank(user);
        rainPool.claim();
        vm.stopPrank();
    }

    function claimRewardsFromPoolPublic(address user) internal {
        vm.startPrank(user);
        rainPoolPublic.claim();
        vm.stopPrank();
    }

    function returnInEther(uint256 amount) public view returns (uint256) {
        return amount * (10 ** baseTokenDecimals);
    }
}
