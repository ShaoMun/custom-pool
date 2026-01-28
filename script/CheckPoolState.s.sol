// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/USDT.sol";
import "../src/tokens/XSGD.sol";
import "../src/pool/Pool.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title CheckPoolState
 * @notice Check Pool's current state and deposits
 */
contract CheckPoolState is Script {
    // Deployed contracts on Sepolia
    address constant POOL = 0x1bCBD779C5c8e5362214F797Fe8EB995E3E9869e;
    address constant USDT_TOKEN = 0xd63a629094758a70C87aCEEF75f87E1D992F359A;
    address constant XSGD_TOKEN = 0xb7EEd4B34777Fbb78769bc75a9aF163c8D0b7143;
    address constant USDT_VAULT = 0x31e6B7e465ADd0920162662DD281DDdDd33cb1d0;
    address constant XSGD_VAULT = 0xBd4ef7477Ae8a25b8865559425DC49f9B5198922;

    function run() external {
        console.log("=== Pool State Check ===");

        // Check Pool's token balance
        uint256 poolUsdtBalance = USDT(USDT_TOKEN).balanceOf(POOL);
        uint256 poolXsgdBalance = XSGD(XSGD_TOKEN).balanceOf(POOL);

        console.log("Pool USDT balance:", poolUsdtBalance / 1e18);
        console.log("Pool XSGD balance:", poolXsgdBalance / 1e18);

        // Check vault token balances
        uint256 vaultUsdtBalance = USDT(USDT_TOKEN).balanceOf(USDT_VAULT);
        uint256 vaultXsgdBalance = XSGD(XSGD_TOKEN).balanceOf(XSGD_VAULT);

        console.log("USDT Vault token balance:", vaultUsdtBalance / 1e18);
        console.log("XSGD Vault token balance:", vaultXsgdBalance / 1e18);

        // The Pool needs deposits in vaults to swap
        console.log("");
        console.log("To fix: Pool needs to deposit tokens to each vault");
        console.log("Then Pool can withdraw from output vault during swaps");
    }
}
