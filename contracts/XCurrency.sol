// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XCurrency is ERC20 {
    constructor(uint256 initialSupply) ERC20("X Currency", "X20") {
        _mint(msg.sender, initialSupply);
    }
}