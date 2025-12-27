// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PairFixture} from "test/fixtures/PairFixture.t.sol";
import {MiniAmmPair} from "src/core/MiniAmmPair.sol";

// If your fixture already imports MiniAmmPair / exposes `pair` as MiniAmmPair, keep this.
// Otherwise adjust the import/path/type accordingly.

contract MiniAmmPair_SkimSync_Test is PairFixture {
    // -------------------------
    // helpers
    // -------------------------
    function _ensureLiquidity() internal returns (uint112 r0, uint112 r1, uint32 ts) {
        (r0, r1, ts) = pair.getReserves();
        if (r0 == 0 || r1 == 0) {
            // Seed initial liquidity using deal() so we don't depend on token mint() APIs.
            uint256 amt0 = 10e18;
            uint256 amt1 = 20e18;

            deal(address(token0), address(this), amt0);
            deal(address(token1), address(this), amt1);

            bool ok0 = token0.transfer(address(pair), amt0);
            bool ok1 = token1.transfer(address(pair), amt1);
            require(ok0 && ok1, "seed transfer failed");

            pair.mint(address(this));

            (r0, r1, ts) = pair.getReserves();
            require(r0 > 0 && r1 > 0, "seed reserves still zero");
        }
    }

    function _donateExcess(uint256 extra0, uint256 extra1) internal {
        if (extra0 > 0) {
            deal(address(token0), address(this), token0.balanceOf(address(this)) + extra0);
            bool ok0 = token0.transfer(address(pair), extra0);
            require(ok0, "donate0 failed");
        }
        if (extra1 > 0) {
            deal(address(token1), address(this), token1.balanceOf(address(this)) + extra1);
            bool ok1 = token1.transfer(address(pair), extra1);
            require(ok1, "donate1 failed");
        }
    }

    // -------------------------
    // skim
    // -------------------------

    function test_skim_transfersOnlyExcess_andDoesNotTouchReservesOrTimestamp() external {
        (uint112 r0, uint112 r1, uint32 ts0) = _ensureLiquidity();

        uint256 extra0 = 1e18;
        uint256 extra1 = 2e18;
        address to = makeAddr("skim_to");

        _donateExcess(extra0, extra1);

        // Balances should now be reserves + donated extras
        assertEq(token0.balanceOf(address(pair)), uint256(r0) + extra0);
        assertEq(token1.balanceOf(address(pair)), uint256(r1) + extra1);

        // Warp so timestamp would change if skim incorrectly called _update
        vm.warp(block.timestamp + 13);

        pair.skim(to);

        // Pair balances back to exactly reserves
        assertEq(token0.balanceOf(address(pair)), uint256(r0));
        assertEq(token1.balanceOf(address(pair)), uint256(r1));

        // Recipient got the excess only
        assertEq(token0.balanceOf(to), extra0);
        assertEq(token1.balanceOf(to), extra1);

        // Reserves + blockTimestampLast MUST remain unchanged (skim does not call _update)
        (uint112 r0After, uint112 r1After, uint32 tsAfter) = pair.getReserves();
        assertEq(r0After, r0);
        assertEq(r1After, r1);
        assertEq(tsAfter, ts0);
    }

    // -------------------------
    // sync
    // -------------------------

    function test_sync_updatesReservesToCurrentBalances() external {
        (uint112 r0, uint112 r1,) = _ensureLiquidity();

        uint256 extra0 = 3e18;
        uint256 extra1 = 4e18;

        _donateExcess(extra0, extra1);

        // Pre: reserves unchanged
        (uint112 pre0, uint112 pre1, uint32 tsPre) = pair.getReserves();
        assertEq(pre0, r0);
        assertEq(pre1, r1);

        vm.warp(block.timestamp + 17);

        pair.sync();

        // Post: reserves updated to balances (including donation)
        (uint112 post0, uint112 post1, uint32 tsPost) = pair.getReserves();
        assertEq(post0, uint112(uint256(r0) + extra0));
        assertEq(post1, uint112(uint256(r1) + extra1));
        assertEq(tsPost, uint32(block.timestamp));

        // timestamp should have advanced vs pre (unless wrap, which is practically impossible in tests)
        assertTrue(tsPost != tsPre);
    }

    // -------------------------
    // TWAP via sync/_update
    // -------------------------

    function test_sync_accumulatesTWAP_usingOldReserves_priceTimesDt() external {
        (uint112 r0, uint112 r1, uint32 ts0) = _ensureLiquidity();

        // Capture cumulative prices BEFORE
        uint256 p0Before = pair.price0CumulativeLast();
        uint256 p1Before = pair.price1CumulativeLast();

        // Move time forward and call sync() with unchanged balances == reserves
        // This triggers _update and should accumulate using OLD reserves (r0/r1).
        uint256 dt = 23;
        vm.warp(block.timestamp + dt);

        pair.sync();

        // Compute expected delta using the same math as UniswapV2:
        // price0 = (r1 << 112) / r0 ; price1 = (r0 << 112) / r1
        uint32 timeElapsed = uint32(block.timestamp) - ts0;
        uint256 price0 = (uint256(r1) << 112) / uint256(r0);
        uint256 price1 = (uint256(r0) << 112) / uint256(r1);

        uint256 p0Expected = p0Before + price0 * uint256(timeElapsed);
        uint256 p1Expected = p1Before + price1 * uint256(timeElapsed);

        assertEq(pair.price0CumulativeLast(), p0Expected);
        assertEq(pair.price1CumulativeLast(), p1Expected);
    }

    function test_sync_dtZero_noAccumulatorChange() external {
        _ensureLiquidity();

        uint256 p0Before = pair.price0CumulativeLast();
        uint256 p1Before = pair.price1CumulativeLast();

        // Call sync twice in the same block timestamp → dt=0
        pair.sync();
        uint256 p0Mid = pair.price0CumulativeLast();
        uint256 p1Mid = pair.price1CumulativeLast();

        pair.sync();
        uint256 p0After = pair.price0CumulativeLast();
        uint256 p1After = pair.price1CumulativeLast();

        // First sync may or may not change depending on how fixture set blockTimestampLast;
        // but second sync at same timestamp must not change cumulatives.
        assertEq(p0After, p0Mid);
        assertEq(p1After, p1Mid);

        // Also: if dt=0 initially, then even first call won't change.
        // So we allow p0Mid == p0Before as well (no assertion needed beyond consistency).
        (p0Before);
        (p1Before);
    }

    // -------------------------
    // uint112 overflow guard (ReservesOverflow)
    // -------------------------

    function test_sync_revertsOnReservesOverflow_uint112() external {
        _ensureLiquidity();

        // Force pair's balance beyond uint112 max, then sync should revert at your new bounds check.
        uint256 tooBig = uint256(type(uint112).max) + 1;

        // Set pair token0 balance to tooBig; token1 can be anything.
        deal(address(token0), address(pair), tooBig);
        deal(address(token1), address(pair), 1);

        vm.expectRevert(MiniAmmPair.ReservesOverflow.selector);
        pair.sync();
    }
}
