import {IMiniAmmCallee} from "../interfaces/IMiniAmmCallee.sol";

import {MiniAmmPair} from "src/core/MiniAmmPair.sol";

import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";

contract FlashBorrower is IMiniAmmCallee {
    error UnauthorizedAccess();

    MiniAmmPair immutable pair;

    address public token0;
    address public token1;

    constructor(MiniAmmPair _pair, address _token0, address _token1) {
        pair = _pair;

        token0 = _token0;

        token1 = _token1;
    }

    function miniAmmCall(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data)
        external
        override
    {
        uint256 amountBack;
        address tokenToRepay;

        //establish a firewall;
        if (msg.sender != address(pair)) revert UnauthorizedAccess();

        // Implement some of my own logic to do with the amoutOut
        if (amount0Out == 0) {
            tokenToRepay = token1;
            amountBack = (amount1Out * 1000) / 997 + 1;
        } else {
            tokenToRepay = token0;
            amountBack = (amount0Out * 1000) / 997 + 1;
        }
    bool success = IERC20Minimal(tokenToRepay).transfer(address(pair), amountBack);
    require(success, "Transfer Failed");
    }
}
