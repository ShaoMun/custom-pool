// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Stablecoin.sol";

/**
 * @title USDT
 * @notice Tether USD stablecoin
 * @dev All tokens have 18 decimals and 1,000,000 initial supply
 */
contract USDT is Stablecoin {
    constructor(address initialOwner, uint256 initialSupply)
        Stablecoin("Tether USD", "USDT", 18, initialOwner, initialSupply)
    {}
}
