// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {RainDeployer} from "../src/RainDeployer.sol";
import {RainFactory} from "../src/RainFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployRainPoolDeployer is Script {
    address baseTokenAddress = vm.envAddress("USDT");
    uint256 baseTokenDecimals = 6;
    address authorityAddress = 0xE2F215BbD5C214AC79BB1315d05117673c1A7D7e;
    address resolverAddress = 0xe05643b2266929C5181cABf09BC15018fB5c80e4;
    address rainTokenAddress = 0x00c5B4e382AF800037E00A31E3D3a7824e97bF9d;
    address swapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        RainFactory rainFactory = new RainFactory();
        console.log("RainFactory deployed at:", address(rainFactory));

        RainDeployer rainDeployerImplementation = new RainDeployer();
        console.log("RainDeployer Implementation deployed at:", address(rainDeployerImplementation));

        bytes memory rainDeployerParams = abi.encodeWithSelector(
            RainDeployer.initialize.selector,
            address(rainFactory),
            address(authorityAddress),
            baseTokenAddress,
            authorityAddress,
            resolverAddress,
            rainTokenAddress,
            swapRouterAddress,
            baseTokenDecimals,
            12,
            25,
            15 * (10 ** baseTokenDecimals),
            12,
            1
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(rainDeployerImplementation), rainDeployerParams);
        console.log("UUPS Proxy deployed at:", address(proxy));

        RainDeployer rainDeployer = RainDeployer(address(proxy));
        console.log("RainPool deployed at:", address(rainDeployer));

        vm.stopBroadcast();
    }
}
