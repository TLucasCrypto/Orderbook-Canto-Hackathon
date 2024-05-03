//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Script.sol";
import {PublicMarket} from "src/PublicMarket.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DeployDemo is Script {

    PublicMarket public market;
    address public _market;

    ERC20Mock public mockNote;
    ERC20Mock public mockWCanto;

    address public _mockNote;
    address public _mockWCanto;

    address public user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public _note = 0x4e71A2E537B7f9D9413D3991D37958c0b5e1e503;
    address public _wCanto = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;

    modifier BroadcastFrom(address caller) {
        vm.startBroadcast(caller);
        _;
        vm.stopBroadcast();
    }

    function setUp() public {

        vm.startBroadcast(user);
        mockNote = new ERC20Mock();
        mockWCanto = new ERC20Mock();
        market = new PublicMarket();

        mockNote.mint(user, 1e24);
        mockWCanto.mint(user, 1e24);

        vm.stopBroadcast();

        _market = address(market);
        _mockNote = address(mockNote);
        _mockWCanto = address(mockWCanto);
    }

    function run() public {

        bytes memory wCantoData = abi.encodeWithSignature("deposit()");
        
    

        vm.startBroadcast(user);
        _wCanto.call{value: 8000e18}(wCantoData);

        vm.stopBroadcast();

        approveMarket();
        makeOrders();
        //market.makeOfferSimple(_mockNote, 5e18, _mockWCanto, 20e18);
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


    function approveMarket() internal BroadcastFrom(user) {
        bytes memory approveData = abi.encodeWithSignature("approve(address,uint256)", _market, type(uint256).max);
        bool ok;
        (ok, ) = _note.call(approveData);
        require(ok, "Note approve Fail");
        (ok, ) = _wCanto.call(approveData);
        require(ok, "wCanto approve Fail");
        (ok, ) = _mockNote.call(approveData);
        require(ok, "MockNote approve Fail");
        (ok, ) = _mockWCanto.call(approveData);
        require(ok, "MockCanto approve Fail");
    }

    function makeOrders() internal BroadcastFrom(user) {

        market.makeOfferSimple(_mockNote, 5e18, _mockWCanto, 20e18);
        market.makeOfferSimple(_mockNote, 5.48e18, _mockWCanto, 22e18);
        market.makeOfferSimple(_mockNote, 4.7e18, _mockWCanto, 21e18);
        market.makeOfferSimple(_mockNote, 6e18, _mockWCanto, 27e18);
        market.makeOfferSimple(_mockNote, 6.5e18, _mockWCanto, 29e18);

        market.makeOfferSimple(_mockWCanto, 20e18, _mockNote, 5.2e18);
        market.makeOfferSimple(_mockWCanto, 22e18, _mockNote, 5.8e18);
        market.makeOfferSimple(_mockWCanto, 21e18, _mockNote, 5.3e18);
        market.makeOfferSimple(_mockWCanto, 25e18, _mockNote, 6.3e18);
        market.makeOfferSimple(_mockWCanto, 29e18, _mockNote, 7.3e18);
    }
}

