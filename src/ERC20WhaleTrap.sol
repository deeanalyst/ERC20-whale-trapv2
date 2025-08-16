// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @notice ERC20 Whale Trap — monitors token balance + price feed changes
contract ERC20WhaleTrap is ITrap {
    /// @notice Monitored wallet address (whale)
    address public constant trackedAddress = 0xF38eED066703d093B20Be0A9D9fcC8684F64cdc4;

    

    /// @notice The ERC20 token to monitor
    IERC20 public constant token = IERC20(0x0000000000000000000000000000000000000002); // TODO: Replace with actual token address

    /// @notice The Chainlink price feed for the token
    AggregatorV3Interface public constant priceFeed = AggregatorV3Interface(0x0000000000000000000000000000000000000003); // TODO: Replace with actual price feed address

    /// @notice Threshold for token balance delta (in token's smallest unit)
    uint256 public constant BALANCE_THRESHOLD = 1000 * 1e18;

    /// @notice Threshold for price change (Chainlink decimals, e.g. 8 decimals)
    int256 public constant PRICE_THRESHOLD = 50e8;

    /// @notice Collects current tracked data: token balance + price
    function collect() external view override returns (bytes memory) {
        uint256 tokenBalance = token.balanceOf(trackedAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return abi.encode(trackedAddress, tokenBalance, price);
    }

    /// @notice Compares last and current data to decide if we should respond
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        (address tracked0, uint256 balance0, int256 price0) = abi.decode(data[0], (address, uint256, int256));
        (address tracked1, uint256 balance1, int256 price1) = abi.decode(data[1], (address, uint256, int256));

        // Check balance difference
        uint256 balanceDiff = balance1 > balance0 ? balance1 - balance0 : balance0 - balance1;

        // Check price difference
        int256 priceDiff = abs(price1 - price0);

        bool triggered = (balanceDiff > BALANCE_THRESHOLD) && (priceDiff > PRICE_THRESHOLD);

        if (triggered) {
            return (
                true,
                abi.encode(tracked1, balance0, balance1, price0, price1) // must match response function
            );
        }

        return (false, "");
    }

    /// @dev Simple absolute value for int256
    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}