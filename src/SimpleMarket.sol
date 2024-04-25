//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {StructuredLinkedList, IStructureInterface} from "src/Libraries/StructuredLinkedList.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";
import {OptionsLib} from "src/Libraries/OptionsLib.sol";
import {SoladySafeCastLib} from "src/Libraries/SoladySafeCastLib.sol";
import {IOrderToken} from "src/Interfaces/IOrderToken.sol";

contract SimpleMarket is IStructureInterface {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using OptionsLib for OptionsLib.Option;

    event DEBUG(string s, uint256 v);
    event DEBUG(string s, bytes b);

    uint256 nextOrderId = 1;

    // User address => Token address => balance
    mapping(address => mapping(address => uint256)) public userBalances;

    mapping(uint256 => OffersLib.Offer) public offers;
    mapping(uint256 => OptionsLib.Option) public options;

    // Order Id to linked list
    mapping(bytes32 => StructuredLinkedList.List) marketLists;
    mapping(bytes32 => StructuredLinkedList.List) optionLists;

    event MakeOffer(uint256 id, bytes32 market, uint256 price);
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
        uint96 pay_amt,
        address pay_tkn,
        uint256 buy_amt,
        address buy_tkn
    ) internal returns(uint256) {
        uint256 thisOrder = nextOrderId;
        nextOrderId++;

        OffersLib.Offer storage offer = offers[thisOrder];
        require(!offer.isActive(), "Uh oh");

        offer.pay_amount = pay_amt;
        offer.pay_token = pay_tkn;
        offer.buy_token = buy_tkn;
        offer.owner = msg.sender;
        offer.offerCreated = uint40(block.timestamp);
        // Must be done after pay_amount is set
        uint256 orderPrice = offer.buyToPrice(buy_amt);
        if (orderPrice < OffersLib.MAX_PRECISION_LOSS) revert PrecisionLoss();
        offer.price = orderPrice;

        bytes32 market = getMarket(pay_tkn, buy_tkn);
        StructuredLinkedList.List storage list = marketLists[market];

        uint256 spot = list.getSortedSpot(address(this), orderPrice);

        require(list.insertBefore(spot, thisOrder), "Failed Insert");

        emit MakeOffer(thisOrder, market, orderPrice);
        return(thisOrder);
    }

    function _recordOption() internal returns (uint256) {}


    function receiveFunds(address pay_token, address from, address receiver) internal returns(uint256){
        uint256 balanceBefore = IOrderToken(pay_token).balanceOf(receiver);
        IOrderToken(pay_token).safeTransferFrom(from, receiver, pay_amt);
        return IOrderToken(pay_token).balanceOf(receiver) - balanceBefore;
    }
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Interface Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function getValue(uint256 id) external view returns (uint256) {
        return offers[id].price;
    }
}