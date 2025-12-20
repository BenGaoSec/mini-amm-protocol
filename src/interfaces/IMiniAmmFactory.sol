// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Factory interface (UniswapV2-style)
interface IMiniAmmFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 allPairsLength);

    // views
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256 index) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    // actions
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address _feeTo) external;
    function setFeeToSetter(address _feeToSetter) external;
}
