//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {MatchingEngine, IOrderToken, SoladySafeCastLib, StructuredLinkedList, OffersLib, OptionsLib} from "src/MatchingEngine.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {SoladySafeCastLib} from "src/Libraries/SoladySafeCastLib.sol";
import {IOrderToken} from "src/Interfaces/IOrderToken.sol";

contract PublicMarket is MatchingEngine {
    using StructuredLinkedList for StructuredLinkedList.List;
    using SoladySafeCastLib for uint256;
    using SafeTransferLib for IOrderToken;


    function makeOffer(
        uint256 pay_amt,
        address pay_tkn,
        uint256 buy_amt,
        address buy_tkn
    ) external returns (uint256) {

        if (pay_amt == 0) revert InvalidOffer();
        if (buy_amt == 0) revert InvalidOffer();
        if (pay_tkn == address(0)) revert InvalidOffer();
        if (buy_tkn == address(0)) revert InvalidOffer();
        if (pay_tkn == buy_tkn) revert InvalidOffer();

        uint256 received = receiveFunds(pay_tkn, msg.sender, address(this));

        (uint256 remaining, uint256 price) = _marketBuy(pay_tkn, received, buy_tkn, buy_amt);

        return _recordOffer(remaining.toUint96(), pay_tkn, buy_amt, buy_tkn);
    }





}