// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PairFixture} from "test/fixtures/PairFixture.t.sol";

contract MiniAmmPair_MintBurn_Fuzz_Test is PairFixture {
    function testFuzz_mintThenBurn_roundTrip(uint96 raw0, uint96 raw1) external {
        // 1) Constrain fuzz inputs to a sane range:
        // - Not too small (avoid MINIMUM_LIQUIDITY-related reverts)
        // - Not too large (avoid reserve uint112 / overflow edge cases)
        uint256 a0 = bound(uint256(raw0), 1e9, 1e24);
        uint256 a1 = bound(uint256(raw1), 1e9, 1e24);

        // 2) Mint LP to alice
        uint256 liq = _addLiquidity(alice, a0, a1);
        assertGt(liq, 0, "liq > 0");

        uint256 supplyBefore = pair.totalSupply();

        // 3) Burn flow (Uniswap V2 pattern): user transfers LP into the Pair first
        vm.startPrank(alice);
        pair.transfer(address(pair), liq);
        (uint256 out0, uint256 out1) = pair.burn(alice);
        vm.stopPrank();

        // 4) Properties / invariants
        assertGt(out0, 0, "out0 > 0");
        assertGt(out1, 0, "out1 > 0");

        // Should never return more than deposited (rounding + min-liq lock usually makes it smaller)
        assertLe(out0, a0, "out0 <= deposit0");
        assertLe(out1, a1, "out1 <= deposit1");

        // If MINIMUM_LIQUIDITY is locked, user should not get 100% back
        assertLt(out0, a0, "out0 < deposit0 when min liq locked");
        assertLt(out1, a1, "out1 < deposit1 when min liq locked");

        // Pair should not hold LP after burning
        assertEq(pair.balanceOf(address(pair)), 0, "pair should not hold LP");

        // totalSupply must drop
        assertLt(pair.totalSupply(), supplyBefore, "totalSupply should drop");

        // Only MINIMUM_LIQUIDITY remains (single LP provider case)
        assertEq(pair.totalSupply(), pair.MINIMUM_LIQUIDITY(), "supply == MINIMUM_LIQUIDITY");

        // Reserves should match balances
        _assertReservesMatchBalances();
    }
}
