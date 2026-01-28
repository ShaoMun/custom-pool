// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Stablecoin.sol";

/**
 * @title XSGD
 * @notice Singapore Dollar stablecoin
 * @dev All tokens have 18 decimals and 1,000,000 initial supply
 */
contract XSGD is Stablecoin {
    constructor(address initialOwner, uint256 initialSupply)
        Stablecoin("Singapore Dollar", "XSGD", 18, initialOwner, initialSupply)
    {}
}
