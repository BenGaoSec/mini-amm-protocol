// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RouterFixture} from "test/fixtures/RouterFixture.t.sol";
import {MiniAmmPair} from "src/core/MiniAmmPair.sol";

contract MiniAmmRouter_AddLiquidity_v0_Test is RouterFixture {
    function testAddLiquidity_firstLiquidity_success() external {
        uint256 a = 1e18;
        uint256 b = 2e18;

        _mintAndApprove(alice, a, b);

        uint256 deadline = block.timestamp;

        vm.startPrank(alice);
        (uint256 amountA, uint256 amountB, uint256 liq) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            a,
            b,
            0, // amountAMin
            0, // amountBMin
            bob,
            deadline
        );
        vm.stopPrank();

        // v0 expectation: returns desired amounts
        assertEq(amountA, a, "amountA");
        assertEq(amountB, b, "amountB");
        assertGt(liq, 0, "liq > 0");

        // Pair created
        MiniAmmPair p = _pair();

        // LP minted to `bob` (router must mint to `to`)
        assertEq(p.balanceOf(bob), liq, "lp to bob");

        // Router holds no tokens (no custody)
        assertEq(tokenA.balanceOf(address(router)), 0, "router holds tokenA");
        assertEq(tokenB.balanceOf(address(router)), 0, "router holds tokenB");

        // Reserves should match balances
        _assertReservesMatchBalances(p);
    }

    function testAddLiquidity_revert_expiredDeadline() external {
        _mintAndApprove(alice, 1e18, 1e18);

        uint256 deadline = block.timestamp - 1;

        vm.startPrank(alice);

        // If you have a custom error (e.g., Expired()), tighten this:
        // vm.expectRevert(MiniAmmRouter.Expired.selector);
        vm.expectRevert();

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1e18,
            1e18,
            0,
            0,
            alice,
            deadline
        );

        vm.stopPrank();
    }
}
