// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/USDT.sol";
import "../src/tokens/XSGD.sol";
import "../src/pool/Pool.sol";
import "../src/vault/Vault.sol";
import "../src/pool/IPool.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title IntegrationTest
 * @notice Integration tests for swap and bridge functionality
 */
contract IntegrationTest is Test {
    // Pyth Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    USDT usdt;
    XSGD xsgd;
    Pool pool;
    Vault usdtVault;
    Vault xsgdVault;

    address deployer;      // Contract deployer with all initial tokens
    address testUser;      // New wallet for testing
    uint256 initialSupply = 1_000_000 * 10**18;
    uint256 vaultLiquidity = 100_000 * 10**18;    // Liquidity per vault
    uint256 testUserTokens = 10_000 * 10**18;     // Tokens for test user
    uint256 testUserGas = 10 ether;                // Gas tokens for test user

    function setUp() public {
        deployer = address(this);  // Deployer is the test contract
        testUser = address(0x1);   // Create test user wallet

        // ===========================================
        // 1. Deploy Tokens (all minted to deployer)
        // ===========================================
        usdt = new USDT(deployer, initialSupply);
        xsgd = new XSGD(deployer, initialSupply);

        // ===========================================
        // 2. Deploy Vaults
        // ===========================================
        usdtVault = new Vault(IERC20(address(usdt)), 11155111);
        xsgdVault = new Vault(IERC20(address(xsgd)), 11155111);

        // ===========================================
        // 3. Deploy Pool
        // ===========================================
        address[] memory tokensList = new address[](2);
        tokensList[0] = address(xsgd);
        tokensList[1] = address(usdt);

        bytes32[] memory feedIds = new bytes32[](2);
        feedIds[0] = XSGD_FEED_ID;
        feedIds[1] = USDT_FEED_ID;

        pool = new Pool(
            tokensList,
            feedIds,
            deployer
        );

        // Configure pool
        pool.setVault(address(usdt), usdtVault);
        pool.setVault(address(xsgd), xsgdVault);

        // ===========================================
        // 4. Set Prices
        // ===========================================
        uint64 currentTimestamp = uint64(block.timestamp);
        PythStructs.Price memory usdtPrice = PythStructs.Price({
            price: 99868428,
            conf: 108232,
            expo: -8,
            publishTime: currentTimestamp
        });
        PythStructs.Price memory xsgdPrice = PythStructs.Price({
            price: 126141,
            conf: 21,
            expo: -5,
            publishTime: currentTimestamp
        });

        bytes32[] memory priceFeedIds = new bytes32[](2);
        priceFeedIds[0] = USDT_FEED_ID;
        priceFeedIds[1] = XSGD_FEED_ID;

        PythStructs.Price[] memory priceData = new PythStructs.Price[](2);
        priceData[0] = usdtPrice;
        priceData[1] = xsgdPrice;

        pool.updatePrices(priceFeedIds, priceData);

        // ===========================================
        // 5. Deployer Funds All Vaults with Initial Liquidity
        //    This enables bidirectional swaps (XSGD <-> USDT)
        //
        //    IMPORTANT: We must fund vaults THROUGH the Pool,
        //    so the Pool has userDeposits in each vault to use for swaps
        //
        //    Process:
        //    1. Transfer tokens from deployer to Pool
        //    2. Call pool.bootstrapPool() to deposit into all vaults
        // ===========================================
        console.log("\n=== Funding Vaults with Initial Liquidity ===");
        console.log("Vault liquidity per token:", vaultLiquidity / 10**18);

        // Transfer tokens to Pool (Pool must hold tokens before bootstrapping)
        usdt.transfer(address(pool), vaultLiquidity);
        xsgd.transfer(address(pool), vaultLiquidity);

        // Prepare amounts array for bootstrap
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = vaultLiquidity; // XSGD
        amounts[1] = vaultLiquidity; // USDT

        // Bootstrap Pool - deposits tokens into all vaults
        pool.bootstrapPool(amounts);

        console.log("All vaults funded with Pool deposits:");
        console.log("  XSGD Pool deposit:", xsgdVault.userDeposits(address(pool)) / 10**18);
        console.log("  USDT Pool deposit:", usdtVault.userDeposits(address(pool)) / 10**18);

        // ===========================================
        // 6. Create & Fund Test User Wallet
        //    - Gas tokens (ETH) for transactions
        //    - Minted currencies (XSGD, USDT) for swapping
        // ===========================================
        console.log("\n=== Creating & Funding Test User Wallet ===");
        console.log("Test user address:", testUser);

        // Transfer gas tokens to test user
        vm.deal(testUser, testUserGas);
        console.log("Transferred ETH to test user:", testUserGas / 1e18, "ETH");

        // Transfer minted currencies to test user
        usdt.transfer(testUser, testUserTokens);
        console.log("Transferred USDT to test user:", testUserTokens / 10**18);

        xsgd.transfer(testUser, testUserTokens);
        console.log("Transferred XSGD to test user:", testUserTokens / 10**18);

        console.log("\n=== Setup Complete ===");
        console.log("All vaults funded - swaps can work in both directions!");
        console.log("Test user ready with gas + tokens for testing");
    }

    function testSwapUSDTToXSGD() public {
        console.log("\n=== Test: Swap USDT to XSGD ===");

        // Get initial balances for test user
        uint256 usdtBefore = usdt.balanceOf(testUser);
        uint256 xsgdBefore = xsgd.balanceOf(testUser);

        console.log("Test user USDT before:", usdtBefore / 10**18);
        console.log("Test user XSGD before:", xsgdBefore / 10**18);

        // Test user approves and swaps
        uint256 swapAmount = 100 * 10**18; // 100 USDT

        vm.prank(testUser);
        usdt.approve(address(pool), swapAmount);

        bytes memory priceData = "";
        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: priceData
        });

        vm.prank(testUser);
        uint256 amountOut = pool.swap(params);

        // Verify results
        uint256 usdtAfter = usdt.balanceOf(testUser);
        uint256 xsgdAfter = xsgd.balanceOf(testUser);

        assertEq(usdtBefore - usdtAfter, swapAmount, "USDT should decrease by swap amount");
        assertGt(xsgdAfter - xsgdBefore, 0, "XSGD should increase");
        assertGt(amountOut, 0, "Should receive output tokens");

        console.log("Swapped USDT:", swapAmount / 10**18);
        console.log("Received XSGD:", amountOut / 10**18);
        console.log("Test user USDT after:", usdtAfter / 10**18);
        console.log("Test user XSGD after:", xsgdAfter / 10**18);
    }

    function testVaultDepositAndWithdraw() public {
        console.log("\n=== Test: Vault Deposit and Withdraw ===");

        uint256 depositAmount = 1000 * 10**18;

        // Get initial balances for test user
        uint256 userTokenBefore = usdt.balanceOf(testUser);
        uint256 vaultTokenBefore = usdtVault.getBalance();
        uint256 userDepositBefore = usdtVault.userDeposits(testUser);

        console.log("Test user USDT before:", userTokenBefore / 10**18);
        console.log("Vault balance before:", vaultTokenBefore / 10**18);

        // Test user deposits
        vm.prank(testUser);
        usdt.approve(address(usdtVault), depositAmount);
        vm.prank(testUser);
        usdtVault.deposit(depositAmount);

        // Verify deposit
        assertEq(userTokenBefore - usdt.balanceOf(testUser), depositAmount, "User token balance should decrease");
        assertEq(usdtVault.getBalance(), vaultTokenBefore + depositAmount, "Vault balance should increase");
        assertEq(usdtVault.userDeposits(testUser), userDepositBefore + depositAmount, "User deposit should increase");

        console.log("Test user deposited:", depositAmount / 10**18);
        console.log("Vault balance after:", usdtVault.getBalance() / 10**18);

        // Withdraw
        uint256 withdrawAmount = 500 * 10**18;
        vm.prank(testUser);
        usdtVault.withdraw(withdrawAmount);

        // Verify withdrawal
        assertEq(usdtVault.userDeposits(testUser), userDepositBefore + depositAmount - withdrawAmount, "User deposit should decrease");

        console.log("Test user withdrew:", withdrawAmount / 10**18);
        console.log("Test user deposit after:", usdtVault.userDeposits(testUser) / 10**18);
    }

    function testLockForCrossChain() public {
        console.log("\n=== Test: Lock Tokens for Cross-Chain ===");

        // First deposit some tokens
        uint256 depositAmount = 1000 * 10**18;
        vm.prank(testUser);
        usdt.approve(address(usdtVault), depositAmount);
        vm.prank(testUser);
        usdtVault.deposit(depositAmount);

        uint256 userDepositBefore = usdtVault.userDeposits(testUser);

        // Lock tokens for cross-chain transfer
        uint64 targetChain = 421614; // Arbitrum Sepolia
        uint256 lockAmount = 500 * 10**18;

        vm.prank(testUser);
        usdtVault.lockForCrossChain(targetChain, lockAmount);

        // Verify lock
        assertEq(usdtVault.userDeposits(testUser), userDepositBefore - lockAmount, "User deposit should decrease");

        console.log("Test user locked tokens:", lockAmount / 10**18);
        console.log("Target chain:", targetChain);
        console.log("Test user deposit after lock:", usdtVault.userDeposits(testUser) / 10**18);
    }

    function testUpdateChainBalance() public {
        uint64 remoteChain = 421614; // Arbitrum Sepolia
        uint256 remoteBalance = 50000 * 10**18;

        usdtVault.updateChainBalance(remoteChain, remoteBalance);

        // Verify update
        assertEq(usdtVault.getChainBalance(remoteChain), remoteBalance, "Remote chain balance should be updated");

        console.log("=== Chain Balance Update Test ===");
        console.log("Remote chain:", remoteChain);
        console.log("Remote balance:", remoteBalance / 10**18);
    }

    function testSlippageProtection() public {
        console.log("\n=== Test: Slippage Protection ===");

        uint256 swapAmount = 100 * 10**18;

        vm.prank(testUser);
        usdt.approve(address(pool), swapAmount);

        bytes memory priceData = "";
        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 999_999 * 10**18, // Unrealistic slippage protection
            priceData: priceData
        });

        vm.prank(testUser);
        vm.expectRevert("Pool: slippage exceeded");
        pool.swap(params);

        console.log("Slippage protection working correctly");
    }

    function testBidirectionalSwaps() public {
        console.log("\n=== Test: Bidirectional Swaps (All Vaults Funded) ===");

        // Get initial balances
        uint256 usdtBefore = usdt.balanceOf(testUser);
        uint256 xsgdBefore = xsgd.balanceOf(testUser);

        console.log("Initial balances:");
        console.log("  USDT:", usdtBefore / 10**18);
        console.log("  XSGD:", xsgdBefore / 10**18);

        // ===========================================
        // Swap 1: USDT -> XSGD
        // ===========================================
        uint256 swapAmount1 = 100 * 10**18; // 100 USDT

        vm.prank(testUser);
        usdt.approve(address(pool), swapAmount1);

        IPool.SwapParams memory params1 = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount1,
            minAmountOut: 0,
            priceData: ""
        });

        vm.prank(testUser);
        uint256 receivedXSGD = pool.swap(params1);

        console.log("\nSwap 1: USDT -> XSGD");
        console.log("  Input USDT:", swapAmount1 / 10**18);
        console.log("  Output XSGD:", receivedXSGD / 10**18);

        // ===========================================
        // Swap 2: XSGD -> USDT
        // ===========================================
        uint256 swapAmount2 = 50 * 10**18; // 50 XSGD

        vm.prank(testUser);
        xsgd.approve(address(pool), swapAmount2);

        IPool.SwapParams memory params2 = IPool.SwapParams({
            tokenIn: address(xsgd),
            tokenOut: address(usdt),
            amountIn: swapAmount2,
            minAmountOut: 0,
            priceData: ""
        });

        vm.prank(testUser);
        uint256 receivedUSDT = pool.swap(params2);

        console.log("\nSwap 2: XSGD -> USDT");
        console.log("  Input XSGD:", swapAmount2 / 10**18);
        console.log("  Output USDT:", receivedUSDT / 10**18);

        // ===========================================
        // Verify final balances
        // ===========================================
        uint256 usdtAfter = usdt.balanceOf(testUser);
        uint256 xsgdAfter = xsgd.balanceOf(testUser);

        console.log("\nFinal balances:");
        console.log("  USDT:", usdtAfter / 10**18);
        console.log("  XSGD:", xsgdAfter / 10**18);

        // Both vaults should have liquidity
        assertGt(usdtVault.getBalance(), 0, "USDT vault should have liquidity");
        assertGt(xsgdVault.getBalance(), 0, "XSGD vault should have liquidity");

        console.log("\nVault balances:");
        console.log("  USDT Vault:", usdtVault.getBalance() / 10**18);
        console.log("  XSGD Vault:", xsgdVault.getBalance() / 10**18);

        console.log("\nAll vaults funded - bidirectional swaps working!");
    }
}
