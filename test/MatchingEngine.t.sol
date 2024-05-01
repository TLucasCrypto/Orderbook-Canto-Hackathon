//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.8.4;

import "test/TestDeploy.sol";
import {Offers} from "test/Offers.sol";


contract MatchingEngineTest is TestDeploy, Offers {
    using OffersLib for OffersLib.Offer;
    using SoladySafeCastLib for uint256;

    struct Balances {
        uint256 aliceWeth;
        uint256 aliceWeth2;
        uint256 bobWeth;
        uint256 bobWeth2;
    }

    function setUp() public {
        InitPublicMarket();
    }

    function testMarketBuy() public {
        (bytes32 greenMarket, bytes32 redMarket) = target.GetMarkets(
            _weth,
            _weth2
        );

        uint256 bobPay = 2.7e18;
        uint256 bobWant = 2.8e18;

        console2.log("Bob Pay    :", bobPay);
        console2.log("Bob Want   :", bobWant);
        console2.log("");

        vm.startPrank(alice);
        weth.approve(_target, type(uint256).max);
        target.makeOfferSimple(_weth, 1e18, _weth2, 8.1e17);
        target.makeOfferSimple(_weth, 1.5e18, _weth2, 1.2e18);
        target.makeOfferSimple(_weth, 1.1e18, _weth2, 1.8e18);
        target.makeOfferSimple(_weth, 1.8e17, _weth2, 1.9e18);

        vm.stopPrank();

        printList(greenMarket, "Green Market");

        console2.log("");
        console2.log("- - - - - - - - - - - -");
        console2.log("");
        uint256 bobBalanceWeth = weth.balanceOf(bob);
        uint256 bobBalanceWeth2 = weth2.balanceOf(bob);
        vm.startPrank(bob);
        weth2.approve(_target, type(uint256).max);
        uint256 remaining = target.marketBuy(_weth2, bobPay, _weth, bobWant);
        vm.stopPrank();

        printList(greenMarket, "Green Market");
        (uint256 marketRemaining, uint256 marketWant, , ) = target.CleanMarkets(
            _weth,
            _weth2
        );

        console2.log("");
        console2.log("- - - - - - - - - - - -");
        console2.log("");

        console2.log("Alice Weth : ", target.userBalances(alice, _weth));
        console2.log("Alice Weth2: ", target.userBalances(alice, _weth2));

        console2.log("Bob Weth   : ", weth.balanceOf(bob));
        console2.log("Bob Weth2  : ", weth2.balanceOf(bob));

        console2.log("");
        console2.log("Remaining  : ", remaining);
        console2.log("Calc       : ", CalcPrice(bobPay, bobWant, remaining));

        assertGe(target.userBalances(alice, _weth2) + remaining, bobPay);
        assertGe(weth.balanceOf(bob) - bobBalanceWeth + CalcPrice(bobPay, bobWant, remaining), bobWant);
        assertGe(target.userBalances(alice, _weth2) + marketWant, 8e17 + 1.2e18 + 1.8e18 + 1.9e18);
        assertGe(weth.balanceOf(bob) - bobBalanceWeth + marketRemaining, 1e18 + 1.5e18 + 1.1e18 + 1.8e17);
    }


    function testFuzzMarketBuy(uint256) public {
        uint256 r1;
        uint256 r2;

        uint256 max = 1e15;
        uint256 offset = 1e4;
        uint256 depth = 3;

        bytes32 greenMarket = target.getMarket(_weth, _weth2);

        GiveApproval(alice, _weth);
        GiveApproval(bob, _weth2);

        uint256 aliceR1Sum;
        uint256 aliceR2Sum;

        for (uint256 i; i < depth; ++i) {
            r1 = (_random() % max) + offset;
            r2 = (_random() % max) + offset;

            userOffer(alice, _weth, r1, _weth2, r2);
            aliceR1Sum += r1;
            aliceR2Sum += r2;
        }

        printList(greenMarket, "Market");

        console2.log("");
        console2.log("- - - - - - - - - - - -");
        console2.log("");

        r1 = (_random() % max) + offset;
        r2 = (_random() % max) + offset;

        uint256 bobBalanceWethBefore = weth.balanceOf(bob);
        uint256 bobBalanceWeth2Before = weth2.balanceOf(bob);

        vm.prank(bob);
        uint256 bobRemaining = target.marketBuy(_weth2, r1, _weth, r2);

        printList(greenMarket, "Market After ");

        (uint256 marketRemaining, uint256 marketWant, , ) = target.CleanMarkets(
            _weth,
            _weth2
        );

        console2.log("Bob Pays      : ", r1);
        console2.log("Bob Want      : ", r2);
        console2.log("Bob Remaining : ", bobRemaining);
        console2.log("");
        console2.log("Market Remain : ", marketRemaining);
        console2.log("Market Want   : ", marketWant);
        console2.log("");
        console2.log("Bob Weth      : ", weth.balanceOf(bob) - bobBalanceWethBefore);
        console2.log("Bob Weth2     : ", weth2.balanceOf(bob));
        console2.log("");
        console2.log("Alice Weth2   : ", target.userBalances(alice, _weth2));
        console2.log("Alice r1 Sum  : ", aliceR1Sum);
        console2.log("Alice r2 Sum  : ", aliceR2Sum);

        console2.log("");
        console2.log("Alice Weth2 Condition");
        assertGe(target.userBalances(alice, _weth2) + bobRemaining, r1);
        console2.log("Bob Remaining Condition");
        assertGe(weth.balanceOf(bob) - bobBalanceWethBefore + CalcPrice(r1, r2, bobRemaining) + depth, r2);
        console2.log("Alice MarketWant Condition");
        assertGe(target.userBalances(alice, _weth2) + marketWant + depth, aliceR2Sum);
    }

    function testFuzzMarketOffers(uint256) public {
        uint256 r1;
        uint256 r2;

        uint256 max = 1e20;
        uint256 offset = 1e8;
        uint256 loops = 8;

        uint256 bobWethBalanceBefore = weth.balanceOf(bob);

        vm.startPrank(alice);
        weth.approve(_target, type(uint256).max);
        // weth2.approve(_target, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        // weth.approve(_target, type(uint256).max);
        weth2.approve(_target, type(uint256).max);
        vm.stopPrank();

        uint256[] memory aliceR1 = new uint256[](loops);
        uint256[] memory aliceR2 = new uint256[](loops);
        uint256[] memory bobR1 = new uint256[](loops);
        uint256[] memory bobR2 = new uint256[](loops);

        for (uint256 i; i < loops; ++i) {
            r1 = (_random() % max) + offset;
            r2 = (_random() % max) + offset;

            userOffer(alice, _weth, r1, _weth2, r2);
            aliceR1[i] = r1;
            aliceR2[i] = r2;
        }

        for (uint256 i; i < loops; ++i) {
            r1 = (_random() % max) + offset;
            r2 = (_random() % max) + offset;

            userOffer(bob, _weth2, r1, _weth, r2);
            bobR1[i] = r1;
            bobR2[i] = r2;
        }

        printList(target.getMarket(_weth, _weth2), "Green Market");
        printList(target.getMarket(_weth2, _weth), "Red Market");

        Balances memory userBalances = Balances({
            aliceWeth: target.userBalances(alice, _weth),
            aliceWeth2: target.userBalances(alice, _weth2),
            bobWeth: weth.balanceOf(bob) - bobWethBalanceBefore,
            bobWeth2: weth2.balanceOf(bob)
        });

        console2.log("Alice Weth  : ", userBalances.aliceWeth);
        console2.log("Alice Weth2  : ", userBalances.aliceWeth2);
        console2.log("Bob Weth  : ", userBalances.bobWeth);
        console2.log("Bob Weth2  : ", userBalances.bobWeth2);
        console2.log("- - - - - - - - - - - -");


        (
            uint256 greenRemaining,
            uint256 greenWant,
            uint256 redRemaining,
            uint256 redWant
        ) = target.CleanMarkets(_weth, _weth2);



        Balances memory randomBalances;
        // aliceWeth = sum of aliceR1 values or pay amounts
        // aliceWeth2 = sum of aliceR2 values or want amounts
        // bobWeth = sum of bobR1 values or pay amounts
        // bobWeth2 = sum of bobR2 values or want amounts
        for (uint256 i; i < loops; ++i) {
            randomBalances.aliceWeth += aliceR1[i];
            randomBalances.aliceWeth2 += aliceR2[i];
            randomBalances.bobWeth += bobR1[i];
            randomBalances.bobWeth2 += bobR2[i];
        }

        console2.log("Alice Balance Condition");
        assertGe(target.userBalances(alice, _weth2) + greenWant + 1e3, randomBalances.aliceWeth2);
        console2.log("Bob Balance Condition");
        assertGe(userBalances.bobWeth + redWant + 1e3, randomBalances.bobWeth2);
        console2.log("Contract Weth Balance Condition");
        console2.log("Contract Weth          : ", weth.balanceOf(_target));
        console2.log("Contract Required Weth : ", greenRemaining);
        assertGe(weth.balanceOf(_target), greenRemaining);
        console2.log("Contract Weth2          : ", weth2.balanceOf(_target) - target.userBalances(alice, _weth2));
        console2.log("Contract Required Weth2 : ", redRemaining);
        console2.log("Contract Weth2 Balance Condition");
        assertGe(weth2.balanceOf(_target), redRemaining);
    }

    function DebugIndivdual(
        uint256 alicePay,
        uint256 aliceBuy,
        uint256 bobPay,
        uint256 bobBuy
    ) public {
        (bytes32 greenMarket, bytes32 redMarket) = target.GetMarkets(
            _weth,
            _weth2
        );

        vm.prank(alice);
        weth.approve(_target, type(uint256).max);

        vm.prank(bob);
        weth2.approve(_target, type(uint256).max);

        vm.prank(alice);
        target.makeOfferSimple(_weth, alicePay, _weth2, aliceBuy);
        vm.prank(bob);
        target.makeOfferSimple(_weth2, bobPay, _weth, bobBuy);

        console2.log("Alice Pays : ", alicePay);
        console2.log("Alice Want : ", aliceBuy);
        console2.log("Bob Pays   : ", bobPay);
        console2.log("Bob Want   : ", bobBuy);
        console2.log("");

        printList(greenMarket, "Green Market Initial");
        printList(redMarket, "Red Market Initial");
        console2.log("");

        // target.SimpleMarketMatch(_weth, _weth2);

        // console2.log("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        // console2.log("");

        // printList(greenMarket, "Green Market Final");
        // printList(redMarket, "Red Market Final");
        // console2.log("");

        // console2.log("Alice Weth2: ", target.userBalances(alice, _weth2));
        // console2.log("Bob Weth   : ", target.userBalances(bob, _weth));
    }

    function testDebug() public {
        (
            uint256[] memory alicePay,
            uint256[] memory aliceBuy,
            uint256[] memory bobPay,
            uint256[] memory bobBuy
        ) = getOffers();

        uint256 item = 6;
        
        DebugIndivdual(
            alicePay[item],
            aliceBuy[item],
            bobPay[item],
            bobBuy[item]
        );

        // DebugIndivdual(
        //     405586178452820382218987278,
        //     437809479060803100646319891,
        //     511627432897446258298922268,
        //     405586178452820382218987278
        // );
    }
}