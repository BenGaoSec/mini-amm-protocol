// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMiniAmmPool } from '../interfaces/IMiniAmmPool.sol';
import { IERC20Minimal } from '../interfaces/IERC20Minimal.sol';
import { AmmMath } from '../libraries/AmmMath.sol';
import { SafeTransferLib } from '../libraries/SafeTransferLib.sol';
import { ReentrancyGuard } from '../libraries/ReentrancyGuard.sol';

/// @title MiniAmmPool - x*y=k AMM for two ERC20 tokens
/// @notice Learning / internal project, NOT production-ready
contract MiniAmmPool is IMiniAmmPool, ReentrancyGuard {
    // ==========
    //  Errors
    // ==========
    // TODO: define custom errors (e.g., InsufficientLiquidity, InvalidAmount, etc.)

    // ==========
    //  Events
    // ==========
    // TODO: Mint, Burn, Swap, Sync
    event Transfer(address indexed from, address to, uint256 value);
    event Approval(address indexed owner, address spender, uint256 value);

    // ==========
    //  Immutable config
    // ==========
    // TODO: addresses of token0, token1
    // TODO: optionally fee parameters

    // ==========
    //  Storage - reserves & LP accounting
    // ==========

    string public constant name = 'MINI-AMM-LP';
    string public constant symbol = 'MLP';
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // ==========
    //  Constructor
    // ==========
    // TODO: set token addresses, sanity checks

    // ==========
    //  External view functions
    // ==========
    // TODO: getReserves()
    // TODO: totalSupply()
    // TODO: balanceOf(address account)
    // TODO: quote functions (optional)

    // ==========
    //  Core external actions
    // ==========

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // addLiquidity
    // removeLiquidity
    // swap

    /**  This fuction is design for user to add Liquidity.
        The first thing is to make sure is this the fisrt LP
        If this is the first LP, there are has to be Two different token.
        The two token will decide the ratio and K.
        If it is not the total supply is not empty, it ok for user to send only one token,
        but I have to use code to split the token in two token by swap? 
        but if the customer send two token with random amount is also cannot accpet.
        And I have make sure the two token is belong to this pool
        The User also give the  amount0Min, Why? add liquidity also has a slippage?   */
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1, uint256 liquidity) {}

    function removeLiquidity(
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1) {
        // TODO: implement according to flowchart
    }

    function swap(
        uint256 amountIn,
        uint256 minAmountOut,
        bool zeroForOne,
        address to
    ) external returns (uint256 amountOut) {
        // TODO: implement according to flowchart
    }

    // ==========
    //  Internal helpers
    // ==========
    // _updateReserves
    // _mintLiquidity
    // _burnLiquidity
    // _getAmountOut (thin wrapper around library)
    // _safeTransfer / _safeTransferFrom

    // TODO: internal helper stubs only, no logic yet
}
