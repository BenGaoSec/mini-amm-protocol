// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AmmMath
/// @notice Small math helpers for AMM (min/max/sqrt/log2)
/// @dev sqrt returns floor(sqrt(a)) for all uint256 a.
library AmmMath {
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /// @notice Returns floor(sqrt(a)).
    /// @dev Uses: initial guess from log2 + fixed Newton iterations.
    function sqrt(uint256 a) internal pure returns (uint256 result) {
        if (a == 0) return 0;

        // Initial guess: 1 << (floor(log2(a)) / 2)
        uint256 x = 1 << (log2(a) >> 1);
        result = x;

        unchecked {
            // Newton-Raphson iterations. 7 rounds are enough for uint256.
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;

            // Pull back if we overshot.
            uint256 r1 = a / result;
            if (result > r1) result = r1;

            // Final safety: ensure floor(sqrt(a))
            if (result * result > a) result--;
        }
    }

    /// @notice Returns floor(log2(x)) for x > 0.
    function log2(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            if (x >> 128 > 0) x >>= 128;
            r += 128;
            if (x >> 64 > 0) x >>= 64;
            r += 64;
            if (x >> 32 > 0) x >>= 32;
            r += 32;
            if (x >> 16 > 0) x >>= 16;
            r += 16;
            if (x >> 8 > 0) x >>= 8;
            r += 8;
            if (x >> 4 > 0) x >>= 4;
            r += 4;
            if (x >> 2 > 0) x >>= 2;
            r += 2;
            if (x >> 1 > 0) r += 1;
        }
    }
}
