// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/pool/IPool.sol";
import "../src/vault/IVault.sol";

/**
 * @title QuickTest
 * @notice Quick helper script for common testing operations
 *
 * Usage:
 *   forge script script/QuickTest.s.sol:QuickTest --rpc-url $RPC_URL --broadcast
 */
contract QuickTest is Script {
    // ===========================================
    // UPDATE THESE WITH DEPLOYED ADDRESSES
    // ===========================================
    address constant POOL = 0x0000000000000000000000000000000000000000;
    address constant XSGD = 0x0000000000000000000000000000000000000000;
    address constant USDT = 0x0000000000000000000000000000000000000000;
    address constant THBT = 0x0000000000000000000000000000000000000000;
    address constant IDRT = 0x0000000000000000000000000000000000000000;

    address constant XSGD_VAULT = 0x0000000000000000000000000000000000000000;
    address constant USDT_VAULT = 0x0000000000000000000000000000000000000000;
    address constant THBT_VAULT = 0x0000000000000000000000000000000000000000;
    address constant IDRT_VAULT = 0x0000000000000000000000000000000000000000;

    /**
     * @notice Check state of all deployed contracts
     * @dev Run without --broadcast flag (read-only)
     */
    function checkState() external view {
        console.log("\n=== Deployed Contracts State ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);

        console.log("\n--- Token Balances ---");
        IERC20 xsgd = IERC20(XSGD);
        IERC20 usdt = IERC20(USDT);
        IERC20 thbt = IERC20(THBT);
        IERC20 idrt = IERC20(IDRT);

        console.log("XSGD total supply:", xsgd.totalSupply() / 10**18);
        console.log("USDT total supply:", usdt.totalSupply() / 10**18);
        console.log("THBT total supply:", thbt.totalSupply() / 10**18);
        console.log("IDRT total supply:", idrt.totalSupply() / 10**18);

        console.log("\n--- Vault Balances ---");
        IVault xsgdVault = IVault(XSGD_VAULT);
        IVault usdtVault = IVault(USDT_VAULT);
        IVault thbtVault = IVault(THBT_VAULT);
        IVault idrtVault = IVault(IDRT_VAULT);

        console.log("XSGD Vault total:", xsgdVault.getBalance() / 10**18);
        console.log("  Pool deposit:", xsgdVault.userDeposits(POOL) / 10**18);
        console.log("  Total liquidity:", xsgdVault.getTotalLiquidity() / 10**18);

        console.log("USDT Vault total:", usdtVault.getBalance() / 10**18);
        console.log("  Pool deposit:", usdtVault.userDeposits(POOL) / 10**18);
        console.log("  Total liquidity:", usdtVault.getTotalLiquidity() / 10**18);

        console.log("THBT Vault total:", thbtVault.getBalance() / 10**18);
        console.log("  Pool deposit:", thbtVault.userDeposits(POOL) / 10**18);
        console.log("  Total liquidity:", thbtVault.getTotalLiquidity() / 10**18);

        console.log("IDRT Vault total:", idrtVault.getBalance() / 10**18);
        console.log("  Pool deposit:", idrtVault.userDeposits(POOL) / 10**18);
        console.log("  Total liquidity:", idrtVault.getTotalLiquidity() / 10**18);

        console.log("\n--- Pool Configuration ---");
        IPool pool = IPool(POOL);
        console.log("Pool fee (basis points):", pool.feeBps());

        console.log("\n=== State Check Complete ===");
    }

    /**
     * @notice Check balances for a specific address
     * @param user Address to check
     */
    function checkBalances(address user) external view {
        console.log("\n=== Balances for", user, "===");

        IERC20 xsgd = IERC20(XSGD);
        IERC20 usdt = IERC20(USDT);
        IERC20 thbt = IERC20(THBT);
        IERC20 idrt = IERC20(IDRT);

        console.log("ETH:", user.balance / 1e18);
        console.log("XSGD:", xsgd.balanceOf(user) / 10**18);
        console.log("USDT:", usdt.balanceOf(user) / 10**18);
        console.log("THBT:", thbt.balanceOf(user) / 10**18);
        console.log("IDRT:", idrt.balanceOf(user) / 10**18);

        IVault xsgdVault = IVault(XSGD_VAULT);
        IVault usdtVault = IVault(USDT_VAULT);
        IVault thbtVault = IVault(THBT_VAULT);
        IVault idrtVault = IVault(IDRT_VAULT);

        console.log("\nVault Deposits:");
        console.log("  XSGD Vault:", xsgdVault.userDeposits(user) / 10**18);
        console.log("  USDT Vault:", usdtVault.userDeposits(user) / 10**18);
        console.log("  THBT Vault:", thbtVault.userDeposits(user) / 10**18);
        console.log("  IDRT Vault:", idrtVault.userDeposits(user) / 10**18);
    }

    /**
     * @notice Fund a wallet with ETH and tokens
     * @param recipient Address to fund
     * @param ethAmount ETH to send (in wei)
     * @param tokenAmount Tokens to send (each, in wei)
     */
    function fundWallet(
        address recipient,
        uint256 ethAmount,
        uint256 tokenAmount
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Funding Wallet ===");
        console.log("From:", deployer);
        console.log("To:", recipient);
        console.log("ETH:", ethAmount / 1e18);
        console.log("Tokens each:", tokenAmount / 10**18);

        vm.startBroadcast(deployerPrivateKey);

        // Transfer ETH
        payable(recipient).transfer(ethAmount);

        // Transfer tokens
        IERC20(XSGD).transfer(recipient, tokenAmount);
        IERC20(USDT).transfer(recipient, tokenAmount);
        IERC20(THBT).transfer(recipient, tokenAmount);
        IERC20(IDRT).transfer(recipient, tokenAmount);

        vm.stopBroadcast();

        console.log("Funding complete!");
    }

    /**
     * @notice Execute a test swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount to swap (in wei)
     */
    function testSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Test Swap ===");
        console.log("Token In:", tokenIn);
        console.log("Token Out:", tokenOut);
        console.log("Amount:", amountIn / 10**18);

        IERC20 inputToken = IERC20(tokenIn);
        IERC20 outputToken = IERC20(tokenOut);
        IPool pool = IPool(POOL);

        // Check balances before
        uint256 inputBefore = inputToken.balanceOf(deployer);
        uint256 outputBefore = outputToken.balanceOf(deployer);

        console.log("\nBalances before:");
        console.log("  Input:", inputBefore / 10**18);
        console.log("  Output:", outputBefore / 10**18);

        vm.startBroadcast(deployerPrivateKey);

        // Approve pool
        inputToken.approve(POOL, amountIn);

        // Execute swap
        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            minAmountOut: 0,
            priceData: ""
        });

        uint256 amountOut = pool.swap(params);

        vm.stopBroadcast();

        // Check balances after
        uint256 inputAfter = inputToken.balanceOf(deployer);
        uint256 outputAfter = outputToken.balanceOf(deployer);

        console.log("\nBalances after:");
        console.log("  Input:", inputAfter / 10**18);
        console.log("    Spent:", (inputBefore - inputAfter) / 10**18);
        console.log("  Output:", outputAfter / 10**18);
        console.log("    Received:", (outputAfter - outputBefore) / 10**18);
        console.log("  Amount out:", amountOut / 10**18);

        console.log("\nSwap complete!");
    }
}
