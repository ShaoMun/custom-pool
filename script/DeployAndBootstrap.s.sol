// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/XSGD.sol";
import "../src/tokens/THBT.sol";
import "../src/tokens/IDRT.sol";
import "../src/tokens/USDT.sol";
import "../src/vault/Vault.sol";
import "../src/pool/Pool.sol";

/**
 * @title DeployAndBootstrap
 * @notice Deploy all contracts and properly bootstrap the Pool
 */
contract DeployAndBootstrap is Script {
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 constant POOL_LIQUIDITY = 100_000 * 10**18;

    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant THBT_FEED_ID = 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394;
    bytes32 constant IDRT_FEED_ID = 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploy and Bootstrap ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        XSGD xsgd = new XSGD(deployer, INITIAL_SUPPLY);
        THBT thbt = new THBT(deployer, INITIAL_SUPPLY);
        IDRT idrt = new IDRT(deployer, INITIAL_SUPPLY);
        USDT usdt = new USDT(deployer, INITIAL_SUPPLY);

        console.log("Tokens deployed");

        // Deploy vaults
        uint64 chainId = uint64(block.chainid);
        Vault xsgdVault = new Vault(IERC20(address(xsgd)), chainId);
        Vault thbtVault = new Vault(IERC20(address(thbt)), chainId);
        Vault idrtVault = new Vault(IERC20(address(idrt)), chainId);
        Vault usdtVault = new Vault(IERC20(address(usdt)), chainId);

        console.log("Vaults deployed");

        // Deploy pool
        address[] memory tokensList = new address[](4);
        tokensList[0] = address(xsgd);
        tokensList[1] = address(thbt);
        tokensList[2] = address(idrt);
        tokensList[3] = address(usdt);

        bytes32[] memory feedIds = new bytes32[](4);
        feedIds[0] = XSGD_FEED_ID;
        feedIds[1] = THBT_FEED_ID;
        feedIds[2] = IDRT_FEED_ID;
        feedIds[3] = USDT_FEED_ID;

        Pool pool = new Pool(tokensList, feedIds, deployer);
        console.log("Pool deployed");

        // Configure pool
        pool.setVault(address(usdt), usdtVault);
        pool.setVault(address(xsgd), xsgdVault);
        pool.setVault(address(thbt), thbtVault);
        pool.setVault(address(idrt), idrtVault);

        console.log("Pool configured");

        // Bootstrap each vault directly (not through Pool)
        // This gives the Pool deposits in each vault
        xsgd.approve(address(xsgdVault), POOL_LIQUIDITY);
        xsgdVault.deposit(POOL_LIQUIDITY);
        console.log("XSGD vault bootstrapped");

        thbt.approve(address(thbtVault), POOL_LIQUIDITY);
        thbtVault.deposit(POOL_LIQUIDITY);
        console.log("THBT vault bootstrapped");

        idrt.approve(address(idrtVault), POOL_LIQUIDITY);
        idrtVault.deposit(POOL_LIQUIDITY);
        console.log("IDRT vault bootstrapped");

        usdt.approve(address(usdtVault), POOL_LIQUIDITY);
        usdtVault.deposit(POOL_LIQUIDITY);
        console.log("USDT vault bootstrapped");

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Pool:", address(pool));
        console.log("All vaults bootstrapped with 100k tokens for Pool");
        console.log("Pool can now execute swaps!");
    }
}
