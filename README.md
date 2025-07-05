# SimpleSwap - A Minimal Uniswap V2 Clone

[![Solidity Version](https://img.shields.io/badge/Solidity-^0.8.0-blue)](https://soliditylang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

SimpleSwap is a decentralized exchange (DEX) protocol implementing an automated market maker (AMM) model, inspired by Uniswap V2. It allows users to swap ERC20 tokens and provide liquidity to earn trading fees.

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [📊 Contract Structure](#-contract-structure)
- [🚀 Deployment](#-deployment)
- [💡 Usage Examples](#-usage-examples)
- [🔧 API Reference](#-api-reference)
- [🧪 Testing](#-testing)
- [🔒 Security](#-security)
- [📜 License](#-license)

---

## ✨ Features

| Feature     | Description                                |
|-------------|--------------------------------------------|
| AMM Model   | Constant product formula (x . y = k)       |
| LP Tokens   | ERC20 "SSLP" tokens track liquidity shares |
| Swap Fees   | 0.3% fee on trades                         |
| Protections | Slippage controls and deadline enforcement |

---
## 📊 Contract Structure

```
// Core Storage
mapping(address => mapping(address => Pool)) public pools;

struct Pool {
    uint256 reserveA;
    uint256 reserveB;
}
```

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
await simpleSwap.addLiquidity(
    TOKEN_A, 
    TOKEN_B,
    1e18,                // 1.0 Token A
    2000e18,            // 2000 Token B
    0.9e18,             // Min 0.9 Token A
    1800e18,            // Min 1800 Token B
    recipientAddress,
    Date.now() + 300    // 5 min deadline
);
```

---

## 🔧 API Reference

### Core Functions

| `Function`	               | `Parameters`	                                                                          | `Returns`                       |
|------------------------------|------------------------------------------------------------------------------------------|---------------------------------|
| `addLiquidity`	           | `(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline)` | `(amountA, amountB, liquidity)` |
| `swapExactTokensForTokens`   | `(amountIn, amountOutMin, path, to, deadline)`                                           | `amounts[]`                     |

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

### Audit Status

⚠️ Warning: This code is unaudited. Use at your own risk.

### Critical Checks
```
require(deadline >= block.timestamp, "EXPIRED");
require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT");
```

---

## 📜 License

This project is licensed under the MIT License - See LICENSE for full details.



