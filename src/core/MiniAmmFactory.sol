// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMiniAmmFactory } from "../interfaces/IMiniAmmFactory.sol";
import { IMiniAmmPair } from "../interfaces/IMiniAmmPair.sol";
import { MiniAmmPair } from "./MiniAmmPair.sol";

/// @title MiniAmmFactory
/// @notice Deploys MiniAmmPair contracts and tracks them (Uniswap V2 style)
contract MiniAmmFactory is IMiniAmmFactory {
    // =============================================================
    //                           ERRORS
    // =============================================================
    error IdenticalAddresses();
    error ZeroAddress();
    error PairExists();
    error Forbidden();

    // =============================================================
    //                           STORAGE
    // =============================================================
    /// @dev Mapping to look up pair by ordered tokens; getPair[token0][token1] => Pair
    mapping(address =>mapping(address => address)) public override getPair;
    /// @dev enumerate all pairs
    address[] public override allPairs;
    /// @inheritdoc IMiniAmmFactory
    address public override feeTo;
    /// @inheritdoc IMiniAmmFactory
    address public override feeToSetter;
    

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================
        constructor(address _feeToSetter) {
        // If you prefer msg.sender as admin, just pass msg.sender in deployment script.
        if(_feeToSetter == address(0)) revert ZeroAddress();
        feeToSetter = _feeToSetter;
    }


    // =============================================================
    //                          VIEW
    // =============================================================

    function allPairsLength() external view override returns (uint256){
        return allPairs.length;
    }

    /// @notice Convenience helper: Pair init code hash (useful for offchain address precompute)
    function pairCodeHash() external pure returns(bytes32){
        return keccak256(type(MiniAmmPair).creationCode);
    }

    // =============================================================
    //                         CREATE PAIR
    // =============================================================
    function createPair(address tokenA, address tokenB) external override returns (address pair){
        if(tokenA == tokenB) revert IdenticalAddresses();
        if(tokenA == address(0) || tokenB == address(0)) revert ZeroAddress();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB ) :(tokenB, tokenA);
        if(getPair[token0][token1] != address(0)) revert PairExists();
        bytes32 salt = keccak256(abi.encodePacked(token0,token1));
        //Deploy pair deterministically with CREATE2
        pair = address(new MiniAmmPair{salt : salt}());
        // Initialize
        IMiniAmmPair(pair).initialize(token0,token1);
        //BookKeeping in both direction
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // =============================================================
    //                     FEE PARAM ADMIN
    // =============================================================

    function setFeeTo(address _feeTo) external override {
        if(msg.sender != feeToSetter) revert Forbidden();
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override{
        if(msg.sender != feeToSetter) revert Forbidden();
        if(_feeToSetter == address(0)) revert ZeroAddress();
        feeToSetter = _feeToSetter;
    }


}
