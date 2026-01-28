// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IPool.sol";
import "../vault/IVault.sol";

/**
 * @title Pool
 * @notice Swap pool for exchanging tokens using off-chain price feeds
 * @dev Supports swaps between any two tokens with slippage protection and fees
 * @dev Prices are updated by admin based on API calls (Pyth Hermes)
 */
contract Pool is IPool, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Token address -> Vault address mapping
    mapping(address => IVault) public vaults;

    /// @notice List of supported tokens
    address[] public tokens;

    /// @notice Token address -> Price feed ID
    mapping(address => bytes32) public priceFeedIds;

    /// @notice Price feed ID -> Price data (updated by admin from API)
    mapping(bytes32 => PythStructs.Price) public prices;

    /// @notice Maximum price age (60 seconds)
    uint256 public constant MAX_PRICE_AGE = 60 seconds;

    /// @notice Fee basis points (30 = 0.3%)
    uint256 public feeBps = 30;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new swap pool
     * @param _tokens List of supported token addresses
     * @param _priceFeedIds List of price feed IDs for each token
     * @param _owner Pool owner address
     */
    constructor(
        address[] memory _tokens,
        bytes32[] memory _priceFeedIds,
        address _owner
    ) Ownable(_owner) {
        require(_tokens.length == _priceFeedIds.length, "Pool: length mismatch");

        tokens = _tokens;

        for (uint256 i = 0; i < _tokens.length; i++) {
            priceFeedIds[_tokens[i]] = _priceFeedIds[i];
        }
    }

    /*//////////////////////////////////////////////////////////////
                          SWAP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Swaps tokens using off-chain price feeds
     * @param params Swap parameters (priceData is ignored, prices stored on-chain)
     * @return amountOut Amount of output tokens received
     * @dev Token approvals must be set before calling
     */
    function swap(SwapParams calldata params) external override returns (uint256 amountOut) {
        // Validate inputs
        require(params.amountIn > 0, "Pool: invalid amount");
        require(params.tokenIn != params.tokenOut, "Pool: same token");
        require(vaults[params.tokenIn] != IVault(address(0)), "Pool: vault not set for input");
        require(vaults[params.tokenOut] != IVault(address(0)), "Pool: vault not set for output");

        // Get prices from storage
        (uint256 priceIn, uint256 priceOut) = _getPrices(params.tokenIn, params.tokenOut);

        // Calculate expected output using safe arithmetic
        uint256 amountInScaled = params.amountIn / 1e10; // Scale down from 18 to 8 decimals
        uint256 expectedAmountOut = (amountInScaled * priceIn) / priceOut;
        expectedAmountOut = expectedAmountOut * 1e10; // Scale back to 18 decimals

        // Apply fee
        uint256 fee = (expectedAmountOut * feeBps) / 10000;
        amountOut = expectedAmountOut - fee;

        // Check slippage
        require(amountOut >= params.minAmountOut, "Pool: slippage exceeded");

        // Transfer input tokens from user to pool
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);

        // Approve vault to spend tokens
        IERC20(params.tokenIn).approve(address(vaults[params.tokenIn]), params.amountIn);

        // Deposit input tokens to vault (increases Pool's balance in input vault)
        vaults[params.tokenIn].deposit(params.amountIn);

        // Transfer output tokens directly from output vault to user
        // This uses Pool's deposited balance in the output vault
        vaults[params.tokenOut].directTransfer(msg.sender, amountOut);

        emit Swapped(msg.sender, params.tokenIn, params.tokenOut, params.amountIn, amountOut);
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets prices for two tokens from stored price data
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @return priceIn Price of input token
     * @return priceOut Price of output token
     */
    function _getPrices(
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 priceIn, uint256 priceOut) {
        // Get price feed IDs
        bytes32 feedIdIn = priceFeedIds[tokenIn];
        require(feedIdIn != bytes32(0), "Pool: price feed not found for input");

        bytes32 feedIdOut = priceFeedIds[tokenOut];
        require(feedIdOut != bytes32(0), "Pool: price feed not found for output");

        // Get prices from storage
        PythStructs.Price memory priceInStruct = prices[feedIdIn];
        _validatePrice(priceInStruct);

        PythStructs.Price memory priceOutStruct = prices[feedIdOut];
        _validatePrice(priceOutStruct);

        // Convert int64 price to uint256 safely
        require(priceInStruct.price > 0, "Pool: invalid price in");
        require(priceOutStruct.price > 0, "Pool: invalid price out");
        priceIn = uint256(uint64(priceInStruct.price));
        priceOut = uint256(uint64(priceOutStruct.price));
    }

    /**
     * @notice Validates a Pyth price
     * @param price Pyth price struct to validate
     */
    function _validatePrice(PythStructs.Price memory price) internal view {
        require(price.price > 0, "Pool: invalid price");
        // Check price freshness without underflow - add instead of subtract
        require(price.publishTime + MAX_PRICE_AGE >= block.timestamp, "Pool: stale price");
    }

    /**
     * @notice Gets the expected output amount for a swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @return expectedAmount Expected amount of output tokens
     * @dev This view function requires prices to be set first
     */
    function getExpectedAmount(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view override returns (uint256 expectedAmount) {
        revert("Pool: use swap with current prices");
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the vault for a token
     * @param token Token address
     * @param vault Vault address
     */
    function setVault(address token, IVault vault) external onlyOwner {
        vaults[token] = vault;
    }

    /**
     * @notice Sets the fee basis points
     * @param newFeeBps New fee in basis points (max 1000 = 10%)
     */
    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 1000, "Pool: fee too high");
        feeBps = newFeeBps;
    }

    /**
     * @notice Updates price data from API
     * @param _priceFeedIds List of price feed IDs
     * @param _priceData List of price data corresponding to feed IDs
     * @dev Called by admin after fetching prices from Pyth Hermes API
     */
    function updatePrices(
        bytes32[] calldata _priceFeedIds,
        PythStructs.Price[] calldata _priceData
    ) external onlyOwner {
        require(_priceFeedIds.length == _priceData.length, "Pool: length mismatch");

        for (uint256 i = 0; i < _priceFeedIds.length; i++) {
            prices[_priceFeedIds[i]] = _priceData[i];
        }
    }

    /**
     * @notice Bootstraps the Pool with initial liquidity in all vaults
     * @param amounts Array of token amounts to deposit (must match tokens array order)
     * @dev Pool must hold the tokens before calling this function
     */
    function bootstrapPool(uint256[] calldata amounts) external onlyOwner {
        require(amounts.length == tokens.length, "Pool: length mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            IVault vault = vaults[token];
            uint256 amount = amounts[i];

            require(vault != IVault(address(0)), "Pool: vault not set");
            require(amount > 0, "Pool: invalid amount");

            // Approve vault
            IERC20(token).approve(address(vault), amount);

            // Deposit to vault
            vault.deposit(amount);
        }
    }
}
