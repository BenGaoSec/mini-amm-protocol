// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MiniAmmPool - x*y=k AMM for two ERC20 tokens
/// @notice Learning / internal project, NOT production-ready
contract MiniAmmPool {
    // ==========
    //  Errors
    // ==========
    // TODO: define custom errors (e.g., InsufficientLiquidity, InvalidAmount, etc.)

    // ==========
    //  Events
    // ==========
    // TODO: Mint, Burn, Swap, Sync

    // ==========
    //  Immutable config
    // ==========
    // TODO: addresses of token0, token1
    // TODO: optionally fee parameters

    // ==========
    //  Storage - reserves & LP accounting
    // ==========
    // TODO: reserves for token0 / token1
    // TODO: totalSupply for LP
    // TODO: mapping of address => LP balance

    // ==========
    //  Constructor
    // ==========
    // TODO: set token addresses, sanity checks

    // ==========
    //  External view functions
    // ==========
    // TODO: getReserves()
    // TODO: totalSupply()
    // TODO: balanceOf(address account)
    // TODO: quote functions (optional)

    // ==========
    //  Core external actions
    // ==========
    // addLiquidity
    // removeLiquidity
    // swap

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1, uint256 liquidity) {
        // TODO: implement according to flowchart
    }

    function removeLiquidity(
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1) {
        // TODO: implement according to flowchart
    }

    function swap(
        uint256 amountIn,
        uint256 minAmountOut,
        bool zeroForOne,
        address to
    ) external returns (uint256 amountOut) {
        // TODO: implement according to flowchart
    }

    // ==========
    //  Internal helpers
    // ==========
    // _updateReserves
    // _mintLiquidity
    // _burnLiquidity
    // _getAmountOut (thin wrapper around library)
    // _safeTransfer / _safeTransferFrom

    // TODO: internal helper stubs only, no logic yet
}
