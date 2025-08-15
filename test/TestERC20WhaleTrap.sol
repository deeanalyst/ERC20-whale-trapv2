// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "src/ERC20WhaleTrap.sol";

/// @notice Test version of ERC20WhaleTrap that allows setting addresses in the constructor
contract TestERC20WhaleTrap is ITrap {
    address public immutable trackedAddress;
    IERC20 public immutable token;
    AggregatorV3Interface public immutable priceFeed;

    uint256 public constant BALANCE_THRESHOLD = 1000 * 1e18;
    int256 public constant PRICE_THRESHOLD = 50e8;

    mapping(address => bool) public whitelist;

    constructor(address _trackedAddress, address _tokenAddress, address _priceFeedAddress) {
        trackedAddress = _trackedAddress;
        token = IERC20(_tokenAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        whitelist[msg.sender] = true;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    function collect() external view override onlyWhitelisted returns (bytes memory) {
        uint256 tokenBalance = token.balanceOf(trackedAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return abi.encode(trackedAddress, tokenBalance, price);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        (address tracked0, uint256 balance0, int256 price0) = abi.decode(data[0], (address, uint256, int256));
        (address tracked1, uint256 balance1, int256 price1) = abi.decode(data[1], (address, uint256, int256));

        uint256 balanceDiff = balance1 > balance0 ? balance1 - balance0 : balance0 - balance1;
        int256 priceDiff = abs(price1 - price0);

        bool triggered = (balanceDiff > BALANCE_THRESHOLD) && (priceDiff > PRICE_THRESHOLD);

        if (triggered) {
            return (true, abi.encode(tracked1, balance0, balance1, price0, price1));
        }

        return (false, "");
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function addToWhitelist(address _user) external {
        whitelist[_user] = true;
    }
}
