// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

library OffersLib {
    using Math for uint256;

    /// @notice The struct that defines offers
    /// @param price The sorted value for the struct
    /// @param pay_amount The amount of pay_token used as collateral
    /// @param pay_token The address of the collateral token
    /// @param buy_token The address of the desired token
    /// @param owner The address of the owner of the collateral tokens provided
    /// @param expiry The time at which the offer expires
    /// @dev The "buy_amount" is a calculated value from the price and pay_amount
    /// @dev This is to mitigate issues which rounding can create
    struct Offer {
        uint256 price;
        uint96 pay_amount;
        address pay_token;
        address buy_token;
        address owner;
        uint48 expiry;
    }
    // Constant scale factor to reduce rounding issues
    uint256 internal constant SCALE_FACTOR = 1e27;
    // Constant minimum value for the price variable to prevent certain unwanted behavior
    uint256 internal constant MAX_PRECISION_LOSS = 1e4;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Memory Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /// @notice Converts a buy amount and the offer's pay_amount to price
    /// @param self The offer itself
    /// @param buy_amount The amount of buy_token to calculate the price from
    function buyToPriceMemory(Offer memory self, uint256 buy_amount) internal pure returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              Storage Pointer Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /// @notice Checks if the offer has expired
    /// @param self The offer itself
    function isExpired(Offer storage self) internal view returns (bool) {
        return (self.expiry < block.timestamp);
    }
    /// @notice Converts a buy amount and the offer's pay_amount to price
    /// @param self The offer itself
    /// @param buy_amount The amount of buy_token to calculate the price from
    function buyToPrice(Offer storage self, uint256 buy_amount) internal view returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, self.pay_amount);
    }
    /// @notice Converts the price and pay_amount of the offer to the buy_amount
    /// @param self The offer itself
    function priceToBuy(Offer storage self) internal view returns (uint256) {
        return self.price.mulDiv(self.pay_amount, SCALE_FACTOR);
    }
    /// @notice Calculates the change in an offer to buy purchase amount
    /// @dev See MatchingEngine:_processBuy
    /// @param self The offer itself
    /// @param purchase The amount to purchase from the offer
    /// @return uint256 The amount purchased for purchase
    function buyQuote(Offer storage self, uint256 purchase) internal view returns (uint256) {
        return purchase.mulDiv(SCALE_FACTOR, self.price);
    }
    /// @notice Calculates the reversed price of an offer
    /// @dev The price if pay_token and buy_token were swapped
    /// @dev Mirrored across 1e27
    /// @param self The offer itself
    /// @return uint256 The reversed price
    function reversePrice(Offer storage self) internal view returns (uint256) {
        return SCALE_FACTOR.mulDiv(SCALE_FACTOR, self.price);
    }

    /// @notice Converts a buy amount and the offer's pay_amount to price
    /// @dev Used when the offer object itself is not available
    /// @param buy_amount The amount to buy
    /// @param pay_amount The amount provided as collateral
    /// @return uint256 The calculated price
    function buyToPrice(uint256 buy_amount, uint256 pay_amount) internal pure returns (uint256) {
        return buy_amount.mulDiv(SCALE_FACTOR, pay_amount);
    }
}
