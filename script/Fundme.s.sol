//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Script.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MakeTokens is Script {

    ERC20Mock public mockNote;
    ERC20Mock public mockWCanto;

    address public _mockNote;
    address public _mockWCanto;

    address public user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    modifier BroadcastFrom(address caller) {
        vm.startBroadcast(caller);
        _;
        vm.stopBroadcast();
    }

    function setUp() public {

    }

    function run() public {

        mockNote = new ERC20Mock();
        mockWCanto = new ERC20Mock();


        vm.startBroadcast(user);

        mockNote.mint(user, 1e24);
        mockWCanto.mint(user, 1e24);

        vm.stopBroadcast();

        _mockNote = address(mockNote);
        _mockWCanto = address(mockWCanto);
        
    }


}

