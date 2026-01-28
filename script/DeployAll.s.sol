// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/XSGD.sol";
import "../src/tokens/THBT.sol";
import "../src/tokens/IDRT.sol";
import "../src/tokens/USDT.sol";
import "../src/vault/Vault.sol";
import "../src/pool/Pool.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title DeployAll
 * @notice Deploys all tokens, vaults, and pool to a single chain
 */
contract DeployAll is Script {
    // Chain IDs
    uint64 constant SEPOLIA = 11155111;
    uint64 constant ARBITRUM_SEPOLIA = 421614;
    uint64 constant POLYGON_AMOY = 80002;

    // Pyth feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant THBT_FEED_ID = 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433;
    bytes32 constant IDRT_FEED_ID = 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    // Initial supply for tokens (1,000,000 tokens)
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // ===========================================
        // 1. Deploy Tokens
        // ===========================================
        console.log("\n=== Deploying Tokens ===");

        XSGD xsgd = new XSGD(deployer, INITIAL_SUPPLY);
        console.log("XSGD deployed at:", address(xsgd));

        THBT thbt = new THBT(deployer, INITIAL_SUPPLY);
        console.log("THBT deployed at:", address(thbt));

        IDRT idrt = new IDRT(deployer, INITIAL_SUPPLY);
        console.log("IDRT deployed at:", address(idrt));

        USDT usdt = new USDT(deployer, INITIAL_SUPPLY);
        console.log("USDT deployed at:", address(usdt));

        // ===========================================
        // 2. Deploy Vaults
        // ===========================================
        console.log("\n=== Deploying Vaults ===");

        // Get current chain ID
        uint64 chainId = uint64(block.chainid);
        console.log("Current chain ID:", chainId);

        Vault xsgdVault = new Vault(IERC20(address(xsgd)), chainId);
        console.log("XSGD Vault deployed at:", address(xsgdVault));

        Vault thbtVault = new Vault(IERC20(address(thbt)), chainId);
        console.log("THBT Vault deployed at:", address(thbtVault));

        Vault idrtVault = new Vault(IERC20(address(idrt)), chainId);
        console.log("IDRT Vault deployed at:", address(idrtVault));

        Vault usdtVault = new Vault(IERC20(address(usdt)), chainId);
        console.log("USDT Vault deployed at:", address(usdtVault));

        // ===========================================
        // 3. Deploy Pool
        // ===========================================
        console.log("\n=== Deploying Pool ===");

        // Prepare token and feed ID arrays
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

        Pool pool = new Pool(
            tokensList,
            feedIds,
            deployer
        );
        console.log("Pool deployed at:", address(pool));

        // ===========================================
        // 4. Configure Pool
        // ===========================================
        console.log("\n=== Configuring Pool ===");

        pool.setVault(address(xsgd), IVault(address(xsgdVault)));
        console.log("Set XSGD vault in pool");

        pool.setVault(address(thbt), IVault(address(thbtVault)));
        console.log("Set THBT vault in pool");

        pool.setVault(address(idrt), IVault(address(idrtVault)));
        console.log("Set IDRT vault in pool");

        pool.setVault(address(usdt), IVault(address(usdtVault)));
        console.log("Set USDT vault in pool");

        // ===========================================
        // 5. Bootstrap Pool with Initial Liquidity
        // ===========================================
        console.log("\n=== Bootstrapping Pool ===");

        uint256 poolLiquidity = 100_000 * 10**18;
        console.log("Bootstrapping pool with:", poolLiquidity / 10**18, "tokens per vault");

        // Transfer tokens to Pool
        xsgd.transfer(address(pool), poolLiquidity);
        console.log("Transferred XSGD to pool");

        thbt.transfer(address(pool), poolLiquidity);
        console.log("Transferred THBT to pool");

        idrt.transfer(address(pool), poolLiquidity);
        console.log("Transferred IDRT to pool");

        usdt.transfer(address(pool), poolLiquidity);
        console.log("Transferred USDT to pool");

        // Prepare amounts array for bootstrap
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = poolLiquidity; // XSGD
        amounts[1] = poolLiquidity; // THBT
        amounts[2] = poolLiquidity; // IDRT
        amounts[3] = poolLiquidity; // USDT

        // Call bootstrapPool function
        pool.bootstrapPool(amounts);
        console.log("Pool bootstrapped with liquidity in all vaults");

        vm.stopBroadcast();

        // ===========================================
        // 6. Summary
        // ===========================================
        console.log("\n=== Deployment Summary ===");
        console.log("Tokens:");
        console.log("  XSGD:  ", address(xsgd));
        console.log("  THBT:  ", address(thbt));
        console.log("  IDRT:  ", address(idrt));
        console.log("  USDT:  ", address(usdt));
        console.log("\nVaults:");
        console.log("  XSGD:  ", address(xsgdVault));
        console.log("  THBT:  ", address(thbtVault));
        console.log("  IDRT:  ", address(idrtVault));
        console.log("  USDT:  ", address(usdtVault));
        console.log("\nPool:");
        console.log("  Pool:  ", address(pool));
        console.log("\nDeployment complete!");
    }
}
