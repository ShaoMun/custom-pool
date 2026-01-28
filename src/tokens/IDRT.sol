// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Stablecoin.sol";

/**
 * @title IDRT
 * @notice Indonesian Rupiah stablecoin
 * @dev All tokens have 18 decimals and 1,000,000 initial supply
 */
contract IDRT is Stablecoin {
    constructor(address initialOwner, uint256 initialSupply)
        Stablecoin("Indonesian Rupiah", "IDRT", 18, initialOwner, initialSupply)
    {}
}
