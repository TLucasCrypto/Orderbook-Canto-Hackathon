// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {console2} from "lib/forge-std/src/Test.sol";

library OffersLib {
    using Math for uint256;

    struct Offer {
        uint256 price;
        uint96 pay_amount;
        address pay_token;
        address buy_token;
        address owner;
        uint48 expiry;
    }

    uint256 internal constant SCALE_FACTOR = 1e27;
    uint256 internal constant MAX_PRECISION_LOSS = 1e4;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Memory Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function buyToPriceMemory(Offer memory self, uint256 buy_amount) internal pure returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              Storage Pointer Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function isActive(Offer storage self) internal view returns (bool) {
        return self.owner != address(0);
    }

    function isExpired(Offer storage self) internal view returns (bool) {
        return (self.expiry < block.timestamp);
    }

    function buyToPrice(Offer storage self, uint256 buy_amount) internal view returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }

    function priceToBuy(Offer storage self) internal view returns (uint256) {
        return self.price.mulDiv(self.pay_amount, SCALE_FACTOR);
    }

    function buyQuote(Offer storage self, uint256 remaining) internal view returns (uint256) {
        return remaining.mulDiv(SCALE_FACTOR, self.price);
    }

    function consumePrices(Offer storage self, Offer storage smallerOffer) internal view returns (uint256) {
        uint256 avgPrice = self.price.average(reversePrice(smallerOffer));
        return uint256(smallerOffer.pay_amount).mulDiv(SCALE_FACTOR, avgPrice);
    }

    function reversePrice(Offer storage self) internal view returns (uint256) {
        return SCALE_FACTOR.mulDiv(SCALE_FACTOR, self.price);
    }

    function priceToBuy(uint256 price, uint256 pay_amount) internal returns (uint256) {
        return price.mulDiv(pay_amount, SCALE_FACTOR);
    }

    function buyToPrice(uint256 buy_amount, uint256 pay_amount) internal returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, pay_amount);
    }
}
