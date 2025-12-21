// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMiniAmmPair} from "../interfaces/IMiniAmmPair.sol";
import {IMiniAmmFactory} from "../interfaces/IMiniAmmFactory.sol";
import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";
import {IMiniAmmCallee} from "../interfaces/IMiniAmmCallee.sol";
import {AmmMath} from "../libraries/AmmMath.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";
import {ReentrancyGuard} from "../libraries/ReentrancyGuard.sol";
import {UQ112x112} from "../libraries/UQ112x112.sol";

/// @title MiniAmmPair
/// @notice UniswapV2-style Pair core (mint/burn/swap/sync/skim).
/// @dev Learning contract. Not production-ready.
contract MiniAmmPair is IMiniAmmPair, ReentrancyGuard {
    using AmmMath for uint256;
    using UQ112x112 for uint224;

    // =============================================================
    //                           CUSTOM ERRORS
    // =============================================================

    error Forbidden();
    error AlreadyInitialized();
    error ZeroAddress();
    error IdenticalAddresses();
    error InvalidTo();
    error InsufficientLiquidity();
    error InsufficientInputAmount();
    error InsufficientOutputAmount();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error Slippage();
    error KInvariant();
    error ReservesOverflow();
    error InsufficientAllowance();
    error InsufficientBalance();

    /// @dev Used for functions that are intentionally left as stubs for now.
    error NotImplemented();

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    string public constant name = "MINI-AMM-LP";
    string public constant symbol = "MLP";
    uint8 public constant decimals = 18;

    uint256 public constant MINIMUM_LIQUIDITY = 1_000;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @dev Factory is set at deployment time (UniswapV2 pattern).
    address public immutable factory;

    address public token0;
    address public token1;

    /// @dev Reserves are kept in a single storage slot (two uint112 + one uint32 timestamp).
    uint112 private reserve0; // accessible via getReserves()
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    /// @dev Optional TWAP accumulators (UniswapV2-style).
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    bool private initialized;
    // =============================================================
    //                           MODIFIER
    // =============================================================
    modifier onlyFactory() {
        if (msg.sender != factory) revert Forbidden();
        _;
    }

    // =============================================================
    //                        LP ERC20 STORAGE
    // =============================================================

    /// @dev Public state variables auto-satisfy the interface getters.
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // =============================================================
    //                         CONSTRUCTOR/INIT
    // =============================================================

    constructor() {
        factory = msg.sender;
    }

    /// @notice Called once by the factory right after CREATE2 deployment.
    function initialize(address _token0, address _token1) external override onlyFactory {
        if (initialized) revert AlreadyInitialized();
        if (_token0 == address(0) || _token1 == address(0)) revert ZeroAddress();

        token0 = _token0;
        token1 = _token1;

        initialized = true;
    }

    // =============================================================
    //                           VIEWS
    // =============================================================

    /// @notice Returns reserves and last block timestamp (uint32) used for TWAP/cumulative price logic.
    function getReserves()
        external
        view
        override
        returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast)
    {
        return (reserve0, reserve1, blockTimestampLast);
    }

    // =============================================================
    //                         LP ERC20 LOGIC
    // =============================================================

    function approve(address spender, uint256 value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        // Standard ERC20 behavior: if allowance is max uint256, treat as infinite.
        if (allowed != type(uint256).max) {
            if (allowed < value) revert InsufficientAllowance();
            unchecked {
                allowance[from][msg.sender] = allowed - value;
            }
            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }

        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (to == address(0)) revert ZeroAddress();

        uint256 bal = balanceOf[from];
        if (bal < value) revert InsufficientBalance();

        unchecked {
            balanceOf[from] = bal - value;
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        if (to == address(0) && value != MINIMUM_LIQUIDITY) revert ZeroAddress();

        totalSupply += value;
        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        uint256 bal = balanceOf[from];
        if (bal < value) revert InsufficientBalance();

        unchecked {
            balanceOf[from] = bal - value;
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }

    // =============================================================
    //                           CORE AMM
    // =============================================================

    /// @notice Placeholder. Implement later (LP minting logic).
    function mint(address to) external override returns (uint256 liquidity) {
        if (to == address(0)) revert ZeroAddress();
        uint112 _reserve0 = reserve0;
        uint112 _reserve1 = reserve1;
        uint256 balance0 = IERC20Minimal(token0).balanceOf(address(this));
        uint256 balance1 = IERC20Minimal(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - uint256(_reserve0);
        uint256 amount1 = balance1 - uint256(_reserve1);
        if (amount0 == 0 || amount1 == 0) revert InsufficientInputAmount();
        uint256 _totolSupply = totalSupply;
        if (_totolSupply == 0) {
            //calculate the liquidity
            uint256 rootK = AmmMath.sqrt(amount0 * amount1);
            liquidity = rootK - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
            _mint(to, liquidity);
        } else {
            uint256 liquidity0 = (amount0 * _totolSupply) / _reserve1;
            uint256 liquidity1 = (amount1 * _totolSupply) / _reserve0;

            liquidity = AmmMath.min(liquidity0, liquidity1);
            if (liquidity == 0) revert InsufficientLiquidityMinted();
            _mint(to, liquidity);
        }
        // Update reserves + TWAP accumulators, then emit Mint
        _upadate(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @notice Placeholder. Implement later (LP burning logic).
    function burn(
        address /*to*/
    )
        external
        override
        returns (
            uint256, /*amount0*/
            uint256 /*amount1*/
        )
    {
        revert NotImplemented();
    }

    /// @notice Placeholder. Implement later (swap + optional flash swap callback).
    function swap(
        uint256,
        /*amount0Out*/
        uint256,
        /*amount1Out*/
        address,
        /*to*/
        bytes calldata /*data*/
    )
        external
        override
    {
        revert NotImplemented();
    }

    /// @notice Transfers any token balances above the stored reserves to `to`.
    /// @dev Useful for recovering accidental transfers; does not update reserves.
    function skim(address to) external override {
        if (to == address(0)) revert ZeroAddress();

        uint256 bal0 = IERC20Minimal(token0).balanceOf(address(this));
        uint256 bal1 = IERC20Minimal(token1).balanceOf(address(this));

        uint256 r0 = uint256(reserve0);
        uint256 r1 = uint256(reserve1);

        if (bal0 > r0) {
            uint256 excess0 = bal0 - r0;
            bool ok0 = IERC20Minimal(token0).transfer(to, excess0);
            require(ok0, "T0_TRANSFER_FAIL");
        }

        if (bal1 > r1) {
            uint256 excess1 = bal1 - r1;
            bool ok1 = IERC20Minimal(token1).transfer(to, excess1);
            require(ok1, "T1_TRANSFER_FAIL");
        }
    }

    /// @notice Updates reserves to match current balances and updates TWAP accumulators.
    function sync() external override {
        // Read balances and update the stored reserves.
        uint256 balance0 = IERC20Minimal(token0).balanceOf(address(this));
        uint256 balance1 = IERC20Minimal(token1).balanceOf(address(this));

        _upadate(balance0, balance1, reserve0, reserve1);
    }

    /// @dev Updates reserves + blockTimestampLast and accumulates price * timeElapsed for TWAP.
    ///      Uses the OLD reserves for price accumulation, then writes the NEW reserves.
    function _upadate(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) internal {
        // 1) Bounds check BEFORE narrowing (prevents silent truncation).
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) revert ReservesOverflow();

        // 2) Timestamp compression to uint32 (mod 2^32).
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);

        // 3) TWAP hook: accumulate using OLD reserves and time elapsed.
        unchecked {
            // uint32 wrap-around is intentional and matches UniswapV2 behavior.
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;

            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // Fixed-point price in UQ112x112:
                // price0 = (reserve1 << 112) / reserve0, price1 = (reserve0 << 112) / reserve1
                uint256 price0 = (uint256(_reserve1) << 112) / uint256(_reserve0);
                uint256 price1 = (uint256(_reserve0) << 112) / uint256(_reserve1);

                // Accumulate integral(price) over time: sum(price * dt).
                price0CumulativeLast += price0 * uint256(timeElapsed);
                price1CumulativeLast += price1 * uint256(timeElapsed);
            }
        }

        // 4) Commit NEW reserves to storage.
        uint112 newReserve0 = uint112(balance0);
        uint112 newReserve1 = uint112(balance1);

        reserve0 = newReserve0;
        reserve1 = newReserve1;
        blockTimestampLast = blockTimestamp;

        // 5) Emit NEW reserves.
        emit Sync(newReserve0, newReserve1);
    }

    // =============================================================
    //                           INTERNALS
    // =============================================================
}
