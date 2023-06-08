// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    @title IStakeManager
    @notice Interface for determining exchange rates.
 */
interface IExchangeRate {
    error TokenNotSupported(address _token);

    /// @notice returns the value denominated in base tokens.
    function convert(address _token, uint256 _amount) external view returns (uint256 _baseAmount);

    /// @notice returns true if the token is supported
    function tokenSupported(address _token) external view returns (bool);
}
