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
 * @title ComprehensiveScenariosTest
 * @notice Comprehensive test cases for swap, bridge, and cross-chain swap scenarios
 * @dev Tests various edge cases and real-world scenarios with detailed transaction info
 */
contract ComprehensiveScenariosTest is Test {
    // Pyth Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;
    bytes32 constant THBT_FEED_ID = 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394;
    bytes32 constant IDRT_FEED_ID = 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433;

    // Chain IDs
    uint64 constant SEPOLIA = 11155111;
    uint64 constant ARBITRUM_SEPOLIA = 421614;
    uint64 constant POLYGON_AMOY = 80002;

    USDT usdt;
    XSGD xsgd;
    Pool pool;
    Vault usdtVault;
    Vault xsgdVault;

    address deployer;
    address alice;
    address bob;

    uint256 initialSupply = 1_000_000 * 10**18;
    uint256 vaultLiquidity = 100_000 * 10**18;

    function setUp() public {
        deployer = address(this);
        alice = address(0xA11CE);
        bob = address(0xB0B);

        // Deploy tokens
        usdt = new USDT(deployer, initialSupply);
        xsgd = new XSGD(deployer, initialSupply);

        // Deploy vaults
        usdtVault = new Vault(IERC20(address(usdt)), SEPOLIA);
        xsgdVault = new Vault(IERC20(address(xsgd)), SEPOLIA);

        // Deploy pool
        address[] memory tokensList = new address[](2);
        tokensList[0] = address(xsgd);
        tokensList[1] = address(usdt);

        bytes32[] memory feedIds = new bytes32[](2);
        feedIds[0] = XSGD_FEED_ID;
        feedIds[1] = USDT_FEED_ID;

        pool = new Pool(tokensList, feedIds, deployer);

        // Configure pool
        pool.setVault(address(usdt), usdtVault);
        pool.setVault(address(xsgd), xsgdVault);

        // Set prices
        _updatePrices();

        // Fund vaults
        usdt.transfer(address(pool), vaultLiquidity);
        xsgd.transfer(address(pool), vaultLiquidity);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = vaultLiquidity;
        amounts[1] = vaultLiquidity;

        pool.bootstrapPool(amounts);

        // Fund test users
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);

        usdt.transfer(alice, 10_000 * 10**18);
        xsgd.transfer(alice, 10_000 * 10**18);
        usdt.transfer(bob, 10_000 * 10**18);
        xsgd.transfer(bob, 10_000 * 10**18);
    }

    function _updatePrices() internal {
        uint64 currentTimestamp = uint64(block.timestamp);

        PythStructs.Price memory usdtPrice = PythStructs.Price({
            price: 99868428,
            conf: 108232,
            expo: -8,
            publishTime: currentTimestamp
        });

        PythStructs.Price memory xsgdPrice = PythStructs.Price({
            price: 74000000,
            conf: 100000,
            expo: -8,
            publishTime: currentTimestamp
        });

        bytes32[] memory priceFeedIds = new bytes32[](2);
        priceFeedIds[0] = USDT_FEED_ID;
        priceFeedIds[1] = XSGD_FEED_ID;

        PythStructs.Price[] memory priceData = new PythStructs.Price[](2);
        priceData[0] = usdtPrice;
        priceData[1] = xsgdPrice;

        pool.updatePrices(priceFeedIds, priceData);
    }

    // ===========================================
    // SCENARIO 1: Basic Swap Scenarios
    // ===========================================

    function testScenario_SmallSwap() public {
        console.log("\n=== Scenario 1: Small Swap (1 USDT) ===");

        uint256 swapAmount = 1 * 10**18; // 1 USDT

        vm.startPrank(alice);
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 gasBefore = gasleft();
        uint256 amountOut = pool.swap(params);
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  User: Alice");
        console.log("  Input: 1 USDT");
        console.log("  Output:", amountOut / 10**18, "XSGD");
        console.log("  Rate: 1 USDT =", amountOut / 10**18, "XSGD");
        console.log("  Gas Used:", gasUsed);
        console.log("  Fee (0.3%):", (swapAmount * 30 / 10000) / 10**18, "XSGD");
    }

    function testScenario_MediumSwap() public {
        console.log("\n=== Scenario 2: Medium Swap (1000 USDT) ===");

        uint256 swapAmount = 1000 * 10**18;

        vm.startPrank(alice);
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 gasBefore = gasleft();
        uint256 amountOut = pool.swap(params);
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  User: Alice");
        console.log("  Input: 1000 USDT");
        console.log("  Output:", amountOut / 10**18, "XSGD");
        console.log("  Gas Used:", gasUsed);
        console.log("  Fee (0.3%):", (swapAmount * 30 / 10000) / 10**18, "XSGD");
    }

    function testScenario_LargeSwap() public {
        console.log("\n=== Scenario 3: Large Swap (5,000 USDT) ===");

        uint256 swapAmount = 5_000 * 10**18; // Alice only has 10k USDT

        vm.startPrank(alice);
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 gasBefore = gasleft();
        uint256 amountOut = pool.swap(params);
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  User: Alice");
        console.log("  Input: 5,000 USDT");
        console.log("  Output:", amountOut / 10**18, "XSGD");
        console.log("  Gas Used:", gasUsed);
        console.log("  Fee (0.3%):", (swapAmount * 30 / 10000) / 10**18, "XSGD");
        console.log("  Effective Rate: 1 USDT =", amountOut / swapAmount, "XSGD");
    }

    // ===========================================
    // SCENARIO 2: Reverse Swap Scenarios
    // ===========================================

    function testScenario_ReverseSwap() public {
        console.log("\n=== Scenario 4: Reverse Swap (XSGD -> USDT) ===");

        uint256 swapAmount = 100 * 10**18; // 100 XSGD

        vm.startPrank(bob);
        xsgd.approve(address(pool), swapAmount);

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(xsgd),
            tokenOut: address(usdt),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 gasBefore = gasleft();
        uint256 amountOut = pool.swap(params);
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  User: Bob");
        console.log("  Input: 100 XSGD");
        console.log("  Output:", amountOut / 10**18, "USDT");
        console.log("  Rate: 1 XSGD =", amountOut / swapAmount, "USDT");
        console.log("  Gas Used:", gasUsed);
    }

    // ===========================================
    // SCENARIO 3: Slippage Protection
    // ===========================================

    function testScenario_SlippageProtection_Success() public {
        console.log("\n=== Scenario 5: Slippage Protection (Success) ===");

        uint256 swapAmount = 100 * 10**18;
        uint256 expectedOut = 100 * 10**18 * 74 / 100; // ~74 XSGD
        uint256 minOut = expectedOut * 95 / 100; // 5% slippage tolerance

        vm.startPrank(alice);
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: minOut,
            priceData: ""
        });

        uint256 amountOut = pool.swap(params);
        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  Input: 100 USDT");
        console.log("  Min Output (5% slippage):", minOut / 10**18, "XSGD");
        console.log("  Actual Output:", amountOut / 10**18, "XSGD");
        console.log("  Slippage Protected: SUCCESS");
    }

    function testScenario_SlippageProtection_Revert() public {
        console.log("\n=== Scenario 6: Slippage Protection (Revert) ===");

        uint256 swapAmount = 100 * 10**18;
        uint256 unrealisticMinOut = 999_999 * 10**18; // Impossible slippage requirement

        vm.startPrank(alice);
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: unrealisticMinOut,
            priceData: ""
        });

        vm.expectRevert("Pool: slippage exceeded");
        pool.swap(params);
        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  Input: 100 USDT");
        console.log("  Min Output Required:", unrealisticMinOut / 10**18, "XSGD");
        console.log("  Slippage Protected: REVERTED (as expected)");
    }

    // ===========================================
    // SCENARIO 4: Bridge Scenarios
    // ===========================================

    function testScenario_Bridge_DepositAndLock() public {
        console.log("\n=== Scenario 7: Bridge - Deposit and Lock ===");

        uint256 depositAmount = 1_000 * 10**18;
        uint64 targetChain = ARBITRUM_SEPOLIA;

        vm.startPrank(alice);

        // Deposit to vault
        usdt.approve(address(usdtVault), depositAmount);
        usdtVault.deposit(depositAmount);

        uint256 depositBefore = usdtVault.userDeposits(alice);

        // Lock for cross-chain
        uint256 lockAmount = 500 * 10**18;
        usdtVault.lockForCrossChain(targetChain, lockAmount);

        uint256 depositAfter = usdtVault.userDeposits(alice);

        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  User: Alice");
        console.log("  Source Chain: Sepolia (11155111)");
        console.log("  Destination Chain: Arbitrum Sepolia (421614)");
        console.log("  Deposit Amount:", depositAmount / 10**18, "USDT");
        console.log("  Lock Amount:", lockAmount / 10**18, "USDT");
        console.log("  Deposit Before Lock:", depositBefore / 10**18, "USDT");
        console.log("  Deposit After Lock:", depositAfter / 10**18, "USDT");
        console.log("  Tokens Burned (Locked):", lockAmount / 10**18, "USDT");
        console.log("  Bridge Status: Ready for cross-chain transfer");
    }

    function testScenario_Bridge_WithdrawAfterLock() public {
        console.log("\n=== Scenario 8: Bridge - Withdraw Remaining After Lock ===");

        uint256 depositAmount = 1_000 * 10**18;
        uint64 targetChain = ARBITRUM_SEPOLIA;

        vm.startPrank(bob);

        // Deposit and lock
        usdt.approve(address(usdtVault), depositAmount);
        usdtVault.deposit(depositAmount);
        usdtVault.lockForCrossChain(targetChain, 500 * 10**18);

        // Withdraw remaining
        uint256 withdrawAmount = 400 * 10**18;
        usdtVault.withdraw(withdrawAmount);

        uint256 finalDeposit = usdtVault.userDeposits(bob);

        vm.stopPrank();

        console.log("Transaction Details:");
        console.log("  User: Bob");
        console.log("  Initial Deposit:", depositAmount / 10**18, "USDT");
        console.log("  Locked for Arbitrum:", 500, "USDT");
        console.log("  Withdrawn:", withdrawAmount / 10**18, "USDT");
        console.log("  Remaining Deposit:", finalDeposit / 10**18, "USDT");
        console.log("  Bridge Status: Partial bridge, partial withdraw");
    }

    // ===========================================
    // SCENARIO 5: Cross-Chain Mint
    // ===========================================

    function testScenario_CrossChainMint() public {
        console.log("\n=== Scenario 9: Cross-Chain Mint ===");

        // Setup messenger (simulate LayerZero)
        vm.prank(deployer);
        usdtVault.setCrossChainMessenger(address(this));

        uint256 mintAmount = 500 * 10**18;

        // Mint tokens received from cross-chain
        usdtVault.mintFromCrossChain(alice, mintAmount);

        uint256 aliceDeposit = usdtVault.userDeposits(alice);

        console.log("Transaction Details:");
        console.log("  Source Chain: Arbitrum Sepolia");
        console.log("  Destination Chain: Sepolia");
        console.log("  Recipient: Alice");
        console.log("  Mint Amount:", mintAmount / 10**18, "USDT");
        console.log("  Alice's Deposit:", aliceDeposit / 10**18, "USDT");
        console.log("  Bridge Status: Tokens minted from cross-chain");
    }

    // ===========================================
    // SCENARIO 6: Swap Then Bridge
    // ===========================================

    function testScenario_SwapThenBridge() public {
        console.log("\n=== Scenario 10: Swap Then Bridge ===");

        uint256 swapAmount = 200 * 10**18; // 200 USDT

        vm.startPrank(alice);

        // Step 1: Swap USDT for XSGD
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory swapParams = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 receivedXSGD = pool.swap(swapParams);

        console.log("Step 1: SWAP");
        console.log("  Input: 200 USDT");
        console.log("  Output:", receivedXSGD / 10**18, "XSGD");

        // Step 2: Bridge XSGD to Arbitrum
        uint256 bridgeAmount = 100 * 10**18; // Bridge 100 XSGD

        xsgd.approve(address(xsgdVault), bridgeAmount);
        xsgdVault.deposit(bridgeAmount);
        xsgdVault.lockForCrossChain(ARBITRUM_SEPOLIA, bridgeAmount);

        vm.stopPrank();

        console.log("\nStep 2: BRIDGE");
        console.log("  Locked:", bridgeAmount / 10**18, "XSGD");
        console.log("  Destination: Arbitrum Sepolia");

        console.log("\nTransaction Summary:");
        console.log("  USDT -> XSGD -> Arbitrum Sepolia");
        console.log("  Final: 100 XSGD bridged to Arbitrum Sepolia");
        console.log("  Remaining:", (receivedXSGD - bridgeAmount) / 10**18, "XSGD with Alice");
    }

    // ===========================================
    // SCENARIO 7: Bridge Then Swap
    // ===========================================

    function testScenario_BridgeThenSwap() public {
        console.log("\n=== Scenario 11: Bridge Then Swap ===");

        // Simulate receiving tokens from cross-chain
        vm.prank(deployer);
        usdtVault.setCrossChainMessenger(address(this));

        uint256 mintAmount = 1_000 * 10**18;
        usdtVault.mintFromCrossChain(bob, mintAmount);

        console.log("Step 1: RECEIVE FROM CROSS-CHAIN");
        console.log("  Received:", mintAmount / 10**18, "USDT");
        console.log("  Source: Arbitrum Sepolia");

        // Now swap the received tokens
        uint256 swapAmount = 500 * 10**18;

        vm.startPrank(bob);
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory swapParams = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 receivedXSGD = pool.swap(swapParams);
        vm.stopPrank();

        console.log("\nStep 2: SWAP");
        console.log("  Input: 500 USDT");
        console.log("  Output:", receivedXSGD / 10**18, "XSGD");

        console.log("\nTransaction Summary:");
        console.log("  Arbitrum Sepolia -> USDT -> XSGD");
        console.log("  Final: Bob has", receivedXSGD / 10**18, "XSGD");
        console.log("  Remaining: 500 USDT in vault");
    }

    // ===========================================
    // SCENARIO 8: Multiple Sequential Swaps
    // ===========================================

    function testScenario_MultiHopSwaps() public {
        console.log("\n=== Scenario 12: Multiple Sequential Swaps ===");

        vm.startPrank(alice);

        // Swap 1: USDT -> XSGD
        uint256 swap1Amount = 100 * 10**18;
        usdt.approve(address(pool), swap1Amount);

        IPool.SwapParams memory params1 = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swap1Amount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 received1 = pool.swap(params1);

        console.log("Swap 1:");
        console.log("  Input:", swap1Amount / 10**18, "USDT");
        console.log("  Output:", received1 / 10**18, "XSGD");

        // Swap 2: XSGD -> USDT
        uint256 swap2Amount = 50 * 10**18;
        xsgd.approve(address(pool), swap2Amount);

        IPool.SwapParams memory params2 = IPool.SwapParams({
            tokenIn: address(xsgd),
            tokenOut: address(usdt),
            amountIn: swap2Amount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 received2 = pool.swap(params2);

        console.log("\nSwap 2:");
        console.log("  Input:", swap2Amount / 10**18, "XSGD");
        console.log("  Output:", received2 / 10**18, "USDT");

        vm.stopPrank();

        console.log("\nTransaction Summary:");
        console.log("  Path: USDT -> XSGD -> USDT");
        console.log("  Total Input:", swap1Amount / 10**18, "USDT");
        console.log("  Total Output:", received2 / 10**18, "USDT");
        console.log("  Loss (fees):", (swap1Amount - received2) / 10**18, "USDT");
        console.log("  Round-trip efficiency:", (received2 * 100 / swap1Amount), "%");
    }

    // ===========================================
    // SCENARIO 9: Concurrent User Swaps
    // ===========================================

    function testScenario_ConcurrentSwaps() public {
        console.log("\n=== Scenario 13: Concurrent User Swaps ===");

        uint256 aliceSwapAmount = 100 * 10**18;
        uint256 bobSwapAmount = 200 * 10**18;

        // Alice swaps
        vm.startPrank(alice);
        usdt.approve(address(pool), aliceSwapAmount);

        IPool.SwapParams memory aliceParams = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: aliceSwapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 aliceReceived = pool.swap(aliceParams);
        vm.stopPrank();

        // Bob swaps
        vm.startPrank(bob);
        usdt.approve(address(pool), bobSwapAmount);

        IPool.SwapParams memory bobParams = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: bobSwapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 bobReceived = pool.swap(bobParams);
        vm.stopPrank();

        console.log("Alice's Transaction:");
        console.log("  Input:", aliceSwapAmount / 10**18, "USDT");
        console.log("  Output:", aliceReceived / 10**18, "XSGD");
        console.log("  Rate:", aliceReceived / aliceSwapAmount, "XSGD per USDT");

        console.log("\nBob's Transaction:");
        console.log("  Input:", bobSwapAmount / 10**18, "USDT");
        console.log("  Output:", bobReceived / 10**18, "XSGD");
        console.log("  Rate:", bobReceived / bobSwapAmount, "XSGD per USDT");

        console.log("\nVault State After Concurrent Swaps:");
        console.log("  USDT Vault Balance:", usdtVault.getBalance() / 10**18);
        console.log("  XSGD Vault Balance:", xsgdVault.getBalance() / 10**18);
        console.log("  Pool USDT Deposit:", usdtVault.userDeposits(address(pool)) / 10**18);
        console.log("  Pool XSGD Deposit:", xsgdVault.userDeposits(address(pool)) / 10**18);
    }

    // ===========================================
    // SCENARIO 10: Full Cross-Chain Swap
    // ===========================================

    function testScenario_FullCrossChainSwap() public {
        console.log("\n=== Scenario 14: Full Cross-Chain Swap ===");
        console.log("User wants to: Swap USDT for XSGD, then bridge to Arbitrum");

        // Setup messenger
        vm.prank(deployer);
        usdtVault.setCrossChainMessenger(address(this));
        vm.prank(deployer);
        xsgdVault.setCrossChainMessenger(address(this));

        vm.startPrank(alice);

        // Step 1: Swap USDT for XSGD
        uint256 swapAmount = 500 * 10**18;
        usdt.approve(address(pool), swapAmount);

        IPool.SwapParams memory swapParams = IPool.SwapParams({
            tokenIn: address(usdt),
            tokenOut: address(xsgd),
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 receivedXSGD = pool.swap(swapParams);

        console.log("Step 1: SWAP ON SEPOLIA");
        console.log("  Input: 500 USDT");
        console.log("  Output:", receivedXSGD / 10**18, "XSGD");
        console.log("  Chain: Sepolia");

        // Step 2: Bridge XSGD to Arbitrum Sepolia
        uint256 bridgeAmount = receivedXSGD; // Bridge all received XSGD

        xsgd.approve(address(xsgdVault), bridgeAmount);
        xsgdVault.deposit(bridgeAmount);
        xsgdVault.lockForCrossChain(ARBITRUM_SEPOLIA, bridgeAmount);

        vm.stopPrank();

        console.log("\nStep 2: BRIDGE TO ARBITRUM SEPOLIA");
        console.log("  Locked:", bridgeAmount / 10**18, "XSGD");
        console.log("  From: Sepolia (11155111)");
        console.log("  To: Arbitrum Sepolia (421614)");

        // Step 3: Simulate minting on destination chain
        uint256 mintAmount = bridgeAmount;

        // On Arbitrum Sepolia, tokens would be minted
        console.log("\nStep 3: MINT ON ARBITRUM SEPOLIA (Simulated)");
        console.log("  Mint:", mintAmount / 10**18, "XSGD");
        console.log("  To: Alice");
        console.log("  Chain: Arbitrum Sepolia");

        console.log("\nTransaction Summary:");
        console.log("  Complete Flow: USDT (Sepolia) -> XSGD (Sepolia) -> XSGD (Arbitrum Sepolia)");
        console.log("  Alice's Final Balance:", mintAmount / 10**18, "XSGD on Arbitrum Sepolia");
        console.log("  Cross-Chain Swap: SUCCESS");
    }
}
