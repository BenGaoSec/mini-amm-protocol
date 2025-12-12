// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";

/// @notice Extremely small safe transfer helpers (no OZ).
library SafeTransferLib {
    // function transfer(address to, uint256 amount) external returns (bool);

    // function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function safeTransfer(address token, address to, uint256 amount) internal {
        bool ok = IERC20Minimal(token).transfer(to, amount);
        require(ok, "TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        bool ok = IERC20Minimal(token).transferFrom(from, to, amount);
        require(ok, "TRANSFER_FAILED");
    }
}
