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

        market.makeOfferSimple(_mockNote, 5.34e18, _wCanto, 5.34e18 * 4.5);
        market.makeOfferSimple(_mockNote, 5.48e18, _wCanto, 5.48e18 * 4.7);
        market.makeOfferSimple(_mockNote, 4.78e18, _wCanto, 4.78e18 * 4.65);
        market.makeOfferSimple(_mockNote, 6.12e18, _wCanto, 6.12e18 * 4.3);
        market.makeOfferSimple(_mockNote, 6.55e18, _wCanto, 6.55e18 * 4.51);
        market.makeOfferSimple(_mockNote, 3.42e18, _wCanto, 3.42e18 * 4.8);
        market.makeOfferSimple(_mockNote, 11.78e18, _wCanto, 11.78e18 * 4.35);
        market.makeOfferSimple(_mockNote, 8.15e18, _wCanto,  8.15e18 * 4.29);
        market.makeOfferSimple(_mockNote, 1.35e18, _wCanto, 1.35e18 * 4.99);
        market.makeOfferSimple(_mockNote, 9.58e18, _wCanto, 9.58e18 * 4.78);
        market.makeOfferSimple(_mockNote, 8.90e18, _wCanto, 8.90e18 * 4.23);

        market.makeOfferSimple(_wCanto, 5.2e18 * 3.98, _mockNote, 5.2e18);
        market.makeOfferSimple(_wCanto, 5.8e18 * 3.77, _mockNote, 5.8e18);
        market.makeOfferSimple(_wCanto, 5.3e18 * 3.82, _mockNote, 5.3e18);
        market.makeOfferSimple(_wCanto, 6.3e18 * 3.55, _mockNote, 6.3e18);
        market.makeOfferSimple(_wCanto, 7.3e18 * 3.72, _mockNote, 7.3e18);
        market.makeOfferSimple(_wCanto, 8.21e18 * 3.12, _mockNote, 8.21e18);
        market.makeOfferSimple(_wCanto, 11.78e18 * 3.65, _mockNote, 11.78e18);
        market.makeOfferSimple(_wCanto, 2.8e18 * 3.89, _mockNote, 2.8e18);
        market.makeOfferSimple(_wCanto, 1.78e18 * 3.91, _mockNote, 1.78e18);
        market.makeOfferSimple(_wCanto, 9.25e18 * 3.5, _mockNote, 9.25e18);
        market.makeOfferSimple(_wCanto, 4.34e18 * 3.58, _mockNote, 4.34e18);
    }
}

