// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IMarketIntegration.sol";

/**
 * @title MarketIntegration
 * @dev Contract for managing liquidity and enabling trades between two ERC20 tokens.
 * It provides functions to add/remove liquidity to a token pair pool and to trade between the two tokens.
 */
contract MarketIntegration is IMarketIntegration, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses.");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant returns (uint256, uint256, uint256) {
        (uint256 adjustedAmountA, uint256 adjustedAmountB) = _getAdjustedAmounts(amountA, amountB);
        tokenA.safeTransferFrom(msg.sender, address(this), adjustedAmountA);
        tokenB.safeTransferFrom(msg.sender, address(this), adjustedAmountB);

        uint256 mintedLiquidity = _mintLiquidity(adjustedAmountA, adjustedAmountB);
        liquidity[msg.sender] = liquidity[msg.sender].add(mintedLiquidity);
        totalLiquidity = totalLiquidity.add(mintedLiquidity);

        emit LiquidityAdded(msg.sender, adjustedAmountA, adjustedAmountB, mintedLiquidity);
        return (adjustedAmountA, adjustedAmountB, mintedLiquidity);
    }

    function removeLiquidity(uint256 amount) external nonReentrant returns (uint256, uint256) {
        require(liquidity[msg.sender] >= amount, "Insufficient liquidity.");
        uint256 amountA = amount.mul(reserveA) / totalLiquidity;
        uint256 amountB = amount.mul(reserveB) / totalLiquidity;

        liquidity[msg.sender] = liquidity[msg.sender].sub(amount);
        totalLiquidity = totalLiquidity.sub(amount);
        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, amount);
        return (amountA, amountB);
    }

    function trade(address tokenIn, uint256 amountIn, uint256 minAmountOut) external nonReentrant returns (uint256) {
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token address");
        require(amountIn > 0, "Amount in must be greater than zero");

        IERC20 inputToken = IERC20(tokenIn);
        IERC20 outputToken = (tokenIn == address(tokenA) ? tokenB : tokenA);

        uint256 amountOut = getAmountOut(tokenIn, amountIn);
        require(amountOut >= minAmountOut, "Slippage exceeds limit");

        inputToken.safeTransferFrom(msg.sender, address(this), amountIn);
        outputToken.safeTransfer(msg.sender, amountOut);

        _updateReserves(tokenIn, amountIn, amountOut);

        emit TradeExecuted(msg.sender, tokenIn, amountIn, amountOut, minAmountOut);
        return amountOut;
    }

    // Helper functions to handle liquidity calculations
    function _getAdjustedAmounts(uint256 amountA, uint256 amountB) private view returns (uint256, uint256) {
        if (reserveA == 0 && reserveB == 0) {
            return (amountA, amountB);
        }
        uint256 adjustedAmountB = amountA.mul(reserveB) / reserveA;
        if (adjustedAmountB > amountB) {
            uint256 adjustedAmountA = amountB.mul(reserveA) / reserveB;
            return (adjustedAmountA, amountB);
        }
        return (amountA, adjustedAmountB);
    }

    function _mintLiquidity(uint256 amountA, uint256 amountB) private returns (uint256) {
        uint256 liquidityMinted;
        if (totalLiquidity == 0) {
            liquidityMinted = SafeMath.sqrt(amountA.mul(amountB)).sub(1000);
        } else {
            liquidityMinted = Math.min(amountA.mul(totalLiquidity) / reserveA, amountB.mul(totalLiquidity) / reserveB);
        }
        reserveA = reserveA.add(amountA);
        reserveB = reserveB.add(amountB);
        return liquidityMinted;
    }

    function getAmountOut(address tokenIn, uint256 amountIn) private view returns (uint256) {
        require(amountIn > 0, "Amount in must be positive.");
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token address.");

        uint256 inputReserve = tokenIn == address(tokenA) ? reserveA : reserveB;
        uint256 outputReserve = tokenIn == address(tokenA) ? reserveB : reserveA;

        // Assuming a 0.25% fee for simplicity, where 9975 represents 99.75% (10000 - 0.25% fee)
        uint256 fee = 9975;
        uint256 amountInWithFee = amountIn * fee;
        uint256 numerator = amountInWithFee * outputReserve;
        uint256 denominator = (inputReserve * 10000) + amountInWithFee;

        return numerator / denominator;
    }
}
