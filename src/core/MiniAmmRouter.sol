// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMiniAmmFactory} from "../interfaces/IMiniAmmFactory.sol";
import {IMiniAmmPair} from "../interfaces/IMiniAmmPair.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

/// @title MiniAmmRouter
/// @notice UniswapV2-style router implementation.
contract MiniAmmRouter {
    using SafeTransferLib for address;

    // =============================================================
    //                           ERRORS
    // =============================================================
    error Expired();
    error IdenticalAddresses();
    error ZeroAddress();
    error PairNotFound();
    error InvalidPath();

    error InsufficientLiquidity();
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientAmount();
    error InsufficientOutputAmount();
    error ExcessiveInputAmount();

    // =============================================================
    //                          IMMUTABLES
    // =============================================================
    address public immutable factory;

    constructor(address _factory) {
        if (_factory == address(0)) revert ZeroAddress();
        factory = _factory;
    }

    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) revert Expired();
        _;
    }

    // =============================================================
    //                    EXTERNAL: LIQUIDITY
    // =============================================================

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // 1) Decide optimal deposit amounts
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        // 2) Pair must exist
        address pair = _pairFor(tokenA, tokenB);

        // 3) Move tokens to the Pair
        tokenA.safeTransferFrom(msg.sender, pair, amountA);
        tokenB.safeTransferFrom(msg.sender, pair, amountB);

        // 4) Mint LP to recipient
        liquidity = IMiniAmmPair(pair).mint(to);
        if (liquidity == 0) revert InsufficientLiquidity();
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        if (to == address(0)) revert ZeroAddress();

        address pair = _pairFor(tokenA, tokenB);

        // Map (amount0, amount1) -> (amountA, amountB)
        (address token0,) = _sortTokens(tokenA, tokenB);

        // Transfer LP into the pair, then burn
        pair.safeTransferFrom(msg.sender, pair, liquidity);

        // Burn returns amounts in (token0, token1) order
        (uint256 amount0, uint256 amount1) = IMiniAmmPair(pair).burn(to);

        // Map to caller's order
        (amountA, amountB) = (tokenA == token0) ? (amount0, amount1) : (amount1, amount0);

        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    // =============================================================
    //                      EXTERNAL: SWAPS
    // =============================================================

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        // 1. Calculate all amounts out along the path
        amounts = getAmountsOut(amountIn, path);
        
        // 2. Check slippage (minimum output)
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        
        // 3. Transfer the initial input token from user to the first pair
        // Note: The first pair needs specifically amounts[0] (which is amountIn)
        address pair = _pairFor(path[0], path[1]);
        path[0].safeTransferFrom(msg.sender, pair, amounts[0]);
        
        // 4. Execute the swap chain
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        // 1. Calculate all amounts in required along the path
        amounts = getAmountsIn(amountOut, path);
        
        // 2. Check slippage (maximum input)
        if (amounts[0] > amountInMax) revert ExcessiveInputAmount();
        
        // 3. Transfer the exact calculated input token from user to the first pair
        address pair = _pairFor(path[0], path[1]);
        path[0].safeTransferFrom(msg.sender, pair, amounts[0]);
        
        // 4. Execute the swap chain
        _swap(amounts, path, to);
    }

    // =============================================================
    //                     PUBLIC VIEW: AMOUNTS
    // =============================================================

    function getAmountsOut(uint256 amountIn, address[] calldata path) public view returns (uint256[] memory amounts) {
        if (path.length < 2) revert InvalidPath();
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path) public view returns (uint256[] memory amounts) {
        if (path.length < 2) revert InvalidPath();
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // =============================================================
    //                        PURE MATH (V2)
    // =============================================================

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public pure returns (uint256 amountB) {
        if (amountA == 0) revert InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        
        // Formula: y = (x * 997 * Y) / (X * 1000 + x * 997)
        // 0.3% fee means 99.7% of input is used for swap
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountIn)
    {
        if (amountOut == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        if (amountOut >= reserveOut) revert InsufficientLiquidity(); // Cannot swap entire pool or more

        // Formula: x = (X * y * 1000) / ((Y - y) * 997) + 1
        // We add 1 to round up, ensuring the pool doesn't lose dust
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        
        amountIn = (numerator / denominator) + 1;
    }

    // =============================================================
    //                         INTERNALS
    // =============================================================

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        if (IMiniAmmFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IMiniAmmFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = _getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @dev Internal function to execute the swap chain.
    /// Requires that the initial amount has already been sent to the first pair.
    function _swap(uint256[] memory amounts, address[] calldata path, address finalTo) internal {
        for (uint256 i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            
            // We need to know token0 to correctly assign amount0Out vs amount1Out
            (address token0,) = _sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            
            // If input == token0, we are swapping token0 -> token1, so amountOut is amount1Out
            (uint256 amount0Out, uint256 amount1Out) = input == token0 
                ? (uint256(0), amountOut) 
                : (amountOut, uint256(0));

            // Destination address: 
            // If it's the last pair in the path, send to `finalTo` (the user).
            // Otherwise, send to the *next pair* address.
            address to = i < path.length - 2 
                ? _pairFor(output, path[i + 2]) 
                : finalTo;

            // Trigger the swap on the Pair contract
            IMiniAmmPair(_pairFor(input, output)).swap(
                amount0Out, 
                amount1Out, 
                to, 
                new bytes(0) // empty data = no flash swap callback
            );
        }
    }

    function _pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        pair = IMiniAmmFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) revert PairNotFound();
    }

    function _getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        address pair = _pairFor(tokenA, tokenB);
        (address token0,) = _sortTokens(tokenA, tokenB);
        (uint112 r0, uint112 r1,) = IMiniAmmPair(pair).getReserves();
        (reserveA, reserveB) = (tokenA == token0) ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        if (tokenA == address(0) || tokenB == address(0)) revert ZeroAddress();
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}