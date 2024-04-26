//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.8.4;


import "test/TestDeploy.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";
import {OptionsLib} from "src/Libraries/OptionsLib.sol";

contract PublicMarketTest is TestDeploy { 

    function setUp() public {
        InitPublicMarket();
    }

    function testRandomStuff() public {


    }

    function testMakeOffer() public {
        uint256 offerAmount = 1e18;
        uint256 required = 1.5e18;
        
        uint256 aliceBalance = weth.balanceOf(alice);
        console2.log("Alice Offer");
        uint256 orderTwo = CreateAndPrintOffer(alice, _weth, offerAmount, _weth2, required);
        
        assertEq(aliceBalance - weth.balanceOf(alice), offerAmount);

        GiveApproval(bob, _weth2);
        uint256 bobWethBalance = weth.balanceOf(bob);
        uint256 bobWeth2Balance = weth2.balanceOf(bob);
        vm.prank(bob);
        uint256 bobOrder = target.makeOffer(_weth2, 2 * required, _weth, offerAmount);
        
        console2.log("Bob Offer");
        PrintOffer(bobOrder);

        console2.log("Bob Weth Condition");
        assertGe(weth.balanceOf(bob) - bobWethBalance, offerAmount);
        console2.log("Bob Weth2 Condition");
        assertEq(bobWeth2Balance - weth2.balanceOf(bob), 2 * required);


    }
}