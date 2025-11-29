// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Math helpers for x*y=k AMM
library AmmMath {
    /// @notice Babylonian method for integer square root.
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) {
            return 0;
        }

        // Initial guess: y
        uint256 x = y;
        z = (x + 1) >> 1;
        while (z < x) {
            x = z;
            z = (y / z + z) >> 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}
