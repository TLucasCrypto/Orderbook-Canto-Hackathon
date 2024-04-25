// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

library OptionsLib {
    using Math for uint256;

    struct Option {
        uint256 price;
        uint96 pay_amount;
        address pay_token;
        uint96 premium;
        address buy_token;
        address owner;
        uint40 deadline;
    }

    uint256 internal constant SCALE_FACTOR = 1e27;
    uint256 internal constant MAX_PRECISION_LOSS = 1e4;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Memory Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function buyToPriceMemory(
        Option memory self,
        uint256 buy_amount
    ) internal pure returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              Storage Pointer Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    function buyToPrice(
        Option storage self,
        uint256 buy_amount
    ) internal view returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }

    function buyAmount(Option storage self) internal view returns (uint256) {
        return self.price.mulDiv(self.pay_amount, SCALE_FACTOR);
    }

    function buyQuote(
        Option storage self,
        uint256 remaining
    ) internal view returns (uint256) {
        return remaining.mulDiv(SCALE_FACTOR, self.price);
    }

    function consumePrices(
        Option storage self,
        Option storage smallerOption
    ) internal view returns (uint256) {
        uint256 avgPrice = self.price.average(reversePrice(smallerOption));
        return uint256(smallerOption.pay_amount).mulDiv(SCALE_FACTOR, avgPrice);
    }

    function reversePrice(Option storage self) internal view returns (uint256) {
        return SCALE_FACTOR.mulDiv(SCALE_FACTOR, self.price);
    }
}
