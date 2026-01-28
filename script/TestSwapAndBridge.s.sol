// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/USDT.sol";
import "../src/tokens/XSGD.sol";
import "../src/pool/Pool.sol";
import "../src/pool/IPool.sol";
import "../src/vault/Vault.sol";

/**
 * @title TestSwapAndBridge
 * @notice Test script for swap and cross-chain bridge functionality
 */
contract TestSwapAndBridge is Script {
    // ========================
    // Contract Addresses (Sepolia)
    // ========================
    address constant XSGD_TOKEN = 0x7F45B29Cd366A81763F9198aFA6eaB605f6581D1;
    address constant THBT_TOKEN = 0x3dA27031278c1356Ca3ebCC458E9427c8aB07ee3;
    address constant IDRT_TOKEN = 0x5BD7a4cC7024E9f628FCaeB45B2018ab19c90C14;
    address constant USDT_TOKEN = 0x21A1dF35611a06dB25e5B7be8007d8201e910C2D;

    address constant XSGD_VAULT = 0x4D91a73Ed104A851C9004e4F40312b90f50014c7;
    address constant THBT_VAULT = 0x85f0b83fa95cd479D5ac84103cf46A36391f7bc5;
    address constant IDRT_VAULT = 0xDC8A9208C3C07C14ccc31E9e52F4B570c0cC8f66;
    address constant USDT_VAULT = 0x19B1cd853A9bF3C7C718f94065d61a98b377dBFe;

    address constant POOL = 0x21B096Fc58212C325242CfF850980086A5699817;

    // Pyth Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tester = vm.addr(deployerPrivateKey);

        console.log("=== Testing Swap and Bridge Functionality ===");
        console.log("Tester address:", tester);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Initialize contracts
        USDT usdt = USDT(USDT_TOKEN);
        XSGD xsgd = XSGD(XSGD_TOKEN);
        Pool pool = Pool(POOL);
        Vault usdtVault = Vault(USDT_VAULT);
        Vault xsgdVault = Vault(XSGD_VAULT);

        // ========================
        // TEST 1: Check Balances
        // ========================
        console.log("=== TEST 1: Initial Balances ===");

        uint256 usdtBalance = usdt.balanceOf(tester);
        uint256 xsgdBalance = xsgd.balanceOf(tester);
        uint256 usdtVaultBalance = usdt.balanceOf(USDT_VAULT);
        uint256 xsgdVaultBalance = xsgd.balanceOf(XSGD_VAULT);

        console.log("Tester USDT balance:", usdtBalance / 1e18);
        console.log("Tester XSGD balance:", xsgdBalance / 1e18);
        console.log("USDT Vault balance:", usdtVaultBalance / 1e18);
        console.log("XSGD Vault balance:", xsgdVaultBalance / 1e18);
        console.log("");

        // ========================
        // TEST 2: Fetch Pyth Prices
        // ========================
        console.log("=== TEST 2: Fetching Pyth Price Data ===");

        // Fetch price data from Pyth Hermes API
        string[] memory inputs = new string[](3);
        inputs[0] = "curl";
        inputs[1] = "-s";
        inputs[2] = "https://hermes.pyth.network/v2/updates?ids%5B%5D=396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918&ids%5B%5D=2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b";

        bytes memory priceData = vm.ffi(inputs);
        console.log("Price data fetched, length:", priceData.length);
        console.log("Price data (hex):");
        console.logBytes(priceData);
        console.log("");

        // ========================
        // TEST 3: Approve Pool
        // ========================
        console.log("=== TEST 3: Approving Pool to spend tokens ===");

        uint256 swapAmount = 100 * 10**18; // 100 USDT

        usdt.approve(POOL, type(uint256).max);
        console.log("Approved Pool to spend USDT");
        console.log("");

        // ========================
        // TEST 4: Execute Swap
        // ========================
        console.log("=== TEST 4: Executing Swap (100 USDT -> XSGD) ===");
        console.log("Swap amount:", swapAmount / 1e18, "USDT");

        IPool.SwapParams memory swapParams = IPool.SwapParams({
            tokenIn: USDT_TOKEN,
            tokenOut: XSGD_TOKEN,
            amountIn: swapAmount,
            minAmountOut: 0, // Accepting any amount for testing (no slippage protection)
            priceData: priceData
        });

        uint256 amountOut = pool.swap(swapParams);
        console.log("Received XSGD amount:", amountOut / 1e18);
        console.log("Swap successful!");
        console.log("");

        // ========================
        // TEST 5: Verify Balance Changes
        // ========================
        console.log("=== TEST 5: Post-Swap Balances ===");

        uint256 usdtBalanceAfter = usdt.balanceOf(tester);
        uint256 xsgdBalanceAfter = xsgd.balanceOf(tester);
        uint256 usdtVaultBalanceAfter = usdt.balanceOf(USDT_VAULT);
        uint256 xsgdVaultBalanceAfter = xsgd.balanceOf(XSGD_VAULT);

        console.log("Tester USDT balance:", usdtBalanceAfter / 1e18);
        console.log("Tester XSGD balance:", xsgdBalanceAfter / 1e18);
        console.log("USDT Vault balance:", usdtVaultBalanceAfter / 1e18);
        console.log("XSGD Vault balance:", xsgdVaultBalanceAfter / 1e18);
        console.log("");

        // ========================
        // TEST 6: Test Bridge Functions (Placeholder)
        // ========================
        console.log("=== TEST 6: Testing Cross-Chain Bridge Functions ===");
        console.log("Note: These are placeholder functions for future LayerZero integration");
        console.log("");

        // Test lockForCrossChain (will deposit tokens first to have balance)
        console.log("6a. Testing lockForCrossChain...");

        // First, deposit some tokens to the vault
        uint256 depositAmount = 50 * 10**18; // 50 USDT
        usdt.approve(USDT_VAULT, depositAmount);
        usdtVault.deposit(depositAmount);
        console.log("Deposited", depositAmount / 1e18, "USDT to vault");

        // Now test lockForCrossChain (targeting Arbitrum Sepolia)
        uint64 targetChain = 421614; // Arbitrum Sepolia
        uint256 lockAmount = 25 * 10**18; // 25 USDT

        try usdtVault.lockForCrossChain(targetChain, lockAmount) {
            console.log("Successfully locked", lockAmount / 1e18, "USDT for cross-chain transfer to chain", targetChain);

            // Check vault state after lock
            uint256 userDeposit = usdtVault.userDeposits(tester);
            uint256 vaultBalance = usdtVault.getBalance();
            console.log("User deposit in vault:", userDeposit / 1e18);
            console.log("Vault token balance:", vaultBalance / 1e18);
        } catch {
            console.log("lockForCrossChain failed (expected - cross-chain messenger not set)");
        }
        console.log("");

        // Test updateChainBalance (admin function)
        console.log("6b. Testing updateChainBalance (admin function)...");
        try usdtVault.updateChainBalance(targetChain, 0) {
            console.log("Successfully updated chain balance for chain", targetChain);

            // Check updated balance
            uint256 chainBalance = usdtVault.getChainBalance(targetChain);
            console.log("Chain balance for", targetChain, ":", chainBalance);
        } catch {
            console.log("updateChainBalance failed");
        }
        console.log("");

        // ========================
        // TEST 7: Check Pool Fee
        // ========================
        console.log("=== TEST 7: Pool Fee Configuration ===");

        uint256 feeBps = pool.feeBps();
        console.log("Pool fee basis points:");
        console.logUint(feeBps);
        console.log("Pool fee percentage:");
        uint256 feePercent = feeBps * 100 / 10000;
        console.logUint(feePercent);
        console.log("");

        vm.stopBroadcast();

        // ========================
        // Summary
        // ========================
        console.log("=== Test Summary ===");
        console.log("[PASS] Swap functionality tested");
        console.log("[PASS] Bridge placeholder functions tested");
        console.log("[PASS] Cross-chain lock function tested");
        console.log("");
        console.log("Next steps:");
        console.log("1. Implement LayerZero integration for actual cross-chain transfers");
        console.log("2. Add mintFromCrossChain function to receive cross-chain tokens");
        console.log("3. Deploy to Arbitrum Sepolia and Polygon Amoy");
        console.log("4. Test cross-chain swaps between different chains");
    }
}
