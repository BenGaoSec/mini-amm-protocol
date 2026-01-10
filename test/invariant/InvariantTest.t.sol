// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/StdInvariant.sol";
import {PairFixture} from "test/fixtures/PairFixture.t.sol";
import {Handler} from "test/handlers/Handler.sol";

contract InvariantTest is StdInvariant, PairFixture {
    Handler public handler;

    function setUp() public override {
        super.setUp(); // Deploys pair, token0, token1 from Fixture
        handler = new Handler(pair, token0, token1);

        // Target the Handler, not the Pair directly
        targetContract(address(handler));
    }

    // INVARIANT 1: Global Solvency Check
    function invariant_balanceMatch() public {
        // Actual balance must be >= recorded ghost sum (due to fees/donations)
        assertGe(token0.balanceOf(address(pair)), handler.ghost_depositSum0(), "Solvency: Token0 leak");
        assertGe(token1.balanceOf(address(pair)), handler.ghost_depositSum1(), "Solvency: Token1 leak");
    }

    // INVARIANT 2: K-Constant "Soul" Check
    function invariant_K_Values() public {
        (uint112 r0, uint112 r1,) = pair.getReserves();

        // Live calculation of Current K
        uint256 currentK = uint256(r0) * uint256(r1);

        if (handler.ghost_kLast() > 0) {
            // Check against global baseline
            assertGe(currentK, handler.ghost_kLast(), "Global K-Violation");

            // Check against last swap snapshot
            if (handler.ghost_Swap_kLast() > 0) {
                assertGe(currentK, handler.ghost_Swap_kLast(), "Local Swap K-Violation");
            }
        }
    }

    // INVARIANT 3: Strict Accounting (Balance must equal Reserves)
    // This is what breaks when someone does a Direct Transfer (forcePush)

    function invariant_reserveMatch() public {
    (uint112 r0, uint112 r1, ) = pair.getReserves();
    uint256 b0 = token0.balanceOf(address(pair));
    uint256 b1 = token1.balanceOf(address(pair));
    if(r0>b0 || r1>b1) {
        console.log("--- CRITICAL FAILURE ---");
        console.log("Token0 Balance:", b0, "Reserve:", r0);
        console.log("Token1 Balance:", b1, "Reserve:", r1);
        fail();
    }

    assertGe(b0,r0,"Solvency : Token0 missing");
    assertGe(b1,r1,"Solvency : Token1 missing");
}
}
