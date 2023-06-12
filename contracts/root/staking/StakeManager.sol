// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/root/staking/IExchangeRate.sol";
import "../../interfaces/root/staking/IStakeManager.sol";
import "../../interfaces/root/staking/ISupernetManager.sol";
import "./StakeManagerData.sol";
import "./StakeManagerChildChainData.sol";

/**
 * Manages the stake of all child chains / rollups.
 *
 * Notes:
 * * This is an upgradable contract.
 */
contract StakeManager is IStakeManager, StakeManagerData, StakeManagerChildChainData, Initializable {
    using SafeERC20 for IERC20;

    address private baseStakingToken;
    IExchangeRate private exchangeRate;

    // The token is not registered as a token that can be staked with.
    error TokenNotSupported(address _token);

    function initialize(address _baseToken, address _exchangeRateProxy) public initializer {
        baseStakingToken = _baseToken;
        exchangeRate = IExchangeRate(_exchangeRateProxy);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function registerChildChain(address _manager) external returns (uint256 id) {
        id = registerChild(_manager);
        ISupernetManager(_manager).onInit(id);
        // slither-disable-next-line reentrancy-events
        emit ChildManagerRegistered(id, _manager);
    }

    /**
     * TODO add to  IStakeManager
     * Regster a validator, associate the validator with a staking address, and stake some value. 

     */
    function registerValidatorAndStake(
        uint256 _id,
        address _validator,
        bytes calldata /* _proof */,
        address _token,
        uint256 _amount
    ) external {
        // TODO verify the proof. The proof will be the msg.sender signed by the validator's private key

        // TODO will there be a separate minimum stake for validators?

        registerValidatorInternal(_id, _validator);

        stakeFor(_id, _validator, _token, _amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeFor(uint256 _id, address _validator, address _token, uint256 _amount) public {
        revertIfChildChainIdInvalid(_id);

        // TODO revert if validator not registered yet.

        // TODO: Ask child chain / supernet manager if token is supported for child chain.

        // Convert the amount such that it is in the base token
        uint256 baseTokenAmount = exchangeRate.convert(_token, _amount);

        // TODO Check to see if amount of stake is high enough.

        // Transfer the tokens here and update the staking registry.
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        // TODO
        //        addStake(msg.sender, _validator, _id, _token, _amount);

        // Communicate the staking change to the child chain.
        ICustomSupernetManager manager = managerOf(_id);
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

        // TODO removeStake(_validator, id, _amount);
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

        // TODO  Determine the common list of tokens that the validator and staker support
        // TODO slash evenly across the commonly staked tokens.
        // TODO **** How to determine how much of each token to slash.
        address token = address(0);

        // TODO determine stakers associated with a validator
        // TODO slash them equally

        uint256 stake = stakeOf(_validator, token);
        if (_amount > stake) _amount = stake;
        // TODO removeStake(_validator, id, stake);
        _withdrawStake(_validator, msg.sender, token, _amount);
        emit StakeRemoved(id, _validator, token, stake);
        emit ValidatorSlashed(id, _validator, token, _amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawableStake(address _validator) external view returns (uint256) {
        // TODO
        //_amount = withdrawableStakeOf(stakes, _validator);
    }

    function _withdrawStake(address _validator, address _to, address _token, uint256 _amount) private {
        // TODO withdrawStake(_validator, _token, _amount);
        // TODO update stakes lib to handle token addresses
        //stakes.withdrawStake(_validator, _token, _amount);
        // slither-disable-next-line reentrancy-events
        IERC20(_token).safeTransfer(_to, _amount);
        emit StakeWithdrawn(_validator, _to, _token, _amount);
    }

    function stakeOfValidatorNormalised(
        address _validator,
        uint256 _id,
        address[] memory _tokens
    ) external view returns (uint256) {
        uint256 baseTokenAmount;
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 amount = stakeOfValidator(_validator, _id, token);
            if (token != baseStakingToken) {
                amount = exchangeRate.convert(token, amount);
            }
            baseTokenAmount += amount;
        }
        return baseTokenAmount;
    }
}
