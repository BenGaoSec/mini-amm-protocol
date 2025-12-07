// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/MiniAmmPool.sol";
import "../mocks/MockERC20.sol";



contract MiniAmmPool_AddLiquidity_Test is Test {
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
        vm.stopPrank();
    }

    function test_addLiquidity_bootstrap_mintsLP_and_updatesReserves() public {
        vm.startPrank(alice);

        (uint256 amount0, uint256 amount1, uint256 liquidity) =
            pool.addLiquidity(
                100 ether,
                200 ether,
                0,
                0,
                alice
            );

        vm.stopPrank();

        // amounts should equal desired in bootstrap
        assertEq(amount0, 100 ether);
        assertEq(amount1, 200 ether);

        // reserves should match balances
        (uint112 r0, uint112 r1) = pool.getReserves();
        assertEq(uint256(r0), 100 ether);
        assertEq(uint256(r1), 200 ether);

        // totalSupply includes user liquidity + MINIMUM_LIQUIDITY
        assertEq(pool.balanceOf(alice), liquidity);
        assertEq(pool.balanceOf(address(0)), pool.MINIMUM_LIQUIDITY());
        assertEq(pool.totalSupply(), liquidity + pool.MINIMUM_LIQUIDITY());
    }

    function test_addLiquidity_revert_toZero() public {
        vm.startPrank(alice);
        vm.expectRevert("TO_ZERO");
        pool.addLiquidity(1 ether, 1 ether, 0, 0, address(0));
        vm.stopPrank();
    }

    function test_addLiquidity_revert_zeroInput() public {
        vm.startPrank(alice);
        vm.expectRevert("ZERO_INPUT");
        pool.addLiquidity(0, 0, 0, 0, alice);
        vm.stopPrank();
    }
}
