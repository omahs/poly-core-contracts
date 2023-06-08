# IStakeManager

*Polygon Technology (@gretzke)*

> IStakeManager

Manages stakes for all child chains



## Methods

### idFor

```solidity
function idFor(address manager) external view returns (uint256 id)
```

returns the child id for a child chain manager contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| manager | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

### managerOf

```solidity
function managerOf(uint256 id) external view returns (contract ISupernetManager manager)
```

returns the child chain manager contract for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| manager | contract ISupernetManager | undefined |

### registerChildChain

```solidity
function registerChildChain(address _manager) external nonpayable returns (uint256 _id)
```

registers a new child chain with the staking contract Note: Anyone can register a child chain. Attackers registering child chains that are never used is not an attack.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _manager | address | Child chain / supernet manager |

#### Returns

| Name | Type | Description |
|---|---|---|
| _id | uint256 | of the child chain |

### releaseStakeOf

```solidity
function releaseStakeOf(address _validator, address _token, uint256 _amount) external nonpayable
```

called by child manager contract to release a validator&#39;s stake



#### Parameters

| Name | Type | Description |
|---|---|---|
| _validator | address | undefined |
| _token | address | undefined |
| _amount | uint256 | undefined |

### slashStakeOf

```solidity
function slashStakeOf(address validator, uint256 amount) external nonpayable
```

called by child manager contract to slash a validator&#39;s stakemanager collects slashed amount



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |
| amount | uint256 | undefined |

### stakeFor

```solidity
function stakeFor(uint256 _id, address _validator, address _token, uint256 _amount) external nonpayable
```

called by a staker to stake for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined |
| _validator | address | undefined |
| _token | address | undefined |
| _amount | uint256 | undefined |

### stakeOf

```solidity
function stakeOf(address validator, uint256 id) external view returns (uint256 amount)
```

returns the amount staked by a validator for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### totalStake

```solidity
function totalStake() external view returns (uint256 amount)
```

returns the total amount staked for all child chains




#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### totalStakeOf

```solidity
function totalStakeOf(address validator) external view returns (uint256 amount)
```

returns the total amount staked of a validator for all child chains



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### totalStakeOfChild

```solidity
function totalStakeOfChild(uint256 id) external view returns (uint256 amount)
```

returns the total amount staked for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### withdrawStake

```solidity
function withdrawStake(address _to, address _token, uint256 _amount) external nonpayable
```

allows a validator to withdraw released stake



#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | undefined |
| _token | address | undefined |
| _amount | uint256 | undefined |

### withdrawableStake

```solidity
function withdrawableStake(address validator) external view returns (uint256 amount)
```

returns the amount of stake a validator can withdraw



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |



## Events

### ChildManagerRegistered

```solidity
event ChildManagerRegistered(uint256 indexed id, address indexed manager)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| manager `indexed` | address | undefined |

### StakeAdded

```solidity
event StakeAdded(uint256 indexed id, address indexed _staker, address indexed validator, address _token, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| _staker `indexed` | address | undefined |
| validator `indexed` | address | undefined |
| _token  | address | undefined |
| amount  | uint256 | undefined |

### StakeRemoved

```solidity
event StakeRemoved(uint256 indexed id, address indexed validator, address _token, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| validator `indexed` | address | undefined |
| _token  | address | undefined |
| amount  | uint256 | undefined |

### StakeWithdrawn

```solidity
event StakeWithdrawn(address indexed validator, address indexed recipient, address _token, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| recipient `indexed` | address | undefined |
| _token  | address | undefined |
| amount  | uint256 | undefined |

### ValidatorSlashed

```solidity
event ValidatorSlashed(uint256 indexed id, address indexed validator, address _token, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| validator `indexed` | address | undefined |
| _token  | address | undefined |
| amount  | uint256 | undefined |



