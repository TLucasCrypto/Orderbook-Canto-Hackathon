//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.8.4;

import "lib/forge-std/src/Test.sol";
import {MockERC20} from "src/Mocks/MockERC20.sol";
import {PublicMarketHarness} from "src/Harness/PublicMarketHarness.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {OffersLib} from "src/Libraries/OffersLib.sol";
import {OfferValidator} from "src/Validator.sol";
import {ERC1967Proxy} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TestDeploy is Test {
    using OffersLib for OffersLib.Offer;

    PublicMarketHarness public target;
    OfferValidator public imp;
    ERC1967Proxy public validator;

    MockERC20 public usdc;
    MockERC20 public weth;
    MockERC20 public weth2;

    address public _target;
    address public _validator;

    address public _usdc;
    address public _weth;
    address public _weth2;

    address public admin = address(1);
    address public alice = address(1000);
    address public bob = address(2000);
    address public carl = address(3000);

    string private checkpointLabel;
    uint256 private checkpointGasLeft = 1; // Start the slot warm.

    function InitPublicMarket() public {
        vm.startPrank(admin);

        bytes memory initData = abi.encodeWithSignature("__OfferValidator_init()");

        imp = new OfferValidator();
        validator = new ERC1967Proxy(address(imp), initData);

        target = new PublicMarketHarness(address(validator));

        usdc = new MockERC20(6);
        weth = new MockERC20(18);
        weth2 = new MockERC20(18);

        vm.stopPrank();

        _target = address(target);
        _validator = address(validator);

        _usdc = address(usdc);
        _weth = address(weth);
        _weth2 = address(weth2);

        vm.label(_target, "Public Market");
        vm.label(_validator, "Validator Proxy");
        vm.label(_usdc, "USDC");
        vm.label(_weth, "WETH");
        vm.label(_weth2, "WETH2");
        vm.label(admin, "ADMIN");
        vm.label(alice, "ALICE");
        vm.label(bob, "BOB");
        vm.label(carl, "CARL");

        DealTokens(_usdc, 1e50);
        DealTokens(_weth, 1e50);
        DealTokens(_weth2, 1e50);
    }

    modifier CallFrom(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    function DealTokens(address token, uint256 amount) internal {
        StdCheats.deal(token, admin, amount);
        StdCheats.deal(token, alice, amount);
        StdCheats.deal(token, bob, amount);
        StdCheats.deal(token, carl, amount);
    }

    function GiveApproval(address user, address token) internal {
        vm.prank(user);
        IERC20(token).approve(_target, type(uint256).max);
    }

    function RetrieveOffer(
        uint256 id
    ) internal returns (OffersLib.Offer memory offer) {
        (uint256 a, uint96 b, address c, address d, address e, uint48 f) = target.offers(
            id
        );
        
        offer = OffersLib.Offer({
            price: a,
            pay_amount: b,
            pay_token: c,
            buy_token: d,
            owner: e,
            expiry: f
        });
    }

    function CreateAndPrintOffer(
        address caller,
        address payToken,
        uint256 payAmount,
        address buyToken,
        uint256 buyAmount
    ) internal returns(uint256) {
        vm.startPrank(caller);
        MockERC20(payToken).approve(_target, payAmount);
        uint256 orderId = target.makeOfferSimple(
            payToken,
            payAmount,
            buyToken,
            buyAmount
        );
        vm.stopPrank();

        OffersLib.Offer memory offer = RetrieveOffer(orderId);
        uint256 buy_amount = target.GetBuyAmount(orderId);
        bytes32 marketIdentifier = target.getMarket(
            offer.pay_token,
            offer.buy_token
        );

        console.log("Offer: ");
        console.log("{");
        console2.log("Price: ", offer.price);
        console2.log("Pay Amount: ", offer.pay_amount);
        console2.log("Buy Amount: ", buy_amount);
        console2.log("Pay Token: ", offer.pay_token);
        console2.log("Buy Token: ", offer.buy_token);
        console2.log("Owner: ", offer.owner);

        console2.logString("Market: ");
        console2.logBytes32(marketIdentifier);
        console.log("}");
        return orderId;
    }


    function PrintOffer(
        uint256 orderId
    ) internal  {

        OffersLib.Offer memory offer = RetrieveOffer(orderId);
        uint256 buy_amount = target.GetBuyAmount(orderId);
        bytes32 marketIdentifier = target.getMarket(
            offer.pay_token,
            offer.buy_token
        );

        console.log("Offer: ");
        console.log("{");
        console2.log("Price: ", offer.price);
        console2.log("Pay Amount: ", offer.pay_amount);
        console2.log("Buy Amount: ", buy_amount);
        console2.log("Pay Token: ", offer.pay_token);
        console2.log("Buy Token: ", offer.buy_token);
        console2.log("Owner: ", offer.owner);

        console2.logString("Market: ");
        console2.logBytes32(marketIdentifier);
        console.log("}");
    }

    function printId(uint256 orderId) internal {
        (uint256 price, uint96 pay, address ptoken, address btoken, address owner, ) = target.offers(orderId);

        uint256 reversed = target.GetReversePrice(orderId);
        console2.log("Order Id   : ", orderId);
        console2.log("PRICE      : ", price);
        console2.log("REVERSED   : ", reversed);
        console2.log("Pay Amount : ", pay);
        console2.log("Buy Amount : ", target.GetBuyAmount(orderId));
        console2.logString("");
    }

    function printList(bytes32 market, string memory id) internal {
        console2.logString(id);
        uint256[] memory lst = target.GetMarketList(market);
        for (uint256 i; i < lst.length; ++i) {
            printId(lst[i]);
        }
        console2.logString("");
    }

    function makeOfferSimples(
        uint256[] memory payAmounts,
        address payToken,
        uint256[] memory buyAmounts,
        address buyToken
    ) internal {
        uint256 len = payAmounts.length;
        assertEq(len, buyAmounts.length);

        for (uint256 i; i < len; ++i) {
            if (payAmounts[i] == 0 || buyAmounts[i] == 0) break;
            target.makeOfferSimple(payToken, payAmounts[i], buyToken, buyAmounts[i]);
        }
        bytes32 market = target.getMarket(payToken, buyToken);
        console2.logAddress(payToken);
        printList(market, "Initial Market");
        console2.log("");
    }

    function userOffer(
        address user,
        address payToken,
        uint256 payAmount,
        address buyToken,
        uint256 buyAmount
    ) internal CallFrom(user) {
        StdCheats.deal(payToken, user, payAmount);
        IERC20(payToken).approve(_target, payAmount);
        target.makeOfferSimple(payToken, payAmount, buyToken, buyAmount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  Solmate Functions                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

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

    /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    function _random() internal returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // This is the keccak256 of a very long string I randomly mashed on my keyboard.
            let
                sSlot
            := 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee
            let sValue := sload(sSlot)

            mstore(0x20, sValue)
            r := keccak256(0x20, 0x40)

            // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
            if iszero(sValue) {
                sValue := sSlot
                let m := mload(0x40)
                calldatacopy(m, 0, calldatasize())
                r := keccak256(m, calldatasize())
            }
            sstore(sSlot, add(r, 1))

            // Do some biased sampling for more robust tests.
            // prettier-ignore
            for {} 1 {} {
                let d := byte(0, r)
                // With a 1/256 chance, randomly set `r` to any of 0,1,2.
                if iszero(d) {
                    r := and(r, 3)
                    break
                }
                // With a 1/2 chance, set `r` to near a random power of 2.
                if iszero(and(2, d)) {
                    // Set `t` either `not(0)` or `xor(sValue, r)`.
                    let t := xor(not(0), mul(iszero(and(4, d)), not(xor(sValue, r))))
                    // Set `r` to `t` shifted left or right by a random multiple of 8.
                    switch and(8, d)
                    case 0 {
                        if iszero(and(16, d)) { t := 1 }
                        r := add(shl(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    default {
                        if iszero(and(16, d)) { t := shl(255, 1) }
                        r := add(shr(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    // With a 1/2 chance, negate `r`.
                    if iszero(and(0x20, d)) { r := not(r) }
                    break
                }
                // Otherwise, just set `r` to `xor(sValue, r)`.
                r := xor(sValue, r)
                break
            }
        }
    }
}
