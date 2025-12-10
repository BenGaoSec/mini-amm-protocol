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
        console2.log("setUp start");

        token0 = new MockERC20("Token0", "T0");
        token1 = new MockERC20("Token1", "T1");
        pool = new MiniAmmPool(address(token0), address(token1));

        token0.mint(alice, 1_000_000 ether);
        token1.mint(alice, 1_000_000 ether);

        console2.log("alice bal0", token0.balanceOf(alice));
        console2.log("alice bal1", token1.balanceOf(alice));

        vm.startPrank(alice);
        token0.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        console2.log("setUp end");
    }

    function test_addLiquidity_bootstrap_liquidityMath_exact() public {
        uint256 a0 = 100 ether;
        uint256 a1 = 200 ether;

        vm.startPrank(alice);
        (uint256 amount0, uint256 amount1, uint256 liquidity) = pool.addLiquidity(
            a0,
            a1,
            0,
            0,
            alice
        );
        vm.stopPrank();

        uint256 rootK = _sqrt(a0 * a1);
        uint256 expectedLiquidity = rootK - pool.MINIMUM_LIQUIDITY();

        assertEq(amount0, a0);
        assertEq(amount1, a1);
        assertEq(liquidity, expectedLiquidity);

        // minimum lock behavior
        assertEq(pool.balanceOf(address(0)), pool.MINIMUM_LIQUIDITY());
        assertEq(pool.totalSupply(), expectedLiquidity + pool.MINIMUM_LIQUIDITY());

        (uint112 r0, uint112 r1) = pool.getReserves();
        assertEq(uint256(r0), a0);
        assertEq(uint256(r1), a1);
    }

    function test_addLiquidity_secondAdd_amount0Limiting_path_and_liquidity() public {
        // bootstrap 100/200
        vm.startPrank(alice);
        pool.addLiquidity(100 ether, 200 ether, 0, 0, alice);
        vm.stopPrank();

        // snapshot before 2nd add
        (uint112 r0, uint112 r1) = pool.getReserves();
        uint256 ts = pool.totalSupply();

        uint256 amount0Desired = 10 ether;
        uint256 amount1Desired = 999 ether; // big enough so token0 is limiting

        uint256 expectedAmount1Optimal = (amount0Desired * uint256(r1)) / uint256(r0);

        vm.startPrank(alice);
        (uint256 amount0, uint256 amount1, uint256 liquidity) = pool.addLiquidity(
            amount0Desired,
            amount1Desired,
            0,
            0,
            alice
        );
        vm.stopPrank();

        assertEq(amount0, amount0Desired);
        assertEq(amount1, expectedAmount1Optimal);

        uint256 liquidity0 = (amount0 * ts) / uint256(r0);
        uint256 liquidity1 = (amount1 * ts) / uint256(r1);
        uint256 expectedLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;

        assertEq(liquidity, expectedLiquidity);

        (uint112 nr0, uint112 nr1) = pool.getReserves();
        assertEq(uint256(nr0), uint256(r0) + amount0);
        assertEq(uint256(nr1), uint256(r1) + amount1);
    }

    function testFuzz_addLiquidity_secondAdd_amount0Limiting_path_and_liquidity(
        uint256 amount0DesiredRaw,
        uint256 extra1Raw
    ) public {
        // --------------------------------------------------------------------
        // 1) bootstrap 100/200
        // --------------------------------------------------------------------
        vm.startPrank(alice);
        pool.addLiquidity(100 ether, 200 ether, 0, 0, alice);
        vm.stopPrank();

        // snapshot before 2nd add
        (uint112 r0, uint112 r1) = pool.getReserves();
        uint256 ts = pool.totalSupply();

        // --------------------------------------------------------------------
        // 2) bound fuzz inputs to sane ranges
        //    (Adjust ranges as you like)
        // --------------------------------------------------------------------
        uint256 amount0Desired = bound(amount0DesiredRaw, 1, 10_000 ether);

        // expected optimal amount1 to keep ratio
        uint256 expectedAmount1Optimal = (amount0Desired * uint256(r1)) / uint256(r0);

        // Make amount1Desired "big enough" so token0 is limiting.
        // We do that by adding a fuzzed extra margin.
        uint256 extra1 = bound(extra1Raw, 0, 10_000 ether);
        uint256 amount1Desired = expectedAmount1Optimal + extra1;

        // --------------------------------------------------------------------
        // 3) second add
        // --------------------------------------------------------------------
        vm.startPrank(alice);
        (uint256 amount0, uint256 amount1, uint256 liquidity) = pool.addLiquidity(
            amount0Desired,
            amount1Desired,
            0,
            0,
            alice
        );
        vm.stopPrank();

        // --------------------------------------------------------------------
        // 4) assertions (same as your unit test)
        // --------------------------------------------------------------------
        assertEq(amount0, amount0Desired);
        assertEq(amount1, expectedAmount1Optimal);

        uint256 liquidity0 = (amount0 * ts) / uint256(r0);
        uint256 liquidity1 = (amount1 * ts) / uint256(r1);
        uint256 expectedLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;

        assertEq(liquidity, expectedLiquidity);

        (uint112 nr0, uint112 nr1) = pool.getReserves();
        assertEq(uint256(nr0), uint256(r0) + amount0);
        assertEq(uint256(nr1), uint256(r1) + amount1);
    }

    function test_addLiquidity_secondAdd_amount1Limiting_path_and_liquidity() public {
        // bootstrap 100/200
        vm.startPrank(alice);
        pool.addLiquidity(100 ether, 200 ether, 0, 0, alice);
        vm.stopPrank();

        (uint112 r0, uint112 r1) = pool.getReserves();
        uint256 ts = pool.totalSupply();

        uint256 amount0Desired = 999 ether; // big
        uint256 amount1Desired = 10 ether; // small -> token1 limiting

        uint256 expectedAmount0Optimal = (amount1Desired * uint256(r0)) / uint256(r1);

        vm.startPrank(alice);
        (uint256 amount0, uint256 amount1, uint256 liquidity) = pool.addLiquidity(
            amount0Desired,
            amount1Desired,
            0,
            0,
            alice
        );
        vm.stopPrank();

        assertEq(amount1, amount1Desired);
        assertEq(amount0, expectedAmount0Optimal);

        uint256 liquidity0 = (amount0 * ts) / uint256(r0);
        uint256 liquidity1 = (amount1 * ts) / uint256(r1);
        uint256 expectedLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;

        assertEq(liquidity, expectedLiquidity);

        (uint112 nr0, uint112 nr1) = pool.getReserves();
        assertEq(uint256(nr0), uint256(r0) + amount0);
        assertEq(uint256(nr1), uint256(r1) + amount1);
    }

    function test_addLiquidity_bootstrap_revert_bothRequired() public {
        vm.startPrank(alice);

        vm.expectRevert("BOTH_REQUIRED");
        pool.addLiquidity(100 ether, 0, 0, 0, alice);

        vm.expectRevert("BOTH_REQUIRED");
        pool.addLiquidity(0, 200 ether, 0, 0, alice);

        vm.stopPrank();
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
