// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20WhaleResponse} from "../src/ERC20WhaleResponse.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";

contract DeployContracts is Script {
    function run() external returns (address, address, address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the response contract
        ERC20WhaleResponse responseContract = new ERC20WhaleResponse();
        console.log("ERC20WhaleResponse deployed to:", address(responseContract));

        // Deploy the mock ERC20 token
        MockERC20 mockToken = new MockERC20("Mock USDT", "USDT");
        console.log("MockERC20 (USDT) deployed to:", address(mockToken));

        // Deploy the mock price feed (e.g., for USDT/USD, 8 decimals)
        // Initial price: $1.00
        int256 initialPrice = 1 * 1e8;
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(initialPrice);
        console.log("MockV3Aggregator (USDT/USD) deployed to:", address(mockPriceFeed));

        vm.stopBroadcast();
        return (address(responseContract), address(mockToken), address(mockPriceFeed));
    }
}