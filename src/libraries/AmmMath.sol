// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Math helpers for x*y=k AMM
library AmmMath {
    /// @notice Babylonian method for integer square root.
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            //First guess
            z = y;
            uint x = (z + 1) >> 1;
            while (x < z) {
                z = x;
                x = (y / z + z) >> 1;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }
}
