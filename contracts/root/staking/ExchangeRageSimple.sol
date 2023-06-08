// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/root/staking/IExchangeRate.sol";

/**
    @title ExchangeRateSimple
    @notice Determine value in base token based on an amount of other tokens.
     TODO: Allow for one to one ratios.
     TODO: Allow rate to be set.

     TODO: This contract is not intended to be extended.
 */
contract ExchangeRateSimple is IExchangeRate {
    // mapping of address of ERC 20 to bool indicating whether the token is supported.
    mapping(address => bool) internal supportedToken;
    address internal baseStakingToken;

    // TODO initializer not found
    //    function initialize(address _imxToken, address _maticToken) external initializer {
    function initialize(address _imxToken, address _maticToken) external {
        baseStakingToken = _imxToken;
        supportedToken[_imxToken] = true;
        supportedToken[_maticToken] = true;
    }

    /**
     * @inheritdoc IExchangeRate
     */
    function convert(address _token, uint256 _amount) external view returns (uint256 _baseAmount) {
        if (_token == baseStakingToken) {
            return _amount;
        }
        if (supportedToken[_token]) {
            // For the moment, everything is one to one.
            return _amount;
        }
        revert TokenNotSupported(_token);
    }

    /**
     * @inheritdoc IExchangeRate
     */
    function tokenSupported(address _token) external view returns (bool) {
        return supportedToken[_token];
    }
}
