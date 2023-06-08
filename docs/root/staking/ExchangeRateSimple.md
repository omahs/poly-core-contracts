# ExchangeRateSimple



> ExchangeRateSimple

Determine value in base token based on an amount of other tokens. TODO: Allow for one to one ratios. TODO: Allow rate to be set. TODO: This contract is not intended to be extended.



## Methods

### convert

```solidity
function convert(address _token, uint256 _amount) external view returns (uint256 _baseAmount)
```

returns the value denominated in base tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |
| _amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _baseAmount | uint256 | undefined |

### initialize

```solidity
function initialize(address _imxToken, address _maticToken) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _imxToken | address | undefined |
| _maticToken | address | undefined |

### tokenSupported

```solidity
function tokenSupported(address _token) external view returns (bool)
```

returns true if the token is supported



#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |




## Errors

### TokenNotSupported

```solidity
error TokenNotSupported(address _token)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _token | address | undefined |


