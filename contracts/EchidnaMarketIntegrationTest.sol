// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MarketIntegration.sol";

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Mock Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "MockERC20: transfer amount exceeds balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "MockERC20: transfer amount exceeds allowance");
        require(balanceOf[from] >= amount, "MockERC20: transfer amount exceeds balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract EchidnaMarketIntegrationTest {
    MarketIntegration public market;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    constructor() {
        tokenA = new MockERC20();
        tokenB = new MockERC20();
        market = new MarketIntegration(address(tokenA), address(tokenB));
        tokenA.approve(address(market), 50000 * 10**18);
        tokenB.approve(address(market), 50000 * 10**18);
        market.addLiquidity(10000 * 10**18, 10000 * 10**18);
    }

    // Ensure the liquidity cannot decrease
    function echidna_test_liquidity_cannot_decrease() public view returns (bool) {
        return market.getReserveA() >= 10000 * 10**18 && market.getReserveB() >= 10000 * 10**18;
    }

    // Ensure that bad trades cannot be executed
    function echidna_test_bad_trade() public returns (bool) {
        // Attempt a trade that should fail due to slippage
        // Note: This requires manual adjustment based on slippage logic in trade()
        try market.trade(address(tokenA), 100 * 10**18, 10000 * 10**18) {
            return false; // If trade succeeds, test should fail
        } catch {
            return true; // Trade failed as expected
        }
    }

    // Total supply for both tokens should not change
    function echidna_test_total_supply_constant() public view returns (bool) {
        return tokenA.totalSupply() == 1000000 * 10**18 && tokenB.totalSupply() == 1000000 * 10**18;
    }

}
