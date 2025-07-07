# SimpleSwap - A Minimal Uniswap V2 Clone

[![Solidity Version](https://img.shields.io/badge/Solidity-^0.8.0-blue)](https://soliditylang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

SimpleSwap is a decentralized exchange (DEX) protocol implementing an automated market maker (AMM) model, inspired by Uniswap V2. It allows users to swap ERC20 tokens and provide liquidity to earn trading fees.

---

## 📄 Overview

**Contract Name:** `SimpleSwap`  
**Author:** Juan Cruz Gonzalez  
**License:** MIT  
**Language:** Solidity ^0.8.0  
**Base Token:** OpenZeppelin ERC20

This contract manages token swaps and liquidity pools for any two ERC20 tokens. Liquidity providers earn LP tokens proportional to their share in the pool.

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [📊 Contract Structure](#-contract-structure)
- [🔧 API Reference](#-api-reference)
- [🚀 Deployment](#-deployment)
- [💡 Usage Examples](#-usage-examples)
- [🧪 Testing](#-testing)
- [🔒 Security](#-security)
- [📜 License](#-license)

---

## ✨ Features

- **Liquidity Provision**: Add or remove token pairs from the pool.
- **Token Swapping**: Swap tokens based on constant product formula.
- **LP Token Minting**: Issues LP tokens to liquidity providers.
- **Reserve Management**: Tracks and updates token reserves.
- **Price and Output Estimation**: Utility functions for price and swap output estimation.

---
## 📊 Contract Structure

```
//Deploys the contract and initializes the LP token with name LPToken and symbol LPT.
constructor(address initialOwner)

//Stores the reserves of token pairs in sorted order.
struct Reserve {
    uint reserve0;
    uint reserve1;
}
```

---

## 🔧 API Reference

### Core Functions

### ```addLiquidity(...)```
##### Adds liquidity to the token pair pool.

- Mints LP tokens to the to address.

- Updates internal reserves.

- Emits LiquidityAdded.

### ```removeLiquidity(...)```

##### Removes liquidity and burns LP tokens.

- Transfers proportional amounts of tokens back to the user.

- Emits LiquidityRemoved.

### ```swapExactTokensForTokens(...)```

##### Swaps an exact amount of input tokens for as many output tokens as possible.

- Uses constant product formula.

- Updates reserves.

- Emits TokensSwapped.

### ```getReserves(tokenA, tokenB)```

- Returns the current reserves for the token pair.

### ```getPrice(tokenA, tokenB)```

- Returns the price of tokenA in terms of tokenB.

### ```getAmountOut(tokenIn, tokenOut, amountIn)```

- Estimates the amount of tokenOut returned for a given input amount.

### 📦 Internal Utilities

```_computeLiquidityAmounts(...)```
Calculates optimal token amounts based on existing reserves and user-provided min/desired values.

```calculateLiquidity(...)```
Computes how many LP tokens to mint based on input amounts and current reserves.

```updateReserves(...)```
Updates stored reserves after liquidity changes or swaps.

```_sqrt(...)```
Efficient square root implementation using the Babylonian method.

### 📝 Events

```LiquidityAdded```: Emitted when liquidity is added.

```LiquidityRemoved```: Emitted when liquidity is removed.

```TokensSwapped```: Emitted when tokens are swapped.

## 📎 Requirements & Assumptions

- Only works with ERC-20 tokens.

- Pairs are sorted internally for consistent tracking.

- Assumes non-zero token addresses and distinct token pairs.

---

## 🚀 Deployment

### Requirements
 - Node.js v16+

 - Hardhat/Foundry

```
//Clone repository
git clone https://github.com/your-repo/simpleswap.git
cd simpleswap

//Install dependencies
npm install
```

---

## 💡 Usage Examples

### Adding Liquidity

```
simpleSwap.addLiquidity(
    tokenA, tokenB,
    amountADesired, amountBDesired,
    amountAMin, amountBMin,
    msg.sender,
    block.timestamp + 300
);
```

### Swapping Tokens

```
simpleSwap.swapExactTokensForTokens(
    amountIn,
    amountOutMin,
    [tokenIn, tokenOut],
    msg.sender,
    block.timestamp + 300
);
```

---

## 🧪 Testing

```
# Run tests
npx hardhat test

# Generate coverage report
npx hardhat coverage
```

---

## 🔒 Security

### Security Considerations

- No reentrancy guard is implemented — should be added in production.

- No slippage protection outside of amountMin checks.

- Use proper allowance and token approval for swaps and liquidity actions.

### Audit Status

⚠️ Warning: This code is unaudited. Use at your own risk.

---

## 📜 License

This project is licensed under the MIT License - See LICENSE for full details.



