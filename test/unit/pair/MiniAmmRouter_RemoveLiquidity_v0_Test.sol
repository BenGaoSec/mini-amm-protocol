// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RouterFixture} from "test/fixtures/RouterFixture.t.sol";
import {MiniAmmPair} from "src/core/MiniAmmPair.sol";
import {MiniAmmRouter} from "src/core/MiniAmmRouter.sol";

contract MiniAmmRouter_RemoveLiquidity_v0_Test is RouterFixture {
    function testRemoveLiquidity_full_success() external {
        uint256 a = 1e18;
        uint256 b = 2e18;

        _mintAndApprove(alice, a, b);

        uint256 deadline = block.timestamp;

        // Add liquidity; mint LP to alice so she can burn it.
        vm.startPrank(alice);
        (,, uint256 liq) = router.addLiquidity(address(tokenA), address(tokenB), a, b, 0, 0, alice, deadline);
        vm.stopPrank();

        MiniAmmPair p = _pair();
        assertEq(p.balanceOf(alice), liq, "lp to alice");

        uint256 aBobBefore = tokenA.balanceOf(bob);
        uint256 bBobBefore = tokenB.balanceOf(bob);

        // Remove all liquidity to bob
        vm.startPrank(alice);
        p.approve(address(router), liq);

        (uint256 amountA, uint256 amountB) =
            router.removeLiquidity(address(tokenA), address(tokenB), liq, 0, 0, bob, deadline);
        vm.stopPrank();

        assertGt(amountA, 0, "amountA > 0");
        assertGt(amountB, 0, "amountB > 0");

        // Tokens sent to bob
        assertEq(tokenA.balanceOf(bob), aBobBefore + amountA, "bob tokenA");
        assertEq(tokenB.balanceOf(bob), bBobBefore + amountB, "bob tokenB");

        // LP burned from alice
        assertEq(p.balanceOf(alice), 0, "alice lp burned");

        // Router holds no custody
        assertEq(tokenA.balanceOf(address(router)), 0, "router holds tokenA");
        assertEq(tokenB.balanceOf(address(router)), 0, "router holds tokenB");

        _assertReservesMatchBalances(p);
    }

    function testRemoveLiquidity_partial_success() external {
        uint256 a = 10e18;
        uint256 b = 20e18;

        _mintAndApprove(alice, a, b);

        uint256 deadline = block.timestamp;

        vm.startPrank(alice);
        (,, uint256 liq) = router.addLiquidity(address(tokenA), address(tokenB), a, b, 0, 0, alice, deadline);
        vm.stopPrank();

        MiniAmmPair p = _pair();

        uint256 burnLiq = liq / 2;
        require(burnLiq > 0, "burnLiq=0");

        uint256 aBefore = tokenA.balanceOf(alice);
        uint256 bBefore = tokenB.balanceOf(alice);

        vm.startPrank(alice);
        p.approve(address(router), burnLiq);

        (uint256 amountA, uint256 amountB) =
            router.removeLiquidity(address(tokenA), address(tokenB), burnLiq, 0, 0, alice, deadline);
        vm.stopPrank();

        assertGt(amountA, 0, "amountA > 0");
        assertGt(amountB, 0, "amountB > 0");

        // Alice receives tokens (to=alice)
        assertEq(tokenA.balanceOf(alice), aBefore + amountA, "alice tokenA");
        assertEq(tokenB.balanceOf(alice), bBefore + amountB, "alice tokenB");

        // LP decreased but not zero
        assertEq(p.balanceOf(alice), liq - burnLiq, "lp remaining");

        _assertReservesMatchBalances(p);
    }

    function testRemoveLiquidity_revert_pairNotFound() external {
        _mintAndApprove(alice, 1e18, 1e18);

        uint256 deadline = block.timestamp;

        vm.startPrank(alice);
        vm.expectRevert(MiniAmmRouter.PairNotFound.selector);

        router.removeLiquidity(address(tokenA), address(tokenB), 1e18, 0, 0, alice, deadline);
        vm.stopPrank();
    }

    function testRemoveLiquidity_revert_insufficientAAmount() external {
        uint256 a = 1e18;
        uint256 b = 2e18;

        _mintAndApprove(alice, a, b);

        uint256 deadline = block.timestamp;

        vm.startPrank(alice);
        (,, uint256 liq) = router.addLiquidity(address(tokenA), address(tokenB), a, b, 0, 0, alice, deadline);
        vm.stopPrank();

        MiniAmmPair p = _pair();

        vm.startPrank(alice);
        p.approve(address(router), liq);

        vm.expectRevert(MiniAmmRouter.InsufficientAAmount.selector);
        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liq,
            type(uint256).max, // too high
            0,
            alice,
            deadline
        );
        vm.stopPrank();
    }

    function testRemoveLiquidity_revert_insufficientBAmount() external {
        uint256 a = 1e18;
        uint256 b = 2e18;

        _mintAndApprove(alice, a, b);

        uint256 deadline = block.timestamp;

        vm.startPrank(alice);
        (,, uint256 liq) = router.addLiquidity(address(tokenA), address(tokenB), a, b, 0, 0, alice, deadline);
        vm.stopPrank();

        MiniAmmPair p = _pair();

        vm.startPrank(alice);
        p.approve(address(router), liq);

        vm.expectRevert(MiniAmmRouter.InsufficientBAmount.selector);
        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liq,
            0,
            type(uint256).max, // too high
            alice,
            deadline
        );
        vm.stopPrank();
    }

    function testRemoveLiquidity_revert_expiredDeadline() external {
        uint256 a = 1e18;
        uint256 b = 2e18;

        _mintAndApprove(alice, a, b);

        // Create LP first
        vm.startPrank(alice);
        (,, uint256 liq) = router.addLiquidity(address(tokenA), address(tokenB), a, b, 0, 0, alice, block.timestamp);
        vm.stopPrank();

        MiniAmmPair p = _pair();

        uint256 expired = block.timestamp - 1;

        vm.startPrank(alice);
        p.approve(address(router), liq);

        vm.expectRevert(MiniAmmRouter.Expired.selector);
        router.removeLiquidity(address(tokenA), address(tokenB), liq, 0, 0, alice, expired);
        vm.stopPrank();
    }
}
