// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PairFixture} from "test/fixtures/PairFixture.t.sol";

contract MiniAmmPair_Swap_Min_Test is PairFixture {
    address internal bob = address(0xB0B);

    function testSwapExactIn_token0ForToken1_min() external {
        // 1) Add initial liquidity
        uint256 a0 = 1e18;
        uint256 a1 = 1e18;
        uint256 liq = _addLiquidity(alice, a0, a1);
        assertGt(liq, 0, "liq > 0");

        // 2) Read reserves BEFORE swap
        (uint112 r0, uint112 r1,) = pair.getReserves();

        // 3) Give bob token0 as input
        uint256 amountIn = 1e17; // 0.1 token0
        token0.mint(bob, amountIn);
        assertEq(token1.balanceOf(bob), 0, "bob token1 should start at 0");

        // 4) Compute amountOut (0.3% fee)
        uint256 amountOut = _getAmountOut(amountIn, uint256(r0), uint256(r1));
        assertGt(amountOut, 0, "amountOut > 0");
        assertLt(amountOut, uint256(r1), "amountOut < r1");

        // 5) Execute swap (transfer in first)
        vm.startPrank(bob);
        token0.transfer(address(pair), amountIn);
        pair.swap(0, amountOut, bob, new bytes(0));
        vm.stopPrank();

        // A) Bob received token1
        assertEq(token1.balanceOf(bob), amountOut, "token1 out mismatch");

        // B) Reserves match balances
        _assertReservesMatchBalances();

        // C) Fee-adjusted invariant holds against OLD reserves
        uint256 bal0 = token0.balanceOf(address(pair));
        uint256 bal1 = token1.balanceOf(address(pair));

        uint256 amount0Out = 0;
        uint256 amount1Out = amountOut;

        uint256 amount0In = bal0 > (uint256(r0) - amount0Out) ? bal0 - (uint256(r0) - amount0Out) : 0;

        uint256 amount1In = bal1 > (uint256(r1) - amount1Out) ? bal1 - (uint256(r1) - amount1Out) : 0;

        assertEq(amount0In, amountIn, "amount0In mismatch");
        assertEq(amount1In, 0, "amount1In should be 0");

        uint256 bal0Adj = bal0 * 1000 - amount0In * 3;
        uint256 bal1Adj = bal1 * 1000 - amount1In * 3;

        assertGe(bal0Adj * bal1Adj, uint256(r0) * uint256(r1) * 1000 * 1000, "K invariant violated");
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "IN=0");
        require(reserveIn > 0 && reserveOut > 0, "RES=0");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
