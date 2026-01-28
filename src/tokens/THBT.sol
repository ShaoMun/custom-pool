// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Stablecoin.sol";

/**
 * @title THBT
 * @notice Thai Baht stablecoin
 * @dev All tokens have 18 decimals and 1,000,000 initial supply
 */
contract THBT is Stablecoin {
    constructor(address initialOwner, uint256 initialSupply)
        Stablecoin("Thai Baht", "THBT", 18, initialOwner, initialSupply)
    {}
}
