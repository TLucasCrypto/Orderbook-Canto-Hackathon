//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {MatchingEngine, SoladySafeCastLib, StructuredLinkedList, OffersLib} from "src/MatchingEngine.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SoladySafeCastLib} from "src/Libraries/SoladySafeCastLib.sol";

// import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract PublicMarket is MatchingEngine {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using SoladySafeCastLib for uint256;
    using SafeERC20 for IERC20;

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
        if (uint256(expires) > block.timestamp + MAX_EXPIRY) {
            revert InvalidOffer();
        }

        uint256 received = receiveFunds(pay_tkn, pay_amt, msg.sender, address(this));

        uint256 orderPrice = OffersLib.buyToPrice(buy_amt, received);
        emit DEBUG("Order Price: ", orderPrice);
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

        sendFunds(buy_tkn, msg.sender);
        return orderId;
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

        uint256 received = receiveFunds(pay_tkn, pay_amt, msg.sender, address(this));

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

        // Need to review this
        sendFunds(buy_tkn, msg.sender);
        if (remaining != 0) {
            IERC20(pay_tkn).safeTransfer(msg.sender, remaining);
        }

        return remaining;
    }

    /// @notice Transfer funds from to receiver and calculate received amount
    /// @param pay_token The address of the token to receive
    /// @param pay_amount The amount of tokens to receive
    /// @param from The address to receive funds from
    /// @param receiver The address to receive the tokens
    /// @return Uint256 The amount of tokens received by receiver
    function receiveFunds(address pay_token, uint256 pay_amount, address from, address receiver)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = IERC20(pay_token).balanceOf(receiver);
        IERC20(pay_token).transferFrom(from, receiver, pay_amount);
        return IERC20(pay_token).balanceOf(receiver) - balanceBefore;
    }

    /// @notice Allow user to withdraw their balance of tokens from contract
    /// @param token The address of the token to receive
    function withdraw(address token) external {
        sendFunds(token, msg.sender);
    }

    /// @notice Allow user to withdraw several tokens at once
    /// @param tokens An array containing the address of tokens to receive
    function withdrawMany(address[] calldata tokens) external {
        uint256 len = tokens.length;
        for (uint256 i; i < len; ++i) {
            sendFunds(tokens[i], msg.sender);
        }
    }

    /// @notice Send funds in userBalances to users
    /// @param token The address of the token to receive
    /// @param receiver The address to receive the tokens
    function sendFunds(address token, address receiver) internal {
        uint256 amount = userBalances[receiver][token];
        if (amount != 0) {
            delete userBalances[receiver][token];
            IERC20(token).safeTransfer(receiver, amount);
        }
    }

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
