// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Fixed point math used by Uniswap V2 TWAP:
///         - encode(uint112) -> UQ112x112 (112.112 fixed point)
///         - uqdiv(UQ112x112, uint112) -> UQ112x112
library UQ112x112 {
    uint224 internal constant Q112 = 2 ** 112;

    function encode(uint112 y) internal pure returns (uint224 z) {
        // y * 2^112
        z = uint224(y) * Q112;
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        // (x / y) in 112.112
        z = x / uint224(y);
    }
}
