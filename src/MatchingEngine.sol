//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {SimpleMarket, IOrderToken, SoladySafeCastLib, StructuredLinkedList, OffersLib, OptionsLib} from "src/SimpleMarket.sol";
import {console2} from "lib/forge-std/src/Test.sol";

contract MatchingEngine is SimpleMarket {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using SoladySafeCastLib for uint256;

    error InvalidBuy();


    function _marketBuy(
        address payToken,
        uint256 payAmount,
        address buyToken,
        uint256 minBuyAmount
    ) internal returns (uint256, uint256) {

        OffersLib.Offer memory request;
        request.pay_amount = payAmount.toUint96();
        request.price = request.buyToPriceMemory(minBuyAmount);

        bytes32 market = _getReversedMarket(payToken, buyToken);

        uint256 remainingAmount = payAmount;
        uint256 purchasedAmount;
        bool flag = true;

        while (flag) {
            (flag, remainingAmount, purchasedAmount) = _processBuy(
                market,
                remainingAmount,
                request.price,
                purchasedAmount,
                payToken,
                buyToken
            );
        }

        userBalances[msg.sender][buyToken] += purchasedAmount;

        return (remainingAmount, request.price);
    }



    function _popHead(bytes32 market, uint256 orderId) private {
        marketLists[market].popFront();
        delete offers[orderId];
    }
}
