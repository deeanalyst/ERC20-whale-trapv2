# ERC20 Whale Trap v2

This project implements a Drosera trap to monitor an ERC20 token for whale activity. The trap is triggered when a specific wallet's token balance and the token's price change significantly within a short period.

## Project Structure

- `src/`: Contains the Solidity contracts.
  - `ERC20WhaleTrap.sol`: The main trap contract that monitors the whale's balance and token price.
  - `ERC20WhaleResponse.sol`: The response contract that is triggered by the trap.
  - `mocks/`: Contains mock contracts for testing.
    - `MockERC20.sol`: A mock ERC20 token.
    - `MockV3Aggregator.sol`: A mock Chainlink price feed.
- `test/`: Contains the test files for the contracts.
- `scripts/`: Contains deployment scripts.
- `drosera.toml`: Configuration file for the Drosera trap.
- `foundry.toml`: Configuration file for the Foundry toolchain.

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- [Bun](https://bun.sh/)
- Drosera CLI (Installation instructions can be found in the official [Drosera GitHub](https://github.com/drosera-network) and their community resources)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd ERC20-whale-trapv2
   ```

2. Install dependencies:
   ```bash
   bun install
   ```

### Testing

To run the tests, use the following command:

```bash
forge test
```

## Contracts

### ERC20WhaleTrap.sol

This is the main trap contract that implements the `ITrap` interface from the Drosera protocol. It monitors a specific address (`trackedAddress`) for changes in its balance of a specific ERC20 token (`token`) and the token's price from a Chainlink price feed (`priceFeed`).

The trap is triggered when both the balance change and the price change exceed their respective thresholds (`BALANCE_THRESHOLD` and `PRICE_THRESHOLD`) between two consecutive data collections.

The `collect` function is protected by a whitelist, so only authorized addresses can trigger a data collection.

### ERC20WhaleResponse.sol

This contract is the response contract that is called by the Drosera protocol when the `ERC20WhaleTrap` is triggered. It emits an event with the details of the whale activity.

## Deployment

### 1. Deploy the Response Contract and Mocks

The `ERC20WhaleResponse` contract and any necessary mock contracts (for testing on a local network) can be deployed using Foundry.

```bash
forge script script/DeployResponseProtocol.s.sol --rpc-url <your-rpc-url> --private-key <your-private-key> --broadcast
```

### 2. Update Configuration

Before deploying the trap contract, you need to update the hardcoded addresses in `src/ERC20WhaleTrap.sol`:

- `token`: The address of the ERC20 token to monitor.
- `priceFeed`: The address of the Chainlink price feed for the token.

You also need to update the `response_contract` address in the `drosera.toml` file with the address of your deployed `ERC20WhaleResponse` contract.

### 3. Deploy the Trap Contract

The `ERC20WhaleTrap` contract must be deployed using the Drosera CLI. Please refer to the official Drosera resources you have (e.g., their GitHub repositories, workshops, and Notion FAQs) for the most up-to-date instructions on how to deploy a trap.