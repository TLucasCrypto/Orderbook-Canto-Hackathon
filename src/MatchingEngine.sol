//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {SimpleMarket, SoladySafeCastLib, StructuredLinkedList, OffersLib, OptionsLib} from "src/SimpleMarket.sol";
import {console2} from "lib/forge-std/src/Test.sol";

contract MatchingEngine is SimpleMarket {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using SoladySafeCastLib for uint256;

    error InvalidBuy();

    function _marketBuy(
        OffersLib.Offer memory request
    ) internal returns (uint256) {
        bytes32 market = _getReversedMarket(
            request.pay_token,
            request.buy_token
        );

        uint256 remainingAmount = request.pay_amount;
        uint256 purchasedAmount;

        bool flag = true;

        while (flag) {
            (flag, remainingAmount, purchasedAmount) = _processBuy(
                market,
                remainingAmount,
                request.price,
                purchasedAmount,
                request.pay_token,
                request.buy_token
            );
        }

        userBalances[msg.sender][request.buy_token] += purchasedAmount;

        return remainingAmount;
    }

    function _processBuy(
        bytes32 market,
        uint256 remainingAmount,
        uint256 requestPrice,
        uint256 purchasedAmount,
        address payToken,
        address buyToken
    ) internal returns (bool, uint256, uint256) {
        (, uint256 orderId) = marketLists[market].getAdjacent(0, true);
        if (orderId == 0) return (false, remainingAmount, purchasedAmount);

        OffersLib.Offer storage offer = offers[orderId];

        if (offer.reversePrice() < requestPrice) {
            return (false, remainingAmount, purchasedAmount);
        }

        uint256 payOut;
        if (offer.priceToBuy() > remainingAmount) {
            payOut = offer.buyQuote(remainingAmount);

            offer.pay_amount = (offer.pay_amount - payOut).toUint96();

            purchasedAmount += payOut;
            userBalances[offer.owner][payToken] += remainingAmount;
            emit UserBalanceUpdated(offer.owner, request.pay_token);

            return (false, 0, purchasedAmount);
        } else {
            // Overwriting payOut
            payOut = offer.priceToBuy();

            purchasedAmount += offer.pay_amount;
            userBalances[offer.owner][payToken] += payOut;
            emit UserBalanceUpdated(offer.owner, request.pay_token);

            _popHead(market, orderId);
            return (true, remainingAmount - payOut, purchasedAmount);
        }
    }

    function _popHead(bytes32 market, uint256 orderId) internal {
        marketLists[market].popFront();
        delete offers[orderId];
    }
}
