// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.1.0/token/ERC20/ERC20.sol";

contract DinoXCoin is ERC20 {
    constructor() ERC20("DinoX Coin", "DNXC") {
        _mint(msg.sender, 160000000 * 10 ** decimals());
    }
}
