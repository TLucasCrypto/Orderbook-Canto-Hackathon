//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {StructuredLinkedList, IStructureInterface} from "src/Libraries/StructuredLinkedList.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";

contract SimpleMarket is IStructureInterface {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;

    event DEBUG(string s, uint256 v);
    event DEBUG(string s, bytes b);
    event DEBUG(string s, address a);

    // Counter for unique offers
    // OfferId of 0 is a critical value, do not set zero to non-zero value
    uint256 nextOfferId = 1;
    // Maximum time limit of 1 year
    uint256 MAX_EXPIRY = 365 days;

    // Used as the address for native tokens
    // Currently not implemented
    // address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // User address => Token address => balance
    mapping(address => mapping(address => uint256)) public userBalances;
    // OfferId to the offer struct
    mapping(uint256 => OffersLib.Offer) public offers;

    // Offer Id to linked list
    mapping(bytes32 => StructuredLinkedList.List) internal marketLists;

    event MakeOffer(uint256 id, bytes32 market, uint256 price);
    event UserBalanceUpdated(address user, address token);

    error InvalidOffer();
    error PrecisionLoss();
    error InvalidOwnership();
    error NotFound();
    error NoneBought();

    /// @notice Get the market identifier for a token pair
    /// @dev Each market has a unique bytes32 identifier based on the token pair
    /// @param pay_token, the address of the token the user has and wants to trade
    /// @param buy_token, the address of the token the user wants in return for pay_token
    /// @return Bytes32 identifier of the market
    function getMarket(address pay_token, address buy_token) public pure returns (bytes32) {
        return keccak256(abi.encode(pay_token, buy_token));
    }

    /// @notice Get the reversed market identifier for a token pair
    /// @dev A reversed market is the flipped token pairs
    /// @dev Example: Market = WCanto/Note , Reversed Market Note/WCanto
    /// @dev Used to keep code consistent of pay_token then buy_token in function calls
    /// @param pay_token, the address of the token the user has and wants to trade
    /// @param buy_token, the address of the token the user wants in return for pay_token
    /// @return Bytes32 identifier of the reverse market pair
    function _getReversedMarket(address pay_token, address buy_token) internal pure returns (bytes32) {
        return getMarket(buy_token, pay_token);
    }

    /// @notice Stores an offer in the appropriate market list
    /// @param offer The offer to record
    /// @return Uint256 The id of the recorded offer
    function _recordOffer(OffersLib.Offer memory offer) internal returns (uint256) {
        require(offer.owner != address(0), "Uh oh");

        uint256 thisOrder = nextOfferId;
        nextOfferId++;

        offers[thisOrder] = offer;

        bytes32 market = getMarket(offer.pay_token, offer.buy_token);
        StructuredLinkedList.List storage list = marketLists[market];

        uint256 spot = list.getSortedSpot(address(this), offer.price);

        require(list.insertBefore(spot, thisOrder), "Failed Insert");

        emit MakeOffer(thisOrder, market, offer.price);
        return (thisOrder);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Interface Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /// @notice Required by StructuredLinkedList for getSortedSpot
    /// @dev Determines how the offers should be sorted in the linked lists
    /// @dev We sort offers by the price value in increasing order
    /// @param id The id of the offer to get the value of
    /// @return Uint256 The value of the offer used for sorting orders
    function getValue(uint256 id) external view returns (uint256) {
        return offers[id].price;
    }
}
