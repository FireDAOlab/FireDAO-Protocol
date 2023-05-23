// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFireSeed {
    function upclass(address usr) external view returns(address);
    function getSingleAwardSbt007() external view returns(uint256);
    function burnFireSeed(address _account, uint256 _idOfUser, uint256 _value) external ;
}