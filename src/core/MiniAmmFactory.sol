// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMiniAmmFactory} from "../interfaces/IMiniAmmFactory.sol";
import {IMiniAmmPair} from "../interfaces/IMiniAmmPair.sol";
import {MiniAmmPair} from "./MiniAmmPair.sol";

/// @title MiniAmmFactory
/// @notice UniswapV2-style factory: CREATE2 deploy pairs, tracks getPair/allPairs, protocol fee config.
contract MiniAmmFactory is IMiniAmmFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor() {
        feeToSetter = msg.sender;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        require(tokenA != address(0) && tokenB != address(0), "ZERO_ADDRESS");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new MiniAmmPair{salt: salt}());

        IMiniAmmPair(pair).initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        require(_feeToSetter != address(0), "FEE_SETTER_ZERO");
        feeToSetter = _feeToSetter;
    }
}
