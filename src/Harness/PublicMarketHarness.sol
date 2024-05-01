//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import "src/PublicMarket.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract PublicMarketHarness is PublicMarket {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using Math for uint256;

    constructor(address _validator) PublicMarket(_validator) {}

    function GetBuyAmount(
        uint256 pay_amount,
        uint256 price
    ) public returns (uint256) {
        return price.mulDiv(pay_amount, OffersLib.SCALE_FACTOR);
    }

    function GetBuyAmount(
        uint256 id
    ) public returns (uint256) {
        OffersLib.Offer storage offer = offers[id];
        return offer.priceToBuy();
    }
    
    function GetReversePrice(uint256 orderId) public returns (uint256) {
        OffersLib.Offer storage offer = offers[orderId];
        return offer.reversePrice();
    }
    function CleanMarkets(
        address tokenOne,
        address tokenTwo
    )
        public
        returns (
            uint256 greenRemaining,
            uint256 greenWant,
            uint256 redRemaining,
            uint256 redWant
        )
    {
        bytes32 greenMarket = getMarket(tokenOne, tokenTwo);
        bytes32 redMarket = getMarket(tokenTwo, tokenOne);
        (, uint256 greenId) = marketLists[greenMarket].getAdjacent(0, true);
        (, uint256 redId) = marketLists[redMarket].getAdjacent(0, true);

        while (greenId != 0) {
            greenRemaining += offers[greenId].pay_amount;
            greenWant += offers[greenId].priceToBuy();
            _popHead(greenMarket, greenId);
            (, greenId) = marketLists[greenMarket].getAdjacent(0, true);
        }
        while (redId != 0) {
            redRemaining += offers[redId].pay_amount;
            redWant += offers[redId].priceToBuy();
            _popHead(redMarket, redId);
            (, redId) = marketLists[redMarket].getAdjacent(0, true);
        }
    }

    function CleanBalance(
        address user,
        address token
    ) public returns (uint256 balance) {
        balance = userBalances[user][token];
        delete userBalances[user][token];
    }

    function GetMarketList(bytes32 market) public view returns (uint256[] memory) {
        StructuredLinkedList.List storage list = marketLists[market];
        uint256 len = list.sizeOf();
        uint256[] memory items = new uint256[](len);

        uint256 current = list.list[0][true];
        for (uint256 i; i < len; ++i) {
            items[i] = current;
            (, current) = list.getNextNode(current);
        }

        return items;
    }


}
