// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {MiniAmmPair} from "src/core/MiniAmmPair.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

abstract contract PairFixture is Test {
    MiniAmmPair internal pair;
    MockERC20 internal token0;
    MockERC20 internal token1;

    address internal alice = address(0xA11CE);

    function setUp() public virtual {
        token0 = new MockERC20("Token0", "T0", 18);
        token1 = new MockERC20("Token1", "T1", 18);

        pair = new MiniAmmPair();
        pair.initialize(address(token0), address(token1));
    }

    function _addLiquidity(address user, uint256 a0, uint256 a1) internal returns (uint256 liq) {
        token0.mint(user, a0);
        token1.mint(user, a1);

        vm.startPrank(user);
        token0.transfer(address(pair), a0);
        token1.transfer(address(pair), a1);
        liq = pair.mint(user);
        vm.stopPrank();
    }

    function _assertReservesMatchBalances() internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(uint256(r0), token0.balanceOf(address(pair)), "reserve0 != balance0");
        assertEq(uint256(r1), token1.balanceOf(address(pair)), "reserve1 != balance1");
    }
}
