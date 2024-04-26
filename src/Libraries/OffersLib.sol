// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interface IOrderToken {

//     /// @dev See IERC20
//     function approve(address spender, uint256 value) external returns (bool);

//     /// @dev See IERC20
//     function transferFrom(address from, address to, uint256 value) external returns (bool);

//     /// @dev See IERC20
//     function balanceOf(address account) external view returns (uint256);

// }

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
    }

    uint256 internal constant SCALE_FACTOR = 1e27;
    uint256 internal constant MAX_PRECISION_LOSS = 1e4;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Memory Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function buyToPriceMemory(
        Offer memory self,
        uint256 buy_amount
    ) internal pure returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              Storage Pointer Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function isActive(Offer storage self) internal view returns (bool) {
        return self.owner != address(0);
    }

    function buyToPrice(
        Offer storage self,
        uint256 buy_amount
    ) internal view returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }

    function priceToBuy(Offer storage self) internal view returns (uint256) {
        return self.price.mulDiv(self.pay_amount, SCALE_FACTOR);
    }

    function buyQuote(
        Offer storage self,
        uint256 remaining
    ) internal view returns (uint256) {
        return remaining.mulDiv(SCALE_FACTOR, self.price);
    }

    function consumePrices(
        Offer storage self,
        Offer storage smallerOffer
    ) internal view returns (uint256) {
        uint256 avgPrice = self.price.average(reversePrice(smallerOffer));
        return uint256(smallerOffer.pay_amount).mulDiv(SCALE_FACTOR, avgPrice);
    }

    function greenRedSelect(
        Offer storage greenOffer,
        Offer storage redOffer
    ) internal view returns (bool) {
        if (greenOffer.pay_amount < priceToBuy(redOffer)) {
            return false;
        } else if (redOffer.pay_amount < priceToBuy(greenOffer)) {
            return true;
        } else {
            return
                greenOffer.pay_amount * greenOffer.price >=
                    redOffer.pay_amount * redOffer.price
                    ? true
                    : false;
        }
    }

    function reversePrice(Offer storage self) internal view returns (uint256) {
        return SCALE_FACTOR.mulDiv(SCALE_FACTOR, self.price);
    }


    function priceToBuy(uint256 price, uint256 pay_amount) internal returns(uint256) {
        return price.mulDiv(pay_amount, SCALE_FACTOR);
    }
    function buyToPrice(uint256 buy_amount, uint256 pay_amount) internal returns(uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, pay_amount);
    }

}
