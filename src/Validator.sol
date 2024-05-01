//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {IOfferValidator} from "src/Libraries/OffersLibEXP.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

contract OfferValidator is IOfferValidator, UUPSUpgradeable, AccessControlUpgradeable {

    function __OfferValidator_init() external initializer {
        __OfferValidator_init_unchained();
    }

    function __OfferValidator_init_unchained() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    /*
    * Order Types:
    *  0 - Basic order, always valid never killed
    *  1 - Expiry order, uint40 timestamp, valid before timestamp killed after timestamp
    * 
    */

    /// @notice Validate an offer's bytes data by above rules
    /// @param data The offer's data field
    /// @return bool The first bool is whether the offer is valid
    /// @return bool The second bool is whether the offer should be deleted permanently
    function validateOffer(bytes calldata data) external view returns(bool, bool) {
        uint256 offerType;
        assembly {
            offerType := shr(248, calldataload(data.offset))

        }
        if (offerType == 0) {
            return validateDefault(data);
        } else if (offerType == 1) {
            return validateExpiry(data);
        }

    }

    function validateDefault(bytes calldata data) internal view returns(bool, bool) {
        return (true, false);
    }

    function validateExpiry(bytes calldata data) internal view returns(bool, bool) {
        uint40 expiry;

        assembly {
            // The offer timestamp should be a packed uint40 after the selector
            // Offers with zeroed data due to misinput will be killed
            expiry := shr(216, calldataload(add(data.offset, 1)))
        }

        if (expiry < uint40(block.timestamp)) {
            // The offer has expired, kill the offer
            return (false, true);
        } else {
            // Offer is valid
            return (true, false);
        }
    }


    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}