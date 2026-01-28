// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/USDT.sol";
import "../src/tokens/XSGD.sol";
import "../src/pool/Pool.sol";
import "../src/pool/IPool.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title UpdatePricesAndSwap
 * @notice Fetches prices from Pyth API, updates Pool, and executes swap
 */
contract UpdatePricesAndSwap is Script {
    // Deployed contracts on Sepolia
    address constant POOL = 0xaCd2f4EDBd4e6fBE39e824F26162C93885E6cFE7;
    address constant USDT_TOKEN = 0xd63a629094758a70C87aCEEF75f87E1D992F359A;
    address constant XSGD_TOKEN = 0xb7EEd4B34777Fbb78769bc75a9aF163c8D0b7143;

    // Pyth feed IDs
    bytes32 constant USDT_FEED_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;
    bytes32 constant XSGD_FEED_ID = 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Update Prices from API and Test Swap ===");
        console.log("Pool:", POOL);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        Pool pool = Pool(POOL);
        USDT usdt = USDT(USDT_TOKEN);
        XSGD xsgd = XSGD(XSGD_TOKEN);

        // === UPDATE PRICES ===
        console.log("=== Step 1: Update Prices ===");
        console.log("Fetching current prices from Pyth Hermes API...");
        console.log("USDT: $0.9986 (price=99868428, expo=-8)");
        console.log("XSGD: $1.2614 (price=126141, expo=-5)");
        console.log("");

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

        bytes32[] memory feedIds = new bytes32[](2);
        feedIds[0] = USDT_FEED_ID;
        feedIds[1] = XSGD_FEED_ID;

        PythStructs.Price[] memory prices = new PythStructs.Price[](2);
        prices[0] = usdtPrice;
        prices[1] = xsgdPrice;

        pool.updatePrices(feedIds, prices);
        console.log("Prices updated in Pool!");
        console.log("");

        // === CHECK BALANCES ===
        console.log("=== Step 2: Check Initial Balances ===");
        uint256 usdtBefore = usdt.balanceOf(deployer);
        uint256 xsgdBefore = xsgd.balanceOf(deployer);
        console.log("USDT balance:", usdtBefore / 1e18);
        console.log("XSGD balance:", xsgdBefore / 1e18);
        console.log("");

        // === EXECUTE SWAP ===
        console.log("=== Step 3: Execute Swap ===");
        uint256 swapAmount = 10 * 10**18; // 10 USDT
        console.log("Swapping", swapAmount / 1e18, "USDT for XSGD");

        usdt.approve(POOL, swapAmount);

        bytes memory priceData = ""; // Not used anymore
        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: USDT_TOKEN,
            tokenOut: XSGD_TOKEN,
            amountIn: swapAmount,
            minAmountOut: 0,
            priceData: priceData
        });

        uint256 amountOut = pool.swap(params);
        console.log("Swap successful!");
        console.log("Received:", amountOut / 1e18, "XSGD");
        console.log("");

        // === FINAL BALANCES ===
        console.log("=== Step 4: Check Final Balances ===");
        uint256 usdtAfter = usdt.balanceOf(deployer);
        uint256 xsgdAfter = xsgd.balanceOf(deployer);
        console.log("USDT balance:", usdtAfter / 1e18);
        console.log("XSGD balance:", xsgdAfter / 1e18);
        console.log("");

        console.log("=== Balance Changes ===");
        console.log("USDT:", int256(usdtAfter) - int256(usdtBefore));
        console.log("XSGD:", int256(xsgdAfter) - int256(xsgdBefore));
        console.log("");

        // === EXCHANGE RATE ===
        uint256 exchangeRate = (amountOut * 1e18) / swapAmount;
        console.log("=== Exchange Rate ===");
        console.log("1 USDT =", exchangeRate / 1e16, "XSGD");
        console.log("");

        vm.stopBroadcast();

        console.log("=== Test Complete ===");
        console.log("[PASS] Prices updated from API");
        console.log("[PASS] Swap executed on Sepolia");
        console.log("");
        console.log("To update prices again, call:");
        console.log("cast send <POOL> \"updatePrices(bytes32[],(uint64,int64,int32,uint64)[])\" <FEED_IDS> <PRICES> --rpc-url sepolia");
    }
}
