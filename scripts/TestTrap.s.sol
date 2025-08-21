// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";

contract TestTrap is Script {
    address public constant MOCK_ERC20_ADDRESS = 0x420842116EB33c1235818cF460c5d13C7Bc0BBA7;
    address public constant MOCK_V3_AGGREGATOR_ADDRESS = 0x200E9015f5153dCE6F6D4795eA75f0893CF8874B;
    address public constant TRACKED_ADDRESS = 0xa17b1106BF46ED526a77CE85E69031277adA4DC1;

    uint256 public constant MINT_AMOUNT = 2_000_000 * 1e18;
    uint256 public constant TRANSFER_AMOUNT = 1_500_000 * 1e18;
    int256 public constant UPDATED_PRICE = 110 * 1e8;

    function run() external {
        // Mint tokens to the tracked address
        // The mint function on MockERC20 is public and can be called by anyone
        vm.startBroadcast();
        MockERC20(MOCK_ERC20_ADDRESS).mint(TRACKED_ADDRESS, MINT_AMOUNT);
        vm.stopBroadcast();

        // Transfer tokens and update price
        vm.startBroadcast();
        MockERC20(MOCK_ERC20_ADDRESS).transfer(address(0xdead), TRANSFER_AMOUNT);
        MockV3Aggregator(MOCK_V3_AGGREGATOR_ADDRESS).setLatestAnswer(UPDATED_PRICE);
        vm.stopBroadcast();
    }
}