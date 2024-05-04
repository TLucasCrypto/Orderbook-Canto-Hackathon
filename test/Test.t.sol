//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.8.4;


import "lib/forge-std/src/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//import {IOfferValidator} from "src/Libraries/OffersLib.sol";


contract MathTest is Test {


    address mockNote = 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d;
    address wCanto = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address market = 0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1;

    function setUp() public {
        vm.createSelectFork("localhost"); 
    }

    function testBalances() public {
        console2.log(IERC20(mockNote).balanceOf(user));
        console2.log(IERC20(wCanto).balanceOf(user));

        console2.log(IERC20(mockNote).allowance(user, market));
        console2.log(IERC20(wCanto).allowance(user, market));

    }

}