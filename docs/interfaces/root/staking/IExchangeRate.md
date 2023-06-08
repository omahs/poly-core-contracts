# IExchangeRate



> IStakeManager

Interface for determining exchange rates.



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


