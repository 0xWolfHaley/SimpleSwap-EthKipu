// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleSwap
 * @author Juan Cruz Gonzalez
 * @notice This contract allows users to add liquidity to a token pair and receive LP tokens, remove liquidity to get back their tokens, and swap between tokens in the pool.
 * @dev Implements a basic constant product automated market maker (AMM) similar to Uniswap V2.
 */
contract SimpleSwap is ERC20 {

    // ============================================================================
    // STRUCTS
    // ============================================================================

    /**
     * @notice Structure for storing token reserves in the pool
     * @param reserveA Reserve amount of the first token (token0)
     * @param reserveB Reserve amount of the second token (token1)
     */
    struct Pool {
        uint256 reserveA;
        uint256 reserveB;
    }

    // ============================================================================
    // STATE VARIABLES
    // ============================================================================

    /**
     * @notice Mapping to store reserves of each token pair
     * @dev Maps token0 address to token1 address to Pool struct
     */
    mapping(address => mapping(address => Pool)) public pools;

    // ============================================================================
    // EVENTS
    // ============================================================================

    /**
     * @notice Emitted when liquidity is added to a pool
     * @param provider The address providing liquidity
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param amountA Amount of tokenA added
     * @param amountB Amount of tokenB added
     * @param liquidity Amount of LP tokens minted
     */
    event LiquidityAdded(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    /**
     * @notice Emitted when liquidity is removed from a pool
     * @param provider The address removing liquidity
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param amountA Amount of tokenA received
     * @param amountB Amount of tokenB received
     * @param liquidity Amount of LP tokens burned
     */
    event LiquidityRemoved(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    /**
     * @notice Emitted when a swap occurs
     * @param sender The address initiating the swap
     * @param tokenIn Token being swapped in
     * @param tokenOut Token being swapped out
     * @param amountIn Amount of tokenIn
     * @param amountOut Amount of tokenOut
     */
    event Swap(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @notice Initializes the contract, setting the name and symbol for the LP token
     */
    constructor() ERC20("SimpleSwap Liquidity Token", "SSLP") {}

    // ============================================================================
    // EXTERNAL FUNCTIONS
    // ============================================================================

    /**
     * @notice Adds liquidity to a token pair pool
     * @dev Mints LP tokens proportional to the liquidity added
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param amountADesired Desired amount of tokenA to add
     * @param amountBDesired Desired amount of tokenB to add
     * @param amountAMin Minimum amount of tokenA to add (slippage protection)
     * @param amountBMin Minimum amount of tokenB to add (slippage protection)
     * @param to Address to receive the LP tokens
     * @param deadline Deadline for the transaction
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(deadline >= block.timestamp, "SimpleSwap: EXPIRED");
        require(tokenA != tokenB, "SimpleSwap: IDENTICAL_ADDRESSES");
        require(tokenA != address(0) && tokenB != address(0), "SimpleSwap: ZERO_ADDRESS");
        
        (amountA, amountB) = _calculateLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        
        _safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        _safeTransferFrom(tokenB, msg.sender, address(this), amountB);
        
        Pool storage pool = pools[tokenA][tokenB];
        uint256 totalSupply = totalSupply();
        
        if (totalSupply == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(
                (amountA * totalSupply) / pool.reserveA,
                (amountB * totalSupply) / pool.reserveB
            );
        }
        
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);
        
        pool.reserveA += amountA;
        pool.reserveB += amountB;
        
        emit LiquidityAdded(to, tokenA, tokenB, amountA, amountB, liquidity);
    }

    /**
     * @notice Removes liquidity from a token pair pool
     * @dev Burns LP tokens and returns the underlying assets
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive (slippage protection)
     * @param amountBMin Minimum amount of tokenB to receive (slippage protection)
     * @param to Address to receive the underlying tokens
     * @param deadline Deadline for the transaction
     * @return amountA Actual amount of tokenA received
     * @return amountB Actual amount of tokenB received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(deadline >= block.timestamp, "SimpleSwap: EXPIRED");
        require(tokenA != tokenB, "SimpleSwap: IDENTICAL_ADDRESSES");
        require(tokenA != address(0) && tokenB != address(0), "SimpleSwap: ZERO_ADDRESS");
        
        Pool storage pool = pools[tokenA][tokenB];
        uint256 totalSupply = totalSupply();
        
        amountA = (liquidity * pool.reserveA) / totalSupply;
        amountB = (liquidity * pool.reserveB) / totalSupply;
        
        require(amountA >= amountAMin, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");
        
        _burn(msg.sender, liquidity);
        
        pool.reserveA -= amountA;
        pool.reserveB -= amountB;
        
        _safeTransfer(tokenA, to, amountA);
        _safeTransfer(tokenB, to, amountB);
        
        emit LiquidityRemoved(to, tokenA, tokenB, amountA, amountB, liquidity);
    }

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible
     * @dev Executes a series of swaps along the specified path
     * @param amountIn Exact amount of input tokens to swap
     * @param amountOutMin Minimum amount of output tokens to receive (slippage protection)
     * @param path Array of token addresses representing the swap path
     * @param to Address to receive the output tokens
     * @param deadline Deadline for the transaction
     * @return amounts Array of amounts at each step of the swap path
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline >= block.timestamp, "SimpleSwap: EXPIRED");
        require(path.length >= 2, "SimpleSwap: INVALID_PATH");
        
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        
        for (uint256 i; i < path.length - 1; i++) {
            (address tokenIn, address tokenOut) = (path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], tokenIn, tokenOut);
        }
        
        require(amounts[amounts.length - 1] >= amountOutMin, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        
        _safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        
        for (uint256 i; i < path.length - 1; i++) {
            (address tokenIn, address tokenOut) = (path[i], path[i + 1]);
            _swap(tokenIn, tokenOut, amounts[i], amounts[i + 1], to);
        }
    }

    /**
     * @notice Gets the price ratio between two tokens in a pool
     * @dev Price is calculated as reserveB/reserveA with 18 decimals precision
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @return price Price ratio of tokenB to tokenA
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        Pool memory pool = pools[tokenA][tokenB];
        require(pool.reserveA > 0 && pool.reserveB > 0, "SimpleSwap: NO_LIQUIDITY");
        price = (pool.reserveB * 1e18) / pool.reserveA;
    }

    // ============================================================================
    // PUBLIC FUNCTIONS
    // ============================================================================

    /**
     * @notice Calculates the amount of output tokens for a given input
     * @param amountIn Amount of input tokens
     * @param tokenIn Address of input token
     * @param tokenOut Address of output token
     * @return amountOut Amount of output tokens
     */
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 amountOut) {
        Pool memory pool;
        uint256 reserveIn;
        uint256 reserveOut;
        
        if (tokenIn < tokenOut) {
            pool = pools[tokenIn][tokenOut];
            reserveIn = pool.reserveA;
            reserveOut = pool.reserveB;
        } else {
            pool = pools[tokenOut][tokenIn];
            reserveIn = pool.reserveB;
            reserveOut = pool.reserveA;
        }
        
        require(reserveIn > 0 && reserveOut > 0, "SimpleSwap: NO_LIQUIDITY");
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    // ============================================================================
    // INTERNAL FUNCTIONS
    // ============================================================================

    /**
     * @notice Calculates optimal amounts of tokens to add to a pool
     * @dev Ensures the added liquidity maintains the current pool ratio
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param amountADesired Desired amount of tokenA
     * @param amountBDesired Desired amount of tokenB
     * @param amountAMin Minimum acceptable amount of tokenA
     * @param amountBMin Minimum acceptable amount of tokenB
     * @return amountA Calculated optimal amount of tokenA
     * @return amountB Calculated optimal amount of tokenB
     */
    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        Pool memory pool = pools[tokenA][tokenB];
        
        if (pool.reserveA == 0 && pool.reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = (amountADesired * pool.reserveB) / pool.reserveA;
            
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * pool.reserveA) / pool.reserveB;
                require(amountAOptimal >= amountAMin, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @notice Executes a token swap between two pools
     * @dev Updates reserves and emits a Swap event
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @param amountOut Amount of output tokens
     * @param to Recipient address
     */
    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address to
    ) internal {
        if (tokenIn < tokenOut) {
            pools[tokenIn][tokenOut].reserveA += amountIn;
            pools[tokenIn][tokenOut].reserveB -= amountOut;
        } else {
            pools[tokenOut][tokenIn].reserveB += amountIn;
            pools[tokenOut][tokenIn].reserveA -= amountOut;
        }
        
        _safeTransfer(tokenOut, to, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /**
     * @notice Calculates the output amount for a given input and reserves
     * @dev Implements the constant product formula with 0.3% fee
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve of input token
     * @param reserveOut Reserve of output token
     * @return amountOut Calculated amount of output tokens
     */
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @notice Safely transfers tokens from one address to another
     * @param token Token to transfer
     * @param to Recipient address
     * @param value Amount to transfer
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SimpleSwap: TRANSFER_FAILED");
    }

    /**
     * @notice Safely transfers tokens from one address to another
     * @param token Token to transfer
     * @param from Source address
     * @param to Recipient address
     * @param value Amount to transfer
     */
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SimpleSwap: TRANSFER_FROM_FAILED");
    }

    // ============================================================================
    // PURE FUNCTIONS
    // ============================================================================

    /**
     * @notice Calculates the square root of a number
     * @dev Babylonian method for square root approximation
     * @param y Number to calculate square root of
     * @return z Square root of y
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @notice Returns the smaller of two numbers
     * @param a First number
     * @param b Second number
     * @return The smaller of a and b
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}