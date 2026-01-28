// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/pool/IPool.sol";

/**
 * @title LiveSwapTest
 * @notice Execute live swap test from deployer account
 *
 * Usage:
 *   1. Deploy contracts using DeployTestEnv.s.sol
 *   2. Update addresses below with deployed addresses
 *   3. Run this script to execute live swap
 *
 *   forge script script/LiveTest.s.sol:LiveSwapTest \
 *     --rpc-url $RPC_URL \
 *     --broadcast \
 *     -vvv
 *
 * Note: Deployer wallet is used as the test user since it already has tokens
 * from the initial minting (900k of each token after funding vaults with 100k)
 */
contract LiveSwapTest is Script {
    // ===========================================
    // CONFIGURATION - Update these with deployed addresses
    // ===========================================
    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;  // Deployed on Sepolia
    address constant XSGD = 0x8c6870dBF36bEbF4c7734C35D6b2DD5AeCe9b385;  // Deployed on Sepolia
    address constant USDT = 0x4B198D1285152B5f8BCbC5e4156D30717B16275e; // Deployed on Sepolia

    // Swap amount
    uint256 constant SWAP_AMOUNT = 100 * 10**18; // 100 USDT

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Live Swap Test ===");
        console.log("Deployer (Test User):", deployer);
        console.log("Chain ID:", block.chainid);

        IERC20 usdt = IERC20(USDT);
        IERC20 xsgd = IERC20(XSGD);
        IPool pool = IPool(POOL);

        // Check initial balances
        console.log("\n--- Initial Balances ---");
        uint256 usdtBefore = usdt.balanceOf(deployer);
        uint256 xsgdBefore = xsgd.balanceOf(deployer);
        console.log("USDT:", usdtBefore / 10**18);
        console.log("XSGD:", xsgdBefore / 10**18);

        vm.startBroadcast(deployerPrivateKey);

        // Approve Pool to spend USDT
        console.log("\n--- Approving Pool ---");
        usdt.approve(POOL, SWAP_AMOUNT);
        console.log("Approved Pool for", SWAP_AMOUNT / 10**18);
        console.log("  Token: USDT");

        // Execute swap: USDT -> XSGD
        console.log("\n--- Executing Swap: USDT -> XSGD ---");

        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: USDT,
            tokenOut: XSGD,
            amountIn: SWAP_AMOUNT,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 amountOut = pool.swap(params);
        console.log("Swapped USDT:", SWAP_AMOUNT / 10**18);
        console.log("Received XSGD:", amountOut / 10**18);

        vm.stopBroadcast();

        // Check final balances
        console.log("\n--- Final Balances ---");
        uint256 usdtAfter = usdt.balanceOf(deployer);
        uint256 xsgdAfter = xsgd.balanceOf(deployer);
        console.log("USDT:", usdtAfter / 10**18);
        console.log("  Spent:", (usdtBefore - usdtAfter) / 10**18);
        console.log("XSGD:", xsgdAfter / 10**18);
        console.log("  Received:", (xsgdAfter - xsgdBefore) / 10**18);

        console.log("\n=== Live Swap Test Complete ===");
        console.log("Swap executed successfully on deployed contracts!");
    }
}
