// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/root/oracles/OracleReader.sol";

import "contracts/interfaces/root/IUniswapV3Pool.sol";

contract Pool is IUniswapV3Pool {
    uint160 _sqrtPriceX96;

    function setSqrtPriceX96(uint160 __sqrtPriceX96) external {
        _sqrtPriceX96 = __sqrtPriceX96;
    }

    function slot0()
        external
        view
        returns (
            // the current price
            uint160 sqrtPriceX96,
            // the current tick
            int24 tick,
            // the most-recently updated index of the observations array
            uint16 observationIndex,
            // the current maximum number of observations that are being stored
            uint16 observationCardinality,
            // the next maximum number of observations to store, triggered in observations.write
            uint16 observationCardinalityNext,
            // the current protocol fee as a percentage of the swap fee taken on withdrawal
            // represented as an integer denominator (1/x)%
            uint8 feeProtocol,
            // whether the pool is locked
            bool unlocked
        )
    {
        return (_sqrtPriceX96, 0, 0, 0, 0, 0, false);
    }
}


// Example script
contract imxMaticOracleTest is Test {
    OracleReader public oracleReader;
    Pool public ethImxPool;
    Pool public maticEthPool;
    // token0 is ETH
    // token1 is IMX
    uint160 public constant ETH_IMX_SQRTPRICE = 3960443678041354732387300076899;

    // token0 is MATIC
    // token1 is ETH
    uint160 public constant MATIC_ETH_SQRTPRICE = 1730902318910981910752958405;

    function setUp() public {
        ethImxPool = new Pool();
        maticEthPool = new Pool();
        oracleReader = new OracleReader(
            address(ethImxPool),
            18,
            false,
            address(maticEthPool),
            18,
            false
        );

        ethImxPool.setSqrtPriceX96(ETH_IMX_SQRTPRICE);
        maticEthPool.setSqrtPriceX96(MATIC_ETH_SQRTPRICE);
    }

    function testGetAmountOut() public view {
        uint256 amountOut = oracleReader.getAmountOutSpot(1e18);
        console.log("1 IMX costs %d/10^18 MATIC", amountOut);
    }
}
