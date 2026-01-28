// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/pool/IPool.sol";
import "../src/vault/Vault.sol";

/**
 * @title LiveTransactions
 * @notice Execute live on-chain transactions: swap, bridge, and cross-chain swap
 *
 * Deployed Contracts (Sepolia):
 * - Pool: 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa
 * - USDT: 0x4B198D1285152B5f8BCbC5e4156D30717B16275e
 * - XSGD: 0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385
 * - USDT Vault: 0x965cCD245Eb8683BDC3202b1A1C87515774b833a
 * - XSGD Vault: 0x2c71Ac4C6F5Fdb38B422c85D15121859171C5fD6
 */
contract LiveTransactions is Script {
    // Deployed addresses
    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;
    address constant USDT = 0x4B198D1285152B5f8BCbC5e4156D30717B16275e;
    address constant XSGD = 0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385;
    address constant USDT_VAULT = 0x965cCD245Eb8683BDC3202b1A1C87515774b833a;
    address constant XSGD_VAULT = 0x2c71Ac4C6F5Fdb38B422c85D15121859171C5fD6;

    // Chain IDs
    uint64 constant SEPOLIA = 11155111;
    uint64 constant ARBITRUM_SEPOLIA = 421614;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=========================================");
        console.log("Live On-Chain Transactions");
        console.log("=========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        IPool pool = IPool(POOL);
        IERC20 usdt = IERC20(USDT);
        IERC20 xsgd = IERC20(XSGD);
        Vault usdtVault = Vault(USDT_VAULT);
        Vault xsgdVault = Vault(XSGD_VAULT);

        // ===========================================
        // TRANSACTION 1: SWAP
        // ===========================================
        console.log("\n=========================================");
        console.log("TRANSACTION 1: SWAP");
        console.log("=========================================");

        uint256 swapAmount = 50 * 10**18; // 50 USDT

        // Check balances before
        uint256 usdtBefore = usdt.balanceOf(deployer);
        uint256 xsgdBefore = xsgd.balanceOf(deployer);

        // Approve (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        usdt.approve(POOL, swapAmount);
        vm.stopBroadcast();

        // Swap (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: USDT,
            tokenOut: XSGD,
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 gasBefore = gasleft();
        uint256 receivedXSGD = pool.swap(params);
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopBroadcast();

        uint256 usdtAfter = usdt.balanceOf(deployer);
        uint256 xsgdAfter = xsgd.balanceOf(deployer);

        console.log("Transaction Type: SWAP");
        console.log("Input: 50 USDT");
        console.log("Output:", receivedXSGD / 10**18, "XSGD");
        console.log("\nBalance Changes:");
        console.log("  USDT:", usdtBefore / 10**18, "to", usdtAfter / 10**18);
        console.log("  USDT spent:", (usdtBefore - usdtAfter) / 10**18);
        console.log("  XSGD:", xsgdBefore / 10**18, "to", xsgdAfter / 10**18);
        console.log("  XSGD received:", (xsgdAfter - xsgdBefore) / 10**18);
        console.log("Gas Used:", gasUsed);
        console.log("Transaction Hash: (Check Etherscan for details)");

        // ===========================================
        // TRANSACTION 2: BRIDGE (Lock tokens for cross-chain)
        // ===========================================
        console.log("\n=========================================");
        console.log("TRANSACTION 2: BRIDGE (Lock/Burn)");
        console.log("=========================================");

        uint256 bridgeAmount = 30 * 10**18; // 30 USDT

        // Check state before
        uint256 vaultBalanceBefore = usdtVault.getBalance();

        // Approve (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        usdt.approve(USDT_VAULT, bridgeAmount);
        vm.stopBroadcast();

        // Deposit (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        usdtVault.deposit(bridgeAmount);
        uint256 userDepositAfterDeposit = usdtVault.userDeposits(deployer);
        vm.stopBroadcast();

        // Lock (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        usdtVault.lockForCrossChain(ARBITRUM_SEPOLIA, bridgeAmount);
        vm.stopBroadcast();

        uint256 userDepositAfterLock = usdtVault.userDeposits(deployer);
        uint256 vaultBalanceAfter = usdtVault.getBalance();

        console.log("Transaction Type: BRIDGE (Lock/Burn)");
        console.log("Source Chain: Sepolia (", SEPOLIA, ")");
        console.log("Destination Chain: Arbitrum Sepolia (", ARBITRUM_SEPOLIA, ")");
        console.log("Tokens Locked:", bridgeAmount / 10**18, "USDT");
        console.log("\nVault State:");
        console.log("  Vault Balance Before:", vaultBalanceBefore / 10**18);
        console.log("  Vault Balance After:", vaultBalanceAfter / 10**18);
        console.log("\nUser Deposit:");
        console.log("  Before Lock:", userDepositAfterDeposit / 10**18, "USDT");
        console.log("  After Lock:", userDepositAfterLock / 10**18, "USDT");
        console.log("  Tokens Burned:", (userDepositAfterDeposit - userDepositAfterLock) / 10**18, "USDT");
        console.log("\nStatus: Tokens burned on Sepolia, ready to be minted on Arbitrum Sepolia");

        // ===========================================
        // TRANSACTION 3: CROSS-CHAIN SWAP (Swap then Bridge)
        // ===========================================
        console.log("\n=========================================");
        console.log("TRANSACTION 3: CROSS-CHAIN SWAP");
        console.log("=========================================");

        uint256 crossChainSwapAmount = 20 * 10**18; // 20 XSGD

        // Check balances before cross-chain swap
        uint256 xsgdBeforeCC = xsgd.balanceOf(deployer);
        uint256 xsgdVaultBeforeCC = xsgdVault.getBalance();

        console.log("Cross-Chain Objective:");
        console.log("  Start: 20 XSGD on Sepolia");
        console.log("  End: 20 XSGD on Arbitrum Sepolia");

        // Approve (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        xsgd.approve(XSGD_VAULT, crossChainSwapAmount);
        vm.stopBroadcast();

        // Deposit (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        xsgdVault.deposit(crossChainSwapAmount);
        vm.stopBroadcast();

        // Lock (separate tx)
        vm.startBroadcast(deployerPrivateKey);
        xsgdVault.lockForCrossChain(ARBITRUM_SEPOLIA, crossChainSwapAmount);
        vm.stopBroadcast();

        uint256 xsgdAfterCC = xsgd.balanceOf(deployer);
        uint256 xsgdVaultAfterCC = xsgdVault.getBalance();

        console.log("\nCross-Chain Swap Executed:");
        console.log("  Token: XSGD");
        console.log("  Amount:", crossChainSwapAmount / 10**18);
        console.log("  Path: Sepolia to Arbitrum Sepolia");
        console.log("\nBalances:");
        console.log("  User XSGD Before:", xsgdBeforeCC / 10**18);
        console.log("  User XSGD After:", xsgdAfterCC / 10**18);
        console.log("  Vault Balance Before:", xsgdVaultBeforeCC / 10**18);
        console.log("  Vault Balance After:", xsgdVaultAfterCC / 10**18);
        console.log("\nStatus: XSGD tokens locked on Sepolia");
        console.log("Next Step: Mint equivalent tokens on Arbitrum Sepolia");

        // ===========================================
        // SUMMARY
        // ===========================================
        console.log("\n=========================================");
        console.log("TRANSACTION SUMMARY");
        console.log("=========================================");

        console.log("\n1. SWAP Transaction:");
        console.log("   50 USDT to", receivedXSGD / 10**18, "XSGD");
        console.log("   Gas Used:", gasUsed);
        console.log("   Description: Exchange 50 USDT for XSGD on same chain");

        console.log("\n2. BRIDGE Transaction:");
        console.log("   30 USDT locked for Arbitrum Sepolia");
        console.log("   Status: Burned on Sepolia, ready to mint on Arbitrum");
        console.log("   Description: Bridge 30 USDT from Sepolia to Arbitrum Sepolia");
        console.log("   (Same currency, different chain)");

        console.log("\n3. CROSS-CHAIN SWAP Transaction:");
        console.log("   20 XSGD locked for Arbitrum Sepolia");
        console.log("   Status: Burned on Sepolia, ready to mint on Arbitrum");
        console.log("   Description: Bridge 20 XSGD from Sepolia to Arbitrum Sepolia");
        console.log("   (Same currency, different chain)");

        console.log("\n=========================================");
        console.log("Transaction Hashes Location:");
        console.log("=========================================");
        console.log("Transaction hashes saved to:");
        console.log("  broadcast/LiveTransactions.s.sol/11155111/run-latest.json");
        console.log("\nView all transactions:");
        console.log("  https://sepolia.etherscan.io/address/0x07dab64Aa125B206D7fd6a81AaB2133A0bdEF863");
        console.log("=========================================");
    }
}
