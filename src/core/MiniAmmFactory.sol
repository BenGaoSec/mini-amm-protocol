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


    // =============================================================
    //                     FEE PARAM ADMIN
    // =============================================================

  
}
