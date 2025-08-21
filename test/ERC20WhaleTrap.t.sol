// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20WhaleTrap} from "../src/ERC20WhaleTrap.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";

contract ERC20WhaleTrapTest is Test {
    ERC20WhaleTrap public trap;
    MockERC20 public token;
    MockV3Aggregator public priceFeed;

    // --- Constants from ERC20WhaleTrap ---
    address private constant TOKEN_ADDR = 0x26aeAb946Be6f4619dBBF88Fcc3C82C68506f9Ab;
    address private constant PRICE_FEED_ADDR = 0x076BeCb937C163c6a963917CB970e2125B67a927;
    address private constant TRACKED_WHALE = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    // ---

    address internal constant OPERATOR = 0x0000000000000000000000000000000000000001;

    function setUp() public {
        // Deploy mock contracts to get their bytecode
        MockERC20 mockToken = new MockERC20("Mock Token", "MTK");
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(0); // Initial value doesn't matter here

        // Place the bytecode at the hardcoded addresses
        vm.etch(TOKEN_ADDR, address(mockToken).code);
        vm.etch(PRICE_FEED_ADDR, address(mockPriceFeed).code);

        // Point our test contract's variables to those addresses
        token = MockERC20(TOKEN_ADDR);
        priceFeed = MockV3Aggregator(PRICE_FEED_ADDR);

        // Manually initialize the state of the etched contract
        priceFeed.setLatestAnswer(2000e8); // Initial price $2000

        // Now we can instantiate the trap
        trap = new ERC20WhaleTrap();
    }

    function test_Collect() public {
        bytes memory data = trap.collect();
        (address tracked, uint256 balance, int256 price) = abi.decode(data, (address, uint256, int256));

        assertEq(tracked, TRACKED_WHALE);
        assertEq(balance, 0, "Initial balance should be 0");
        assertEq(price, 2000e8, "Initial price should be 2000e8");
    }

    function test_ShouldRespond_NotTriggered_NoChange() public {
        bytes[] memory data = new bytes[](2);
        data[0] = trap.collect();
        data[1] = trap.collect();

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should, "Should not respond when there is no change");
    }

    function test_ShouldRespond_NotTriggered_BalanceChangeBelowThreshold() public {
        bytes[] memory data = new bytes[](2);
        data[0] = trap.collect();

        token.mint(TRACKED_WHALE, 500 * 1e18); // Below threshold

        data[1] = trap.collect();

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should, "Should not respond for balance change below threshold");
    }

    function test_ShouldRespond_NotTriggered_PriceChangeBelowThreshold() public {
        bytes[] memory data = new bytes[](2);
        data[0] = trap.collect();

        priceFeed.setLatestAnswer(2040e8); // Below price threshold

        data[1] = trap.collect();

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should, "Should not respond for price change below threshold");
    }

    function test_ShouldRespond_Triggered() public {
        bytes[] memory data = new bytes[](2);
        data[0] = trap.collect();

        token.mint(TRACKED_WHALE, 1500 * 1e18); // Above balance threshold
        priceFeed.setLatestAnswer(2100e8); // Above price threshold

        data[1] = trap.collect();

        (bool should, bytes memory responseData) = trap.shouldRespond(data);
        assertTrue(should, "Should respond when both thresholds are crossed");

        (address tracked, uint256 oldBalance, uint256 newBalance, int256 oldPrice, int256 newPrice) = abi.decode(responseData, (address, uint256, uint256, int256, int256));

        assertEq(tracked, TRACKED_WHALE);
        assertEq(oldBalance, 0);
        assertEq(newBalance, 1500 * 1e18);
        assertEq(oldPrice, 2000e8);
        assertEq(newPrice, 2100e8);
    }
}