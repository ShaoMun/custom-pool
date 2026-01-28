// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVault {
    /**
     * @notice Struct to track balance information per chain
     * @param chainId EIP-155 chain ID
     * @param balance Total vault balance on this chain
     * @param lastUpdate Timestamp of last update
     */
    struct ChainBalance {
        uint64 chainId;
        uint256 balance;
        uint256 lastUpdate;
    }

    /**
     * @notice Emitted when tokens are deposited
     * @param user Address of the user depositing tokens
     * @param amount Amount of tokens deposited
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @notice Emitted when tokens are withdrawn
     * @param user Address of the user withdrawing tokens
     * @param amount Amount of tokens withdrawn
     */
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Emitted when tokens are locked for cross-chain transfer
     * @param user Address of the user locking tokens
     * @param targetChain Chain ID of the target chain
     * @param amount Amount of tokens locked
     */
    event CrossChainLock(address indexed user, uint64 targetChain, uint256 amount);

    /**
     * @notice Emitted when tokens are minted from cross-chain transfer
     * @param user Address of the user receiving tokens
     * @param sourceChain Chain ID of the source chain
     * @param amount Amount of tokens minted
     */
    event CrossChainMint(address indexed user, uint64 sourceChain, uint256 amount);

    /**
     * @notice Emitted when chain balance is updated
     * @param chainId Chain ID that was updated
     * @param newBalance New balance for the chain
     */
    event BalanceUpdated(uint64 indexed chainId, uint256 newBalance);

    /**
     * @notice Deposits tokens into the vault
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Withdraws tokens from the vault
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Returns the current token balance of the vault
     * @return Current token balance
     */
    function getBalance() external view returns (uint256);

    /**
     * @notice Returns the total liquidity tracked by the vault
     * @return Total liquidity amount
     */
    function getTotalLiquidity() external view returns (uint256);

    /**
     * @notice Returns the balance for a specific chain
     * @param chainId Chain ID to query
     * @return Balance on the specified chain
     */
    function getChainBalance(uint64 chainId) external view returns (uint256);

    /**
     * @notice Returns the deposit amount for a user
     * @param user Address to query
     * @return User's deposit amount
     */
    function userDeposits(address user) external view returns (uint256);

    /**
     * @notice Updates the balance for a specific chain
     * @param chainId Chain ID to update
     * @param balance New balance for the chain
     */
    function updateChainBalance(uint64 chainId, uint256 balance) external;

    /**
     * @notice Locks tokens for cross-chain transfer
     * @param targetChain Chain ID of the target chain
     * @param amount Amount of tokens to lock
     */
    function lockForCrossChain(uint64 targetChain, uint256 amount) external;

    /**
     * @notice Mints tokens from cross-chain transfer
     * @param user Address of the user receiving tokens
     * @param amount Amount of tokens to mint
     */
    function mintFromCrossChain(address user, uint256 amount) external;

    /**
     * @notice Directly transfer tokens to a recipient (for Pool swaps)
     * @param recipient Address to receive tokens
     * @param amount Amount of tokens to transfer
     * @dev Deducts from caller's userDeposits and totalLiquidity
     */
    function directTransfer(address recipient, uint256 amount) external;
}
