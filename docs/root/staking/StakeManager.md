# StakeManager





Manages the stake of all child chains / rollups. Notes: * This is an upgradable contract.



## Methods

### idFor

```solidity
function idFor(address _manager) external view returns (uint256)
```

returns the child id for a child chain manager contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| _manager | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### initialize

```solidity
function initialize(address _baseToken, address _exchangeRateProxy) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _baseToken | address | undefined |
| _exchangeRateProxy | address | undefined |

### isStakeOfValidatorZero

```solidity
function isStakeOfValidatorZero(address _validator, uint256 _id, address[] _tokens) external view returns (bool)
```

Indicates if a validator no longer has any stake allocated to it 



#### Parameters

| Name | Type | Description |
|---|---|---|
| _validator | address | Address of validator to get total for. |
| _id | uint256 | Child chain Id. |
| _tokens | address[] | Array of tokens supported by the child chain. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | true if the validators stake is zero |

### isValidatorRegistered

```solidity
function isValidatorRegistered(uint256 _id, address _validator) external view returns (bool)
```

Indicate if a validator is registered for a child chain.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | Child chain id. |
| _validator | address | Address of validator. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### managerOf

```solidity
function managerOf(uint256 _id) external view returns (contract ICustomSupernetManager)
```

returns the child chain manager contract for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ICustomSupernetManager | undefined |

### registerChildChain

```solidity
function registerChildChain(address _manager) external nonpayable returns (uint256 id)
```

registers a new child chain with the staking contract Note: Anyone can register a child chain. Attackers registering child chains that are never used is not an attack.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _manager | address | Child chain / supernet manager |

#### Returns

| Name | Type | Description |
|---|---|---|
| id | uint256 | of the child chain |

### registerValidatorAndStake

```solidity
function registerValidatorAndStake(uint256 _id, address _validator, bytes, address _token, uint256 _amount) external nonpayable
```

TODO add to  IStakeManager Regster a validator, associate the validator with a staking address, and stake some value. 



#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined |
| _validator | address | undefined |
| _2 | bytes | undefined |
| _token | address | undefined |
| _amount | uint256 | undefined |

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
function slashStakeOf(address _validator, uint256 _amount) external nonpayable
```

TODO inheritdoc IStakeManager



#### Parameters

| Name | Type | Description |
|---|---|---|
| _validator | address | undefined |
| _amount | uint256 | undefined |

### stakeFor

```solidity
function stakeFor(uint256 _id, address _validator, address _token, uint256 _amount) external nonpayable
```

called by a staker to stake for a child chain. That is, msg.sender is the staker.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | Child chain identifier. |
| _validator | address | Validator to allocate stake to. |
| _token | address | ERC 20 token to stake. |
| _amount | uint256 | Number of tokens to stake. |

### stakeOf

```solidity
function stakeOf(address _staker, address _token) external view returns (uint256)
```

returns the number of tokens staked by a particular staker.  



#### Parameters

| Name | Type | Description |
|---|---|---|
| _staker | address | Staker&#39;s address. |
| _token | address | Token to get total for. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Number of tokens staked on the child chain. |

### stakeOfValidator

```solidity
function stakeOfValidator(address _validator, uint256 _id, address _token) external view returns (uint256)
```

returns the number of tokens allocated to a validator on a particular child chain.

*This function will revert if the token is not supported by the child chain. *

#### Parameters

| Name | Type | Description |
|---|---|---|
| _validator | address | Address of validator to get total for. |
| _id | uint256 | Child chain Id. |
| _token | address | Token to get total for. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Number of tokens staked on the child chain. |

### stakeOfValidatorNormalised

```solidity
function stakeOfValidatorNormalised(address _validator, uint256 _id, address[] _tokens) external view returns (uint256)
```

returns the number of tokens allocated to a validator on a particular child chain  demoninated in the base token. 



#### Parameters

| Name | Type | Description |
|---|---|---|
| _validator | address | Address of validator to get total for. |
| _id | uint256 | Child chain Id. |
| _tokens | address[] | Array of tokens supported by the child chain. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Number of tokens staked on the child chain. |

### stakersForValidator

```solidity
function stakersForValidator(address _validator, uint256 _id) external view returns (address[])
```

returns the stakers that have allocated tokens to a validator on a child chain.

*This function will revert if the token is not supported by the child chain. *

#### Parameters

| Name | Type | Description |
|---|---|---|
| _validator | address | Address of validator to get total for. |
| _id | uint256 | Child chain Id. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | Number of tokens staked on the child chain. |

### totalStakeOfChild

```solidity
function totalStakeOfChild(uint256 _id, address _token) external view returns (uint256)
```

returns the total number of tokens of a particular type staked for a child chain.

*This function will revert if the token is not supported by the child chain. *

#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | Child chain Id |
| _token | address | Token to get total for. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Number of tokens staked on the child chain. |

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
function withdrawableStake(address _validator) external view returns (uint256)
```

returns the amount of stake a validator can withdraw



#### Parameters

| Name | Type | Description |
|---|---|---|
| _validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



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

### CouldNotFindStakerForChainValidator

```solidity
event CouldNotFindStakerForChainValidator(uint256 _id, address _validator, address _staker)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _id  | uint256 | undefined |
| _validator  | address | undefined |
| _staker  | address | undefined |

### CouldNotFindValidatorForChain

```solidity
event CouldNotFindValidatorForChain(uint256 _id, address _validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _id  | uint256 | undefined |
| _validator  | address | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

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



## Errors

### AlreadyStakedOnChildChain

```solidity
error AlreadyStakedOnChildChain(address _staker, uint256 _id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _staker | address | undefined |
| _id | uint256 | undefined |

### DeregisterRequestNotFromLinkedStaker

```solidity
error DeregisterRequestNotFromLinkedStaker(address _linkedStaker)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _linkedStaker | address | undefined |

### InsufficientWithdrawableBalance

```solidity
error InsufficientWithdrawableBalance(address _staker, address _token, uint256 _withdrawableBalance, uint256 withdrawalRequest)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _staker | address | undefined |
| _token | address | undefined |
| _withdrawableBalance | uint256 | undefined |
| withdrawalRequest | uint256 | undefined |

### InvalidChildChainId

```solidity
error InvalidChildChainId(uint256 _id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined |

### StakerAlreadyLinkedToValidator

```solidity
error StakerAlreadyLinkedToValidator(uint256 _id, address _staker)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined |
| _staker | address | undefined |

### StakerNotStakedOnChain

```solidity
error StakerNotStakedOnChain(address _staker, uint256 _id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _staker | address | undefined |
| _id | uint256 | undefined |

### TokenNotSupported

```solidity
error TokenNotSupported(address _token)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |

### ValidatorAlreadyRegistered

```solidity
error ValidatorAlreadyRegistered(uint256 _id, address _validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined |
| _validator | address | undefined |

### ValidatorNotRegistered

```solidity
error ValidatorNotRegistered(uint256 _id, address _validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined |
| _validator | address | undefined |


