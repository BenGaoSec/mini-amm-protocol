// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// Adjust this import path to your project:
import {MiniAmmPair} from "../src/core/MiniAmmPair.sol";

/// @dev Minimal ERC20 mock for this test:
/// - mint() for giving balances
/// - transfer() + balanceOf() used by your Pair
contract ERC20Mock {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;

    constructor(string memory n, string memory s) {
        name = n;
        symbol = s;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "BAL");
        unchecked {
            balanceOf[msg.sender] -= amount;
            balanceOf[to] += amount;
        }
        return true;
    }
}

contract MiniAmmPairMintTest is Test {
    MiniAmmPair pair;
    ERC20Mock token0;
    ERC20Mock token1;

    address alice = address(0xA11CE);

    function setUp() external {
        token0 = new ERC20Mock("Token0", "T0");
        token1 = new ERC20Mock("Token1", "T1");

        // When deployed, pair.factory = msg.sender, i.e. THIS test contract address
        pair = new MiniAmmPair();

        // Initialize tokens
        pair.initialize(address(token0), address(token1));
    }

    function testMintBasic() external {
        uint256 amount0 = 1e18;
        uint256 amount1 = 1e18;

        // Give Alice tokens
        token0.mint(alice, amount0);
        token1.mint(alice, amount1);

        // Alice transfers tokens INTO the pair, then calls mint
        vm.startPrank(alice);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);

        uint256 liquidity = pair.mint(alice);
        vm.stopPrank();

        // --- Assertions ---
        assertGt(liquidity, 0, "liquidity should be > 0");
        assertEq(pair.balanceOf(alice), liquidity, "alice LP balance mismatch");

        // Reserves should match actual balances after mint
        (uint112 r0, uint112 r1, uint32 ts) = pair.getReserves();
        assertEq(uint256(r0), amount0, "reserve0 mismatch");
        assertEq(uint256(r1), amount1, "reserve1 mismatch");
        assertTrue(ts != 0, "blockTimestampLast should be set");

        // If you implement MINIMUM_LIQUIDITY lock like UniswapV2,
        // then totalSupply == liquidity + MINIMUM_LIQUIDITY and balanceOf(address(0)) == MINIMUM_LIQUIDITY.
        // Uncomment these only after you allow _mint(address(0), MINIMUM_LIQUIDITY).
        //
        // uint256 MIN_LIQ = pair.MINIMUM_LIQUIDITY();
        // assertEq(pair.balanceOf(address(0)), MIN_LIQ, "min liquidity not locked");
        // assertEq(pair.totalSupply(), liquidity + MIN_LIQ, "totalSupply mismatch");
    }
}
