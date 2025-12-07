// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/MiniAmmPool.sol";
import "../mocks/MockERC20.sol";



contract MiniAmmPool_RemoveLiquidity_Test is Test {
    MockERC20 token0;
    MockERC20 token1;
    MiniAmmPool pool;

    address alice = address(0xA11CE);

    function setUp() public {
        token0 = new MockERC20("Token0", "T0");
        token1 = new MockERC20("Token1", "T1");
        pool = new MiniAmmPool(address(token0), address(token1));

        token0.mint(alice, 1_000_000 ether);
        token1.mint(alice, 1_000_000 ether);

        vm.startPrank(alice);
        token0.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);

        pool.addLiquidity(100 ether, 200 ether, 0, 0, alice);
        vm.stopPrank();
    }

    function test_removeLiquidity_basic() public {
        uint256 lpBal = pool.balanceOf(alice);

        uint256 alice0Before = token0.balanceOf(alice);
        uint256 alice1Before = token1.balanceOf(alice);

        vm.startPrank(alice);
        (uint256 amount0, uint256 amount1) =
            pool.removeLiquidity(lpBal / 2, 0, 0, alice);
        vm.stopPrank();

        assertGt(amount0, 0);
        assertGt(amount1, 0);

        assertEq(token0.balanceOf(alice), alice0Before + amount0);
        assertEq(token1.balanceOf(alice), alice1Before + amount1);

        // supply decreased
        assertEq(pool.balanceOf(alice), lpBal - (lpBal / 2));

        // reserves match pool balances
        (uint112 r0, uint112 r1) = pool.getReserves();
        assertEq(uint256(r0), token0.balanceOf(address(pool)));
        assertEq(uint256(r1), token1.balanceOf(address(pool)));
    }

    function test_removeLiquidity_revert_zeroLiquidity() public {
        vm.startPrank(alice);
        vm.expectRevert("LIQUIDITY_ZERO");
        pool.removeLiquidity(0, 0, 0, alice);
        vm.stopPrank();
    }

    function test_removeLiquidity_revert_toZero() public {
        vm.startPrank(alice);
        vm.expectRevert("TO_ZERO");
        pool.removeLiquidity(1, 0, 0, address(0));
        vm.stopPrank();
    }
}
