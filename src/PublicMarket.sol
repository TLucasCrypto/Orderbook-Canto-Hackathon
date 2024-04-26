//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {MatchingEngine, SoladySafeCastLib, StructuredLinkedList, OffersLib, OptionsLib} from "src/MatchingEngine.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SoladySafeCastLib} from "src/Libraries/SoladySafeCastLib.sol";

// import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract PublicMarket is MatchingEngine {
    using StructuredLinkedList for StructuredLinkedList.List;
    using SoladySafeCastLib for uint256;
    using SafeERC20 for IERC20;

    function makeOffer(
        address pay_tkn,
        uint256 pay_amt,
        address buy_tkn,
        uint256 buy_amt
    ) external returns (uint256) {
        if (pay_amt == 0) revert InvalidOffer();
        if (buy_amt == 0) revert InvalidOffer();
        if (pay_tkn == address(0)) revert InvalidOffer();
        if (buy_tkn == address(0)) revert InvalidOffer();
        if (pay_tkn == buy_tkn) revert InvalidOffer();

        uint256 received = receiveFunds(
            pay_tkn,
            pay_amt,
            msg.sender,
            address(this)
        );

        uint256 orderPrice = OffersLib.buyToPrice(buy_amt, received);
        if (orderPrice < OffersLib.MAX_PRECISION_LOSS) revert PrecisionLoss();

        OffersLib.Offer memory offer = OffersLib.Offer({
            price: orderPrice,
            pay_amount: received.toUint96(),
            pay_token: pay_tkn,
            buy_token: buy_tkn,
            owner: msg.sender
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

    function marketBuy(
        address pay_tkn,
        uint256 pay_amt,
        address buy_tkn,
        uint256 buy_amt
    ) external {
        if (pay_amt == 0) revert InvalidOffer();
        if (buy_amt == 0) revert InvalidOffer();
        if (pay_tkn == address(0)) revert InvalidOffer();
        if (buy_tkn == address(0)) revert InvalidOffer();
        if (pay_tkn == buy_tkn) revert InvalidOffer();

        uint256 received = receiveFunds(
            pay_tkn,
            pay_amt,
            msg.sender,
            address(this)
        );

        uint256 orderPrice = OffersLib.buyToPrice(buy_amt, received);
        if (orderPrice < OffersLib.MAX_PRECISION_LOSS) revert PrecisionLoss();

        OffersLib.Offer memory offer = OffersLib.Offer({
            price: orderPrice,
            pay_amount: received.toUint96(),
            pay_token: pay_tkn,
            buy_token: buy_tkn,
            owner: msg.sender
        });

        uint256 remaining = _marketBuy(offer);

        sendFunds(buy_tkn, msg.sender);
        if (remaining != 0) {
            IERC20(pay_token).safeTransfer(receiver, remaining);
        }
    }

    function receiveFunds(
        address pay_token,
        uint256 pay_amount,
        address from,
        address receiver
    ) internal returns (uint256) {
        uint256 balanceBefore = IERC20(pay_token).balanceOf(receiver);
        IERC20(pay_token).safeTransferFrom(from, receiver, pay_amount);
        return IERC20(pay_token).balanceOf(receiver) - balanceBefore;
    }

    function withdraw(address token) external {
        sendFunds(token, msg.sender);
    }

    function withdrawMany(address[] calldata tokens) external {
        uint256 len = tokens.length;
        for (uint256 i; i < len; ++i) {
            sendFunds(tokens[i], msg.sender);
        }
    }

    function sendFunds(address token, address receiver) internal {
        uint256 amount = userBalances[receiver][token];
        if (amount != 0) {
            delete userBalances[receiver][token];
            IERC20(token).safeTransfer(receiver, amount);
        }
    }
}
