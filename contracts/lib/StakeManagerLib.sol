// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/root/staking/IStakeManager.sol";


/*
 * Code that is included in the root/staking/ImmutableStakingManager.sol
 *
 * Code and state to operate on staking information on root chain. 
 */


// The maximum number of times some stake can be re-staked.
uint256 constant MAX_TIMES_RESTAKED_STORAGE_RESERVATION = 1000;

// The maximum number of times some stake can be re-staked.
uint256 constant MAX_NUM_STAKERS_PER_VALIDATOR_STORAGE_RESERVATION = 1000;


struct ChildValidator {
    uint256 child;
    address validator;
    uint256[10] unused;
}

struct StakeAllocations {
    uint256 amount;
    uint256 timesRestaked;
    ChildValidator[MAX_TIMES_RESTAKED_STORAGE_RESERVATION] childValidator;
    uint256[100] unused;

}

struct Staker {
    address staker;
    address token;
}


struct StakerList {
    uint256 numberOfStakers;
    Staker[MAX_NUM_STAKERS_PER_VALIDATOR_STORAGE_RESERVATION] stakers;
    // TODO is a reverse look-up needed? TODO remove validatorArrayOfs
    uint256 validatorArrayOfs;
    uint256[100] unused;
}


struct StakedValue {
    address validator;
    uint256 amount;
}

struct StakedValueList {
    address token;
    StakedValue[] stakedValue;
}


struct Stakes {
    // TODO what is this needed for?
    uint256 totalStake;


    // staker => token => StakeAllocations
    mapping(address => mapping(address => StakeAllocations)) stakes;

    // child chain => validator => StakerList
    mapping(uint256 => mapping(address => StakerList)) validatorStakes;

    // Validators that have stake against them for a specific chain.
    // child chain => array of validators
    mapping(uint256 => address[]) validators;


    // hash(child, validator) =>

    // child chain => total stake
    mapping(uint256 => uint256) totalStakePerChild;

    // TODO what is this needed for?
    mapping(address => uint256) totalStakes;

    // Mapping (staker => token => amount)
//    mapping(address => mapping(address => uint256)) withdrawableStakes;
    mapping(address => uint256) withdrawableStakes;

    uint256[100] __StakesGap;
}

library StakeManagerLib {
    // TODO remove old function
    function addStake(Stakes storage , address, uint256, uint256 ) internal pure {


    }

    function addStake(Stakes storage _self, address _staker, address _token, uint256 _amount, uint256 _id, address _validator) internal {
        addStake(_self, _staker, _token, _amount);
        restake(_self, _staker, _token, _id, _validator);

        // _self.totalStakePerChild[_id] += _amount;
        // _self.totalStakes[_validator] += _amount;
        // _self.totalStake += _amount;
    }


    function addStake(Stakes storage _self, address _staker, address _token, uint256 _amount) internal {
        _self.stakes[_staker][_token].amount += _amount;
    }

    // Restake with a new child chain / validator 
    function restake(Stakes storage _self, address _staker, address _token, uint256 _id, address _validator) internal {
        // Add the chain and validator to the staking data structure.
        uint256 timesRestaked = _self.stakes[_staker][_token].timesRestaked;
        // Stakers can only restake once on the same chain.
        uint256 i = 0;
        for (i = 0; i < timesRestaked; i++) {
            if (_self.stakes[_staker][_token].childValidator[i].child == _id) {
                    revert("Already staking on child chain");
            }
        }
        _self.stakes[_staker][_token].childValidator[i].child = _id;
        _self.stakes[_staker][_token].childValidator[i].validator = _validator;
        _self.stakes[_staker][_token].timesRestaked = timesRestaked + 1;

        // Add the staker to the chain and validator data structure.
        // TODO Add information to: _self.validators[_id][i];
        // TODO Add information to: _self.validatorStakes


    }



    function gatherStake(Stakes storage _self, uint256 _id) internal view returns (StakedValueList[] memory) {
//    function gatherStake(Stakes storage, uint256 ) internal pure returns (StakedValueList[] memory) {
        StakedValueList[] memory stakedValues;
        // TODO need to create the stakeValues array, one entry for each token type supported by the child chain


        uint256 numValidators = _self.validators[_id].length;
        for (uint256 i = 0; i < numValidators; i++) {
            address validator = _self.validators[_id][i];
            uint256 numberOfStakers = _self.validatorStakes[_id][validator].numberOfStakers;
            for (uint256 j = 0; j < numberOfStakers; j++) {
                //TODO complete this
              //  address staker = _self.validatorStakes[_id][validator].stakers[j].staker;
                address token = _self.validatorStakes[_id][validator].stakers[j].token;

                bool found = false;
                for (uint256 k = 0; k < stakedValues.length; k++) {
                    if (token == stakedValues[k].token) {
                        found = true;
                        // TODO add staker information
                    }

                }
                // TODO maybe this should be emit an event, rather than stop code from working / failing.
                require(found, "Staked token not found");

            }



        }



        return stakedValues;
    }




//    function removeStake(Stakes storage self, address validator, uint256 id, uint256 amount) internal {

    function removeStake(Stakes storage, address, uint256, uint256) internal pure {
        // self.stakes[validator][id] -= amount;
        // self.totalStakePerChild[id] -= amount;
        // self.totalStakes[validator] -= amount;
        // self.totalStake -= amount;
        // self.withdrawableStakes[validator] += amount;
    }

    function withdrawStake(Stakes storage self, address validator, uint256 amount) internal {
        self.withdrawableStakes[validator] -= amount;
    }

    function withdrawableStakeOf(Stakes storage self, address validator) internal view returns (uint256 amount) {
        amount = self.withdrawableStakes[validator];
    }

    function totalStakeOfChild(Stakes storage self, uint256 id) internal view returns (uint256 amount) {
        amount = self.totalStakePerChild[id];
    }

//    function stakeOf(Stakes storage self, address validator, uint256 id) internal view returns (uint256 amount) {
    function stakeOf(Stakes storage , address, uint256) internal pure returns (uint256 amount) {
//        amount = self.stakes[validator][id];
        amount = 0;
    }

    function totalStakeOf(Stakes storage self, address validator) internal view returns (uint256 amount) {
        amount = self.totalStakes[validator];
    }
}
