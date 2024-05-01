//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.0;

contract Offers {
    function getOffers()
        public
        pure
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory alicePay = new uint256[](16);
        alicePay[0] = 1.5e6; // Higher
        alicePay[1] = 1.2e6; // Higher
        alicePay[2] = 1.1e6; // Lower
        alicePay[3] = 1.6e6; // Lower
        alicePay[4] = 1.5e6; // Higher
        alicePay[5] = 1.2e6; // Higher
        alicePay[6] = 1.1e6; // Lower
        alicePay[7] = 1.7e6; // Lower
        alicePay[8] = 1.3e6; // Lower
        alicePay[9] = 8e5; // Lower
        alicePay[10] = 1.4e6; // Higher
        alicePay[11] = 1.9e6; // Higher;
        alicePay[12] = 1.3e6; // Lower
        alicePay[13] = 8e5; // Lower
        alicePay[14] = 1.4e6; // Higher
        alicePay[15] = 1.9e6; // Higher;

        uint256[] memory aliceBuy = new uint256[](16);
        aliceBuy[0] = 1.8e6; // Higher
        aliceBuy[1] = 5e5; // Lower
        aliceBuy[2] = 8e5; // Higher
        aliceBuy[3] = 1.1e6; // Lower
        aliceBuy[4] = 9e5; // Lower
        aliceBuy[5] = 1.3e6; // Higher
        aliceBuy[6] = 7e5; // Lower
        aliceBuy[7] = 1.7e5; // Higher
        aliceBuy[8] = 1.8e6; // Higher
        aliceBuy[9] = 5e5; // Lower
        aliceBuy[10] = 8e5; // Higher
        aliceBuy[11] = 1.1e6; // Lower
        aliceBuy[12] = 9e5; // Lower
        aliceBuy[13] = 1.3e6; // Higher
        aliceBuy[14] = 7e5; // Lower
        aliceBuy[15] = 1.7e5; // Higher

        uint256[] memory bobPay = new uint256[](16);
        bobPay[0] = 1.3e6; // Lower
        bobPay[1] = 8e5; // Lower
        bobPay[2] = 1.4e6; // Higher
        bobPay[3] = 1.9e6; // Higher;
        bobPay[4] = 1.3e6; // Lower
        bobPay[5] = 8e5; // Lower
        bobPay[6] = 1.4e6; // Higher
        bobPay[7] = 1.9e6; // Higher;
        bobPay[8] = 1.5e6; // Higher
        bobPay[9] = 1.2e6; // Higher
        bobPay[10] = 1.1e6; // Lower
        bobPay[11] = 1.7e6; // Lower
        bobPay[12] = 1.5e6; // Higher
        bobPay[13] = 1.2e6; // Higher
        bobPay[14] = 1.1e6; // Lower
        bobPay[15] = 1.7e6; // Lower

        uint256[] memory bobBuy = new uint256[](16);
        bobBuy[0] = 9e5; // Lower
        bobBuy[1] = 1.3e6; // Higher
        bobBuy[2] = 7e5; // Lower
        bobBuy[3] = 1.7e6; // Higher
        bobBuy[4] = 1.8e6; // Higher
        bobBuy[5] = 5e5; // Lower
        bobBuy[6] = 8e5; // Higher
        bobBuy[7] = 1.1e6; // Lower
        bobBuy[8] = 9e5; // Lower
        bobBuy[9] = 1.3e6; // Higher
        bobBuy[10] = 7e5; // Lower
        bobBuy[11] = 1.7e5; // Higher
        bobBuy[12] = 1.8e6; // Higher
        bobBuy[13] = 5e5; // Lower
        bobBuy[14] = 8e5; // Higher
        bobBuy[15] = 1.1e6; // Lower

        return (alicePay, aliceBuy, bobPay, bobBuy);
    }
}