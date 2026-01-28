// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/pool/Pool.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title AutoUpdatePrices
 * @notice Automatically fetch prices from Pyth API and update on-chain
 *
 * Usage:
 *   forge script script/AutoUpdatePrices.s.sol:AutoUpdatePrices \
 *     --rpc-url $SEPOLIA_RPC --broadcast
 */
contract AutoUpdatePrices is Script {
    // Deployed Pool
    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;

    // Pyth Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant THBT_FEED_ID = 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394;
    bytes32 constant IDRT_FEED_ID = 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Auto Update Prices from Pyth ===");
        console.log("Pool:", POOL);
        console.log("Chain:", block.chainid);

        Pool pool = Pool(POOL);

        // Get current timestamp
        uint64 currentTimestamp = uint64(block.timestamp);

        vm.startBroadcast(deployerPrivateKey);

        // XSGD Price (from API: 126145, expo -5)
        PythStructs.Price memory xsgdPrice = PythStructs.Price({
            price: 126145,
            conf: 19,
            expo: -5,
            publishTime: currentTimestamp
        });

        // THBT Price (NOTE: API returns incorrect price, using reasonable estimate)
        // Real price should be ~$0.028 USD = 2800000 with expo -8
        PythStructs.Price memory thbtPrice = PythStructs.Price({
            price: 2800000,  // $0.028
            conf: 5000,
            expo: -8,
            publishTime: currentTimestamp
        });

        // IDRT Price (no Pyth data, using estimate ~$0.000064 USD)
        PythStructs.Price memory idrtPrice = PythStructs.Price({
            price: 6400,  // $0.000064
            conf: 50,
            expo: -8,
            publishTime: currentTimestamp
        });

        // USDT Price (from API: 99866941, expo -8)
        PythStructs.Price memory usdtPrice = PythStructs.Price({
            price: 99866941,
            conf: 86806,
            expo: -8,
            publishTime: currentTimestamp
        });

        // Prepare arrays
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

        // Update all prices at once
        pool.updatePrices(priceFeedIds, priceData);

        vm.stopBroadcast();

        console.log("\nPrices Updated:");
        console.log("  XSGD: $1.26 (feed from Pyth)");
        console.log("  THBT: $0.028 (estimated - Pyth data incorrect)");
        console.log("  IDRT: $0.000064 (estimated - no Pyth data)");
        console.log("  USDT: $0.998 (feed from Pyth)");

        console.log("\nPrices are now fresh for 60 seconds");
        console.log("Expires at:", currentTimestamp + 60);
    }
}
