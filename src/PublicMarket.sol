//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity 0.8.24;

import {MatchingEngine, SoladySafeCastLib, StructuredLinkedList, OffersLib} from "src/MatchingEngine.sol";
import {SoladySafeCastLib} from "src/Libraries/SoladySafeCastLib.sol";


contract PublicMarket is MatchingEngine {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using SoladySafeCastLib for uint256;

    // Used for mainnet deployment to register on the turnstile
    // constructor(address _turnstile, address owner) {
    //     (bool ok, ) = _turnstile.call(abi.encodeWithSignature("register(address)", owner));
    //     require(ok, "Failed to register");
    // }

    /// @notice Public entrypoint to making an offer
    /// @dev See makeOfferCustom
    function makeOfferSimple(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt)
        external
        returns (uint256)
    {
        return _makeOffer(pay_tkn, pay_amt, buy_tkn, buy_amt, type(uint48).max);
    }

    /// @notice Public entrypoint to making an offer
    /// @dev See makeOfferCustom
    /// @dev Makes an offer that expires after expiry
    function makeOfferExpiry(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt, uint256 expiry)
        external
        returns (uint256)
    {
        return _makeOffer(pay_tkn, pay_amt, buy_tkn, buy_amt, expiry.toUint48());
    }

    /// @notice Public entrypoint to making a marketBuy
    /// @dev Unpurchased funds will be returned to user
    /// @param pay_tkn, the address of the token the user has and wants to trade
    /// @param pay_amt, the amount of pay_tkn the user wants to trade
    /// @param buy_tkn, the address of the token the user wants in return for pay_token
    /// @param buy_amt, the amount of buy_tkn the user wants in return for pay_amt
    /// @return Uint256, The amount remaining from the marketBuy
    function marketBuy(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt) external returns (uint256) {
        if (pay_amt == 0) revert InvalidOffer();
        if (buy_amt == 0) revert InvalidOffer();
        if (pay_tkn == address(0)) revert InvalidOffer();
        if (buy_tkn == address(0)) revert InvalidOffer();
        if (pay_tkn == buy_tkn) revert InvalidOffer();

        uint256 received = _receiveFunds(pay_tkn, pay_amt, msg.sender);

        uint256 orderPrice = OffersLib.buyToPrice(buy_amt, received);
        if (orderPrice < OffersLib.MAX_PRECISION_LOSS) revert PrecisionLoss();

        OffersLib.Offer memory offer = OffersLib.Offer({
            price: orderPrice,
            pay_amount: received.toUint96(),
            pay_token: pay_tkn,
            buy_token: buy_tkn,
            owner: msg.sender,
            expiry: 0
        });

        uint256 remaining = _marketBuy(offer);

        if (remaining == buy_amt) revert NoneBought();

        _sendFunds(msg.sender, buy_tkn);
        if (remaining != 0) {
            // _sendFunds will provide gas refund for this sstore
            userBalances[msg.sender][pay_tkn] += remaining;
            _sendFunds(msg.sender, pay_tkn);
        }
        return remaining;
    }

    /// @notice Cancel an existing offer
    /// @param offerId The id of the offer to cancel
    function cancelOffer(uint256 offerId) external {
        OffersLib.Offer storage offer = offers[offerId];
        if (msg.sender != offer.owner) revert InvalidOwnership();

        address payToken = offer.pay_token;

        bytes32 market = getMarket(payToken, offer.buy_token);

        userBalances[msg.sender][payToken] += offer.pay_amount;
        
        // There is no offerId 0, so should revert on !nodeExists check in remove
        if (marketLists[market].remove(offerId) != offerId) revert NotFound();
        delete offers[offerId];

        _sendFunds(msg.sender, payToken);
    }

    /// @notice Public entrypoint to making an offer
    /// @dev First checks if the offer can be filled from reversed market
    /// @dev Unpurchased funds will be listed in orderbook
    /// @param pay_tkn, the address of the token the user has and wants to trade
    /// @param pay_amt, the amount of pay_tkn the user wants to trade
    /// @param buy_tkn, the address of the token the user wants in return for pay_token
    /// @param buy_amt, the amount of buy_tkn the user wants in return for pay_amt
    /// @return Uint256, The id of the created order, 0 if fully filled
    function _makeOffer(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt, uint48 expires)
        internal
        returns (uint256)
    {
        if (pay_amt == 0) revert InvalidOffer();
        if (buy_amt == 0) revert InvalidOffer();
        if (pay_tkn == address(0)) revert InvalidOffer();
        if (buy_tkn == address(0)) revert InvalidOffer();
        if (pay_tkn == buy_tkn) revert InvalidOffer();
        if (expires <= block.timestamp) revert InvalidOffer();

        uint256 received = _receiveFunds(pay_tkn, pay_amt, msg.sender);

        uint256 orderPrice = OffersLib.buyToPrice(buy_amt, received);
        if (orderPrice < OffersLib.MAX_PRECISION_LOSS) revert PrecisionLoss();

        OffersLib.Offer memory offer = OffersLib.Offer({
            price: orderPrice,
            pay_amount: received.toUint96(),
            pay_token: pay_tkn,
            buy_token: buy_tkn,
            owner: msg.sender,
            expiry: expires
        });

        uint256 remaining = _marketBuy(offer);
        uint256 orderId;

        if (remaining > 0) {
            offer.pay_amount = remaining.toUint96();
            orderId = _recordOffer(offer);
        }

        _sendFunds(msg.sender, buy_tkn);
        return orderId;
    }

    /// @notice Allow user to withdraw their balance of tokens from contract
    /// @param token The address of the token to receive
    function withdraw(address token) external {
        _sendFunds(msg.sender, token);
    }

    /// @notice Allow user to withdraw several tokens at once
    /// @param tokens An array containing the address of tokens to receive
    function withdrawMany(address[] calldata tokens) external {
        uint256 len = tokens.length;
        for (uint256 i; i < len; ++i) {
            _sendFunds(msg.sender, tokens[i]);
        }
    }

    /// @notice Get the top number of items in a market
    /// @param pay_token The collateral token for the market
    /// @param buy_token The token that is wanted for the provided collateral
    /// @param numItems The number of items to return IF less than market size
    /// @return uint256[] The array of pay_amounts for the top market orders
    /// @return uint256[] The array of buy_amounts for the top market orders
    function getItems(address pay_token, address buy_token, uint256 numItems)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        bytes32 market = getMarket(pay_token, buy_token);

        StructuredLinkedList.List storage list = marketLists[market];

        uint256 size = list.size;
        if (numItems < size) {
            size = numItems;
        }

        uint256[] memory pay_amounts = new uint256[](size);
        uint256[] memory buy_amounts = new uint256[](size);

        uint256 orderId;
        for (uint256 i; i < size; ++i) {
            (, orderId) = list.getAdjacent(orderId, true);
            pay_amounts[i] = (offers[orderId].pay_amount);
            buy_amounts[i] = (offers[orderId].priceToBuy());
        }
        return (pay_amounts, buy_amounts);
    }
}
