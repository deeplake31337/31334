// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import { RainDeployer, IRainDeployer, IERC20 } from "../src/RainDeployer.sol";

contract DeployRainPool is Script {
    // Add deployer contract address here. Make sure the checksum is in correct format.
    RainDeployer rainDeployer =
        RainDeployer(address(0xccCB3C03D9355B01883779EF15C1Be09cf3623F1));
    address baseTokenAddress = vm.envAddress("USDT");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256[] memory liquidityPercentages = new uint256[](2);
        liquidityPercentages[0] = 50;
        liquidityPercentages[1] = 50;

        IERC20(baseTokenAddress).approve(
            address(rainDeployer),
            type(uint256).max
        );

        RainDeployer.Params memory params = IRainDeployer.Params({
            isPublic: false,
            resolverIsAI: true,
            poolOwner: msg.sender,
            startTime: block.timestamp + 5 minutes,
            endTime: block.timestamp + 2 days,
            numberOfOptions: 2,
            oracleEndTime: block.timestamp + 3 days,
            ipfsUri: "QmXxDV1vyGC2mCdqUJcq1sW9vjbi3ieA9jvmBv6Bmm4Non",
            initialLiquidity: 1,
            liquidityPercentages: liquidityPercentages,
            poolResolver: msg.sender
        });

        rainDeployer.createPool(params);

        console.log("RainPool deployed at:", address(rainDeployer));

        vm.stopBroadcast();
    }
}
