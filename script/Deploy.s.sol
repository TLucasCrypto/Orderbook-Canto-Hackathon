//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Script.sol";
import {PublicMarket} from "src/PublicMarket.sol";
import {OfferValidator} from "src/Validator.sol";
import {ERC1967Proxy} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";


contract Deploy is Script {

    PublicMarket public market;
    OfferValidator public validator;
    ERC1967Proxy public proxy;

    ERC20Mock public mockNote;
    ERC20Mock public mockWCanto;

    address _mockNote;
    address _mockWCanto;
    

    function setUp() public {
        mockNote = new ERC20Mock();
        mockWCanto = new ERC20Mock();

        vm.startBroadcast(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        // mockNote.mint(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38, 1e24);
        // mockWCanto.mint(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38, 1e24);
        mockNote.mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1e24);
        mockWCanto.mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1e24);
        vm.stopBroadcast();

        _mockNote = address(mockNote);
        _mockWCanto = address(mockWCanto);
    }

    function run() public {

        bytes memory initData = abi.encodeWithSignature("__OfferValidator_init()");
        vm.startBroadcast(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

        validator = new OfferValidator();
        proxy = new ERC1967Proxy(address(validator), initData);

        market = new PublicMarket(address(proxy));

        mockNote.approve(address(market), 1e24);
        mockWCanto.approve(address(market), 1e24);

        console2.log(mockNote.balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    
        market.makeOfferSimple(_mockNote, 5e18, _mockWCanto, 20e18);
        // market.makeOfferSimple(_mockNote, 5.48e18, _mockWCanto, 22e18);
        // market.makeOfferSimple(_mockNote, 4.7e18, _mockWCanto, 21e18);
        // market.makeOfferSimple(_mockNote, 6e18, _mockWCanto, 27e18);
        // market.makeOfferSimple(_mockNote, 6.5e18, _mockWCanto, 29e18);

        // market.makeOfferSimple(_mockWCanto, 20e18, _mockNote, 5.2e18);
        // market.makeOfferSimple(_mockWCanto, 22e18, _mockNote, 5.8e18);
        // market.makeOfferSimple(_mockWCanto, 21e18, _mockNote, 5.3e18);
        // market.makeOfferSimple(_mockWCanto, 25e18, _mockNote, 6.3e18);
        // market.makeOfferSimple(_mockWCanto, 29e18, _mockNote, 7.3e18);
        vm.stopBroadcast();
    }
}