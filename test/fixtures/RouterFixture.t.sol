// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {MiniAmmFactory} from "src/core/MiniAmmFactory.sol";
import {MiniAmmRouter} from "src/core/MiniAmmRouter.sol";
import {MiniAmmPair} from "src/core/MiniAmmPair.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

abstract contract RouterFixture is Test {
    MiniAmmFactory internal factory;
    MiniAmmRouter internal router;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public virtual {
        tokenA = new MockERC20("TokenA", "TA", 18);
        tokenB = new MockERC20("TokenB", "TB", 18);

        factory = new MiniAmmFactory();

        // If your router constructor differs, adjust this line.
        router = new MiniAmmRouter(address(factory));
    }

    function _mintAndApprove(address user, uint256 a, uint256 b) internal {
        tokenA.mint(user, a);
        tokenB.mint(user, b);

        vm.startPrank(user);
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function _pair() internal view returns (MiniAmmPair p) {
        address pairAddr = factory.getPair(address(tokenA), address(tokenB));
        require(pairAddr != address(0), "PAIR_NOT_CREATED");
        p = MiniAmmPair(pairAddr);
    }

    function _assertReservesMatchBalances(MiniAmmPair p) internal {
        (uint112 r0, uint112 r1,) = p.getReserves();
        assertEq(uint256(r0), tokenA.balanceOf(address(p)) == 0 ? tokenB.balanceOf(address(p)) : uint256(r0), "sanity"); // no-op sanity

        // Use the pair's token0/token1 to map balances correctly.
        address t0 = p.token0();
        address t1 = p.token1();

        assertEq(uint256(r0), MockERC20(t0).balanceOf(address(p)), "reserve0 != balance0");
        assertEq(uint256(r1), MockERC20(t1).balanceOf(address(p)), "reserve1 != balance1");
    }
}
