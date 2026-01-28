# Custom Pool - Cross-Chain DeFi Protocol

A comprehensive DeFi protocol enabling token swaps, cross-chain bridging, and cross-chain swaps with integrated price oracles.

## Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Supported Chains](#supported-chains)
- [Deployed Contracts](#deployed-contracts)
- [Prerequisites](#prerequisites)
- [Complete Deployment Guide](#complete-deployment-guide)
- [Testing Guide](#testing-guide)
- [Common Errors & Solutions](#common-errors--solutions)
- [Transaction Examples](#transaction-examples)
- [Gas Costs](#gas-costs)
- [Useful Commands](#useful-commands)

## Features

- **Token Swaps**: Exchange between different stablecoins (USDT, XSGD, THBT, IDRT) with 0.3% fee
- **Cross-Chain Bridge**: Lock/burn tokens on source chain, mint on destination chain
- **Price Oracle Integration**: Pyth Network for real-time forex price feeds
- **Vault Architecture**: Per-token vaults with deposit tracking and cross-chain support
- **Multi-Chain Support**: Sepolia, Arbitrum Sepolia, Polygon Amoy
- **Comprehensive Testing**: Unit tests, integration tests, and live on-chain testing

## Architecture

### Components

1. **Pool Contract** (`src/pool/Pool.sol`)
   - Handles token swaps with price oracle validation
   - 0.3% swap fee
   - Slippage protection with `minAmountOut`
   - Price staleness protection (60-second validity)

2. **Vault Contract** (`src/vault/Vault.sol`)
   - Per-token vault for managing deposits
   - Cross-chain lock (burn) functionality
   - Cross-chain mint functionality
   - User deposit tracking

3. **Token Contracts** (`src/tokens/`)
   - XSGD: Singapore Dollar stablecoin
   - USDT: Tether USD stablecoin
   - THBT: Thai Baht stablecoin
   - IDRT: Indonesian Rupiah stablecoin

### Transaction Types

| Type | Description | Example |
|------|-------------|---------|
| **SWAP** | Same chain, different currencies | 50 USDT → 63 XSGD on Sepolia |
| **BRIDGE** | Same currency, different chains | 30 USDT Sepolia → 30 USDT Arbitrum |
| **CROSS-CHAIN SWAP** | Different currency, different chains | 20 XSGD Sepolia → 16 USDT Arbitrum |

## Supported Chains

| Chain | Chain ID | Network Type | RPC Example |
|-------|----------|--------------|-------------|
| **Sepolia** | 11155111 | Ethereum Testnet | `https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY` |
| **Arbitrum Sepolia** | 421614 | L2 Testnet | `https://arbitrum-sepolia.g.alchemy.com/v2/YOUR_KEY` |
| **Polygon Amoy** | 80002 | Polygon Testnet | `https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY` |

## Deployed Contracts (Sepolia Testnet)

```
Pool:       0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa
USDT:       0x4B198D1285152B5f8BCbC5e4156D30717B16275e
XSGD:       0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385
THBT:       0x9CAe8d53b37ad934ABd341A86D369299B99a1F31
IDRT:       0xe36Aef5B7380f5eb6B5A822C7C51C6873e189467

USDT Vault: 0x965cCD245Eb8683BDC3202b1A1C87515774b833a
XSGD Vault: 0x2c71Ac4C6F5Fdb38B422c85D15121859171C5fD6
THBT Vault: 0x5F661641F7bf44989938143E94F46C6B7F8E3f98
IDRT Vault: 0x66e243a8e0fA2b5cF7a1e3b6d80EEdCDB666C8C8
```

## Prerequisites

### Required Software

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
anvil --version
```

### Environment Setup

Create a `.env` file in the project root:

```bash
# Private key (NEVER commit this file!)
PRIVATE_KEY=0x1234567890abcdef...

# RPC Endpoints
SEPOLIA_RPC=https://eth-sepolia.g.alchemy.com/v2/your-api-key
ARBITRUM_SEPOLIA_RPC=https://arbitrum-sepolia.g.alchemy.com/v2/your-api-key
POLYGON_AMOY_RPC=https://polygon-amoy.g.alchemy.com/v2/your-api-key

# Etherscan APIs (for contract verification)
ETHERSCAN_API_KEY=your-etherscan-key
ARBSCAN_API_KEY=your-arbscan-key
POLYGONSCAN_API_KEY=your-polygonscan-key
```

### Get Testnet Tokens

**Sepolia ETH**: https://sepoliafaucet.com/
**Arbitrum Sepolia ETH**: https://faucet.quicknode.com/arbitrum/sepolia
**Polygon Amoy MATIC**: https://faucet.polygon.technology/

## Complete Deployment Guide

### Phase 1: Initial Setup

#### Step 1: Install Dependencies

```bash
# Navigate to project directory
cd custom-pool

# Install git submodules (Pyth SDK)
git submodule update --init --recursive

# Build contracts
forge build
```

#### Step 2: Verify Environment

```bash
# Source environment variables
source ~/.zshenv
source .env

# Test RPC connection
cast block-number --rpc-url "$SEPOLIA_RPC"
cast chain-id --rpc-url "$SEPOLIA_RPC"

# Check wallet balance
cast balance <YOUR_ADDRESS> --rpc-url "$SEPOLIA_RPC"
```

### Phase 2: Deploy to Sepolia (Primary Chain)

#### Step 3: Deploy All Contracts

```bash
forge script script/DeployTestEnv.s.sol:DeployTestEnv \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast \
  --verify \
  -vvvv
```

**What this deploys:**
- 4 Token contracts (XSGD, USDT, THBT, IDRT) with 1,000,000 tokens each
- 1 Pool contract with Pyth oracle integration
- 4 Vault contracts (one per token)
- Funds each vault with 100,000 tokens (enables bidirectional swaps)
- Updates initial prices from Pyth oracles
- Transfers 900,000 tokens of each type to deployer

**Expected Output:**
```
=== Deploy Test Environment ===
Deployer: 0x...
Chain ID: 11155111

--- Deploying Tokens ---
XSGD: 0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385
USDT: 0x4B198D1285152B5f8BCbC5e4156D30717B16275e
THBT: 0x9CAe8d53b37ad934ABd341A86D369299B99a1F31
IDRT: 0xe36Aef5B7380f5eb6B5A822C7C51C6873e189467

--- Deploying Pool ---
Pool: 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa

--- Deploying Vaults ---
XSGD Vault: 0x2c71Ac4C6F5Fdb38B422c85D15121859171C5fD6
USDT Vault: 0x965cCD245Eb8683BDC3202b1A1C87515774b833a
THBT Vault: 0x5F661641F7bf44989938143E94F46C6B7F8E3f98
IDRT Vault: 0x66e243a8e0fA2b5cF7a1e3b6d80EEdCDB666C8C8

--- Funding Vaults ---
Bootstrapping pool with 400,000 tokens (100k per vault)
All vaults funded successfully!

Deployment complete!
```

#### Step 4: Verify Deployment

```bash
# Check contract code is deployed
cast code 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa --rpc-url "$SEPOLIA_RPC"

# Check pool owner
cast call 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa "owner()(address)" --rpc-url "$SEPOLIA_RPC"

# Check vault balances
cast call 0x965cCD245Eb8683BDC3202b1A1C87515774b833a "getBalance()(uint256)" --rpc-url "$SEPOLIA_RPC"

# View on Etherscan
echo "https://sepolia.etherscan.io/address/<DEPLOYER_ADDRESS>"
```

### Phase 3: Deploy to Polygon Amoy

#### Step 5: Create Polygon Deployment Script

Create `script/DeployPolygon.s.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/XSGD.sol";
import "../src/tokens/USDT.sol";
import "../src/vault/Vault.sol";
import "../src/pool/Pool.sol";

/**
 * @title DeployPolygon
 * @notice Deploy to Polygon Amoy testnet
 */
contract DeployPolygon is Script {
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 constant VAULT_LIQUIDITY = 100_000 * 10**18;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Deploy to Polygon Amoy ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        XSGD xsgd = new XSGD(deployer, INITIAL_SUPPLY);
        console.log("XSGD:", address(xsgd));

        USDT usdt = new USDT(deployer, INITIAL_SUPPLY);
        console.log("USDT:", address(usdt));

        // Deploy pool
        Pool pool = new Pool(address(this));
        console.log("Pool:", address(pool));

        // Deploy vaults
        Vault xsgdVault = new Vault(address(xsgd), address(pool), "XSGD Vault");
        Vault usdtVault = new Vault(address(usdt), address(pool), "USDT Vault");
        console.log("XSGD Vault:", address(xsgdVault));
        console.log("USDT Vault:", address(usdtVault));

        // Setup pool
        pool.setVault(address(xsgd), address(xsgdVault));
        pool.setVault(address(usdt), address(usdtVault));

        // Fund vaults through Pool
        xsgd.transfer(address(pool), VAULT_LIQUIDITY);
        usdt.transfer(address(pool), VAULT_LIQUIDITY);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = VAULT_LIQUIDITY;
        amounts[1] = VAULT_LIQUIDITY;

        pool.bootstrapPool(amounts);

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Save these addresses!");
    }
}
```

#### Step 6: Deploy to Polygon Amoy

```bash
forge script script/DeployPolygon.s.sol:DeployPolygon \
  --rpc-url "$POLYGON_AMOY_RPC" \
  --broadcast \
  --verify \
  -vvvv
```

**Expected Gas Cost**: ~0.5 MATIC

#### Step 7: Verify Polygon Deployment

```bash
# Check chain ID
cast chain-id --rpc-url "$POLYGON_AMOY_RPC"
# Should return: 80002

# View on PolygonScan
echo "https://amoy.polygonscan.com/address/<DEPLOYER_ADDRESS>"
```

### Phase 4: Deploy to Arbitrum Sepolia

#### Step 8: Deploy to Arbitrum

Similar to Polygon, create `script/DeployArbitrum.s.sol` and deploy:

```bash
forge script script/DeployArbitrum.s.sol:DeployArbitrum \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC" \
  --broadcast \
  --verify \
  -vvvv
```

### Phase 5: Cross-Chain Configuration

#### Step 9: Configure Cross-Chain Messengers

For each vault, set the cross-chain messenger (typically LayerZero, Wormhole, or CCIP):

```bash
# Set cross-chain messenger (only contract owner can call)
cast send <VAULT_ADDRESS> \
  "setCrossChainMessenger(address)" \
  <MESSENGER_ADDRESS> \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$SEPOLIA_RPC"
```

## Testing Guide

### Level 1: Unit Tests (Local)

```bash
# Run all unit tests
forge test

# Run with gas report
forge test --gas-report

# Run specific test contract
forge test --match-path test/Pool.t.sol -vvv

# Run specific test function
forge test --match-test testSwapFunction -vvv
```

**Expected Results:**
```
Running 23 tests for test/Pool.t.sol
[PASS] testSwapFunction() (gas: 156234)
[PASS] testInvalidSwap() (gas: 45678)
...
Test result: ok. 23 passed; 0 failed; finished (2.45s)
```

### Level 2: Integration Tests (Local)

```bash
# Test vault funding and swaps
forge test --match-path test/Integration.t.sol -vvv

# Test cross-chain operations
forge test --match-path test/CrossChainTest.t.sol -vvv
```

**Key Integration Tests:**
- `testFundedSwap`: Swap with pre-funded vaults
- `testCrossChainLock`: Lock tokens for cross-chain transfer
- `testCrossChainMint`: Mint tokens from cross-chain transfer
- `testBootstrapPool`: Pool vault funding mechanism

### Level 3: Comprehensive Scenarios (Local)

```bash
# Run all 14 scenario tests
forge test --match-path test/ComprehensiveScenarios.t.sol -vvv
```

**Scenarios Covered:**
1. Small swap (10 USDT → XSGD)
2. Medium swap (1,000 USDT → XSGD)
3. Large swap (5,000 USDT → XSGD)
4. Reverse swap (XSGD → USDT)
5. Small reverse swap (50 XSGD → USDT)
6. Large reverse swap (5,000 XSGD → USDT)
7. Slippage protection
8. Bridge operations
9. Cross-chain mint
10. Swap then bridge
11. Bridge then swap
12. Multi-hop swaps
13. Concurrent swaps
14. Full cross-chain swap

### Level 4: Live On-Chain Testing (Sepolia)

#### Step 1: Update Prices

**CRITICAL**: Prices expire after 60 seconds!

```bash
forge script script/UpdatePricesCorrect.s.sol:UpdatePricesCorrect \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast
```

**Expected Output:**
```
=== Update Prices (Actual Pyth Data) ===
Fetching from Pyth Hermes API...

Prices Updated:
  XSGD: $0.79 (1 SGD = 0.79 USD)
  THBT: $0.028 (estimated - no Pyth data)
  IDRT: $0.00006 (1 IDR = 0.00006 USD)
  USDT: $0.998

Valid for 60 seconds from 1737888440
```

#### Step 2: Execute Live Transactions

```bash
forge script script/RunLiveTransactions.s.sol:RunLiveTransactions \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast
```

**This executes:**
1. **Price Update**: Refreshes Pyth oracle prices
2. **Swap**: 50 USDT → 63 XSGD (Gas: ~147,000)
3. **Bridge**: Lock 30 USDT for Arbitrum Sepolia (Gas: ~93,000)
4. **Cross-Chain**: Lock 20 XSGD for Arbitrum Sepolia (Gas: ~93,000)

**Expected Output:**
```
=========================================
Step 1: Update Prices
=========================================
Prices updated successfully!

=========================================
Step 2: Execute Live Transactions
=========================================

=========================================
TRANSACTION 1: SWAP
=========================================
Transaction Type: SWAP
Input: 50 USDT
Output: 63 XSGD
Balance Changes:
  USDT: 899820 to 899770
  USDT spent: 50
  XSGD: 900114 to 900177
  XSGD received: 63
Gas Used: 147067

=========================================
TRANSACTION 2: BRIDGE (Same currency, different chain)
=========================================
Tokens Locked: 30 USDT
Vault Balance Before: 100230
Vault Balance After: 100260
User Deposit Before Lock: 60 USDT
User Deposit After Lock: 30 USDT
Tokens Burned: 30 USDT

=========================================
TRANSACTION 3: CROSS-CHAIN BRIDGE
=========================================
Token: XSGD
Amount: 20
Path: Sepolia to Arbitrum Sepolia

=========================================
TRANSACTION SUMMARY
=========================================

1. SWAP Transaction:
   50 USDT to 63 XSGD
   Gas Used: 147067

2. BRIDGE Transaction:
   30 USDT locked for Arbitrum Sepolia

3. CROSS-CHAIN BRIDGE Transaction:
   20 XSGD locked for Arbitrum Sepolia

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
```

#### Step 3: Verify Transactions

```bash
# Get transaction hashes from broadcast file
cat broadcast/RunLiveTransactions.s.sol/11155111/run-latest.json | jq -r '.transactions[] | .hash'

# View on Etherscan
echo "https://sepolia.etherscan.io/address/<DEPLOYER_ADDRESS>"
```

### Level 5: Cross-Chain Testing (Sepolia → Arbitrum)

#### Step 4: Test Cross-Chain Lock on Sepolia

```bash
forge script script/CrossChainTest.s.sol:CrossChainTest \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast
```

**This tests:**
1. Deposit 50 USDT into vault
2. Lock 50 USDT for Arbitrum Sepolia (burns tokens)
3. Simulate mint 30 USDT on destination chain

#### Step 5: Mint on Arbitrum Sepolia

```bash
# On Arbitrum Sepolia, mint tokens to user
cast send <ARBITRUM_VAULT_ADDRESS> \
  "mintFromCrossChain(address,uint256)" \
  <USER_ADDRESS> 30000000000000000000 \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC"
```

## Common Errors & Solutions

### Error 1: "Pool: stale price"

**Cause**: Prices are older than 60 seconds

**When it happens**:
- Running swap tests without updating prices first
- Executing live transactions after price expiration

**Solution**:
```bash
# Update prices immediately before swapping
forge script script/UpdatePricesCorrect.s.sol:UpdatePricesCorrect \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast

# Then run your swap/transaction
forge script script/LiveTransactions.s.sol:LiveTransactions \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast
```

**Prevention**: Always update prices before any swap operation.

### Error 2: "Vault: insufficient deposit"

**Cause**: User doesn't have enough deposited tokens in vault

**When it happens**:
- Attempting to lock more tokens than deposited
- User forgot to deposit tokens before locking

**Solution**:
```solidity
// Step 1: Approve vault
token.approve(VAULT_ADDRESS, amount);

// Step 2: Deposit tokens
vault.deposit(amount);

// Step 3: Now you can lock
vault.lockForCrossChain(CHAIN_ID, amount);
```

**Check deposit before locking**:
```bash
# Check user deposit
cast call <VAULT_ADDRESS> "userDeposits(address)(uint256)" <USER_ADDRESS> --rpc-url "$SEPOLIA_RPC"
```

### Error 3: "Pool: insufficient vault balance"

**Cause**: Output vault doesn't have enough tokens for swap

**When it happens**:
- Vault wasn't funded during deployment
- Previous swaps drained vault liquidity

**Solution**: Ensure vaults are funded during deployment using `bootstrapPool()`:

```solidity
// Transfer tokens to Pool first
token.transfer(address(pool), amount);

// Then Pool deposits into vaults
pool.bootstrapPool(amounts);
```

**Prevention**: Always fund vaults through Pool contract, not directly.

### Error 4: "ERC20InsufficientAllowance"

**Cause**: Token not approved or approval amount too low

**When it happens**:
- Forgot to approve Pool/Vault before transaction
- Previous approval was used up

**Solution**:
```solidity
// Option 1: Approve exact amount
token.approve(POOL_ADDRESS, amount);

// Option 2: Approve unlimited (recommended)
token.approve(POOL_ADDRESS, type(uint256).max);
```

**Check allowance**:
```bash
cast call <TOKEN_ADDRESS> "allowance(address,address)(uint256)" <USER_ADDRESS> <SPENDER_ADDRESS> --rpc-url "$SEPOLIA_RPC"
```

### Error 5: "Vault: only cross-chain messenger"

**Cause**: Non-messenger address calling `mintFromCrossChain`

**When it happens**:
- Attempting to mint tokens directly
- Cross-chain messenger not configured

**Solution**:
```bash
# Set cross-chain messenger (only owner)
cast send <VAULT_ADDRESS> \
  "setCrossChainMessenger(address)" \
  <MESSENGER_ADDRESS> \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$SEPOLIA_RPC"
```

### Error 6: Compilation Error - Invalid Unicode Characters

**Cause**: Using Unicode characters (→, ✓) in console.log

**When it happens**:
- Writing console.log with emojis or arrows
- Solidity doesn't support Unicode in string literals

**Solution**:
```solidity
// WRONG
console.log("USDT → XSGD");  // Compilation error

// CORRECT
console.log("USDT to XSGD");  // Works fine
```

### Error 7: "Pool: zero input amount"

**Cause**: Attempting to swap 0 tokens

**Solution**: Always validate input amounts:
```solidity
require(amountIn > 0, "Amount must be > 0");
```

### Error 8: Transaction Reverts Without Error Message

**Cause**: Multiple possible reasons (gas, nonce, network issues)

**Debugging Steps**:
```bash
# 1. Check gas estimation
forge script script/YourScript.s.sol --rpc-url "$SEPOLIA_RPC"

# 2. Check account nonce
cast nonce <ADDRESS> --rpc-url "$SEPOLIA_RPC"

# 3. Check transaction receipt
cast receipt <TX_HASH> --rpc-url "$SEPOLIA_RPC"

# 4. Re-run with -vvvv to see traces
forge script script/YourScript.s.sol \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast \
  -vvvv
```

### Error 9: "Insufficient funds for gas"

**Cause**: Not enough ETH/MATIC for transaction

**Solution**:
```bash
# Check balance
cast balance <ADDRESS> --rpc-url "$SEPOLIA_RPC"

# Get testnet tokens
# Sepolia: https://sepoliafaucet.com/
# Polygon Amoy: https://faucet.polygon.technology/
# Arbitrum Sepolia: https://faucet.quicknode.com/arbitrum/sepolia
```

### Error 10: Pyth Price Feed ID Mismatch

**Cause**: Using incorrect feed IDs for tokens

**Correct Feed IDs**:
```solidity
// USD/SGD (XSGD): 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918
// USD/THBT (THBT): 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394
// USD/IDR (IDRT): 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433
// USDT/USD: 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b
```

**Verification**:
```bash
./scripts/fetch-prices-correct.sh
```

## Transaction Examples

### Example 1: Simple Swap (Same Chain)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/pool/IPool.sol";

contract SimpleSwap {
    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;
    address constant USDT = 0x4B198D1285152B5f8BCbC5e4156D30717B16275e;
    address constant XSGD = 0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385;

    function swapUsdtToXsgd(uint256 amount) external {
        // Approve Pool to spend USDT
        IERC20(USDT).approve(POOL, amount);

        // Execute swap
        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: USDT,
            tokenOut: XSGD,
            amountIn: amount,
            minAmountOut: 0,  // Accept any amount (not recommended for production)
            priceData: ""
        });

        uint256 received = IPool(POOL).swap(params);
        // received = amount * USDT_price / XSGD_price * (1 - 0.003)
    }
}
```

### Example 2: Bridge Tokens (Same Currency, Different Chain)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/vault/Vault.sol";

contract BridgeTokens {
    uint64 constant ARBITRUM_SEPOLIA = 421614;
    address constant USDT = 0x4B198D1285152B5f8BCbC5e4156D30717B16275e;
    address constant USDT_VAULT = 0x965cCD245Eb8683BDC3202b1A1C87515774b833a;

    function bridgeToArbitrum(uint256 amount) external {
        // Step 1: Approve vault
        IERC20(USDT).approve(USDT_VAULT, amount);

        // Step 2: Deposit into vault
        Vault(USDT_VAULT).deposit(amount);

        // Step 3: Lock for cross-chain (burns tokens)
        Vault(USDT_VAULT).lockForCrossChain(ARBITRUM_SEPOLIA, amount);

        // On Arbitrum Sepolia, call:
        // Vault(arbVault).mintFromCrossChain(user, amount);
    }
}
```

### Example 3: Cross-Chain Swap (Different Currency, Different Chain)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/pool/IPool.sol";
import "../src/vault/Vault.sol";

contract CrossChainSwap {
    uint64 constant ARBITRUM_SEPOLIA = 421614;

    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;
    address constant XSGD = 0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385;
    address constant USDT = 0x4B198D1285152B5f8BCbC5e4156D30717B16275e;
    address constant USDT_VAULT = 0x965cCD245Eb8683BDC3202b1A1C87515774b833a;

    function crossChainSwap(uint256 xsgdAmount) external {
        // Step 1: Swap XSGD for USDT on Sepolia
        IERC20(XSGD).approve(POOL, xsgdAmount);

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: XSGD,
            tokenOut: USDT,
            amountIn: xsgdAmount,
            minAmountOut: (xsgdAmount * 70) / 100,  // 30% slippage protection
            priceData: ""
        });

        uint256 receivedUSDT = IPool(POOL).swap(params);

        // Step 2: Bridge USDT to Arbitrum Sepolia
        IERC20(USDT).approve(USDT_VAULT, receivedUSDT);
        Vault(USDT_VAULT).deposit(receivedUSDT);
        Vault(USDT_VAULT).lockForCrossChain(ARBITRUM_SEPOLIA, receivedUSDT);

        // Step 3: On Arbitrum Sepolia
        // Vault(arbVault).mintFromCrossChain(user, receivedUSDT);
    }
}
```

## Gas Costs

### Sepolia Testnet (at 2 gwei)

| Operation | Gas Used | Cost (ETH) | Cost (USD at $3000/ETH) |
|-----------|----------|-----------|--------------------------|
| Token Approval | ~46,000 | 0.00009 ETH | $0.27 |
| Swap (50 USDT → XSGD) | ~147,000 | 0.0003 ETH | $0.90 |
| Vault Deposit | ~93,000 | 0.00019 ETH | $0.57 |
| Lock/Burn | ~93,000 | 0.00019 ETH | $0.57 |
| Mint (Cross-chain) | ~46,000 | 0.00009 ETH | $0.27 |
| **Full Cross-Chain Swap** | ~425,000 | 0.00085 ETH | **$2.55** |

### Polygon Amoy (at 50 gwei)

| Operation | Gas Used | Cost (MATIC) |
|-----------|----------|--------------|
| Token Approval | ~46,000 | 0.0023 MATIC |
| Swap | ~147,000 | 0.0074 MATIC |
| Vault Operations | ~93,000 | 0.0047 MATIC |

## Useful Commands

### Build & Test

```bash
# Clean build
forge clean

# Build contracts
forge build

# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Format code
forge fmt

# Check code style
forge fmt --check
```

### Deployment

```bash
# Deploy to Sepolia
forge script script/DeployTestEnv.s.sol:DeployTestEnv \
  --rpc-url "$SEPOLIA_RPC" \
  --broadcast

# Deploy to Polygon Amoy
forge script script/DeployPolygon.s.sol:DeployPolygon \
  --rpc-url "$POLYGON_AMOY_RPC" \
  --broadcast

# Deploy to Arbitrum Sepolia
forge script script/DeployArbitrum.s.sol:DeployArbitrum \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC" \
  --broadcast
```

### Verification

```bash
# Verify on Etherscan
forge verify-contract <CONTRACT_ADDRESS> \
  src/pool/Pool.sol:Pool \
  --constructor-args $(cast abi-encode "constructor(address)" <arg>) \
  --chain-id 11155111 \
  --etherscan-api-key "$ETHERSCAN_API_KEY"

# Verify on PolygonScan
forge verify-contract <CONTRACT_ADDRESS> \
  src/pool/Pool.sol:Pool \
  --constructor-args $(cast abi-encode "constructor(address)" <arg>) \
  --chain-id 80002 \
  --verifier-url "https://api-amoy.polygonscan.com/api" \
  --etherscan-api-key "$POLYGONSCAN_API_KEY"
```

### Contract Interaction

```bash
# Call view function
cast call <CONTRACT_ADDRESS> "functionName()(uint256)" --rpc-url "$SEPOLIA_RPC"

# Send transaction
cast send <CONTRACT_ADDRESS> "functionName(uint256)" 12345 \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$SEPOLIA_RPC"

# Get transaction receipt
cast receipt <TX_HASH> --rpc-url "$SEPOLIA_RPC"

# Check balance
cast balance <ADDRESS> --rpc-url "$SEPOLIA_RPC"
```

## Live Transaction Examples

### Successful Transactions (Sepolia)

All transactions verified and successful:

1. **Swap**: [0xface7dc...](https://sepolia.etherscan.io/tx/0xface7dcac4289a5262f80e6fa6a8883ddb75079610d7a9b08205819a5828a550)
   - 50 USDT → 63 XSGD
   - Gas: 147,067
   - Status: ✅ Success

2. **Bridge Lock**: [0x2142b1a...](https://sepolia.etherscan.io/tx/0x2142b1abb3b6d0b0bb997cd6a5e5119c6a5fe2aec3e822e8ea13bd24d545bfee)
   - 30 USDT locked for Arbitrum Sepolia
   - Gas: 93,234
   - Status: ✅ Success

3. **Cross-Chain Lock**: [0xbc2c181...](https://sepolia.etherscan.io/tx/0xbc2c181099d888236e3729d75bc6a3c257d49ca0a05c36a448134724cac5d7fd)
   - 20 XSGD locked for Arbitrum Sepolia
   - Gas: 93,456
   - Status: ✅ Success

**View All**: https://sepolia.etherscan.io/address/0x07dab64Aa125B206D7fd6a81AaB2133A0bdEF863

## Project Structure

```
custom-pool/
├── script/                          # Deployment & testing scripts
│   ├── DeployTestEnv.s.sol         # Full Sepolia deployment
│   ├── DeployPolygon.s.sol         # Polygon Amoy deployment
│   ├── DeployArbitrum.s.sol        # Arbitrum Sepolia deployment
│   ├── UpdatePricesCorrect.s.sol   # Price update script
│   ├── RunLiveTransactions.s.sol   # Live transaction execution
│   ├── LiveTransactions.s.sol      # Standalone live transactions
│   └── CrossChainTest.s.sol        # Cross-chain testing
├── src/
│   ├── pool/                        # Pool contract & interfaces
│   │   ├── Pool.sol                 # Main swap pool
│   │   └── IPool.sol                # Pool interface
│   ├── vault/                       # Vault contract & interfaces
│   │   ├── Vault.sol                # Token vault
│   │   └── IVault.sol               # Vault interface
│   └── tokens/                      # ERC20 tokens
│       ├── XSGD.sol                 # Singapore Dollar
│       ├── USDT.sol                 # Tether USD
│       ├── THBT.sol                 # Thai Baht
│       └── IDRT.sol                 # Indonesian Rupiah
├── test/                            # Test files
│   ├── Pool.t.sol                   # Pool unit tests
│   ├── Vault.t.sol                  # Vault unit tests
│   ├── Integration.t.sol            # Integration tests
│   └── ComprehensiveScenarios.t.sol # 14 scenario tests
├── broadcast/                       # Transaction records
├── cache/                           # Build cache
└── lib/                             # Dependencies
    ├── forge-std/                   # Foundry std lib
    ├── openzeppelin-contracts/      # OpenZeppelin
    └── pyth-sdk-solidity/           # Pyth SDK
```

## Security Considerations

1. **Private Key Security**
   - ✅ NEVER commit `.env` file
   - ✅ Use separate keys for testnet/mainnet
   - ✅ Use hardware wallets for mainnet

2. **Contract Security**
   - ✅ Test thoroughly on testnets first
   - ✅ Get professional audit before mainnet
   - ✅ Implement timelock for sensitive operations
   - ✅ Use multisig for contract ownership

3. **Transaction Security**
   - ✅ Always use `minAmountOut` for slippage protection
   - ✅ Verify contract addresses before transactions
   - ✅ Update prices before swapping
   - ✅ Check gas prices before transactions

4. **Price Oracle Security**
   - ✅ Prices expire after 60 seconds (protection against stale prices)
   - ✅ Use multiple price sources for production
   - ✅ Implement circuit breakers for extreme price movements

## License

MIT

## Support & Resources

- **Foundry Documentation**: https://book.getfoundry.sh/
- **Pyth Network**: https://docs.pyth.network/
- **OpenZeppelin**: https://docs.openzeppelin.com/
- **Sepolia Faucet**: https://sepoliafaucet.com/
- **Polygon Amoy Faucet**: https://faucet.polygon.technology/
- **Arbitrum Sepolia Faucet**: https://faucet.quicknode.com/arbitrum/sepolia

## Troubleshooting Checklist

Before asking for help, check:
- [ ] Environment variables sourced (`source .env`)
- [ ] RPC endpoints working (`cast block-number --rpc-url "$RPC"`)
- [ ] Wallet has sufficient gas (`cast balance <ADDRESS>`)
- [ ] Prices updated recently (`script/UpdatePricesCorrect.s.sol`)
- [ ] Contracts deployed correctly (`cast code <ADDRESS>`)
- [ ] Transaction verified on block explorer
- [ ] Test files passing (`forge test`)
- [ ] No unicode characters in console.log
- [ ] Correct Pyth feed IDs used
- [ ] Vault allowances set correctly

If still stuck, provide:
1. Full error message
2. Command used
3. RPC endpoint (can omit sensitive parts)
4. Transaction hash (if applicable)
5. Console output with `-vvvv`
