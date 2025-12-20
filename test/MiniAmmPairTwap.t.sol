// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// Adjust this import path to match your repo structure.

import {MiniAmmPair} from "../src/core/MiniAmmPair.sol";

/// @dev Minimal ERC20 mock that satisfies IERC20Minimal needs:
///      - balanceOf(address)
///      - transfer(address,uint256) returns (bool)
///      We only need mint + transfer to fund the pair and let pair.sync() read balances.
contract MockERC20Minimal {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) public balanceOf;

    constructor(string memory n, string memory s, uint8 d) {
        name = n;
        symbol = s;
        decimals = d;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 bal = balanceOf[msg.sender];
        require(bal >= amount, "INSUFFICIENT_BALANCE");
        unchecked {
            balanceOf[msg.sender] = bal - amount;
            balanceOf[to] += amount;
        }
        return true;
    }
}

contract MiniAmmPairTwapTest is Test {
    MiniAmmPair pair;
    MockERC20Minimal token0;
    MockERC20Minimal token1;

    function setUp() public {
        token0 = new MockERC20Minimal("Token0", "T0", 18);
        token1 = new MockERC20Minimal("Token1", "T1", 18);

        pair = new MiniAmmPair();
        pair.initialize(address(token0), address(token1));
    }

    function test_TwapAccumulator_constantReserves_deltaMatchesPriceTimesDt() public {
        // Choose simple balances so the spot price is easy:
        // price0 = reserve1/reserve0 = 200/100 = 2
        uint256 amount0 = 100e18;
        uint256 amount1 = 200e18;

        // Mint to this test contract.
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        // Transfer into the pair so pair.sync() can read balances.
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        // First sync sets reserves and blockTimestampLast; cumulative usually stays 0
        // because old reserves were 0 and the TWAP hook is gated by old reserves != 0.
        vm.warp(1_000);
        pair.sync();

        (uint112 r0, uint112 r1, uint32 ts0) = pair.getReserves();
        assertEq(uint256(r0), amount0, "reserve0 mismatch after first sync");
        assertEq(uint256(r1), amount1, "reserve1 mismatch after first sync");
        assertEq(uint256(ts0), 1_000, "blockTimestampLast mismatch after first sync");

        uint256 p0Before = pair.price0CumulativeLast();
        uint256 p1Before = pair.price1CumulativeLast();

        // Advance time by dt seconds, keep balances/reserves constant, then sync again.
        uint256 dt = 10;
        vm.warp(1_000 + dt);
        pair.sync();

        uint256 p0After = pair.price0CumulativeLast();
        uint256 p1After = pair.price1CumulativeLast();

        // Expected fixed-point prices in UQ112x112:
        // price0 = (r1 << 112) / r0
        // price1 = (r0 << 112) / r1
        uint256 expectedPrice0 = (uint256(r1) << 112) / uint256(r0);
        uint256 expectedPrice1 = (uint256(r0) << 112) / uint256(r1);

        // The accumulator stores integral(price) over time => sum(price * dt).
        assertEq(p0After - p0Before, expectedPrice0 * dt, "price0 cumulative delta mismatch");
        assertEq(p1After - p1Before, expectedPrice1 * dt, "price1 cumulative delta mismatch");

        // Timestamp should update to the new warp time.
        (, , uint32 ts1) = pair.getReserves();
        assertEq(uint256(ts1), 1_000 + dt, "blockTimestampLast mismatch after second sync");
    }

    function test_TwapAccumulator_dtZero_noChange() public {
        uint256 amount0 = 100e18;
        uint256 amount1 = 200e18;

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        vm.warp(5_000);
        pair.sync();

        uint256 p0Before = pair.price0CumulativeLast();
        uint256 p1Before = pair.price1CumulativeLast();

        // Same timestamp => dt == 0.
        vm.warp(5_000);
        pair.sync();

        assertEq(pair.price0CumulativeLast(), p0Before, "p0 should not change when dt=0");
        assertEq(pair.price1CumulativeLast(), p1Before, "p1 should not change when dt=0");
    }
}
