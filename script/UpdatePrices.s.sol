// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "../src/pool/Pool.sol";

/**
 * @title UpdatePrices
 * @notice Update prices in the Pool contract
 *
 * Usage:
 *   forge script script/UpdatePrices.s.sol:UpdatePrices \
 *     --rpc-url $SEPOLIA_RPC --broadcast
 */
contract UpdatePrices is Script {
    // Deployed Pool address
    address constant POOL = 0x30F166A8a0c108d32a6DeE5d856877A372A6b2fa;

    // Pyth Feed IDs
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== Update Prices ===");
        console.log("Deployer:", deployer);

        Pool pool = Pool(POOL);

        vm.startBroadcast(deployerPrivateKey);

        // Set fresh prices
        uint64 currentTimestamp = uint64(block.timestamp);

        // USDT price (~0.998 USD)
        PythStructs.Price memory usdtPrice = PythStructs.Price({
            price: 99868428,
            conf: 108232,
            expo: -8,
            publishTime: currentTimestamp
        });

        // XSGD price (~0.74 USD)
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

        vm.stopBroadcast();

        console.log("\nPrices updated successfully!");
        console.log("Prices are now fresh for the next 60 seconds");
    }
}
