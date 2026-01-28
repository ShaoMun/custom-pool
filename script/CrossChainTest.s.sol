// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/vault/Vault.sol";
import "../src/tokens/USDT.sol";

/**
 * @title CrossChainTest
 * @notice Test cross-chain lock (burn) and mint functionality
 *
 * Cross-Chain Flow:
 * 1. User locks tokens on Source Chain → tokens are burned
 * 2. Tokens are minted on Destination Chain via cross-chain message
 *
 * Usage:
 *   forge script script/CrossChainTest.s.sol:CrossChainTest \
 *     --rpc-url $SEPOLIA_RPC --broadcast -vvv
 */
contract CrossChainTest is Script {
    // Deployed addresses on Sepolia
    address constant USDT = 0x4B198D1285152B5f8BCbC5e4156D30717B16275e;
    address constant USDT_VAULT = 0x965cCD245Eb8683BDC3202b1A1C87515774b833a;

    // Chain IDs
    uint64 constant SEPOLIA = 11155111;
    uint64 constant ARBITRUM_SEPOLIA = 421614;

    // Test amounts
    uint256 constant LOCK_AMOUNT = 50 * 10**18;  // 50 USDT to lock
    uint256 constant MINT_AMOUNT = 30 * 10**18;  // 30 USDT to mint

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Cross-Chain Test: Lock (Burn) & Mint ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        IERC20 usdt = IERC20(USDT);
        Vault vault = Vault(USDT_VAULT);

        // ===========================================
        // Part 1: Lock Tokens for Cross-Chain (Burn)
        // ===========================================
        console.log("\n--- Part 1: Lock Tokens (Simulating Source Chain) ---");

        // Check initial state
        uint256 userTokenBefore = usdt.balanceOf(deployer);
        uint256 vaultBalanceBefore = vault.getBalance();
        uint256 userDepositBefore = vault.userDeposits(deployer);

        console.log("Initial state:");
        console.log("  User token balance:", userTokenBefore / 10**18);
        console.log("  Vault token balance:", vaultBalanceBefore / 10**18);
        console.log("  User deposit in vault:", userDepositBefore / 10**18);

        // First, need to deposit tokens into vault
        vm.startBroadcast(deployerPrivateKey);
        usdt.approve(USDT_VAULT, LOCK_AMOUNT);
        vault.deposit(LOCK_AMOUNT);
        vm.stopBroadcast();

        uint256 userDepositAfterDeposit = vault.userDeposits(deployer);
        console.log("\nAfter deposit:");
        console.log("  User deposit in vault:", userDepositAfterDeposit / 10**18);

        // Now lock tokens for cross-chain transfer
        vm.startBroadcast(deployerPrivateKey);
        vault.lockForCrossChain(ARBITRUM_SEPOLIA, LOCK_AMOUNT);
        vm.stopBroadcast();

        // Check state after lock
        uint256 userTokenAfter = usdt.balanceOf(deployer);
        uint256 vaultBalanceAfter = vault.getBalance();
        uint256 userDepositAfter = vault.userDeposits(deployer);
        uint256 chainBalance = vault.getChainBalance(ARBITRUM_SEPOLIA);

        console.log("\nAfter lock for cross-chain:");
        console.log("  User token balance:", userTokenAfter / 10**18);
        console.log("  Vault token balance:", vaultBalanceAfter / 10**18);
        console.log("  User deposit in vault:", userDepositAfter / 10**18);
        console.log("  Arbitrum Sepolia chain balance:", chainBalance / 10**18);

        console.log("\n[LOCK/BURN COMPLETE]");
        console.log("  Tokens locked (burned) on Sepolia");
        console.log("  Ready to be minted on Arbitrum Sepolia");

        // ===========================================
        // Part 2: Set Cross-Chain Messenger
        // ===========================================
        console.log("\n--- Part 2: Setup Cross-Chain Messenger ---");

        // For testing, we set deployer as the messenger
        // In production, this would be LayerZero endpoint
        vm.startBroadcast(deployerPrivateKey);
        vault.setCrossChainMessenger(deployer);
        vm.stopBroadcast();

        console.log("Cross-chain messenger set to:", deployer);
        console.log("(This simulates LayerZero endpoint)");

        // ===========================================
        // Part 3: Mint Tokens from Cross-Chain
        // ===========================================
        console.log("\n--- Part 3: Mint Tokens (Simulating Destination Chain) ---");

        // Check state before mint
        uint256 userDepositBeforeMint = vault.userDeposits(deployer);
        uint256 vaultBalanceBeforeMint = vault.getBalance();

        console.log("Before mint:");
        console.log("  User deposit in vault:", userDepositBeforeMint / 10**18);
        console.log("  Vault token balance:", vaultBalanceBeforeMint / 10**18);

        // Mint tokens received from cross-chain transfer
        // (In production, this would be called by LayerZero messenger)
        vm.startBroadcast(deployerPrivateKey);
        vault.mintFromCrossChain(deployer, MINT_AMOUNT);
        vm.stopBroadcast();

        // Check state after mint
        uint256 userDepositAfterMint = vault.userDeposits(deployer);
        uint256 vaultBalanceAfterMint = vault.getBalance();
        uint256 chainBalanceAfterMint = vault.getChainBalance(SEPOLIA);

        console.log("\nAfter mint from cross-chain:");
        console.log("  User deposit in vault:", userDepositAfterMint / 10**18);
        console.log("  Vault token balance:", vaultBalanceAfterMint / 10**18);
        console.log("  Sepolia chain balance:", chainBalanceAfterMint / 10**18);

        console.log("\n[MINT COMPLETE]");
        console.log("  Tokens minted on Sepolia from cross-chain transfer");

        // ===========================================
        // Summary
        // ===========================================
        console.log("\n=== Cross-Chain Test Summary ===");
        console.log("\nToken Flow:");
        console.log("  Source Chain (Sepolia):");
        console.log("    1. User deposits 50 USDT into vault");
        console.log("    2. User locks 50 USDT for Arbitrum Sepolia");
        console.log("    >> Tokens burned (reduced from user deposit)");
        console.log("    >> Arbitrum Sepolia chain balance updated");
        console.log("\n  Destination Chain (Simulated on Sepolia):");
        console.log("    3. Cross-chain message received");
        console.log("    4. Mint 30 USDT to user");
        console.log("    >> Tokens minted (added to user deposit)");
        console.log("    >> Sepolia chain balance increased");

        console.log("\nFinal User Deposit:", userDepositAfterMint / 10**18);
        console.log("  (Started at:", userDepositBefore / 10**18, ")");
        console.log("  Change:", int256(userDepositAfterMint) - int256(userDepositBefore));

        console.log("\n=== Cross-Chain Test Complete ===");
    }
}
