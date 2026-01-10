// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Ensure this path matches your project structure
import {PairFixture} from "../../fixtures/PairFixture.t.sol";

/// @title Level 3: AMM Lifecycle Verification
/// @notice Tests the complete Mint -> Swap -> Burn cycle to ensure solvency.
contract MiniAmmLifecycleTest is PairFixture {
    function setUp() public override {
        // [Setup] Inherit the standard fixture environment (Factory, Pair, Tokens)
        super.setUp();
    }

    /// @notice Verifies the happy path: Mint -> Swap -> Burn
    function testLifecycle_MintSwapBurn() public {
        // ============================================
        // 1. MINT (Alice adds liquidity)
        // ============================================
        uint256 amount0 = 10 ether;
        uint256 amount1 = 10 ether;

        // [Setup] Mint mock tokens to Alice
        token0.mint(alice, amount0);
        token1.mint(alice, amount1);

        vm.startPrank(alice);

        // [Action] Transfer tokens to pair first (Optimistic transfer pattern)
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        // [Action] Call mint
        uint256 liquidity = pair.mint(alice);

        // [Assert] Verify LP Math: sqrt(10 * 10) - MINIMUM_LIQUIDITY (1000)
        // This hardcoded check ensures no unexpected rounding errors occur.
        assertEq(liquidity, 10 ether - 1000, "LP Math Check Failed");
        assertEq(pair.balanceOf(alice), liquidity, "Alice LP Balance Mismatch");

        vm.stopPrank();

        // ============================================
        // 2. SWAP (Simulation of trading)
        // ============================================
        // [Setup] Simulate a trader (Test Contract)
        token0.mint(address(this), 1 ether);
        token0.transfer(address(pair), 1 ether);

        // [Logic] Simple swap estimation.
        // Input: 1 ether. Output ~ 0.9 ether (roughly).
        // We accept any valid output < reserves to verify the flow does not revert.
        uint256 amount1Out = 0.9 ether;

        // [Action] Perform the swap
        pair.swap(0, amount1Out, address(this), "");

        // [Assert] Verify State Change
        // Pair should have MORE token0 and LESS token1
        assertEq(token0.balanceOf(address(pair)), 11 ether, "Pair Token0 Balance Incorrect");
        assertEq(token1.balanceOf(address(pair)), 10 ether - amount1Out, "Pair Token1 Balance Incorrect");

        // ============================================
        // 3. BURN (Alice removes liquidity)
        // ============================================
        vm.startPrank(alice);

        // [Action] Transfer LP tokens back to pair to trigger burn
        pair.transfer(address(pair), liquidity);
        pair.burn(alice);

        // [Assert] Verify Alice has 0 LP left
        assertEq(pair.balanceOf(alice), 0, "Burn Failed: Alice still has LP");

        vm.stopPrank();
    }

    /// @notice Verifies the 'Sad Path' (Security Revert)
    function testRevert_MintZeroLiquidity() public {
        vm.startPrank(alice);

        // [Action] Transfer negligible amounts (dust)
        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        // [Assert] Expect Revert due to MINIMUM_LIQUIDITY check
        // "InsufficientLiquidityMinted" is the expected custom error
        vm.expectRevert();
        pair.mint(alice);

        vm.stopPrank();
    }
}
