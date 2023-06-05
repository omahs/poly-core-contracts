// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {ValidatorSet, ValidatorInit, Epoch} from "contracts/child/validator/ValidatorSet.sol";
import {RewardPool, IRewardPool, Uptime} from "contracts/child/validator/RewardPool.sol";
import "contracts/interfaces/Errors.sol";

abstract contract Uninitialized is Test {
    address public constant SYSTEM = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    MockERC20 token;
    ValidatorSet validatorSet;
    RewardPool pool;
    address rewardWallet = makeAddr("rewardWallet");
    address alice = makeAddr("alice");
    uint256 baseReward = 1 ether;

    function setUp() public virtual {
        token = new MockERC20();
        validatorSet = new ValidatorSet();
        ValidatorInit[] memory init = new ValidatorInit[](2);
        init[0] = ValidatorInit({addr: address(this), stake: 300});
        init[1] = ValidatorInit({addr: alice, stake: 100});
        validatorSet.initialize(address(1), address(1), address(1), 64, init);
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(1, epoch);
        pool = new RewardPool();
        token.mint(rewardWallet, 1000 ether);
        vm.prank(rewardWallet);
        token.approve(address(pool), type(uint256).max);
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        pool.initialize(address(token), rewardWallet, address(validatorSet), baseReward);
    }
}

abstract contract Distributed is Initialized {
    function setUp() public virtual override {
        super.setUp();
        Uptime[] memory uptime = new Uptime[](2);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 64});
        uptime[1] = Uptime({validator: alice, signedBlocks: 64});
        vm.prank(SYSTEM);
        pool.distributeRewardFor(1, uptime, 0);
    }
}

contract RewardPool_Initialize is Uninitialized {
    function test_Initialize() public {
        pool.initialize(address(token), rewardWallet, address(validatorSet), baseReward);
        assertEq(address(pool.rewardToken()), address(token));
        assertEq(pool.rewardWallet(), rewardWallet);
        assertEq(address(pool.validatorSet()), address(validatorSet));
        assertEq(pool.baseReward(), baseReward);
    }
}

contract RewardPool_Distribute is Initialized {
    event RewardDistributed(uint256 indexed epochId, uint256 totalReward);

    function test_RevertOnlySystem() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        pool.distributeRewardFor(1, new Uptime[](0), 0);
    }

    function test_RevertGenesisEpoch() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.expectRevert("EPOCH_NOT_COMMITTED");
        vm.prank(SYSTEM);
        pool.distributeRewardFor(0, uptime, 0);
    }

    function test_RevertFutureEpoch() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.expectRevert("EPOCH_NOT_COMMITTED");
        vm.prank(SYSTEM);
        pool.distributeRewardFor(2, uptime, 0);
    }

    function test_RevertSignedBlocksExceedsTotalBlocks() public {
        Uptime[] memory uptime = new Uptime[](1);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 65});
        vm.prank(SYSTEM);
        vm.expectRevert("SIGNED_BLOCKS_EXCEEDS_TOTAL");
        pool.distributeRewardFor(1, uptime, 0);
    }

    function test_DistributeRewards() public {
        Uptime[] memory uptime = new Uptime[](2);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 60});
        uptime[1] = Uptime({validator: alice, signedBlocks: 50});
        uint256 reward1 = (baseReward * 3 * 60) / (4 * 64);
        uint256 reward2 = (baseReward * 1 * 50) / (4 * 64);
        uint256 totalReward = reward1 + reward2;
        vm.prank(SYSTEM);
        vm.expectEmit(true, true, true, true);
        emit RewardDistributed(1, totalReward);
        pool.distributeRewardFor(1, uptime, 0);
        assertEq(pool.pendingRewards(address(this)), reward1);
        assertEq(pool.pendingRewards(alice), reward2);
        assertEq(pool.paidRewardPerEpoch(1), totalReward);
    }

    function test_DistributeTradingFees() public {
        uint256 tradingFees = 1000;
        Uptime[] memory uptime = new Uptime[](2);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 60});
        uptime[1] = Uptime({validator: alice, signedBlocks: 50});
        uint256 reward1 = (baseReward * 3 * 60) / (4 * 64);
        uint256 reward2 = (baseReward * 1 * 50) / (4 * 64);
        uint256 totalReward = reward1 + reward2;
        vm.prank(SYSTEM);
        vm.expectEmit(true, true, true, true);
        emit RewardDistributed(1, totalReward);

        pool.distributeRewardFor(1, uptime, tradingFees);

        uint256 totalSupply = validatorSet.totalSupplyAt(validatorSet.currentEpochId());
        uint256 aliceStaked = validatorSet.balanceOfAt(alice, validatorSet.currentEpochId());

        uint256 preAliceBalance = token.balanceOf(alice);
        vm.prank(alice);
        pool.claimTradingFees();
        uint256 postAliceBalance = token.balanceOf(alice);
        uint256 aliceTradingFees = postAliceBalance - preAliceBalance;
        // alice's rewards should be proportional to their staked amount.
        uint256 expectedTradingFees = tradingFees * aliceStaked / totalSupply;
        assertEq(aliceTradingFees, expectedTradingFees);

        Epoch memory epoch = Epoch({startBlock: 65, endBlock: 128, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(2, epoch);

        vm.prank(SYSTEM);
        pool.distributeRewardFor(2, uptime, tradingFees);

        // alice's rewards should be proportional to their staked amount.
        expectedTradingFees = tradingFees * aliceStaked / totalSupply;
        assertEq(aliceTradingFees, expectedTradingFees);

        epoch = Epoch({startBlock: 129, endBlock: 192, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        validatorSet.commitEpoch(3, epoch);

        vm.prank(SYSTEM);
        pool.distributeRewardFor(3, uptime, tradingFees);

        preAliceBalance = token.balanceOf(alice);
        vm.prank(alice);
        pool.claimTradingFees();
        postAliceBalance = token.balanceOf(alice);
        aliceTradingFees = postAliceBalance - preAliceBalance;
        // alice's rewards should be proportional to their staked amount.
        expectedTradingFees = tradingFees * 2 * aliceStaked / totalSupply;
        assertEq(aliceTradingFees, expectedTradingFees);

        // But what if a user stakes after alice has earnt rewards, but before alice claims them?
        // Since the rewards per token will be different.
        // No, I don't think so, because rewards per token is determined at the time of committing the epoch, and therefore at the total staked amount at that time.
        // Therefore, if a user stakes after the epoch is committed, they will not be eligible for rewards for that epoch. and alice will still get the same amount of rewards.
        // (to be tested ^)
    }
}

contract RewardPool_DuplicateDistribution is Distributed {
    function test_RevertEpochAlreadyDistributed() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.prank(SYSTEM);
        vm.expectRevert("REWARD_ALREADY_DISTRIBUTED");
        pool.distributeRewardFor(1, uptime, 0);
    }
}

contract RewardPool_Withdrawal is Distributed {
    function test_SuccessfulWithdrawal() public {
        uint256 reward = pool.pendingRewards(address(this));
        pool.withdrawReward();
        assertEq(pool.pendingRewards(address(this)), 0);
        assertEq(token.balanceOf(address(this)), reward);
    }
}
