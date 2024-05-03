//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import {StructuredLinkedList, IStructureInterface} from "src/Libraries/StructuredLinkedList.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract SimpleMarket is IStructureInterface {
    using StructuredLinkedList for StructuredLinkedList.List;
    using OffersLib for OffersLib.Offer;
    using SafeERC20 for IERC20;
    // event DEBUG(string s, uint256 v);
    // event DEBUG(string s, bytes b);
    // event DEBUG(string s, address a);

    // Counter for unique offers
    // OfferId of 0 is a critical value, do not set zero to non-zero value
    uint256 nextOfferId = 1;
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
    error BadInsert(uint256 pos);

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
        
        if (!list.insertBefore(spot, thisOrder)) revert BadInsert(spot);

        emit MakeOffer(thisOrder, market, offer.price);
        return (thisOrder);
    }


    /// @notice Transfer funds from --> to and calculate received amount
    /// @param pay_token The address of the token to receive
    /// @param pay_amount The amount of tokens to receive
    /// @param from The address to receive funds from
    /// @param to The address to receive the tokens
    /// @return Uint256 The amount of tokens received by to
    function _receiveFunds(address pay_token, uint256 pay_amount, address from, address to)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = IERC20(pay_token).balanceOf(to);
        IERC20(pay_token).safeTransferFrom(from, to, pay_amount);
        return IERC20(pay_token).balanceOf(to) - balanceBefore;
    }

    /// @notice Send funds in userBalances to users
    /// @param token The address of the token to receive
    /// @param to The address to receive the tokens
    function _sendFunds(address to, address token) internal {
        uint256 amount = userBalances[to][token];
        if (amount != 0) {
            delete userBalances[to][token];
            IERC20(token).safeTransfer(to, amount);
        }
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
