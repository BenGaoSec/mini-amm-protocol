// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PairFixture} from "test/fixtures/PairFixture.t.sol";

contract MiniAmmPair_Burn_Test is PairFixture {
    function testBurnBasic() external {
        uint256 a0 = 1e18;
        uint256 a1 = 1e18;

        // 1) mint LP to alice
        uint256 liq = _addLiquidity(alice, a0, a1);
        assertGt(liq, 0, "liq > 0");

        uint256 supplyBefore = pair.totalSupply();

        // 2) burn: alice must transfer LP into the Pair first (V2 pattern)
        vm.startPrank(alice);
        pair.transfer(address(pair), liq);
        (uint256 out0, uint256 out1) = pair.burn(alice);
        vm.stopPrank();

        // --- assertions ---
        assertGt(out0, 0, "out0 > 0");
        assertGt(out1, 0, "out1 > 0");

        // With MINIMUM_LIQUIDITY lock, alice should NOT get 100% back
        // (Pair keeps a tiny remainder corresponding to locked liquidity)
        assertLt(out0, a0, "out0 should be < deposit when min liquidity locked");
        assertLt(out1, a1, "out1 should be < deposit when min liquidity locked");

        // Pair should not hold LP after burn
        assertEq(pair.balanceOf(address(pair)), 0, "pair should not hold LP");

        // totalSupply must drop after burn
        assertLt(pair.totalSupply(), supplyBefore, "totalSupply should drop");

        // reserves should match balances
        _assertReservesMatchBalances();

        // If you implemented UniswapV2-style MINIMUM_LIQUIDITY lock:
        // after burning all alice LP (and only alice provided liquidity),
        // totalSupply should equal MINIMUM_LIQUIDITY.
        assertEq(pair.totalSupply(), pair.MINIMUM_LIQUIDITY(), "supply should equal MINIMUM_LIQUIDITY");
    }
}
