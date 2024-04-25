//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.8.0;

interface IOrderToken {

    /// @dev See IERC20
    function approve(address spender, uint256 value) external returns (bool);
    
    /// @dev See IERC20
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /// @dev See IERC20
    function balanceOf(address account) external view returns (uint256);



}