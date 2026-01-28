// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/USDT.sol";
import "../src/tokens/XSGD.sol";
import "../src/pool/Pool.sol";
import "../src/pool/IPool.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title LiveSwapTest
 * @notice Live swap test on Sepolia with real Pyth prices
 */
contract LiveSwapTest is Script {
    // Deployed contract addresses on Sepolia
    address constant POOL = 0xB06f01e02f28F7A1C420Fb86ccf288a6D10128D7;
    address constant USDT_TOKEN = 0xC8Ce742092fe21e88c38E64131eEE8dCEe46145a;
    address constant XSGD_TOKEN = 0x6999e949EE5C025E1d511bDF5D04a79c460DF2D8;

    // Real Pyth price update data fetched from Hermes API
    // This contains price updates for both USDT and XSGD
    bytes constant PRICE_DATA = hex"504e41550100000003b801000000040d025390d0d61396ab7a993fda6f34e73528315ac9191cfe2073f3429396480f0a227bb3d1bef4012d7f9f7de107e6d8a0eb3bdce5f024ee8a8ebd1234c93a0c7b570003400db9fd4e169931307b875c45090ed12fa4b4bf8aba880ee37a450bda169c051241b8e845841f730df8c506bbcec15e94a5255a5a159a68f5a43ad56e9732290004644241f2d6c128fa012dde7a8f063e951d489169690d329df7ecd0988a052cdd0fafa3f781dfa483ae0b1d3d897acf5d7f3edc07d67fc3f4fef83fd7cbc0ebc70106d57c710f9abe405af700d4137dedeeeba59119213e690796cb2b61340d60852024989a800abd2b718137ce529691aaf763a6652c9c0ee515c143d810e76e889a01081d41d32a49f304307a682001a9ba876c5bbd713b4fb5e8aa6516a7c0767363012886faadcf0eae8a7a42a2bdc000fc65e80e41b6f06910ae50f283cb77847f67010a091ba651e8c9a420c53c15e49a226c3abf6c01895fe87cc747e0e56880a0954f7fe6289a4483cad9a8633f874ba2fd055271d8f3eb0abbf30d2ef57ed8858c56010b92f2ef0d0a1894b136bc5f8de4b5b687e6138a2346a0395317a98898d234054d3c43bd0a8f45ef0088c6c6ab262d241ffefdc3206b3b37e02551d5849690ea1d000ccfbfc52d7f5a0b86a8702a991d3056ca25e3336460178b49c9cc928d9db5711234f5797c1041881c6e8acb1572e72bad63d7510b0addb97811b34ecf122a9835000d12102dece49171a544ea6bb28b3596e04ee441eb6d616b0eea40d4e5924b45346bee41f7fd51bcc05e0ff55b43868a2396cc83d7147f3d3d72410d15373d077b000eac9ade9a410d7b67f1056cf33b323d47bd0e3eafed71e7b921368cc1beeb9b164670fb7595f8811086100566b4f030da8780cc50331763097153139c47058dfd000f204d5f565ecd1dc1d4bc5d4ac06b854eb0e7efdd7f877c9fd4aea5c2e1b72d7c5b8ba39d319eeea3f6c1843d2f109eaeb093c51828af41686a2e220d8c35fbe300103f680954d1531cc83a6c9dfa07718e1336a60f2a65807739f410ede5b6406d92118665bbe2931045e38d72d5311b3d8a1e2ff67b961ab2b0a32287e2f76e0f84011126fb7f985b746271dad9f7e2dd2427e26b2c97a0f6d62fecc5a623ef75ffc7b9361ce16432844f385da4e6e6485f98f6db033b1c35131b7be10840837da5074d016979526000000000001ae101faedac5851e32b9b23b5f9411a8c2bac4aae3ed4dd7b811dd1a72ea4aa71000000000b05758d0141555756000000000010131e1f00002710eecf21ed3bfd3b9a57388351a572b8ecaf090570020055002b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b0000000005f3cc4d0000000000015e29fffffff80000000069795260000000006979525f0000000005f3fad800000000000134960d997ee3becd001c772ba36451b3b228c7266e01b2f1fb63d157b96bd064223b4343f791bcfcd7c622519de326f8f69e1561f5098683ad5d0ddf1d5eb0956d519c8a2b4df2bdfe0526bd8f48cbb9fa5081395a8949160bd5aedff6395a1f88361b953761337d30458c5c4a9f3f834b0830afa56c6c3e1e1a4fbf46314111cfcf4c7ed48c383e80e077d70ae74c9fcda31c7b32a27c0610adc4af3f8e7fbf842501706f341ef988289ebce733f047ee0aaf8c116e7263e20eb2ec41b9850873e593f0c60a76961c0a165f4843b663030a55763a90666ce3f89babbd4f8e08f1fefb54ef45bfa19dbad361deed90d7a7ae824420c992206542ec9e82b33f69ef1be593b7ab4e005500396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918000000000001ecb60000000000000014fffffffb0000000069795260000000006979525f000000000001ec75000000000000001c0dee8e776e4c08bdfbe4ae606eae91e4c3a535e0cb68e0221e8887e403a378000cc599f00cc170140ef70af4233f58a0306011c1a9b055358fc2625701aec34a02fa4dec45379cd2909315f48c0c3728b8e1e1e9fe9c1d4e58d5a9cc3305c1279dc32e34125b2de1825cdc294f4c1d8bbd90e08cb9b96cfc9b3ea592c8ea176531ea85f13b17de4b28f375ab75782e09d2b5147bd6bbbad1d0ffb4fa25fc273c09706f341ef988289ebce733f047ee0aaf8c116e7263e20eb2ec41b9850873e593f0c60a76961c0a165f4843b663030a55763a90666ce3f89babbd4f8e08f1fefb54ef45bfa19dbad361deed90d7a7ae824420c992206542ec9e82b33f69ef1be593b7ab4e00";

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Live Swap Test on Sepolia ===");
        console.log("Tester address:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Get contract instances
        Pool pool = Pool(POOL);
        USDT usdt = USDT(USDT_TOKEN);
        XSGD xsgd = XSGD(XSGD_TOKEN);

        // Check initial balances
        uint256 usdtBefore = usdt.balanceOf(deployer);
        uint256 xsgdBefore = xsgd.balanceOf(deployer);

        console.log("=== Initial Balances ===");
        console.log("USDT balance:", usdtBefore / 1e18);
        console.log("XSGD balance:", xsgdBefore / 1e18);
        console.log("");

        // Swap amount: 10 USDT
        uint256 swapAmount = 10 * 10**18;

        console.log("=== Executing Swap ===");
        console.log("Swapping", swapAmount / 1e18, "USDT for XSGD");

        // Approve pool to spend USDT
        usdt.approve(POOL, swapAmount);
        console.log("Approved pool to spend USDT");

        // Execute swap with real Pyth price data
        IPool.SwapParams memory params = IPool.SwapParams({
            tokenIn: USDT_TOKEN,
            tokenOut: XSGD_TOKEN,
            amountIn: swapAmount,
            minAmountOut: 0, // No slippage protection for test
            priceData: PRICE_DATA
        });

        uint256 amountOut = pool.swap(params);
        console.log("Swap successful!");
        console.log("Received:", amountOut / 1e18, "XSGD");
        console.log("");

        // Check final balances
        uint256 usdtAfter = usdt.balanceOf(deployer);
        uint256 xsgdAfter = xsgd.balanceOf(deployer);

        console.log("=== Final Balances ===");
        console.log("USDT balance:", usdtAfter / 1e18);
        console.log("XSGD balance:", xsgdAfter / 1e18);
        console.log("");

        console.log("=== Balance Changes ===");
        console.log("USDT change:", int256(usdtAfter) - int256(usdtBefore));
        console.log("XSGD change:", int256(xsgdAfter) - int256(xsgdBefore));
        console.log("");

        // Calculate exchange rate
        uint256 exchangeRate = (amountOut * 1e18) / swapAmount;
        console.log("=== Exchange Rate ===");
        console.log("1 USDT =", exchangeRate / 1e16, "XSGD");
        console.log("");

        vm.stopBroadcast();

        console.log("=== Test Complete ===");
        console.log("[PASS] Live swap successful on Sepolia!");
    }
}
