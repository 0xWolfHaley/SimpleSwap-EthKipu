// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TokenB is ERC20 {
    constructor() ERC20 ("TokenB", "TKB"){
    _mint(msg.sender, 1000 * 10 ** decimals());
    }
}