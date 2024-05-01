//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.8.4;


import "lib/forge-std/src/Test.sol";

//import {IOfferValidator} from "src/Libraries/OffersLib.sol";


contract MathTest is Test {


    enum OrderType {
        TypeZero,
        TypeOne,
        TypeTwo,
        TypeThree
    }

    struct Offer {
        uint256 price;
        address owner;
        bytes data;
    }

    string private checkpointLabel;
    uint256 private checkpointGasLeft = 1; // Start the slot warm.

    OfferValidator public validator;
    OfferValidatorTwo public validatorTwo;
    Offer public offer;

    function setUp() public {
        validator = new OfferValidator();
        validatorTwo = new OfferValidatorTwo();
    }

    function testMath() public {

        startMeasuringGas("Burn");
        stopMeasuringGas();
        // Offer memory offer = Offer({
        //     price: 1e18,
        //     owner: address(500),
        //     data: store
        // });
        uint8 a = 1;
        uint40 b = 12739412;
        bytes memory d = abi.encodePacked(a,b);

        uint8 m = 0;
        uint40 n = 12739412;
        bytes memory d2 = abi.encodePacked(m,n);

        
        startMeasuringGas("Non-Func 0");
        validator.validateOffer(d2);
        stopMeasuringGas();

        startMeasuringGas("Non-Func 1");
        validator.validateOffer(d);
        stopMeasuringGas();

        startMeasuringGas("Func 0");
        validatorTwo.validateOffer(d2);
        stopMeasuringGas();
        startMeasuringGas("Func 1");
        validatorTwo.validateOffer(d);
        stopMeasuringGas();
        // console2.logBytes32(bytes32(offer.data >> 16));
        


    }


    function startMeasuringGas(string memory label) internal virtual {
        checkpointLabel = label;

        checkpointGasLeft = gasleft();
    }

    function stopMeasuringGas() internal virtual {
        uint256 checkpointGasLeft2 = gasleft();

        // Subtract 100 to account for the warm SLOAD in startMeasuringGas.
        uint256 gasDelta = checkpointGasLeft - checkpointGasLeft2 - 100;

        emit log_named_uint(
            string(abi.encodePacked(checkpointLabel, " Gas")),
            gasDelta
        );
    }

} 


contract OfferValidator {


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


}
contract OfferValidatorTwo is Test{


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
        } 
        if (offerType == 1) {
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

}
