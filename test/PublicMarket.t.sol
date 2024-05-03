//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.8.4;

import "test/TestDeploy.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";

contract PublicMarketTest is TestDeploy {
    function setUp() public {
        InitPublicMarket();
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

        target.offers(1);
        vm.prank(bob);
        uint256 bobOrder = target.makeOfferSimple(_weth2, 2 * required, _weth, offerAmount);

        console2.log("Bob Offer");
        printId(bobOrder);

        console2.log("Bob Weth Condition");
        assertGe(weth.balanceOf(bob) - bobWethBalance, offerAmount);
        console2.log("Bob Weth2 Condition");
        assertEq(bobWeth2Balance - weth2.balanceOf(bob), 2 * required);
    }

    function testExpiryOffer() public {
        vm.warp(100);

        bytes32 greenMarket = target.getMarket(_weth, _weth2);

        GiveApproval(alice, _weth);
        GiveApproval(bob, _weth2);

        vm.startPrank(alice);
        uint256 offerId = target.makeOfferExpiry(_weth, 1e18, _weth2, 3e18, 1000);
        target.makeOfferExpiry(_weth, 1e18, _weth2, 2e18, 200);
        target.makeOfferExpiry(_weth, 1e18, _weth2, 2e18, 105);
        vm.stopPrank();

        printList(greenMarket, "Green Market");
        console2.log("");
        console2.log("- - - - - - - - - - - -");
        console2.log("");

        vm.warp(300);

        vm.startPrank(bob);
        target.marketBuy(_weth2, 2e18, _weth, 5e17);
        vm.stopPrank();

        printList(greenMarket, "Green Market");

        OffersLib.Offer memory offer = RetrieveOffer(offerId);
        assertEq(offer.expiry, 1000);
        assertApproxEqAbs(offer.pay_amount, uint256(1e18) / uint256(3), 1);
        assertEq(1, target.GetListSize(greenMarket));
    }

    function testExpiryOverflow() public {
        GiveApproval(alice, _weth);

        vm.startPrank(alice);
        vm.expectRevert();
        target.makeOfferExpiry(_weth, 1e18, _weth2, 2e18, type(uint48).max + 1);
        vm.stopPrank();
    }
}
