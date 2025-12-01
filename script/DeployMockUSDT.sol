// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import { ERC20Mock } from "../src/mocks/ERC20Mock.sol";

contract DeployMockUSDT is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the ERC20Mock contract with name, symbol, and initial supply
        ERC20Mock token = new ERC20Mock(
            "Mock USDT",
            "mUSDT",
            1_000_000 * 10 ** 6
        );

        // Log the address
        console.log("Mock USDT deployed at:", address(token));

        vm.stopBroadcast();
    }
}
