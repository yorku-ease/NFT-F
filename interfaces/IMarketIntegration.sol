// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMarketIntegration
 * @dev Interface for interacting with a LiquidityPool contract, allowing for adding/removing liquidity and trading.
 */
interface IMarketIntegration {
    /**
     * @notice Adds liquidity to the pool in exchange for pool tokens.
     * @param tokenAAmount Amount of tokenA to add to the pool.
     * @param tokenBAmount Amount of tokenB to add to the pool.
     * Emits a {LiquidityAdded} event.
     */
    function addLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) external;

    /**
     * @notice Removes liquidity from the pool and returns the underlying tokens.
     * @param tokenAAmount Amount of tokenA to remove from the pool.
     * @param tokenBAmount Amount of tokenB to remove from the pool.
     * Emits a {LiquidityRemoved} event.
     */
    function removeLiquidity(uint256 amount) external;

    /**
     * @notice Executes a trade between tokenA and tokenB.
     * @param tokenIn Address of the token being traded in.
     * @param amountIn Amount of the input token being traded.
     * @param minAmountOut Minimum amount of the output token that must be received for the trade to proceed.
     * Emits a {TradeExecuted} event.
     */
    function trade(address tokenIn, uint256 amountIn, uint256 minAmountOut) external;

    /**
     * @notice Calculates the output amount for a given input amount using the constant product formula.
     * @param tokenIn Address of the input token.
     * @param amountIn Amount of the input token.
     * @return amountOut Calculated output token amount.
     */
    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256);

    // Events
    /**
     * @dev Emitted when liquidity is added to the pool.
     * @param provider Address of the liquidity provider.
     * @param tokenAAmount Amount of tokenA added.
     * @param tokenBAmount Amount of tokenB added.
     */
    event LiquidityAdded(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount);

    /**
     * @dev Emitted when liquidity is removed from the pool.
     * @param provider Address of the liquidity provider.
     * @param tokenAAmount Amount of tokenA removed.
     * @param tokenBAmount Amount of tokenB removed.
     */
    event LiquidityRemoved(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount);

    /**
     * @dev Emitted when a trade is executed in the pool.
     * @param trader Address of the trader.
     * @param tokenIn Address of the token traded in.
     * @param amountIn Amount of the input token traded.
     * @param amountOut Amount of the output token received.
     */
    event TradeExecuted(address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut);
}
