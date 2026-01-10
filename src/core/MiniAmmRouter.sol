// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMiniAmmFactory} from "../interfaces/IMiniAmmFactory.sol";
import {IMiniAmmPair} from "../interfaces/IMiniAmmPair.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

/// @title MiniAmmRouter (Scaffold)
/// @notice UniswapV2-style router scaffold for your MiniAmmFactory/MiniAmmPair.
/// @dev Everything is placeholder for now; replace bodies incrementally.
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

    /// @dev Placeholder for not-yet-implemented functions.
    error NotImplemented();

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
        // 1) Decide optimal deposit amounts that preserve current price (unless first liquidity).
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        // 2) Pair must exist now (may be created inside _addLiquidity).
        address pair = IMiniAmmFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) revert PairNotFound();

        // 3) Move tokens to the Pair; Pair.mint() will read balances and update reserves.
        tokenA.safeTransferFrom(msg.sender, pair, amountA);
        tokenB.safeTransferFrom(msg.sender, pair, amountB);

        // 4) Mint LP to recipient. Pair-level logic should ensure liquidity > 0.
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

        address pair = IMiniAmmFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) revert PairNotFound();

        // Needed only for mapping (amount0, amount1) -> (amountA, amountB)
        (address token0,) = _sortTokens(tokenA, tokenB);

        // In V2-style, LP token is the Pair itself (ERC20). Transfer LP into the pair, then burn.
        pair.safeTransferFrom(msg.sender, pair, liquidity);

        // Burn sends underlying tokens to `to` and returns amounts in (token0, token1) order.
        (uint256 amount0, uint256 amount1) = IMiniAmmPair(pair).burn(to);

        // Map to the caller's token order (A/B).
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
        // TODO: implement
        // - amounts = getAmountsOut(amountIn, path)
        // - require(last >= amountOutMin)
        // - transfer path[0] from msg.sender to firstPair
        // - _swap(amounts, path, to)
        amountIn;
        amountOutMin;
        path;
        to;
        amounts = new uint256[](path.length);
        revert NotImplemented();
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        // TODO: implement
        // - amounts = getAmountsIn(amountOut, path)
        // - require(amounts[0] <= amountInMax)
        // - transfer path[0] from msg.sender to firstPair
        // - _swap(amounts, path, to)
        amountOut;
        amountInMax;
        path;
        to;
        amounts = new uint256[](path.length);
        revert NotImplemented();
    }

    // =============================================================
    //                     PUBLIC VIEW: AMOUNTS
    // =============================================================

    function getAmountsOut(uint256 amountIn, address[] calldata path) public view returns (uint256[] memory amounts) {
        // TODO: implement using _getReserves + getAmountOut in a loop
        amountIn;
        path;
        revert NotImplemented();
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path) public view returns (uint256[] memory amounts) {
        // TODO: implement using _getReserves + getAmountIn in a reverse loop
        amountOut;
        path;
        revert NotImplemented();
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
        // TODO: implement (997/1000)
        amountIn;
        reserveIn;
        reserveOut;
        amountOut = 0;
        revert NotImplemented();
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountIn)
    {
        // TODO: implement (round up +1)
        amountOut;
        reserveIn;
        reserveOut;
        amountIn = 0;
        revert NotImplemented();
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

    function _swap(uint256[] memory amounts, address[] calldata path, address finalTo) internal {
        // TODO: implement multi-hop swap
        amounts;
        path;
        finalTo;
        revert NotImplemented();
    }

    function _pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        pair = IMiniAmmFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) revert PairNotFound();
    }

    function _getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        address pair = IMiniAmmFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) revert PairNotFound();
        (address token0,) = _sortTokens(tokenA, tokenB);
        (uint112 r0, uint112 r1,) = IMiniAmmPair(pair).getReserves();
        (reserveA, reserveB) = (tokenA == token0) ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        if (tokenA == address(0) || tokenB == address(0)) revert ZeroAddress();
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    // =============================================================
    //                OPTIONAL: TRANSFER HELPERS (PLACEHOLDER)
    // =============================================================

    function _transferToPair(address token, address from, address pair, uint256 amount) internal {
        // TODO: implement with SafeTransferLib.safeTransferFrom
        token;
        from;
        pair;
        amount;
        revert NotImplemented();
    }
}
