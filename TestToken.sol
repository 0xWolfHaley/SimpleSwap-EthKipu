// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {

    constructor() ERC20("TestToken", "TTK") {
        _mint(msg.sender, 1000 * 10 ** decimals());
        }
}