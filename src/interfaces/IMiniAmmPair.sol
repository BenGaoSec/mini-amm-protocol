// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IMiniAmmPair
/// @notice UniswapV2-style Pair interface (3-value getReserves)
interface IMiniAmmPair {
    // =============================================================
    //                              VIEWS
    // =============================================================

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    /// @notice Returns reserves and last block timestamp (uint32) used for TWAP/cumulative price logic.
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    // =============================================================
    //                             INIT
    // =============================================================

    /// @notice Called once by the factory right after CREATE2 deployment.
    function initialize(address token0, address token1) external;

    // =============================================================
    //                           LP ERC20
    // =============================================================

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // =============================================================
    //                              CORE
    // =============================================================

    /// @notice Mint LP tokens to `to`. Assumes tokens already transferred into pair.
    function mint(address to) external returns (uint256 liquidity);

    /// @notice Burn LP tokens held by the pair and send underlying to `to`.
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap tokens. If `data.length > 0`, calls `miniAmmCall` on `to` (flash swap style).
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    // =============================================================
    //                           MAINTENANCE
    // =============================================================

    function skim(address to) external;

    function sync() external;
}
