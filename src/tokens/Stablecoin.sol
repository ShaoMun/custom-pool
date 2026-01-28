// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Stablecoin
 * @notice Base ERC20 stablecoin with mint and burn capabilities
 * @dev Inherits from OpenZeppelin's ERC20 and Ownable
 */
contract Stablecoin is ERC20, Ownable {
    uint8 private _decimals;

    /**
     * @notice Constructor to initialize the stablecoin
     * @param name Token name (e.g., "Singapore Dollar")
     * @param symbol Token symbol (e.g., "XSGD")
     * @param decimalsValue Number of decimals (typically 18)
     * @param initialOwner Address that will own the contract
     * @param initialSupply Initial supply to mint to deployer
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimalsValue,
        address initialOwner,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(initialOwner) {
        _decimals = decimalsValue;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Returns the number of decimals the token uses
     * @return The number of decimals
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Mints tokens to a specified address (only owner)
     * @dev Used for cross-chain mint operations
     * @param to Address to receive minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the caller's balance
     * @dev Used for cross-chain burn operations
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
