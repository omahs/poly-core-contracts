// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../interfaces/root/staking/ICustomSupernetManager.sol";

/**
    @title IStakeManager
    @author Polygon Technology (@gretzke) / and significantly reworked by Peter Robinson 
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

    /**
     * @notice called by a staker to stake for a child chain. That is, msg.sender is the staker.
     *
     * @param _id Child chain identifier.
     * @param _validator Validator to allocate stake to.
     * @param _token ERC 20 token to stake.
     * @param _amount Number of tokens to stake.
     */
    function stakeFor(uint256 _id, address _validator, address _token, uint256 _amount) external;

    /// @notice called by child manager contract to release a validator's stake
    function releaseStakeOf(address _validator, address _token, uint256 _amount) external;

    /// @notice allows a validator to withdraw released stake
    function withdrawStake(address _to, address _token, uint256 _amount) external;

    /// @notice called by child manager contract to slash a validator's stake
    /// @notice manager collects slashed amount
    function slashStakeOf(address validator, uint256 amount) external;

    /**
     * Indicate if a validator is registered for a child chain.
     *
     * @param _id Child chain id.
     * @param _validator Address of validator.
     */
    function isValidatorRegistered(uint256 _id, address _validator) external view returns (bool);

    /// @notice returns the amount of stake a validator can withdraw
    // TODO needs to return an array of (token, amount)
    function withdrawableStake(address validator) external view returns (uint256 amount);

    /**
     * @notice returns the total number of tokens of a particular type staked for a child chain.
     * @dev This function will revert if the token is not supported by the child chain.
     *
     * @param _id Child chain Id
     * @param _token Token to get total for.
     * @return Number of tokens staked on the child chain.
     */
    function totalStakeOfChild(uint256 _id, address _token) external view returns (uint256);

    /**
     * @notice returns the number of tokens staked by a particular staker.
     *
     * @param _staker Staker's address.
     * @param _token Token to get total for.
     * @return Number of tokens staked on the child chain.
     */
    function stakeOf(address _staker, address _token) external view returns (uint256);

    /**
     * @notice returns the number of tokens allocated to a validator on a particular child chain.
     * @dev This function will revert if the token is not supported by the child chain.
     *
     * @param _validator Address of validator to get total for.
     * @param _id Child chain Id.
     * @param _token Token to get total for.
     * @return Number of tokens staked on the child chain.
     */
    function stakeOfValidator(address _validator, uint256 _id, address _token) external view returns (uint256);

    /**
     * @notice returns the number of tokens allocated to a validator on a particular child chain
     *  demoninated in the base token.
     *
     * @param _validator Address of validator to get total for.
     * @param _id Child chain Id.
     * @param _tokens Array of tokens supported by the child chain.
     * @return Number of tokens staked on the child chain.
     */
    function stakeOfValidatorNormalised(
        address _validator,
        uint256 _id,
        address[] memory _tokens
    ) external view returns (uint256);

    /**
     * @notice returns the stakers that have allocated tokens to a validator on a child chain.
     * @dev This function will revert if the token is not supported by the child chain.
     *
     * @param _validator Address of validator to get total for.
     * @param _id Child chain Id.
     * @return Number of tokens staked on the child chain.
     */
    function stakersForValidator(address _validator, uint256 _id) external view returns (address[] memory);

    /**
     * @notice Indicates if a validator no longer has any stake allocated to it
     *
     * @param _validator Address of validator to get total for.
     * @param _id Child chain Id.
     * @param _tokens Array of tokens supported by the child chain.
     * @return true if the validators stake is zero
     */
    function isStakeOfValidatorZero(
        address _validator,
        uint256 _id,
        address[] memory _tokens
    ) external view returns (bool);

    /// @notice returns the child chain manager contract for a child chain
    function managerOf(uint256 id) external view returns (ICustomSupernetManager manager);

    /// @notice returns the child id for a child chain manager contract
    function idFor(address manager) external view returns (uint256 id);
}
