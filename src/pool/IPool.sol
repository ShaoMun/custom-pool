// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPool {
    /**
     * @notice Struct for swap parameters
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @param minAmountOut Minimum amount of output tokens (slippage protection)
     * @param priceData Pyth price update data
     */
    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes priceData;
    }

    /**
     * @notice Emitted when a swap is executed
     * @param user Address of the user performing the swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @param amountOut Amount of output tokens
     */
    event Swapped(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @notice Swaps tokens using off-chain Pyth prices
     * @param params Swap parameters including price data
     * @return amountOut Amount of output tokens received
     */
    function swap(SwapParams calldata params) external returns (uint256 amountOut);

    /**
     * @notice Gets the expected output amount for a swap (requires on-chain prices)
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @return expectedAmount Expected amount of output tokens
     * @dev This will revert if on-chain prices are not available
     *      Use swap with priceData for off-chain prices
     */
    function getExpectedAmount(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 expectedAmount);

    /**
     * @notice Returns the current fee in basis points
     * @return Fee in basis points (30 = 0.3%)
     */
    function feeBps() external view returns (uint256);
}
