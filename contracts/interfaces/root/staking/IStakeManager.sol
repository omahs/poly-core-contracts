// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../interfaces/root/staking/ISupernetManager.sol";

/**
    @title IStakeManager
    @author Polygon Technology (@gretzke)
    @notice Manages stakes for all child chains
 */
interface IStakeManager {
    event ChildManagerRegistered(uint256 indexed id, address indexed manager);
    event StakeAdded(
        uint256 indexed id,
        address indexed _staker,
        address indexed validator,
        address _token,
        uint256 amount
    );
    event StakeRemoved(uint256 indexed id, address indexed validator, address _token, uint256 amount);
    event StakeWithdrawn(address indexed validator, address indexed recipient, address _token, uint256 amount);
    event ValidatorSlashed(uint256 indexed id, address indexed validator, address _token, uint256 amount);

    /**
     * @notice registers a new child chain with the staking contract
     * Note: Anyone can register a child chain. Attackers registering child chains
     * that are never used is not an attack.
     *
     * @param _manager Child chain / supernet manager
     * @return _id of the child chain
     */
    function registerChildChain(address _manager) external returns (uint256 _id);

    /// @notice called by a staker to stake for a child chain
    function stakeFor(uint256 _id, address _validator, address _token, uint256 _amount) external;

    /// @notice called by child manager contract to release a validator's stake
    function releaseStakeOf(address _validator, address _token, uint256 _amount) external;

    /// @notice allows a validator to withdraw released stake
    function withdrawStake(address _to, address _token, uint256 _amount) external;

    /// @notice called by child manager contract to slash a validator's stake
    /// @notice manager collects slashed amount
    function slashStakeOf(address validator, uint256 amount) external;

    /// @notice returns the amount of stake a validator can withdraw
    // TODO needs to return an array of (token, amount)
    function withdrawableStake(address validator) external view returns (uint256 amount);

    /// @notice returns the total amount staked for all child chains
    // TODO needs to return array of (token, amount)
    function totalStake() external view returns (uint256 amount);

    /// @notice returns the total amount staked for a child chain
    // TODO needs to return array of (token, amount)
    function totalStakeOfChild(uint256 id) external view returns (uint256 amount);

    /// @notice returns the total amount staked of a validator for all child chains
    // TODO needs to return array of (token, amount)
    function totalStakeOf(address validator) external view returns (uint256 amount);

    /// @notice returns the amount staked by a validator for a child chain
    // TODO needs to return array of (token, amount)
    function stakeOf(address validator, uint256 id) external view returns (uint256 amount);

    /// @notice returns the child chain manager contract for a child chain
    function managerOf(uint256 id) external view returns (ISupernetManager manager);

    /// @notice returns the child id for a child chain manager contract
    function idFor(address manager) external view returns (uint256 id);
}
