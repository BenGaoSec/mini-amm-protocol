// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";

/// @notice Extremely small safe transfer helpers (no OZ).
library SafeTransferLib {
    function safeTransferFrom(
        IERC20Minimal token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool ok = token.transferFrom(from, to, amount);
        require(ok, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20Minimal token,
        address to,
        uint256 amount
    ) internal {
        bool ok = token.transfer(to, amount);
        require(ok, "TRANSFER_FAILED");
    }
}
