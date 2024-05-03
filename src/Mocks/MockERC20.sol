// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private immutable _decimals;


    constructor(uint8 decimals_) ERC20("TestToken", "TT") {
        _decimals = decimals_;
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
    
    function mintTo(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

}
