// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/pool/IPool.sol";
import "../src/pool/Pool.sol";
import "../src/vault/Vault.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title RunLiveTransactions
 * @notice Update prices then execute live on-chain transactions
 */
contract RunLiveTransactions is Script {
    // Deployed addresses
    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;
    address constant USDT = 0x4B198D1285152B5f8BCbC5e4156D30717B16275e;
    address constant XSGD = 0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385;
    address constant USDT_VAULT = 0x965cCD245Eb8683BDC3202b1A1C87515774b833a;
    address constant XSGD_VAULT = 0x2c71Ac4C6F5Fdb38B422c85D15121859171C5fD6;

    // Pyth Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant THBT_FEED_ID = 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394;
    bytes32 constant IDRT_FEED_ID = 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    // Chain IDs
    uint64 constant SEPOLIA = 11155111;
    uint64 constant ARBITRUM_SEPOLIA = 421614;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=========================================");
        console.log("Step 1: Update Prices");
        console.log("=========================================");

        Pool pool = Pool(POOL);
        uint64 currentTimestamp = uint64(block.timestamp);

        vm.startBroadcast(deployerPrivateKey);

        // Update prices
        PythStructs.Price memory xsgdPrice = PythStructs.Price({
            price: 79000000,
            conf: 5000,
            expo: -8,
            publishTime: currentTimestamp
        });

        PythStructs.Price memory usdtPrice = PythStructs.Price({
            price: 99868820,
            conf: 83088,
            expo: -8,
            publishTime: currentTimestamp
        });

        bytes32[] memory priceFeedIds = new bytes32[](2);
        priceFeedIds[0] = XSGD_FEED_ID;
        priceFeedIds[1] = USDT_FEED_ID;

        PythStructs.Price[] memory priceData = new PythStructs.Price[](2);
        priceData[0] = xsgdPrice;
        priceData[1] = usdtPrice;

        pool.updatePrices(priceFeedIds, priceData);

        vm.stopBroadcast();

        console.log("Prices updated successfully!");

        // Now execute transactions
        console.log("\n=========================================");
        console.log("Step 2: Execute Live Transactions");
        console.log("=========================================");

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

        uint256 swapAmount = 50 * 10**18;

        uint256 usdtBefore = usdt.balanceOf(deployer);
        uint256 xsgdBefore = xsgd.balanceOf(deployer);

        // Approve
        vm.startBroadcast(deployerPrivateKey);
        usdt.approve(POOL, swapAmount);
        vm.stopBroadcast();

        // Swap
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
        console.log("Description: Exchange 50 USDT for XSGD on same chain");

        // ===========================================
        // TRANSACTION 2: BRIDGE
        // ===========================================
        console.log("\n=========================================");
        console.log("TRANSACTION 2: BRIDGE (Same currency, different chain)");
        console.log("=========================================");

        uint256 bridgeAmount = 30 * 10**18;

        uint256 vaultBalanceBefore = usdtVault.getBalance();

        // Approve
        vm.startBroadcast(deployerPrivateKey);
        usdt.approve(USDT_VAULT, bridgeAmount);
        vm.stopBroadcast();

        // Deposit
        vm.startBroadcast(deployerPrivateKey);
        usdtVault.deposit(bridgeAmount);
        uint256 userDepositAfterDeposit = usdtVault.userDeposits(deployer);
        vm.stopBroadcast();

        // Lock
        vm.startBroadcast(deployerPrivateKey);
        usdtVault.lockForCrossChain(ARBITRUM_SEPOLIA, bridgeAmount);
        vm.stopBroadcast();

        uint256 userDepositAfterLock = usdtVault.userDeposits(deployer);
        uint256 vaultBalanceAfter = usdtVault.getBalance();

        console.log("Transaction Type: BRIDGE");
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
        console.log("\nDescription: Bridge 30 USDT from Sepolia to Arbitrum Sepolia");
        console.log("Status: Tokens burned on Sepolia, ready to be minted on Arbitrum Sepolia");

        // ===========================================
        // TRANSACTION 3: CROSS-CHAIN SWAP
        // ===========================================
        console.log("\n=========================================");
        console.log("TRANSACTION 3: CROSS-CHAIN BRIDGE (Same currency, different chain)");
        console.log("=========================================");

        uint256 crossChainSwapAmount = 20 * 10**18;

        uint256 xsgdBeforeCC = xsgd.balanceOf(deployer);
        uint256 xsgdVaultBeforeCC = xsgdVault.getBalance();

        console.log("Cross-Chain Objective:");
        console.log("  Start: 20 XSGD on Sepolia");
        console.log("  End: 20 XSGD on Arbitrum Sepolia");

        // Approve
        vm.startBroadcast(deployerPrivateKey);
        xsgd.approve(XSGD_VAULT, crossChainSwapAmount);
        vm.stopBroadcast();

        // Deposit
        vm.startBroadcast(deployerPrivateKey);
        xsgdVault.deposit(crossChainSwapAmount);
        vm.stopBroadcast();

        // Lock
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
        console.log("\nDescription: Bridge 20 XSGD from Sepolia to Arbitrum Sepolia");
        console.log("Status: XSGD tokens locked on Sepolia");
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
        console.log("   Description: Bridge 30 USDT from Sepolia to Arbitrum Sepolia (same currency, different chain)");

        console.log("\n3. CROSS-CHAIN BRIDGE Transaction:");
        console.log("   20 XSGD locked for Arbitrum Sepolia");
        console.log("   Status: Burned on Sepolia, ready to mint on Arbitrum");
        console.log("   Description: Bridge 20 XSGD from Sepolia to Arbitrum Sepolia (same currency, different chain)");

        console.log("\n=========================================");
        console.log("Transaction Hashes Location:");
        console.log("=========================================");
        console.log("Transaction hashes saved to:");
        console.log("  broadcast/RunLiveTransactions.s.sol/11155111/run-latest.json");
        console.log("\nView all transactions:");
        console.log("  https://sepolia.etherscan.io/address/0x07dab64Aa125B206D7fd6a81AaB2133A0bdEF863");
        console.log("=========================================");
    }
}
