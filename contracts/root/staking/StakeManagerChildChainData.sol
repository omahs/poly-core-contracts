// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../interfaces/root/staking/IStakeManager.sol";

/*
 * Holds the mapping between CustomSupernetManager contract address and
 * child chain id.
 *
 * NOTE: In Polygon's core-contracts repo, this contract is ChildChainLib.sol
 */
abstract contract StakeManagerChildChainData is IStakeManager {
    // Counter that determines the next child chain id.
    uint256 private childChainCounter;
    // Mapping id to address of manager
    mapping(uint256 => address) private childChainManagers;
    // Mapping address of manager to id
    mapping(address => uint256) private childChainIds;

    // solhint-disable-next-line var-name-mixedcase
    uint256[1000] private __StorageGapStakeManagerChildChainData;

    // The staking of the ID is invalid.
    error InvalidChildChainId(uint256 _id);

    function registerChild(address _manager) internal returns (uint256 id) {
        // TODO switch to Error
        require(_manager != address(0), "Manager address is 0");
        // TODO switch to Error
        require(childChainIds[_manager] == 0, "Child chain already registered");
        id = ++childChainCounter;
        childChainManagers[id] = _manager;
        childChainIds[_manager] = id;
    }

    function revertIfChildChainIdInvalid(uint256 _id) internal view {
        if (!(_id != 0 && _id <= childChainCounter)) {
            revert InvalidChildChainId(_id);
        }
    }

    /**
     * @inheritdoc IStakeManager
     */
    function managerOf(uint256 _id) public view returns (ICustomSupernetManager) {
        address manager = childChainManagers[_id];
        // TODO switch to Error
        require(manager != address(0), "Invalid id");
        return ICustomSupernetManager(manager);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function idFor(address _manager) public view returns (uint256) {
        uint256 id = childChainIds[_manager];
        // TODO switch to Error
        require(id != 0, "Invalid manager");
        return id;
    }
}
