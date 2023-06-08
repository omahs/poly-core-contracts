// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/root/staking/IExchangeRate.sol";
import "../../interfaces/root/staking/IStakeManager.sol";
import "../../lib/ChildManagerLib.sol";
import "../../lib/StakeManagerLib.sol";

/**
 * Manages the stake of all child chains / rollups.
 *
 * Notes:
 * * This is an upgradable contract.
 */
contract StakeManager is IStakeManager, Initializable {
    using ChildManagerLib for ChildChains;
    using StakeManagerLib for Stakes;
    using SafeERC20 for IERC20;

    address private baseStakingToken;
    IExchangeRate private exchangeRate;
    ChildChains private chains;
    Stakes private stakes;

    // The staking of the ID is invalid.
    error InvalidChildChainId(uint256 _id);

    // The token is not registered as a token that can be staked with.
    error TokenNotSupported(address _token);

    function initialize(address _baseToken, address _exchangeRateProxy) public initializer {
        baseStakingToken = _baseToken;
        exchangeRate = IExchangeRate(_exchangeRateProxy);
    }

    /**
     * TODO can't find IStakeManager  inheritdoc IStakeManager
     *
     */
    function registerChildChain(address _manager) external returns (uint256 id) {
        id = chains.registerChild(_manager);
        ISupernetManager(_manager).onInit(id);
        // slither-disable-next-line reentrancy-events
        emit ChildManagerRegistered(id, _manager);
    }

    /**
     * TODO inheritdoc IStakeManager
     */
    // TODO msg.sender is staker
    // TODO _validator is the validator
    function stakeFor(uint256 _id, address _validator, address _token, uint256 _amount) external {
        if (!(_id != 0 && _id <= chains.counter)) {
            revert InvalidChildChainId(_id);
        }

        // TODO: Ask child chain / supernet manager if token is supported for child chain.

        // Convert the amount such that it is in the base token
        uint256 baseTokenAmount = exchangeRate.convert(_token, _amount);

        // TODO Check to see if amount of stake is high enough.

        // Transfer the tokens here and update the staking registry.
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        StakeManagerLib.addStake(stakes, msg.sender, _id, _amount);
        // TODO Update lib to handle separate validator and staker and to handle tokens
        //StakeManagerLib.addStake(stakes, msg.sender, _validator, _id, _token, _amount);

        // Communicate the staking change to the child chain.
        ISupernetManager manager = managerOf(_id);
        manager.onStake(_validator, baseTokenAmount);
        // slither-disable-next-line reentrancy-events
        emit StakeAdded(_id, msg.sender, _validator, _token, _amount);
    }

    /**
     * @inheritdoc IStakeManager
     *
     */
    function releaseStakeOf(address _validator, address _token, uint256 _amount) external {
        // NOTE: idFor ensures can only be called by supernet / chain manager.
        uint256 id = idFor(msg.sender);

        stakes.removeStake(_validator, id, _amount);
        // TODO upgrade lib to handle tokens
        //stakes.removeStake(_validator, id, _token, _amount);
        // slither-disable-next-line reentrancy-events
        emit StakeRemoved(id, _validator, _token, _amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawStake(address _to, address _token, uint256 _amount) external {
        _withdrawStake(msg.sender, _to, _token, _amount);
    }

    /**
     * TODO inheritdoc IStakeManager
     *
     */
    function slashStakeOf(address _validator, uint256 _amount) external {
        // NOTE: idFor ensures can only be called by supernet / chain manager.
        uint256 id = idFor(msg.sender);

        // TODO  work out which token(s) for which staker(s) to slash
        address token = address(0);

        uint256 stake = stakeOf(_validator, id);
        if (_amount > stake) _amount = stake;
        stakes.removeStake(_validator, id, stake);
        _withdrawStake(_validator, msg.sender, token, _amount);
        emit StakeRemoved(id, _validator, token, stake);
        emit ValidatorSlashed(id, _validator, token, _amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawableStake(address _validator) external view returns (uint256 _amount) {
        _amount = stakes.withdrawableStakeOf(_validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStake() external view returns (uint256 _amount) {
        _amount = stakes.totalStake;
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStakeOfChild(uint256 _id) external view returns (uint256 _amount) {
        _amount = stakes.totalStakeOfChild(_id);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStakeOf(address _validator) external view returns (uint256 _amount) {
        _amount = stakes.totalStakeOf(_validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeOf(address _validator, uint256 _id) public view returns (uint256 _amount) {
        _amount = stakes.stakeOf(_validator, _id);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function managerOf(uint256 _id) public view returns (ISupernetManager _manager) {
        _manager = ISupernetManager(chains.managerOf(_id));
    }

    /**
     * @inheritdoc IStakeManager
     */
    function idFor(address _manager) public view returns (uint256 _id) {
        _id = ChildManagerLib.idFor(chains, _manager);
    }

    function _withdrawStake(address _validator, address _to, address _token, uint256 _amount) private {
        stakes.withdrawStake(_validator, _amount);
        // TODO update stakes lib to handle token addresses
        //stakes.withdrawStake(_validator, _token, _amount);
        // slither-disable-next-line reentrancy-events
        IERC20(_token).safeTransfer(_to, _amount);
        emit StakeWithdrawn(_validator, _to, _token, _amount);
    }
}
