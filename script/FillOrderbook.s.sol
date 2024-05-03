//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Script.sol";
import {PublicMarket} from "src/PublicMarket.sol";


contract Deploy is Script {

    PublicMarket public market;

    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address _market = 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d;

    function setUp() public {
        market = PublicMarket(_market);
    }

    function run() public {

        vm.startBroadcast(user);

        

        vm.stopBroadcast();

    
        // market.makeOfferSimple(_mockNote, 5e18, _mockWCanto, 20e18);
        // market.makeOfferSimple(_mockNote, 5.48e18, _mockWCanto, 22e18);
        // market.makeOfferSimple(_mockNote, 4.7e18, _mockWCanto, 21e18);
        // market.makeOfferSimple(_mockNote, 6e18, _mockWCanto, 27e18);
        // market.makeOfferSimple(_mockNote, 6.5e18, _mockWCanto, 29e18);

        // market.makeOfferSimple(_mockWCanto, 20e18, _mockNote, 5.2e18);
        // market.makeOfferSimple(_mockWCanto, 22e18, _mockNote, 5.8e18);
        // market.makeOfferSimple(_mockWCanto, 21e18, _mockNote, 5.3e18);
        // market.makeOfferSimple(_mockWCanto, 25e18, _mockNote, 6.3e18);
        // market.makeOfferSimple(_mockWCanto, 29e18, _mockNote, 7.3e18);
        
    }
}