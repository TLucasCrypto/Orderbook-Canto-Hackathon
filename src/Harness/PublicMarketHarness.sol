//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import "src/PublicMarket.sol";

contract PublicMarketHarness is PublicMarket {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using OptionsLib for OptionsLib.Option;

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
            greenWant += offers[greenId].buyAmount();
            _popHead(greenMarket, greenId);
            (, greenId) = marketLists[greenMarket].getAdjacent(0, true);
        }
        while (redId != 0) {
            redRemaining += offers[redId].pay_amount;
            redWant += offers[redId].buyAmount();
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

    function _popHead(bytes32 market, uint256 orderId) private {
        marketLists[market].popFront();
        delete offers[orderId];
    }
}
