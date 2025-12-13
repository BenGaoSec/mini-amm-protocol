// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///@title IMiniAmmFactory
///@notice Factory interface for deploying and tracking MiniAMM pair contracts(Uniswap v2 sytle)
interface IMiniAMMfactory{
    // =============================================================
    //                            EVENTS
    // =============================================================

    ///@notice Emitted when a new pair is created
    ///@dev Mirrors Uniswap v2's PairPreated event shape for familiarity
    event PairCreated (
        address indexed token0,
        address indexed token1,
        address pair,
        uint256 allPairsLength
    );

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================
    /// @notice Returns the pair address for tokenA/tokenB, or address(0) if not created
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    
    /// @notice Returns the pair address at index
    function allPair(uint256 index) external view returns(address pair);

    /// @notice Returns total number of pairs created by this factory
    function allPairsLength() external view returns(uint256);

    // =============================================================
    //                      PROTOCOL PARAMETERS
    // =============================================================

    /// @notice Address that receives protocol fees (if enabled in your Pair implementation)
    function feeTo() external view returns (address);

    /// @notice Admin address allowed to update feeTo / feeToSetter
    function feeToSetter() external view returns (address);
    // =============================================================
    //                      STATE-CHANGING
    // =============================================================

    /// @notice Creates a new pair for tokenA/tokenB (order-agnostic)
    /// @dev Should revert if tokenA == tokenB, tokenA/tokenB is zero, or pair already exists
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /// @notice Sets protocol fee recipient
    /// @dev Typically restricted to feeToSetter
    function setFeeTo(address _feeTo) external;

    /// @notice Sets the admin for fee parameters
    /// @dev Typically restricted to current feeToSetter
    function setFeeToSetter(address _feeToSetter) external;
}