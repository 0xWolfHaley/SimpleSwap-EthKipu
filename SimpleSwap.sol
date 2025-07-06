// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleSwap {
    struct LiquidityPool {
        uint256 reserveA;
        uint256 reserveB;
        mapping(address => uint256) liquidity;
    }

    mapping(address => mapping(address => LiquidityPool)) public pools;

    function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
    require(block.timestamp <= deadline, "EXPIRED");
    require(to != address(0), "INVALID_TO");

    // Transferir los tokens
    IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
    IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

    // ✅ Validación de mínimos
    require(amountADesired >= amountAMin, "INSUFFICIENT_A");
    require(amountBDesired >= amountBMin, "INSUFFICIENT_B");

    LiquidityPool storage pool = pools[tokenA][tokenB];

    pool.reserveA += amountADesired;
    pool.reserveB += amountBDesired;

    liquidity = amountADesired + amountBDesired;
    pool.liquidity[to] += liquidity;

    return (amountADesired, amountBDesired, liquidity);
}

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256, // amountAMin (unused for simplicity)
        uint256, // amountBMin (unused for simplicity)
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "EXPIRED");

        LiquidityPool storage pool = pools[tokenA][tokenB];

        require(pool.liquidity[to] >= liquidity, "INSUFFICIENT_LIQUIDITY");

        amountA = (liquidity * pool.reserveA) / (pool.reserveA + pool.reserveB);
        amountB = liquidity - amountA;

        pool.reserveA -= amountA;
        pool.reserveB -= amountB;
        pool.liquidity[to] -= liquidity;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(path.length == 2, "ONLY_SUPPORTS_TWO_TOKENS");
        require(block.timestamp <= deadline, "EXPIRED");

        address tokenA = path[0];
        address tokenB = path[1];

        LiquidityPool storage pool = pools[tokenA][tokenB];
        require(pool.reserveA > 0 && pool.reserveB > 0, "INSUFFICIENT_LIQUIDITY");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = getAmountOut(amountIn, pool.reserveA, pool.reserveB);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT");

        pool.reserveA += amountIn;
        pool.reserveB -= amountOut;

        IERC20(tokenB).transfer(to, amountOut);
    }

    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        LiquidityPool storage pool = pools[tokenA][tokenB];
        require(pool.reserveA > 0, "NO_LIQUIDITY");
        return (pool.reserveB * 1e18) / pool.reserveA;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }
}