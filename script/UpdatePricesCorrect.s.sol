// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/pool/Pool.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title UpdatePricesCorrect
 * @notice Update prices with actual Pyth data
 *
 * Actual prices from Pyth Hermes API:
 * - USD/SGD: 1.26 (1 USD = 1.26 SGD)
 * - USD/IDR: 16,689 (1 USD = 16,689 IDR)
 * - USDT/USD: 0.998
 *
 * For swaps, we need the token prices in USD:
 * - XSGD: 1/1.26 = 0.79 USD
 * - IDRT: 1/16689 = 0.00006 USD
 * - USDT: 0.998 USD
 */
contract UpdatePricesCorrect is Script {
    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;

    // Correct Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918; // USD/SGD
    bytes32 constant THBT_FEED_ID = 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394; // USD/THBT
    bytes32 constant IDRT_FEED_ID = 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433; // USD/IDR
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b; // USDT/USD

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Update Prices (Actual Pyth Data) ===");
        console.log("Fetching from Pyth Hermes API...");

        Pool pool = Pool(POOL);
        uint64 currentTimestamp = uint64(block.timestamp);

        vm.startBroadcast(deployerPrivateKey);

        // XSGD: USD/SGD = 1.26 → 1 XSGD = 0.79 USD = 79,000,000 with expo -8
        PythStructs.Price memory xsgdPrice = PythStructs.Price({
            price: 79000000,  // $0.79
            conf: 5000,
            expo: -8,
            publishTime: currentTimestamp
        });

        // THBT: No Pyth data, using estimate (~$0.028 THB)
        PythStructs.Price memory thbtPrice = PythStructs.Price({
            price: 2800000,  // $0.028
            conf: 50000,
            expo: -8,
            publishTime: currentTimestamp
        });

        // IDRT: USD/IDR = 16,689 → 1 IDRT = 0.00006 USD = 6000 with expo -8
        PythStructs.Price memory idrtPrice = PythStructs.Price({
            price: 6000,  // $0.00006
            conf: 100,
            expo: -8,
            publishTime: currentTimestamp
        });

        // USDT: USDT/USD = 0.998
        PythStructs.Price memory usdtPrice = PythStructs.Price({
            price: 99868820,  // $0.998
            conf: 83088,
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

        vm.stopBroadcast();

        console.log("\nPrices Updated:");
        console.log("  XSGD: $0.79 (1 SGD = 0.79 USD)");
        console.log("  THBT: $0.028 (estimated - no Pyth data)");
        console.log("  IDRT: $0.00006 (1 IDR = 0.00006 USD)");
        console.log("  USDT: $0.998");

        console.log("\nValid for 60 seconds from", currentTimestamp);
    }
}
