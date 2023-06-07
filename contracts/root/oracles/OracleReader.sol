// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/interfaces/root/IUniswapV3Pool.sol";
import "contracts/lib/FullMath.sol";

contract OracleReader {
    struct SwapInfo {
        address poolAddress;
        uint8 decimalsToken0;
        bool zeroForOne;
    }

    SwapInfo public firstSwapInfo;
    SwapInfo public secondSwapInfo;

    constructor(
        address firstPool,
        uint8 firstDecimalsToken0,
        bool firstZeroForOne,
        address secondPool,
        uint8 secondDecimalsToken0,
        bool secondZeroForOne
    ) {
        firstSwapInfo = SwapInfo(firstPool, firstDecimalsToken0, firstZeroForOne);
        secondSwapInfo = SwapInfo(secondPool, secondDecimalsToken0, secondZeroForOne);
    }

    function getAmountOutSpot(uint256 amountIn) external view returns (uint256 amountOut) {
        SwapInfo memory _firstSwapInfo = firstSwapInfo;
        SwapInfo memory _secondSwapInfo = secondSwapInfo;
        IUniswapV3Pool pool1 = IUniswapV3Pool(_firstSwapInfo.poolAddress);
        IUniswapV3Pool pool2 = IUniswapV3Pool(_secondSwapInfo.poolAddress);

        // First swap
        (uint160 sqrtPriceX96, , , , , , ) = pool1.slot0();
        uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 numerator2 = 10 ** _firstSwapInfo.decimalsToken0;
        uint256 token0Price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);

        if (_firstSwapInfo.zeroForOne) {
            amountOut = (amountIn * token0Price) / 1e18;
        } else {
            uint256 token1Price = 1e18 ** 2 / token0Price;
            amountOut = (amountIn * token1Price) / 1e18;
        }

        // Second swap
        (sqrtPriceX96, , , , , , ) = pool2.slot0();
        numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        numerator2 = 10 ** _secondSwapInfo.decimalsToken0;
        token0Price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        if (_secondSwapInfo.zeroForOne) {
            // This is the amount we get out
            amountOut = (amountOut * token0Price) / 1e18;
        } else {
            uint256 token1Price = 1e18 ** 2 / token0Price;
            amountOut = (amountOut * token1Price) / 1e18;
        }
    }
}
