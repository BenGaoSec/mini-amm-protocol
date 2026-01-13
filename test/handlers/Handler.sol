// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {FlashBorrower} from "src/periphery/FlashBorrower.sol";
import {MiniAmmPair} from "src/core/MiniAmmPair.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract Handler is Test {
    MockERC20 public token0;
    MockERC20 public token1;
    MiniAmmPair public pair;
    FlashBorrower public flashBorrower;

    // Ghost Variables: The "Ledger of Truth"
    uint256 public ghost_depositSum0;
    uint256 public ghost_depositSum1;
    uint256 public ghost_kLast; // Baseline K after last liquidity change
    uint256 public ghost_Swap_kLast; // Snapshot K right before a swap

    constructor(MiniAmmPair _pair, FlashBorrower _flashBorrower, MockERC20 _token0, MockERC20 _token1) {
        token0 = _token0;
        token1 = _token1;
        pair = _pair;
        flashBorrower = _flashBorrower;
    }

    function deposit(uint256 amount0, uint256 amount1) public {
        // Bound to prevent immediate uint112 overflow in Pair reserves
        amount0 = bound(amount0, 1001, 1e25);
        amount1 = bound(amount1, 1001, 1e25);

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        ghost_depositSum0 += amount0;
        ghost_depositSum1 += amount1;

        pair.mint(address(this));

        // Update K Baseline (Cast to uint256 to prevent overflow)
        (uint112 r0, uint112 r1,) = pair.getReserves();
        ghost_kLast = uint256(r0) * uint256(r1);
    }

    function swap(bool zeroForOne, uint256 amountIn) public {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 < 1000 || r1 < 1000) return;

        // Take snapshot before action
        ghost_Swap_kLast = uint256(r0) * uint256(r1);

        uint256 reserveIn = zeroForOne ? r0 : r1;
        uint256 reserveOut = zeroForOne ? r1 : r0;

        // Bound swap size to 10% of pool to maintain mathematical stability
        amountIn = bound(amountIn, 1, reserveIn / 10);

        uint256 amountInWithFee = amountIn * 997;
        uint256 amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
        if (amountOut == 0) return;

        MockERC20 inputToken = zeroForOne ? token0 : token1;
        inputToken.mint(address(this), amountIn);
        inputToken.transfer(address(pair), amountIn);

        if (zeroForOne) {
            pair.swap(0, amountOut, address(this), "");
            ghost_depositSum0 += amountIn;
            ghost_depositSum1 -= amountOut;
        } else {
            pair.swap(amountOut, 0, address(this), "");
            ghost_depositSum1 += amountIn;
            ghost_depositSum0 -= amountOut;
        }
    }

    function burn() public {
        uint256 amountTransfer = pair.balanceOf(address(this));
        if (amountTransfer == 0) return;
        pair.transfer(address(pair), amountTransfer);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        ghost_depositSum0 = (amount0 > ghost_depositSum0) ? 0 : ghost_depositSum0 - amount0;
        ghost_depositSum1 = (amount1 > ghost_depositSum1) ? 0 : ghost_depositSum1 - amount1;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        ghost_kLast = uint256(r0) * uint256(r1);
        ghost_Swap_kLast = uint256(r0) * uint256(r1);

    }

    function flashSwap(uint256 amountToBorrow, bool borrowToken0) public {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (borrowToken0) {
            amountToBorrow = bound(amountToBorrow, 1, uint256(r0) * 9 / 10);
        } else {
            amountToBorrow = bound(amountToBorrow, 1, uint256(r1) * 9 / 10);
        }
        uint256 amount0Out = borrowToken0 ? amountToBorrow : 0;
        uint256 amount1Out = borrowToken0 ? 0 : amountToBorrow;
        pair.swap(amount0Out, amount1Out, address(flashBorrower), "flashLoan");

        (r0, r1,) = pair.getReserves();
        ghost_kLast = uint256(r0) * uint256(r1);

        uint256 amountRepaid = (amountToBorrow * 1000) / 997 + 1;
        uint256 feePaid = amountRepaid - amountToBorrow;

        if (borrowToken0) {
            ghost_depositSum0 += feePaid;
        } else {
            ghost_depositSum1 += feePaid;
        }
    }

    // inject 1-1e20 tokens to pool.
    function forcePush(bool ZeroForOne, uint256 amountInput) public {
        MockERC20 inputToken = ZeroForOne ? token0 : token1;
        amountInput = bound(amountInput, 1, 1e20);
        inputToken.mint(address(pair), amountInput);
    }

    //call the pair.sync
    function sync() public {
        pair.sync();
    }

    //call the pair.skim
    function skim() public {
        pair.skim(address(this));
    }
}
