# ICustomSupernetManager

*Polygon Technology (@gretzke)*

> ICustomSupernetManager

Manages validator access and syncs voting power between the stake manager and validator set on the child chain

*Implements the base SupernetManager contract*

## Methods

### enableStaking

```solidity
function enableStaking() external nonpayable
```

enables staking after successful initialisation of the child chain

*only callable by owner*


### finalizeGenesis

```solidity
function finalizeGenesis() external nonpayable
```

finalizes initial genesis validator set

*only callable by owner*


### genesisSet

```solidity
function genesisSet() external view returns (struct GenesisValidator[])
```

returns the genesis validator set with their balances




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | GenesisValidator[] | undefined |

### getListOfStakingTokens

```solidity
function getListOfStakingTokens() external view returns (address[])
```

returns list of tokens supported by this child chain.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### getValidator

```solidity
function getValidator(address validator_) external view returns (struct Validator)
```

returns validator instance based on provided address



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator_ | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | Validator | undefined |

### onInit

```solidity
function onInit(uint256 id) external nonpayable
```

called when a new child chain is registered



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

### onL2StateReceive

```solidity
function onL2StateReceive(uint256, address sender, bytes data) external nonpayable
```

called by the exit helpers to either release the stake of a validator or slash it

*can only be synced from child after genesis*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |

### onStake

```solidity
function onStake(address validator, uint256 amount) external nonpayable
```

called when a validator stakes



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |
| amount | uint256 | undefined |

### register

```solidity
function register(uint256[2] signature, uint256[4] pubkey) external nonpayable
```

registers the public key of a validator



#### Parameters

| Name | Type | Description |
|---|---|---|
| signature | uint256[2] | undefined |
| pubkey | uint256[4] | undefined |

### stakingTokenSupported

```solidity
function stakingTokenSupported(address _token) external view returns (bool)
```

returns true if token is supported by this child chain.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### whitelistValidators

```solidity
function whitelistValidators(address[] validators_) external nonpayable
```

Allows to whitelist validators that are allowed to stake

*only callable by owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| validators_ | address[] | undefined |

### withdrawSlashedStake

```solidity
function withdrawSlashedStake(address to, address _token) external nonpayable
```

Withdraws slashed MATIC of slashed validators

*only callable by owner*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| _token | address | undefined |



## Events

### AddedToWhitelist

```solidity
event AddedToWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### GenesisFinalized

```solidity
event GenesisFinalized(uint256 amountValidators)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amountValidators  | uint256 | undefined |

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### StakingEnabled

```solidity
event StakingEnabled()
```






### ValidatorDeactivated

```solidity
event ValidatorDeactivated(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator  | address | undefined |

### ValidatorRegistered

```solidity
event ValidatorRegistered(address indexed validator, uint256[4] blsKey)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| blsKey  | uint256[4] | undefined |



## Errors

### InvalidSignature

```solidity
error InvalidSignature(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

### Unauthorized

```solidity
error Unauthorized(string message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| message | string | undefined |


