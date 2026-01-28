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
 * @title DeployTestEnv
 * @notice Deploy all contracts and set up a test environment with:
 *         1. All vaults funded with initial liquidity (enables bidirectional swaps)
 *         2. Test user wallet with gas tokens + minted currencies
 *         3. Initial price updates
 *
 * Usage:
 *   forge script script/DeployTestEnv.s.sol:DeployTestEnv --rpc-url $RPC_URL --broadcast --verify
 */
contract DeployTestEnv is Script {
    // Configuration
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 constant VAULT_LIQUIDITY = 100_000 * 10**18;  // Liquidity per vault

    // Pyth Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant THBT_FEED_ID = 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394;
    bytes32 constant IDRT_FEED_ID = 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Deploy Test Environment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // ===========================================
        // 1. Deploy Tokens (all minted to deployer)
        // ===========================================
        console.log("\n--- Deploying Tokens ---");

        XSGD xsgd = new XSGD(deployer, INITIAL_SUPPLY);
        console.log("XSGD:", address(xsgd));

        THBT thbt = new THBT(deployer, INITIAL_SUPPLY);
        console.log("THBT:", address(thbt));

        IDRT idrt = new IDRT(deployer, INITIAL_SUPPLY);
        console.log("IDRT:", address(idrt));

        USDT usdt = new USDT(deployer, INITIAL_SUPPLY);
        console.log("USDT:", address(usdt));

        // ===========================================
        // 2. Deploy Vaults
        // ===========================================
        console.log("\n--- Deploying Vaults ---");

        uint64 chainId = uint64(block.chainid);

        Vault xsgdVault = new Vault(IERC20(address(xsgd)), chainId);
        console.log("XSGD Vault:", address(xsgdVault));

        Vault thbtVault = new Vault(IERC20(address(thbt)), chainId);
        console.log("THBT Vault:", address(thbtVault));

        Vault idrtVault = new Vault(IERC20(address(idrt)), chainId);
        console.log("IDRT Vault:", address(idrtVault));

        Vault usdtVault = new Vault(IERC20(address(usdt)), chainId);
        console.log("USDT Vault:", address(usdtVault));

        // ===========================================
        // 3. Deploy Pool
        // ===========================================
        console.log("\n--- Deploying Pool ---");

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
        console.log("Pool:", address(pool));

        // ===========================================
        // 4. Configure Pool with Vaults
        // ===========================================
        console.log("\n--- Configuring Pool ---");

        pool.setVault(address(xsgd), IVault(address(xsgdVault)));
        pool.setVault(address(thbt), IVault(address(thbtVault)));
        pool.setVault(address(idrt), IVault(address(idrtVault)));
        pool.setVault(address(usdt), IVault(address(usdtVault)));
        console.log("All vaults configured");

        // ===========================================
        // 5. Deployer Funds All Vaults with Initial Liquidity
        //    This enables bidirectional swaps (e.g., XSGD <-> USDT)
        //
        //    Process:
        //    1. Transfer tokens from deployer to Pool
        //    2. Call pool.bootstrapPool() to deposit into all vaults
        //
        //    IMPORTANT: We must fund vaults THROUGH the Pool,
        //    so the Pool has userDeposits in each vault to use for swaps
        // ===========================================
        console.log("\n--- Funding Vaults with Initial Liquidity ---");
        console.log("Liquidity per vault:", VAULT_LIQUIDITY / 10**18, "tokens");

        // Transfer tokens to Pool (Pool must hold tokens before bootstrapping)
        xsgd.transfer(address(pool), VAULT_LIQUIDITY);
        thbt.transfer(address(pool), VAULT_LIQUIDITY);
        idrt.transfer(address(pool), VAULT_LIQUIDITY);
        usdt.transfer(address(pool), VAULT_LIQUIDITY);

        // Prepare amounts array for bootstrap (order must match tokens array)
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = VAULT_LIQUIDITY; // XSGD
        amounts[1] = VAULT_LIQUIDITY; // THBT
        amounts[2] = VAULT_LIQUIDITY; // IDRT
        amounts[3] = VAULT_LIQUIDITY; // USDT

        // Bootstrap Pool - deposits tokens into all vaults
        pool.bootstrapPool(amounts);

        console.log("All vaults funded:");
        console.log("  XSGD Pool deposit:", xsgdVault.userDeposits(address(pool)) / 10**18);
        console.log("  THBT Pool deposit:", thbtVault.userDeposits(address(pool)) / 10**18);
        console.log("  IDRT Pool deposit:", idrtVault.userDeposits(address(pool)) / 10**18);
        console.log("  USDT Pool deposit:", usdtVault.userDeposits(address(pool)) / 10**18);

        // ===========================================
        // 6. Set Initial Prices
        // ===========================================
        console.log("\n--- Setting Initial Prices ---");

        uint64 currentTimestamp = uint64(block.timestamp);

        // XSGD price (~0.74 USD)
        PythStructs.Price memory xsgdPrice = PythStructs.Price({
            price: 126141,   // ~0.74141 * 10^5
            conf: 21,
            expo: -5,
            publishTime: currentTimestamp
        });

        // THBT price (~0.028 USD)
        PythStructs.Price memory thbtPrice = PythStructs.Price({
            price: 2800000,  // 0.028 * 10^8
            conf: 5000,
            expo: -8,
            publishTime: currentTimestamp
        });

        // IDRT price (~0.000064 USD)
        PythStructs.Price memory idrtPrice = PythStructs.Price({
            price: 6400,     // 0.000064 * 10^8
            conf: 50,
            expo: -8,
            publishTime: currentTimestamp
        });

        // USDT price (~0.998 USD)
        PythStructs.Price memory usdtPrice = PythStructs.Price({
            price: 99868428, // 0.99868428 * 10^8
            conf: 108232,
            expo: -8,
            publishTime: currentTimestamp
        });

        bytes32[] memory priceFeedIds = new bytes32[](4);
        priceFeedIds[0] = XSGD_FEED_ID;
        priceFeedIds[1] = THBT_FEED_ID;
        priceFeedIds[2] = IDRT_FEED_ID;
        priceFeedIds[3] = USDT_FEED_ID;

        PythStructs.Price[] memory priceData = new PythStructs.Price[](4);
        priceData[0] = xsgdPrice;
        priceData[1] = thbtPrice;
        priceData[2] = idrtPrice;
        priceData[3] = usdtPrice;

        pool.updatePrices(priceFeedIds, priceData);
        console.log("All prices updated");

        vm.stopBroadcast();

        // ===========================================
        // 7. Summary & Testing Instructions
        // ===========================================
        console.log("\n=== Deployment Complete ===");
        console.log("\nDeployed Contracts:");
        console.log("  XSGD:        ", address(xsgd));
        console.log("  THBT:        ", address(thbt));
        console.log("  IDRT:        ", address(idrt));
        console.log("  USDT:        ", address(usdt));
        console.log("\n  XSGD Vault:  ", address(xsgdVault));
        console.log("  THBT Vault:  ", address(thbtVault));
        console.log("  IDRT Vault:  ", address(idrtVault));
        console.log("  USDT Vault:  ", address(usdtVault));
        console.log("\n  Pool:        ", address(pool));

        console.log("\nDeployer Balances (Ready for Testing):");
        console.log("  Address:     ", deployer);
        console.log("  XSGD:        ", xsgd.balanceOf(deployer) / 10**18);
        console.log("  THBT:        ", thbt.balanceOf(deployer) / 10**18);
        console.log("  IDRT:        ", idrt.balanceOf(deployer) / 10**18);
        console.log("  USDT:        ", usdt.balanceOf(deployer) / 10**18);

        console.log("\nTest Environment Ready:");
        console.log("  [OK] All vaults funded with initial liquidity");
        console.log("  [OK] Bidirectional swaps enabled (XSGD <-> USDT, etc.)");
        console.log("  [OK] Initial prices set");
        console.log("  [OK] Deployer has remaining tokens for testing");

        console.log("\n--- Ready for Live Testing! ---");
        console.log("\nNext Steps:");
        console.log("  1. Use deployer wallet to connect to DApp/Etherscan");
        console.log("  2. Approve Pool to spend tokens");
        console.log("  3. Execute swaps to test functionality");
        console.log("\nOr run:");
        console.log("  forge script script/LiveSwapTest.s.sol --rpc-url $RPC_URL --broadcast");
    }
}
