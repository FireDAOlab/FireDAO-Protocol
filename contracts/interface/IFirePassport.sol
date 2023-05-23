// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../struct/User.sol';
interface IFirePassport {
    function usernameExists(string memory username) external returns(bool);
    function getUserCount() external view  returns(uint);
    function hasPID(address user) external view returns(bool);
    function getUserInfo(address user) external view returns(User memory);
    
    }
