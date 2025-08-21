// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TestERC20WhaleTrap} from "./TestERC20WhaleTrap.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";
import {ERC20WhaleResponse} from "../src/ERC20WhaleResponse.sol";

contract ERC20WhaleTrapTest is Test {
    TestERC20WhaleTrap public trap;
    MockERC20 public token;
    MockV3Aggregator public priceFeed;
    ERC20WhaleResponse public responseContract;

    address internal constant TRACKED_WHALE = 0xF38eED066703d093B20Be0A9D9fcC8684F64cdc4;
    address internal constant OPERATOR = 0x0000000000000000000000000000000000000001;

    function setUp() public {
        token = new MockERC20("Mock Token", "MTK");
        priceFeed = new MockV3Aggregator(2000e8); // Initial price $2000
        responseContract = new ERC20WhaleResponse();

        trap = new TestERC20WhaleTrap(TRACKED_WHALE, address(token), address(priceFeed));
        trap.addToWhitelist(OPERATOR);
    }

    function test_Collect() public {
        vm.prank(OPERATOR);
        bytes memory data = trap.collect();
        (address tracked, uint256 balance, int256 price) = abi.decode(data, (address, uint256, int256));

        assertEq(tracked, TRACKED_WHALE);
        assertEq(balance, 0);
        assertEq(price, 2000e8);
    }

    function test_ShouldRespond_NotTriggered_NoChange() public {
        bytes[] memory data = new bytes[](2);
        vm.prank(OPERATOR);
        data[0] = trap.collect();
        vm.prank(OPERATOR);
        data[1] = trap.collect();

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should);
    }

    function test_ShouldRespond_NotTriggered_BalanceChangeBelowThreshold() public {
        bytes[] memory data = new bytes[](2);
        vm.prank(OPERATOR);
        data[0] = trap.collect();

        token.mint(TRACKED_WHALE, 500 * 1e18); // Below threshold

        vm.prank(OPERATOR);
        data[1] = trap.collect();

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should);
    }

    function test_ShouldRespond_NotTriggered_PriceChangeBelowThreshold() public {
        bytes[] memory data = new bytes[](2);
        vm.prank(OPERATOR);
        data[0] = trap.collect();

        priceFeed.setLatestAnswer(2020e8); // Below threshold

        vm.prank(OPERATOR);
        data[1] = trap.collect();

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should);
    }

    function test_ShouldRespond_Triggered() public {
        bytes[] memory data = new bytes[](2);
        vm.prank(OPERATOR);
        data[0] = trap.collect();

        token.mint(TRACKED_WHALE, 1500 * 1e18); // Above threshold
        priceFeed.setLatestAnswer(2100e8); // Above threshold

        vm.prank(OPERATOR);
        data[1] = trap.collect();

        (bool should, bytes memory responseData) = trap.shouldRespond(data);
        assertTrue(should);

        (address tracked, uint256 oldBalance, uint256 newBalance, int256 oldPrice, int256 newPrice) = abi.decode(responseData, (address, uint256, uint256, int256, int256));

        assertEq(tracked, TRACKED_WHALE);
        assertEq(oldBalance, 0);
        assertEq(newBalance, 1500 * 1e18);
        assertEq(oldPrice, 2000e8);
        assertEq(newPrice, 2100e8);
    }

    function test_Whitelist_RevertsIfNotWhitelisted() public {
        address nonWhitelistedAddress = address(0xdeadbeef);
        vm.prank(nonWhitelistedAddress);
        vm.expectRevert("Not whitelisted");
        trap.collect();
    }
}
