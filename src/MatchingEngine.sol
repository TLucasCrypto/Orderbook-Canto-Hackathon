//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {SimpleMarket, StructuredLinkedList} from "src/SimpleMarket.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";
import {SoladySafeCastLib} from "src/Libraries/SoladySafeCastLib.sol";

contract MatchingEngine is SimpleMarket {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using SoladySafeCastLib for uint256;

    error InvalidBuy();

    /// @notice Handles the overall market buy process
    /// @param request The marketBuy request data as an Offer struct
    /// @return remainingAmount The amount of the request left unbought
    function _marketBuy(OffersLib.Offer memory request) internal returns (uint256) {
        // Buying into the reversed market list
        bytes32 market = _getReversedMarket(request.pay_token, request.buy_token);

        uint256 remainingAmount = request.pay_amount;
        uint256 purchasedAmount;

        bool flag = true;

        while (flag) {
            (flag, remainingAmount, purchasedAmount) =
                _processBuy(market, remainingAmount, request.price, purchasedAmount, request.pay_token);
        }

        if (purchasedAmount != 0) {
            userBalances[msg.sender][request.buy_token] += purchasedAmount;
        }

        return remainingAmount;
    }

    /// @notice Handle the market buy process on individual stored orders
    /// @param market The bytes32 identifier for the market
    /// @param remainingAmount The amount left in the buy order
    /// @param requestPrice The maximum price to buy orders
    /// @param purchasedAmount The total amount of purchased tokens
    /// @param payToken The pay_token of the ***buy_order***
    /// @return bool True if we continue buying offers, false if done
    /// @return uint256 The remaining amount of purchasing power
    /// @return uint256 The cumulative amount of tokens purchased
    function _processBuy(
        bytes32 market,
        uint256 remainingAmount,
        uint256 requestPrice,
        uint256 purchasedAmount,
        address payToken
    ) internal returns (bool, uint256, uint256) {
        (, uint256 offerId) = marketLists[market].getAdjacent(0, true);
        // If offerId is zero the list is empty
        if (offerId == 0) return (false, remainingAmount, purchasedAmount);

        OffersLib.Offer storage offer = offers[offerId];

        if (!_validateOffer(offer, offerId, market)) {
            return (true, remainingAmount, purchasedAmount);
        }

        if (offer.reversePrice() < requestPrice) {
            return (false, remainingAmount, purchasedAmount);
        }

        uint256 payOut;
        // If the offer is greater than the buy request, consume the buy request
        // otherwise consume the offer and continue
        if (offer.priceToBuy() > remainingAmount) {
            payOut = offer.buyQuote(remainingAmount);
            offer.pay_amount = (offer.pay_amount - payOut).toUint96();

            purchasedAmount += payOut;
            userBalances[offer.owner][payToken] += remainingAmount;
            emit UserBalanceUpdated(offer.owner, payToken);

            return (false, 0, purchasedAmount);
        } else {
            payOut = offer.priceToBuy();

            purchasedAmount += offer.pay_amount;
            userBalances[offer.owner][payToken] += payOut;
            emit UserBalanceUpdated(offer.owner, payToken);

            _popHead(market, offerId);
            return (true, remainingAmount - payOut, purchasedAmount);
        }
    }

    /// @notice Validate an offer is able to be purchased
    /// @dev This can be changed before deployment to include additional conditions
    /// @dev In the experimental folder there is a version of this to include an upgradeable
    /// @dev Validator contract that allows for changes and updates to validation conditions
    /// @dev Would love community feedback on what types of orders/conditions to support
    /// @dev Can include an extra uint96 and uint48 to the Offer struct with packing
    /// @dev Can also change to a bytes data format to become more programmable
    /// @param offer The offer itself
    /// @param offerId The id of the offer
    /// @param market The market that contains the offer
    /// @return bool True if the offer is valid, false otherwise
    function _validateOffer(OffersLib.Offer storage offer, uint256 offerId, bytes32 market) internal returns (bool) {
        if (offer.isExpired()) {
            _killOffer(offer, offerId, market);
            return false;
        }
        return true;
    }

    /// @notice Kill an existing offer
    /// @param offer The offer itself
    /// @param offerId The id of the offer
    /// @param market The market that contains the offer
    function _killOffer(OffersLib.Offer storage offer, uint256 offerId, bytes32 market) private {
        userBalances[offer.owner][offer.pay_token] += offer.pay_amount;
        marketLists[market].remove(offerId);
        delete offers[offerId];
    }

    /// @notice Private function to remove the first item of the list
    /// @param market The market of the order to remove
    /// @param offerId The id of the offer to remove
    function _popHead(bytes32 market, uint256 offerId) internal {
        marketLists[market].popFront();
        delete offers[offerId];
    }
}
