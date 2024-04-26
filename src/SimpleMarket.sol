//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {StructuredLinkedList, IStructureInterface} from "src/Libraries/StructuredLinkedList.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";
import {OptionsLib} from "src/Libraries/OptionsLib.sol";
import {SoladySafeCastLib} from "src/Libraries/SoladySafeCastLib.sol";

contract SimpleMarket is IStructureInterface {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using OptionsLib for OptionsLib.Option;

    event DEBUG(string s, uint256 v);
    event DEBUG(string s, bytes b);

    uint256 nextOrderId = 1;
    uint256 MAX_EXPIRY = 365 days;
    address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // User address => Token address => balance
    mapping(address => mapping(address => uint256)) public userBalances;
    // mapping(address => mapping(address => OptionsLib.Lock)) public lockup;

    mapping(uint256 => OffersLib.Offer) public offers;
    mapping(uint256 => OptionsLib.Option) public options;

    // Order Id to linked list
    mapping(bytes32 => StructuredLinkedList.List) marketLists;
    mapping(bytes32 => StructuredLinkedList.List) optionLists;

    event MakeOffer(uint256 id, bytes32 market, uint256 price);
    event MakeOption(uint256 id, bytes32 market, uint256 price);
    event UserBalanceUpdated(address user, address token);

    error InvalidOffer();
    error PrecisionLoss();
    error InvalidOwnership();
    error NotFound();

    function getMarket(
        address pay_token,
        address buy_token
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(pay_token, buy_token));
    }

    function _getReversedMarket(
        address pay_token,
        address buy_token
    ) internal pure returns (bytes32) {
        return getMarket(buy_token, pay_token);
    }

    function _recordOffer(
        OffersLib.Offer memory offer
    ) internal returns (uint256) {
        require(offer.owner != address(0), "Uh oh");

        uint256 thisOrder = nextOrderId;
        nextOrderId++;

        offers[thisOrder] = offer;

        bytes32 market = getMarket(offer.pay_token, offer.buy_token);
        StructuredLinkedList.List storage list = marketLists[market];

        uint256 spot = list.getSortedSpot(address(this), offer.price);

        require(list.insertBefore(spot, thisOrder), "Failed Insert");

        emit MakeOffer(thisOrder, market, offer.price);
        return (thisOrder);
    }

    function _recordOption(OptionsLib.Option memory option) internal returns (uint256) {
        require(option.owner != address(0), "Uh oh");

        uint256 thisOrder = nextOrderId;
        nextOrderId++;

        options[thisOrder] = option;
        bytes32 market = getMarket(option.pay_token, option.buy_token);
        StructuredLinkedList.List storage list = optionLists[market];

        uint256 spot = list.getSortedSpot(address(this), option.price);

        require(list.insertBefore(spot, thisOrder), "Failed Insert");

        emit MakeOption(thisOrder, market, option.price);
        return (thisOrder);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Interface Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function getValue(uint256 id) external view returns (uint256) {
        return offers[id].price;
    }
}
