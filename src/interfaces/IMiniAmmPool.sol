// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMiniAmmPool {
    // view
    // TODO: getReserves, totalSupply, balanceOf, etc.

    // actions
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1, uint256 liquidity);

    function removeLiquidity(
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amountIn,
        uint256 minAmountOut,
        bool zeroForOne,
        address to
    ) external returns (uint256 amountOut);
}
