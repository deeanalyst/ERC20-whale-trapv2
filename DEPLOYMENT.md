# Deployment Process

This document outlines the steps taken to deploy and configure the ERC20 Whale Trap project.

## 1. Deploy Mock Contracts

The first step was to deploy the mock contracts for the ERC20 token and the Chainlink price feed. This was done using the following command:

```bash
source .env && forge script scripts/DeployResponseProtocol.s.sol --rpc-url $HOODI_RPC_URL --broadcast
```

This command deployed the following contracts to the testnet:

*   **ERC20WhaleResponse:** `0x0cb8e05bde37321c139b3688523379dE89de110f`
*   **MockERC20 (USDT):** `0x420842116EB33c1235818cF460c5d13C7Bc0BBA7`
*   **MockV3Aggregator (USDT/USD):** `0x200E9015f5153dCE6F6D4795eA75f0893CF8874B`

The transaction details are saved in `broadcast/DeployResponseProtocol.s.sol/560048/run-latest.json`.

## 2. Update `ERC20WhaleTrap.sol`

After deploying the mock contracts, the `ERC20WhaleTrap.sol` file was updated with the new contract addresses. The following placeholders were replaced:

```solidity
// Before
IERC20 public constant token = IERC20(0x0000000000000000000000000000000000000002); // TODO: Replace with actual token address
AggregatorV3Interface public constant priceFeed = AggregatorV3Interface(0x0000000000000000000000000000000000000003); // TODO: Replace with actual price feed address

// After
IERC20 public constant token = IERC20(0x420842116EB33c1235818cF460c5d13C7Bc0BBA7); // MockERC20 (USDT)
AggregatorV3Interface public constant priceFeed = AggregatorV3Interface(0x200E9015f5153dCE6F6D4795eA75f0893CF8874B); // MockV3Aggregator (USDT/USD)
```

## 3. Update `drosera.toml`

The `drosera.toml` file was updated with the bytecode hash of the `ERC20WhaleTrap.sol` contract and the address of the deployed `ERC20WhaleResponse` contract.

First, the bytecode hash was calculated:

```bash
forge inspect ERC20WhaleTrap bytecode | sed 's/^0x//' | xxd -r -p | sha256sum
```

This command returned the following hash: `96604b4ee3f3cec58a305715881eca618f88e641c042eeb705560b5a1fa9caff`

The `drosera.toml` file was then updated as follows:

```toml
[traps.erc20whaletrap]
path = "out/ERC20WhaleTrap.sol/ERC20WhaleTrap.json"
response_contract = "0x0cb8e05bde37321c139b3688523379dE89de110f"
response_function = "respondWithERC20Context(address,uint256,uint256,int256,int256)"
cooldown_period_blocks = 10
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size = 2
private_trap = true
whitelist = []
trap_bytecode_hash = "96604b4ee3f3cec58a305715881eca618f88e641c042eeb705560b5a1fa9caff"
```

## 4. Run Tests

Finally, the test suite was run to ensure that all changes were working as expected:

```bash
forge test
```

All tests passed, confirming that the trap logic is functioning correctly.