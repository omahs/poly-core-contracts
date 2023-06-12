// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../interfaces/root/staking/IStakeManager.sol";
import "../../interfaces/root/staking/ICustomSupernetManager.sol";

/*
 * Code and state to operate on staking information on root chain.
 *
 * NOTE: In Polygon's core-contracts repo, this contract is StakeManagerLib.sol
 */
abstract contract StakeManagerData is IStakeManager {
    // Mapping validator address to staker address
    mapping(bytes32 => address) private validatorLinkedStaker;
    // Mapping staker address to validator address
    mapping(bytes32 => address) private stakerLinkedValidator;

    struct StakeAllocations {
        uint256[] children;
        address[] validators;
    }

    // TODO what is this needed for?
    //uint256 private totalStake;

    // Which child chain and validator stakes are allocated to.
    // staker => token => amount
    mapping(address => mapping(address => uint256)) private stakes;

    // Which child chain and validator stakes are allocated to.
    // staker => StakeAllocations
    mapping(address => StakeAllocations) private stakeAllocations;

    // Map of chain id to the array of validators for that chain
    // child chain => validators
    mapping(uint256 => address[]) private validators;

    // Map of chain id to map of validators to array of stakers for the validator for that chain
    // child chain => validator => stakers
    mapping(uint256 => mapping(address => address[])) private validatorStakers;

    // Mapping (staker => token => amount)
    mapping(address => mapping(address => uint256)) withdrawableStakes;

    // solhint-disable-next-line var-name-mixedcase
    uint256[100] private __StakesManagerStorageGap;

    event CouldNotFindStakerForChainValidator(uint256 _id, address _validator, address _staker);
    event CouldNotFindValidatorForChain(uint256 _id, address _validator);

    error ValidatorAlreadyRegistered(uint256 _id, address _validator);
    error ValidatorNotRegistered(uint256 _id, address _validator);
    error StakerAlreadyLinkedToValidator(uint256 _id, address _staker);
    error DeregisterRequestNotFromLinkedStaker(address _linkedStaker);
    error InsufficientWithdrawableBalance(
        address _staker,
        address _token,
        uint256 _withdrawableBalance,
        uint256 withdrawalRequest
    );
    error AlreadyStakedOnChildChain(address _staker, uint256 _id);
    error StakerNotStakedOnChain(address _staker, uint256 _id);

    /**
     * Register a validator and its linked staker.
     *
     * Note: An "linked staker" can only be associated with one validator address per chain.
     * Note: msg.sender must be the staker account.
     *
     * @param _id Child chain id.
     * @param _validator Address of a validator.
     */
    function registerValidatorInternal(uint256 _id, address _validator) internal {
        address staker = msg.sender;
        bytes32 idValidator = keccak256(abi.encodePacked(_id, _validator));
        bytes32 idStaker = keccak256(abi.encodePacked(_id, staker));
        if (validatorLinkedStaker[idValidator] != address(0)) {
            revert ValidatorAlreadyRegistered(_id, _validator);
        }
        if (stakerLinkedValidator[idStaker] != address(0)) {
            revert StakerAlreadyLinkedToValidator(_id, staker);
        }
        validatorLinkedStaker[idValidator] = staker;
        stakerLinkedValidator[idStaker] = _validator;
    }

    /**
     * Deegister a validator and its associated staker.
     * Note: msg.sender must be the staker account.
     *
     * @param _id Child chain id.
     * @param _validator Address of a validator.
     */
    function deregisterValidator(uint256 _id, address _validator) internal {
        bytes32 idValidator = keccak256(abi.encodePacked(_id, _validator));
        address staker = validatorLinkedStaker[idValidator];
        if (staker != msg.sender) {
            revert DeregisterRequestNotFromLinkedStaker(msg.sender);
        }
        bytes32 idStaker = keccak256(abi.encodePacked(_id, staker));
        if (validatorLinkedStaker[idValidator] != address(0)) {
            revert ValidatorNotRegistered(_id, _validator);
        }
        validatorLinkedStaker[idValidator] = address(0);
        stakerLinkedValidator[idStaker] = address(0);
    }

    // function addStake(address _staker, address _token, uint256 _amount, uint256 _id, address _validator) internal {
    //     addStake(_self, _staker, _token, _amount);
    //     restake(_self, _staker, _token, _id, _validator);

    // }

    /**
     * Deposit stake to be held in escrow. The stake can then be allocated to a validator on a chain.
     * Note: msg.sender must be the staker account.
     *
     * @param _token Token to stake.
     * @param _amount Number of tokens to stake.
     */
    function stakeValue(address _token, uint256 _amount) internal {
        stakes[msg.sender][_token] += _amount;
    }

    function removeStake(address _token, uint256 _amount) internal {
        stakes[msg.sender][_token] -= _amount;
        withdrawableStakes[msg.sender][_token] += _amount;
    }

    function withdrawStake(address _token, uint256 _amount) internal {
        uint256 withdrawableBalance = withdrawableStakeOf(_token);
        if (withdrawableBalance < _amount) {
            revert InsufficientWithdrawableBalance(msg.sender, _token, withdrawableBalance, _amount);
        }

        withdrawableStakes[msg.sender][_token] -= _amount;
    }

    /**
     * Allocate all of the stake of a staker to a validator on a chain.
     *
     * Note: msg.sender must be the staker account.
     *
     * @param _id Child chain id.
     * @param _validator Address of a validator.
     */
    function allocateStake(uint256 _id, address _validator) internal {
        address staker = msg.sender;
        uint256 timesRestakedEver = stakeAllocations[staker].children.length;
        // Stakers can only restake once on the same chain.
        for (uint256 i = 0; i < timesRestakedEver; i++) {
            if (stakeAllocations[staker].children[i] == _id) {
                revert AlreadyStakedOnChildChain(staker, _id);
            }
        }

        // Add the information where the stake has been staked.
        stakeAllocations[staker].children.push(_id);
        stakeAllocations[staker].validators.push(_validator);

        // Add the staker to the child chain and validator data structure.
        // Only add the validator to the array of validators on a chain if it hasn't been added yet.
        if (validatorStakers[_id][_validator].length == 0) {
            validators[_id].push(_validator);
        }
        validatorStakers[_id][_validator].push(staker);
    }

    /**
     * Deallocate all of the stake of a staker from a validator on a chain.
     *
     * Note: msg.sender must be the staker account.
     *
     * @param _id Child chain id.
     */
    function deallocateStake(uint256 _id) internal {
        address staker = msg.sender;
        // Find the child chain id, and the remove the allocation
        bool notFound = true;
        address validator;
        for (uint256 i = 0; i < stakeAllocations[staker].children.length; i++) {
            if (stakeAllocations[staker].children[i] == _id) {
                stakeAllocations[staker].children[i] = 0;
                validator = stakeAllocations[staker].validators[i];
                stakeAllocations[staker].validators[i] = address(0);
                notFound = false;
                break;
            }
        }
        if (notFound) {
            revert StakerNotStakedOnChain(staker, _id);
        }

        // Remove the staker from the child chain and validator data structure.
        notFound = true;
        for (uint256 i = 0; i < validatorStakers[_id][validator].length; i++) {
            if (validatorStakers[_id][validator][i] == staker) {
                validatorStakers[_id][validator][i] = address(0);
                notFound = false;
                break;
            }
        }
        if (notFound) {
            emit CouldNotFindStakerForChainValidator(_id, validator, staker);
            return;
        }

        // Check to see if there are any stakers for the validator still?
        for (uint256 i = 0; i < validatorStakers[_id][validator].length; i++) {
            if (validatorStakers[_id][validator][i] != address(0)) {
                // Exit if at least one active staker found.
                return;
            }
        }

        // A validator no longer has any stake.
        notFound = true;
        for (uint256 i = 0; i < validators[_id].length; i++) {
            if (validators[_id][i] == validator) {
                validators[_id][i] = address(0);
                break;
            }
        }
        if (notFound) {
            emit CouldNotFindValidatorForChain(_id, validator);
        }
    }

    /**
     * Return information about which validators have what stake allocated to them.
     *
     * @param _id Child chain id.
     * @return amount of stake as array: [supported token index][validator address]
     */
    function gatherStake(
        uint256 _id,
        address[] memory _tokensSupportedByChain
    ) internal view returns (uint256[][] memory) {
        uint256 numTokensSupportedByChain = _tokensSupportedByChain.length;
        uint256 numValidators = validators[_id].length;
        uint256[][] memory stakedValue = new uint256[][](numTokensSupportedByChain);
        for (uint256 i = 0; i < numTokensSupportedByChain; i++) {
            stakedValue[i] = new uint256[](numValidators);
        }

        for (uint256 i = 0; i < numValidators; i++) {
            address validator = validators[_id][i];
            uint256 numberOfStakers = validatorStakers[_id][validator].length;
            for (uint256 j = 0; j < numberOfStakers; j++) {
                address staker = validatorStakers[_id][validator][j];
                for (uint256 k = 0; k < numTokensSupportedByChain; k++) {
                    address token = _tokensSupportedByChain[k];
                    stakedValue[k][i] = stakes[staker][token];
                }
            }
        }
        return stakedValue;
    }

    /**
     * @inheritdoc IStakeManager
     */
    function isValidatorRegistered(uint256 _id, address _validator) public view override returns (bool) {
        bytes32 idValidator = keccak256(abi.encodePacked(_id, _validator));
        address staker = validatorLinkedStaker[idValidator];
        return staker != address(0);
    }

    function withdrawableStakeOf(address _token) internal view returns (uint256) {
        return withdrawableStakes[msg.sender][_token];
    }

    function totalStakeOfChild(uint256 _id, address _token) external view returns (uint256) {
        ICustomSupernetManager childChainManager = this.managerOf(_id);
        require(childChainManager.stakingTokenSupported(_token), "Token not supported by child");

        uint256 amount;
        uint256 numValidators = validators[_id].length;

        for (uint256 i = 0; i < numValidators; i++) {
            address validator = validators[_id][i];
            uint256 numberOfStakers = validatorStakers[_id][validator].length;
            for (uint256 j = 0; j < numberOfStakers; j++) {
                address staker = validatorStakers[_id][validator][j];
                amount += stakes[staker][_token];
            }
        }

        return amount;
    }

    function stakeOf(address _staker, address _token) public view returns (uint256) {
        return stakes[_staker][_token];
    }

    function stakeOfValidator(address _validator, uint256 _id, address _token) public view override returns (uint256) {
        ICustomSupernetManager childChainManager = this.managerOf(_id);
        require(childChainManager.stakingTokenSupported(_token), "Token not supported by child");

        uint256 amount;
        uint256 numberOfStakers = validatorStakers[_id][_validator].length;
        for (uint256 i = 0; i < numberOfStakers; i++) {
            address staker = validatorStakers[_id][_validator][i];
            amount += stakes[staker][_token];
        }
        return amount;
    }

    function isStakeOfValidatorZero(
        address _validator,
        uint256 _id,
        address[] memory _tokens
    ) external view override returns (bool) {
        uint256 numberOfStakers = validatorStakers[_id][_validator].length;
        for (uint256 i = 0; i < numberOfStakers; i++) {
            address staker = validatorStakers[_id][_validator][i];
            for (uint256 j = 0; j < _tokens.length; j++) {
                if (stakes[staker][_tokens[j]] != 0) {
                    return false;
                }
            }
        }
        return true;
    }

    function stakersForValidator(address _validator, uint256 _id) external view override returns (address[] memory) {
        uint256 numberOfStakers = validatorStakers[_id][_validator].length;
        address[] memory stakers = new address[](numberOfStakers);
        for (uint256 i = 0; i < numberOfStakers; i++) {
            stakers[i] = validatorStakers[_id][_validator][i];
        }
        return stakers;
    }

    function getTokensSupportedByChildChain(uint256 _id) private view returns (address[] memory) {
        ICustomSupernetManager childChainManager = this.managerOf(_id);
        return childChainManager.getListOfStakingTokens();
    }
}
