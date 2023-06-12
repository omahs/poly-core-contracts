// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SupernetManager.sol";
import "../../interfaces/common/IBLS.sol";
import "../../interfaces/IStateSender.sol";
import "../../interfaces/root/staking/ICustomSupernetManager.sol";

contract CustomSupernetManager is ICustomSupernetManager, Ownable2StepUpgradeable, SupernetManager {
    using SafeERC20 for IERC20;
    using GenesisLib for GenesisSet;

    bytes32 private constant STAKE_SIG = keccak256("STAKE");
    bytes32 private constant UNSTAKE_SIG = keccak256("UNSTAKE");
    bytes32 private constant SLASH_SIG = keccak256("SLASH");
    uint256 public constant SLASHING_PERCENTAGE = 50;

    IBLS private bls;
    IStateSender private stateSender;

    // Staking token support.
    // Are tokens supported?
    // Map (address of token => boolean indicating whether the token is supported by this chain)
    mapping(address => bool) private stakingTokensMap;
    // List of staking tokens
    address[] private stakingTokensList;

    address private childValidatorSet;
    address private exitHelper;

    bytes32 public domain;

    GenesisSet private _genesis;
    mapping(address => Validator) public validators;

    modifier onlyValidator(address validator) {
        if (!validators[validator].isActive) revert Unauthorized("VALIDATOR");
        _;
    }

    /**
     *
     * @param newStakeManager  Address of stake manager contract
     * @param newBls           TODO what is this for?
     * @param newStateSender   Address of state sender contract
     * @param initialTokenList Staking tokens allows for this chain
     * @param newChildValidatorSet TODO what is this for?
     * @param newExitHelper    TODO what is this for?
     * @param newDomain        TODO what is this for?
     */

    function initialize(
        address newStakeManager,
        address newBls,
        address newStateSender,
        address[] calldata initialTokenList,
        address newChildValidatorSet,
        address newExitHelper,
        string memory newDomain
    ) public initializer {
        require(
            newStakeManager != address(0) &&
                newBls != address(0) &&
                newStateSender != address(0) &&
                newChildValidatorSet != address(0) &&
                newExitHelper != address(0) &&
                bytes(newDomain).length != 0,
            "INVALID_INPUT"
        );

        __SupernetManager_init(newStakeManager);
        bls = IBLS(newBls);
        stateSender = IStateSender(newStateSender);
        childValidatorSet = newChildValidatorSet;
        exitHelper = newExitHelper;
        domain = keccak256(abi.encodePacked(newDomain));

        // TODO should pass in the ExchangeRate interface, and then validate that the token is supported
        // TODO by the overall system
        for (uint256 i = 0; i < initialTokenList.length; i++) {
            address token = initialTokenList[i];
            require(token != address(0), "Token list: 0 token address");
            require(stakingTokensMap[token] == false, "Token list: duplicate token");
            stakingTokensList.push(token);
            stakingTokensMap[token] = true;
        }

        __Ownable2Step_init();
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function whitelistValidators(address[] calldata validators_) external onlyOwner {
        uint256 length = validators_.length;
        for (uint256 i = 0; i < length; i++) {
            _addToWhitelist(validators_[i]);
        }
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external {
        Validator storage validator = validators[msg.sender];
        if (!validator.isWhitelisted) revert Unauthorized("WHITELIST");
        _verifyValidatorRegistration(msg.sender, signature, pubkey);
        validator.blsKey = pubkey;
        validator.isActive = true;
        _removeFromWhitelist(msg.sender);
        emit ValidatorRegistered(msg.sender, pubkey);
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function finalizeGenesis() external onlyOwner {
        // calling the library directly once fixes the coverage issue
        // https://github.com/foundry-rs/foundry/issues/4854#issuecomment-1528897219
        GenesisLib.finalize(_genesis);
        emit GenesisFinalized(_genesis.set().length);
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function enableStaking() external onlyOwner {
        _genesis.enableStaking();
        emit StakingEnabled();
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function withdrawSlashedStake(address to, address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function onL2StateReceive(uint256 /*id*/, address sender, bytes calldata data) external {
        if (msg.sender != exitHelper || sender != childValidatorSet) revert Unauthorized("exitHelper");
        if (bytes32(data[:32]) == UNSTAKE_SIG) {
            (address validator, uint256 amount) = abi.decode(data[32:], (address, uint256));
            _unstake(validator, amount);
        } else if (bytes32(data[:32]) == SLASH_SIG) {
            address validator = abi.decode(data[32:], (address));
            _slash(validator);
        }
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function genesisSet() external view returns (GenesisValidator[] memory) {
        return _genesis.set();
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function getValidator(address validator_) external view returns (Validator memory) {
        return validators[validator_];
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function stakingTokenSupported(address _token) external view returns (bool) {
        return stakingTokensMap[_token];
    }

    /**
     * @inheritdoc ICustomSupernetManager
     */
    function getListOfStakingTokens() public view returns (address[] memory) {
        uint256 len = stakingTokensList.length;
        address[] memory supportedTokens = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            supportedTokens[i] = stakingTokensList[i];
        }
        return supportedTokens;
    }

    // TODO need to take validator and staker
    // Note: amount is based token
    function _onStake(address validator, uint256 amount) internal override onlyValidator(validator) {
        // TODO record who has staked what

        // TODO better understand what code below is doing
        if (_genesis.gatheringGenesisValidators()) {
            _genesis.insert(validator, amount);
        } else if (_genesis.completed()) {
            stateSender.syncState(childValidatorSet, abi.encode(STAKE_SIG, validator, amount));
        } else {
            revert Unauthorized("Wait for genesis");
        }
    }

    function _unstake(address validator, uint256 amount) internal {
        // TODO need to remove address(0)
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        stakeManager.releaseStakeOf(validator, address(0), amount);
        _removeIfValidatorUnstaked(validator);
    }

    function _slash(address validator) internal {
        address[] memory tokens = getListOfStakingTokens();
        uint256 stake = stakeManager.stakeOfValidatorNormalised(validator, id, tokens);
        uint256 slashedAmount = (stake * SLASHING_PERCENTAGE) / 100;
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        stakeManager.slashStakeOf(validator, slashedAmount);
        _removeIfValidatorUnstaked(validator);
    }

    function _verifyValidatorRegistration(
        address signer,
        uint256[2] calldata signature,
        uint256[4] calldata pubkey
    ) internal view {
        /// @dev signature verification succeeds if signature and pubkey are empty
        if (signature[0] == 0 && signature[1] == 0) revert InvalidSignature(signer);
        // slither-disable-next-line calls-loop
        (bool result, bool callSuccess) = bls.verifySingle(signature, pubkey, _message(signer));
        if (!callSuccess || !result) revert InvalidSignature(signer);
    }

    /// @notice Message to sign for registration
    function _message(address signer) internal view returns (uint256[2] memory) {
        // slither-disable-next-line calls-loop
        return bls.hashToPoint(domain, abi.encodePacked(signer, address(this), block.chainid));
    }

    function _addToWhitelist(address validator) internal {
        validators[validator].isWhitelisted = true;
        emit AddedToWhitelist(validator);
    }

    function _removeFromWhitelist(address validator) internal {
        validators[validator].isWhitelisted = false;
        emit RemovedFromWhitelist(validator);
    }

    function _removeIfValidatorUnstaked(address validator) internal {
        if (stakeManager.isStakeOfValidatorZero(validator, id, getListOfStakingTokens())) {
            validators[validator].isActive = false;
            emit ValidatorDeactivated(validator);
        }
    }
}
