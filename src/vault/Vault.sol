// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IVault.sol";

/**
 * @title Vault
 * @notice Per-token vault that manages unified liquidity across chains
 * @dev Tracks deposits, withdrawals, and cross-chain operations
 */
contract Vault is IVault {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The token this vault manages
    IERC20 public immutable token;

    /// @notice The chain ID where this vault is deployed
    uint64 public immutable chainId;

    /// @notice Track balances across all chains
    mapping(uint64 => ChainBalance) public chainBalances;

    /// @notice Track user deposits
    mapping(address => uint256) public userDeposits;

    /// @notice Total liquidity tracked by this vault
    uint256 public totalLiquidity;

    /// @notice Cross-chain messenger address (for LayerZero integration)
    address public crossChainMessenger;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Only authorized messenger can call cross-chain functions
    modifier onlyMessenger() {
        require(msg.sender == crossChainMessenger, "Vault: only messenger");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new vault
     * @param _token The token this vault manages
     * @param _chainId The chain ID where this vault is deployed
     */
    constructor(
        IERC20 _token,
        uint64 _chainId
    ) {
        token = _token;
        chainId = _chainId;

        // Initialize this chain's balance
        chainBalances[_chainId] = ChainBalance({
            chainId: _chainId,
            balance: 0,
            lastUpdate: block.timestamp
        });
    }

    /*//////////////////////////////////////////////////////////////
                          CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits tokens into the vault
     * @param amount Amount of tokens to deposit
     * @dev Tokens must be approved first
     */
    function deposit(uint256 amount) external override {
        token.safeTransferFrom(msg.sender, address(this), amount);

        userDeposits[msg.sender] += amount;
        totalLiquidity += amount;
        chainBalances[chainId].balance += amount;
        chainBalances[chainId].lastUpdate = block.timestamp;

        emit Deposit(msg.sender, amount);
        emit BalanceUpdated(chainId, chainBalances[chainId].balance);
    }

    /**
     * @notice Withdraws tokens from the vault
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external override {
        require(userDeposits[msg.sender] >= amount, "Vault: insufficient deposit");

        userDeposits[msg.sender] -= amount;
        totalLiquidity -= amount;
        chainBalances[chainId].balance -= amount;
        chainBalances[chainId].lastUpdate = block.timestamp;

        token.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
        emit BalanceUpdated(chainId, chainBalances[chainId].balance);
    }

    /**
     * @notice Lock tokens for cross-chain transfer (future LayerZero integration)
     * @param targetChain Chain ID of the target chain
     * @param amount Amount of tokens to lock
     */
    function lockForCrossChain(uint64 targetChain, uint256 amount) external override {
        require(userDeposits[msg.sender] >= amount, "Vault: insufficient deposit");

        userDeposits[msg.sender] -= amount;
        totalLiquidity -= amount;
        chainBalances[chainId].balance -= amount;
        chainBalances[chainId].lastUpdate = block.timestamp;

        // TODO: Send message via LayerZero
        // crossChainMessenger.sendLockMessage(targetChain, msg.sender, amount);

        emit CrossChainLock(msg.sender, targetChain, amount);
        emit BalanceUpdated(chainId, chainBalances[chainId].balance);
    }

    /**
     * @notice Mints tokens received from cross-chain transfer
     * @param user Address of the user receiving tokens
     * @param amount Amount of tokens to mint
     * @dev Only callable by authorized messenger
     */
    function mintFromCrossChain(address user, uint256 amount) external override onlyMessenger {
        userDeposits[user] += amount;
        totalLiquidity += amount;
        chainBalances[chainId].balance += amount;
        chainBalances[chainId].lastUpdate = block.timestamp;

        emit CrossChainMint(user, chainId, amount);
        emit BalanceUpdated(chainId, chainBalances[chainId].balance);
    }

    /**
     * @notice Directly transfer tokens to a recipient (for Pool swaps)
     * @param recipient Address to receive tokens
     * @param amount Amount of tokens to transfer
     * @dev Deducts from caller's userDeposits and totalLiquidity
     */
    function directTransfer(address recipient, uint256 amount) external override {
        require(userDeposits[msg.sender] >= amount, "Vault: insufficient deposit");

        userDeposits[msg.sender] -= amount;
        totalLiquidity -= amount;
        chainBalances[chainId].balance -= amount;
        chainBalances[chainId].lastUpdate = block.timestamp;

        token.safeTransfer(recipient, amount);

        emit Withdraw(msg.sender, amount);
        emit BalanceUpdated(chainId, chainBalances[chainId].balance);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates balance info from other chains
     * @param chainId_ Chain ID to update
     * @param balance New balance for the chain
     * @dev Used for off-chain aggregation of cross-chain balances
     */
    function updateChainBalance(uint64 chainId_, uint256 balance) external override {
        chainBalances[chainId_] = ChainBalance({
            chainId: chainId_,
            balance: balance,
            lastUpdate: block.timestamp
        });

        emit BalanceUpdated(chainId_, balance);
    }

    /**
     * @notice Sets the cross-chain messenger address
     * @param _messenger Address of the messenger contract
     */
    function setCrossChainMessenger(address _messenger) external {
        crossChainMessenger = _messenger;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current token balance of the vault
     * @return Current token balance
     */
    function getBalance() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Returns the total liquidity tracked by the vault
     * @return Total liquidity amount
     */
    function getTotalLiquidity() external view override returns (uint256) {
        return totalLiquidity;
    }

    /**
     * @notice Returns the balance for a specific chain
     * @param chainId_ Chain ID to query
     * @return Balance on the specified chain
     */
    function getChainBalance(uint64 chainId_) external view override returns (uint256) {
        return chainBalances[chainId_].balance;
    }
}
