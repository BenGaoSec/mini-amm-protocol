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




}