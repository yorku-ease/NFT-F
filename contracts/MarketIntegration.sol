// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IMarketIntegration.sol";

/**
 * @title MarketIntegration
 * @dev Contract for managing liquidity and enabling trades between two ERC20 tokens.
 * It provides functions to add/remove liquidity to a token pair pool and to trade between the two tokens.
 */
contract MarketIntegration is IMarketIntegration, Ownable, ReentrancyGuard {
    // ERC20 tokens for trading
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Reserves for liquidity of both tokens
    uint256 private reserveA;
    uint256 private reserveB;


    /**
     * @dev Constructor to set up the market with two tokens.
     * @param _tokenA The address of the first token.
     * @param _tokenB The address of the second token.
     */
    constructor(address _tokenA, address _tokenB)  Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Token addresses cannot be zero.");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /**
     * @dev Allows a user to add liquidity to the pool for both tokens.
     * @param tokenAAmount The amount of tokenA to add.
     * @param tokenBAmount The amount of tokenB to add.
     */
    function addLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) external nonReentrant {
        reserveB += tokenBAmount;

    require(
            tokenA.transferFrom(msg.sender, address(this), tokenAAmount),
            "TokenA transfer failed"
        );
        require(
            tokenB.transferFrom(msg.sender, address(this), tokenBAmount),
            "TokenB transfer failed"
        );        reserveA += tokenAAmount;
        emit LiquidityAdded(msg.sender, tokenAAmount, tokenBAmount);
    }

    /**
     * @dev Allows a user to remove liquidity from the pool for both tokens.
     * @param tokenAAmount The amount of tokenA to remove.
     * @param tokenBAmount The amount of tokenB to remove.
     */
    function removeLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) external nonReentrant {
        reserveA -= tokenAAmount;
        reserveB -= tokenBAmount;
        require(tokenAAmount <= reserveA && tokenBAmount <= reserveB, "Insufficient reserves.");
        require(
        tokenA.transfer(msg.sender, tokenAAmount), "TokenA transfer failed");
        require(
        tokenB.transfer(msg.sender, tokenBAmount), "TokenB transfer failed");

        emit LiquidityRemoved(msg.sender, tokenAAmount, tokenBAmount);
    }

    /**
     * @dev Executes a trade from one token to another.
     * @param tokenIn The address of the token being traded in.
     * @param amountIn The amount of the input token being traded.
     * @param minAmountOut The minimum amount of the output token expected (for slippage protection).
     */
    function trade(address tokenIn, uint256 amountIn, uint256 minAmountOut) external nonReentrant {
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token address.");
        require(amountIn > 0 && minAmountOut > 0, "Invalid trading amounts.");

        IERC20 inputToken = IERC20(tokenIn);
        IERC20 outputToken = (tokenIn == address(tokenA)) ? tokenB : tokenA;
        uint256 amountOut = getAmountOut(tokenIn, amountIn);

        require(amountOut >= minAmountOut, "Slippage exceeded.");
        updateReserves(tokenIn, amountIn, amountOut);

        require(
            inputToken.transferFrom(msg.sender, address(this), amountIn),
            "Input token transfer failed"
        );
        require(
            outputToken.transfer(msg.sender, amountOut),
            "Output token transfer failed"
        );

        emit TradeExecuted(msg.sender, tokenIn, amountIn, amountOut);
    }

    /**
     * @dev Calculates the output amount for a given input amount using a simple formula.
     * @param tokenIn The address of the input token.
     * @param amountIn The amount of the input token.
     * @return amountOut The calculated output token amount.
     */
    function getAmountOut(address tokenIn, uint256 amountIn) public view returns (uint256) {
        require(amountIn > 0, "Amount in must be positive.");
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token address.");

        uint256 inputReserve = tokenIn == address(tokenA) ? reserveA : reserveB;
        uint256 outputReserve = tokenIn == address(tokenA) ? reserveB : reserveA;

        // Assuming a 0.3% fee for simplicity
        uint256 fee = 9975;
        uint256 amountInWithFee = amountIn * fee;
        uint256 numerator = amountInWithFee * outputReserve;
        uint256 denominator = (inputReserve * 10000) + amountInWithFee;
        return numerator / denominator;
    }

/**
 * @dev Internal function to update reserves after a trade.
     * @param tokenIn The address of the token being traded in.
     * @param amountIn The amount of the input token.
     * @param amountOut The amount of the output token.
     */
 function updateReserves(address tokenIn, uint256 amountIn, uint256 amountOut) private {
    if(tokenIn == address(tokenA)) {
    reserveA += amountIn;
    reserveB -= amountOut;
    } else {
    reserveB += amountIn;
    reserveA -= amountOut; }
    }
 }
