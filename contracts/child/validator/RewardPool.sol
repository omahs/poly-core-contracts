// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../System.sol";
import "../../interfaces/child/validator/IRewardPool.sol";

contract RewardPool is IRewardPool, System, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant PRECISION = 1e18;

    IERC20Upgradeable public rewardToken;
    address public rewardWallet;
    IValidatorSet public validatorSet;
    uint256 public baseReward;

    mapping(uint256 => uint256) public paidRewardPerEpoch;
    mapping(address => uint256) public pendingRewards;

    uint256 public cumulativeTradingFeesPerToken;

    mapping(address user => uint256 amount) public previousCumulatedRewardPerToken;

    event TradingFeesPaid(address indexed user, uint256 amount);

    function initialize(
        address newRewardToken,
        address newRewardWallet,
        address newValidatorSet,
        uint256 newBaseReward
    ) public initializer {
        require(
            newRewardToken != address(0) && newRewardWallet != address(0) && newValidatorSet != address(0),
            "ZERO_ADDRESS"
        );

        rewardToken = IERC20Upgradeable(newRewardToken);
        rewardWallet = newRewardWallet;
        validatorSet = IValidatorSet(newValidatorSet);
        baseReward = newBaseReward;
    }

    /**
     * @dev Distributes trading rewards to the reward wallet, keeping track of total trading rewards per unit of staked balance.
     */
    function distributeTradingFees(uint256 tradingFees, uint256 epochId) internal {
        uint256 totalSupply = validatorSet.totalSupplyAt(epochId);
        if (totalSupply == 0) {
            return;
        }
        uint256 newTradingFeesPerStakedUnit = (tradingFees * PRECISION) / totalSupply;
        cumulativeTradingFeesPerToken += newTradingFeesPerStakedUnit;

        // We do not transfer tradingFees tokens to the reward wallet here, because we do it at the end of `distributeRewardFor`.
    }

    /**
     * @inheritdoc IRewardPool
     */
    function distributeRewardFor(
        uint256 epochId,
        Uptime[] calldata uptime,
        uint256 tradingFees
    ) external onlySystemCall {
        require(paidRewardPerEpoch[epochId] == 0, "REWARD_ALREADY_DISTRIBUTED");
        uint256 totalBlocks = validatorSet.totalBlocks(epochId);
        require(totalBlocks != 0, "EPOCH_NOT_COMMITTED");

        if (tradingFees > 0) {
            distributeTradingFees(tradingFees, epochId);
        }

        uint256 epochSize = validatorSet.EPOCH_SIZE();
        // slither-disable-next-line divide-before-multiply
        uint256 reward = (baseReward * totalBlocks) / epochSize;

        uint256 totalSupply = validatorSet.totalSupplyAt(epochId);
        uint256 length = uptime.length;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < length; i++) {
            Uptime memory data = uptime[i];
            require(data.signedBlocks <= totalBlocks, "SIGNED_BLOCKS_EXCEEDS_TOTAL");
            // slither-disable-next-line calls-loop
            uint256 balance = validatorSet.balanceOfAt(data.validator, epochId);
            // slither-disable-next-line divide-before-multiply
            uint256 validatorReward = (reward * balance * data.signedBlocks) / (totalSupply * totalBlocks);
            pendingRewards[data.validator] += validatorReward;
            totalReward += validatorReward;
        }
        paidRewardPerEpoch[epochId] = totalReward;
        _transferRewards(totalReward + tradingFees);
        emit RewardDistributed(epochId, totalReward);
    }

    function claimTradingFees() external {
        uint256 _cumulativeRewardPerToken = cumulativeTradingFeesPerToken;
        uint256 stakedAmount = validatorSet.balanceOfAt(msg.sender, validatorSet.currentEpochId());
        uint256 accountReward = (stakedAmount *
            (_cumulativeRewardPerToken - previousCumulatedRewardPerToken[msg.sender])) / PRECISION;

        previousCumulatedRewardPerToken[msg.sender] = _cumulativeRewardPerToken;

        if (accountReward > 0) {
            rewardToken.safeTransfer(msg.sender, accountReward);
            emit TradingFeesPaid(msg.sender, accountReward);
        }
    }

    /**
     * @inheritdoc IRewardPool
     */
    function withdrawReward() external {
        uint256 pendingReward = pendingRewards[msg.sender];
        pendingRewards[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, pendingReward);
    }

    /// @dev this method can be overridden to add logic depending on the reward token
    function _transferRewards(uint256 amount) internal virtual {
        // slither-disable-next-line arbitrary-send-erc20
        rewardToken.safeTransferFrom(rewardWallet, address(this), amount);
    }
}
